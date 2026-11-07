# Execution roadmap — 20 working/calendar days target (aggressive)

A 20-day target is appropriate for a constrained internal beta **if** design decisions, team capacity, API access and store enrollment are ready; it is not a guarantee of store approval, legal compliance or production-grade autonomous release.

| Days | Primary deliverables | Exit gates |
|---|---|---|
| 1–2 | Repo, CI, agent framework, data contracts, tokenized design system, approvals | Builds locally; test harness, RLS policy baseline |
| 3–5 | Auth, create/join circle, household & child profiles, onboarding | Adult/child role tests, onboarding accepts minimal data |
| 6–9 | Recipe catalog, ingredient/allergen system, AI adapter, week planner | Unsafe recipes fail closed; plan unit tests |
| 10–12 | Budgets/SNAP manual cycle, grocery lists, pantry/drinks, shopping cadence | Quantity, prices and uncertainty correct |
| 13–15 | Family voting, kid mode, Bingo + Roulette, adult-only billing stub | Minor commerce inaccessible; circle permissions |
| 16–17 | Explicit feedback, simple recommender, learned consumption, notifications | Missed vote neutral; privacy reset functions work |
| 18–19 | Security, accessibility, E2E, performance and visual QA | Zero critical findings, core scenarios green |
| 20 | Staging beta freeze, seed sample data, issue triage, release candidate | Human launch review; do NOT auto-publish |

## Gate for public launch
Legal review for minors and SNAP claims, privacy terms, image rights, subscription provider/store-policy review, penetration review, observed app stability, app-store review. If any fails, ship staging beta only.
