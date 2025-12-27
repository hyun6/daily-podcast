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
            import torch
            import torchaudio as ta
            from chatterbox.tts import ChatterboxTTS
            
            # Determine device - prefer MPS (Apple Silicon) > CUDA > CPU
            if torch.backends.mps.is_available():
                device = "mps"
            elif torch.cuda.is_available():
                device = "cuda"
            else:
                device = "cpu"
            
            print(f"[Chatterbox] Loading model on device: {device}")
            model = ChatterboxTTS.from_pretrained(device=device)
            print("[Chatterbox] Model loaded successfully!")
            
        except ImportError as ie:
            print(f"[Chatterbox] Import Error: {ie}")
            print("[Chatterbox] Falling back to EdgeTTS.")
            path = await self._generate_edge_tts(script)
            return (path, "edge-tts (chatterbox fallback)")
        except Exception as e:
            print(f"[Chatterbox] Initialization Error: {e}")
            print("[Chatterbox] Falling back to EdgeTTS.")
            path = await self._generate_edge_tts(script)
            return (path, "edge-tts (chatterbox fallback)")

        # Generate audio using Chatterbox
        try:
            combined_audio = AudioSegment.empty()
            
            for i, line in enumerate(script.lines):
                text = line.text
                segment_path = os.path.join(self.temp_dir, f"segment_cb_{i}.wav")
                
                print(f"[Chatterbox] Generating segment {i+1}/{len(script.lines)}...")
                
                # Run synthesis in thread to avoid blocking async
                wav = await asyncio.to_thread(model.generate, text)
                
                # Save using torchaudio
                await asyncio.to_thread(ta.save, segment_path, wav, model.sr)
                
                if os.path.exists(segment_path):
                    segment_audio = AudioSegment.from_wav(segment_path)
                    combined_audio += segment_audio
                    combined_audio += AudioSegment.silent(duration=300)
            
            # Export final audio
            filename = f"cb_{script.title.replace(' ', '_')}_{script.created_at.strftime('%Y%m%d%H%M')}.mp3"
            output_path = os.path.join(self.download_dir, filename)
            combined_audio.export(output_path, format="mp3")
            
            # Cleanup temp
            for f in os.listdir(self.temp_dir):
                if f.startswith("segment_cb_"):
                    os.remove(os.path.join(self.temp_dir, f))
            
            print(f"[Chatterbox] Audio saved to: {output_path}")
            return (output_path, "chatterbox")
            
        except Exception as e:
            print(f"[Chatterbox] Generation Error: {e}")
            print("[Chatterbox] Falling back to EdgeTTS.")
            path = await self._generate_edge_tts(script)
            return (path, "edge-tts (chatterbox fallback)")

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

