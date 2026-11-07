# Ad policy and revenue

Only adult free-tier surfaces, contextual non-sensitive targeting and explicit sponsored labels; limit 1 sponsored slot per 8 organic recipe cards and max 2 ad impressions per adult session initially, subject to actual user research. No ad on child zone, allergies, budget hardship/SNAP setup, crisis/budget rescue, recipe safety steps, or voting choice that can alter recommendations. Ad networks must permit compliant contextual/no tracking mode.

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
