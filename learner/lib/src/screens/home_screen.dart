import 'package:flutter/material.dart';

import '../models.dart';
import '../progress_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.catalog,
    required this.progress,
    required this.onOpenLesson,
    required this.onOpenTrack,
    required this.onReset,
  });

  final Catalog catalog;
  final ProgressStore progress;
  final void Function(LessonRef lesson) onOpenLesson;
  final void Function(Track track) onOpenTrack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final studied = progress.studiedIds;
    final readyDone = catalog.lessons
        .where((lesson) => lesson.isReady && studied.contains(lesson.id))
        .length;
    final todoDone = catalog.lessons
        .where((lesson) => !lesson.isReady && studied.contains(lesson.id))
        .length;
    final start = catalog.lessonById(catalog.recommendedStart);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ступени'),
        actions: [
          IconButton(
            tooltip: 'Сбросить прогресс',
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Пульт, прошивка и облако станца. Сначала локальный HTTP, потом всё остальное.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (start != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('С чего начать', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(start.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Около ${start.minutes} минут. Модули 01–03 написаны целиком.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('start-lesson'),
                      onPressed: () => onOpenLesson(start),
                      child: const Text('Открыть первый урок'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Готовые уроки: $readyDone из ${catalog.readyTotal}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: catalog.readyTotal == 0 ? 0 : readyDone / catalog.readyTotal,
          ),
          const SizedBox(height: 8),
          Text(
            'Конспекты TODO просмотрены: $todoDone из ${catalog.todoTotal}'
            '${progress.streak > 0 ? ' · серия ${progress.streak}\u00A0дн.' : ''}',
          ),
          const SizedBox(height: 20),
          Text('Маршрут', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final track in catalog.tracks) ...[
            _TrackTile(
              track: track,
              studied: track.studiedCount(studied),
              onTap: () => onOpenTrack(track),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.studied,
    required this.onTap,
  });

  final Track track;
  final int studied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = track.isReady;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: ready
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text('${track.order}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        _StatusChip(ready: ready),
                      ],
                    ),
                    Text(track.subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(track.summary, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('$studied из ${track.lessons.length}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(ready ? 'написан' : 'TODO'),
    );
  }
}
