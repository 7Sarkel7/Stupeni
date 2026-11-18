import 'package:flutter_test/flutter_test.dart';
import 'package:stupeni/src/logic.dart';

void main() {
  test('процент проверки режет края', () {
    expect(quizPercent(0, 4), 0);
    expect(quizPercent(1, 4), 25);
    expect(quizPercent(4, 4), 100);
    expect(quizPercent(3, 0), 0);
    expect(quizPercent(-1, 4), 0);
  });

  test('лучший процент не понижается', () {
    expect(betterScore(null, 40), 40);
    expect(betterScore(40, 100), 100);
    expect(betterScore(100, 40), 100);
    expect(betterScore(0, 0), 0);
  });

  test('серия дней не прыгает внутри суток и рвётся на пропуске', () {
    expect(nextStreak(current: 0, lastDay: null, today: 10), 1);
    expect(nextStreak(current: 3, lastDay: 10, today: 10), 3);
    expect(nextStreak(current: 3, lastDay: 9, today: 10), 4);
    expect(nextStreak(current: 3, lastDay: 8, today: 10), 1);
    expect(nextStreak(current: 0, lastDay: 10, today: 10), 1);
  });

  test('ссылка на ключ остаётся внутри content', () {
    expect(
      resolveContentHref('01-fundamentals/01-git.md', '../hints/01-git.md'),
      'hints/01-git.md',
    );
    expect(
      resolveContentHref('01-fundamentals/01-git.md', '02-http.md'),
      '01-fundamentals/02-http.md',
    );
    expect(
      resolveContentHref(
        '01-fundamentals/01-git.md',
        'https://git-scm.com/docs',
      ),
      isNull,
    );
    expect(
      resolveContentHref(
        '01-fundamentals/01-git.md',
        '../hints/../../etc/passwd.md',
      ),
      isNull,
    );
    expect(isHintMarkdown('hints/01-git-02-setup.md'), isTrue);
    expect(isHintMarkdown('01-fundamentals/01-git.md'), isFalse);
    expect(isHintMarkdown('hints/nested/01-git.md'), isFalse);
  });

  test('местный день один и тот же утром и вечером', () {
    final morning = DateTime(2026, 11, 1, 8, 30);
    final evening = DateTime(2026, 11, 1, 23, 10);
    expect(localEpochDay(morning), localEpochDay(evening));
    expect(
      localEpochDay(DateTime(2026, 11, 2, 0, 5)),
      isNot(localEpochDay(evening)),
    );
  });
}
