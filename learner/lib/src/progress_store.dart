import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Локальный прогресс: прочитанные уроки, лучший процент, серия дней.
/// Сеть не используется. Тот же приём, что последний IP пульта станца.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const studiedKey = 'studied';
  static const scoresKey = 'scores';
  static const streakKey = 'streak';
  static const lastDayKey = 'last_day';

  Set<String> get studiedIds =>
      (_prefs.getStringList(studiedKey) ?? const <String>[]).toSet();

  int get streak => _prefs.getInt(streakKey) ?? 0;

  bool isStudied(String lessonId) => studiedIds.contains(lessonId);

  int? bestPercent(String lessonId) {
    final raw = _prefs.getString(scoresKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final value = decoded[lessonId];
    if (value is! int) return null;
    return value;
  }

  Future<void> markStudied(String lessonId) async {
    final next = studiedIds;
    final added = next.add(lessonId);
    if (added) {
      final list = next.toList()..sort();
      await _prefs.setStringList(studiedKey, list);
    }
    await _touchStreak();
    notifyListeners();
  }

  /// Пишет попытку. Возвращает лучший процент после неё.
  Future<int> recordQuiz(String lessonId, int correct, int total) async {
    final percent = quizPercent(correct, total);
    final best = betterScore(bestPercent(lessonId), percent);
    final decoded = _readScores();
    decoded[lessonId] = best;
    await _prefs.setString(scoresKey, jsonEncode(decoded));
    final studied = studiedIds..add(lessonId);
    await _prefs.setStringList(studiedKey, studied.toList()..sort());
    await _touchStreak();
    notifyListeners();
    return best;
  }

  Future<void> reset() async {
    await _prefs.remove(studiedKey);
    await _prefs.remove(scoresKey);
    await _prefs.remove(streakKey);
    await _prefs.remove(lastDayKey);
    notifyListeners();
  }

  Map<String, dynamic> _readScores() {
    final raw = _prefs.getString(scoresKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> _touchStreak() async {
    final today = localEpochDay(_now());
    final last = _prefs.getInt(lastDayKey);
    final updated = nextStreak(current: streak, lastDay: last, today: today);
    await _prefs.setInt(streakKey, updated);
    await _prefs.setInt(lastDayKey, today);
  }
}
