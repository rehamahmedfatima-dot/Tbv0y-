from fastapi import APIRouter, Depends
from ...core.security import get_current_user_id
from ...core.supabase_client import get_admin_client

router = APIRouter(prefix="/account", tags=["account"])


@router.delete("")
def delete_account(user_id: str = Depends(get_current_user_id)):
    """Permanently deletes the authenticated user's account and all
    their data. This must run server-side: it needs the service_role key
    (to delete the underlying auth.users row) which the Flutter app never
    holds. All `user_id`-referencing tables cascade-delete automatically
    via the foreign keys defined in schema.sql — deleting the auth user
    is enough to remove everything downstream."""
    admin = get_admin_client()
    admin.auth.admin.delete_user(user_id)
    return {"status": "deleted", "user_id": user_id}
