# Frontend Architecture — Clean Architecture (Flutter)

## Actual Layout (implemented)
```
frontend/lib/
  core/
    constants/api_constants.dart   # API_BASE_URL from env (default http://localhost:8080)
    network/
      api_client.dart              # Dio singleton + _AuthInterceptor (JWT refresh on 401)
      secure_storage.dart          # Conditional export: native → secure_storage_native.dart, web → secure_storage_web.dart
      secure_storage_native.dart   # flutter_secure_storage (Android EncryptedSharedPrefs, iOS Keychain)
      secure_storage_web.dart      # shared_preferences (localStorage) — flutter_secure_storage breaks on web
    router/app_router.dart         # GoRouter + routerProvider; root `/` always redirects (auth or home)
    theme/app_theme.dart           # AppColors, AppTextStyles, AppRadius, AppTheme.light()
  features/
    auth/                          # sign up / sign in
    trips/                         # home, create trip, timeline, itinerary review, public trip
    checkin/                       # check-in create/view
    profile/                       # profile page
```

Each feature: data/(datasources, models, repositories) → domain/(entities, repositories, usecases) → presentation/(pages, providers)

## Key Implementation Notes
- `SecureStorageService` uses conditional file export (`dart.library.html`) — never import flutter_secure_storage on web (causes OperationError from Web Crypto API)
- Router redirect: `state.matchedLocation == AppRoutes.root` → always redirect; `goingToAuth` only matches `/auth` not `/`
- Handle validation: strip leading `@` before send; frontend regex matches backend `^[a-z0-9_]{3,30}$`
- API base URL via `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080')`

## Platforms
- Web (Chrome): working. Run: `flutter run -d chrome` from `frontend/`
- macOS: scaffolded. Requires Xcode.app (not just CLI tools). Entitlements: network.client added.
- Android/iOS: not yet scaffolded.

## Key Dependencies
- `flutter_riverpod: ^2.5.1` — state management (AsyncNotifier for auth)
- `go_router: ^14.0.0` — navigation
- `dio: ^5.4.3` — HTTP + interceptors
- `flutter_secure_storage: ^9.0.0` — native token storage
- `shared_preferences: ^2.3.0` — web token storage fallback
- `google_fonts: ^6.2.1`
- `image_picker: ^1.1.2`

## Design System
Colors: teal #1D9E75, coral #D85A30, amber #BA7517, bg #F8F6F1
Fonts: DM Sans (body), DM Serif Display (headings)
5-tab bottom nav: Trips, Explore (V2), +, Activity, Profile

## 9 Screens
1. Sign up/login  2. Home trip list  3a. Create trip  3b. Invite collaborators
4a. AI generating  4b. Itinerary review  5. Trip timeline  5b. Check-in  6. Published view