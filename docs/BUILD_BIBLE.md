# Family Circle — definitive implementation contract

**Status:** Build specification, not an implemented application. Conflicting instructions: privacy/child safety > safety validation > server-authorized data > product acceptance criteria > visual direction. Production and legal/compliance releases need owner signoff.

## Project identity and product boundaries

- Product: Family Circle; Flutter client, Supabase Postgres/Auth/Storage/Edge Functions backend, REST/RPC contracts, push delivered through explicitly configured provider.
- Audience: solo adults, couples, mixed-age households, parents and children; SNAP/EBT and cash budgets, or both. The household is the subscription entitlement boundary.
- Free tier must provide a complete useful weekly plan, allergy safety, grocery totals, budget tracking, pantry manual entry, limited family voting and challenges; paid tiers purchase convenience/capacity rather than basic nutrition or safety.
- No screen may imply EBT balance sync, exact retailer stock, real-time grocery pricing, allergy guarantees, or complete nutrition verification without verified provenance and integration.
- EBT Edge: do not request, scrape, store card numbers, logins or PINs. The v1 benefit amount and deposit date are manual. Any future read-only integration requires a supported authorized provider, security and compliance review.
- Age: 18+ recognized for purchase/admin authorization, but self-reported age is not a substitute for reliable adult authorization where needed. Children's profiles are parent-managed; no unsolicited children-to-stranger interaction, targeted advertising, commercial prompts, or public leaderboards.
- Single adults can join all solo activities; multiplayer rounds adapt to one-person mode, abstentions and household sizes 1–12+.

## System-of-record and source of truth

1. `DECISIONS.md` captures product defaults with owner review requirement.
2. `contracts/` specifies durable schemas, semantics and error responses.
3. `database/migrations/` defines enforceable security, constraints and indexes.
4. `storyboard/**/<screen_id>-<slug>.md` is implementation contract for that screen; companion PNG is a visual reference with explicit state tag.
5. `games/` is behavior contract for that game; no generic implementations may replace individual win conditions and event models.
6. `intelligence/` defines rule-based algorithms, metrics and tests; do not claim trained models before sufficient data and validation.
7. `agents/` specifies responsibility and write scope; orchestrator owns integration and release gate.
8. `manifest.json` is generated inventory and cannot be silently edited to hide missing components.

## Non-negotiable cross-cutting invariants

- A member may belong to circles through a membership table; every circle-scoped write checks active membership and role using server-side policy; no client-trusted circle_id ownership.
- Under-18 participants cannot see pricing, purchase prompts, external ads, sponsor messaging, monetary amounts designated private, or adult analytics. Permissions enforced in API and RLS.
- Physical-food allergens are a hard eligibility constraint: uncertain ingredient composition, unknown packaged-food cross-contact and unverified substitutions must not be represented as safe. Never let an LLM declare an unknown ingredient allergen-free.
- Shopping cost is an estimate tagged `source`, `observed_at`, `region`, `confidence`, `currency`, not an invented exact live local price. SNAP eligibility displayed as provisional unless trustworthy product evidence exists.
- Any shared recipe must be deduplicated, ingredient-validated, image-provenance-checked and explicitly approved for catalog promotion. Private notes, budgets and child behavioral histories never migrate with it.
- Absence of voting or interactions is *missing data*, not negative taste. Negative signals require an explicit reason or corrective adult confirmation.
- All personalization has visibility, correction, pause and deletion controls. Child activity learning only for requested functionality, never ad profiling.
- Every external integration uses named data-processing purpose, secret in protected backend and explicit failure mode. Fallbacks must be functional and honestly labeled.
- Never charge an adult or change prices on the basis of a recommendation model decision. Billing authority resides in purchase platform/server verification.
- At-rest encryption by managed provider and TLS 1.2+ in transit; highly sensitive data minimization, application-level envelope encryption where justified, versioned keys and audited access. Never claim blanket end-to-end encryption if server computes on the data.

## User journey and acceptance baseline

`welcome -> adult auth -> household creation -> member count and age bands -> allergies and required restrictions -> budget and benefit cadence optional -> first week plan -> review meal eligibility -> approve -> consolidated grocery list -> trip log -> preference feedback`. Optional member invites, receipt scanning, addresses, diagnostics and exact birthdates are deferred; age band is enough for meal serving estimates. Ask consent for personalization with a concise explanation, independently from mandatory processing.

## Personalization data ontology

Record `event_id, event_type, actor_profile_id (nullable), circle_id, object_type, object_id, occurred_at, schema_version, consent_basis, source, metadata_whitelist` for meal viewed, selected, cooked, rated, skipped-with-reason, explicit dislike, substitution accepted, grocery purchased, amount consumed estimate, game participation, notification opt-in, and plan regenerated. Never log medical narrative, raw receipts, PINs, complete chat prompts, or children's detailed timeline to analytics. Persist raw events no longer than documented retention policy. Derived model state should expose provenance, confidence and last_updated.

## Ranking pipeline

First resolve circle and eaters -> apply structural constraints (allergen exclusions, age, dietary rules, serving feasibility, budget feasibility, pantry handling) -> score safe viable catalog recipes -> enforce variety and prep time -> assemble menu across days with ingredient reuse -> price basket with confidence -> obtain adult approval -> store why-this-meal explanations. If too few safe candidates, show actionable error and request user clarification instead of unsafe completion.

## Productized monetization policies

Proposed initial tiers for testing: Free $0; Plus $3.99/month; Family Pro $6.99/month, one active entitlement per circle; actual catalog price and taxes from store/checkout provider. Price shown only in adult contexts. Free may display restrained contextual non-personalized advertisements to authenticated adults, clearly marked and never embedded to disguise paid items as allergy-verified organic results. Ads are disabled for children, on sensitive budgets/benefits/allergen screens, during food-safety instructions, and in any shared child view. No use of SNAP/EBT status, allergies, minors' behavior or financial need for targeting. Paid tiers: no ads. Keep free essential capability even if ad provider unavailable.

## Revenue analytics and experimental boundaries

Measure MRR, net subscription receipts, activation, trial-to-paid, monthly churn, acquisition source, ARPA, revenue per household, gross margin after model/image/notification/storage fees, ad fill and effective RPM, refunds and child-compliance incidents. Experiments are adult-only, randomized at circle level, avoid exploitative scarcity or withholding safety. Dynamic price analysis can suggest but NEVER automatically publish; human approves every billing change. Competitor monitoring only from lawful public pages, store metadata or approved datasets, with timestamp and evidence. Never fabricate comparable prices.

## Design principle

Professional consumer product: dark graphite surfaces, restrained accent green, accessible typography, photorealistic appropriately licensed cuisine imagery, skeletons and calm motion; no emojis, no fake food photos and no cartoonish template feel. Images are not interchangeable decorative stock. A screenshot cannot substitute for separable source assets or a functioning Flutter layout.

## Release verification

Unit, widget, integration, RLS authorization, performance, accessibility, threat model, purchase restoration, privacy deletion, offline conflict and adversarial ingredient tests must pass. Human signoff for legal privacy review (including children), payments, external media licenses and production publication. A 20-day timeline is an MVP *goal*, not a guarantee of compliance, quality or deployment.
