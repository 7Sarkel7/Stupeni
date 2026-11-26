import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/practice.dart';
import 'package:stupeni/src/practice_history.dart';
import 'package:stupeni/src/practice_select.dart';

PracticeTopic _topic(String id) =>
    PracticeTopic(id: id, title: 'Тема $id', subtitle: '', lessonIds: const []);

PracticeItem _choice(PracticeTopic topic, String id) => PracticeItem(
  topic: topic,
  task: ChoiceTask(
    Question(
      id: id,
      prompt: 'Вопрос $id',
      options: ['a$id', 'b$id', 'c$id', 'd$id'],
      correctIndex: 0,
      explanation: 'Разбор $id',
    ),
  ),
);

PracticeItem _fill(PracticeTopic topic, String id) => PracticeItem(
  topic: topic,
  task: FillTask(
    id: id,
    prompt: 'Допиши $id',
    code: 'val x = ___',
    answers: const ['1'],
    explanation: 'Разбор $id',
  ),
);

Map<PracticeTopic, List<PracticeItem>> _banks(Map<String, int> sizes) => {
  for (final entry in sizes.entries)
    _topic(entry.key): [
      for (var i = 0; i < entry.value; i++)
        i % 3 == 0
            ? _fill(_topic(entry.key), '${entry.key}-f$i')
            : _choice(_topic(entry.key), '${entry.key}-c$i'),
    ],
};

TaskStats _stats({
  int shown = 1,
  int wrong = 0,
  bool lastWrong = false,
  int daysAgo = 1,
}) => TaskStats(
  shown: shown,
  wrong: wrong,
  lastShown: DateTime(2026, 6, 30).subtract(Duration(days: daysAgo)),
  lastWrong: lastWrong,
);

Iterable<String> _ids(List<PracticeItem> session) => session.map((e) => e.id);

