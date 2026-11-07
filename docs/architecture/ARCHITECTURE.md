# Technical architecture

## Stack
Flutter stable + Dart 3, Riverpod state management, GoRouter navigation, Freezed/json_serializable (optional), `supabase_flutter`; Supabase Auth, PostgreSQL, RLS, Storage with signed URLs for private images, Edge Functions for trusted operations. Push via FCM/APNs (opt-in), local notification scheduler, server-driven feature flags. Dart tests, PostgreSQL RLS tests, end-to-end mobile flows, image/snapshot comparisons.

## Package boundaries
`lib/app/` routing/theme/bootstrap; `lib/features/auth`, `households`, `onboarding`, `meal_plans`, `recipes`, `shopping`, `pantry`, `drinks`, `games`, `subscriptions`, `privacy`, `notifications`; `lib/shared/` design system + API clients + input validation; `supabase/migrations/`; `supabase/functions/`; `test/`; `integration_test/`.

## Security boundary
Mobile client may query ONLY RLS-protected user-specific tables directly. AI recipe publishing, shared catalog approval, invitations, role changes, paid entitlements, event processing, child-age role enforcement, budget computations tied to paid features, and notifications are server-side RPC/Edge Functions. Service-role key never reaches mobile. All authorization decisions recheck current circle memberships and roles on server.

## Data flow
Client → authenticated RLS query / Edge Function → policy/rules engine → validated reusable recipe catalog → candidate scorer → meal-plan review → aggregated grocery list → pantry/usage events → preference learner → next plan. Audit sensitive mutations with minimal non-PII logging.

## Failure design
Offline cached read-only last plan; queued idempotent user actions only where safe; retry with exponential backoff; conflict detection on concurrent shopping edits; AI timeout falls back to existing validated recipes and manual options; no unverified meal as 'allergen-safe'.

## Deployment
Dev/staging/prod Supabase projects, isolated keys and storage, migration-forward practices, pull-request gating, least-privileged CI identities, automated secret scanning, backups and restore drills. Environment variables through platform secret stores. No live production integration before approvals.
