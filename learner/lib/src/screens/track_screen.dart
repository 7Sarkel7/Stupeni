import 'package:flutter/material.dart';

import '../models.dart';
import '../progress_store.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({
    super.key,
    required this.track,
    required this.progress,
    required this.onOpenLesson,
  });

  final Track track;
  final ProgressStore progress;
  final void Function(LessonRef lesson) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(track.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(track.summary),
          const SizedBox(height: 12),
          for (var i = 0; i < track.lessons.length; i++)
            _LessonTile(
              index: i + 1,
              lesson: track.lessons[i],
              studied: progress.isStudied(track.lessons[i].id),
              best: progress.bestPercent(track.lessons[i].id),
              onTap: () => onOpenLesson(track.lessons[i]),
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.studied,
    required this.best,
    required this.onTap,
  });

  final int index;
  final LessonRef lesson;
  final bool studied;
  final int? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing = studied
        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
        : Icon(
            lesson.isReady ? Icons.menu_book_outlined : Icons.notes_outlined,
          );
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Text('$index', style: theme.textTheme.titleMedium),
        title: Text(lesson.title),
        subtitle: Text(
          lesson.isReady
              ? 'Урок · ${lesson.minutes} мин'
                    '${best != null ? ' · проверка $best%' : ''}'
              : 'Конспект TODO · полного урока ещё нет',
        ),
        trailing: trailing,
      ),
    );
  }
}
