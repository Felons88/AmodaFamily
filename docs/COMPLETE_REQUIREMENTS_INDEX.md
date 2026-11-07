# COMPLETE REQUIREMENTS INDEX — v2.0

This is an **implementation-specification inventory**. The presence of a document does not mean its corresponding code, high-fidelity PNG or external integration has been implemented.

## Reading and authority order

1. Read `AGENTS.md` and `BUILD_BIBLE.md` for non-negotiable constraints.
2. Read `DECISIONS.md` and `orchestration/ADRS/` for reversible choices.
3. Read `contracts/`, `database/`, `intelligence/` and `security/` before executing functionality.
4. Read the exact screen and game files before a UI implementation.
5. Read `monetization/` before wiring payment or ad SDK.
6. Consult `manifest.json` for file existence and checksum; avoid using missing files as if they exist.

## Required launch gates

1. No cross-tenant data exposure.
2. No child paywall or ads.
3. Hard allergy validation outside LLM.
4. Correct source-labeled photos and prices.
5. Household-wide verified entitlements.
6. No EBT Edge credentials.
7. Consent/correct/delete learning data.
8. Complete basic free service without ad dependency.
9. App store billing compliance.
10. Manual owner approval of public launch.

## All authored specification files

### AGENTS.md (1 Markdown documents)

- `AGENTS.md` — AGENTS.md — instructions for all Codex/Devin agents

### BUILD_BIBLE.md (1 Markdown documents)

- `BUILD_BIBLE.md` — Family Circle — definitive implementation contract

### DECISIONS.md (1 Markdown documents)

- `DECISIONS.md` — Architectural decision log

### README.md (1 Markdown documents)

- `README.md` — Family Circle — autonomous build handoff v1.0

### agents (20 Markdown documents)

- `agents/ACCESSIBILITY_ENGINEER.md` — Accessibility Engineer
- `agents/ALLERGEN_SAFETY_ENGINEER.md` — Allergen Safety Engineer
- `agents/DATA_ANALYTICS_ENGINEER.md` — Data Analytics Engineer
- `agents/DESIGN_DIRECTOR.md` — Soul: Design Director
- `agents/DEVOPS_RELEASE_ENGINEER.md` — Soul: Devops Release Engineer
- `agents/FLUTTER_ENGINEER.md` — Soul: Flutter Engineer
- `agents/GAMEPLAY_ENGINEER.md` — Gameplay Engineer
- `agents/HOUSEHOLD_INTELLIGENCE_ARCHITECT.md` — Soul: Household Intelligence Architect
- `agents/IMAGE_VALIDATION_ENGINEER.md` — Image Validation Engineer
- `agents/INTEGRATION_ENGINEER.md` — Integration Engineer
- `agents/MONETIZATION_ENGINEER.md` — Monetization Engineer
- `agents/NOTIFICATION_ENGINEER.md` — Notification Engineer
- `agents/ORCHESTRATOR.md` — Soul: Lead Orchestrator / Principal Engineer
- `agents/PRIVACY_CHILD_SAFETY_REVIEWER.md` — Privacy Child Safety Reviewer
- `agents/PRODUCT_OWNER_PROXY.md` — Product Owner Proxy
- `agents/QA_AUTOMATION_ENGINEER.md` — Soul: Qa Automation Engineer
- `agents/RECIPE_CONTENT_CURATOR.md` — Soul: Recipe Content Curator
- `agents/SAFETY_SECURITY_REVIEWER.md` — Soul: Safety Security Reviewer
- `agents/SUBSCRIPTION_ENGINEER.md` — Soul: Subscription Engineer
- `agents/SUPABASE_ENGINEER.md` — Soul: Supabase Engineer

### architecture (8 Markdown documents)

- `architecture/API_CONTRACT.md` — API patterns
- `architecture/ARCHITECTURE.md` — Technical architecture
- `architecture/ASSET_PIPELINE.md` — Image and recipe assets
- `architecture/DATABASE.md` — Database contracts (Postgres/Supabase)
- `architecture/FLUTTER_STRUCTURE.md` — Flutter structure
- `architecture/OBSERVABILITY.md` — Observability
- `architecture/OFFLINE_SYNC.md` — Offline first decisions
- `architecture/SUPABASE_DEPLOYMENT.md` — Supabase deployment

### contracts (21 Markdown documents)

