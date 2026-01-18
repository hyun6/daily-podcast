# Implementation Plan - Delete Episode Feature

## Backend
- [x] `Backend`: Add `delete_episode` endpoint to `src/api_router.py`.
    - [x] Define `DELETE /episodes/{filename}`.
    - [x] Implement local file deletion in `data/audio`.
    - [x] Implement Supabase deletion using `storage_client.delete_audio`.

## Frontend
- [x] `Frontend`: Update `PodcastRepository` interface.
    - [x] Add `deleteEpisode(String filePath)` in `app/lib/repositories/podcast_repository.dart`.
- [x] `Frontend`: Update `RealPodcastRepository`.
    - [x] Implement `deleteEpisode` using `Dio.delete`.
    - [x] Add logic to extract filename from URL.
- [x] `Frontend`: Update `MockPodcastRepository`.
    - [x] Implement `deleteEpisode` (mock).
- [x] `Frontend`: Update `PodcastProvider`.
    - [x] Add `deletePodcast` method.
    - [x] Update `_recentPodcasts` state on success.
- [x] `Frontend`: Update `HomeScreen`.
    - [x] Add `IconButton` (delete) to `ListTile` trailing.
    - [x] Implement `onPressed` handler with `Provider` call.
