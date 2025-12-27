from fastapi import APIRouter, HTTPException, BackgroundTasks
from src.models import ProcessingRequest, PodcastEpisode, PodcastMetadata, ScriptResponse, AudioFromScriptRequest, AudioResponse, DialogueScript
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
# Use Mock client if API key is not set or default
if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY.startswith("your_api_key") or settings.GEMINI_API_KEY == "TODO":
    print("WARNING: Using Mock Gemini Client (Valid GEMINI_API_KEY not found)")
    llm_client = MockGeminiClient()
else:
    print("Using Real Gemini Client")
    try:
        llm_client = GeminiClient()
    except Exception as e:
        print(f"Error initializing Gemini Client, falling back to Mock: {e}")
        llm_client = MockGeminiClient()

tts_engine = TTSEngine()

@router.post("/generate", response_model=PodcastEpisode)
async def generate_episode(request: ProcessingRequest):
    """
    Generate a podcast episode from the provided sources.
    """
    print(f"[DEBUG] Received request: sources={len(request.sources)}, tts_engine={request.tts_engine}")
    for i, src in enumerate(request.sources):
        print(f"[DEBUG] Source {i}: type={src.source_type}, url={src.url}, name={src.name}")
    
    full_text = ""
    source_names = []
    
    # 1. Fetch Content
    for source in request.sources:
        content = None
        try:
            if source.source_type == 'rss':
                content = rss_fetcher.fetch(str(source.url))
            elif source.source_type == 'web':
                content = web_fetcher.fetch(str(source.url))
            elif source.source_type == 'youtube':
                content = youtube_fetcher.fetch(str(source.url))
            else:
                print(f"[WARN] Unknown source_type: {source.source_type}")
        except Exception as e:
            print(f"[ERROR] Failed to fetch {source.url}: {e}")
        
        if content:
            full_text += f"\n\nSource: {source.name or source.url}\n{content}"
            source_names.append(source.name or str(source.url))
    
    if not full_text:
        print("[ERROR] Failed to fetch any content from sources.")
        raise HTTPException(status_code=400, detail="Failed to fetch any content from sources. Check your URLs and source types.")

    # 2. Generate Script
    script = llm_client.generate_script(full_text)
    if not script.lines:
        raise HTTPException(status_code=500, detail="Script generation failed.")

    # 3. Generate Audio
    try:
        audio_path, engine_used = await tts_engine.generate_audio(script, tts_engine=request.tts_engine)
        print(f"[INFO] Audio generated using: {engine_used}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Audio generation failed: {str(e)}")

    # 4. Create Metadata
    # For now, return the path. In real app, save to DB/JSON log.
    
    return PodcastEpisode(
        file_path=audio_path,
        metadata=PodcastMetadata(
            title=script.title,
            duration_seconds=0.0, # TODO: Calculate duration
            sources=source_names,
            created_at=datetime.now()
        ),
        tts_engine_used=engine_used
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

@router.post("/generate-script", response_model=ScriptResponse)
async def generate_script_only(request: ProcessingRequest):
    """
    Generate a podcast script from the provided sources without generating audio.
    This allows users to preview and edit the script before TTS generation.
    """
    print(f"[DEBUG] Script-only generation: sources={len(request.sources)}")
    
    full_text = ""
    source_names = []
    
    # 1. Fetch Content
    for source in request.sources:
        content = None
        try:
            if source.source_type == 'rss':
                content = rss_fetcher.fetch(str(source.url))
            elif source.source_type == 'web':
                content = web_fetcher.fetch(str(source.url))
            elif source.source_type == 'youtube':
                content = youtube_fetcher.fetch(str(source.url))
            else:
                print(f"[WARN] Unknown source_type: {source.source_type}")
        except Exception as e:
            print(f"[ERROR] Failed to fetch {source.url}: {e}")
        
        if content:
            full_text += f"\n\nSource: {source.name or source.url}\n{content}"
            source_names.append(source.name or str(source.url))
    
    if not full_text:
        print("[ERROR] Failed to fetch any content from sources.")
        raise HTTPException(status_code=400, detail="Failed to fetch any content from sources. Check your URLs and source types.")

    # 2. Generate Script
    script = llm_client.generate_script(full_text)
    if not script.lines:
        raise HTTPException(status_code=500, detail="Script generation failed.")

    return ScriptResponse(
        script=script,
        sources=source_names
    )

@router.post("/generate-audio", response_model=AudioResponse)
async def generate_audio_from_script(request: AudioFromScriptRequest):
    """
    Generate audio from an existing script using TTS.
    This is the second step after script preview/editing.
    """
    print(f"[DEBUG] Audio generation from script: title={request.script.title}, lines={len(request.script.lines)}")
    
    if not request.script.lines:
        raise HTTPException(status_code=400, detail="Script has no dialogue lines.")

    try:
        audio_path, engine_used = await tts_engine.generate_audio(request.script, tts_engine=request.tts_engine)
        print(f"[INFO] Audio generated using: {engine_used}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Audio generation failed: {str(e)}")

    return AudioResponse(
        file_path=audio_path,
        tts_engine_used=engine_used
    )
