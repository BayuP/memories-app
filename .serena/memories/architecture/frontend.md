# Frontend Architecture — Clean Architecture (Flutter)

## Structure
```
frontend/lib/
  core/                    # App-wide shared infrastructure
    config/                # API base URL, env config
    theme/                 # Colors, typography (DM Sans + DM Serif Display), spacing
    router/                # App routing (go_router)
    network/               # HTTP client, interceptors, auth header injection
    constants/             # App-wide constants
    utils/                 # Helpers (date formatting, EXIF reader, etc.)
  features/                # Feature-based clean architecture
    auth/                  # Sign up, login
    trips/                 # Home, create trip, trip list
    itinerary/             # AI generation, review, reorder
    checkin/               # Check-in screen, timeline, spontaneous
    profile/               # User profile, settings
  shared/
    widgets/               # Cross-feature reusable widgets (bottom nav, avatar stack)
    models/                # Shared data models
```

Each feature follows: data/ (datasources, models, repositories) → domain/ (entities, repositories, usecases) → presentation/ (pages, widgets, providers)

## 9 Screens
1. Sign up/login  2. Home trip list  3a. Create trip  3b. Invite collaborators
4a. AI generating  4b. Itinerary review  5. Trip timeline  5b. Check-in  6. Published view

## Design System
Colors: teal #1D9E75, coral #D85A30, amber #BA7517, bg #F8F6F1
Fonts: DM Sans (body), DM Serif Display (headings)
5-tab bottom nav: Trips, Explore (V2), +, Activity, Profile