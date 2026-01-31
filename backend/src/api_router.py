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
import uuid
from datetime import datetime
import asyncio
from pydub import AudioSegment

from src.storage_client import storage_client
from src.audio.qwen_handler import QwenTTSHandler

router = APIRouter()

# Initialize Podcastfy client
podcastfy_client = PodcastfyClient()

def get_reference_audio(speaker_name: str) -> str:
    """Get the reference audio path for a given speaker."""
    base_dir = os.path.join(os.path.dirname(__file__), "../data/voices")
    # Default mapping based on generated references
    if "Host B" in speaker_name or "Person2" in speaker_name:
        return os.path.abspath(os.path.join(base_dir, "host_b.wav"))
    return os.path.abspath(os.path.join(base_dir, "host_a.wav"))


def split_text_into_chunks(text: str, max_length: int = 150) -> List[str]:
    """Split text into smaller chunks by semantic boundaries."""
    if not text:
        return []
    
    # If text is short enough, return as is
    if len(text) <= max_length:
        return [text]
        
    chunks = []
    current_chunk = ""
    
    # Split by sentence endings first
    # Simple split by common punctuation
    sentences = text.replace("?", "?|").replace("!", "!|").replace(".", ".|").split("|")
    
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
            
        # If adding this sentence exceeds max length, push current chunk
        if len(current_chunk) + len(sentence) > max_length:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = sentence
        else:
            if current_chunk:
                current_chunk += " " + sentence
            else:
                current_chunk = sentence
    
    if current_chunk:
        chunks.append(current_chunk)
        
    return chunks

async def generate_with_qwen(script: DialogueScript) -> str:
    """Generate audio using QwenTTSHandler."""
    handler = QwenTTSHandler()
    combined_audio = AudioSegment.empty()
    
    print(f"[QwenTTS] Starting generation for {len(script.lines)} lines")
    
    temp_files = []
    
    try:
        for i, line in enumerate(script.lines):
            ref_audio = get_reference_audio(line.speaker)
            # Use strict text to avoid empty generation issues
            text = line.text.strip()
            if not text:
                continue
            
            # Split long text into semantic chunks for better pacing
            chunks = split_text_into_chunks(text)
            
            print(f"[QwenTTS] Processing line {i+1} ({len(chunks)} chunks): {text[:30]}...")
            
            line_audio = AudioSegment.empty()
            
            for j, chunk in enumerate(chunks):
                if not chunk.strip():
                    continue
                    
                wav_path = await handler.generate(chunk, ref_audio)
                
                if wav_path and os.path.exists(wav_path):
                    segment = AudioSegment.from_wav(wav_path)
                    line_audio += segment
                    # Short pause between sentences within a line
                    if j < len(chunks) - 1:
                        line_audio += AudioSegment.silent(duration=150)
                    temp_files.append(wav_path)
                else:
                    print(f"[QwenTTS] Warning: No audio generated for chunk {j+1} of line {i+1}")
            
            if len(line_audio) > 0:
                combined_audio += line_audio
                # Add pause between dialogue lines
                combined_audio += AudioSegment.silent(duration=400) 
            
    except Exception as e:
        print(f"[QwenTTS] Error during generation loop: {e}")
        # Clean up temp files
        for f in temp_files:
            if os.path.exists(f):
                os.remove(f)
        raise e

    # Clean up temp files
    for f in temp_files:
        if os.path.exists(f):
            os.remove(f)
            
    # Save combined output
    filename = f"{uuid.uuid4()}.mp3"
    output_dir = "./data/audio"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, filename)
    
    print(f"[QwenTTS] Exporting combined audio to {output_path}")
    combined_audio.export(output_path, format="mp3")
    
    # Upload to Supabase if enabled
    if storage_client.is_enabled():
        try:
            print(f"[INFO] Uploading audio to Supabase: {filename}")
            audio_url = storage_client.upload_audio(output_path, filename)
            
            # Clean up local file
            if os.path.exists(output_path):
                os.remove(output_path)
            
            return audio_url
        except Exception as e:
            print(f"[ERROR] Upload failed, keeping local file: {e}")
            
    return output_path

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
        # Normalize TTS engine name
        tts_engine = request.tts_engine or "edge"
        
        # 1. Generate Script first (we need script to pass to Qwen if selected)
        # Using podcastfy just for script generation is safer if we want to intercept TTS
        
        if tts_engine == "qwen":
            # Generate script only
            script = await asyncio.to_thread(
                podcastfy_client.generate_script_only,
                urls=urls
            )
            # Generate Audio with Qwen
            audio_path = await generate_with_qwen(script)
        else:
            # Use original flow (Edge TTS via Podcastfy)
            if tts_engine == "edge-tts": 
                tts_engine = "edge"
                
            audio_path, script = await asyncio.to_thread(
                podcastfy_client.generate_from_urls,
                urls,
                tts_engine
            )
        
        # Sanitize path
        if audio_path:
            if audio_path.startswith("./"):
                audio_path = audio_path[2:]
            
        print(f"[INFO] Podcast generated: {audio_path}")
        
    except Exception as e:
        print(f"[ERROR] Podcast generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Podcast generation failed: {str(e)}")

    return PodcastEpisode(
        file_path=audio_path,
        metadata=PodcastMetadata(
            title=script.title,
            duration_seconds=0.0,
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
    """
    print(f"[DEBUG] Audio generation from script: title={request.script.title}, lines={len(request.script.lines)}")
    
    if not request.script.lines:
        raise HTTPException(status_code=400, detail="Script has no dialogue lines.")

    try:
        tts_engine = request.tts_engine or "edge"
        
        if tts_engine == "qwen":
            audio_path = await generate_with_qwen(request.script)
        else:
            if tts_engine == "edge-tts":
                tts_engine = "edge"
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
        
        tts_engine = engine_name or "edge"
        
        if tts_engine == "qwen":
            audio_path = await generate_with_qwen(script)
        else:
            if tts_engine == "edge-tts":
                tts_engine = "edge"
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
        print(f"[Task {task_id}] Failed: {e}")
        task.error = str(e)
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
