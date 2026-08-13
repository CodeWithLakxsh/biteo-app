# Development

## Prerequisites

- Flutter SDK (stable channel) and the Dart SDK bundled with it.
- Android Studio or Android SDK with an emulator/device.
- A Google account for Firebase CLI (`firebase-tools`) if you work on the
  backend codebases.

## Setup

```sh
# 1. Install Flutter/Dart and enable Android tooling.
flutter --version
flutter doctor

# 2. Resolve Dart dependencies.
flutter pub get

# 3. (Optional) Backend dependencies for Cloud Functions.
cd functions && npm install
cd ../support-ai && npm install
```

## Environment file

The app reads `.env` at runtime via `flutter_dotenv`. It is **optional**: the
app boots normally when the file is absent (see `lib/main.dart`), and the
file is **git-ignored**.

Create your local copy from the template:

```sh
cp .env.example .env
```

Fill in `RAZORPAY_KEY_ID` and any other values you need. See
[docs/environment.md](environment.md) for what each value is for. **Never**
commit real values — see [docs/security.md](security.md).

> Note: `android/local.properties` (which holds the Google Maps API key for
> Android builds) is also git-ignored. If it is missing, `flutter run` will
> regenerate a minimal one; supply your own Maps key there or via the
> `MAPS_API_KEY` Gradle property if you need Google Maps SDK features.

## Running

```sh
flutter run                    # default device
flutter run -d <device-id>     # specific device
```

## Verifying

```sh
flutter analyze                # static analysis
flutter test                   # unit tests
```

## Continuous integration

`.github/workflows/ci.yml` runs `flutter pub get`, `flutter analyze`, and
`flutter test` on push to `main` and on pull requests. No secrets, signing
keys, or APK/web build jobs are included.
