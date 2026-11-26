import 'dart:convert';

import 'models.dart';

// Тренировка вне маршрута. Банк темы — вопросы проверок её уроков плюс
// отдельные задания из content/practice/<тема>.json. Прогресс уроков
// (лучший процент, «изучил») здесь не меняется.

class PracticeTopic {
  const PracticeTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessonIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> lessonIds;

  @override
  bool operator ==(Object other) => other is PracticeTopic && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Тема собирает вопросы проверок нескольких уроков.
/// Уроки без готовой проверки пропускаются, тема без вопросов не показывается.
const practiceTopics = <PracticeTopic>[
  PracticeTopic(
    id: 'kotlin-basics',
    title: 'Основы Kotlin',
    subtitle: 'null-safety, val и var, lazy',
    lessonIds: ['kc-basics'],
  ),
  PracticeTopic(
    id: 'control-functions',
    title: 'Условия, циклы и функции',
    subtitle: 'if и when, for, аргументы по умолчанию',
    lessonIds: ['kc-control'],
  ),
  PracticeTopic(
    id: 'lambdas',
    title: 'Лямбды',
    subtitle: 'синтаксис, функциональные типы, захват, inline',
    lessonIds: [
      'kc-lambda-syntax',
      'kc-function-types',
      'kc-nullable-lambdas',
      'kc-capture-inline',
      'kc-hw-lambdas',
    ],
  ),
  PracticeTopic(
    id: 'collections',
    title: 'Коллекции',
    subtitle: 'List, Set, операторы map, filter, groupBy',
    lessonIds: ['kc-collection-ops', 'career-collections'],
  ),
  PracticeTopic(
    id: 'scope-extensions',
    title: 'Scope-функции и extension',
    subtitle: 'let, apply, also, takeIf, расширения',
    lessonIds: ['kc-scope', 'kc-extensions'],
  ),
  PracticeTopic(
    id: 'classes',
    title: 'Классы, generics, ошибки',
    subtitle: 'data class, sealed, object, require и check',
    lessonIds: ['kc-classes', 'kc-generics-errors'],
  ),
  PracticeTopic(
    id: 'coroutines',
    title: 'Корутины и Flow',
    subtitle: 'launch, async, Job, scope, Flow',
    lessonIds: [
      'and-coroutines',
      'kc-job-scope',
      'career-coroutines',
      'cis-flow',
      'cis-threads',
    ],
  ),
  PracticeTopic(
    id: 'compose',
    title: 'Jetpack Compose',
    subtitle: 'состояние, эффекты, навигация, списки, Material 3',
    lessonIds: [
      'and-compose',
      'and-remember',
      'and-effects',
      'and-navigation',
      'and-vm-compose',
      'and-lazy',
      'and-m3',
      'and-compose-test',
    ],
  ),
  PracticeTopic(
    id: 'android-platform',
    title: 'Платформа Android',
    subtitle: 'lifecycle, разрешения, сервисы, сборка релиза',
    lessonIds: [
      'ac-lifecycle',
      'ac-serialization',
      'ac-permissions',
      'ac-ble-wifi',
      'ac-services',
      'ac-gradle-release',
    ],
  ),
  PracticeTopic(
    id: 'http-json',
    title: 'HTTP и JSON',
    subtitle: 'запросы, коды ответа, контракты, OkHttp',
    lessonIds: ['fund-http', 'fund-json', 'and-okhttp', 'career-http'],
  ),
  PracticeTopic(
    id: 'git',
    title: 'Git',
    subtitle: 'коммиты, ветки, rebase, stash, remote',
    lessonIds: [
      'fund-git',
      'fund-git-setup',
      'fund-git-daily',
      'fund-git-undo',
      'fund-git-branches',
      'fund-git-rebase',
      'fund-git-stash',
      'fund-git-remotes',
      'fund-git-github',
      'fund-git-secrets',
      'fund-git-interview',
      'fund-git-project',
    ],
  ),
];

/// Задание тренировки: вопрос с выбором или «допиши код».
sealed class PracticeTask {
  const PracticeTask();

  String get id;
  String get prompt;
  String get explanation;
}

class ChoiceTask extends PracticeTask {
  const ChoiceTask(this.question);

  final Question question;

  @override
  String get id => question.id;

  @override
  String get prompt => question.prompt;

  @override
  String get explanation => question.explanation;
}

const fillBlank = '___';

/// Фрагмент кода с одним пропуском. Ответ проверяется по списку допустимых.
class FillTask extends PracticeTask {
  const FillTask({
    required this.id,
    required this.prompt,
    required this.code,
    required this.answers,
    required this.explanation,
    this.lang = 'kotlin',
  });

  @override
  final String id;
  @override
  final String prompt;
  @override
  final String explanation;
  final String code;
  final List<String> answers;
  final String lang;

  /// Ответ, который показывают пользователю.
  String get shownAnswer => answers.first;

