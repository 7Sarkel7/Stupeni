import 'dart:convert';

import 'package:flutter/services.dart';

/// Путь к словарю в ассетах. Файл правят вручную, формат описан в `learner/README.md`.
const glossaryAsset = 'assets/glossary/glossary.json';

typedef LoadGlossary = Future<Glossary> Function();

Future<Glossary> loadBundledGlossary() async =>
    Glossary.parse(await rootBundle.loadString(glossaryAsset));

String _normalize(String value) =>
    value.toLowerCase().replaceAll('ё', 'е').trim();

class GlossaryEntry {
  GlossaryEntry({
    required this.term,
    required this.original,
    required this.definition,
    required this.example,
    this.aliases = const [],
  });

  final String term;
  final String original;
  final String definition;
  final String example;
  final List<String> aliases;

  /// Буква для заголовка группы в списке. Знаки в начале (`.gitignore`) пропускаются.
  String get letter {
    for (final rune in term.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[A-Za-zА-Яа-яЁё0-9]').hasMatch(char)) {
        return char.toUpperCase();
      }
    }
    return '#';
  }

  late final String _haystack = _normalize(
    [term, original, ...aliases].join('\n'),
  );

  /// Ищет подстроку в термине, оригинале и синонимах. Для длинных запросов
  /// отбрасывает окончание, чтобы «запахом» находило «запах кода».
  bool matches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;
    if (_haystack.contains(q)) return true;
    final cut = q.length >= 6 ? 2 : (q.length == 5 ? 1 : 0);
    return cut > 0 && _haystack.contains(q.substring(0, q.length - cut));
  }

  factory GlossaryEntry.fromJson(Object? json, int index) {
    if (json is! Map<String, dynamic>) {
      throw FormatException('Термин №${index + 1}: ожидался объект');
    }
    String field(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Термин №${index + 1} (${json['term']}): пустое поле «$key»',
        );
      }
      return value.trim();
    }

    final rawAliases = json['aliases'];
    final aliases = <String>[];
    if (rawAliases != null) {
      if (rawAliases is! List) {
        throw FormatException('Термин «${json['term']}»: aliases — не список');
      }
      for (final alias in rawAliases) {
        if (alias is! String || alias.trim().isEmpty) {
          throw FormatException('Термин «${json['term']}»: пустой синоним');
        }
        aliases.add(alias.trim());
      }
    }
    return GlossaryEntry(
      term: field('term'),
      original: field('original'),
      definition: field('definition'),
      example: field('example'),
      aliases: aliases,
    );
  }
}

class Glossary {
  Glossary._(this.entries);

  /// Термины по алфавиту: сначала русские, затем латинские.
  final List<GlossaryEntry> entries;

  factory Glossary.fromEntries(Iterable<GlossaryEntry> entries) {
    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(_normalize(entry.term))) {
        throw FormatException('Термин «${entry.term}» указан дважды');
      }
    }
    final sorted = entries.toList()
      ..sort((a, b) => _compareTerms(a.term, b.term));
    return Glossary._(List.unmodifiable(sorted));
  }

  factory Glossary.parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['terms'] is! List) {
      throw const FormatException('В словаре нет списка terms');
    }
    final terms = decoded['terms'] as List;
    return Glossary.fromEntries([
      for (var i = 0; i < terms.length; i++)
        GlossaryEntry.fromJson(terms[i], i),
    ]);
  }

  List<GlossaryEntry> search(String query) =>
      entries.where((entry) => entry.matches(query)).toList();
}

int _compareTerms(String a, String b) {
  final byScript = _scriptRank(a).compareTo(_scriptRank(b));
  if (byScript != 0) return byScript;
  return _sortKey(a).compareTo(_sortKey(b));
}

String _sortKey(String term) {
  final lower = term.toLowerCase();
  final stripped = lower.replaceFirst(RegExp(r'^[^a-zа-яё0-9]+'), '');
  // «ё» идёт сразу после «е», а не в конце алфавита.
  return stripped.replaceAll('ё', 'е\uFFFF');
}

int _scriptRank(String term) {
  final key = term.toLowerCase().replaceFirst(RegExp(r'^[^a-zа-яё0-9]+'), '');
  if (key.isEmpty) return 2;
  final code = key.codeUnitAt(0);
  if (code >= 0x0400 && code <= 0x04FF) return 0;
  if (code >= 0x61 && code <= 0x7A) return 1;
  return 2;
}
