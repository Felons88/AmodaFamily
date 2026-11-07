# 20-day execution

Days 1–3 foundation/auth/circles/permissions; 4–6 onboarding/catalog safety; 7–9 planner/budget; 10–12 grocery/pantry/drinks; 13–14 voting/games; 15–16 preferences/notifications; 17–18 billing/ads adult-gated; 19–20 tests, UAT and staging beta. Parallel work subject to CI; defer risky integrations and all unclear legal/licensing dependencies.

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
