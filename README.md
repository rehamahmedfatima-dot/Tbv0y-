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
        │   ├── achievements/         # Phase 6
        │   ├── skills/               # Phase 6
        │   ├── books/                # Phase 6
        │   ├── letters/              # Phase 6
        │   ├── my_journey/           # Phase 6
        │   ├── my_story/             # Phase 6
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
- [x] **Phase 2** — Auth (Supabase Auth: Google/Apple/Email/Anonymous/OTP/Biometric) + Onboarding flow (5 pages + AI identity analysis via Gemini) + go_router wiring
- [x] **Phase 3** — Home dashboard (Discipline Score, Growth Tree, AI mission, mood, weekly chart) + Habits module (full CRUD, streaks, stats)
- [x] **Phase 4** — AI Coach (chat + weekly/monthly AI reports) + Discipline Score engine (already powering Home in Phase 3)
- [x] **Phase 5** — Journal (AI summaries + mood-pattern insight), Mood Tracker (chart + AI activity suggestions), Goals (AI roadmap + milestones), Focus Mode (Pomodoro/Deep Work/Forest timer + stats)
- [x] **Phase 6** — Achievements/XP/Levels, Challenges (30/100-day + custom), Legacy (mission/values/AI alignment check), Time Machine, My Journey (aggregator), My Story (AI annual report)
- [x] **Phase 7** — FastAPI backend: account deletion, push notifications, and scheduled batch jobs (daily AI missions, nightly discipline score rollup, habit reminders) — see `backend/README.md`
- [x] **Phase 8** — Settings (theme/language/AI style/notification times), push notifications (FCM + local display), biometric app lock, data export (CSV + PDF)

## 🎉 All 8 phases complete
TBVOY now has: auth, onboarding, home dashboard, habits, AI coach, journal,
mood tracking, goals, focus mode, achievements/challenges/skills/books,
letters, legacy, time machine, My Journey, My Story, a FastAPI backend,
and settings/notifications/security. See each feature's file-path table
in the conversation history for exactly where every file goes.

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
