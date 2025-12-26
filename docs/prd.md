# Project: Daily AI Podcast Generator (NotebookLM Clone)

## 1. Project Overview
**Goal**: Build a multi-platform application that automatically converts daily content from specific RSS feeds, Blogs, and YouTube channels into a "Podcast-style" audio conversation between two AI hosts.
**Core Value**: Create a personalized "Daily Audio Briefing" playlist that users can listen to continuously, similar to a music playlist.

## 2. Technical Stack Strategy (Mandatory)
The agent must use the following technology stack to ensure multi-platform support and cost-efficiency.

### Frontend (Mobile/Desktop App)
* **Framework**: **Flutter** (Dart)
    * *Reason*: Single codebase for iOS, Android, Windows, and macOS.
* **State Management**: Riverpod (or Provider)
* **Audio Player**: `just_audio` (for background playback & playlist management) + `audio_service` (for lock screen controls).
* **Local Storage**: `hive` or `shared_preferences` (for storing feed URLs and settings).

### Backend (Logic & Processing)
* **Language**: **Python 3.10+** (Local execution or Lightweight Server)
* **Key Libraries**:
    * `google-generativeai`: For accessing **Gemini 3 Flash** (Script generation with Thinking Mode).
    * `edge-tts`: For generating high-quality speech without API costs.
    * `beautifulsoup4` / `feedparser`: For scraping web/blog content.
    * `youtube-transcript-api`: For extracting YouTube subtitles.
    * `pydub` + `ffmpeg`: For merging audio segments and background music.
    * `fastapi` (Optional): If a local API server is needed to communicate with the Flutter app.

---

## 3. Functional Requirements (Step-by-Step)

### Phase 1: Python Backend (The Content Pipeline)
The agent shall create a Python script (`podcast_engine.py`) that performs the following:

1.  **Fetcher Module**:
    * Accept a list of URLs (RSS, Blog Article, YouTube Video).
    * Check `last_processed_timestamp` to filter only new content.
    * Extract text content (Body text for blogs, Transcript for YouTube).
2.  **Script Writer Module (LLM)**:
    * Use **`gemini-3-flash-preview`** (or latest `gemini-3-flash` variant).
    * **Reasoning Config**:
        * Enable **Thinking Mode** to improve script quality.
        * Set `thinking_level="medium"` (Balanced for scriptwriting).
    * **Prompt Logic**: "Analyze the input text using your reasoning capabilities. Identify the key insights and emotional tone. Then, generate a 5-minute engaging podcast script between two hosts (Host A: Professional/Male, Host B: Curious/Female). Output format: JSON Array."
    * **Cost Management**:
        * Utilize the **Free Tier** of Google AI Studio.
        * Implement rate limiting (sleep 2-3 seconds between requests) as per Flash tier limits.
3.  **Audio Synthesizer Module (TTS)**:
    * Parse the JSON script.
    * Use `edge-tts` to generate audio files for each line using distinct voices (e.g., `ko-KR-InJoonNeural` for Male, `ko-KR-SunHiNeural` for Female).
    * Combine all audio clips into a single `.mp3` file.
    * (Optional) Mix a soft background music track at low volume (-20dB).
4.  **Output**:
    * Save the final MP3 file to a structured directory: `./downloads/YYYY-MM-DD_{Title}.mp3`.
    * Generate a metadata JSON file for the app to read (Title, Duration, Source URL).

### Phase 2: Flutter Application (The Player)
The agent shall create a Flutter app with the following screens:

1.  **Home Screen (Playlist)**:
    * List generated audio files sorted by date (Newest first).
    * Show metadata: Title, Source Name, Duration.
    * "Refresh" button to trigger the Python backend (if running locally) or reload the file list.
2.  **Player Screen**:
    * Standard controls: Play, Pause, Next, Previous, Seek bar.
    * Speed control (1.0x, 1.25x, 1.5x).
    * **Crucial**: Support continuous playback (Auto-play next track).
3.  **Settings / Feed Management**:
    * Add/Remove target URLs (YouTube Channels, Blog RSS).
    * Input Google Gemini API Key.

---

## 4. UI/UX Design Guidelines
* **Theme**: Dark Mode (Cyberpunk or Midnight Blue style).
* **Style**: Minimalist. Focus on the "Play" button and the list.
* **Reference**: Spotify or Apple Podcasts UI.

## 5. Development Constraints & Rules
* **Zero-Cost Operation**: Do not use paid TTS APIs (like OpenAI Audio or ElevenLabs). Stick to `edge-tts`.
* **Error Handling**: If a YouTube video has no subtitles, the backend must skip it and log a warning, rather than crashing.
* **File Handling**: Ensure the app has permission to read/write local files (adjust `AndroidManifest.xml` and `Info.plist` accordingly).

---

## 6. Implementation Prompts (For Agent)
*Start by setting up the Python virtual environment and installing necessary dependencies. Then, create the `Fetcher Module` to test text extraction from a sample URL.*