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

### Firebase Android client config (`google-services.json`)

The real `android/app/google-services.json` is **not** in the repository — only
`android/app/google-services.json.example` (placeholders) is committed.

To build/run for Android you must supply the real file:

1. In the Firebase console (`biteo-1e76d`) open
   *Project settings → Your apps → Android app (`com.biteo.biteo`)* and
   download `google-services.json`.
2. Place it at `android/app/google-services.json`. It is git-ignored.
3. Do **not** commit it; if you need it in CI, pass it via repository secrets
   (e.g. write it from `$GOOGLE_SERVICES_JSON` before `flutter build`).

This file is normal Android client configuration (API keys, app id) — not a
password — but it is project-specific and kept out of version control by
policy.

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

`.github/workflows/ci.yml` runs on push to `main` and on pull requests:

1. `flutter pub get` — resolve dependencies.
2. `flutter analyze` — static analysis.
3. `flutter test` — unit tests.
4. `flutter build apk --debug` — compile validation.

The debug build uses the Android **debug signing key** and never requires
production credentials: the Google Services Gradle plugin is not applied, so
`google-services.json` is not needed; the Maps placeholder defaults to
`MISSING_KEY`; and Flutter regenerates `local.properties` from the SDK path.
No secrets, signing keys, or release/deployment jobs are included.
