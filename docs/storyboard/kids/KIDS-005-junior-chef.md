---
screen_id: KIDS-005
slug: junior-chef
platform: flutter_mobile
area: kids
audience: minor
visual_status: schematic_png_needs_hifi_design_approval
reference_png: KIDS-005-junior-chef.png
---

# KIDS-005 — Junior Chef

## Purpose and exact content
Cooking safety lessons, age-appropriate supervised tasks.

## Visual contract
Follow `design_system/DESIGN_SYSTEM.md`. Real licensed food/family photography when context calls for it; no emojis; no misleading or unverified meal images. Design is responsive 360–430 logical pixels with safe areas, contrast, semantics, enlarged type and clear hierarchy. A dedicated high-fidelity PNG is **missing**: design director must produce one before declaring visual fidelity done.

## Primary action
`Complete lesson`; provide confirmation, reversible change when possible, disabled/loading state and meaningful error. Navigation defined by GoRouter typed route; no dead buttons.

## Data / integrations
`game_progress`. Require authenticated server permissions as appropriate; use RLS on all circle-scoped data. Never invent real prices, verified balance, allergens, photo provenance, or entitlements.

## Learning / behavior
Learning progress only. If no explicit signal, **do not** infer dislike. Honor consent and deletion controls. Store policy_version and avoid unnecessary identifiers.

## Permissions
Intended mode: `minor`. Child mode: never render prices, financial account details, subscription routes, purchase prompts, external ads, or unapproved communication. Server must reject role-forbidden writes regardless of hidden buttons.

## States / exceptions
Loading: visible skeleton and progress; empty: helpful first action; error: retry with clear explanation; offline: cached approved content or disabled state; accessibility: labels for all meaningful images and controls; missing image: labeled placeholder, never unrelated dish. If data cannot be verified, disclose uncertainty.

## QA acceptance
- [ ] Visual approved by design owner; screenshot taken at 390x844 and 360x800.
- [ ] Primary action and back navigation tested.
- [ ] Role/tenant permission verified on server; forbidden actions fail.
- [ ] Allergy, privacy, child commerce and budget rules checked where relevant.
- [ ] Widget test for loading/empty/error/offline states.
- [ ] Accessibility tested with TalkBack/VoiceOver and large text.
- [ ] Event tracking verified to be opt-in, scoped and semantically correct.

## Expanded functional acceptance for KIDS-005

**Specific job:** Show safety-first lesson steps with adult-supervision markers.

### Information hierarchy

1. Primary task at top; show real household context only if authorized.
2. Immediate safe next action; a user can exit without losing confirmed state.
3. Cost and data provenance badges where estimates appear.
4. Clear feedback, retries and empty states; no dead buttons.
5. In child mode no ads, bills, upgrade prompts, money-stress disclosures or open social links.

### User stories and test fixtures

- **Happy path:** eligible circle completes `junior-chef` action and sees server-confirmed result.
- **Loading:** show semantic skeleton; avoid blank screen.
- **Empty:** new household has no data; show safe first-action copy.
- **Permission denied:** revoked member receives `CIRCLE_FORBIDDEN` and no private fallback content.
- **Offline:** cache only approved content and mark pending writes; retry safely.
- **Personalization:** explicit decisions may update preference signals; no-view is not dislike.
- **Allergy:** hard-filter every recipe and substitution at server before rendering approval.
- **Accessibility:** keyboard, focus, 200% text, screen-reader labels and nonvisual task alternative.

### Agent handoff

Flutter agent builds typed widget, routes, repository and widget tests. Supabase agent implements policies and RPC/Edge contract. Intelligence agent supplies feature-specific safe event schema. QA compares visual with PNG (status: `pending_individual_design`), rechecks camera/media rights and captures 360x800 and 390x844 screenshots. Design owner must approve any cropped storyboard reference before declaring pixel-perfect parity.
