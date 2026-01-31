# Daily AI Podcast Backend

FastAPI server for generating AI podcasts.

## Integration & Setup

1.  **Environment Variables**:
    Create a `.env` file in the `backend/` directory:
    ```env
    ENV=development
    GEMINI_API_KEY=your_actual_api_key_here
    TTS_ENGINE=edge-tts
    
    # Optional: Qwen TTS (Local)
    # TTS_ENGINE=qwen
    # QWEN_MODEL_ID=Qwen/Qwen3-TTS-12Hz-0.6B-Base
    ```

    *   `GEMINI_API_KEY`: Required for actual script generation. If missing or default, it falls back to a Mock Client.
    *   `TTS_ENGINE`: `edge-tts` (Free, Cloud) or `qwen` (Local, High Quality).

2.  **Running the Server**:
    ```bash
    uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
    ```
    *   `--host 0.0.0.0` is crucial for allowing access from Android Emulator or external devices.

3.  **Connecting from Flutter App**:
    *   **Android Emulator**: Use `http://10.0.2.2:8000`
    *   **iOS Simulator**: Use `http://127.0.0.1:8000`
    *   **Physical Device**: Use your computer's local IP (e.g., `http://192.168.1.50:8000`).

## Qwen3 TTS Setup (Local)

To use the local Qwen3 TTS engine (High Quality Voice Cloning):

1.  **Hardware Requirements**:
    *   Mac with Apple Silicon (M1/M2/M3) or NVIDIA GPU recommended.
    *   **Note**: Currently runs on **CPU** on Mac due to an MPS compatibility issue with the specific Qwen model ops. 0.6B is fast enough on CPU.
    *   ~2GB RAM for 0.6B model.

2.  **Installation**:
    The backend dependencies already include `qwen-tts`.
    The model (`Qwen/Qwen3-TTS-12Hz-0.6B-Base`) will be downloaded automatically on first run (~1.2GB).

3.  **Voice Cloning**:
    Reference audio files are automatically generated in `backend/data/voices/` (host_a.wav, host_b.wav) using Edge TTS as a seed.

## API Endpoints

*   `POST /api/v1/generate`: Generate a new episode.
    *   Body:
        ```json
        {
          "sources": [
            {"source_type": "rss", "url": "https://..."}
          ],
          "tts_engine": "qwen"
        }
        ```
*   `GET /api/v1/episodes`: List generated MP3 files.
*   `GET /downloads/{filename}`: Download/Stream audio file.
