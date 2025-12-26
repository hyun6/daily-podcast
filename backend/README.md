# Daily AI Podcast Backend

FastAPI server for generating AI podcasts.

## Integration & Setup

1.  **Environment Variables**:
    Create a `.env` file in the `backend/` directory:
    ```env
    ENV=development
    GEMINI_API_KEY=your_actual_api_key_here
    TTS_ENGINE=edge-tts
    ```

    *   `GEMINI_API_KEY`: Required for actual script generation. If missing or default, it falls back to a Mock Client.
    *   `TTS_ENGINE`: `edge-tts` (Free) or `chatterbox` (High Quality).

2.  **Running the Server**:
    ```bash
    uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
    ```
    *   `--host 0.0.0.0` is crucial for allowing access from Android Emulator or external devices.

3.  **Connecting from Flutter App**:
    *   **Android Emulator**: Use `http://10.0.2.2:8000`
    *   **iOS Simulator**: Use `http://127.0.0.1:8000`
    *   **Physical Device**: Use your computer's local IP (e.g., `http://192.168.1.50:8000`).

## API Endpoints

*   `POST /api/v1/generate`: Generate a new episode.
    *   Body:
        ```json
        {
          "sources": [
            {"source_type": "rss", "url": "https://..."}
          ]
        }
        ```
*   `GET /api/v1/episodes`: List generated MP3 files.
*   `GET /downloads/{filename}`: Download/Stream audio file.
