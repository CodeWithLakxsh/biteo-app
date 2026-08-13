# Security

This document records the security-relevant decisions for the Biteo App
repository. It is **living documentation**: update it whenever credentials or
access rules change.

## Golden rule

> Never commit secrets. Real credentials belong in git-ignored local files or
> in Firebase/secret-manager configuration — never in source.

## Resolved (actions taken in this release)

### 1. Android Attestation keybox removed — `linux/yk50.xml`

`linux/yk50.xml` contained an Android **Attestation keybox**: an ECDSA
**private key (PEM)** plus a three-certificate chain, labeled
`DeviceID="2gvwow8"`. It was present in the tree but referenced nowhere by the
build.

- **Action:** file deleted from the tree, and `.gitignore` now blocks
  `linux/yk50.xml` and any `*.keybox`.
- **Rotation guidance:** Android hardware-backed attestation keyboxes cannot
  be "revoked" like a certificate. If this keybox was ever deployed to a
  device, generate a fresh keybox via Google's Play Integrity / keybox
  provisioning and rotate the device keys.

### 2. Environment files with real values deleted

- `.env` (contained a Razorpay test key `rzp_test_*` and a Gemini API key)
  was deleted and added to `.gitignore` (`.env`, `.env.*`, with
  `.env.example` allow-listed).
- `functions/.env` and `functions/.env.biteo-1e76d` deleted and ignored.
- A documented template `.env.example` was created with placeholders only.
- `lib/main.dart` now loads dotenv with `isOptional: true`, so the app runs
  without a local `.env`.

### 3. Google Maps API key removed from Dart source

`lib/features/address/data/services/places_service.dart` had a hardcoded
Maps API key (`AIzaSyC_…` redacted). Replaced with the
placeholder `YOUR_GOOGLE_MAPS_API_KEY` and documented.

- **Rotation guidance:** the exposed key was a client key restricted to this
  app's package in the console (recommended). Still, rotate it in Google
  Cloud Console if you believe it leaked, and keep per-package restriction +
  quota caps in place.

### 4. `android/local.properties` removed from version control

Contains `MAPS_API_KEY` (real key) and machine-specific SDK paths. Now
git-ignored and regenerated per machine.

### 5. Client Firebase identifiers committed (safe)

`android/app/google-services.json` and the Android options in
`lib/firebase_options.dart` contain **public client identifiers** (API key,
app id, project number). These are not secrets — they ship inside every
published APK. They are committed intentionally so the project builds
out-of-the-box.

## Documented — REQUIRES FUTURE ARCHITECTURAL CHANGE

These findings were **not** changed in this release because fixing them
requires architectural changes to the backend. They are documented here as
required follow-ups **before public launch**.

### A. Firestore security rules

Firestore rules were reviewed as too permissive for production (data
accessible beyond the signed-in owner's scope). Required hardening:

- Scope reads/writes to `request.auth.uid`.
- Protect vendor/admin collections from arbitrary client writes.
- Use granular rules for order and cart collections.

Status: **REQUIRES FUTURE ARCHITECTURAL CHANGE** — apply before launch.

### B. Cloud Storage rules

Storage rules should allow only authenticated uploads confined to
`users/{userId}/...`. Status: **REQUIRES FUTURE SECURITY REVIEW**.

### C. Cloud Functions authentication

`functions/index.js` and `support-ai/index.js` should validate the caller's
Firebase ID token (ID-token verification) before acting on the Razorpay or
support-AI flows. The Razorpay key **secret** and Gemini key must live in
Firebase config/Secret Manager, not client code. Status: **REQUIRES FUTURE
SECURITY REVIEW**.

## Recurring checks

Before committing or releasing:

1. Run the repository secret scan gate (see `docs/development.md` / CI).
2. `git grep -iE 'rzp_(test|live)_[0-9a-zA-Z]{10,}|AIza[0-9A-Za-z_-]{20,}|BEGIN (RSA |EC |)PRIVATE KEY'`
   (excluding `google-services.json` and `lib/firebase_options.dart`, which
   intentionally carry public Firebase client keys) must return nothing
   outside safe placeholders.
3. Confirm no `*.keybox`, `*.pem`, `*.keystore`, `.env` (non-example) files
   are staged: `git status --porcelain`.
