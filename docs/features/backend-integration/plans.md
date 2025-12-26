# Feature Plan: Backend Integration & Optimization

## 1. Goal
To enable real-world usage of the Podcast Engine by integrating the actual Gemini API and validating the end-to-end flow with the Flutter App.
This includes configuring environment variables, ensuring the LLM client works with real keys, and verifying audio serving.

## 2. Key Tasks
- **Environment Setup**: Ensure `.env` is properly loaded and `GEMINI_API_KEY` is accessible.
- **LLM Integration**: Review `src/api_router.py` to ensure it switches to `GeminiClient` when the API Key is present, even in development.
- **Prompt Engineering (Refinement)**: Verify the prompt in `llm_client.py` matches the "Reasoning Mode" requirements for Gemini 3 Flash.
- **CORS Config**: Configure CORS in FastAPI to allow requests from the Flutter app (especially for Web/Emulator testing).
- **Network Access**: Ensure the backend listens on `0.0.0.0` or the app points to the correct IP.

## 3. Integration Testing Plan
1.  **Backend**: Run with a valid (or dummy that passes validation) API Key.
2.  **App**: Update `SettingsScreen` or default config to point to the backend's local IP (e.g., `10.0.2.2` for Android Emulator, local IP for physical device).
3.  **Flow**: Generate Podcast -> Polling/Waiting -> Download/Stream URL -> Play.

## 4. Deliverables
- Updated `backend/src/main.py` (CORS).
- Updated `backend/src/api_router.py` (Client logic).
- `backend/README.md` with setup instructions.
- Verification Report.
