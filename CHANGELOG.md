# Changelog

All notable changes to the Biteo App are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-13

### Added

- Initial public release of the Biteo customer app.
- Vendor browsing, menu, cart, checkout, address selection (Google Maps /
  Places), and order pickup flows.
- Firebase Authentication, Firestore, Cloud Messaging, and Remote Config
  integration (Android).
- Razorpay payment checkout.

### Changed

- Repository prepared for GitHub publication:
  - Removed committed secrets and credentials.
  - Removed stale counter widget test; added pure-Dart cart domain unit
    tests.
  - Added CI workflow (`flutter analyze` + `flutter test`).
  - Added project documentation and a MIT license.
  - Cleaned generated build artifacts and duplicate files.

### Security

- Removed Android Attestation keybox (`linux/yk50.xml`) from the repository.
- Removed `.env`, `android/local.properties`, and `functions/.env*` real
  credential files; they are now git-ignored with an `.env.example` template.
- Removed a hardcoded Google Maps API key from Dart source.
