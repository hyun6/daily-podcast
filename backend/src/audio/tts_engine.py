import edge_tts
import asyncio
from pydub import AudioSegment
import os
from typing import List
from src.models import DialogueScript
from src.config import settings

class TTSEngine:
    def __init__(self):
        self.download_dir = settings.DOWNLOADS_DIR
        os.makedirs(self.download_dir, exist_ok=True)
        # Temporary dir for segments
        self.temp_dir = os.path.join(self.download_dir, "temp")
        os.makedirs(self.temp_dir, exist_ok=True)

        self.voices = {
            "Host A": "ko-KR-InJoonNeural",
            "Host B": "ko-KR-SunHiNeural"
        }

    async def generate_audio(self, script: DialogueScript) -> str:
        """
        Generates audio for the script and returns the path to the final mp3 file.
        """
        if settings.TTS_ENGINE != "edge-tts":
            raise NotImplementedError(f"TTS Engine '{settings.TTS_ENGINE}' is not yet implemented.")

        combined_audio = AudioSegment.empty()
        
        for i, line in enumerate(script.lines):
            speaker = line.speaker
            text = line.text
            voice = self.voices.get(speaker, "ko-KR-InJoonNeural") # Default voice
            
            # Generate individual segment
            segment_path = os.path.join(self.temp_dir, f"segment_{i}.mp3")
            communicate = edge_tts.Communicate(text, voice)
            await communicate.save(segment_path)
            
            # Load and append
            segment_audio = AudioSegment.from_mp3(segment_path)
            combined_audio += segment_audio
            
            # Add small pause between lines
            combined_audio += AudioSegment.silent(duration=300) 

        # Save final output
        filename = f"{script.title.replace(' ', '_')}_{script.created_at.strftime('%Y%m%d%H%M')}.mp3"
        output_path = os.path.join(self.download_dir, filename)
        combined_audio.export(output_path, format="mp3")
        
        # Cleanup temp
        for f in os.listdir(self.temp_dir):
            os.remove(os.path.join(self.temp_dir, f))
        
        return output_path
