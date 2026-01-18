from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Literal

class Settings(BaseSettings):
    # App Config
    APP_NAME: str = "Daily Podcast Generator"
    APP_VERSION: str = "0.1.0"
    ENV: Literal["development", "production"] = "development"

    # API Keys & External Services
    GEMINI_API_KEY: str = Field("TODO", description="Google Gemini API Key")
    JINA_API_KEY: str = Field(None, description="Jina AI API Key (required for Podcastfy web scraping)")
    
    # Supabase (Optional - for cloud storage)
    SUPABASE_URL: str = Field("", description="Supabase Project URL")
    SUPABASE_KEY: str = Field("", description="Supabase anon/public key")
    
    # Paths
    DATA_DIR: str = "data"
    DOWNLOADS_DIR: str = "downloads"

    # Audio Configuration
    TTS_ENGINE: Literal["edge-tts", "openai", "elevenlabs"] = Field(
        default="edge-tts", 
        description="Text-to-Speech Engine to use"
    )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
