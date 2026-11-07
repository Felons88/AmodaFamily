# Family Circle planner engine foundation

Pure Dart FC-007/FC-008 planning logic. Run `dart pub get --offline`,
`dart analyze lib test`, and `dart run test/planner_engine_test.dart` here.

The planner accepts only trusted canonical ingredient facts and catalog-approved
recipes. It performs hard allergen filtering before any price or preference
decision, uses only explicitly compatible quantities, subtracts confirmed
pantry stock, and requires dated labeled estimates for every needed item.
Unknown SNAP eligibility is never counted as verified benefit coverage. A
ready result still needs adult review and approval. This package has no data
access or authorization layer; server integration and end-to-end tests remain
required before use.
