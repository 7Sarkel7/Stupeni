import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/practice_history.dart';

void main() {
  late SharedPreferences prefs;
  var clock = DateTime(2026, 6, 1, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = DateTime(2026, 6, 1, 12);
  });

  PracticeHistory open() => PracticeHistory(prefs, now: () => clock);

  test('пустая история, затем показы и ошибки считаются по заданию', () async {
    final history = open();
    expect(history.stats, isEmpty);

    await history.record('a', correct: false);
    clock = clock.add(const Duration(days: 1));
    await history.record('a', correct: false);
    await history.record('b', correct: true);

    final a = history.stats['a']!;
    expect(a.shown, 2);
    expect(a.wrong, 2);
    expect(a.lastWrong, isTrue);
    expect(a.lastShown, clock);
    final b = history.stats['b']!;
    expect(b.shown, 1);
    expect(b.wrong, 0);
    expect(b.lastWrong, isFalse);
  });

  test('верный ответ снимает метку «ошибся в последний раз»', () async {
    final history = open();
    await history.record('a', correct: false);
    await history.record('a', correct: true);
    final a = history.stats['a']!;
    expect(a.lastWrong, isFalse);
    expect(a.wrong, 1);
    expect(a.shown, 2);
  });

  test('история переживает перезапуск, сброс очищает', () async {
    await open().record('a', correct: false);
    final reopened = open();
    expect(reopened.stats['a']!.wrong, 1);
    expect(reopened.stats['a']!.lastShown, clock);

    await reopened.reset();
    expect(reopened.stats, isEmpty);
    expect(open().stats, isEmpty);
  });

  test('повреждённая запись не роняет приложение', () async {
    await prefs.setString(PracticeHistory.historyKey, '{не json');
    expect(open().stats, isEmpty);
    await prefs.setString(
      PracticeHistory.historyKey,
      '{"a":[1,0,0,0],"b":"мусор","c":[1]}',
    );
    expect(open().stats.keys, ['a']);
  });
}
