# Automated acceptance suite

## Core E2E scenarios
A. Adult creates circle with 2 adults + 2 managed children, allergy kiwi, SNAP $500 and $100 cash, 10th deposit day; resulting plan includes **zero kiwi ingredients**, no false guarantee of cross-contact safety, grocery budget estimate with dated source.
B. Adult in Circle A cannot read/edit Circle B records, catalog drafts, other minors, billing status or private images, even via direct API.
C. Child sees approved game/vote pages but cannot navigate or call purchase/plan-change/budget-edit endpoints; hitting free limit shows neutral cooldown without upsell.
D. Adult upgrades one circle; signed webhook makes entitlement available to all its authorized members; cancel/grace/refund correctly handled; unrelated circle unaffected.
E. Skip 5 vote rounds; recipe taste scores unchanged. Mark 'too long' → prep-fit changes but ingredient preference stays unchanged. Delete inference → no reappearance from unconsented history.
F. Two gallons/week milk, validated pantry quantity, different weekly/biweekly shopping cadence -> reasonable unit-normalized recommendations with cost warning and expiry limits.
G. AI suggests chicken enchiladas with shrimp image -> rejects image; AI recipe with unknown allergen term -> blocks recommendation pending review.
H. Offline mode shows last approved plan and queues safe actions; budget conflict handled without overwriting more recent values.
I. App accessibility: VoiceOver/TalkBack traverses controls, readable at large text, reduced motion honored, all key controls meet contrast and touch size criteria.
J. Pricing unavailable → marked estimated/unavailable, never fabricated live cost; EBT account credentials never requested.

## CI tasks
`dart format --output=none --set-exit-if-changed .`; `flutter analyze`; `flutter test`; `flutter test integration_test` in device runner; SQL authorization tests with distinct auth JWT fixtures; static secret scan; dependency audit; screenshot review report; mocked provider webhook replay and forgery tests. Fix command specifics based on actual generated project.

## Exit evidence
For every screen: approved mock reference, build screenshot, golden/snapshot result where suitable, navigation/action tests, role and error tests, accessibility checklist, image provenance if pictured, and signed-off QA review. Produce test logs and known-issues register.
