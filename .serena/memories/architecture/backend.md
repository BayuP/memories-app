# Backend Architecture — Clean Architecture (Go)

## Layer Structure
```
backend/
  cmd/server/              # Entry point, wire dependencies
  internal/
    domain/                # Core business logic — NO external dependencies
      entity/              # Trip, User, Checkin, ItineraryItem, Media, etc.
      repository/          # Repository interfaces (ports)
      service/             # Domain services (business rules)
    usecase/               # Application logic — orchestrates domain
      auth/                # JWT, OAuth, register/login
      user/                # Profile, handle search
      trip/                # CRUD, member management, status transitions
      itinerary/           # Item CRUD, sort order, reorder
      checkin/             # 3-layer check-in write/read, timeline queries
      media/               # Upload orchestration, EXIF extraction
      ai/                  # Itinerary generation + refinement
      notification/        # Activity feed, push dispatch
      publish/             # Public queries, privacy filter
    adapter/               # Interface adapters — implements ports
      handler/http/        # HTTP handlers
      handler/middleware/  # Auth, trip membership, rate limiting
      repository/postgres/ # PostgreSQL implementations of repository interfaces
      storage/s3/          # S3/R2 client
      external/anthropic/  # Anthropic API client
      external/google/     # Google OAuth client
    infrastructure/        # Frameworks and drivers
      config/              # Env config loading
      database/            # Postgres connection, pgBouncer
      server/              # HTTP server setup, router
  migrations/              # Numbered SQL migration files
  pkg/                     # Shared utilities (exported)
    validator/             # Input validation
    response/              # Standard API response helpers
    jwt/                   # JWT token utilities
```

## Dependency Rule
domain ← usecase ← adapter ← infrastructure
Inner layers never import outer layers. Interfaces defined in domain, implemented in adapter.

## 9 Database Tables
users, trips, trip_members, itinerary_items, checkins, checkin_memory, checkin_logistics, checkin_recommendations, media