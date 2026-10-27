# Foundit app (Flutter)

UI stage: 12 screens plus the admin section, running on sample data. No Firebase or backend yet.

Built for Flutter 3.47.7 / Dart 3.13.5. Not yet compiled by the author's tooling, so run `flutter analyze` first and fix anything it reports.

## First run (Windows, PowerShell)

```
cd app
E:\flutter\bin\flutter create --org com.onavri --project-name foundit .
E:\flutter\bin\flutter pub get
E:\flutter\bin\flutter analyze
E:\flutter\bin\flutter test
E:\flutter\bin\flutter run -d chrome
```

`flutter create .` adds the `android/`, `ios/` and `web/` folders around the existing `lib/`. If it replaces `lib/main.dart`, restore it with `git checkout lib/main.dart`.

For an Android phone or emulator, install Android SDK Command-line Tools (Android Studio, SDK Manager, SDK Tools), then run `flutter doctor --android-licenses` and `flutter run`.

## Screens

| # | Screen | File |
| --- | --- | --- |
| 1 | Splash and onboarding | `screens/onboarding.dart` |
| 2 | Login and sign-up | `screens/login.dart` |
| 3 | Home dashboard | `screens/home.dart` |
| 4 | Create report | `screens/create_report.dart` |
| 5 | Photo and details | `screens/photo_details.dart` |
| 6 | Browse reports | `screens/browse.dart` |
| 7 | Search and filters | `screens/search.dart` |
| 8 | Match results | `screens/matches.dart` |
| 9 | Item details | `screens/item_detail.dart` |
| 10 | Ownership claim | `screens/claim.dart` |
| 11 | Notifications and my reports | `screens/activity.dart` |
| 12 | Profile and settings | `screens/profile.dart` |
| Admin | Flags, claims, desk, stats | `screens/admin.dart` |

## Colours

Three families only, defined in `lib/theme.dart`: Teal (found, trusted), Amber (lost, attention), Ink (text and structure; greys are tints of ink). Selected chips use ink, never teal or amber.

## Packages

Only the Flutter SDK for now. Firebase packages are added when the backend work starts.
