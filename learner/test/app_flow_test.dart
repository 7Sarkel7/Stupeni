import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/practice_history.dart';
import 'package:stupeni/src/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Catalog catalog;
  late ProgressStore progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = ProgressStore(await SharedPreferences.getInstance());
    catalog = Catalog(
      title: 'Ступени',
      recommendedStart: 'a',
      tracks: [
        Track(
          id: 'fund',
          order: 1,
          title: 'Фундамент',
          subtitle: 'база',
          status: 'ready',
          summary: 'общий язык',
          lessons: [
            LessonRef(
              id: 'a',
              title: 'Первый урок',
              minutes: 10,
              status: 'ready',
              path: 'a.md',
              quiz: 'a.quiz.json',
            ),
          ],
        ),
        Track(
          id: 'backend',
          order: 4,
          title: 'Backend',
          subtitle: 'облако',
          status: 'todo',
          summary: 'конспект',
          lessons: [
            LessonRef(
              id: 'b',
              title: 'Конспект NAT',
              minutes: 5,
              status: 'todo',
              path: 'b.md',
              quiz: null,
            ),
          ],
        ),
      ],
    );
  });

  Future<String> load(String path) async {
    if (path == 'a.md') {
      return '# Первый урок\n\nКороткий текст для проверки экрана.';
    }
    if (path == 'b.md') {
      return '# Конспект\n\n> **TODO:** ещё не написан.';
    }
    if (path == 'a.quiz.json') {
      return '''
{
  "lessonId": "a",
  "questions": [
    {
      "id": "q1",
      "prompt": "Где обслуживают HTTP на плате?",
      "options": ["в loop", "в конструкторе Activity", "в gitignore", "в эпоксидке"],
      "correctIndex": 0,
      "explanation": "loop вызывает handleClient."
    }
  ]
}
''';
    }
    throw StateError('нет $path');
  }

  testWidgets('маршрут: урок, отметка, проверка, конспект без квиза', (
    tester,
  ) async {
    await tester.pumpWidget(
      StupeniApp(
        catalog: catalog,
        progress: progress,
        history: PracticeHistory(await SharedPreferences.getInstance()),
        load: load,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Фундамент'), 200);
    expect(find.text('Фундамент'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Backend'), 200);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('TODO'), findsOneWidget);

    final startLesson = find.byKey(const Key('start-lesson'));
    await tester.scrollUntilVisible(startLesson, -200);
    await tester.pumpAndSettle();
    await tester.tap(startLesson);
    await tester.pumpAndSettle();
    expect(find.textContaining('Короткий текст'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-studied')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-quiz')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-quiz')));
    await tester.pumpAndSettle();
    expect(find.text('Где обслуживают HTTP на плате?'), findsOneWidget);

    await tester.tap(find.text('в loop'));
    await tester.pumpAndSettle();
    expect(find.textContaining('handleClient'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-next')));
    await tester.pumpAndSettle();
    expect(find.text('Сейчас 100%. Верно 1 из 1.'), findsOneWidget);

    await tester.tap(find.text('К уроку'));
    await tester.pumpAndSettle();
    expect(progress.bestPercent('a'), 100);

    Navigator.of(tester.element(find.byKey(const Key('open-quiz')))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Backend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Конспект NAT'));
    await tester.pumpAndSettle();
    expect(find.textContaining('это конспект'), findsOneWidget);
    expect(find.byKey(const Key('open-quiz')), findsNothing);
    await tester.tap(find.text('Конспект прочитан'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Проверка появится'), findsOneWidget);
    expect(progress.isStudied('b'), isTrue);
  });

  testWidgets('ссылка на ключ открывает текст и не ставит отметку', (
    tester,
  ) async {
    final hintCatalog = Catalog(
      title: 'Ступени',
      recommendedStart: 'a',
      tracks: [
        Track(
          id: 'fund',
          order: 1,
          title: 'Фундамент',
          subtitle: 'база',
          status: 'ready',
          summary: 'общий язык',
          lessons: [
            LessonRef(
              id: 'a',
              title: 'Первый урок',
              minutes: 10,
              status: 'ready',
              path: '01-fundamentals/01-git.md',
              quiz: 'a.quiz.json',
            ),
          ],
        ),
      ],
    );

    Future<String> hintLoad(String path) async {
      if (path == '01-fundamentals/01-git.md') {
        return '# Первый урок\n\nТекст.\n\n[Ключ к вопросам](../hints/01-git.md)\n';
      }
      if (path == 'hints/01-git.md') {
        return '# Ключ\n\nКороткий ключ песочницы.';
      }
      throw StateError('нет $path');
    }

    await tester.pumpWidget(
      StupeniApp(
        catalog: hintCatalog,
        progress: progress,
        history: PracticeHistory(await SharedPreferences.getInstance()),
        load: hintLoad,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-lesson')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ключ к вопросам'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Короткий ключ песочницы'), findsOneWidget);
    expect(
      find.textContaining('Отметку «изучил» этот экран не ставит'),
      findsOneWidget,
    );
    expect(progress.isStudied('a'), isFalse);
  });
}
