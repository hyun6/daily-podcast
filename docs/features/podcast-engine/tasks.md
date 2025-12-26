# Task List: Podcast Engine

## Phase 1: Environment & Core Setup
- [x] 1. Initialize `uv` project and install dependencies (`fastapi`, `uvicorn`, `pydantic`, `pytest`).
- [x] 2. Create `src/config.py` for environment variables (API Keys, Paths).
- [x] 3. Create `src/main.py` with Hello World FastAPI endpoint.

## Phase 2: Domain Modeling
- [x] 4. Define Pydantic models in `src/models.py`.
    - Input: `ProcessingRequest`, `ContentSource`
    - Output: `PodcastEpisode`, `PodcastMetadata`
    - Script: `DialogueLine`, `DialogueScript`

## Phase 3: Content Fetcher (Mock First)
- [x] 5. Create `src/fetcher/base.py` interface.
- [x] 6. Implement `RSSFetcher` and `WebFetcher` using `feedparser`, `bs4`.
- [x] 7. Implement `YouTubeFetcher` using `youtube-transcript-api`.
- [x] 8. Write tests for fetchers (mocking network calls).

## Phase 4: Script Writer (Gemini Integration)
- [x] 9. Create `src/writer/llm_client.py`.
- [x] 10. Implement `generate_script(text_content)` with `gemini-3-flash-preview` and **Thinking Mode**.
- [x] 11. Implement **Rate Limiter** (sleep 2s) for Free Tier compliance.
- [x] 12. Create mock LLM client for testing without API costs.

## Phase 5: Audio Synthesizer (Edge TTS)
- [x] 16. Create `src/audio/tts_engine.py`.
- [x] 17. Implement `generate_audio(script)` using `edge-tts`.
- [x] 18. Implement audio merging logic using `pydub`.

## Phase 6: Integration & API
- [x] 19. Implement `POST /generate` endpoint connecting the pipeline.
- [x] 20. Implement `GET /episodes` endpoint.
- [x] 21. Verify full flow with a sample input.
