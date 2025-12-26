from fastapi import FastAPI
from src.config import settings
from src.api_router import router as api_router

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Backend API for Daily AI Podcast Generator"
)
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development, allow all. In production, be specific.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
from fastapi.staticfiles import StaticFiles
import os

app.include_router(api_router, prefix="/api/v1")

# Ensure downloads directory exists
os.makedirs(settings.DOWNLOADS_DIR, exist_ok=True)
app.mount("/downloads", StaticFiles(directory=settings.DOWNLOADS_DIR), name="downloads")

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
