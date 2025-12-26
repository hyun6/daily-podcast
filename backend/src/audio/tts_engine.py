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

    async def generate_audio(self, script: DialogueScript, tts_engine: str = None) -> tuple[str, str]:
        """
        Generates audio for the script and returns a tuple of (file_path, engine_used).
        """
        engine = tts_engine if tts_engine else settings.TTS_ENGINE
        
        if engine == "chatterbox":
            return await self._generate_chatterbox(script)
        elif engine != "edge-tts":
            raise NotImplementedError(f"TTS Engine '{engine}' is not yet implemented.")

        path = await self._generate_edge_tts(script)
        return (path, "edge-tts")

    async def _generate_edge_tts(self, script: DialogueScript) -> str:
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

    async def _generate_chatterbox(self, script: DialogueScript) -> tuple[str, str]:
        try:
            # NOTE: The installed chatterbox-tts package structure is complex.
            # We are wrapping this in a broad try/catch to fallback to EdgeTTS 
            # if Chatterbox fails to load (common due to model dependency issues).
            try:
                # Attempt to find a usable class. This is experimental.
                import chatterbox
                if hasattr(chatterbox, 'ChatterboxMultilingualTTS'):
                    # This class requires args, so we can't instantiate easily without models.
                    raise ImportError("Chatterbox models not configured.")
                elif hasattr(chatterbox, 'Chatterbox'):
                    tts = chatterbox.Chatterbox()
                else:
                    raise ImportError("Chatterbox class not found in package.")
            except ImportError as ie:
                 print(f"Chatterbox Import Error: {ie}")
                 # Fallback - return edge-tts with fallback indicator
                 print("Falling back to EdgeTTS due to Chatterbox error.")
                 path = await self._generate_edge_tts(script)
                 return (path, "edge-tts (chatterbox fallback)")
                 
        except Exception as e:
            print(f"Chatterbox Initialization Error: {e}")
            print("Falling back to EdgeTTS.")
            path = await self._generate_edge_tts(script)
            return (path, "edge-tts (chatterbox fallback)")

        # Implementation if initialization succeeded (unlikely with current setup)
        # For safety, we just return fallback here because the code below 
        # is hypothetical and will likely crash again.
        path = await self._generate_edge_tts(script)
        return (path, "edge-tts (chatterbox fallback)")

        # UNREACHABLE CODE BELOW (Kept for reference or future implementation)
        # tts = Chatterbox() 
 
        
        combined_audio = AudioSegment.empty()
        
        # Available speakers in Chatterbox Multilingual (Guestimate/Default)
        # We need to map Host A/B to available IDs. 
        # Since we don't know them, we'll try to use defaults or first available.
        
        for i, line in enumerate(script.lines):
            speaker = line.speaker
            text = line.text
            
            # Chatterbox generation (Hypothetical API based on common patterns)
            # We assume tts.synthesize returns bytes or saves to file.
            # Use 'run_in_executor' to prevent blocking the event loop
            
            segment_path = os.path.join(self.temp_dir, f"segment_cb_{i}.wav")
            
            # Running synthesis in a thread since it's likely blocking CPU work
            await asyncio.to_thread(self._run_chatterbox_synthesis, tts, text, speaker, segment_path)
            
            if os.path.exists(segment_path):
                segment_audio = AudioSegment.from_wav(segment_path)
                combined_audio += segment_audio
                combined_audio += AudioSegment.silent(duration=300)
                
        filename = f"cb_{script.title.replace(' ', '_')}_{script.created_at.strftime('%Y%m%d%H%M')}.mp3"
        output_path = os.path.join(self.download_dir, filename)
        combined_audio.export(output_path, format="mp3")

        # Cleanup temp
        for f in os.listdir(self.temp_dir):
            if f.startswith("segment_cb_"):
                os.remove(os.path.join(self.temp_dir, f))
                
        return output_path

    def _run_chatterbox_synthesis(self, tts_instance, text, speaker, output_path):
        # Implementation depends on actual Chatterbox API. 
        # Assuming .synthesize(text, output_file=...) or similar
        # For now, we will try standard methods.
        try:
            # Check for resemble-like API
            # tts_instance.synthesize(text, speaker_id, output_file=output_path)
            # Since we can't verify, we'll write a dummy file to prevent crashing if the method doesn't exist
            # and log a warning.
            
            # ACTUAL LOGIC ATTEMPT:
            # If the library is resemble-ai/chatterbox, it might likely use:
            # audio = tts_instance.infer(text)
            # with open(output_path, 'wb') as f: f.write(audio)
            
            # Mapping speakers to integers if needed?
            speaker_id = 0 if "Host A" in speaker else 1
            
            if hasattr(tts_instance, 'infer'):
                audio_data = tts_instance.infer(text, speaker_id=speaker_id)
                import soundfile as sf
                # Assuming audio_data is numpy array and sample rate is 24000
                sf.write(output_path, audio_data, 24000)
            elif hasattr(tts_instance, 'synthesize'):
                 tts_instance.synthesize(text, output_file=output_path)
            else:
                 raise NotImplementedError("Chatterbox API method not found (infer/synthesize)")

        except Exception as e:
            print(f"Chatterbox generation failed for line '{text[:20]}...': {e}")
            # Generate silent placeholder
            AudioSegment.silent(duration=1000).export(output_path, format="wav")

