# Walkthrough - Delete Episode Feature

## Changes

### Backend
- Modified `backend/src/api_router.py`:
    - Imported `storage_client`.
    - Added `DELETE /episodes/{filename}` endpoint.
    - Implemented logic to delete from local `data/audio` and Supabase.

### Frontend
- Modified `app/lib/repositories/podcast_repository.dart`: 
    - Added `deleteEpisode(String filePath)` to the interface.
- Modified `app/lib/repositories/real_podcast_repository.dart`:
    - Implemented `deleteEpisode` to call the new API endpoint.
- Modified `app/lib/repositories/mock_podcast_repository.dart`:
    - Added mock implementation for `deleteEpisode`.
- Modified `app/lib/providers/podcast_provider.dart`:
    - Added `deletePodcast` method to handle state updates and null safety.
    - Fixed a bug in `generateAudioFromCurrentScript` (restored `finally` block).
- Modified `app/lib/screens/home_screen.dart`:
    - Added a delete icon button to the episode list.
    - Added a confirmation dialog before deletion.

## Verification Results

### Automatic Verification
- **Backend**: Created a dummy file `test_delete.mp3` and successfully deleted it via `curl -X DELETE`.
- **Frontend Analysis**: `flutter analyze` passed (with one unrelated deprecation warning).

### Manual Verification Steps
1. Open the app.
2. Generate a podcast or view `Recent Episodes`.
3. Click the delete (trash) icon on an episode.
4. Confirm deletion in the dialog.
5. Verify the episode disappears from the list.
6. Verify the file is removed from the server (or Supabase).
