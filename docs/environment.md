# Environment

This app uses **client-side configuration** values. Anything bundled into a
distributed app can be extracted, so every value below must be treated as
**public client configuration**, never as a protected secret.

## `.env` (Flutter client, git-ignored)

Loaded at runtime by `flutter_dotenv` (`dotenv.load(isOptional: true)` in
`lib/main.dart`). A template lives at `.env.example`.

| Key                 | Used by                                                            | Notes                                        |
| ------------------- | ------------------------------------------------------------------ | -------------------------------------------- |
| `ENVIRONMENT`       | App configuration                                                  | `development` or `production`.               |
| `RAZORPAY_KEY_ID`   | `lib/features/checkout/.../checkout_providers.dart`                | Public Razorpay client key (`rzp_test_*` in test). The **key secret** must never appear here — it lives server-side only. |
| `GEMINI_API_KEY`    | `support-ai/` Cloud Function (server-side)                         | Not read by the Flutter app; listed for completeness. |

## Google Maps / Places key

- **Android Maps SDK key:** injected at build time via the manifest
  placeholder from `android/local.properties` (`MAPS_API_KEY`). That file is
  **git-ignored**.
- **Places REST key (Dart):** `lib/features/address/data/services/places_service.dart`
  contains the placeholder `YOUR_GOOGLE_MAPS_API_KEY`. Replace it with your
  own key for local development — real keys must never be committed.

## Firebase

- Client API keys / app ids live in `android/app/google-services.json` and in
  `lib/firebase_options.dart` (sourced from that file). These are **public
  client identifiers**, safe to commit.
- `functions/.env` / `functions/.env.biteo-1e76d` (Razorpay secret, Gemini key)
  are **git-ignored** and must be supplied on the developer machine; prefer
  Firebase config or Secret Manager in production.

## What is git-ignored

- `.env`, `.env.*` (except `.env.example`)
- `android/local.properties`, `android/key.properties`
- `linux/yk50.xml` and any `*.keybox` (Android Attestation — private keys!)
- `node_modules/`, `build/`, `.dart_tool/`, ephemeral dirs, IDE files