  bool accepts(String input) {
    final value = normalizeAnswer(input);
    if (value.isEmpty) return false;
    return answers.any((answer) => normalizeAnswer(answer) == value);
  }

  static FillTask fromJson(Map<String, dynamic> json) {
    final id = _text(json, 'id');
    final code = _text(json, 'code');
    if (RegExp(fillBlank).allMatches(code).length != 1) {
      throw FormatException('задание $id: в code нужен ровно один $fillBlank');
    }
    final raw = json['answers'];
    if (raw is! List || raw.isEmpty) {
      throw FormatException('задание $id: нет answers');
    }
    final answers = raw.map((e) => e.toString()).toList();
    if (answers.any((a) => normalizeAnswer(a).isEmpty)) {
      throw FormatException('задание $id: пустой ответ');
    }
    return FillTask(
      id: id,
      prompt: _text(json, 'prompt'),
      code: code,
      answers: answers,
      explanation: _text(json, 'explanation'),
      lang: json['lang'] is String ? json['lang'] as String : 'kotlin',
    );
  }
}

/// Пробелы вокруг знаков препинания и операторов не важны, повторные пробелы
/// схлопываются, регистр сохраняется: `it*2` и `it  *  2` совпадают, а
/// `val x` и `valx` нет.
String normalizeAnswer(String input) {
  final collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  return collapsed.replaceAllMapped(
    RegExp(r'\s*([^\p{L}\p{N}_\s])\s*', unicode: true),
    (match) => match.group(1)!,
  );
}

/// Разбор файла content/practice/<тема>.json.
List<PracticeTask> parsePracticeBank(String raw, String topicId) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('practice/$topicId: корень должен быть объектом');
  }
  if (decoded['topicId'] != topicId) {
    throw FormatException('practice/$topicId: другой topicId');
  }
  final list = decoded['tasks'];
  if (list is! List) throw FormatException('practice/$topicId: нет tasks');
  final seen = <String>{};
  final tasks = <PracticeTask>[];
  for (final item in list) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('practice/$topicId: задание не объект');
    }
    final type = item['type'];
    final PracticeTask task;
    if (type == 'choice') {
      task = ChoiceTask(Question.fromJson(item));
    } else if (type == 'fill') {
      task = FillTask.fromJson(item);
    } else {
      throw FormatException('practice/$topicId: тип $type');
    }
    if (!seen.add(task.id)) {
      throw FormatException('practice/$topicId: повтор ${task.id}');
    }
    tasks.add(task);
  }
  return tasks;
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('поле $key пустое');
  }
  return value;
}

/// Одно задание вместе с темой, из которой оно взято.
class PracticeItem {
  const PracticeItem({required this.topic, required this.task});

  final PracticeTopic topic;
  final PracticeTask task;

  String get id => task.id;
}

/// Готовые уроки темы, у которых есть файл проверки.
List<LessonRef> topicLessons(Catalog catalog, PracticeTopic topic) {
  final result = <LessonRef>[];
  for (final id in topic.lessonIds) {
    final lesson = catalog.lessonById(id);
    if (lesson != null && lesson.isReady && lesson.quiz != null) {
      result.add(lesson);
    }
  }
  return result;
}

/// Темы, по которым есть хотя бы один готовый урок с проверкой.
List<PracticeTopic> availableTopics(Catalog catalog) => [
  for (final topic in practiceTopics)
    if (topicLessons(catalog, topic).isNotEmpty) topic,
];

/// Весь банк темы: вопросы проверок уроков и задания из practice/.
Future<List<PracticeItem>> loadTopicItems(
  Catalog catalog,
  PracticeTopic topic,
  Future<String> Function(String relativePath) load,
) async {
  final lessons = topicLessons(catalog, topic);
  final results = await Future.wait([
    for (final lesson in lessons) load(lesson.quiz!),
    load('practice/${topic.id}.json'),
  ]);
  final tasks = <PracticeTask>[];
  for (var i = 0; i < lessons.length; i++) {
    for (final question in Quiz.parse(results[i]).questions) {
      tasks.add(ChoiceTask(question));
    }
  }
  tasks.addAll(parsePracticeBank(results.last, topic.id));
  final seen = <String>{};
  for (final task in tasks) {
    if (!seen.add(task.id)) {
      throw FormatException('тема ${topic.id}: повтор id ${task.id}');
    }
  }
  return [for (final task in tasks) PracticeItem(topic: topic, task: task)];
}

/// Банки всех доступных тем.
Future<Map<PracticeTopic, List<PracticeItem>>> loadAllTopicItems(
  Catalog catalog,
  Future<String> Function(String relativePath) load,
) async {
  final topics = availableTopics(catalog);
  final loaded = await Future.wait([
    for (final topic in topics) loadTopicItems(catalog, topic, load),
  ]);
  return {for (var i = 0; i < topics.length; i++) topics[i]: loaded[i]};
}