void main() {
  group('тренировка по теме', () {
    test('без истории: 10 новых заданий без повторов, обе формы', () {
      final banks = _banks({'a': 50});
      for (var seed = 0; seed < 20; seed++) {
        final session = buildSession(banks, {}, Random(seed));
        expect(session, hasLength(practiceSessionLength));
        expect(_ids(session).toSet(), hasLength(session.length));
        expect(session.every((e) => e.topic.id == 'a'), isTrue);
      }
    });

    test('новые приоритетнее: из старых только слоты повтора', () {
      final banks = _banks({'a': 50});
      final items = banks.values.single;
      final stats = {for (final item in items.take(30)) item.id: _stats()};
      for (var seed = 0; seed < 30; seed++) {
        final session = buildSession(banks, stats, Random(seed));
        final old = session.where((e) => stats.containsKey(e.id)).length;
        expect(old, 3);
        expect(session.length - old, 7);
      }
    });

    test('ошибочные возвращаются, давно не показанные следом', () {
      final banks = _banks({'a': 50});
      final items = banks.values.single;
      final stats = {
        for (final item in items.take(20)) item.id: _stats(daysAgo: 1),
        items[3].id: _stats(lastWrong: true, wrong: 1, daysAgo: 1),
        items[5].id: _stats(lastWrong: true, wrong: 3, daysAgo: 2),
        items[7].id: _stats(daysAgo: 40),
        items[8].id: _stats(daysAgo: 30),
      };
      for (var seed = 0; seed < 30; seed++) {
        final session = buildSession(banks, stats, Random(seed));
        expect(_ids(session), containsAll([items[3].id, items[5].id]));
        expect(_ids(session), contains(items[7].id));
        expect(_ids(session), isNot(contains(items[8].id)));
      }
    });

    test('ошибка исправлена правильным ответом: больше не в приоритете', () {
      final banks = _banks({'a': 50});
      final items = banks.values.single;
      final fixed = _stats(lastWrong: false, wrong: 2, daysAgo: 1);
      final stats = {
        for (final item in items.take(20)) item.id: _stats(daysAgo: 5),
        items[0].id: fixed,
        items[1].id: _stats(daysAgo: 100),
        items[2].id: _stats(daysAgo: 90),
        items[4].id: _stats(daysAgo: 80),
      };
      for (var seed = 0; seed < 20; seed++) {
        final session = buildSession(banks, stats, Random(seed));
        expect(_ids(session), isNot(contains(items[0].id)));
        expect(
          _ids(session),
          containsAll([items[1].id, items[2].id, items[4].id]),
        );
      }
    });

    test('новые кончились: сессия добирается повторами без повторов', () {
      final banks = _banks({'a': 12});
      final items = banks.values.single;
      final stats = {for (final item in items) item.id: _stats()};
      final session = buildSession(banks, stats, Random(1));
      expect(session, hasLength(practiceSessionLength));
      expect(_ids(session).toSet(), hasLength(practiceSessionLength));
    });

    test('мало заданий в теме: сессия короче, без повторов', () {
      final banks = _banks({'a': 4});
      final session = buildSession(banks, {}, Random(1));
      expect(session, hasLength(4));
      expect(_ids(session).toSet(), hasLength(4));
      expect(buildSession(_banks({'a': 0}), {}, Random(1)), isEmpty);
    });

    test('перемешанные варианты сохраняют правильный ответ', () {
      final banks = _banks({'a': 40});
      for (var seed = 0; seed < 20; seed++) {
        for (final item in buildSession(banks, {}, Random(seed))) {
          final task = item.task;
          if (task is! ChoiceTask) continue;
          final q = task.question;
          expect(q.options[q.correctIndex], 'a${q.id}');
          expect(q.options.toSet(), hasLength(4));
        }
      }
    });
  });

  group('микс', () {
    test('соседние задания из разных тем и без повторов', () {
      for (var seed = 0; seed < 30; seed++) {
        final banks = _banks({'a': 20, 'b': 20, 'c': 5, 'd': 2});
        final session = buildSession(banks, {}, Random(seed));
        expect(session, hasLength(practiceSessionLength));
        for (var i = 1; i < session.length; i++) {
          expect(session[i].topic, isNot(session[i - 1].topic));
        }
        expect(_ids(session).toSet(), hasLength(session.length));
      }
    });

    test('при достаточном числе тем каждая берётся один раз', () {
      final banks = _banks({for (var i = 0; i < 12; i++) 't$i': 20});
      final session = buildSession(banks, {}, Random(1));
      expect(session.map((e) => e.topic).toSet(), hasLength(session.length));
    });

    test('с историей: ошибки возвращаются, соседние темы разные', () {
      for (var seed = 0; seed < 30; seed++) {
        final banks = _banks({for (var i = 0; i < 11; i++) 't$i': 50});
        final all = banks.values.expand((e) => e).toList();
        final wrongA = banks[_topic('t2')]![4];
        final wrongB = banks[_topic('t7')]![9];
        final stats = {
          for (final item in all.where((e) => e.id.hashCode % 2 == 0))
            item.id: _stats(daysAgo: 3),
          wrongA.id: _stats(lastWrong: true, wrong: 2),
          wrongB.id: _stats(lastWrong: true, wrong: 1),
        };
        final session = buildSession(banks, stats, Random(seed));
        expect(session, hasLength(practiceSessionLength));
        expect(_ids(session), containsAll([wrongA.id, wrongB.id]));
        expect(_ids(session).toSet(), hasLength(session.length));
        for (var i = 1; i < session.length; i++) {
          expect(session[i].topic, isNot(session[i - 1].topic));
        }
      }
    });

    test('одна тема и пустые темы не ломают сессию', () {
      final one = buildSession(_banks({'a': 4, 'b': 0}), {}, Random(2));
      expect(one, hasLength(4));
      expect(buildSession(_banks({'a': 0}), {}, Random(2)), isEmpty);
    });
  });
}
