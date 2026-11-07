# AGENTS.md — instructions for all Codex/Devin agents

1. Read `README.md`, `BUILD_BIBLE.md`, `DECISIONS.md`, `manifest.json`, `contracts/DOMAIN_MODEL.md`, `security/SECURITY_ARCHITECTURE.md`, then relevant screen/game/feature files before editing.
2. The Bible is specifications. Do not report a Flutter app, backend or media as implemented unless code exists and tests were executed. Do not claim PNG is approved if its status is directional or schematic.
3. Start each task from `orchestration/TASK_BOARD.md`, lock file/feature ownership and isolate work in branches. Integrate via review PR and CI.
4. Resolve ambiguity by hierarchy: safety/child/privacy > schema and invariant > feature contract > screen contract > design. If genuinely undecided, create an ADR in `orchestration/ADRS/` and request owner review for irreversible decisions.
5. All database writes use explicit RLS/server authorization. All client actions are typed. Secrets never committed. Receipt/ads/AI and child-state logic server-gated.
6. Test missing votes neutral, allergies fail-closed, catalog images accurately mapped, price estimate provenance and adult-only commerce across every relevant feature.
7. Do not bypass human release gates. Implement autonomously within repository, make clear blocker tickets when external credentials, licensing, regulated-data access or legal signoff is required.
8. Definition of done per feature: code + typed contract + migrations/policies + fixtures + tests + screen shots (where relevant) + accessibility + cost/observability notes + reviewer signoff.
9. Manifest is generated from actual files with SHA256, scope and status. No silent omissions, no pretend fully approved high-fidelity mockups.
10. Begin with `prompts/UNIFIED_AUTONOMOUS_START.md`; continue to follow `orchestration/EXECUTION_RUNBOOK.md`.
