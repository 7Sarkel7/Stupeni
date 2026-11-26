import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/practice_history.dart';
import 'package:stupeni/src/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('собранный каталог открывает первый урок и его проверку', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressStore(await SharedPreferences.getInstance());
    final raw = await rootBundle.loadString('assets/content/catalog.json');
    final catalog = Catalog.parse(raw);
    expect(catalog.tracks, hasLength(11));
    expect(catalog.readyTotal, 89);

    await tester.pumpWidget(
      StupeniApp(
        catalog: catalog,
        progress: progress,
        history: PracticeHistory(await SharedPreferences.getInstance()),
        load: (path) => rootBundle.loadString('assets/content/$path'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Открыть первый урок'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('open-career')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-career')));
    await tester.pumpAndSettle();
    expect(find.text('Коллекции и цена операции'), findsOneWidget);
    Navigator.of(tester.element(find.text('Коллекции и цена операции'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-android-cis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-android-cis')));
    await tester.pumpAndSettle();
    expect(find.text('Корутины, Flow и StateFlow'), findsOneWidget);
    Navigator.of(tester.element(find.text('Корутины, Flow и StateFlow'))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Фундамент'), 400);
    expect(find.text('Фундамент'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('частично'), 400);
    expect(find.text('частично'), findsOneWidget);
    final startLesson = find.byKey(const Key('start-lesson'));
    await tester.scrollUntilVisible(startLesson, -200);
    // Длинный маршрут упирает кнопку в AppBar: сдвиг списка открывает её целиком.
    await tester.drag(find.byType(ListView).first, const Offset(0, 160));
    await tester.pumpAndSettle();
    await tester.tap(startLesson);
    await tester.pumpAndSettle();

    expect(find.text('Как Git помнит работу'), findsWidgets);
    expect(find.text('Я изучил'), findsOneWidget);

    await tester.tap(find.text('Я изучил'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-quiz')));
    await tester.pumpAndSettle();

    expect(find.textContaining('следующий коммит'), findsOneWidget);
    await tester.tap(find.text('В индексе, это уже отмеченный снимок'));
    await tester.pumpAndSettle();
    expect(find.textContaining('подготовленный снимок'), findsOneWidget);
    expect(progress.isStudied('fund-git'), isTrue);
  });
}
