# Mobile Release Readiness

## Current State

The Flutter client under `mobile/` is the primary iOS/Android app. FE0-FE9 have
passed staging QA on Android emulator with the Railway staging API.

Role-specific app flavor planning lives in
`docs/MOBILE_FLAVOR_ARCHITECTURE.md`.
Mac iOS build verification context lives in
`docs/MAC_IOS_FLAVOR_VERIFICATION.md`.

Android product flavors and iOS schemes are configured for Employee, Manager,
Admin, and Platform. iOS build verification and release signing remain pending.

Current defaults:

- `APP_ENV=staging`
- `API_BASE_URL=https://workforce-management-production.up.railway.app`
- Face provider: backend mock provider
- Notifications: in-app polling only

## Environment Configuration

The app reads release configuration from Dart defines:

```bash
--dart-define=APP_ENV=staging
--dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

Production builds must pass production values explicitly:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

Do not commit production secrets, credentials, signing passwords, service-account
JSON, or vendor API keys.

## CI Gate

`.github/workflows/mobile-ci.yml` runs on mobile changes:

- `flutter pub get`
- `dart format --set-exit-if-changed lib test integration_test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

This is a source/build gate. Staging integration tests remain manually triggered
because they require private role credentials from `scripts/staging-smoke/smoke.env`.

## Face Identification Plan

The current app and backend use a safe mock provider flow:

1. Admin/HR creates or updates face enrollment metadata for an employee.
2. Employee starts clock-in/out.
3. App requests camera permission.
4. App performs face verification through `POST /api/face/verify`.
5. Backend returns a short-lived `faceVerificationReference`.
6. App sends that reference to `POST /api/attendance/clock-in`.
7. Backend fails closed if the reference is missing, expired, reused, invalid, or
   belongs to a different employee.

Production face identification should keep the same frontend contract but replace
the provider behind the backend adapter:

- Use a vendor with liveness detection, spoof resistance, audit controls, and
  deletion APIs.
- Capture camera input only for verification; do not store raw images on device.
- Do not persist biometric templates in the Flutter app.
- Store only provider references and safe enrollment status in backend records.
- Require explicit employee consent before enrollment.
- Add offboarding/deletion workflow for provider-side biometric records.
- Add provider failure modes: verification unavailable should block clock-in and
  show a clear retry/escalation state.
- Update `docs/THREAT_MODEL.md`, `docs/FACE_VERIFICATION_RULES.md`, and
  `docs/PRIVACY_AND_LOGGING_RULES.md` when a provider is chosen.

Recommended provider-selection questions:

- Does the vendor support passive and/or active liveness checks?
- Where are biometric templates stored and processed?
- What deletion SLA and audit proof is available?
- Can provider references be rotated or re-enrolled without exposing templates?
- What is the false accept / false reject profile for the workforce environment?
- How does the provider handle poor lighting, PPE, accessibility needs, and
  device camera differences?

## Push Notification Plan

The backend currently supports in-app notifications only. Production mobile push
should be added as a separate delivery layer without changing notification
ownership rules:

1. Add device-token registration endpoints.
2. Store device tokens scoped to user, device, platform, and company.
3. Add opt-in/permission UI in Flutter.
4. Use FCM for Android and APNs for iOS, likely through Firebase Cloud Messaging.
5. Send push from notification creation events while preserving the in-app record.
6. Add token refresh, logout token deletion, and inactive-device cleanup.
7. Keep notification title/body out of audit logs.

## Store Release Checklist

Before app-store submission:

- Replace placeholder app name, bundle IDs, icons, and launch screens.
- Replace shared placeholder launcher icon with final per-app icons.
- Configure Android signing and Play Console app bundle upload for each flavor.
- Run the manual `Mobile iOS Flavor Builds` workflow or local macOS no-signing
  builds for each iOS scheme using `mobile/scripts/verify_ios_flavors.sh`.
- Configure iOS signing, provisioning, capabilities, and TestFlight for each
  scheme.
- Confirm production backend URL, CORS policy for web surfaces, and mobile network
  security policy.
- Confirm privacy policy, terms, biometric consent language, and data deletion
  language.
- Run FE9 launch gate against production-like pre-prod.
- Run camera denied, location denied, no network, expired token, and low-permission
  regression checks on physical iOS and Android devices.
- Verify accessibility: dynamic text, contrast, keyboard/screen reader basics.
- Verify timezone and geofence behavior for real worksite coordinates.

## Open Production Decisions

- Production face/liveness vendor.
- Push notification provider and backend delivery design.
- App display name and bundle identifiers.
- Production API hostname.
- Whether admin-heavy workflows remain in mobile or split into a dedicated web
  admin console later.
- Whether `platform` ships as a mobile flavor, web-only, or both.
