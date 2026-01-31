# Implementation Plan - Settings Screen Refactoring

## Refactoring
- [x] `UI`: Refactor `_showEngineSelectionDialog` in `app/lib/screens/settings_screen.dart`.
    - [x] Wrap `Column` (or children) with `RadioGroup`.
    - [x] Move state management (`cubit.setTtsEngine`) to `RadioGroup.onChanged`.
    - [x] Remove deprecated `groupValue` and `onChanged` from `RadioListTile`.
    - [x] Verify no analysis errors using `dart analyze`.
