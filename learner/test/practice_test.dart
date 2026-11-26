import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/practice.dart';
import 'package:stupeni/src/practice_history.dart';
import 'package:stupeni/src/practice_select.dart';
import 'package:stupeni/src/progress_store.dart';
import 'package:stupeni/src/screens/practice_screen.dart';

FillTask _fill(List<String> answers) => FillTask(
  id: 'f',
  prompt: 'Допиши',
  code: 'val d = { x: Int -> x ___ 2 }',
  answers: answers,
  explanation: 'Разбор',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('допиши код: проверка ответа', () {
    test('пробелы вокруг знаков и повторные пробелы не важны', () {
      final task = _fill(['it * 2', 'x*2']);
      expect(task.accepts('it * 2'), isTrue);
      expect(task.accepts('  it*2 '), isTrue);
      expect(task.accepts('it   *   2'), isTrue);
      expect(task.accepts('x * 2'), isTrue);
      expect(task.accepts('it * 3'), isFalse);
      expect(task.accepts(''), isFalse);
      expect(task.accepts('   '), isFalse);
    });

    test('пробел между словами важен, регистр сохраняется', () {
      final task = _fill(['val x']);
      expect(task.accepts('val  x'), isTrue);
      expect(task.accepts('valx'), isFalse);
      expect(task.accepts('Val x'), isFalse);
      expect(normalizeAnswer('git  switch -c'), 'git switch-c');
      expect(normalizeAnswer(' a , b '), 'a,b');
    });

    test('разбор файла банка: типы, id и пропуск проверяются', () {
      String bank(String task) => '{"topicId":"t","tasks":[$task]}';
      const choice =
          '{"id":"t-c01","type":"choice","prompt":"в","options":["1","2","3","4"],'
          '"correctIndex":1,"explanation":"р"}';
      const fill =
          '{"id":"t-f01","type":"fill","prompt":"в","code":"a ___","answers":["b"],'
          '"explanation":"р","lang":"bash"}';
      final tasks = parsePracticeBank(bank('$choice,$fill'), 't');
      expect(tasks[0], isA<ChoiceTask>());
      expect((tasks[1] as FillTask).lang, 'bash');

      void bad(String json) => expect(
        () => parsePracticeBank(bank(json), 't'),
        throwsFormatException,
      );
      bad('$choice,$choice');
      bad(fill.replaceAll('a ___', 'a ___ ___'));
      bad(fill.replaceAll('a ___', 'a'));
      bad(fill.replaceAll('["b"]', '[]'));
      bad(fill.replaceAll('"fill"', '"quiz"'));
      expect(
        () => parsePracticeBank(bank(choice), 'other'),
        throwsFormatException,
      );
    });
  });

  group('собранный каталог', () {
    late Catalog catalog;
    Future<String> load(String path) =>
        rootBundle.loadString('assets/content/$path');

    setUp(() async {
      catalog = Catalog.parse(await load('catalog.json'));
    });

    test('все уроки тем есть в каталоге, готовы и имеют проверку', () {
      final ids = <String>{};
      for (final topic in practiceTopics) {
        expect(ids.add(topic.id), isTrue, reason: 'повтор темы ${topic.id}');
        for (final id in topic.lessonIds) {
          final lesson = catalog.lessonById(id);
          expect(lesson, isNotNull, reason: '$id нет в каталоге');
          expect(lesson!.isReady && lesson.quiz != null, isTrue, reason: id);
        }
      }
      expect(availableTopics(catalog), hasLength(practiceTopics.length));
    });

    test('банк каждой темы: от 50 заданий, заметная доля «допиши»', () async {
      final allIds = <String>{};
      for (final topic in practiceTopics) {
        final items = await loadTopicItems(catalog, topic, load);
        final fills = items.where((e) => e.task is FillTask).length;
        expect(items.length, greaterThanOrEqualTo(50), reason: topic.id);
        expect(fills, greaterThanOrEqualTo(15), reason: topic.id);
        expect(fills / items.length, lessThan(0.5), reason: topic.id);
        for (final item in items) {
          expect(allIds.add(item.id), isTrue, reason: 'повтор ${item.id}');
        }
      }
    });

    test(
      'допустимые ответы «допиши» принимаются и не равны пропуску',
      () async {
        for (final topic in practiceTopics) {
          for (final item in await loadTopicItems(catalog, topic, load)) {
            final task = item.task;
            if (task is! FillTask) continue;
            expect(task.accepts(fillBlank), isFalse, reason: task.id);
            for (final answer in task.answers) {
              expect(task.accepts(answer), isTrue, reason: task.id);
              expect(answer.length, lessThanOrEqualTo(60), reason: task.id);
            }
          }
        }
      },
    );

    test('сессии темы и микса собираются из ассетов', () async {
      final topic = practiceTopics.firstWhere((t) => t.id == 'lambdas');
      final items = await loadTopicItems(catalog, topic, load);
      final session = buildSession({topic: items}, {}, Random(1));
      expect(session, hasLength(practiceSessionLength));
      final all = await loadAllTopicItems(catalog, load);
      final mix = buildSession(all, {}, Random(4));
      expect(mix, hasLength(practiceSessionLength));
      for (var i = 1; i < mix.length; i++) {
        expect(mix[i].topic, isNot(mix[i - 1].topic));
      }
    });

    testWidgets(
      'главный экран ведёт в тему и в микс, прогресс уроков не меняется',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final progress = ProgressStore(prefs);
        await tester.pumpWidget(
          StupeniApp(
            catalog: catalog,
            progress: progress,
            history: PracticeHistory(prefs),
            load: load,
          ),
        );
        await tester.pumpAndSettle();

        final topics = find.byKey(const Key('open-practice-topics'));
        await tester.ensureVisible(topics);
        await tester.pumpAndSettle();
        await tester.tap(topics);
        await tester.pumpAndSettle();
        expect(find.text('Тренировка по теме'), findsOneWidget);
        await tester.tap(find.byKey(const Key('practice-topic-lambdas')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Лямбды: 1 из 10'), findsOneWidget);
        expect(find.byKey(const Key('practice-topic-chip')), findsNothing);
        Navigator.of(tester.element(find.textContaining('Лямбды: 1'))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Тренировка по теме'))).pop();
        await tester.pumpAndSettle();

        final mix = find.byKey(const Key('open-practice-mix'));
        await tester.ensureVisible(mix);
        await tester.pumpAndSettle();
        await tester.tap(mix);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Микс: 1 из 10'), findsOneWidget);
        expect(find.byKey(const Key('practice-topic-chip')), findsOneWidget);

        expect(progress.studiedIds, isEmpty);
        expect(progress.streak, 0);
      },
    );
  });

  group('экран подхода', () {
    const topic = PracticeTopic(
      id: 'x',
      title: 'Тема',
      subtitle: '',
      lessonIds: [],
    );

    PracticeItem choice(String id) => PracticeItem(
      topic: topic,
      task: ChoiceTask(
        Question(
          id: id,
          prompt: 'Вопрос $id',
          options: const ['верно', 'x', 'y', 'z'],
          correctIndex: 0,
          explanation: 'Разбор $id',
        ),
      ),
    );

    PracticeItem fill(String id) => PracticeItem(
      topic: topic,
      task: FillTask(
        id: id,
        prompt: 'Допиши $id',
        code: 'val d = { x: Int -> x ___ 2 }',
        answers: const ['*', 'times'],
        explanation: 'Разбор $id',
      ),
    );

    testWidgets('выбор и «допиши»: ответы пишутся в историю, итог считается', (
      tester,
    ) async {
      final recorded = <String, bool>{};
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeSessionScreen(
            title: 'Тема',
            buildSession: () async => [choice('c1'), fill('f1'), fill('f2')],
            onAnswered: (item, correct) => recorded[item.id] = correct,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('верно'));
      await tester.pumpAndSettle();
      expect(find.text('Разбор c1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('practice-next')));
      await tester.pumpAndSettle();

      expect(find.text('Допиши f1'), findsOneWidget);
      expect(find.byKey(const Key('practice-code')), findsOneWidget);
      final check = find.byKey(const Key('practice-fill-check'));
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('practice-fill-input')),
        '  *  ',
      );
      await tester.pump();
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Верно: *'), findsOneWidget);
      expect(find.text('Разбор f1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('practice-next')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('practice-fill-input')),
        'plus',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('practice-fill-check')));
      await tester.pumpAndSettle();
      expect(find.text('Правильный ответ: *'), findsOneWidget);
      await tester.tap(find.byKey(const Key('practice-next')));
      await tester.pumpAndSettle();

      expect(find.text('Верно 2 из 3.'), findsOneWidget);
      expect(recorded, {'c1': true, 'f1': true, 'f2': false});
    });

    testWidgets('«Не знаю» засчитывается ошибкой и показывает ответ', (
      tester,
    ) async {
      final recorded = <String, bool>{};
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeSessionScreen(
            title: 'Тема',
            buildSession: () async => [fill('f1')],
            onAnswered: (item, correct) => recorded[item.id] = correct,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('practice-fill-giveup')));
      await tester.pumpAndSettle();
      expect(find.text('Правильный ответ: *'), findsOneWidget);
      expect(recorded, {'f1': false});
    });
  });
}