- `contracts/DOMAIN_MODEL.md` — Domain model
- `contracts/ENTITLEMENTS.md` — Entitlements
- `contracts/ERROR_CODES.md` — Error vocabulary
- `contracts/EVENT_TAXONOMY.md` — Event semantics
- `contracts/FOOD_AND_BUDGET_UNITS.md` — Units and money
- `contracts/endpoints/v1-billing-webhook.md` — POST /v1/billing/webhook
- `contracts/endpoints/v1-budget-cycles.md` — POST /v1/budget-cycles
- `contracts/endpoints/v1-circles-circleid-members.md` — POST /v1/circles/:circleId/members
- `contracts/endpoints/v1-circles.md` — POST /v1/circles
- `contracts/endpoints/v1-entitlements-checkout.md` — POST /v1/entitlements/checkout
- `contracts/endpoints/v1-feedback.md` — POST /v1/feedback
- `contracts/endpoints/v1-pantry-adjust.md` — POST /v1/pantry/adjust
- `contracts/endpoints/v1-plans-generate.md` — POST /v1/plans/generate
- `contracts/endpoints/v1-plans-planid-approve.md` — POST /v1/plans/:planId/approve
- `contracts/endpoints/v1-privacy-delete.md` — POST /v1/privacy/delete
- `contracts/endpoints/v1-privacy-export.md` — POST /v1/privacy/export
- `contracts/endpoints/v1-recipes.md` — GET /v1/recipes
- `contracts/endpoints/v1-revenue-recommendations.md` — GET /v1/revenue/recommendations
- `contracts/endpoints/v1-shopping-trips.md` — POST /v1/shopping-trips
- `contracts/endpoints/v1-vote-rounds-id-vote.md` — POST /v1/vote-rounds/:id/vote
- `contracts/endpoints/v1-vote-rounds.md` — POST /v1/vote-rounds

### design_system (1 Markdown documents)

- `design_system/DESIGN_SYSTEM.md` — Visual system and imagery rules

### games (19 Markdown documents)

- `games/GAME_ENGINE_CORE.md` — Game platform
- `games/GAME_REWARDS.md` — Virtual rewards
- `games/GAME_SCHEDULER.md` — Game frequency and quotas
- `games/budget-hero.md` — Budget Hero — executable game contract
- `games/build-a-meal.md` — Build a Meal — executable game contract
- `games/cooking-together.md` — Cooking Together — executable game contract
- `games/dinner-showdown.md` — Dinner Showdown — executable game contract
- `games/family-food-quest.md` — Family Food Quest — executable game contract
- `games/family-restaurant.md` — Family Restaurant — executable game contract
- `games/food-trivia.md` — Food Trivia — executable game contract
- `games/fridge-rescue.md` — Fridge Rescue — executable game contract
- `games/grocery-detective.md` — Grocery Detectives — executable game contract
- `games/junior-chef.md` — Junior Chef Academy — executable game contract
- `games/leftover-legends.md` — Leftover Legends — executable game contract
- `games/mystery-recipe.md` — Mystery Recipe — executable game contract
- `games/pantry-bingo.md` — Pantry Bingo — executable game contract
- `games/price-guess.md` — Guess the Grocery Price — executable game contract
- `games/recipe-roulette.md` — Recipe Roulette — executable game contract
- `games/world-food.md` — World Food Adventure — executable game contract

### intelligence (15 Markdown documents)

- `intelligence/ALGORITHM_REGISTRY.md` — Algorithm registry
- `intelligence/BASKET_OPTIMIZER.md` — Shopping optimizer
- `intelligence/BEVERAGE_MODEL.md` — Beverage planner
- `intelligence/CATALOG_DEDUP.md` — Shared catalog dedup
- `intelligence/CONSUMPTION_FORECAST.md` — Consumption engine
- `intelligence/FEEDBACK_AND_NONVOTES.md` — Missing votes and feedback
- `intelligence/IMAGE_MATCH_VALIDATION.md` — Visual recipe assurance
- `intelligence/MEAL_PLAN_OPTIMIZER.md` — Meal optimizer
- `intelligence/NOTIFICATION_POLICY.md` — Notification optimizer
- `intelligence/PREFERENCE_LEARNING.md` — Preference learning
- `intelligence/PSEUDOCODE_AND_GOLDEN_CASES.md` — Intelligence reference algorithms and golden fixtures
- `intelligence/RECIPE_RANKER.md` — Recipe ranker
- `intelligence/RECOMMENDER.md` — Household Intelligence Engine v1: algorithms and evaluation
- `intelligence/SAFETY_CONSTRAINTS.md` — Safety algorithms
- `intelligence/VOTING_AND_FAIRNESS.md` — Voting fairness

### monetization (6 Markdown documents)

