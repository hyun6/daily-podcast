# Feature Plan: Podcast Engine (Phase 1)

## 1. 개요 및 목표
Daily AI Podcast Generator의 핵심 백엔드 로직인 `podcast-engine`을 구현합니다.
이 엔진은 URL(RSS, YouTube 등)을 입력받아 텍스트를 추출하고, LLM(Gemini)을 통해 대본을 작성한 뒤, TTS(Edge-TTS)를 사용하여 오디오 파일로 변환하는 파이프라인을 담당합니다.
초기 접근성을 위해 **FastAPI** 서버로 구성하며, 추후 Flutter 앱과의 연동을 고려합니다.

## 2. 상세 요구사항
- **입력**: URL 리스트 (블로그, 뉴스 RSS, 유튜브 영상 등)
- **처리**:
    1.  **Fetcher**: URL에서 본문 텍스트 또는 자막 추출.
    2.  **Filter**: 이미 처리된 콘텐츠 필터링 (JSON 기반 상태 관리).
    3.  **Script Writer**: `gemini-3-flash-preview` (Thinking Mode)를 사용하여 2인 대화 형식 대본 생성. Rate limiting 적용.
    4.  **Audio Synthesizer**: Edge-TTS를 사용하여 대본을 음성으로 변환 및 병합.
- **출력**: 생성된 MP3 파일 및 메타데이터 JSON.
- **API**:
    - `POST /generate`: 입력된 소스들로 팟캐스트 생성 트리거.
    - `GET /episodes`: 생성된 에피소드 목록 조회.

## 3. 기술적 구현 계획
- **언어**: Python 3.10+
- **패키지 매니저**: **`uv`** (사용자 요청)
- **웹 프레임워크**: **FastAPI**
- **데이터 저장**: 로컬 **JSON 파일** (`data/processed_log.json` 등)
- **주요 라이브러리**:
    - `fastapi`, `uvicorn`: API 서버
    - `google-generativeai`: Gemini API 연동 (v3 flash)
    - `edge-tts`: 음성 합성
    - `feedparser`, `beautifulsoup4`: RSS/블로그 파싱
    - `youtube-transcript-api`: 유튜브 자막 추출
    - `pydub`: 오디오 병합 (ffmpeg 필요)
    - `pydantic`: 데이터 모델링 및 검증

### 구현 단계 (Phase 1)
1.  **Project Setup**: `uv` 초기화, FastAPI 기본 구조, 환경 변수(.env) 설정.
2.  **Core Domain Models**: Pydantic을 이용한 Input/Output/Script 모델 정의.
3.  **Fetcher Module**: RSS/Web/YouTube 파서 구현 (Mocking 테스트 포함).
4.  **Script Writer Module**: Gemini 3 Flash 연동, Thinking Mode 설정, Rate Limiter 구현.
5.  **Audio Synthesizer Module**: Edge-TTS 연동 및 오디오 병합 로직.
6.  **FastAPI Integration**: 엔드포인트 구현 및 전체 파이프라인 연결.

## 4. 제안사항 및 질문 (Resolved)
- **FastAPI**로 시작하여 확장성 확보.
- **JSON** 파일로 가볍게 상태 관리.
- **uv**를 사용하여 빠른 패키지 관리.
- **Mocking**을 통한 비용 절감 테스트 전략.
