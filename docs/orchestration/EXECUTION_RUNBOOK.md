# Orchestrator execution runbook

## Preflight

- Verify manifest checksum coverage; if any file missing regenerate and stop claiming completeness.
- Validate repository: `flutter --version`, `dart --version`, `supabase --version`, `git status`, SQL linter, secrets placeholders and `README` start path.
- Establish shared pull request workflow and branch protections; update task board every merge.
- Prioritize P0: role privacy, allergy validator, affordable first plan, core app. P1: games+learning, revenue. P2: advanced OCR and integrations.

## Task granularity

Each ticket references one or more specs; must include screen ID/game ID, backend tables, API route, edge cases, QA evidence, assigned worker, exit criteria and changelog. No worker owns the whole repo except orchestrator merging changes. At most one owner of migrations at a time.

## Internal build loop

1. Select unblocked ticket. 2. Read all referenced specs. 3. Draft implementation plan. 4. Implement. 5. Run local tests. 6. Commit in branch. 7. Cross-review security/safety. 8. Merge. 9. Update manifest and task board. 10. Re-run integration regression.

## Human approval gates

H1 final high-fidelity art and usage rights; H2 production credentials; H3 live pricing/ads and payment provider; H4 children/privacy legal review; H5 production deployment/app store submission. Development and staging can proceed with placeholders and mock payment provider. Never claim H1–H5 approved without actual record.

## Evidence format

Record actual file hashes/commit ID, tests and exact command exit status; screenshot dimensions and snapshot diff; staging URL only if verified. If an agent cannot use web/services, mark integration stubbed and deliver interface contract; do not invent commercial contracts.
