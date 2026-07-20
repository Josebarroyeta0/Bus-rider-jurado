# bus_rider_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Local setup and configuration notes
----------------------------------
- Add the required dependencies: `cloud_firestore`, `firebase_core`, `google_maps_flutter`, `shared_preferences` to `pubspec.yaml` and run:

```bash
flutter pub get
```

- Configure Firebase (recommended):
	- Install `flutterfire` CLI: `dart pub global activate flutterfire_cli`.
	- Run `flutterfire configure` and follow the steps to generate `lib/firebase_options.dart`.
	- Alternatively, add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) manually.

	- Android: add your key to `android/app/src/main/AndroidManifest.xml` at the meta-data entry `com.google.android.geo.API_KEY`.
	- iOS: add `GMSApiKey` to `ios/Runner/Info.plist` or initialize in `AppDelegate` with `GMSServices.provideAPIKey()`.
 Google Maps keys:
	- Android: add your key to `android/app/src/main/AndroidManifest.xml` at the meta-data entry `com.google.android.geo.API_KEY`.
	- iOS: add your key to `ios/Runner/Info.plist` at the `GMSApiKey` key.
After configuration, start the app with:

```bash
 Firebase configuration:
	- Preferred: Run `flutterfire configure` to generate `lib/firebase_options.dart`.
	- Alternate: manually add `google-services.json` for Android in `android/app/` and `GoogleService-Info.plist` for iOS in `ios/Runner/`.
 Example run commands:
```
flutter pub get
flutter analyze
flutter test
flutter run -d chrome -t lib/main.dart
```

Quick project checks (scripts)
------------------------------
We've added convenience scripts to validate the workspace and run static checks/tests.
- Windows PowerShell:
	- `powershell -ExecutionPolicy Bypass -File scripts/check_env.ps1`
- Unix/macOS:
	- `bash scripts/check_env.sh`

CI (GitHub Actions)
--------------------
This repo includes a GitHub Actions workflow at `.github/workflows/flutter-ci.yml` that:
- runs on Pull Requests and pushes to `main`/`master`.
- runs on ubuntu-latest, macos-latest and windows-latest.
- installs Flutter, fetches packages, runs `flutter analyze` and `flutter test`.

APK artifact (from CI)
----------------------
The CI workflow also builds a debug APK and uploads it as a workflow artifact. After a workflow run completes you can download the APK from the actions run details.

Badge
-----
Add a status badge to your README (replace `OWNER` and `REPO` with your GitHub repo):

```markdown
![CI](https://github.com/OWNER/REPO/actions/workflows/flutter-ci.yml/badge.svg)
```


Deploy to Firebase from CI
--------------------------
This project includes a workflow `.github/workflows/deploy-firebase.yml` that builds the web app and deploys to Firebase Hosting and Functions.

Setup steps:
- Create a CI token locally: `firebase login:ci` and copy the token.
- Add the token to your repository secrets as `FIREBASE_TOKEN` (Repo Settings → Secrets).
- Ensure `firebase.json` exists (already added) and `functions/` contains the Cloud Function sources.

The workflow runs on pushes to `main`/`master` and will run:
```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
firebase deploy --only hosting,functions --token "$FIREBASE_TOKEN"
```



```

