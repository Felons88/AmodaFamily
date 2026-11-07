# Missing votes and feedback

Track vote offered, delivered, opened, cast, manually skipped, timed-out and notification-disabled distinctly. None of delivered/not-opened/timeout is a dislike. After 2–3 repeated explicit skips, optional low-pressure question: busy, none appealing, already decided, other; never prompt children repeatedly. Use feedback reason to modify schedule/choice diversity, not infer diagnosis.

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
