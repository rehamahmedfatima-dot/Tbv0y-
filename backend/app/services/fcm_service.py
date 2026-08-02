import firebase_admin
from firebase_admin import credentials, messaging
from ..core.config import settings

_initialized = False


def _ensure_initialized() -> None:
    global _initialized
    if not _initialized:
        cred = credentials.Certificate(settings.firebase_service_account_path)
        firebase_admin.initialize_app(cred)
        _initialized = True


def send_push(fcm_token: str, title: str, body: str, data: dict | None = None) -> str:
    """Sends a single push notification. Returns the FCM message id.
    Callers are responsible for looking up the user's fcm_token and for
    logging the send to notification_logs."""
    _ensure_initialized()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        token=fcm_token,
    )
    return messaging.send(message)


def send_push_batch(tokens: list[str], title: str, body: str) -> messaging.BatchResponse:
    _ensure_initialized()
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        tokens=tokens,
    )
    return messaging.send_multicast(message)
