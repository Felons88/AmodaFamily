# Work board — planned, not completed

| ID | Scope | Agent | Depends on | Acceptance | State |
|---|---|---|---|---|---|
| FC-001 | Flutter workspace + CI | DevOps + Flutter | none | build/analyze passes | in progress — flutter_foundation |
| FC-002 | Postgres schema + RLS | Supabase + Security | FC-001 | tenant attacks fail | in progress — database_security (foundation; integration pending FC-001) |
| FC-003 | Adult auth + circle creation | Flutter + Supabase | FC-002 | signup/create + invited adult works | planned |
| FC-004 | Food ontology and allergen checks | Safety + Catalog | FC-002 | unknown composition denied | in progress — allergen_safety (standalone library; integration pending FC-002) |
| FC-005 | Onboarding + adult dashboard | Flutter + Design | FC-003 | first-plan path usable | planned |
| FC-006 | Recipe catalog + validated images | Catalog + Image | FC-004 | photo mismatch rejected | planned |
| FC-007 | Ranking + 7-day planning | Intelligence | FC-004,FC-006 | deterministic fixtures pass | planned |
| FC-008 | Budget baskets + pantry + drinks | Intelligence + Flutter | FC-007 | actual quantity and source math verified | planned |
| FC-009 | Voting and age-safe games | Gameplay + Flutter | FC-003,FC-006 | solo and child modes tested | planned |
| FC-010 | Adaptive feedback + nonvote semantics | Intelligence | FC-009 | missing vote neutral | planned |
| FC-011 | Subscription, ads, pricing insights | Monetization + Security | FC-003 | verified adult-only activation | planned |
| FC-012 | Notifications + privacy controls | Notifications + Privacy | FC-003 | opt-out and deletion pass | planned |
| FC-013 | Screen-by-screen visual QA | Design + QA | FC-005…012 | approved reference and screenshot test | planned |
| FC-014 | Staging beta and release gates | Orchestrator | all P0/P1 | signed checklist | planned |

## Active file ownership (2026-11-07)

- `flutter_foundation`: root Flutter configuration, `lib/**`, `test/**`, `.github/workflows/**`, `.gitignore` for FC-001.
- `database_security`: `supabase/migrations/**`, `supabase/tests/**` for FC-002. Sole migration owner.
- `allergen_safety`: `safety_engine/**` for FC-004 deterministic safety library. Backend integration follows FC-002 review.
- Orchestrator: `docs/orchestration/TASK_BOARD.md`, manifest updates, review, integration and commits.

The workspace began with only `docs/` and no Git repository. A local baseline repository was initialized. Managed worktree paths are outside the writable sandbox, so workers share this checkout with disjoint file ownership; the orchestrator will commit and review scopes separately. No release or production approval has been granted.

## First-wave evidence and remaining gates

- FC-001: Flutter 3.47.7 / Dart 3.13.5 scaffold, Android/iOS shells, Riverpod/GoRouter bootstrap, theme, one widget smoke test and CI workflow authored. Local `flutter analyze` exited 0 and `flutter test` exited 0 (1 test). CI has not run remotely; auth and product flows remain.
- FC-002: identity/circle/managed-minor migration and adversarial SQL tests drafted. Tests have **not run** because the Docker daemon is unavailable and Supabase CLI telemetry writes are blocked in this sandbox. Security review and live RLS test execution remain gates.
- FC-004: standalone Dart safety engine and known/unknown allergen cases drafted. `dart analyze lib test` exited 0 and `dart run test/safety_engine_test.dart` exited 0. Backend integration, trusted ingredient provenance, and end-to-end checks remain gates.
- No remote Git repository or pull request/CI review target is configured in this workspace.
