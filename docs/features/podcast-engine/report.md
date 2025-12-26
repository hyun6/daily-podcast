# Feature Implementation Report: Podcast Engine (Phase 1)

## 1. 구현 요약
`podcast-engine`의 핵심 백엔드 로직을 **FastAPI**, **uv**, **Gemini 3 Flash**, **Edge-TTS**를 사용하여 구현했습니다.
TDD 방식으로 개발되었으며, 주요 모듈(Fetcher, Writer, Audio)에 대한 단위 테스트와 통합 테스트를 완료했습니다.

## 2. 주요 변경 사항
- **Project Structure**: `backend/` 디렉토리에 `uv` 기반 Python 프로젝트 생성.
- **API**: `POST /api/v1/generate`, `GET /api/v1/episodes` 엔드포인트 구현.
- **Modules**:
    - **Fetcher**: RSS, Web, YouTube 자막 추출기 구현 (+ Mock Tests).
    - **Writer**: Gemini 3 Flash (Thinking Mode) 연동 및 Rate Limiting 적용.
    - **Audio**: Edge-TTS를 활용한 한국어 음성 합성 및 `pydub` 기반 오디오 병합.
- **Config**: `.env` 및 `src/config.py`를 통한 환경 변수 관리 (TTS 엔진 변경 가능성 고려).

## 3. 사이드 이펙트 검토
- **의존성**: `uv`를 사용하므로 로컬 환경에 `uv` 설치가 필요합니다.
- **API Key**: `GEMINI_API_KEY`가 없으면 Mock Client가 동작하도록 설정되어 개발 편의성을 높였습니다.
- **Runtime**: `ffmpeg`가 시스템에 설치되어 있어야 `pydub`가 정상 동작합니다 (오디오 병합 시).

## 4. 추가 제안 및 개선 아이디어
- **Dockerizing**: 배포 편의를 위해 Dockerfile 추가 제안.
- **Database**: 현재는 파일 시스템에 의존하지만, 메타데이터 관리를 위해 SQLite 도입 고려.
- **Background Worker**: 긴 생성 시간(스크립트 작성 + TTS)을 고려하여 Celery나 rq 같은 비동기 큐 도입 추천.

## 5. Next Steps
- **Phase 2 (Flutter App)** 연동을 위한 API 명세서 공유.
- 실제 Gemini API Key를 발급받아 `.env` 업데이트 필요.
