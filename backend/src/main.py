from fastapi import FastAPI
from src.config import settings
from src.api_router import router as api_router

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Backend API for Daily AI Podcast Generator"
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def read_root():
    return {
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "tts_engine": settings.TTS_ENGINE
    }

@app.get("/health")
def health_check():
    return {"status": "ok", "env": settings.ENV}
