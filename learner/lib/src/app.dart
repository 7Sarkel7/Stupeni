import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'practice.dart';
import 'progress_store.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/track_screen.dart';

class StupeniApp extends StatefulWidget {
  const StupeniApp({
    super.key,
    required this.catalog,
    required this.progress,
    required this.load,
  });

  final Catalog catalog;
  final ProgressStore progress;
  final LoadText load;

  @override
  State<StupeniApp> createState() => _StupeniAppState();
}

class _StupeniAppState extends State<StupeniApp> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmReset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text(
          'Отметки «изучил», проценты проверок и серия дней сотрутся с этого устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (yes == true) await widget.progress.reset();
  }

  void _openLesson(BuildContext context, LessonRef lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LessonScreen(
          catalog: widget.catalog,
          lesson: lesson,
          progress: widget.progress,
          load: widget.load,
          onOpenLesson: (next) => _openLesson(context, next),
        ),
      ),
    );
  }

  void _openTrack(BuildContext context, Track track) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TrackScreen(
          track: track,
          progress: widget.progress,
          onOpenLesson: (lesson) => _openLesson(context, lesson),
        ),
      ),
    );
  }

  void _openPracticeTopics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PracticeTopicsScreen(
          topics: availableTopics(widget.catalog),
          onOpenTopic: (topic) => _openTopicPractice(context, topic),
        ),
      ),
    );
  }

  void _openTopicPractice(BuildContext context, PracticeTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PracticeSessionScreen(
          title: topic.title,
          buildSession: () async => buildTopicSession(
            await loadTopicItems(widget.catalog, topic, widget.load),
            Random(),
          ),
        ),
      ),
    );
  }

  void _openMixPractice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PracticeSessionScreen(
          title: 'Микс',
          showTopic: true,
          buildSession: () async => buildMixSession(
            await loadAllTopicItems(widget.catalog, widget.load),
            Random(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A6B),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Ступени',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
        ),
      ),
      home: Builder(
        builder: (context) => HomeScreen(
          catalog: widget.catalog,
          progress: widget.progress,
          onOpenLesson: (lesson) => _openLesson(context, lesson),
          onOpenTrack: (track) => _openTrack(context, track),
          onOpenPracticeTopics: () => _openPracticeTopics(context),
          onOpenPracticeMix: () => _openMixPractice(context),
          onReset: () => _confirmReset(context),
        ),
      ),
    );
  }
}
