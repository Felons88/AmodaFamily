# Fixture image-protein: chicken enchilada shrimp photo mismatch

## Given

image classification shrimp. Use deterministic seed and synthetic circle IDs; no real user PII.

## When

Execute corresponding server API, client state and privacy-safe analytics handler after authenticated actor-role setup. Capture all allow/deny conditions and store seed test data only in temporary environment.

## Expected

`IMAGE_MISMATCH`. No bypass through alternate route, cached state, AI-generated text, affiliate rank or client-side override. Verify typed error code, visible user-safe message, zero unintended side effects and idempotent retries.

## Test ownership

Assigned QA agent plus security reviewer for access/safety cases. Mandatory before beta, not marked passed until an actual test command with output and exit code is recorded.
