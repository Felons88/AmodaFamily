# Family Circle

Flutter client for the Family Circle household meal planner. The product contracts and implementation plan are in [`docs/`](docs/README.md).

## What is implemented

A runnable app covering all 40 storyboard screens (6 onboarding, 14 adult, 6 kids, 10 storyboard games, 4 shared) plus the remaining 6 game contracts from `docs/games/`.

- **Backend:** `lib/shared/store.dart` — an in-memory local backend that enforces the same rules the Supabase RPC layer is specified to enforce: adult-only privileged writes, hard-allergen fail-closed filtering (`safety_engine`), basket math (`planner_engine`), per-circle game/vote quotas, idempotent badge awards, consent-gated typed events, offline queue for safe writes, integer-cents money with labeled price provenance. No real network calls; Supabase migrations exist under `supabase/` but are not wired to a live project.
- **Kids mode:** profile switching to a managed minor hides all prices, commerce, billing and ads; the backend still rejects minor privileged actions (`ADULT_ONLY`, `MINOR_COMMERCE_BLOCKED`) regardless of hidden buttons.
- **Design:** token-based dark/light themes per `docs/design_system/DESIGN_SYSTEM.md`. No emojis as icons; recipe imagery renders as labeled placeholders / AI-illustration / verified-photo badges — never a wrong-dish image.
- **Honest labeling:** all prices are labeled sample estimates (`sample_estimate`, region `US-DEMO`, confidence shown); SNAP eligibility is `verified`/`unverified`; demo checkout is a mock provider; demo data is marked as sample content.

## AI (OpenRouter)

`lib/shared/ai.dart` — a consent-gated, adult-only OpenRouter adapter that asks for one meal idea using only verified-safe ingredient names. AI output is labeled AI-generated and never treated as allergy verification (the hard filter always decides safety). Configure at build time:

```sh
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-... --dart-define=OPENROUTER_MODEL=openrouter/auto
```

Unset key → the AI card reports "not configured" instead of failing. For production this call must move behind a Supabase Edge Function so the key never ships in the client.

## Auto-updates

`lib/shared/updates.dart` — on app start the home screen fetches a version manifest and prompts the user to download a newer APK. Point builds at a hosted manifest:

```sh
flutter build apk --release --dart-define=UPDATE_MANIFEST_URL=https://your-host/version.json
```

Manifest format is in `deploy/version.json`. Silent no-op when unset; Play Store builds can swap the same surface for the in-app-update API.

## Build the APK

```sh
flutter build apk --release \
  --dart-define=OPENROUTER_API_KEY=... \
  --dart-define=UPDATE_MANIFEST_URL=...
# → build/app/outputs/flutter-apk/app-release.apk
```

## Not implemented (explicitly, per docs limits)

- Live Supabase project, real auth, push provider, store billing, live grocery pricing, EBT/retailer integrations, OCR/camera pantry scanning (surface is stubbed with an explicit permission/unavailable notice).
- Licensed food photography (placeholders labeled `Photo pending verification` instead).
- Release/store/legal gates H1–H5 — unchanged, require human signoff.

## Local checks

Install Flutter 3.47.7 (Dart 3.13.5), then run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

`flutter analyze` exits 0 and `flutter test` passes 19 tests including the safety golden cases (allergen fail-closed, non-vote neutrality, minor commerce block, quota enforcement, idempotent badges, offline queue, plan infeasibility, SNAP provenance).

## Try it

`flutter run` on any device. From the welcome screen either create a household (full onboarding → generated plan) or tap **Explore the demo household** for a seeded 2-adult/2-kid family with an approved plan, pantry, budget, open vote and beverages. Switch profiles from the home app bar to enter kid mode; toggle **Simulate offline** in More to exercise the queue.
