from pydantic import BaseModel, HttpUrl, Field
from typing import List, Optional
from datetime import datetime

# --- Input Models ---

class ContentSource(BaseModel):
    source_type: str = Field(..., description="Type of source: 'rss', 'youtube', 'web'")
    url: HttpUrl
    name: Optional[str] = None

class ProcessingRequest(BaseModel):
    sources: List[ContentSource]
    force_refresh: bool = False
    tts_engine: Optional[str] = None # 'edge-tts' or 'chatterbox'

# --- Script Models ---

class DialogueLine(BaseModel):
    speaker: str = Field(..., description="Host name (e.g., 'Host A', 'Host B')")
    text: str
    emotion: Optional[str] = Field(None, description="Tone/Emotion instruction for TTS")

class DialogueScript(BaseModel):
    title: str
    lines: List[DialogueLine]
    created_at: datetime = Field(default_factory=datetime.now)

# --- Output Models ---

class PodcastMetadata(BaseModel):
    title: str
    duration_seconds: float
    sources: List[str]
    created_at: datetime

class PodcastEpisode(BaseModel):
    file_path: str
    metadata: PodcastMetadata
    tts_engine_used: Optional[str] = None  # Actual engine used (may differ if fallback occurred)
