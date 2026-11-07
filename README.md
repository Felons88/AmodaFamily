# Family Circle

Flutter client foundation for the Family Circle household meal planner. The product contracts and implementation plan are in [`docs/`](docs/README.md). The current app contains only a bootable foundation screen; auth, meal plans, and backend integration are not implemented yet.

## Local checks

Install Flutter 3.47.7 (Dart 3.13.5), then run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Android and iOS project shells were generated with Flutter. iOS builds require a macOS host and signing setup.
