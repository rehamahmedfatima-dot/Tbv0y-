from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import account, notifications, jobs, health

app = FastAPI(
    title="TBVOY API",
    description="Server-side operations for TBVOY that the Flutter app "
    "cannot safely perform itself: account deletion, push notifications, "
    "and scheduled batch jobs (daily missions, discipline score rollups, "
    "habit reminders).",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter mobile/web clients only call specific
    allow_credentials=True,  # endpoints with a verified user JWT — safe to
    allow_methods=["*"],  # keep open; tighten to your web domain if you
    allow_headers=["*"],  # ship the Flutter web build publicly.
)

app.include_router(health.router)
app.include_router(account.router)
app.include_router(notifications.router)
app.include_router(jobs.router)
