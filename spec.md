# 설정 화면 리팩토링 (RadioGroup 도입)

## 개요
`SettingsScreen`에서 발생하는 `RadioListTile`의 `groupValue` 및 `onChanged` 속성 Deprecation 경고를 해결한다.
Flutter의 최신 권장 사항에 따라 `RadioGroup` 위젯을 도입하여 라디오 버튼 그룹 상태를 관리하도록 리팩토링한다.

## 문제 상황
- `RadioListTile` 사용 시 `groupValue`와 `onChanged` 속성이 Deprecated됨.
- 경고 메시지: `'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead.`

## 해결 방안
1. `SettingsScreen`의 `_showEngineSelectionDialog` 메서드 내 `RadioListTile`들을 감싸는 `Column` 상위에 `RadioGroup` 위젯을 추가한다.
2. `RadioListTile`에서 `groupValue`와 `onChanged` 속성을 제거하고, `RadioGroup`에서 통합 관리한다.
3. `RadioGroup`의 `onChanged` 콜백에서 `GenerationCubit`의 상태를 업데이트하고 다이얼로그를 닫는 로직을 구현한다.

## 변경 사항
- **File**: `app/lib/screens/settings_screen.dart`
- **Logic**:
    - `RadioGroup` 위젯 사용.
    - TTS 엔진 선택 로직을 `RadioGroup.onChanged`로 이동.
