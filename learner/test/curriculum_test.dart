import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stupeni/src/models.dart';

void main() {
  final contentDir = Directory('${Directory.current.path}/../content');

  test('каталог целый, готовые уроки полные, конспекты помечены TODO', () {
    expect(
      contentDir.existsSync(),
      isTrue,
      reason: 'тесты запускают из каталога learner',
    );
    final raw = File('${contentDir.path}/catalog.json').readAsStringSync();
    final catalog = Catalog.parse(raw);

    expect(catalog.tracks.map((t) => t.order).toList(), [1, 2, 3, 4, 5, 6, 7]);
    expect(catalog.readyTotal, 12);
    expect(catalog.lessonById('fund-git'), isNotNull);

    const readySections = [
      '## Цель',
      '## Зачем это вам',
      '## Теория',
      '## Разбор на примере',
      '## Упражнения',
      '## Типичные ошибки',
      '## Чеклист',
      '## Следующий урок',
    ];

    for (final track in catalog.tracks) {
      final allReady = track.lessons.every((lesson) => lesson.isReady);
      expect(track.isReady, allReady, reason: track.id);
      for (final lesson in track.lessons) {
        final file = File('${contentDir.path}/${lesson.path}');
        expect(file.existsSync(), isTrue, reason: lesson.path);
        final text = file.readAsStringSync();
        if (lesson.isReady) {
          for (final section in readySections) {
            expect(
              text.contains(section),
              isTrue,
              reason: '${lesson.id} $section',
            );
          }
          expect(text.contains('**TODO:**'), isFalse, reason: lesson.id);
          final quizFile = File('${contentDir.path}/${lesson.quiz}');
          expect(quizFile.existsSync(), isTrue, reason: lesson.quiz);
          final quiz = Quiz.parse(quizFile.readAsStringSync());
          expect(quiz.lessonId, lesson.id);
          expect(quiz.questions.length, greaterThanOrEqualTo(4));
        } else {
          expect(text.contains('**TODO:**'), isTrue, reason: lesson.id);
          expect(lesson.quiz, isNull);
        }
      }
    }
  });
}
