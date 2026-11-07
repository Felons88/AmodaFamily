# Visual system and imagery rules

## Direction
Modern, premium **consumer-product** aesthetic, not 'vibe-coded': restrained near-black/charcoal surfaces, purposeful fresh-green accent, cream-neutral text, generous whitespace, authentic food and family photography, semantic typography and calm interaction design. Existing dark/green board is the *directional reference*, not a blanket directive to copy its inaccuracies. Implement light-mode equivalent as a design-system variant. No emojis as icons. Use licensed custom vector iconography or Lucide-like consistent icon set; do not use generic AI-rendered interface screenshots as shipped assets.

## Tokens (draft; approve in Figma/Flutter before production)
Colors: `bg #101411`, `surface #1B211D`, `surfaceElevated #252D27`, `primary #65D36E`, `primaryDark #215C35`, `text #F5F7F2`, `muted #B6C2B9`, `warning #EAB65F`, `error #FF746C`, `outline #38443C`. Contrast AA minimum; don't use green alone to encode status. Spacing 4pt base (4,8,12,16,24,32); radii 12/16/24; touch targets >= 44x44pt; type scale 12,14,16,20,24,30; Inter/appropriate platform fallback; bottom nav max five destinations.

## Photography requirements
Food photos must depict precisely the recipe (e.g. chicken enchiladas, not shrimp) and visible ingredients/technique; no random stock substitution; photo must have licensed source record, source/creator, allowed usage, alt-text and verification status. GenAI illustrations explicitly labeled 'AI illustration', not exact cooking outcome. If no validated photo, use a neutral intentional dish placeholder with text, never a wrong dish. Family photography must be licensed/consented, diverse but non-tokenizing, never imply a user-submitted family image by default; do not display unrelated real people as household members.

## UX principles
One primary action/screen; clear progressive onboarding; review before adding to plan or basket; show estimate source/date/range; seamless single-person mode; accessible language with optional details; child mode: engaging but no commerce and no dark patterns. Skeletons, offline, empty, error, and permission states specified per-screen. Motion reduced on request; readable font scaling and TalkBack/VoiceOver.

## QA
Take device-size screenshots matching all approved screen PNGs; compare hierarchy, spacing, typographic rhythm, photography composition and interactive states manually + snapshot diff. No pixel-perfect comparison to AI collage crops because those are reference only, not true approved individual mocks.
