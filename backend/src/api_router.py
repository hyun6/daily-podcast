from fastapi import APIRouter, HTTPException, BackgroundTasks
from typing import List, Optional, Callable
from src.models import (
    ProcessingRequest, PodcastEpisode, PodcastMetadata, ScriptResponse, 
    AudioFromScriptRequest, AudioResponse, DialogueScript,
    AsyncTaskResponse, TaskStatusResponse
)
from src.podcastfy_client import PodcastfyClient
from src.audio.task_manager import task_manager
from src.config import settings
import os
from datetime import datetime
import asyncio

from src.storage_client import storage_client  # Import storage_client

router = APIRouter()

# Initialize Podcastfy client
podcastfy_client = PodcastfyClient()

@router.post("/generate", response_model=PodcastEpisode)
async def generate_episode(request: ProcessingRequest):
    """
    Generate a podcast episode from the provided sources.
    Uses Podcastfy for script generation and TTS.
    """
    print(f"[DEBUG] Received request: sources={len(request.sources)}, tts_engine={request.tts_engine}")
    for i, src in enumerate(request.sources):
        print(f"[DEBUG] Source {i}: type={src.source_type}, url={src.url}, name={src.name}")
    
    # Extract URLs from sources
    urls = [str(source.url) for source in request.sources]
    source_names = [source.name or str(source.url) for source in request.sources]
    
    if not urls:
        raise HTTPException(status_code=400, detail="No valid sources provided.")

    try:
        # Normalize TTS engine name for Podcastfy
        tts_engine = request.tts_engine
        if tts_engine == "edge-tts":
            tts_engine = "edge"
        elif not tts_engine:
            tts_engine = "edge"
            
        # Generate podcast using Podcastfy
        audio_path, script = await asyncio.to_thread(
            podcastfy_client.generate_from_urls,
            urls,
            tts_engine
        )
        
        # Sanitize path for URL usage (remove leading ./)
        # Sanitize path for URL usage (remove leading ./)
        if audio_path:
            if audio_path.startswith("./"):
                audio_path = audio_path[2:]
            # If it's a full URL (Supabase), keep it as is
            
        print(f"[INFO] Podcast generated: {audio_path}")
        
    except Exception as e:
        print(f"[ERROR] Podcast generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Podcast generation failed: {str(e)}")

    return PodcastEpisode(
        file_path=audio_path,
        metadata=PodcastMetadata(
            title=script.title,
            duration_seconds=0.0,  # TODO: Calculate duration
            sources=source_names,
            created_at=datetime.now()
        ),
        tts_engine_used=tts_engine
    )

@router.get("/episodes")
async def list_episodes():
    """List all generated podcast episodes."""
    files = []
    # Scan Podcastfy output directory
    audio_dir = "./data/audio"
    if os.path.exists(audio_dir):
        for f in os.listdir(audio_dir):
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
    
    urls = [str(source.url) for source in request.sources]
    source_names = [source.name or str(source.url) for source in request.sources]
    
    if not urls:
        raise HTTPException(status_code=400, detail="No valid sources provided.")

    try:
        script = await asyncio.to_thread(
            podcastfy_client.generate_script_only,
            urls=urls
        )
    except Exception as e:
        print(f"[ERROR] Script generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Script generation failed: {str(e)}")

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
        tts_engine = request.tts_engine or "edge"
        audio_path = await asyncio.to_thread(
            podcastfy_client.generate_audio_from_script,
            request.script,
            tts_engine
        )
        print(f"[INFO] Audio generated: {audio_path}")
    except Exception as e:
        print(f"[ERROR] Audio generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Audio generation failed: {str(e)}")

    return AudioResponse(
        file_path=audio_path,
        tts_engine_used=tts_engine
    )

@router.post("/generate-audio-async", response_model=AsyncTaskResponse, status_code=202)
async def generate_audio_async(request: AudioFromScriptRequest, background_tasks: BackgroundTasks):
    """
    Start audio generation asynchronously. Returns a task ID.
    """
    task_id = task_manager.create_task()
    
    background_tasks.add_task(
        run_tts_task,
        task_id,
        request.script,
        request.tts_engine
    )
    
    return AsyncTaskResponse(task_id=task_id)

@router.get("/tasks/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    task = task_manager.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task.to_status_model()

@router.post("/tasks/{task_id}/cancel")
async def cancel_task(task_id: str):
    if task_manager.cancel_task(task_id):
        return {"message": "Task cancellation requested"}
    raise HTTPException(status_code=404, detail="Task not found or cannot be cancelled")

async def run_tts_task(task_id: str, script: DialogueScript, engine_name: Optional[str]):
    task = task_manager.get_task(task_id)
    if not task:
        return

    try:
        task.set_status("running")
        
        # Use Podcastfy for audio generation
        tts_engine = engine_name or "edge"
        audio_path = await asyncio.to_thread(
            podcastfy_client.generate_audio_from_script,
            script,
            tts_engine
        )
        
        if task.status == "cancelled":
            print(f"[Task {task_id}] Task was cancelled, ignoring result.")
            return

        task.result = audio_path
        task.set_status("completed")
        task.progress = 1.0
        
    except Exception as e:
        task.set_status("failed")


@router.delete("/episodes/{filename}")
async def delete_episode(filename: str):
    """
    Delete a podcast episode.
    Removes the file from local storage and Supabase storage if applicable.
    """
    deleted = False
    error_msg = ""

    # 1. Try deleting from local storage
    local_path = os.path.join("./data/audio", filename)
    if os.path.exists(local_path):
        try:
            os.remove(local_path)
            deleted = True
            print(f"[INFO] Deleted local file: {local_path}")
        except Exception as e:
            print(f"[ERROR] Failed to delete local file: {e}")
            error_msg += f"Local delete failed: {str(e)}; "

    # 2. Try deleting from Supabase
    if storage_client.is_enabled():
        try:
            # Assuming filename is the remote name in Supabase
            if storage_client.delete_audio(filename):
                deleted = True
                print(f"[INFO] Deleted from Supabase: {filename}")
            else:
                 # It might not exist in Supabase, which is fine if we deleted it locally
                 pass
        except Exception as e:
            print(f"[ERROR] Failed to delete from Supabase: {e}")
            error_msg += f"Supabase delete failed: {str(e)}; "

    if deleted:
        return {"message": f"Episode {filename} deleted successfully", "details": error_msg}
    else:
        # If we couldn't delete it from anywhere (and it didn't exist locally), return 404
        if not os.path.exists(local_path) and not storage_client.is_enabled():
             raise HTTPException(status_code=404, detail="Episode not found")
        
        # If we tried but failed
        if error_msg:
             raise HTTPException(status_code=500, detail=f"Failed to delete episode: {error_msg}")
        
        # If file didn't exist locally and Supabase returns false (or disabled)
        raise HTTPException(status_code=404, detail="Episode not found")
