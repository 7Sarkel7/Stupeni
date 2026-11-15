import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/logic.dart';
import 'package:stupeni/src/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('отметка урока и проверка пишут лучший процент', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore(prefs);

    await store.markStudied('fund-git');
    expect(store.isStudied('fund-git'), isTrue);
    expect(store.streak, 1);

    await store.markStudied('fund-git');
    expect(store.streak, 1);

    final best = await store.recordQuiz('fund-git', 2, 4);
    expect(best, 50);
    expect(store.bestPercent('fund-git'), 50);

    final kept = await store.recordQuiz('fund-git', 1, 4);
    expect(kept, 50);
    expect(store.bestPercent('fund-git'), 50);

    final raised = await store.recordQuiz('fund-git', 4, 4);
    expect(raised, 100);
  });

  test('пропуск дня сбрасывает серию, вчерашняя растит', () async {
    final today = localEpochDay(DateTime.now());
    SharedPreferences.setMockInitialValues({
      ProgressStore.streakKey: 4,
      ProgressStore.lastDayKey: today - 2,
    });
    final gap = ProgressStore(await SharedPreferences.getInstance());
    await gap.markStudied('a');
    expect(gap.streak, 1);

    SharedPreferences.setMockInitialValues({
      ProgressStore.streakKey: 4,
      ProgressStore.lastDayKey: today - 1,
    });
    final next = ProgressStore(await SharedPreferences.getInstance());
    await next.markStudied('b');
    expect(next.streak, 5);
  });

  test('сброс чистит отметки', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore(prefs);
    await store.markStudied('fund-git');
    await store.recordQuiz('fund-git', 4, 4);
    await store.reset();
    expect(store.studiedIds, isEmpty);
    expect(store.bestPercent('fund-git'), isNull);
    expect(store.streak, 0);
  });
}
