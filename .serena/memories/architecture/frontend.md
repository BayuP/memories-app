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

## Design System (updated May 2026 — warm cream direction locked)
Colors: bg #F5F3EF (warm cream), primary #1A1815 (near-black CTAs), text #2D2A26, textSecondary #8A7F75, border #E8E4DE — NO teal/coral
Fonts: Playfair Display italic (display/headings), Inter (body/UI) — via google_fonts
Single theme source: `core/theme/app_theme.dart` — `ui/theme/app_theme.dart` deleted
5-tab bottom nav: Trips, Explore (V2 disabled), +, Activity, Profile
Active nav: #1A1815, inactive: textMuted. No teal nav indicator.

## UI screens (lib/ui/screens/ — agent-generated, warm cream styled)
10 screens: sign_in, home, create_trip, ai_generating, ai_itinerary_review,
trip_view, check_in, edit_check_in, spontaneous_add_sheet, published_trip

## 9 Reusable widgets (lib/ui/widgets/)
trip_card, collaborator_avatars, vibe_chip, status_badge, layer_tabs,
media_thumbnail_strip, day_selector_strip, timeline_item, spontaneous_bucket

## HTML Prototypes (design reference)
Warm cream (approved): design/html-prototype/ — 10 screens, Playfair italic, #F5F3EF bg
Clean minimalist (comparison): design/html-prototype-clean/ — Inter only, pure white
Warm cream direction approved by Bayu. Clean variant kept for reference only.