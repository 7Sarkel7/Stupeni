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
      9,
    ]);
    expect(catalog.readyTotal, 59);
    expect(catalog.lessonById('fund-git'), isNotNull);
    final career = catalog.trackById('career');
    expect(career, isNotNull);
    expect(career!.lessonStatusLabel, 'частично');
    expect(catalog.trackById('fundamentals')!.lessonStatusLabel, 'написан');
    expect(catalog.trackById('backend')!.lessonStatusLabel, 'TODO');
    final androidCis = catalog.trackById('android-cis');
    expect(androidCis, isNotNull);
    expect(androidCis!.lessonStatusLabel, 'написан');
    expect(androidCis.lessons, hasLength(17));

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
          if (lesson.id.startsWith('career-') || lesson.id.startsWith('cis-')) {
            expect(text.contains('**Уровень:**'), isTrue, reason: lesson.id);
          }
          if (lesson.id.startsWith('career-')) {
            expect(text.contains('solutions/'), isTrue, reason: lesson.id);
          }
          if (lesson.id.startsWith('cis-hw-')) {
            expect(text.contains('### Рубрика'), isTrue, reason: lesson.id);
          }
          if (lesson.id == 'cis-capstone') {
            expect(text.contains('capstone/SPEC.md'), isTrue, reason: lesson.id);
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
    expect(specText.contains('Jetpack Compose'), isTrue);
    expect(specText.contains('Material 3'), isTrue);
    expect(
      specText.contains('https://developer.android.com/develop/ui/compose/bom'),
      isTrue,
    );

    final pedagogy = File('${contentDir.path}/../PEDAGOGY.md').readAsStringSync();
    expect(
      pedagogy.contains(
        'https://developer.android.com/develop/ui/compose/documentation',
      ),
      isTrue,
    );
    expect(
      pedagogy.contains(
        'https://developer.android.com/develop/ui/compose/designsystems/material3',
      ),
      isTrue,
    );

    final composeSkeleton = File(
      '${contentDir.path}/02-kotlin-android/homework/RemoteSkeleton.kt',
    );
    final skeletonText = composeSkeleton.readAsStringSync();
    expect(skeletonText.contains('TODO('), isTrue);
    expect(skeletonText.contains('NavDisplay'), isFalse);
    expect(skeletonText.contains('collectAsStateWithLifecycle'), isFalse);
    expect(skeletonText.contains('compose-bom:20'), isFalse);

    final smenaSpec = File('${contentDir.path}/android-cis/capstone/SPEC.md');
    final smenaText = smenaSpec.readAsStringSync();
    expect(smenaText.contains('## Критерии приёмки'), isTrue);
    expect(smenaText.contains('## Рубрика для самопроверки'), isTrue);
    expect(smenaText.contains('M0.'), isTrue);
    expect(smenaText.contains('M7.'), isTrue);
    expect(smenaText.contains('WorkManager'), isTrue);
    expect(smenaText.contains('RuStore'), isTrue);
    expect(smenaText.contains('Room'), isTrue);
    final smenaNames = File(
      '${contentDir.path}/android-cis/capstone/skeleton/Names.kt',
    );
    final namesText = smenaNames.readAsStringSync();
    expect(namesText.contains('TODO('), isTrue);
    expect(namesText.contains('@HiltAndroidApp'), isFalse);
    expect(namesText.contains('class MainActivity'), isFalse);
    final outbox = File(
      '${contentDir.path}/android-cis/lab/src/main/kotlin/dev/stupeni/hire/Outbox.kt',
    );
    expect(outbox.readAsStringSync().contains('TODO('), isTrue);
    final outboxHint = File(
      '${contentDir.path}/android-cis/solutions/hint-outbox.md',
    );
    expect(outboxHint.readAsStringSync().contains('fun collapseOutbox'), isFalse);
    expect(
      pedagogy.contains('https://developer.android.com/training/dependency-injection/hilt-android'),
      isTrue,
    );
    expect(
      pedagogy.contains('https://www.rustore.ru/help/sdk/push-notifications'),
      isTrue,
    );
    expect(
      pedagogy.contains(
        'https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started',
      ),
      isTrue,
    );
  });
}
