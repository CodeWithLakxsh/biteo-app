# Architecture

## Overview

The Biteo App is a Flutter application organized around **clean
architecture**. Shared infrastructure lives under `lib/core/`, and product
capabilities are implemented as independent `features/` modules. Each feature
is further split into three layers:

- **`data/`** — repositories, models, and remote/local datasources.
- **`domain/`** — entities and repository contracts (interfaces).
- **`presentation/`** — screens, widgets, providers/notifiers.

State management is handled with **Riverpod** (`flutter_riverpod`). Routing
uses **go_router**.

## Source layout

```
lib/
├── main.dart                 # App entry: dotenv, Firebase init, Router
├── firebase_options.dart     # FlutterFire options (Android client)
├── core/
│   ├── errors/               # Shared failure types
│   ├── providers/            # Cross-cutting Riverpod providers
│   ├── router/               # go_router configuration
│   ├── services/             # Shared services (e.g. Places REST helper)
│   ├── theme/                # App theme
│   └── widgets/              # Shared widgets
└── features/
    ├── auth/                 # Sign in / sign up, session
    ├── home/                 # Home feed, vendor browsing
    ├── vendor/               # Vendor detail, menu
    ├── cart/                 # Cart entity + business rules
    ├── address/              # Address book, Google Maps/Places
    ├── checkout/             # Order placement, Razorpay payment
    └── profile/              # User profile
```

## Feature example — Cart

`lib/features/cart/domain/entities/cart_entity.dart` defines plain Dart
immutable value objects:

- `CartItemEntity` — one menu item with an immutable `unitPricePaise`
  snapshot and `lineTotalPaise` / display getters.
- `CartEntity` — a user's cart scoped to one vendor, with `expiresAt` (5-minute
  lock), `isExpired`, `totalItemCount`, `quantityOf`, and `copyWith`.
- `CartFailure` — sealed failure variants (`differentVendor`,
  `insufficientStock`, `cartExpired`, ...), each exposing a `userMessage`.

These types have **no code generation** (plain Dart), which keeps them
directly testable in CI without Flutter/Firebase dependencies.

## Backend (Cloud Functions)

Two Firebase Cloud Functions codebases ship alongside the app:

| Codebase      | Source dir     | Purpose                                        |
| ------------- | -------------- | ---------------------------------------------- |
| `default`     | `functions/`   | Backend logic (e.g. Razorpay order handling).  |
| `support-ai`  | `support-ai/`  | Gemini-powered support assistant.              |

Both are deployed to the Firebase project `biteo-1e76d` (see `.firebaserc`
and `firebase.json`).

## Platform targets

Only **Android** is fully configured for Firebase (`google-services.json` in
`android/app/`). `DefaultFirebaseOptions.currentPlatform` throws
`UnsupportedError` for iOS, web, macOS, Windows, and Linux; the web and
desktop host folders are unconfigured shells.

## Testing

- `test/cart_entity_test.dart` — pure Dart unit tests (no Flutter binding).
- CI runs `flutter analyze` and `flutter test` on every push/PR.