- `monetization/ADS_ENGINE.md` — Ad policy and revenue
- `monetization/AFFILIATES.md` — Affiliate model
- `monetization/BILLING_LIFECYCLE.md` — Billing lifecycle
- `monetization/EXPERIMENTS.md` — Experiments
- `monetization/PRICING_ENGINE.md` — Pricing intelligence
- `monetization/UNIT_ECONOMICS.md` — Unit economics

### operations (6 Markdown documents)

- `operations/20_DAY_EXECUTION.md` — 20-day execution
- `operations/AGENT_HANDOFF.md` — Agent handoff protocol
- `operations/CI_CD.md` — Delivery pipeline
- `operations/ENVIRONMENT_VARIABLES.md` — Environment matrix
- `operations/INCIDENT_RESPONSE.md` — Incident and rollback
- `operations/RELEASE_CHECKLIST.md` — Release readiness

### orchestration (3 Markdown documents)

- `orchestration/ADRS/ADR-001-initial-decisions.md` — ADR-001 initial technical decisions
- `orchestration/EXECUTION_RUNBOOK.md` — Orchestrator execution runbook
- `orchestration/TASK_BOARD.md` — Work board — planned, not completed

### product (10 Markdown documents)

- `product/ACCESSIBILITY.md` — Accessibility
- `product/ANALYTICS_AND_METRICS.md` — Metrics
- `product/COPY_AND_CONTENT.md` — Voice and messaging
- `product/FEATURE_FLAGS.md` — Feature flags
- `product/JOURNEYS.md` — Journey maps
- `product/LOCALIZATION.md` — Localization
- `product/NOTIFICATIONS.md` — Notifications
- `product/ONBOARDING.md` — Progressive onboarding
- `product/PERSONAS.md` — Personas
- `product/VISION_AND_POSITIONING.md` — Vision and competitive advantage

### prompts (5 Markdown documents)

- `prompts/CODEX_MASTER_PROMPT.md` — Ready-to-copy Codex master prompt
- `prompts/DESIGN_AGENT_PROMPT.md` — Design agent production prompt
- `prompts/DEVIN_MASTER_PROMPT.md` — Ready-to-copy Devin master prompt
- `prompts/QA_AGENT_PROMPT.md` — QA agent prompt
- `prompts/UNIFIED_AUTONOMOUS_START.md` — Universal kickoff — paste into Codex or Devin

### qa (27 Markdown documents)

- `qa/PERFORMANCE_SLOS.md` — Performance targets
- `qa/SECURITY_TEST_MATRIX.md` — Security QA
- `qa/TEST_STRATEGY.md` — Test strategy
- `qa/USER_ACCEPTANCE.md` — User acceptance
- `qa/fixtures/adult-entitlement.md` — Fixture adult-entitlement: one adult upgrades circle
- `qa/fixtures/affiliate-safety.md` — Fixture affiliate-safety: affiliate payout cannot reorder against safety
- `qa/fixtures/allergy-known.md` — Fixture allergy-known: kiwi allergy blocks kiwi smoothie
- `qa/fixtures/allergy-unknown.md` — Fixture allergy-unknown: unknown premix composition
- `qa/fixtures/benefit-manual.md` — Fixture benefit-manual: EBT manual amount used no credentials
- `qa/fixtures/budget-infeasible.md` — Fixture budget-infeasible: budget lower than feasible weekly food costs
- `qa/fixtures/child-ad.md` — Fixture child-ad: child sees no sponsored recipe
- `qa/fixtures/child-notification.md` — Fixture child-notification: minor notifications respect guardian opt-in
- `qa/fixtures/child-paywall.md` — Fixture child-paywall: child opens adult subscription route
- `qa/fixtures/cross-circle.md` — Fixture cross-circle: user reads other circle
- `qa/fixtures/duplicate-vote.md` — Fixture duplicate-vote: retry vote does not duplicate
- `qa/fixtures/expired-vote.md` — Fixture expired-vote: late vote fails
- `qa/fixtures/food-expiry.md` — Fixture food-expiry: expired leftovers never used as meal input
- `qa/fixtures/image-protein.md` — Fixture image-protein: chicken enchilada shrimp photo mismatch
- `qa/fixtures/missing-photo.md` — Fixture missing-photo: failed image validation shows placeholder
- `qa/fixtures/nonvote-neutral.md` — Fixture nonvote-neutral: unopened vote ignored
- `qa/fixtures/offline-conflict.md` — Fixture offline-conflict: stale shopping list does not overwrite updated server
- `qa/fixtures/pantry-stock.md` — Fixture pantry-stock: weekly milk need subtracts inventory
- `qa/fixtures/price-stale.md` — Fixture price-stale: old merchant price not live
- `qa/fixtures/privacy-ad.md` — Fixture privacy-ad: SNAP status not used for ad selection
- `qa/fixtures/privacy-delete.md` — Fixture privacy-delete: removed preference not used
- `qa/fixtures/purchase-double.md` — Fixture purchase-double: duplicate checkout webhook ignored
- `qa/fixtures/solo-game.md` — Fixture solo-game: one-person vote does not stall

