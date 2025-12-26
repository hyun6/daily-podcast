# Tasks: Flutter Application (Phase 2)

## Phase 1: Project Setup
- [x] 1. Initialize Flutter project in `app/` directory.
- [x] 2. Clean up default boilerplate code.
- [x] 3. Install dependencies (`dio`, `provider`, `audioplayers`, `path_provider`, `shared_preferences`).

## Phase 2: Domain Layer & State
- [x] 4. Define Data Models (`Podcast`, `Source`).
- [x] 5. Create `PodcastRepository` abstract class.
- [x] 6. Implement `MockPodcastRepository` for UI testing.
- [x] 7. Setup `PodcastProvider` (State Management).

## Phase 3: UI Implementation
- [x] 8. Implement `MainScreen` with Bottom Navigation.
- [x] 9. Implement `HomeScreen` (URL Input + Recent List).
- [x] 10. Implement `PlayerScreen` (Audio Controls).
- [x] 11. Implement `SettingsScreen` (Backend URL, TTS Config).

## Phase 4: Integration
- [x] 12. Implement `RealPodcastRepository` using `dio` to connect to Python Backend.
- [x] 13. Verify full flow (Generate -> Play).
