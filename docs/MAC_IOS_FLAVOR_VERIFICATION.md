# Mac iOS Flavor Verification Handoff

## Purpose

Use this document on the Mac to verify the iOS side of FE10. Windows can scaffold
the Flutter/Dart layer, Android product flavors, and iOS project files, but only
macOS with Xcode can prove the iOS schemes build.

## Current Project State

Repository:

```text
https://github.com/washappenin/Workforce-Management.git
```

Mobile app path:

```text
mobile/
```

Backend staging API:

```text
https://workforce-management-production.up.railway.app
```

FE10 status:

- Dart flavor layer: complete.
- Android product flavors: complete and verified.
- iOS schemes/build configs: scaffolded.
- iOS build verification: pending on Mac.

## iOS Apps To Verify

| App | Flutter Flavor | Dart Entrypoint | iOS Bundle ID | Display Name |
| --- | -------------- | --------------- | ------------- | ------------ |
| Aurelia Employee | `employee` | `lib/main_employee.dart` | `com.aurelia.workforce.employee` | Aurelia Employee |
| Aurelia Manager | `manager` | `lib/main_manager.dart` | `com.aurelia.workforce.manager` | Aurelia Manager |
| Aurelia Admin | `admin` | `lib/main_admin.dart` | `com.aurelia.workforce.admin` | Aurelia Admin |
| Aurelia Platform | `platform` | `lib/main_platform.dart` | `com.aurelia.workforce.platform` | Aurelia Platform |

## Mac Prerequisites

Install or confirm:

- Xcode 15+ from the App Store or Apple Developer downloads.
- Xcode command line tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
```

- Flutter 3.24+:

```bash
flutter --version
flutter doctor -v
```

- CocoaPods, if Flutter reports it missing:

```bash
sudo gem install cocoapods
pod --version
```

## Clone And Prepare

```bash
git clone https://github.com/washappenin/Workforce-Management.git
cd Workforce-Management/mobile
flutter pub get
```

If the repo is already cloned:

```bash
cd Workforce-Management
git checkout main
git pull origin main
cd mobile
flutter pub get
```

## One-Command Verification

From `mobile/`:

```bash
bash scripts/verify_ios_flavors.sh
```

The script runs:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- no-signing debug iOS builds for `employee`, `manager`, `admin`, and `platform`

The script defaults to:

```bash
APP_ENV=staging
API_BASE_URL=https://workforce-management-production.up.railway.app
```

Override if needed:

```bash
APP_ENV=production API_BASE_URL=https://api.example.com bash scripts/verify_ios_flavors.sh
```

## Manual Build Commands

Use these if you want to run one flavor at a time:

```bash
flutter build ios --debug --no-codesign \
  --flavor employee \
  -t lib/main_employee.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app

flutter build ios --debug --no-codesign \
  --flavor manager \
  -t lib/main_manager.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app

flutter build ios --debug --no-codesign \
  --flavor admin \
  -t lib/main_admin.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app

flutter build ios --debug --no-codesign \
  --flavor platform \
  -t lib/main_platform.dart \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://workforce-management-production.up.railway.app
```

## Expected Result

Each build should finish with a successful Flutter/Xcode build message for the
selected flavor. No code signing is required for this verification step.

Expected schemes:

```bash
xcodebuild -list -project ios/Runner.xcodeproj
```

Should show:

- `employee`
- `manager`
- `admin`
- `platform`
- `Runner`

## What To Send Back

After running verification, send back:

- Mac chip and macOS version.
- `flutter --version`.
- `xcodebuild -version`.
- Whether `bash scripts/verify_ios_flavors.sh` passed.
- If it failed, the first error block and which flavor failed.

Do not send secrets, certificates, provisioning profiles, Apple account details,
or signing passwords.

## Common Fixes

If CocoaPods fails:

```bash
cd ios
pod repo update
pod install
cd ..
```

If Xcode selection is wrong:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

If Flutter cannot find iOS tooling:

```bash
flutter doctor -v
```

If a scheme is missing, confirm the repo contains:

```text
mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/employee.xcscheme
mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/manager.xcscheme
mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/admin.xcscheme
mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/platform.xcscheme
```

## After Verification Passes

Once all no-signing iOS flavor builds pass:

1. Update `docs/FRONTEND_CHECKPOINT_LOG.md` and mark FE10 iOS build verification complete.
2. Keep FE10 as release-hardening pending until signing/provisioning is configured.
3. Begin Apple Developer setup:
   - App identifiers for each bundle ID.
   - Provisioning profiles.
   - Signing certificates or automatic signing.
   - TestFlight records.
   - Final per-app icons and launch screens.
