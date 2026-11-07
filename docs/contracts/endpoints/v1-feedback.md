# POST /v1/feedback

## Purpose

record reason-coded feedback.

## Authorization and tenancy

member permitted; explicit consent. Validate caller identity, circle membership and role on the server; no authority from a client-supplied member ID alone. Never expose restricted data to managed child UI.

## Request and response

`Content-Type: application/json`. Include `request_id` on each response, `Idempotency-Key` for mutation, `schema_version`, and `circle_id` only when context authorized. Successful result contains `feedback_id` plus `revision` when mutable. Return typed errors with code, message and retryable fields. The endpoint schema must be finalized as typed Dart + TypeScript DTO pair before implementation; reject unknown keys.

## Constraints and observability

No private data in URLs, logs or analytics. Rate limit requests. Handle offline conflicts via `CONFLICT_REVISION`. Record minimal audit event and execution cost where AI service is called. Validate allergy safety and estimated price provenance for any meal output.

## Acceptance

- [ ] Happy path round trip and typed JSON schema tests.
- [ ] Cross-circle IDOR denied and child authorization denied where required.
- [ ] Invalid UUID, missing fields, stale revision and duplicate idempotency tested.
- [ ] No secret, restricted profile, or raw input prompt in logs or response.
- [ ] Throttling, provider outage and network retry documented.
