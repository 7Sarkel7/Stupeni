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

    expect(catalog.tracks.map((t) => t.order).toList(), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
    ]);
    expect(catalog.readyTotal, 32);
    expect(catalog.lessonById('fund-git'), isNotNull);
    final career = catalog.trackById('career');
    expect(career, isNotNull);
    expect(career!.lessonStatusLabel, 'частично');
    expect(catalog.trackById('fundamentals')!.lessonStatusLabel, 'написан');
    expect(catalog.trackById('backend')!.lessonStatusLabel, 'TODO');

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
          if (lesson.id.startsWith('career-')) {
            expect(text.contains('**Уровень:**'), isTrue, reason: lesson.id);
            expect(text.contains('solutions/'), isTrue, reason: lesson.id);
          }
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

  test('лаборатория без готового решения, спека капстоуна на месте', () {
    final lab = File(
      '${contentDir.path}/career/lab/src/main/kotlin/dev/stupeni/career/Collections.kt',
    );
    final hint = File('${contentDir.path}/career/solutions/01-collections.md');
    final spec = File('${contentDir.path}/career/capstone/SPEC.md');
    final skeleton = File(
      '${contentDir.path}/03-cpp-esp32/homework/status_skeleton.ino',
    );
    expect(lab.readAsStringSync().contains('TODO('), isTrue);
    expect(hint.readAsStringSync().contains('fun wordCount'), isFalse);
    expect(skeleton.readAsStringSync().contains('server.send'), isFalse);
    expect(
      Directory('${contentDir.path}/career/solutions/kotlin').existsSync(),
      isFalse,
    );
    final specText = spec.readAsStringSync();
    expect(specText.contains('## Критерии приёмки'), isTrue);
    expect(specText.contains('## Рубрика для самопроверки'), isTrue);
    expect(specText.contains('M0.'), isTrue);
    expect(specText.contains('M4.'), isTrue);
  });
}
