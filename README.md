# Lullify Mobile

Lo-fi radio streaming app built with Flutter. Listeners browse live stations, tune in to HLS audio streams, favorite the ones they love and keep track of their listening history. Broadcasters manage their own streams, and admins get a dedicated panel with platform metrics.

The app talks to the [Lullify backend](https://github.com/Sukeshi7/Lullify_Backend), a Go API that handles auth, streaming, playlists and observability.

## Features

- Email/password authentication with JWT (access + refresh) stored in secure storage, with automatic token refresh and session-expiry handling
- Live stream list with real-time listener counts (5s polling) and pull-to-refresh
- HLS audio playback through `just_audio` + `audio_service`, with background playback and media notifications
- Favorites, listening history, user profile
- Role-based UI: listener, broadcaster (dashboard) and admin (user management + platform stats)
- Vaporwave design system: custom theme, pixel-art splash animation, lo-fi page transitions
- WCAG-minded accessibility: semantic labels, contrast-checked palette

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3 (Dart ≥ 3.11) |
| State management | Riverpod 2 (`StateNotifier`) |
| Navigation | go_router with auth-aware redirects |
| HTTP | Dio with a JWT interceptor (auto-refresh on 401) |
| Audio | just_audio + audio_service (HLS) |
| Secure storage | flutter_secure_storage |
| Fonts | Google Fonts (VT323, Quicksand) |

## Architecture

The codebase follows Clean Architecture, one direction of dependency: presentation → domain ← data.

```
lib/
├── core/           # app shell, router, theme, network (Dio client), constants
├── data/           # datasources (REST calls), models (JSON), repository implementations
├── domain/         # entities and repository interfaces — pure Dart, no Flutter imports
├── presentation/   # pages, widgets, Riverpod providers
└── services/       # audio handler (just_audio / audio_service bridge)
```

Repositories are exposed through Riverpod providers, which makes every page testable by overriding the repository provider with a fake — no mocking framework needed.

## Getting started

Prerequisites: Flutter SDK ≥ 3.x, a running backend (local or remote).

```bash
git clone https://github.com/azat44/Lullify_Frontend.git
cd Lullify_Frontend
flutter pub get
```

Run against a local backend (default `http://localhost:8080/api/v1`):

```bash
flutter run
```

Run against the hosted dev backend:

```bash
flutter run --dart-define=API_BASE_URL=https://lullifybackend-dev.up.railway.app/api/v1
```

The API base URL is a compile-time define (`AppConstants.apiBaseUrl`), so no secrets live in the repo.

## Tests

Widget tests cover the critical pages (auth, home/stream list, player, profile, admin, history):

```bash
flutter test
```

An integration test drives the real app end to end — splash → login → stream list → player → sign out — with faked repositories. It needs a desktop or mobile device:

```bash
flutter test integration_test/ -d macos
```

## CI

Every push and pull request runs `flutter analyze` and the widget test suite through GitHub Actions (see `.github/workflows/`). Branches follow `feat/…`, `test/…`, `docs/…` and merge into `develop` through reviewed pull requests.