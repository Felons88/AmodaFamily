# Recipe Roulette — executable game contract

## Player-facing objective

Server seeds a spin among only verified safe feasible recipes, weighted modestly for diversity, outcome disclosed as random selection from eligible pool.

## Participants and restrictions

Support solo mode, 2-person pair, larger circle, limited literacy, and adult-managed profiles. The `circle_id` and active membership are resolved server-side. All underlying recipes are filtered against the eaters' hard allergen rules and the current budget before appearing. Children receive no ad, upgrade, cash prize, or unsolicited contact surfaces.

## State machine

`not_started -> available -> started -> in_progress -> completed -> awarded` with `paused`, `canceled`, `expired`, `blocked_safety` branches. Server owns state, expiry, eligible user IDs and awards. `game_session_id` idempotent; allow reconnect to saved state when possible.

## Scoring and resolution

No eligible recipe: disable spin and offer filter relaxation only for non-safety constraints.

Points are bounded (0–100 per session), deterministic from recorded actions, awarded only once via unique `(circle_id,session_id,reward_type)`. No randomized paid prizes and no penalty for missed days. For children, do not rank users against strangers.

## Free/premium and quotas

Free 3 spins/circle/week; premium expanded; no purchase prompt to minors. Quota is enforced server-side and windowed by circle; child sees only 'available again' timing. Paid entitlement is inherited by circle, not individually charged.

## Data and learning signals

Events: `roulette_started, roulette_result_presented, roulette_accepted, roulette_rerolled`. Separate objective completion from taste evaluation. A participant not opening the game conveys no dislike. Adult feedback may amend recommendations; game play is *not* a substitute for a dietary preference survey. Store only the event fields whitelisted by `contracts/EVENT_TAXONOMY.md`.

## UI sequence

1. Game lobby: safe photo/illustration, short purpose, frequency remaining without purchase CTA for minors.
2. Instructions: one short example, accessibility option.
3. Active play: clear primary action, progress and one-tap leave.
4. Results: factual explanation, safe next action, participation badge.
5. Adult approval if action changes meals, grocery list or privacy setting.

## Edge cases

Offline state: read cached session, queue only permitted low-risk action; expired ballot/session cannot be submitted; duplicate requests idempotent; cross-circle join denied; no eligible recipes -> show safe alternative; zero votes -> no inferred dislike; all members absent -> pause or close without penalty.

## Server contracts

`POST /v1/games/recipe-roulette/sessions` (adult initiated where needed), `GET /v1/games/sessions/:id`, `POST /v1/games/sessions/:id/actions`, `POST /v1/games/sessions/:id/finish`. Validate action schema, current state, active membership, quotas, role and version; audit approvals. Return typed errors.

## Tests

- [ ] Eligible safe candidates only; unknown allergens blocked.
- [ ] Solo and 12-member circles produce usable experience.
- [ ] All game transitions deterministic and rollback-safe.
- [ ] One member cannot cast for another; no duplicate award.
- [ ] Children receive no commerce/ad surfaces in any state.
- [ ] Network loss and resumed state do not corrupt results.
- [ ] Expiry/absence is neutral for preference learning.
