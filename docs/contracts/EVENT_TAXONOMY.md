# Event semantics

Prefer explicit event names: recipe_viewed, recipe_saved, recipe_selected, recipe_cooked, recipe_rated, recipe_disliked_explicit, meal_vote_submitted, meal_vote_skipped_explicit, meal_vote_not_seen (not dislike), purchase_confirmed, quantity_corrected, ingredient_depleted, game_started, game_completed, offer_viewed_adult. Logging follows consent; raw minor events not exported to ad tech.

## Implementation contract

1. Design inputs and version them before implementing.
2. Validate the actor's role and circle membership on the server before reading or writing private data.
3. Treat uncertainty as a product state, not as permission to fabricate data.
4. Emit privacy-minimized typed events only when processing is authorized.
5. Apply explicit test fixtures for success, empty, invalid, outage and cross-tenant use.
6. Document dependencies, rollback flags and operational observability.
7. Preserve accessibility, offline behavior and child safety across all features.

## Required acceptance

- [ ] Types/contracts reviewed and tracked in manifest.
- [ ] Unit and end-to-end happy and adversarial tests supplied.
- [ ] Staging behavior tested under degraded backend or no network.
- [ ] Owner approval captured for external services, costs and new personal-data purposes.
- [ ] No regression in safety, circle isolation or child commerce rules.
