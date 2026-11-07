# Household Intelligence Engine v1: algorithms and evaluation

## Non-negotiable policies
Opt-in personalized learning; no cross-household profiling. Never infer allergy from a dislike, or treat a non-vote as dislike. Explicit allergies and exclusion rules always override preferences, votes, and paid features. Unknown ingredients are excluded from safety-sensitive recommendations pending verification. No calorie restriction or weight-loss nudges for minors. Do not optimize addictive session duration.

## Event taxonomy
`recipe_impression`, `recipe_open`, `vote_cast`, `vote_skipped` (system-observed absence, no negative weight), `recipe_disliked` (reason: taste|time|cost|texture|ingredient|other), `recipe_saved`, `meal_cooked`, `meal_not_cooked` (reason optional), `leftover_created`, `leftover_used`, `ingredient_purchased`, `ingredient_consumed_estimate`, `quantity_corrected`, `recommendation_explained`, `signal_corrected`, `signal_deleted`. Every event has timestamp, origin, actor scope, confidence, and retention policy. Analytics aggregate after privacy controls.

## Candidate pipeline
1. Retrieve approved recipe versions from global library.
2. Hard-filter: ingredient allergens/restrictions per household participant, unknown provenance, unsafe preparation for age mode, explicitly excluded ingredients, ingredient substitution unsafe. In case of uncertain cross-contact, show warning and abstain from a safety guarantee.
3. Adjust servings for eater age bands and self-reported appetites using editable baseline, never rigid assumptions.
4. Calculate canonical ingredient requirements and subtract pantry quantities only when unit-convertible; exclude ambiguous pantry entries from automatic subtraction.
5. Estimate prices from dated, labeled source; fallback historical estimates with uncertainty range. Label all SNAP eligibility as unverified unless verified source.
6. Score remaining candidates and diversify; do not rank recipe solely by popularity or engagement.
7. Show explanations and editing controls; user confirmation before plan/list purchase.

## Transparent initial scoring (calibrate after consented data)
`score = .25 * household_taste + .20 * affordability + .15 * pantry_use + .12 * prep_fit + .10 * nutrition_variety + .08 * meal_rotation + .06 * member_fairness + .04 * seasonal_fit` where each component is in [0,1]. Budget is a hard constraint for full-plan total when the user specifies a cap; fail gracefully by showing alternatives if impossible. Adult may adjust weights; soft scores cannot bypass exclusions. Do not claim clinically optimized nutrition.

## Learning individual tastes
Prior weights: explicit like +1.0; explicit dislike -1.0 for ingredient or recipe; cooked and positively rated +0.4; saved +0.2; vote +0.15; opening +0.02 (low trust); skipped vote = 0. Per-feature exponential time decay (e.g. 90-day half-life) with Bayesian shrinkage to neutral and max rate of change. No strong negative inference from abandonment or silence. Members can see and reset inferred preferences. Explicit reasons update only their target dimension (e.g., 'too expensive' lowers affordability fit for that recipe, not ingredient taste).

## Household preference aggregation
Aggregate active eater preferences weighted equally by default, allow adult manual overrides, prevent one loud voter's dominance. Rotate who influences choices across weeks. Unknown tastes stay neutral. Safety restrictions apply across all intended eaters; optional separately served substitutions must be checked individually.

## Meal selection
Constrained optimization over days/slots: total estimated spend <= available target budget (with adjustable reserve), servings sufficient, schedule/prep constraints, reuse perishable packages sensibly, ingredient overlap (not monotonous meals), variety and adequate food availability. MVP: greedy beam search over prefiltered candidates with capped iterations; no requirement for heavy ML. Provide 'couldn't fit' explanation rather than inventing food prices.

## Consumption forecast
For each ingredient, `next_trip_need = max(0, expected_consumption_until_next_trip + planned_recipe_needs + safety_buffer - verified_pantry_on_hand)` with unit normalization; consumption from rolling median of confirmed purchases + corrections, not solely AI. Handle spoilage, shelf-life, stores, beverages and pack rounding. Forecast confidence shown; default asks user to confirm. Milk example: historical two gallons/week, one gallon on hand, next shopping 7 days => suggest approximately one gallon adjusted for scheduled recipe use, shelf life and budget.

## Feedback on missed voting
Treat as `missing` and track UX diagnostics at aggregate level (was invitation delivered, was voting window open, accessible interface?). Offer optional low-frequency reason choice such as 'busy', 'none appealed', 'didn't see this'; no automatic negative food preference. Notification delivery telemetry needs opt-in/minimization.

## Evaluations
Compare personalized ranker against safe generic baseline with anonymized/consented test fixtures. Metrics: explicit satisfaction, weekly plan acceptance, number of manual changes, safe meal coverage, estimate error (MAPE only where sensible), feedback correction rate, rejected recipe diversity, and fairness across member preferences. Audit separate child/adult pathways. Offline simulation and holdout; no claims of 'learning' without measured improvement.

## Pseudocode
```python
def recommend(circle, eaters, budget, pantry, candidates):
    safe = [r for r in candidates if approved(r) and
            validated_allergens(r, eaters) and
            complies_with_explicit_restrictions(r, eaters)]
    if not safe:
        return NeedsHumanReview('No verified safe recipes found')
    scored = [(r, transparent_score(r, circle, pantry, budget)) for r in safe]
    return constrained_meal_plan(scored, budget, pantry, variety=True,
                                 display_uncertainty=True, require_user_approval=True)
```
