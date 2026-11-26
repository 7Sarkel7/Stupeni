import 'package:flutter/material.dart';

import 'glossary.dart';
import 'models.dart';
import 'progress_store.dart';
import 'screens/glossary_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/track_screen.dart';

class StupeniApp extends StatefulWidget {
  const StupeniApp({
    super.key,
    required this.catalog,
    required this.progress,
    required this.load,
    this.loadGlossary = loadBundledGlossary,
  });

  final Catalog catalog;
  final ProgressStore progress;
  final LoadText load;
  final LoadGlossary loadGlossary;

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

  void _openGlossary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GlossaryScreen(load: widget.loadGlossary),
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
          onOpenGlossary: () => _openGlossary(context),
          onOpenLesson: (lesson) => _openLesson(context, lesson),
          onOpenTrack: (track) => _openTrack(context, track),
          onReset: () => _confirmReset(context),
        ),
      ),
    );
  }
}
