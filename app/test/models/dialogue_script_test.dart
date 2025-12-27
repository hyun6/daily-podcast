import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/dialogue_script.dart';

void main() {
  group('DialogueLine', () {
    test('should create DialogueLine with required fields', () {
      final line = DialogueLine(speaker: 'Host A', text: '안녕하세요!');

      expect(line.speaker, 'Host A');
      expect(line.text, '안녕하세요!');
      expect(line.emotion, isNull);
    });

    test('should create DialogueLine with emotion', () {
      final line = DialogueLine(
        speaker: 'Host B',
        text: '정말요?',
        emotion: 'excited',
      );

      expect(line.speaker, 'Host B');
      expect(line.text, '정말요?');
      expect(line.emotion, 'excited');
    });

    test('should create DialogueLine from JSON', () {
      final json = {'speaker': 'Host A', 'text': '반갑습니다', 'emotion': 'neutral'};

      final line = DialogueLine.fromJson(json);

      expect(line.speaker, 'Host A');
      expect(line.text, '반갑습니다');
      expect(line.emotion, 'neutral');
    });

    test('should convert DialogueLine to JSON', () {
      final line = DialogueLine(
        speaker: 'Host A',
        text: '테스트',
        emotion: 'happy',
      );

      final json = line.toJson();

      expect(json['speaker'], 'Host A');
      expect(json['text'], '테스트');
      expect(json['emotion'], 'happy');
    });
  });

  group('DialogueScript', () {
    test('should create DialogueScript with required fields', () {
      final script = DialogueScript(title: '테스트 팟캐스트', lines: []);

      expect(script.title, '테스트 팟캐스트');
      expect(script.lines, isEmpty);
      expect(script.createdAt, isNotNull);
    });

    test('should create DialogueScript with lines', () {
      final lines = [
        DialogueLine(speaker: 'Host A', text: '안녕하세요'),
        DialogueLine(speaker: 'Host B', text: '반갑습니다'),
      ];

      final script = DialogueScript(title: '대화 테스트', lines: lines);

      expect(script.lines.length, 2);
      expect(script.lines[0].speaker, 'Host A');
      expect(script.lines[1].speaker, 'Host B');
    });

    test('should create DialogueScript from JSON', () {
      final json = {
        'title': 'JSON 테스트',
        'lines': [
          {'speaker': 'Host A', 'text': '첫번째', 'emotion': 'neutral'},
          {'speaker': 'Host B', 'text': '두번째', 'emotion': 'excited'},
        ],
        'created_at': '2025-12-27T08:00:00.000',
      };

      final script = DialogueScript.fromJson(json);

      expect(script.title, 'JSON 테스트');
      expect(script.lines.length, 2);
      expect(script.createdAt.year, 2025);
    });

    test('should convert DialogueScript to JSON', () {
      final script = DialogueScript(
        title: '변환 테스트',
        lines: [DialogueLine(speaker: 'Host A', text: '테스트')],
        createdAt: DateTime(2025, 12, 27),
      );

      final json = script.toJson();

      expect(json['title'], '변환 테스트');
      expect(json['lines'], isA<List>());
      expect((json['lines'] as List).length, 1);
    });
  });
}
