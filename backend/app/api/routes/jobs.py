from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends
from ...core.security import verify_jobs_secret
from ...core.supabase_client import get_admin_client
from ...services.gemini_service import generate_text
from ...services.fcm_service import send_push

router = APIRouter(prefix="/jobs", tags=["jobs"], dependencies=[Depends(verify_jobs_secret)])


@router.post("/generate-daily-missions")
def generate_daily_missions():
    """Runs once a day (e.g. 00:05 server time) so every user opens the
    app to an AI mission that's already waiting for them, instead of
    generating it on first open and making them wait. Skips users who
    already have today's mission (idempotent — safe to re-run)."""
    admin = get_admin_client()
    today = date.today().isoformat()

    users = admin.table("users").select("id, display_name").execute().data
    created = 0

    for user in users:
        existing = (
            admin.table("ai_missions")
            .select("id")
            .eq("user_id", user["id"])
            .eq("mission_date", today)
            .maybe_single()
            .execute()
        )
        if existing.data:
            continue

        habits = (
            admin.table("habits")
            .select("title")
            .eq("user_id", user["id"])
            .eq("is_active", True)
            .limit(5)
            .execute()
            .data
        )
        habit_titles = ", ".join(h["title"] for h in habits) or "no habits yet"

        prompt = (
            "Generate one small, specific, achievable mission for today for "
            "a personal-growth app user. Their current habits: "
            f"{habit_titles}. Respond with just the mission title, under 10 words, "
            "e.g. 'Read 10 pages' or 'Walk for 20 minutes'."
        )
        title = generate_text(prompt) or "Take one small step forward today"

        admin.table("ai_missions").insert(
            {"user_id": user["id"], "mission_date": today, "title": title}
        ).execute()
        created += 1

    return {"status": "ok", "missions_created": created, "total_users": len(users)}


@router.post("/compute-discipline-scores")
def compute_discipline_scores():
    """Nightly rollup: computes yesterday's discipline score for every
    user from their habit/mood/journal/focus activity, so the Home
    dashboard's weekly trend chart has a permanent record even for days
    the user never opened the app. Mirrors the same weighting the
    client-side calculator uses in supabase_home_repository.dart."""
    admin = get_admin_client()
    yesterday = (date.today() - timedelta(days=1)).isoformat()

    users = admin.table("users").select("id").execute().data
    computed = 0

    for user in users:
        uid = user["id"]

        habit_logs = (
            admin.table("habit_logs")
            .select("completed")
            .eq("user_id", uid)
            .eq("log_date", yesterday)
            .execute()
            .data
        )
        habit_score = (
            0
            if not habit_logs
            else round(100 * sum(1 for h in habit_logs if h["completed"]) / len(habit_logs))
        )

        journal_count = (
            admin.table("journal_entries")
            .select("id")
            .eq("user_id", uid)
            .eq("entry_date", yesterday)
            .execute()
            .data
        )
        journal_score = 100 if journal_count else 0

        mood_row = (
            admin.table("mood_logs")
            .select("mood_score")
            .eq("user_id", uid)
            .eq("log_date", yesterday)
            .maybe_single()
            .execute()
        )
        mood_score = (mood_row.data["mood_score"] * 20) if mood_row.data else 50

        focus_logs = (
            admin.table("focus_sessions")
            .select("duration_minutes, completed")
            .eq("user_id", uid)
            .gte("started_at", f"{yesterday}T00:00:00")
            .lte("started_at", f"{yesterday}T23:59:59")
            .execute()
            .data
        )
        focus_minutes = sum(f["duration_minutes"] for f in focus_logs if f["completed"])
        focus_score = min(100, round(focus_minutes / 60 * 100))

        overall = round(
            habit_score * 0.4 + journal_score * 0.2 + mood_score * 0.2 + focus_score * 0.2
        )

        admin.table("discipline_scores").upsert(
            {
                "user_id": uid,
                "score_date": yesterday,
                "overall_score": overall,
                "habit_completion_score": habit_score,
                "journal_score": journal_score,
                "mood_score": mood_score,
                "focus_score": focus_score,
            },
            on_conflict="user_id,score_date",
        ).execute()
        computed += 1

    return {"status": "ok", "scores_computed": computed}


@router.post("/send-habit-reminders")
def send_habit_reminders():
    """Runs every ~15 minutes. Pushes a reminder to any user whose
    configured reminder time for an incomplete habit just passed."""
    admin = get_admin_client()
    now = datetime.now()
    window_start = (now - timedelta(minutes=15)).strftime("%H:%M:00")
    window_end = now.strftime("%H:%M:00")
    today = date.today().isoformat()

    habits = (
        admin.table("habits")
        .select("id, user_id, title, reminder_times")
        .eq("is_active", True)
        .execute()
        .data
    )

    sent = 0
    for habit in habits:
        reminder_times = habit.get("reminder_times") or []
        if not any(window_start <= t <= window_end for t in reminder_times):
            continue

        log = (
            admin.table("habit_logs")
            .select("completed")
            .eq("habit_id", habit["id"])
            .eq("log_date", today)
            .maybe_single()
            .execute()
        )
        if log.data and log.data.get("completed"):
            continue  # already done — no need to nag

        settings_row = (
            admin.table("user_settings")
            .select("fcm_token")
            .eq("user_id", habit["user_id"])
            .maybe_single()
            .execute()
        )
        token = (settings_row.data or {}).get("fcm_token")
        if not token:
            continue

        send_push(token, "Habit reminder", f"Time for: {habit['title']}")
        sent += 1

    return {"status": "ok", "reminders_sent": sent}
