import json
import google.generativeai as genai
from ..core.config import settings

genai.configure(api_key=settings.gemini_api_key)
_model = genai.GenerativeModel("gemini-2.0-flash")


def generate_text(prompt: str) -> str:
    response = _model.generate_content(prompt)
    return (response.text or "").strip()


def generate_json(prompt: str) -> dict | list:
    response = _model.generate_content(
        prompt,
        generation_config={"response_mime_type": "application/json"},
    )
    raw = (response.text or "{}").strip()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}
