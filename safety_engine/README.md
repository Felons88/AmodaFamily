# Family Circle safety engine foundation

Pure Dart ingredient eligibility filter for FC-004. Run `dart pub get --offline`,
then `dart run test/safety_engine_test.dart` from this directory. It uses no
external packages or services.

The caller must supply canonical ingredient IDs and trusted, reviewed facts.
Substitutions must be represented by their actual ingredient IDs and checked
again. `eligible` only permits a candidate to enter meal planning; it does not
certify allergy or cross-contact safety. Backend integration, provenance
validation, authorization, and end-to-end tests remain required.
