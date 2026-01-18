# 에피소드 삭제 기능 추가

## 개요
Flutter 앱 내부와 서버에서 생성된 팟캐스트 에피소드를 삭제하는 기능을 추가한다.
사용자가 앱의 "Recent Episodes" 리스트에서 삭제 버튼을 누르면, 해당 파일이 서버(로컬 또는 Supabase)에서 제거되고 앱의 리스트에서도 사라져야 한다.

## Backend 변경 사항

### API Endpoint
- **Method**: `DELETE`
- **Path**: `/api/v1/episodes/{filename}`
- **Description**: 지정된 파일명의 에피소드를 삭제한다.
- **Parameters**:
    - `filename`: 삭제할 파일 이름 (예: `episode_123.mp3`)

### Logic
1. `data/audio` 디렉토리에서 해당 파일 존재 여부 확인 후 삭제.
2. Supabase가 활성화되어 있다면 `StorageClient`를 통해 Supabase Storage에서도 삭제 시도.
3. 성공 시 200 OK, 실패 시 500 또는 404 반환.

## Frontend 변경 사항

### Data Repository
- `PodcastRepository` 인터페이스에 `deleteEpisode(String filePath)` 메서드 추가.
- `RealPodcastRepository` 구현:
    - `filePath` URL에서 실제 파일명(filename)을 추출.
    - `DELETE /api/v1/episodes/{filename}` 호출.
- `MockPodcastRepository` 구현: 로컬 리스트에서 제거하는 흉내.

### Provider
- `PodcastProvider`에 `deleteEpisode(Podcast podcast)` 메서드 추가.
    - Repository 호출 성공 시 `_recentPodcasts` 리스트에서 해당 객체 제거 및 `notifyListeners()`.

### UI (HomeScreen)
- `Recent Episodes` 리스트 아이템(`ListTile`)에 Trailing Icon Button(휴지통 아이콘) 추가.
- 클릭 시 확인 다이얼로그(Optional) 후 삭제 실행.

## 고려 사항
- 파일명 추출: `filePath`가 전체 URL로 되어 있으므로, 마지막 `/` 뒤의 부분을 파일명으로 간주한다.
- 동기화: 서버에서 삭제된 후 앱 상태를 업데이트한다.
