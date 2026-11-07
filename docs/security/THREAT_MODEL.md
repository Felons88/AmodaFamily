# Security, privacy and safety requirements

## Threat scenarios
Circle A reading Circle B profiles or pantry; adult impersonating a guardian; child viewing paywall; unauthorized member receiving financial data; compromised invite token; webhook entitlement spoofing; prompt injection through recipe text; exposed API keys; unsafe allergen substitution; leaked household activity; malicious image/copyright violation; offline device loss.

## Required controls
- Supabase Auth with secure session storage, account recovery, optional passkeys/OAuth when supported. Avoid local plaintext secrets and do not record full DOB unless required by legal review.
- PostgreSQL RLS and membership checks on **every** tenant-scoped object. Deny by default and test same-circle vs cross-circle, adult vs minor. Do not grant billing or admin updates via generic client write.
- Server-authorized circle member invitations, short-lived single-use tokens, guardian authorization, member removal, revoke sessions. Avoid open search/discovery of minors.
- Encryption in transit TLS and managed-at-rest encryption; additional application-layer envelope encryption for highly sensitive household fields if threat model and operations warrant; KMS rotation, encrypted backups, least-privilege operations. Do not claim blanket end-to-end encryption while server-side AI needs plaintext.
- Child-safe commerce separation at Flutter **and** API layer; no paywall UI/routes, prices, banners, upsells, targeted ads, third-party child profiling or public chat. Age gating can use self-declared age band plus guardian-managed minors, with legal privacy review.
- COPPA / applicable child privacy review before launching under-13 features; parent notice/consent where applicable, data minimization, limits on retention and collection, consent revocation, no unnecessary precise location.
- AI gateway: redact identifiers, minimize member details, strict structured schema response, timeout/rate/cost caps, treat AI output as untrusted, deterministic backend validation, no AI authority to change allergy state or membership.
- Recipe provenance, ingredient ontology and allergen validation; cross-contact is brand/preparation specific and cannot be guaranteed by a recipe model. Do not say a food is safe for an allergy without ingredient/product verification and user review.
- Recipe/image source licensing, generated imagery labeling, image-match confidence with human review queue. No scraping Google image results into an app without rights.
- EBT manual amount/date workflow in MVP; do not take EBT Edge password, card number or PIN. Future direct integration only via documented authorized provider/API agreement and a separate security/legal assessment.
- Subscriptions: verify store/processor signed webhooks, ensure idempotency, subscription bound to `circle_id`, adult purchase authorization, billing owner separation, child never charged. App-store payment rules reviewed for distribution channels.
- Export/delete and data retention controls; private event streams segregated by tenant; audit permission changes, avoid logging recipes linked with personal allergies unnecessarily.

## Must-pass abuse tests
Unauthenticated access denied; cross-tenant SELECT/INSERT/UPDATE/DELETE denied; minors cannot call price/billing routes; invited guest cannot mutate; token reuse rejected; webhook forged/replayed rejected; unsafe ingredient image/recipe rejected; AI payload injection cannot modify role/policy; deleted profile no longer used in recommender; quiet-hours override prevented except user-selected urgent food safety notices.
