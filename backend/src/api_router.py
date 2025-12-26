from fastapi import APIRouter, HTTPException, BackgroundTasks
from src.models import ProcessingRequest, PodcastEpisode, PodcastMetadata
from src.fetcher.text_fetchers import RSSFetcher, WebFetcher
from src.fetcher.youtube_fetcher import YouTubeFetcher
from src.writer.llm_client import GeminiClient
from src.writer.mock_client import MockGeminiClient
from src.audio.tts_engine import TTSEngine
from src.config import settings
import os
from datetime import datetime

router = APIRouter()

# Initialize services
# In production, use Dependency Injection
rss_fetcher = RSSFetcher()
web_fetcher = WebFetcher()
youtube_fetcher = YouTubeFetcher()

# Use Mock client for dev unless API key is set
if settings.ENV == "development" and settings.GEMINI_API_KEY == "your_api_key_here":
    print("Using Mock Gemini Client")
    llm_client = MockGeminiClient()
else:
    llm_client = GeminiClient()

tts_engine = TTSEngine()

@router.post("/generate", response_model=PodcastEpisode)
async def generate_episode(request: ProcessingRequest):
    """
    Generate a podcast episode from the provided sources.
    """
    full_text = ""
    source_names = []
    
    # 1. Fetch Content
    for source in request.sources:
        content = None
        if source.source_type == 'rss':
            content = rss_fetcher.fetch(str(source.url))
        elif source.source_type == 'web':
            content = web_fetcher.fetch(str(source.url))
        elif source.source_type == 'youtube':
            content = youtube_fetcher.fetch(str(source.url))
        
        if content:
            full_text += f"\n\nSource: {source.name or source.url}\n{content}"
            source_names.append(source.name or str(source.url))
    
    if not full_text:
        raise HTTPException(status_code=400, detail="Failed to fetch any content from sources.")

    # 2. Generate Script
    script = llm_client.generate_script(full_text)
    if not script.lines:
        raise HTTPException(status_code=500, detail="Script generation failed.")

    # 3. Generate Audio
    try:
        audio_path = await tts_engine.generate_audio(script)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Audio generation failed: {str(e)}")

    # 4. Create Metadata
    # For now, return the path. In real app, save to DB/JSON log.
    
    return PodcastEpisode(
        file_path=audio_path,
        metadata=PodcastMetadata(
            title=script.title,
            duration_seconds=0.0, # TOOD: Calculate duration
            sources=source_names,
            created_at=datetime.now()
        )
    )

@router.get("/episodes")
async def list_episodes():
    # List files in downloads dir
    files = []
    if os.path.exists(settings.DOWNLOADS_DIR):
        for f in os.listdir(settings.DOWNLOADS_DIR):
            if f.endswith(".mp3"):
                files.append(f)
    return {"episodes": files}
