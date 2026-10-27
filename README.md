# citycalls-customer-mobile

CityCalls customer app — Flutter/Dart. Fully independent of `citycalls-vendor-mobile`; no shared code between them despite both being Flutter. See [citycalls-docs](../docs) for architecture, API contracts, and screen specs.

## Setup

```bash
flutter pub get
flutter run
```

The API base URL defaults to the live server (`https://api.citycalls.in/api/v1`, set in `lib/providers/auth_providers.dart`). For a local `citycalls-api`, override it per run with `flutter run --dart-define=API_BASE_URL=http://<host>:4000/api/v1` (or `scripts/run-local.sh`). Plain `http://` only works in debug builds.

## Release signing

Copy `android/key.properties.example` to `android/key.properties` (git-ignored) and point it at your upload keystore. Without it, release builds fall back to the debug key and cannot be uploaded to the Play Store.

## Structure

- `lib/data/` — Dio API client + one repository class per module (Manish's functional/data layer)
- `lib/providers/` — Riverpod providers/notifiers consumed by screens
- `lib/models/` — local Dart models mirroring `citycalls-api`'s contract, to be regenerated from the synced OpenAPI spec (`scripts/sync-contracts.sh`) once it exists
- `lib/screens/`, `lib/widgets/` — Rohit's UI, per `docs/rohit/05-customer-app-screen-list.md`
- `lib/tokens/` — this app's own copy of design tokens/enum-label maps

## Status

Functional skeleton: login flow wired end-to-end against `citycalls-api`'s real `/auth/login` endpoint (Dio client, secure token storage, Riverpod state, form validation). `flutter analyze` and `flutter test` both pass. UI is a functional placeholder — visual design is Rohit's pass per `docs/rohit/02-design-system.md`.
