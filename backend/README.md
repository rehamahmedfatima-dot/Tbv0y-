# TBVOY Backend (FastAPI)

Server-side operations the Flutter app cannot safely perform itself:

| Endpoint | Purpose |
|---|---|
| `DELETE /account` | Permanently deletes the signed-in user's account (needs the Supabase service_role key) |
| `POST /notifications/register-token` | Stores the caller's FCM token |
| `POST /notifications/send-test` | Sends the caller a test push |
| `POST /jobs/generate-daily-missions` | Batch-generates today's AI mission for every user |
| `POST /jobs/compute-discipline-scores` | Nightly rollup of yesterday's Discipline Score for every user |
| `POST /jobs/send-habit-reminders` | Pushes reminders for incomplete habits whose reminder time just passed |
| `GET /health` | Health check |

`/jobs/*` endpoints require an `X-Job-Secret` header matching `JOBS_SECRET`
in your `.env` — only your scheduler should call these, never the app.

## Local setup

```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env              # fill in real values
# download your Firebase service account JSON, save it as
# firebase-service-account.json in this folder (or update the path in .env)
uvicorn app.main:app --reload --port 8000
```

Visit `http://localhost:8000/docs` for interactive API docs (Swagger UI).

## Deployment

Any container host works (Railway, Render, Fly.io, Cloud Run). The
important part: set the same environment variables from `.env.example`
as the host's secrets/env config, and set `BACKEND_API_URL` in the
Flutter app's `.env` to the deployed URL.

## Scheduling the /jobs endpoints

These need to be called on a schedule from *outside* the app — e.g.:

- **Supabase pg_cron** (Database → Cron Jobs) calling the endpoints via
  `pg_net.http_post`
- **GitHub Actions** scheduled workflow (`on: schedule`) doing a `curl`
- **Cloud Scheduler** (if deployed on Google Cloud Run)

Suggested schedule:
- `generate-daily-missions` — once daily, early morning (e.g. 00:05)
- `compute-discipline-scores` — once daily, just after midnight
- `send-habit-reminders` — every 15 minutes
