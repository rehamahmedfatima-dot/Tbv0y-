from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    supabase_url: str
    supabase_service_role_key: str
    supabase_jwt_secret: str

    gemini_api_key: str

    firebase_service_account_path: str = "./firebase-service-account.json"

    jobs_secret: str

    class Config:
        env_file = ".env"


settings = Settings()
