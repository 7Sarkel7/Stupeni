import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/models.dart';
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
    expect(catalog.tracks, hasLength(7));
    expect(catalog.readyTotal, 12);

    await tester.pumpWidget(
      StupeniApp(
        catalog: catalog,
        progress: progress,
        load: (path) => rootBundle.loadString('assets/content/$path'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Фундамент'), findsOneWidget);
    expect(find.text('Открыть первый урок'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-lesson')));
    await tester.pumpAndSettle();

    expect(find.text('Git, который переживает вечер'), findsWidgets);
    expect(find.text('Я изучил'), findsOneWidget);

    await tester.tap(find.text('Я изучил'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-quiz')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Секрет облака'), findsOneWidget);
    await tester.tap(find.textContaining('считать утёкшим'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('влияет на будущие добавления'),
      findsOneWidget,
    );
    expect(progress.isStudied('fund-git'), isTrue);
  });
}
