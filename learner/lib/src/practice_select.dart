import 'dart:math';

import 'models.dart';
import 'practice.dart';
import 'practice_history.dart';

const practiceSessionLength = 10;

/// Доля старых заданий в сессии: из десяти три, если они есть.
const practiceReviewShare = 0.3;

/// Собирает сессию из банков тем с учётом истории.
///
/// - Задания внутри сессии не повторяются.
/// - Большая часть слотов отдана новым (ещё ни разу не показанным) заданиям.
/// - Остальные слоты — повтор: сначала задания, где в прошлый раз была
///   ошибка (чем больше ошибок, тем раньше), затем те, что дольше всего не
///   показывали. Слоты повтора расставлены ровно по сессии.
/// - Если новых не хватает, слоты добирают повторами, и наоборот.
/// - Соседние задания по возможности из разных тем (важно для микса).
///
/// Функция чистая: время и случайность приходят снаружи.
List<PracticeItem> buildSession(
  Map<PracticeTopic, List<PracticeItem>> byTopic,
  Map<String, TaskStats> stats,
  Random random, {
  int length = practiceSessionLength,
  double reviewShare = practiceReviewShare,
}) {
  final fresh = <PracticeTopic, List<PracticeItem>>{};
  final seen = <PracticeItem>[];
  for (final entry in byTopic.entries) {
    final unseen = <PracticeItem>[];
    for (final item in entry.value) {
      if (stats.containsKey(item.id)) {
        seen.add(item);
      } else {
        unseen.add(item);
      }
    }
    if (unseen.isNotEmpty) fresh[entry.key] = unseen..shuffle(random);
  }
  seen.shuffle(random);
  seen.sort((a, b) => _reviewOrder(stats[a.id]!, stats[b.id]!));

  final used = <PracticeTopic, int>{for (final t in byTopic.keys) t: 0};
  final reviewSlots = seen.isEmpty ? 0 : (length * reviewShare).round();
  final reviewAt = <int>{
    for (var r = 0; r < reviewSlots; r++)
      ((r + 1) * length) ~/ (reviewSlots + 1),
  };

  PracticeItem? pickFresh(PracticeTopic? previous) {
    var topics = fresh.keys.toList();
    if (topics.isEmpty) return null;
    if (previous != null && topics.length > 1) {
      topics = topics.where((t) => t != previous).toList();
    }
    final least = topics.map((t) => used[t]!).reduce(min);
    final tied = topics.where((t) => used[t] == least).toList();
    final topic = tied[random.nextInt(tied.length)];
    final list = fresh[topic]!;
    final item = list.removeLast();
    if (list.isEmpty) fresh.remove(topic);
    return item;
  }

  PracticeItem? pickSeen(PracticeTopic? previous) {
    if (seen.isEmpty) return null;
    var index = 0;
    if (previous != null) {
      final other = seen.indexWhere((item) => item.topic != previous);
      if (other >= 0) index = other;
    }
    return seen.removeAt(index);
  }

  final session = <PracticeItem>[];
  PracticeTopic? previous;
  while (session.length < length) {
    final wantReview = reviewAt.contains(session.length);
    final item = wantReview
        ? (pickSeen(previous) ?? pickFresh(previous))
        : (pickFresh(previous) ?? pickSeen(previous));
    if (item == null) break;
    session.add(_shuffleOptions(item, random));
    used[item.topic] = used[item.topic]! + 1;
    previous = item.topic;
  }
  return session;
}

/// Ошибочные раньше безошибочных, при равенстве — больше ошибок раньше,
/// затем те, что показывали давно.
int _reviewOrder(TaskStats a, TaskStats b) {
  if (a.lastWrong != b.lastWrong) return a.lastWrong ? -1 : 1;
  if (a.lastWrong && a.wrong != b.wrong) return b.wrong.compareTo(a.wrong);
  return a.lastShown.compareTo(b.lastShown);
}

PracticeItem _shuffleOptions(PracticeItem item, Random random) {
  final task = item.task;
  if (task is! ChoiceTask) return item;
  final question = task.question;
  final order = List<int>.generate(question.options.length, (i) => i)
    ..shuffle(random);
  return PracticeItem(
    topic: item.topic,
    task: ChoiceTask(
      Question(
        id: question.id,
        prompt: question.prompt,
        options: [for (final i in order) question.options[i]],
        correctIndex: order.indexOf(question.correctIndex),
        explanation: question.explanation,
      ),
    ),
  );
}
