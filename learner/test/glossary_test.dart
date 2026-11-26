import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stupeni/src/app.dart';
import 'package:stupeni/src/glossary.dart';
import 'package:stupeni/src/models.dart';
import 'package:stupeni/src/progress_store.dart';
import 'package:stupeni/src/screens/glossary_screen.dart';

const _tiny = '''
{
  "version": 1,
  "terms": [
    {
      "term": "Рантайм",
      "original": "runtime",
      "definition": "Время, когда программа уже запущена.",
      "example": "Ошибка в рантайме."
    },
    {
      "term": "Запах кода",
      "original": "code smell",
      "definition": "Признак рискованного кода.",
      "example": "Оператор !! в коде приложения."
    },
    {
      "term": "NPE",
      "original": "NullPointerException",
      "definition": "Падение из-за null.",
      "example": "s!!.length при s == null."
    },
    {
      "term": "Ёж-тест",
      "original": "hedgehog",
      "definition": "Проверка порядка букв.",
      "example": "Ё после Е."
    },
    {
      "term": "Единица",
      "original": "unit",
      "definition": "Один.",
      "example": "1."
    }
  ]
}
''';

Catalog _catalog() => Catalog(
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
          quiz: null,
        ),
      ],
    ),
  ],
);

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpGlossary(WidgetTester tester, String raw) async {
  _tallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(home: GlossaryScreen(load: () async => Glossary.parse(raw))),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Glossary.parse', () {
    test('сортирует по алфавиту: русские, затем латинские, ё после е', () {
      final glossary = Glossary.parse(_tiny);
      expect(glossary.entries.map((e) => e.term).toList(), [
        'Единица',
        'Ёж-тест',
        'Запах кода',
        'Рантайм',
        'NPE',
      ]);
    });

    test('отвергает дубли без учёта регистра', () {
      const raw = '''
{"terms": [
  {"term": "Баг", "original": "bug", "definition": "Ошибка.", "example": "1"},
  {"term": "баг", "original": "bug", "definition": "Ошибка.", "example": "2"}
]}
''';
      expect(() => Glossary.parse(raw), throwsFormatException);
    });

    test('отвергает пустые определения, оригиналы и примеры', () {
      for (final field in ['definition', 'original', 'example']) {
        final entry = {
          'term': 'Баг',
          'original': 'bug',
          'definition': 'Ошибка.',
          'example': 'Кнопка не работает.',
          field: '  ',
        };
        final raw =
            '{"terms": [{"term": "${entry['term']}", '
            '"original": "${entry['original']}", '
            '"definition": "${entry['definition']}", '
            '"example": "${entry['example']}"}]}';
        expect(() => Glossary.parse(raw), throwsFormatException, reason: field);
      }
    });

    test('поиск понимает формы слова и английский оригинал', () {
      final glossary = Glossary.parse(_tiny);
      expect(glossary.search('запахом').map((e) => e.term), ['Запах кода']);
      expect(glossary.search('рантайме').map((e) => e.term), ['Рантайм']);
      expect(glossary.search('code smell').map((e) => e.term), ['Запах кода']);
      expect(glossary.search('nullpointer').map((e) => e.term), ['NPE']);
      expect(glossary.search('  '), hasLength(5));
      expect(glossary.search('нет такого слова'), isEmpty);
    });
  });

  group('ассет словаря', () {
    final raw = File('assets/glossary/glossary.json').readAsStringSync();

    test('загружается, без дублей и пустых определений', () {
      final glossary = Glossary.parse(raw);
      final titles = glossary.entries
          .map((e) => e.term.toLowerCase().replaceAll('ё', 'е'))
          .toList();
      expect(titles.toSet(), hasLength(titles.length));
      expect(glossary.entries.length, greaterThanOrEqualTo(100));
      for (final entry in glossary.entries) {
        expect(entry.definition.trim(), isNotEmpty, reason: entry.term);
        expect(entry.original.trim(), isNotEmpty, reason: entry.term);
        expect(entry.example.trim(), isNotEmpty, reason: entry.term);
        expect(
          entry.definition.length,
          lessThan(420),
          reason: '«${entry.term}»: определение должно быть коротким',
        );
      }
    });

    test('в словаре есть слова, которые пояснены в уроках и проверках', () {
      final glossary = Glossary.parse(raw);
      for (final query in [
        'запах кода',
        'рантайм',
        'NPE',
        'рефакторинг',
        'boilerplate',
        'легаси',
        'хардкод',
        'костыль',
        'дебаг',
        'деплой',
        'билд',
        'коммит',
        'скрининг',
        'ревью',
        'продакшн',
        'пуш',
        'мерж',
        'таймаут',
        'колбэк',
        'CI',
      ]) {
        expect(glossary.search(query), isNotEmpty, reason: query);
      }
    });

    test('файл из pubspec читается через rootBundle', () async {
      final bundled = await rootBundle.loadString(glossaryAsset);
      expect(bundled, raw);
    });
  });

  group('экран словаря', () {
    testWidgets('показывает определение, оригинал и пример', (tester) async {
      await _pumpGlossary(tester, _tiny);

      expect(find.text('Словарь жаргона'), findsOneWidget);
      expect(find.text('Терминов: 5'), findsOneWidget);
      expect(find.text('Запах кода'), findsOneWidget);
      expect(find.text('code smell'), findsOneWidget);
      expect(find.text('Признак рискованного кода.'), findsOneWidget);
      expect(
        find.textContaining('Оператор !! в коде приложения.'),
        findsOneWidget,
      );
    });

    testWidgets('поиск сужает список, пустой результат объясняется', (
      tester,
    ) async {
      await _pumpGlossary(tester, _tiny);

      await tester.enterText(find.byKey(const Key('glossary-search')), 'запах');
      await tester.pump();
      expect(find.text('Запах кода'), findsOneWidget);
      expect(find.text('Рантайм'), findsNothing);
      expect(find.text('Найдено: 1 из 5'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('glossary-search')), 'npe');
      await tester.pump();
      expect(find.text('NPE'), findsOneWidget);
      expect(find.text('Запах кода'), findsNothing);

      await tester.enterText(find.byKey(const Key('glossary-search')), 'zzz');
      await tester.pump();
      expect(find.byKey(const Key('glossary-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('glossary-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Терминов: 5'), findsOneWidget);
      expect(find.text('Рантайм'), findsOneWidget);
    });

    testWidgets('открывается с главного экрана и кнопкой в меню', (
      tester,
    ) async {
      _tallScreen(tester);
      SharedPreferences.setMockInitialValues({});
      final progress = ProgressStore(await SharedPreferences.getInstance());

      Future<void> pumpApp() async {
        await tester.pumpWidget(
          StupeniApp(
            catalog: _catalog(),
            progress: progress,
            load: (path) async => '# Первый урок',
            loadGlossary: () async => Glossary.parse(_tiny),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpApp();
      await tester.tap(find.byKey(const Key('open-glossary-action')));
      await tester.pumpAndSettle();
      expect(find.text('Словарь жаргона'), findsOneWidget);
      expect(find.text('Рантайм'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('open-glossary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-glossary')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('glossary-search')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('glossary-search')),
        'рантайм',
      );
      await tester.pump();
      expect(find.text('Найдено: 1 из 5'), findsOneWidget);
    });

    testWidgets('настоящий словарь из ассетов: поиск по слову из квиза', (
      tester,
    ) async {
      final bundled = (await tester.runAsync(loadBundledGlossary))!;
      await tester.pumpWidget(
        MaterialApp(home: GlossaryScreen(load: () async => bundled)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('glossary-search')), 'запах');
      await tester.pump();
      expect(
        find.byKey(const Key('glossary-entry-Запах кода')),
        findsOneWidget,
      );
      expect(find.text('code smell'), findsOneWidget);
    });
  });
}
