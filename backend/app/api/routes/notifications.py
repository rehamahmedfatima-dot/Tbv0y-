from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ...core.security import get_current_user_id
from ...core.supabase_client import get_admin_client
from ...services.fcm_service import send_push

router = APIRouter(prefix="/notifications", tags=["notifications"])


class RegisterTokenRequest(BaseModel):
    fcm_token: str


@router.post("/register-token")
def register_token(body: RegisterTokenRequest, user_id: str = Depends(get_current_user_id)):
    """Stores/updates the caller's FCM token so scheduled jobs can reach
    their device. Called by the Flutter app once on startup and whenever
    the token refreshes."""
    admin = get_admin_client()
    admin.table("user_settings").update({"fcm_token": body.fcm_token}).eq("user_id", user_id).execute()
    return {"status": "ok"}


class SendTestNotificationRequest(BaseModel):
    title: str
    body: str


@router.post("/send-test")
def send_test_notification(body: SendTestNotificationRequest, user_id: str = Depends(get_current_user_id)):
    """Lets the signed-in user send themselves a test push — used by the
    Notifications section in Settings ("Send test notification")."""
    admin = get_admin_client()
    settings_row = (
        admin.table("user_settings").select("fcm_token").eq("user_id", user_id).maybe_single().execute()
    )
    token = (settings_row.data or {}).get("fcm_token")
    if not token:
        return {"status": "no_token_registered"}

    send_push(token, body.title, body.body)
    admin.table("notification_logs").insert(
        {"user_id": user_id, "type": "test", "title": body.title, "body": body.body}
    ).execute()
    return {"status": "sent"}
