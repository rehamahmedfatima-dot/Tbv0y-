# TBVOY — The Best Version Of Yourself

_"Small Actions. Big Transformation."_

An AI-powered personal growth platform: habits, identity building, discipline
scoring, journaling, mood tracking, goals, and an AI coach — built to feel
like Fabulous × Notion × Reflectly, with its own identity.

## Repo layout

```
tbvoy/
├── database/
│   └── schema.sql          # Full Supabase Postgres schema (Phase 1 ✅)
├── backend/                 # FastAPI service (Phase 7)
│   ├── app/
│   │   ├── api/             # routers per domain (habits, journal, ai, auth...)
│   │   ├── core/             # config, security, deps
│   │   ├── models/           # SQLAlchemy / Pydantic models
│   │   ├── services/         # business logic (discipline score engine, AI orchestration)
│   │   └── main.py
│   └── requirements.txt
└── flutter_app/
    └── lib/
        ├── core/
        │   ├── theme/         # app_colors.dart, app_spacing.dart, app_theme.dart (Phase 1 ✅)
        │   ├── constants/
        │   ├── router/        # go_router config
        │   ├── network/       # dio client, interceptors
        │   ├── storage/       # hive boxes, sqlite, secure storage
        │   └── utils/
        ├── features/
        │   ├── auth/                 # Phase 2
        │   ├── onboarding/           # Phase 2
        │   ├── home/                 # Phase 3
        │   ├── habits/               # Phase 3
        │   ├── ai_coach/             # Phase 4
        │   ├── identity_builder/     # Phase 4
        │   ├── discipline_score/     # Phase 4
        │   ├── journal/              # Phase 5
        │   ├── mood_tracker/         # Phase 5
        │   ├── goals/                # Phase 5
        │   ├── focus_mode/           # Phase 5
        │   ├── challenges/           # Phase 6
        │   ├── my_journey/           # Phase 6
        │   ├── my_story/             # Phase 6
        │   ├── growth_tree/          # Phase 6
        │   ├── time_machine/         # Phase 6
        │   ├── legacy/               # Phase 6
        │   ├── notifications/        # Phase 8
        │   └── settings/             # Phase 8
        └── main.dart

Each feature module follows Clean Architecture internally:
    feature/
      data/        (models, remote + local data sources, repository impls)
      domain/      (entities, repository interfaces, use cases)
      presentation/(riverpod providers, screens, widgets)
```

## Build roadmap

- [x] **Phase 1** — Database schema + Flutter project foundation (theme, spacing, pubspec)
- [~] **Phase 2** — Auth (Supabase Auth: Google/Apple/Email/Anonymous/OTP/Biometric) ✅ + Onboarding flow (next)
- [ ] **Phase 3** — Home dashboard + Habits module (full CRUD, offline-first via Hive)
- [ ] **Phase 4** — AI Coach + Identity Builder + Discipline Score engine
- [ ] **Phase 5** — Journal, Mood Tracker, Goals, Focus Mode
- [ ] **Phase 6** — Challenges, My Journey, My Story, Growth Tree, Time Machine, Legacy
- [ ] **Phase 7** — FastAPI backend (all REST endpoints) + AI integration layer
- [ ] **Phase 8** — Notifications, Settings, security hardening, export/backup, polish & animations

## Why phased delivery

TBVOY's spec covers 20+ full feature modules across a Flutter app, a FastAPI
backend, an AI layer, and a normalized database — the scope of a real
multi-month team project. Building it phase by phase means every file
delivered is complete, working code (no stubs, no TODOs) rather than a
shallow skeleton pretending to be the whole app.

## Setup

### 1. Supabase (database + auth)
1. Create a project at https://supabase.com
2. Run the schema: `psql <your-connection-string> -f database/schema.sql`
   (or paste it into the Supabase SQL Editor)
3. In **Authentication → Providers**, enable Google, Apple, Email, and
   Anonymous sign-ins.
4. Copy your **Project URL** and **anon public key** from
   *Project Settings → API*.

### 2. Gemini (AI features)
1. Go to https://aistudio.google.com/apikey
2. Create an API key (free tier is enough for development).

### 3. Flutter app
```bash
cd flutter_app
cp .env.example .env        # then fill in SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY
flutter pub get
flutter run
```

> Auth (Google/Apple native sign-in) also needs standard platform setup —
> `google-services.json` / `GoogleService-Info.plist` for FCM, plus the
> Google Sign-In `serverClientId` and Apple's Sign in with Apple capability
> in Xcode. These are documented per-platform in Phase 8 (final polish).
