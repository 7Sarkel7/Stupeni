import 'dart:convert';

class Catalog {
  Catalog({
    required this.title,
    required this.recommendedStart,
    required this.tracks,
  });

  final String title;
  final String recommendedStart;
  final List<Track> tracks;

  List<LessonRef> get lessons => [for (final track in tracks) ...track.lessons];

  int get readyTotal => lessons.where((lesson) => lesson.isReady).length;

  int get todoTotal => lessons.where((lesson) => !lesson.isReady).length;

  LessonRef? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  Track? trackOf(String lessonId) {
    for (final track in tracks) {
      if (track.lessons.any((lesson) => lesson.id == lessonId)) return track;
    }
    return null;
  }

  LessonRef? nextAfter(String lessonId) {
    final flat = lessons;
    final index = flat.indexWhere((lesson) => lesson.id == lessonId);
    if (index < 0 || index + 1 >= flat.length) return null;
    return flat[index + 1];
  }

  Track? trackById(String id) {
    for (final track in tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  LessonRef? byMarkdownBasename(String href) {
    final clean = href.split('?').first.split('#').first;
    if (!clean.endsWith('.md')) return null;
    final name = clean.split('/').last;
    if (name == 'README.md') return null;
    for (final lesson in lessons) {
      if (lesson.path.endsWith('/$name') || lesson.path == name) return lesson;
    }
    return null;
  }

  static Catalog parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('catalog.json: корень должен быть объектом');
    }
    final title = _string(decoded, 'title');
    final recommendedStart = _string(decoded, 'recommendedStart');
    final tracksRaw = decoded['tracks'];
    if (tracksRaw is! List || tracksRaw.isEmpty) {
      throw const FormatException('catalog.json: tracks пуст');
    }
    final tracks = <Track>[];
    final seen = <String>{};
    for (final item in tracksRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('catalog.json: трек не объект');
      }
      final track = Track.fromJson(item, seen);
      tracks.add(track);
    }
    final catalog = Catalog(
      title: title,
      recommendedStart: recommendedStart,
      tracks: tracks,
    );
    if (catalog.lessonById(recommendedStart) == null) {
      throw FormatException(
        'catalog.json: recommendedStart=$recommendedStart не найден',
      );
    }
    return catalog;
  }
}

class Track {
  Track({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.summary,
    required this.lessons,
  });

  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String status;
  final String summary;
  final List<LessonRef> lessons;

  bool get isReady => status == 'ready';

  /// Подпись для списка маршрутов: трек может быть написан частично.
  String get lessonStatusLabel {
    final ready = lessons.where((lesson) => lesson.isReady).length;
    if (ready == 0) return 'TODO';
    if (ready == lessons.length) return 'написан';
    return 'частично';
  }

  int studiedCount(Set<String> studied) =>
      lessons.where((lesson) => studied.contains(lesson.id)).length;

  static Track fromJson(Map<String, dynamic> json, Set<String> seenIds) {
    final lessonsRaw = json['lessons'];
    if (lessonsRaw is! List || lessonsRaw.isEmpty) {
      throw FormatException('трек ${json['id']}: нет уроков');
    }
    final lessons = <LessonRef>[];
    for (final item in lessonsRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('урок не объект');
      }
      final lesson = LessonRef.fromJson(item);
      if (!seenIds.add(lesson.id)) {
        throw FormatException('повтор id урока ${lesson.id}');
      }
      lessons.add(lesson);
    }
    final status = _string(json, 'status');
    if (status != 'ready' && status != 'todo') {
      throw FormatException('трек ${json['id']}: статус $status');
    }
    return Track(
      id: _string(json, 'id'),
      order: _int(json, 'order'),
      title: _string(json, 'title'),
      subtitle: _string(json, 'subtitle'),
      status: status,
      summary: _string(json, 'summary'),
      lessons: lessons,
    );
  }
}

class LessonRef {
  LessonRef({
    required this.id,
    required this.title,
    required this.minutes,
    required this.status,
    required this.path,
    required this.quiz,
  });

  final String id;
  final String title;
  final int minutes;
  final String status;
  final String path;
  final String? quiz;

  bool get isReady => status == 'ready';

  static LessonRef fromJson(Map<String, dynamic> json) {
    final status = _string(json, 'status');
    if (status != 'ready' && status != 'todo') {
      throw FormatException('урок ${json['id']}: статус $status');
    }
    final quiz = json['quiz'];
    if (quiz != null && quiz is! String) {
      throw FormatException('урок ${json['id']}: quiz не строка');
    }
    if (status == 'ready' && (quiz == null || (quiz as String).isEmpty)) {
      throw FormatException(
        'урок ${json['id']}: у готового урока нет проверки',
      );
    }
    if (status == 'todo' && quiz != null) {
      throw FormatException(
        'урок ${json['id']}: у конспекта не должно быть проверки',
      );
    }
    final path = _string(json, 'path');
    if (path.contains('..') || path.startsWith('/')) {
      throw FormatException('урок ${json['id']}: путь $path');
    }
    return LessonRef(
      id: _string(json, 'id'),
      title: _string(json, 'title'),
      minutes: _int(json, 'minutes'),
      status: status,
      path: path,
      quiz: quiz as String?,
    );
  }
}

class Quiz {
  Quiz({required this.lessonId, required this.questions});

  final String lessonId;
  final List<Question> questions;

  static Quiz parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('quiz: корень должен быть объектом');
    }
    final questionsRaw = decoded['questions'];
    if (questionsRaw is! List || questionsRaw.isEmpty) {
      throw const FormatException('quiz: нет вопросов');
    }
    final seen = <String>{};
    final questions = <Question>[];
    for (final item in questionsRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('quiz: вопрос не объект');
      }
      final question = Question.fromJson(item);
      if (!seen.add(question.id)) {
        throw FormatException('quiz: повтор ${question.id}');
      }
      questions.add(question);
    }
    return Quiz(lessonId: _string(decoded, 'lessonId'), questions: questions);
  }
}

class Question {
  Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  static Question fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    if (optionsRaw is! List || optionsRaw.length != 4) {
      throw FormatException('вопрос ${json['id']}: нужно 4 варианта');
    }
    final options = optionsRaw.map((e) => e.toString()).toList();
    if (options.toSet().length != options.length) {
      throw FormatException('вопрос ${json['id']}: варианты повторяются');
    }
    final correct = _int(json, 'correctIndex');
    if (correct < 0 || correct >= options.length) {
      throw FormatException('вопрос ${json['id']}: correctIndex');
    }
    final explanation = _string(json, 'explanation');
    return Question(
      id: _string(json, 'id'),
      prompt: _string(json, 'prompt'),
      options: options,
      correctIndex: correct,
      explanation: explanation,
    );
  }
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('поле $key пустое');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('поле $key не целое');
  return value;
}
