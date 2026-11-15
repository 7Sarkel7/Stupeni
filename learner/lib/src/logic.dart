// Чистые функции прогресса. Их проверяют тесты без виджетов и без диска.

int quizPercent(int correct, int total) {
  if (total <= 0 || correct <= 0) return 0;
  if (correct >= total) return 100;
  return (correct * 100) ~/ total;
}

/// Лучший процент не понижается, если пересдать хуже.
int betterScore(int? previous, int percent) {
  if (previous == null || percent > previous) return percent;
  return previous;
}

/// Серия дней: тот же местный день не растит счётчик, следующий прибавляет,
/// дырка сбрасывает к единице.
int nextStreak({
  required int current,
  required int? lastDay,
  required int today,
}) {
  if (lastDay == null) return 1;
  if (lastDay == today) return current < 1 ? 1 : current;
  if (lastDay == today - 1) return current + 1;
  return 1;
}

/// Номер местного календарного дня, устойчивый к поясу: берём местную дату
/// и считаем полночь UTC этой календарной даты.
int localEpochDay(DateTime now) {
  final local = now.toLocal();
  final asUtcMidnight = DateTime.utc(local.year, local.month, local.day);
  return asUtcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}