### roadmap (1 Markdown documents)

- `roadmap/20_DAY_PLAN.md` — Execution roadmap — 20 working/calendar days target (aggressive)

### security (6 Markdown documents)

- `security/ABUSE_CASES.md` — Abuse protections
- `security/CHILD_PRIVACY.md` — Minor safeguards
- `security/DATA_CLASSIFICATION.md` — Data classification
- `security/PRIVACY_RETENTION.md` — Retention
- `security/SECURITY_ARCHITECTURE.md` — Security boundaries
- `security/THREAT_MODEL.md` — Security, privacy and safety requirements

### storyboard (41 Markdown documents)

- `storyboard/README.md` — Screen-by-screen delivery
- `storyboard/adult/ADULT-001-home.md` — ---
- `storyboard/adult/ADULT-002-week-plan.md` — ---
- `storyboard/adult/ADULT-003-recipe-detail.md` — ---
- `storyboard/adult/ADULT-004-grocery-list.md` — ---
- `storyboard/adult/ADULT-005-pantry-scanner.md` — ---
- `storyboard/adult/ADULT-006-drinks.md` — ---
- `storyboard/adult/ADULT-007-circle-members.md` — ---
- `storyboard/adult/ADULT-008-spending.md` — ---
- `storyboard/adult/ADULT-009-shopping-calendar.md` — ---
- `storyboard/adult/ADULT-010-family-votes.md` — ---
- `storyboard/adult/ADULT-011-food-insights.md` — ---
- `storyboard/adult/ADULT-012-recipe-vault.md` — ---
- `storyboard/adult/ADULT-013-subscriptions.md` — ---
- `storyboard/adult/ADULT-014-privacy-controls.md` — ---
- `storyboard/games/GAME-001-dinner-showdown.md` — ---
- `storyboard/games/GAME-002-pantry-bingo.md` — ---
- `storyboard/games/GAME-003-recipe-roulette.md` — ---
- `storyboard/games/GAME-004-price-guess.md` — ---
- `storyboard/games/GAME-005-fridge-rescue.md` — ---
- `storyboard/games/GAME-006-build-a-meal.md` — ---
- `storyboard/games/GAME-007-mystery-recipe.md` — ---
- `storyboard/games/GAME-008-world-food.md` — ---
- `storyboard/games/GAME-009-family-restaurant.md` — ---
- `storyboard/games/GAME-010-budget-hero.md` — ---
- `storyboard/kids/KIDS-001-kids-home.md` — ---
- `storyboard/kids/KIDS-002-meal-voting.md` — ---
- `storyboard/kids/KIDS-003-food-quest.md` — ---
- `storyboard/kids/KIDS-004-badge-vault.md` — ---
- `storyboard/kids/KIDS-005-junior-chef.md` — ---
- `storyboard/kids/KIDS-006-food-passport.md` — ---
- `storyboard/onboarding/ONB-001-welcome.md` — ---
- `storyboard/onboarding/ONB-002-account.md` — ---
- `storyboard/onboarding/ONB-003-household.md` — ---
- `storyboard/onboarding/ONB-004-food-needs.md` — ---
- `storyboard/onboarding/ONB-005-budget-benefits.md` — ---
- `storyboard/onboarding/ONB-006-first-plan.md` — ---
- `storyboard/shared/SHARED-001-notifications.md` — ---
- `storyboard/shared/SHARED-002-feedback.md` — ---
- `storyboard/shared/SHARED-003-shopping-review.md` — ---
- `storyboard/shared/SHARED-004-offline-error.md` — ---

### testing (1 Markdown documents)

- `testing/ACCEPTANCE.md` — Automated acceptance suite

## Per-screen execution and evidence checklist

### ONB-001 — Welcome

- Read `storyboard/onboarding/ONB-001-welcome.md` for the screen contract.
- Visual reference: `storyboard/onboarding/ONB-001-welcome.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ONB-002 — Account

- Read `storyboard/onboarding/ONB-002-account.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ONB-003 — Household

- Read `storyboard/onboarding/ONB-003-household.md` for the screen contract.
- Visual reference: `storyboard/onboarding/ONB-003-household.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ONB-004 — Food Needs

- Read `storyboard/onboarding/ONB-004-food-needs.md` for the screen contract.
- Visual reference: `storyboard/onboarding/ONB-004-food-needs.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ONB-005 — Budget Benefits

