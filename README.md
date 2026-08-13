# Biteo App

Biteo — customer-facing application for the Biteo food-delivery and
restaurant ecosystem.

This repository contains the **Biteo App**, the Flutter client used by
customers to browse vendors, order food, pay, and track pickups. Companion
backend codebases (`functions`, `support-ai`) live in this repo as Firebase
Cloud Functions for convenience, but this app is the primary deliverable.

- **Website:** https://www.biteo.in/
- **Version:** 1.0.0+1
- **Platform:** Android (primary). Web / desktop shells exist but Firebase is
  only configured for Android.
- **Firebase project:** `biteo-1e76d`

## Highlights

- Clean architecture: `core/` shared infrastructure + `features/` with
  `data / domain / presentation` layering per feature.
- State management with Riverpod.
- Android native config via `android/app/google-services.json`.
- Razorpay checkout (client-side via `RAZORPAY_KEY_ID`).
- Google Maps / Places for address selection.

## Repository layout

| Path               | Purpose                                              |
| ------------------ | ---------------------------------------------------- |
| `lib/`             | Flutter application source.                          |
| `android/`         | Android host project (only fully configured target). |
| `functions/`       | Firebase Cloud Functions (Razorpay verification, etc.). |
| `support-ai/`      | Firebase Cloud Function (Gemini support assistant).  |
| `web/`, `windows/`, `macos/`, `linux/` | Unused host shells. |
| `test/`            | Unit tests (pure Dart, no device/Firebase needed).   |
| `docs/`            | Architecture, development, deployment, environment, security. |

## Getting started

See [docs/development.md](docs/development.md) for setup instructions and
[docs/environment.md](docs/environment.md) for required environment variables.

```sh
flutter pub get
flutter analyze
flutter test
```

CI runs `flutter analyze` and `flutter test` on every push to `main` and on
pull requests (see `.github/workflows/ci.yml`).

## Security

**Do not commit secrets.** See [docs/security.md](docs/security.md) for the
documented rules, including the Razorpay key handling, the deleted Google
Maps key, and the Android Attestation keybox (`linux/yk50.xml`) that was
removed from this repository. Real credentials belong in git-ignored local
files or Firebase/secret configuration, never in source.

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Laksh Yadav.
