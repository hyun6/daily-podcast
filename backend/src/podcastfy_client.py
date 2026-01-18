"""
Podcastfy Client - Podcastfy 래퍼 및 어댑터

Podcastfy 라이브러리를 사용하여 팟캐스트를 생성하고,
출력 형식을 기존 DialogueScript 모델로 변환합니다.
"""
import os
import re
import glob
from typing import List, Optional, Tuple
from datetime import datetime

from podcastfy.client import generate_podcast
from src.models import DialogueScript, DialogueLine
from src.config import settings
from src.storage_client import storage_client
import uuid


class PodcastfyClient:
    """
    Podcastfy 라이브러리 래퍼 + 어댑터
    
    - Podcastfy를 호출하여 팟캐스트 생성
    - <Person1>, <Person2> 태그를 DialogueScript로 변환
    """
    
    def __init__(self):
        self.transcript_dir = "./data/transcripts"
        self.audio_dir = "./data/audio"
        
        # 한국어 EdgeTTS 설정
        self.conversation_config = {
            "output_language": "Korean",
            "podcast_name": "일일 팟캐스트",
            "podcast_tagline": "AI가 들려주는 오늘의 이야기",
            "conversation_style": ["engaging", "conversational", "informative"],
            "roles_person1": "main host who explains topics clearly",
            "roles_person2": "curious co-host who asks questions",
            "ending_message": "오늘의 팟캐스트를 들어주셔서 감사합니다!",
            "text_to_speech": {
                "default_tts_model": "edge",
                "edge": {
                    "default_voices": {
                        "question": "ko-KR-InJoonNeural",  # Male - Host A
                        "answer": "ko-KR-SunHiNeural"       # Female - Host B
                    }
                }
            }
        }
        
        # Speaker 매핑 (Person1/2 → Host A/B)
        self.speaker_map = {
            "Person1": "Host A",
            "Person2": "Host B"
        }
    
    def generate_from_urls(
        self, 
        urls: List[str],
        tts_engine: Optional[str] = "edge"
    ) -> Tuple[str, DialogueScript]:
        """
        URL 목록에서 팟캐스트 생성
        
        Args:
            urls: 콘텐츠 URL 목록
            tts_engine: TTS 엔진 (edge, openai, elevenlabs)
        
        Returns:
            tuple: (오디오 파일 경로, DialogueScript)
        """
        # Debug: Check environment variables
        jina_key = os.environ.get("JINA_API_KEY")
        print(f"[DEBUG] JINA_API_KEY configured: {bool(jina_key)}")
        if jina_key:
            print(f"[DEBUG] JINA_API_KEY prefix: {jina_key[:4]}...")

        audio_file = generate_podcast(
            urls=urls,
            conversation_config=self.conversation_config,
            tts_model=tts_engine,
            llm_model_name="gemini-2.0-flash-exp"
        )
        
        
        # 가장 최근 transcript 파일 찾기
        transcript_path = self._find_latest_transcript()
        script = self._parse_transcript(transcript_path)
        
        # Supabase Storage가 활성화되어 있으면 업로드
        if storage_client.is_enabled():
            try:
                # UUID로 파일명 생성 (충돌 방지 및 보안)
                remote_name = f"{uuid.uuid4()}.mp3"
                print(f"[INFO] Uploading audio to Supabase: {remote_name}")
                audio_url = storage_client.upload_audio(audio_file, remote_name)
                
                # 로컬 파일 정리
                if os.path.exists(audio_file):
                    os.remove(audio_file)
                
                audio_file = audio_url
                print(f"[INFO] Upload successful: {audio_file}")
            except Exception as e:
                print(f"[ERROR] Upload failed, keeping local file: {e}")

        return audio_file, script
    
    def generate_from_text(
        self, 
        text: str,
        tts_engine: Optional[str] = "edge"
    ) -> Tuple[str, DialogueScript]:
        """
        텍스트에서 팟캐스트 생성
        
        Args:
            text: 원본 텍스트 콘텐츠
            tts_engine: TTS 엔진
        
        Returns:
            tuple: (오디오 파일 경로, DialogueScript)
        """
        audio_file = generate_podcast(
            text=text,
            conversation_config=self.conversation_config,
            tts_model=tts_engine,
            llm_model_name="gemini-2.0-flash-exp"
        )
        
        transcript_path = self._find_latest_transcript()
        script = self._parse_transcript(transcript_path)
        
        # Supabase Storage가 활성화되어 있으면 업로드
        if storage_client.is_enabled():
            try:
                remote_name = f"{uuid.uuid4()}.mp3"
                audio_url = storage_client.upload_audio(audio_file, remote_name)
                
                if os.path.exists(audio_file):
                    os.remove(audio_file)
                
                audio_file = audio_url
            except Exception as e:
                print(f"[ERROR] Upload failed: {e}")

        return audio_file, script
    
    def generate_script_only(
        self, 
        urls: List[str] = None,
        text: str = None
    ) -> DialogueScript:
        """
        스크립트만 생성 (오디오 없이)
        
        Args:
            urls: URL 목록 (옵션)
            text: 텍스트 콘텐츠 (옵션)
        
        Returns:
            DialogueScript: 변환된 대본
        """
        generate_podcast(
            urls=urls,
            text=text,
            conversation_config=self.conversation_config,
            transcript_only=True,
            llm_model_name="gemini-2.0-flash-exp"
        )
        
        transcript_path = self._find_latest_transcript()
        return self._parse_transcript(transcript_path)
    
    def generate_audio_from_script(
        self,
        script: DialogueScript,
        tts_engine: Optional[str] = "edge"
    ) -> str:
        """
        기존 DialogueScript에서 오디오 생성
        
        Args:
            script: 기존 DialogueScript 형식
            tts_engine: TTS 엔진
        
        Returns:
            str: 오디오 파일 경로
        """
        # DialogueScript → Podcastfy transcript 형식 변환
        transcript_text = self._script_to_transcript(script)
        
        # Podcastfy는 transcript 파일에서 직접 오디오 생성 지원
        audio_file = generate_podcast(
            transcript_file=self._save_temp_transcript(transcript_text),
            conversation_config=self.conversation_config,
            tts_model=tts_engine
        )
        
        # Supabase Storage가 활성화되어 있으면 업로드
        if storage_client.is_enabled():
            try:
                remote_name = f"{uuid.uuid4()}.mp3"
                audio_url = storage_client.upload_audio(audio_file, remote_name)
                
                if os.path.exists(audio_file):
                    os.remove(audio_file)
                
                audio_file = audio_url
            except Exception as e:
                print(f"[ERROR] Upload failed: {e}")

        return audio_file
    
    def _find_latest_transcript(self) -> str:
        """가장 최근 생성된 transcript 파일 경로 반환"""
        pattern = os.path.join(self.transcript_dir, "transcript_*.txt")
        files = glob.glob(pattern)
        if not files:
            raise FileNotFoundError(f"No transcript files found in {self.transcript_dir}")
        return max(files, key=os.path.getctime)
    
    def _parse_transcript(self, path: str) -> DialogueScript:
        """
        Podcastfy transcript 파일을 DialogueScript로 파싱
        
        <Person1>...<Person2>... 형식을 DialogueLine[] 으로 변환
        """
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = []
        
        # 정규식: <Person1> 또는 <Person2> 태그와 내용 추출
        pattern = r'<(Person\d)>(.*?)(?=<Person\d>|</Person\d>|$)'
        matches = re.findall(pattern, content, re.DOTALL)
        
        for speaker_tag, text in matches:
            text = text.strip()
            # 닫는 태그 제거
            text = re.sub(r'</Person\d>', '', text).strip()
            # <lang> 태그 제거
            text = re.sub(r'<lang xml:lang="[^"]*">', '', text).strip()
            
            if text:
                speaker = self.speaker_map.get(speaker_tag, speaker_tag)
                lines.append(DialogueLine(
                    speaker=speaker,
                    text=text,
                    emotion=None
                ))
        
        # 제목 추출 (첫 번째 라인에서)
        title = "Untitled Podcast"
        if lines:
            # 첫 번째 대사에서 "환영합니다" 등의 키워드로 제목 추출 시도
            first_text = lines[0].text
            if "일일 팟캐스트" in first_text or "팟캐스트" in first_text:
                title = "일일 팟캐스트"
        
        return DialogueScript(
            title=title,
            lines=lines,
            created_at=datetime.now()
        )
    
    def _script_to_transcript(self, script: DialogueScript) -> str:
        """DialogueScript를 Podcastfy transcript 형식으로 변환"""
        result = []
        
        # Host A/B → Person1/2 역매핑
        reverse_map = {v: k for k, v in self.speaker_map.items()}
        
        for line in script.lines:
            tag = reverse_map.get(line.speaker, "Person1")
            result.append(f"<{tag}>{line.text}</{tag}>")
        
        return "".join(result)
    
    def _save_temp_transcript(self, content: str) -> str:
        """임시 transcript 파일 저장 및 경로 반환"""
        temp_path = os.path.join(self.transcript_dir, "temp_transcript.txt")
        with open(temp_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return temp_path