- Read `storyboard/onboarding/ONB-005-budget-benefits.md` for the screen contract.
- Visual reference: `storyboard/onboarding/ONB-005-budget-benefits.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ONB-006 — First Plan

- Read `storyboard/onboarding/ONB-006-first-plan.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-001 — Home

- Read `storyboard/adult/ADULT-001-home.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-001-home.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-002 — Week Plan

- Read `storyboard/adult/ADULT-002-week-plan.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-002-week-plan.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-003 — Recipe Detail

- Read `storyboard/adult/ADULT-003-recipe-detail.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-003-recipe-detail.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-004 — Grocery List

- Read `storyboard/adult/ADULT-004-grocery-list.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-004-grocery-list.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-005 — Pantry Scanner

- Read `storyboard/adult/ADULT-005-pantry-scanner.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-005-pantry-scanner.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-006 — Drinks

- Read `storyboard/adult/ADULT-006-drinks.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-006-drinks.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-007 — Circle Members

- Read `storyboard/adult/ADULT-007-circle-members.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-007-circle-members.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-008 — Spending

- Read `storyboard/adult/ADULT-008-spending.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-009 — Shopping Calendar

- Read `storyboard/adult/ADULT-009-shopping-calendar.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-010 — Family Votes

- Read `storyboard/adult/ADULT-010-family-votes.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-011 — Food Insights

- Read `storyboard/adult/ADULT-011-food-insights.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-012 — Recipe Vault

- Read `storyboard/adult/ADULT-012-recipe-vault.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-013 — Subscriptions

- Read `storyboard/adult/ADULT-013-subscriptions.md` for the screen contract.
- Visual reference: `storyboard/adult/ADULT-013-subscriptions.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### ADULT-014 — Privacy Controls

- Read `storyboard/adult/ADULT-014-privacy-controls.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-001 — Kids Home

- Read `storyboard/kids/KIDS-001-kids-home.md` for the screen contract.
- Visual reference: `storyboard/kids/KIDS-001-kids-home.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-002 — Meal Voting

- Read `storyboard/kids/KIDS-002-meal-voting.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-003 — Food Quest

- Read `storyboard/kids/KIDS-003-food-quest.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-004 — Badge Vault

- Read `storyboard/kids/KIDS-004-badge-vault.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-005 — Junior Chef

- Read `storyboard/kids/KIDS-005-junior-chef.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### KIDS-006 — Food Passport

- Read `storyboard/kids/KIDS-006-food-passport.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-001 — Dinner Showdown

- Read `storyboard/games/GAME-001-dinner-showdown.md` for the screen contract.
- Visual reference: `storyboard/games/GAME-001-dinner-showdown.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-002 — Pantry Bingo

- Read `storyboard/games/GAME-002-pantry-bingo.md` for the screen contract.
- Visual reference: `storyboard/games/GAME-002-pantry-bingo.png`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-003 — Recipe Roulette

- Read `storyboard/games/GAME-003-recipe-roulette.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-004 — Price Guess

- Read `storyboard/games/GAME-004-price-guess.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-005 — Fridge Rescue

- Read `storyboard/games/GAME-005-fridge-rescue.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-006 — Build A Meal

- Read `storyboard/games/GAME-006-build-a-meal.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-007 — Mystery Recipe

- Read `storyboard/games/GAME-007-mystery-recipe.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-008 — World Food

- Read `storyboard/games/GAME-008-world-food.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-009 — Family Restaurant

- Read `storyboard/games/GAME-009-family-restaurant.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### GAME-010 — Budget Hero

- Read `storyboard/games/GAME-010-budget-hero.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### SHARED-001 — Notifications

- Read `storyboard/shared/SHARED-001-notifications.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### SHARED-002 — Feedback

- Read `storyboard/shared/SHARED-002-feedback.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### SHARED-003 — Shopping Review

- Read `storyboard/shared/SHARED-003-shopping-review.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.

### SHARED-004 — Offline Error

- Read `storyboard/shared/SHARED-004-offline-error.md` for the screen contract.
- Visual reference: `NOT APPROVED: create individual high-fidelity PNG`.
- Flutter: typed route and widget with loading, empty, error, offline and real-data states.
- Backend: RLS and membership validation before any private data access.
- Safety: do not expose unverified ingredients as allergen safe.
- Learning: only explicit feedback modifies taste; missing vote stays neutral.
- Privacy: adult and child layouts are server-role gated, no child commerce/ads.
- QA: test 360×800 and 390×844, text scale 200%, TalkBack and network outage.
- Evidence: screenshot/commit/test output recorded; state remains planned until executed.
