from functools import lru_cache
from supabase import create_client, Client
from .config import settings


@lru_cache
def get_admin_client() -> Client:
    """Service-role Supabase client — bypasses RLS. Only ever used
    server-side, and only for operations the Flutter app cannot safely
    perform itself (account deletion, cross-user batch jobs)."""
    return create_client(settings.supabase_url, settings.supabase_service_role_key)
