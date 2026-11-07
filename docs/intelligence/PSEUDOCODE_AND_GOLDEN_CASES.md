# Intelligence reference algorithms and golden fixtures

## Safe candidate selection

```python
def eligible(recipe, eaters, pantry, max_prep_minutes, all_sources):
    for component in recipe.canonical_ingredients:
        fact = all_sources.lookup(component.ingredient_id)
        if not fact or fact.composition_unverified:
            return False, 'ALLERGEN_UNCERTAIN'
        for eater in eaters:
            if fact.overlaps(eater.hard_allergens):
                return False, 'ALLERGEN_BLOCKED'
        if component.is_packaged and not component.brand_label_checked:
            return False, 'PACKAGED_FOOD_UNVERIFIED'
    if recipe.time_minutes > max_prep_minutes:
        return False, 'TIME_CONSTRAINT'
    return True, 'ELIGIBLE'
```

**Never** use the LLM to bypass this filter. A generic cookbook recipe is not medical certification of cross-contact safety.

## Preference update

```python
def update_taste(prior, event):
    if event.type in ('meal_vote_not_seen', 'meal_vote_timeout', 'recipe_viewed'):
        return prior
    weights = {'recipe_cooked_liked': +0.24, 'recipe_rated_positive': +0.20,
               'meal_vote_cast': +0.08, 'recipe_disliked_explicit': -0.27,
               'recipe_cooked_disliked': -0.26}
    evidence = weights.get(event.type)
    if evidence is None: return prior
    return clamp(prior + evidence * (1 - abs(prior)), -1, 1)
```

Hard allergies are stored as separate constraints and cannot be updated by taste events.

## Basket estimate

```python
def calculate_basket(recipe_lines, pantry, offers):
    need = aggregate_by_ingredient_and_unit(recipe_lines)
    for ingredient in need:
        need[ingredient] = max(0, need[ingredient] - confirmed_stock(pantry, ingredient))
    selected_packs = choose_smallest_feasible_pack_combo(need, offers)
    return {'total_estimate_cents': sum(x.estimated_cents for x in selected_packs),
            'source_timestamps': [x.price_as_of for x in selected_packs],
            'unknown_prices': [k for k in need if not has_verified_or_labeled_estimate(k)]}
```

## Consumption forecasts

`daily_rate = alpha * observed_daily_rate + (1-alpha) * prior_daily_rate` with `alpha=.25`, no forecast before 3 confirmed intervals unless labeled 'initial estimate'. `purchase_units = ceil(max(0, daily_rate * days_until_next_trip + safety_stock - current_inventory)/package_size)`; restrict fresh purchases by shelf-life and storage capacity. Deduplicate recipe-use and beverage consumption.

## Voting and feedback

For every vote round, record invitation status separate from vote status. `unseen`, `notification_opt_out`, `expired` are neutral. When member explicitly chooses 'none of these', offer optional reason tags `too_spicy`, `not_in_mood`, `time`, `cost`, `other`; reasons apply to the aspect of the meal, not all recipes using its ingredients. Ties resolved by adult or pre-announced deterministic rule, not monetization.

## Golden tests

1. Kiwi allergy + kiwi smoothie recommendation -> zero candidates, code ALLERGEN_BLOCKED.
2. Kiwi allergy + unknown fruit mix -> zero candidates, ALLERGEN_UNCERTAIN.
3. Chicken enchiladas text + shrimp fajita photo -> reject image, show labeled placeholder.
4. Five meal vote offers, zero opens -> no negative preference update.
5. 2 gallons milk weekly; pantry 1 gallon; 7d cycle -> purchase 1 gallon if consumption pattern confirmed and no extra stock buffer.
6. SNAP $150 / cash $40; grocery item eligibility unknown -> never claim the $150 covers it.
7. Three-person circle one subscription -> all active members inherit premium; child sees no paywall.
8. Minor attempts `POST /billing/checkout` -> ADULT_ONLY; never instantiate ad SDK in child runtime.
9. Multi-circle user requests different circle's child preference -> denied regardless of JWT membership in own circle.
10. Food budget too low for valid meal plan -> return PLAN_INFEASIBLE with safe review choices, never promise nutritional adequacy.
11. Family of one: tournament uses solo choice mode, no dead 'waiting for votes' state.
12. User deletes learning state: future recommendation explanations never cite removed preference history.
