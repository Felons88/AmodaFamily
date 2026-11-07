# Entitlements

Server-sourced one entitlement per circle based on verified store/processor webhook; `plan=free|plus|family_pro`, `effective_at`, `expires_at`, `grace_until`, `provider_reference`; members inherit access from circle. Only authorized adult owner/admin purchases; child SDK payment paths never instantiated. Cancel means use through current paid term, then free. Restore verifies provider receipt.

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
