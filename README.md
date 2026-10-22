# SafeRide-LK Parent App

A production-oriented Flutter parent experience for an IoT school-transport safety research project. The app supports multiple children, destination-verified transport states, vehicle tracking, read-only attendance, notifications, and parent settings.

## Run the complete demo

The default build uses clearly labeled fictional data and does not require a backend, Firebase project, or Maps key.

```bash
flutter pub get
flutter run
```

Demo login is pre-filled (`parent@saferide.lk` / `demo123`). Simulated locations and records are always marked as Demo data and never presented as live information.

## Real integration build

```bash
flutter run \
  --dart-define=DEMO_MODE=false \
  --dart-define=API_BASE_URL=https://api.your-domain.lk
```

Real mode expects the proposed Laravel endpoints under `/api`. The parser accepts direct values or Laravel-style `{ "data": ... }` envelopes. Authentication tokens are stored in platform secure storage and attached as Bearer tokens by a Dio interceptor. A `401` clears the local token; the backend must enforce every parent-to-student authorization check.

### External configuration still required

- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), then configure FlutterFire. Initialization fails gracefully when files are absent.
- Set `MAPS_API_KEY` in `android/gradle.properties` for Android and configure the restricted iOS key natively. Demo Mode uses a schematic map and works without credentials.
- Confirm Laravel response shapes, the device-token payload, pagination, error envelopes, and token revocation behavior.
- Configure APNs/FCM credentials, notification channels, and backend message categories.
- Add production signing, store privacy copy, and school-approved driver-contact visibility rules.

The parent app requests no device-location permission and never connects directly to a driver or IoT device. Location polling runs only while the tracking screen is active; the repository boundary can later be replaced with WebSockets.

## Validation

```bash
dart format .
flutter analyze
flutter test
```

Configuration uses `--dart-define`; `.env.example` contains no secrets.
