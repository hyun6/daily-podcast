"""
Supabase Storage Client
오디오 파일을 Supabase Storage에 업로드하고 Public URL 반환
"""
import os
from typing import Optional
from supabase import create_client, Client
from src.config import settings


class StorageClient:
    """Supabase Storage 래퍼"""
    
    BUCKET_NAME = "podcast-audio"
    
    def __init__(self):
        self.client: Optional[Client] = None
        if settings.SUPABASE_URL and settings.SUPABASE_KEY:
            try:
                self.client = create_client(
                    settings.SUPABASE_URL, 
                    settings.SUPABASE_KEY
                )
            except Exception as e:
                print(f"[WARNING] Failed to initialize Supabase client: {e}")
    
    def is_enabled(self) -> bool:
        """Supabase 연동 활성화 여부"""
        return self.client is not None
    
    def upload_audio(self, local_path: str, remote_name: str) -> str:
        """
        오디오 파일을 Supabase Storage에 업로드
        
        Args:
            local_path: 로컬 파일 경로
            remote_name: 저장할 파일명 (UUID.mp3 권장)
        
        Returns:
            str: Public URL
        """
        if not self.client:
            raise RuntimeError("Supabase not configured")
        
        if not os.path.exists(local_path):
             raise FileNotFoundError(f"Audio file not found: {local_path}")

        try:
            with open(local_path, "rb") as f:
                self.client.storage.from_(self.BUCKET_NAME).upload(
                    path=remote_name,
                    file=f,
                    file_options={"content-type": "audio/mpeg"}
                )
            
            return self.client.storage.from_(self.BUCKET_NAME).get_public_url(remote_name)
        except Exception as e:
            print(f"[ERROR] Failed to upload audio to Supabase: {e}")
            raise e
    
    def delete_audio(self, remote_name: str) -> bool:
        """오디오 파일 삭제"""
        if not self.client:
            return False
        
        try:
            self.client.storage.from_(self.BUCKET_NAME).remove([remote_name])
            return True
        except Exception as e:
            print(f"[ERROR] Failed to delete audio from Supabase: {e}")
            return False


# Singleton instance
storage_client = StorageClient()
