# Deployment

## App (Flutter)

The app is published through the normal Android release flow:

1. Bump the version in `pubspec.yaml` (e.g. `1.0.0+1`).
2. Build a release bundle:

   ```sh
   flutter build appbundle --release
   ```

3. Upload `build/app/outputs/bundle/release/app-release.aab` to the Google
   Play Console for the `com.biteo.biteo` application, then promote through
   internal/closed/open tracks.

Release artifacts and their checksums are provided alongside each tagged
release:

- `biteo-app-v1.0.0.zip`
- `SHA256SUMS.txt`

### Release checklist

- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Version bumped in `pubspec.yaml` and tagged `v<version>`.
- [ ] No secrets in the tree (see [security.md](security.md)).
- [ ] Real `android/app/google-services.json` present in the build
      environment and matching the Play application id `com.biteo.biteo`
      (the committed file is only a placeholder template).

## Firebase / Cloud Functions

Firebase resources (Authentication, Firestore, Storage, Cloud Messaging,
Functions) belong to the `biteo-1e76d` project.

```sh
# Deploy both functions codebases (default + support-ai)
firebase deploy --only functions
```

Backend configuration lives in `functions/.env` /
`functions/.env.biteo-1e76d` **on the developer's machine only** — these
files are git-ignored. In production, prefer Firebase environment variables
or Secret Manager for values such as the Razorpay key secret and the Gemini
API key.

### Firestore / Storage security

Before public launch, apply **defense-in-depth rules** (documented in
[docs/security.md](security.md)):

- Firestore rules must restrict reads/writes to the signed-in user's own
  data (e.g. `request.auth.uid`-scoped), with vendor/admin collections
  protected from client writes.
- Storage rules must allow only authenticated uploads to
  `users/{userId}/...` paths.
- Cloud Functions must re-validate the caller's identity (ID-token checks)
  before performing privileged operations.

These changes are **architecture-level** and out of scope for this release;
the current rules/functions are documented as requiring future review.
