from fastapi import Header, HTTPException, status
from jose import jwt, JWTError
from .config import settings


def get_current_user_id(authorization: str = Header(...)) -> str:
    """Verifies the Supabase-issued JWT the Flutter app sends as
    `Authorization: Bearer <token>` and returns the authenticated user's id.
    Every endpoint that acts on behalf of a specific user depends on this —
    never trust a user_id passed in the request body instead."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token missing subject")
    return user_id


def verify_jobs_secret(x_job_secret: str = Header(...)) -> None:
    """Guards the /jobs/* endpoints so only your scheduler (cron / Cloud
    Scheduler / GitHub Actions) can trigger batch jobs — never exposed to
    the Flutter app."""
    if x_job_secret != settings.jobs_secret:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Invalid job secret")
