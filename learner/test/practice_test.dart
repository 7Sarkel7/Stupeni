import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/practice.dart';
import 'package:stupeni/src/progress_store.dart';
import 'package:stupeni/src/screens/practice_screen.dart';

Question _question(String id, {int correct = 0}) => Question(
  id: id,
  prompt: 'Вопрос $id',
  options: ['a$id', 'b$id', 'c$id', 'd$id'],
  correctIndex: correct,
  explanation: 'Разбор $id',
);

PracticeTopic _topic(String id) =>
    PracticeTopic(id: id, title: 'Тема $id', subtitle: '', lessonIds: const []);

Map<PracticeTopic, List<PracticeItem>> _pools(Map<String, int> sizes) {
  return {
    for (final entry in sizes.entries)
      _topic(entry.key): [
        for (var i = 0; i < entry.value; i++)
          PracticeItem(
            topic: _topic(entry.key),
            lessonId: 'l-${entry.key}',
            question: _question('${entry.key}-$i'),
          ),
      ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('микс', () {
    test('соседние вопросы из разных тем и без повторов', () {
      for (var seed = 0; seed < 30; seed++) {
        final byTopic = _pools({'a': 6, 'b': 6, 'c': 2, 'd': 1});
        final session = buildMixSession(byTopic, Random(seed));
        expect(session, hasLength(practiceSessionLength));
        for (var i = 1; i < session.length; i++) {
          expect(session[i].topic, isNot(session[i - 1].topic));
        }
        final ids = session.map((e) => e.question.id).toSet();
        expect(ids, hasLength(session.length));
      }
    });

    test('при достаточном числе тем каждая берётся один раз', () {
      final byTopic = _pools({for (var i = 0; i < 12; i++) 't$i': 3});
      final session = buildMixSession(byTopic, Random(1));
      expect(session.map((e) => e.topic).toSet(), hasLength(session.length));
    });

    test('одна тема и пустые темы не ломают сессию', () {
      final one = buildMixSession(_pools({'a': 4, 'b': 0}), Random(2));
      expect(one, hasLength(4));
      expect(buildMixSession(_pools({'a': 0}), Random(2)), isEmpty);
    });
  });

  group('тема', () {
    test('вопросы только из выбранной темы, без повторов, не больше длины', () {
      final items = _pools({'a': 25})[_topic('a')]!;
      final session = buildTopicSession(items, Random(3));
      expect(session, hasLength(practiceSessionLength));
      expect(session.map((e) => e.question.id).toSet(), hasLength(10));
      expect(session.every((e) => e.topic.id == 'a'), isTrue);
      expect(
        buildTopicSession(items.take(3).toList(), Random(3)),
        hasLength(3),
      );
    });

    test('перемешанные варианты сохраняют правильный ответ', () {
      final items = _pools({'a': 10})[_topic('a')]!;
      for (var seed = 0; seed < 20; seed++) {
        for (final item in buildTopicSession(items, Random(seed))) {
          final id = item.question.id;
          expect(item.question.options[item.question.correctIndex], 'a$id');
          expect(item.question.options.toSet(), hasLength(4));
        }
      }
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

    test('вопросы каждой темы читаются из ассетов', () async {
      for (final topic in practiceTopics) {
        final items = await loadTopicItems(catalog, topic, load);
        expect(items, isNotEmpty, reason: topic.id);
        expect(
          items.map((e) => e.question.id).toSet(),
          hasLength(items.length),
        );
      }
      final all = await loadAllTopicItems(catalog, load);
      expect(buildMixSession(all, Random(4)), hasLength(practiceSessionLength));
    });

    testWidgets('главный экран ведёт в тему и в микс, прогресс не меняется', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final progress = ProgressStore(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        StupeniApp(catalog: catalog, progress: progress, load: load),
      );
      await tester.pumpAndSettle();

      final topics = find.byKey(const Key('open-practice-topics'));
      await tester.ensureVisible(topics);
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
    });
  });

  group('экраны', () {
    late Catalog catalog;

    final quizzes = {
      for (final id in ['a', 'b'])
        '$id.quiz.json': jsonEncode({
          'lessonId': id,
          'questions': [
            for (var i = 0; i < 3; i++)
              {
                'id': '$id-$i',
                'prompt': 'Вопрос $id-$i',
                'options': ['верно', 'x', 'y', 'z'],
                'correctIndex': 0,
                'explanation': 'Разбор $id-$i',
              },
          ],
        }),
    };

    Future<String> load(String path) async => quizzes[path]!;

    LessonRef lesson(String id) => LessonRef(
      id: id,
      title: 'Урок $id',
      minutes: 5,
      status: 'ready',
      path: '$id.md',
      quiz: '$id.quiz.json',
    );

    setUp(() async {
      catalog = Catalog(
        title: 'Ступени',
        recommendedStart: 'a',
        tracks: [
          Track(
            id: 't',
            order: 1,
            title: 'Трек',
            subtitle: '',
            status: 'ready',
            summary: '',
            lessons: [lesson('a'), lesson('b')],
          ),
        ],
      );
    });

    testWidgets('тренировка по теме: проходит подход и не трогает прогресс', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PracticeSessionScreen(
            title: 'Тема',
            buildSession: () async => buildTopicSession(
              await loadTopicItems(
                catalog,
                const PracticeTopic(
                  id: 'x',
                  title: 'Тема',
                  subtitle: '',
                  lessonIds: ['a'],
                ),
                load,
              ),
              Random(1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(find.textContaining('Вопрос a-'), findsOneWidget);
        await tester.tap(find.text('верно'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('practice-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Верно 3 из 3.'), findsOneWidget);
    });
  });
}
