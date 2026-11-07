# Recipe ranker

Hard filter first. For each safe recipe compute utility on 0–1: estimated preference .30, budget fit .25, pantry overlap .15, preparation time .12, variety .10, family preference fairness .08. Renormalize only non-sensitive defined missing components, with neutral defaults and uncertainty penalty. Add random exploration max 10% among safe affordable recipes, opt-out. Return explainable top reasons and stable seed.

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
