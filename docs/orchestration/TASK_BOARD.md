# Work board — planned, not completed

| ID | Scope | Agent | Depends on | Acceptance | State |
|---|---|---|---|---|---|
| FC-001 | Flutter workspace + CI | DevOps + Flutter | none | build/analyze passes | planned |
| FC-002 | Postgres schema + RLS | Supabase + Security | FC-001 | tenant attacks fail | planned |
| FC-003 | Adult auth + circle creation | Flutter + Supabase | FC-002 | signup/create + invited adult works | planned |
| FC-004 | Food ontology and allergen checks | Safety + Catalog | FC-002 | unknown composition denied | planned |
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
