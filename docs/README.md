# Family Circle Autonomous Build Bible v2.0

**Handoff status:** comprehensive implementation specifications and paired screen reference assets; **not** a runnable Flutter application, verified production service, approved high-fidelity complete screen set or active agent execution.

Start here: `prompts/UNIFIED_AUTONOMOUS_START.md`, then `AGENTS.md`, `BUILD_BIBLE.md`, `COMPLETE_REQUIREMENTS_INDEX.md` and `manifest.json`. Codex/Devin can clone/import this package and execute the staged plan without relying on this conversation for requirements.

## Package map

- `storyboard/` — 40 Markdown screen contracts + 40 paired PNGs (15 crops, 25 explicitly schematic) plus CSV status register.
- `games/` — 16 distinctive game implementations and server-first rewards/frequency contracts.
- `intelligence/` — meal ranking, allergies, optimization, voting, nonvotes, forecasts, image verification and deterministic algorithm pseudocode.
- `monetization/` — adult-only contextual ad policy, household subscriptions, competitor pricing recommendations, economics and experiments.
- `contracts/` — domain and event contracts, 16 endpoint contracts and JSON schemas.
- `database/migrations/` — initial migration/RLS baseline; must be security reviewed, extended and tested before deployment.
- `security/`, `qa/`, `architecture/`, `product/`, `operations/` — substantive requirements and review gates.
- `agents/` — scoped agents, roles, safety authority and no-self-approval limits.
- `orchestration/` — task board, runbook and ADR record.

## Limits / decisions requiring human review

- Production account credentials, app store billing configuration, legal child privacy/advertising assessment, food safety/medical claims, supplier photo licenses and publication approval.
- Online competitor data/live grocery pricing and supported EBT integrations are not bundled and must not be fabricated.
- Price suggestions are not a verified competitive benchmark. No prices may automatically change.
- 20 days is a constrained MVP staging target, not a guarantee.

## Verification

Read `VERIFICATION_REPORT.md` and `manifest.json`: file counts, SHA256 and pairing checks are calculated from actual package contents. Run `python3 verify_package.py` after modifying files and regenerate manifest when intentionally updating the package.
