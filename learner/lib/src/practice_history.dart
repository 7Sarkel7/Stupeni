import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Что известно о задании: сколько раз показывали, сколько раз ошиблись,
/// когда показывали в последний раз и была ли ошибка в последний раз.
class TaskStats {
  const TaskStats({
    required this.shown,
    required this.wrong,
    required this.lastShown,
    required this.lastWrong,
  });

  final int shown;
  final int wrong;
  final DateTime lastShown;
  final bool lastWrong;

  TaskStats afterAnswer({required bool correct, required DateTime now}) =>
      TaskStats(
        shown: shown + 1,
        wrong: correct ? wrong : wrong + 1,
        lastShown: now,
        lastWrong: !correct,
      );

  List<Object> toJson() => [
    shown,
    wrong,
    lastShown.millisecondsSinceEpoch,
    lastWrong ? 1 : 0,
  ];

  static TaskStats? fromJson(Object? raw) {
    if (raw is! List || raw.length != 4) return null;
    final shown = raw[0];
    final wrong = raw[1];
    final millis = raw[2];
    final lastWrong = raw[3];
    if (shown is! int || wrong is! int || millis is! int || lastWrong is! int) {
      return null;
    }
    return TaskStats(
      shown: shown,
      wrong: wrong,
      lastShown: DateTime.fromMillisecondsSinceEpoch(millis),
      lastWrong: lastWrong == 1,
    );
  }
}

/// История показов и ошибок тренировки. Лежит в SharedPreferences на
/// устройстве, отдельно от прогресса уроков.
class PracticeHistory {
  PracticeHistory(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const historyKey = 'practice_history';

  Map<String, TaskStats>? _cache;

  Map<String, TaskStats> get stats => Map.unmodifiable(_load());

  Map<String, TaskStats> _load() {
    final cached = _cache;
    if (cached != null) return cached;
    final result = <String, TaskStats>{};
    final raw = _prefs.getString(historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final stats = TaskStats.fromJson(entry.value);
            if (stats != null) result[entry.key.toString()] = stats;
          }
        }
      } on FormatException {
        // Повреждённая запись: начинаем историю заново.
      }
    }
    return _cache = result;
  }

  Future<void> record(String taskId, {required bool correct}) async {
    final all = _load();
    final previous = all[taskId];
    all[taskId] =
        (previous ??
                TaskStats(
                  shown: 0,
                  wrong: 0,
                  lastShown: _now(),
                  lastWrong: false,
                ))
            .afterAnswer(correct: correct, now: _now());
    await _prefs.setString(
      historyKey,
      jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}),
    );
  }

  Future<void> reset() async {
    _cache = {};
    await _prefs.remove(historyKey);
  }
}
