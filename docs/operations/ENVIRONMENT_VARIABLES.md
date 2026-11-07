# Environment matrix

Flutter public Supabase URL/anon key only; never include service role. Backend protected keys: AI provider, image provider, webhook signing, APNs/FCM, ad provider identifiers adult-only, analytics privacy-safe. Sample env files contain placeholders; hard fail when required secret missing.

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

## Client build-time defines (this build)

| Variable | Purpose | Notes |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | safe to ship |
| `SUPABASE_ANON_KEY` | Publishable anon key | designed for client use; data is protected by RLS |
| `UPDATE_MANIFEST_URL` | Auto-update manifest JSON | `{version, build, apkUrl, notes, mandatory}`; silent no-op when unset |

## Server-side secrets (NEVER in the client)

| Variable | Purpose | Where |
|---|---|---|
| `OPENROUTER_API_KEY` | OpenRouter key for AI meal ideas | `supabase secrets set` only |
| `OPENROUTER_MODEL` | Model id | optional, default `openrouter/auto` |
| `sb_secret_*` | Supabase service-role key | Dashboard/CI only. NEVER in the APK, repo, or logs. |

The AI feature calls `supabase/functions/ai-meal-idea`, which holds the
OpenRouter key server-side. Client carries no AI secrets. Feature is gated
behind the in-app AI-processing consent toggle and adult role; output is
labeled AI-generated and never treated as allergy verification.
