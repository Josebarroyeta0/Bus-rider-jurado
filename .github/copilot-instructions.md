Purpose
-------
This short guide helps AI coding agents (Copilot/assistants) get productive rapidly in this Flutter app. It focuses on the repo's architecture, setup, conventions, integration points, and gotchas discovered by reading the code.

Getting started
---------------
- SDK: Use Flutter with Dart SDK matching `pubspec.yaml` (environment: ^3.10.4). Verify with `flutter --version`.
- First actions: run `flutter pub get` and `flutter analyze` to discover missing dependencies and static errors.
- Keep incremental, low-risk changes: modify `pubspec.yaml` to add missing runtime dependencies (see "Dependencies") and commit small PRs.

Project structure & entrypoints
-------------------------------
- App entry: [lib/main](../lib/main)
- Screens: [lib/screens](../lib/screens) — key screens are `login_screen`, `home_screen`, `mapa_tracking_screen`, `admin_screen`, `bus_detalle_screen`.
- Models: [lib/models/models](../lib/models/models) — contains `Horario` and `Bus`; expect to find or add `ruta_data.dart` with `RutaGuarico` data referenced across screens.
 - Services: [lib/services/firestore_service.dart](../lib/services/firestore_service.dart) — centralized Firestore helper methods (`busStream`, `updateBusLocation`, `setBus`).

Big-picture architecture
------------------------
- Single-process Flutter app with UI inside MaterialApp at `lib/main`.
- Data flow:
  - Local data: `RutaGuarico` provides route, stops and bus list used for UI (e.g., home list & map polyline).
  - Local state: Login uses `SharedPreferences` to store `user_email` and boolean `is_admin` flag (see [lib/screens/login_screen](../lib/screens/login_screen)).
  - Remote live updates: Firestore collection `buses` provides bus positions. `mapa_tracking_screen` subscribes to `buses/{id}` snapshots and updates UI in real time.
  - Admin tools (in-app) update Firestore to simulate bus GPS updates (see [lib/screens/admin_screen](../lib/screens/admin_screen)).

Integration points and external dependencies
-------------------------------------------
- Firebase (Cloud Firestore): code directly uses `cloud_firestore` API to read/write `buses` documents. Typical document fields used: `placa`, `lat`, `lng`, `estado`.
- Google Maps: uses `google_maps_flutter` widget for mapping and polylines.
- Shared Preferences: local login uses `shared_preferences` for session data.
- Note: `pubspec.yaml` in repo does not currently include these third-party packages — add them before running.

Required environment setup
--------------------------
- Dependencies to add (examples):
  - `cloud_firestore`, `firebase_core` (for Firestore usage)
  - `google_maps_flutter` (map rendering)
  - `shared_preferences` (local session)
  - `firebase_analytics` / `firebase_auth` only if introduced — not required today
- Firebase configuration:
  - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), or use `flutterfire configure` to generate `firebase_options.dart`.
  - Initialize `Firebase.initializeApp()` in `main()` prior to Firestore calls.
- Google Maps key:
  - Add Android API key in AndroidManifest and iOS in Info.plist, enable Maps SDKs in Google Cloud Console.

Common tasks and commands
-------------------------
- Fetch dependencies: `flutter pub get`.
- Build & run: `flutter run -d <device>` (or use VSCode/Android Studio Run). Use `flutter run -v` for verbose logs.
- Lint & analyze: `flutter analyze`.
- Web/desktop tests are not configured; `test/widget_test` contains a default template and will need updates if running.

Firestore schema used by the app
--------------------------------
- Collection: `buses`
- Each bus document (id = busId as string) fields:
  - `placa`: String (license plate)
  - `lat`: double (latitude)
  - `lng`: double (longitude)
  - `estado`: String (text status used in UI)

Notable code patterns & conventions
----------------------------------
- The app keeps UI state inside `StatefulWidget` screens — no global state-management library (Provider, BLoC, Riverpod) is used.
- Screens directly access Firestore — if adding features, prefer extracting Firestore logic into a `services/` layer (e.g., `lib/services/firestore_service.dart`).
- Simulated login: `shared_preferences` with demo accounts `passenger@test.com` and `admin@test.com`.
- Time & location:
  - Polylines use `RutaGuarico.rutaCompleta` for route visualization — implement or update `RutaGuarico` data to include `LatLng` list.
  - The `admin_screen` contains a live-simulation script to update `buses/1` coordinates.

Failure modes & gotchas
-----------------------
- Repo is partially incomplete/stale: the `pubspec.yaml` doesn't list packages used in code and some file imports (e.g., `ruta_data.dart`) appear to be missing or misnamed (e.g., `lib/models/models`). Expect `flutter analyze` or the editor to report errors.
- Some model definitions mismatch usage (e.g., `Bus.ubicacion` typed as `String` while `mapa_tracking_screen` expects `LatLng`), causing runtime or type errors.
- Tests use the default counter app template and should be updated to match app widgets (e.g., `BusRiderGuaricoApp`).

How to help (developer workflow for AI agents)
-------------------------------------------
- Start with small, well-scoped PRs that fix one problem: add dependencies, add missing files, or fix type mismatches.
- Validate with `flutter analyze` and a device run. If tests are updated, run `flutter test`.
- When adding or updating a feature which uses Firestore or Maps, include a short README or an example snippet showing required configuration (Android keys, iOS plist, `firebase_options.dart`).

Reference files to inspect first
-------------------------------
- [lib/main](../lib/main)
- [lib/screens/login_screen](../lib/screens/login_screen)
- [lib/screens/home_screen](../lib/screens/home_screen)
- [lib/screens/mapa_tracking_screen](../lib/screens/mapa_tracking_screen)
- [lib/screens/admin_screen](../lib/screens/admin_screen)
- [lib/models/models](../lib/models/models)

If anything seems unclear, ask for the intended runtime setup (Firebase project ID, maps key), and whether to formalize Firestore read/update logic into a service layer.

End of file
