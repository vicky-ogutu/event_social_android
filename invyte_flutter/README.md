# Invyte (Flutter)

Plan events, book trusted vendors, and share the moment live. This is the Flutter port of the original Kotlin/Compose Android app in this repo.

## Run it

```bash
flutter pub get
flutter run                                    # API at http://10.0.2.2:3000 (Android emulator → host)
flutter run --dart-define=API_BASE_URL=https://api.example.com --dart-define=SOCKET_URL=https://api.example.com
```

Optional `--dart-define`s:

| Key | Purpose |
| --- | --- |
| `STRIPE_PUBLISHABLE_KEY` | Overrides the key from `GET /api/payments/config` |
| `APPLE_MERCHANT_ID` | Enables Apple Pay in the payment sheet (iOS) |
| `TURN_URL`, `TURN_USERNAME`, `TURN_CREDENTIAL` | TURN relay for live video on strict networks (e.g. self-hosted coturn) |

**Demo mode:** on the sign-in screen, tap **Event host** or **Vendor** under "Or take the tour". The app then runs against an in-memory copy of the API (`lib/core/demo/`) with seeded vendors, events, bookings, posts and chats, so no backend is needed. Demo credentials: `amara@invyte.app` / `daniel@lumiere.studio`, password `demo1234`.

## Architecture

Feature-first clean architecture:

```
lib/
  app/                 MaterialApp, go_router routes, bottom-nav shell
  core/
    config/            compile-time config (--dart-define)
    network/           ApiClient (package:http): auth header, envelope unwrap, errors → Failure
    storage/           LocalStorage (shared_preferences): session, onboarding, theme
    realtime/          RealtimeService (Socket.IO) for chat
    demo/              DemoBackend: in-memory API exposed as an http.Client
    di/                app-wide Riverpod providers
    theme/ widgets/ utils/
  features/<feature>/
    domain/            entities + repository interfaces (pure Dart)
    data/              mappers (JSON ↔ entity), remote data sources, repository impls
    presentation/      Riverpod providers/notifiers, screens, widgets
```

Features: `auth`, `events`, `vendors`, `bookings` (with payments), `social` (feed, comments, event chat), `messaging`, `profile`, `livestream`, `home`.

- **State:** Riverpod 3 (`Notifier`, `AsyncNotifier`, `FutureProvider`). Repositories watch a session-scope provider, so every cached query resets on sign-out or account switch.
- **Demo mode** swaps only the `http.Client`. Data sources, repositories and providers run the same code in both modes.

## Tests

```bash
flutter analyze && flutter test
```

The tests cover `ApiClient` error handling, JSON mapping, an end-to-end book → pay → vendor-accepts flow through the real providers, session persistence, and app start-up routing.

## Payments

Checkout runs `create-intent` → Stripe **PaymentSheet** (cards, Google Pay, Apple Pay) → `POST /api/payments/confirm`. The server checks the PaymentIntent with Stripe and marks the booking paid, so this works even before webhooks are set up. Stream passes use the same sheet, followed by `confirm-purchase`. The backend needs `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` (use test keys).

## Live video

Live video is peer-to-peer WebRTC (`flutter_webrtc`), and it's free: there is no media server. The host's phone sends its camera to each viewer, and the backend only relays signalling over Socket.IO (`live:host`, `live:join`, `live:signal`, …). The practical limit is roughly 5–10 viewers per broadcast, set by the host's upload bandwidth. Most networks only need the Google STUN servers; add a TURN server through the `TURN_*` dart-defines for strict corporate or mobile NATs.

In demo mode the host sees their real camera, but there's no relay, so demo viewers see a placeholder instead.

## Demo photos

The demo content uses curated Creative Commons photos bundled in `assets/demo/`, so it works offline. Attribution is in `assets/demo/CREDITS.md` and on the in-app licenses page (Profile → About → View licenses).
