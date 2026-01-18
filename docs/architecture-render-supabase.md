# Render + Supabase Storage 배포 아키텍처

> 작성일: 2026-01-18  
> 상태: 계획 수립 완료

Backend를 Docker로 컨테이너화하여 Render에 배포하고, 생성된 오디오 파일은 Supabase Storage에 업로드하여 영구 보관 및 다운로드를 지원합니다.

---

## 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [보안 고려사항](#보안-고려사항)
3. [변경사항 상세](#변경사항-상세)
4. [환경 변수](#환경-변수)
5. [배포 가이드](#배포-가이드)
6. [무료 티어 제한](#무료-티어-제한)

---

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ 스크립트 생성 │ →  │  오디오 생성  │ →  │ 다운로드/재생 │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└────────────┬──────────────────┬───────────────────┬─────────────┘
             │ 1. API 요청       │ 2. API 요청        │ 4. 다운로드
             ▼                   ▼                   ▼
┌─────────────────────────────────────────┐   ┌──────────────────┐
│            Render (Backend)              │   │ Supabase Storage │
│  ┌─────────────────────────────────┐    │   │                  │
│  │     FastAPI + Podcastfy         │    │   │  podcast-audio/  │
│  │                                 │    │   │   ├── uuid1.mp3  │
│  │  • 스크립트 생성 (Gemini API)    │────────▶│   ├── uuid2.mp3  │
│  │  • 오디오 생성 (Edge TTS)        │ 3.업로드│   └── ...        │
│  │  • Supabase 업로드              │    │   │                  │
│  └─────────────────────────────────┘    │   │  (Public Bucket) │
└─────────────────────────────────────────┘   └──────────────────┘
```

### 데이터 흐름

1. **스크립트 생성**: Flutter → Render → Gemini API → 스크립트 반환
2. **오디오 생성**: Flutter → Render → Edge TTS → 오디오 생성
3. **오디오 저장**: Render → Supabase Storage (업로드)
4. **오디오 접근**: Flutter → Supabase Storage (Public URL로 직접 다운로드)

---

## 보안 고려사항

### 🔐 API 키 보호

| 항목 | 위치 | 보호 방법 |
|------|------|----------|
| `GEMINI_API_KEY` | Render 환경변수 | 코드에 하드코딩 금지, .env에만 저장 |
| `SUPABASE_URL` | Render 환경변수 | 서버에서만 사용 |
| `SUPABASE_KEY` | Render 환경변수 | anon key 사용 (service_role 금지) |

### 📁 .gitignore 필수 항목

```gitignore
# 이미 backend/.gitignore에 포함됨
.env
.env.*
.env.local
.env.production
```

### 🔒 추가 보안 조치

1. **환경 변수 템플릿 (.env.example)**
   - 실제 값 없이 필요한 변수 목록만 제공
   - 새 개발자가 어떤 변수가 필요한지 파악 가능

2. **Supabase Storage 보안**
   - Public bucket 사용 (다운로드 편의)
   - **파일명에 UUID 사용** → URL 추측 불가능
   - RLS (Row Level Security) 필요 없음 (Public이므로)

3. **CORS 설정**
   - 개발: `allow_origins=["*"]`
   - 프로덕션: 특정 도메인만 허용 권장

4. **API 키 범위 제한**
   - Gemini API: 필요한 모델만 활성화
   - Supabase: `anon` key 사용 (읽기/쓰기 제한)

### ⚠️ 절대 하지 말 것

- ❌ API 키를 코드에 직접 작성
- ❌ `.env` 파일을 Git에 커밋
- ❌ Supabase `service_role` 키를 클라이언트에 노출
- ❌ Flutter 앱에 API 키 하드코딩

---

## 변경사항 상세

### Backend - 새 파일

#### 1. `Dockerfile`

```dockerfile
FROM python:3.11-slim

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y \
    ffmpeg \
    mecab \
    libmecab-dev \
    mecab-ko-dic \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python 의존성
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 복사
COPY . .

# 데이터 디렉토리 생성 (임시 파일용)
RUN mkdir -p data/audio data/transcripts downloads

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### 2. `.dockerignore`

```dockerignore
.venv/
__pycache__/
*.pyc
.env
.env.*
.git/
data/
downloads/
.pytest_cache/
tests/
*.md
```

#### 3. `render.yaml`

```yaml
services:
  - type: web
    name: daily-podcast-backend
    runtime: docker
    dockerfilePath: ./Dockerfile
    dockerContext: .
    envVars:
      - key: GEMINI_API_KEY
        sync: false  # Dashboard에서 직접 설정
      - key: SUPABASE_URL
        sync: false
      - key: SUPABASE_KEY
        sync: false
      - key: ENV
        value: production
    healthCheckPath: /health
    autoDeploy: true
```

#### 4. `.env.example`

```bash
# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key_here

# Supabase (Optional - for cloud storage)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key_here

# Environment
ENV=development
TTS_ENGINE=edge-tts
```

#### 5. `src/storage_client.py`

```python
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
            self.client = create_client(
                settings.SUPABASE_URL, 
                settings.SUPABASE_KEY
            )
    
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
        
        with open(local_path, "rb") as f:
            self.client.storage.from_(self.BUCKET_NAME).upload(
                path=remote_name,
                file=f,
                file_options={"content-type": "audio/mpeg"}
            )
        
        return self.client.storage.from_(self.BUCKET_NAME).get_public_url(remote_name)
    
    def delete_audio(self, remote_name: str) -> bool:
        """오디오 파일 삭제"""
        if not self.client:
            return False
        
        self.client.storage.from_(self.BUCKET_NAME).remove([remote_name])
        return True


# Singleton instance
storage_client = StorageClient()
```

### Backend - 수정 파일

#### `src/config.py` (수정)

```diff
  # API Keys & External Services
  GEMINI_API_KEY: str = Field("TODO", description="Google Gemini API Key")
+    
+ # Supabase (Optional - for cloud storage)
+ SUPABASE_URL: str = Field("", description="Supabase Project URL")
+ SUPABASE_KEY: str = Field("", description="Supabase anon/public key")
```

#### `src/podcastfy_client.py` (수정)

오디오 생성 후 Supabase에 업로드:

```python
# 추가 import
from src.storage_client import storage_client
import uuid

# generate_from_urls, generate_audio_from_script 메서드에서:
audio_file = generate_podcast(...)

# Supabase Storage가 활성화되어 있으면 업로드
if storage_client.is_enabled():
    remote_name = f"{uuid.uuid4()}.mp3"
    audio_url = storage_client.upload_audio(audio_file, remote_name)
    # 로컬 파일 삭제 (Render는 ephemeral이므로)
    os.remove(audio_file)
    audio_file = audio_url

return audio_file, script
```

#### `pyproject.toml` (수정)

```diff
  dependencies = [
      ...
+     "supabase>=2.0.0",
  ]
```

### Flutter App - 수정

#### `real_podcast_repository.dart`

```dart
// 헬퍼 메서드 추가
String _buildAudioUrl(String path) {
  // 이미 절대 URL인 경우 (Supabase Storage)
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  // 상대 경로인 경우 (로컬 개발)
  return "${baseUrl.replaceAll("/api/v1", "")}/$path";
}

// 사용 예시
return Podcast(
  filePath: _buildAudioUrl(data['file_path']),
  // ...
);
```

---

## 환경 변수

### 개발 환경 (로컬)

`backend/.env`:
```bash
GEMINI_API_KEY=your_key
TTS_ENGINE=edge-tts
# Supabase는 선택적 (없으면 로컬 파일 사용)
```

### 프로덕션 환경 (Render)

Render Dashboard → Environment Variables:

| Key | Value | 비고 |
|-----|-------|------|
| `GEMINI_API_KEY` | `AIza...` | 필수 |
| `SUPABASE_URL` | `https://xxx.supabase.co` | 필수 |
| `SUPABASE_KEY` | `eyJ...` | anon key |
| `ENV` | `production` | - |
| `TTS_ENGINE` | `edge-tts` | 기본값 |

---

## 배포 가이드

### Step 1: Supabase 설정

1. [Supabase Console](https://supabase.com) 로그인
2. 새 프로젝트 생성 (또는 기존 프로젝트 사용)
3. **Storage** → **New bucket** → `podcast-audio`
4. Bucket 설정: **Public** 체크 ✅
5. **Settings** → **API** 에서 URL과 anon key 복사

### Step 2: Render 배포

1. GitHub 저장소와 Render 연결
2. **New** → **Web Service** 선택
3. Repository 선택 → `backend` 폴더 지정
4. 설정:
   - Runtime: Docker
   - Build Command: (자동)
   - Start Command: (자동 - Dockerfile에서)
5. Environment Variables 추가
6. **Deploy** 클릭

### Step 3: 배포 확인

```bash
# Health check
curl https://your-app.onrender.com/health

# 스크립트 생성 테스트
curl -X POST https://your-app.onrender.com/api/v1/generate-script \
  -H "Content-Type: application/json" \
  -d '{"sources": [{"source_type": "url", "url": "https://example.com/article"}]}'
```

### Step 4: Flutter 앱 설정

```dart
// lib/config/environment.dart
const String apiBaseUrl = kDebugMode
    ? 'http://localhost:8000/api/v1'  // 개발
    : 'https://your-app.onrender.com/api/v1';  // 프로덕션
```

---

## 무료 티어 제한

### Render 무료 티어

| 항목 | 제한 |
|------|------|
| 슬립 | 15분 비활성 시 슬립 (재시작 ~30초) |
| 빌드 시간 | 750시간/월 |
| 대역폭 | 100GB/월 |

### Supabase 무료 티어

| 항목 | 제한 | 예상 사용량 |
|------|------|------------|
| 스토리지 | 1GB | 에피소드당 ~15MB → **~60개** |
| 대역폭 | 2GB/월 | 다운로드 ~130회/월 |
| API 요청 | 무제한 | - |

### 💡 용량 관리 팁

1. **오래된 에피소드 삭제**: 30일 이상 된 에피소드 자동 삭제
2. **오디오 품질 조절**: 비트레이트 낮추면 용량 감소
3. **사용량 모니터링**: Supabase Dashboard에서 확인

---

## 다음 단계

1. [ ] Dockerfile 및 관련 파일 생성
2. [ ] Supabase Storage 연동 코드 작성
3. [ ] 로컬 Docker 테스트
4. [ ] Supabase 프로젝트 생성 및 Bucket 설정
5. [ ] Render 배포
6. [ ] Flutter 앱에서 E2E 테스트
