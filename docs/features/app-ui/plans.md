# Feature Plan: Flutter Application (Phase 2)

## 1. Goal
Implementation of the Flutter mobile application (Frontend) based on the PRD.
This app will serve as the user interface for generating and playing AI podcasts.

## 2. Key Features

### A. Home Screen (Podcast Generation)
- **Input Form**: User provides a URL (RSS feed, Web link, or YouTube video).
- **Generate Button**: Triggers the backend API (`POST /generate`).
- **Loading State**: Displays a progress indicator while the podcast is being created.
- **Recent Episodes**: Lists locally available or recently generated episodes.

### B. Player Screen (Playback)
- **Audio Player**: Basic controls (Play, Pause, Seek).
- **Metadata Display**: Title, Host Names, Source Link.
- **Waveform Visualization**: (Optional for MVP, nice to have).

### C. Settings Screen
- **TTS Engine Selection**: Dropdown to choose between `edge-tts` and `chatterbox`.
- **Backend URL Config**: Input field to set the backend API address (default: `http://localhost:8000`).

## 3. Technical Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider or Riverpod (Start with Provider for simplicity).
- **Networking**: `dio` or `http`.
- **Audio Playback**: `audioplayers` or `just_audio`.
- **UI Components**: Material Design 3.

## 4. Implementation Steps (Summary)
1.  Initialize Flutter Project.
2.  Setup Dependency Injection & State Management.
3.  Implement API Client (Repository Pattern).
4.  Build Home Screen (Input & List).
5.  Build Player Screen.
6.  Build Settings Screen.

## 5. Mocking Strategy
- Use a `MockPodcastRepository` initially to develop UI without backend dependency.
