import 'dart:math';

import 'models.dart';

// Тренировка вне маршрута: вопросы берутся из готовых проверок уроков.
// Прогресс уроков (лучший процент, «изучил») здесь не меняется.

const practiceSessionLength = 10;

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

/// Один вопрос тренировки вместе с темой, из которой он взят.
class PracticeItem {
  const PracticeItem({
    required this.topic,
    required this.lessonId,
    required this.question,
  });

  final PracticeTopic topic;
  final String lessonId;
  final Question question;
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

Future<List<PracticeItem>> loadTopicItems(
  Catalog catalog,
  PracticeTopic topic,
  Future<String> Function(String relativePath) load,
) async {
  final lessons = topicLessons(catalog, topic);
  final quizzes = await Future.wait([
    for (final lesson in lessons) load(lesson.quiz!),
  ]);
  final items = <PracticeItem>[];
  for (var i = 0; i < lessons.length; i++) {
    final quiz = Quiz.parse(quizzes[i]);
    for (final question in quiz.questions) {
      items.add(
        PracticeItem(topic: topic, lessonId: lessons[i].id, question: question),
      );
    }
  }
  return items;
}

/// Вопросы всех доступных тем, сгруппированные по теме.
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

/// Тренировка по теме: случайные вопросы одной темы без повторов.
List<PracticeItem> buildTopicSession(
  List<PracticeItem> items,
  Random random, {
  int length = practiceSessionLength,
}) {
  final shuffled = [...items]..shuffle(random);
  return [
    for (final item in shuffled.take(length)) _shuffleOptions(item, random),
  ];
}

/// Микс: каждый следующий вопрос из другой темы, чем предыдущий.
/// Сначала берётся тема, из которой вопросов задано меньше всего, поэтому
/// при достаточном числе тем подряд идущие вопросы не повторяют тему
/// и вся сессия обходит разные темы. Вопросы не повторяются.
List<PracticeItem> buildMixSession(
  Map<PracticeTopic, List<PracticeItem>> byTopic,
  Random random, {
  int length = practiceSessionLength,
}) {
  final pools = <PracticeTopic, List<PracticeItem>>{
    for (final entry in byTopic.entries)
      if (entry.value.isNotEmpty)
        entry.key: ([...entry.value]..shuffle(random)),
  };
  final used = <PracticeTopic, int>{for (final topic in pools.keys) topic: 0};
  final session = <PracticeItem>[];
  PracticeTopic? previous;
  while (session.length < length) {
    var candidates = [
      for (final entry in pools.entries)
        if (entry.value.isNotEmpty) entry.key,
    ];
    if (candidates.isEmpty) break;
    if (candidates.length > 1 && previous != null) {
      candidates = candidates.where((topic) => topic != previous).toList();
    }
    final least = candidates.map((topic) => used[topic]!).reduce(min);
    final fewest = candidates.where((topic) => used[topic] == least).toList();
    final topic = fewest[random.nextInt(fewest.length)];
    session.add(_shuffleOptions(pools[topic]!.removeLast(), random));
    used[topic] = used[topic]! + 1;
    previous = topic;
  }
  return session;
}

PracticeItem _shuffleOptions(PracticeItem item, Random random) {
  final question = item.question;
  final order = List<int>.generate(question.options.length, (i) => i)
    ..shuffle(random);
  return PracticeItem(
    topic: item.topic,
    lessonId: item.lessonId,
    question: Question(
      id: question.id,
      prompt: question.prompt,
      options: [for (final i in order) question.options[i]],
      correctIndex: order.indexOf(question.correctIndex),
      explanation: question.explanation,
    ),
  );
}
