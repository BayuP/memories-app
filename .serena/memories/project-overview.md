# Trip Memory App — Project Overview

## What
Flutter + Go app for planning, capturing, and remembering shared experiences.
Personal project by Bayu. No launch pressure.

## Stack
- Frontend: Flutter (iOS + Android) — clean architecture with feature-based structure
- Backend: Go modular monolith — clean architecture (domain → usecase → adapter → infrastructure)
- Database: PostgreSQL 16 (managed, Singapore region)
- Storage: Cloudflare R2 (S3-compatible)
- AI: Anthropic API (claude-sonnet with web search) for itinerary generation
- Auth: Email/password + Google OAuth, JWT (15min access, 30d refresh)

## Core Flow
1. Plan — Create trip → invite collaborators → AI generates full itinerary (departure to return)
2. Capture — Timeline view during trip, check-in at places (photos/videos/notes), spontaneous moments via EXIF
3. Remember — AI recap (V1.5), published trip view shows recommendations only

## Privacy Rule (CRITICAL)
checkin_logistics data NEVER leaves DB for AI calls, public endpoints, or published views. Enforced at code level.

## V1 Success
Use with wife on one real trip + three small hangouts. Must feel better than WhatsApp + Notes.

## Source Docs
PRD v2, TRD v1, Visual Spec v1 at /Users/bayupabisa/Downloads/Memories App/