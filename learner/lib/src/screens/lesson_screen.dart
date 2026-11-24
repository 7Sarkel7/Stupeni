import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../logic.dart';
import '../models.dart';
import '../progress_store.dart';

typedef LoadText = Future<String> Function(String relativePath);

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.catalog,
    required this.lesson,
    required this.progress,
    required this.load,
    required this.onOpenLesson,
    this.markdownOverride,
  });

  final Catalog catalog;
  final LessonRef lesson;
  final ProgressStore progress;
  final LoadText load;
  final void Function(LessonRef lesson) onOpenLesson;
  final String? markdownOverride;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Future<String> _markdown;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _markdown = _read();
  }

  Future<String> _read() async {
    final override = widget.markdownOverride;
    if (override != null) return override;
    return widget.load(widget.lesson.path);
  }

  Future<void> _mark() async {
    setState(() => _busy = true);
    await widget.progress.markStudied(widget.lesson.id);
    if (mounted) setState(() => _busy = false);
  }

  void _openHref(String text, String? href) {
    if (href == null) return;
    final resolved = resolveContentHref(widget.lesson.path, href);
    if (resolved != null && isHintMarkdown(resolved)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => HintScreen(
            title: text.trim().isEmpty ? 'Ключ' : text.trim(),
            path: resolved,
            load: widget.load,
          ),
        ),
      );
      return;
    }
    final target = widget.catalog.byMarkdownBasename(href);
    if (target != null) {
      widget.onOpenLesson(target);
      return;
    }
    if (href.contains('://')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(href)));
    }
  }

  Future<void> _openQuiz() async {
    final quizPath = widget.lesson.quiz;
    if (quizPath == null) return;
    setState(() => _busy = true);
    try {
      final raw = await widget.load(quizPath);
      final quiz = Quiz.parse(raw);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => QuizScreen(
            lesson: widget.lesson,
            quiz: quiz,
            progress: widget.progress,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Проверка не открылась: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final studied = widget.progress.isStudied(lesson.id);
    final next = widget.catalog.nextAfter(lesson.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Column(
        children: [
          if (!lesson.isReady)
            Container(
              width: double.infinity,
              color: theme.colorScheme.tertiaryContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                'TODO: это конспект. Полной теории, разбора и проверки ещё нет.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<String>(
              future: _markdown,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Текст не прочитан: ${snapshot.error}\n\n'
                      'Из корня репозитория выполните ./tool/sync_content.sh',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Markdown(
                  data: snapshot.data!,
                  selectable: true,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  builders: {'a': _MarkdownLinkBuilder(onTap: _openHref)},
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    codeblockDecoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!studied)
                    FilledButton(
                      key: const Key('mark-studied'),
                      onPressed: _busy ? null : _mark,
                      child: Text(
                        lesson.isReady ? 'Я изучил' : 'Конспект прочитан',
                      ),
                    ),
                  if (studied && lesson.isReady)
                    FilledButton(
                      key: const Key('open-quiz'),
                      onPressed: _busy ? null : _openQuiz,
                      child: const Text('К проверке'),
                    ),
                  if (studied && !lesson.isReady)
                    Text(
                      'Проверка появится вместе с полным уроком.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (next != null)
                    TextButton(
                      onPressed: () => widget.onOpenLesson(next),
                      child: Text('Дальше: ${next.title}'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownLinkBuilder extends MarkdownElementBuilder {
  _MarkdownLinkBuilder({required this.onTap});

  final void Function(String text, String? href) onTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final label = element.textContent;
    final href = element.attributes['href'];
    final style = (parentStyle ?? const TextStyle())
        .merge(preferredStyle)
        .copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerUp: (_) => onTap(label, href),
      child: Text(label, style: style),
    );
  }
}

class HintScreen extends StatelessWidget {
  const HintScreen({
    super.key,
    required this.title,
    required this.path,
    required this.load,
  });

  final String title;
  final String path;
  final LoadText load;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Ключ к упражнениям. Сверьтесь после своей попытки. Отметку «изучил» этот экран не ставит.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: load(path),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Ключ не прочитан: ${snapshot.error}\n\n'
                      'Из корня репозитория выполните ./tool/sync_content.sh',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Markdown(
                  data: snapshot.data!,
                  selectable: true,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    codeblockDecoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.lesson,
    required this.quiz,
    required this.progress,
  });

  final LessonRef lesson;
  final Quiz quiz;
  final ProgressStore progress;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  var _index = 0;
  int? _picked;
  var _correct = 0;
  var _finished = false;
  int? _best;
  var _currentPercent = 0;

  Question get _question => widget.quiz.questions[_index];

  Future<void> _choose(int option) async {
    if (_picked != null) return;
    final right = option == _question.correctIndex;
    setState(() {
      _picked = option;
      if (right) _correct += 1;
    });
  }

  Future<void> _advance() async {
    final last = _index + 1 >= widget.quiz.questions.length;
    if (!last) {
      setState(() {
        _index += 1;
        _picked = null;
      });
      return;
    }
    final total = widget.quiz.questions.length;
    final percent = (total == 0) ? 0 : (_correct * 100) ~/ total;
    final best = await widget.progress.recordQuiz(
      widget.lesson.id,
      _correct,
      total,
    );
    if (!mounted) return;
    setState(() {
      _finished = true;
      _best = best;
      _currentPercent = percent;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _result(context);
    final question = _question;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Вопрос ${_index + 1} из ${widget.quiz.questions.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(question.prompt, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionButton(
                text: question.options[i],
                picked: _picked == i,
                reveal: _picked != null,
                correct: i == question.correctIndex,
                onPressed: _picked == null ? () => _choose(i) : null,
              ),
            ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            Text(question.explanation),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('quiz-next'),
              onPressed: _advance,
              child: Text(
                _index + 1 >= widget.quiz.questions.length
                    ? 'Готово'
                    : 'Дальше',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context) {
    final best = _best ?? _currentPercent;
    final kept = best > _currentPercent;
    return Scaffold(
      appBar: AppBar(title: const Text('Проверка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сейчас $_currentPercent%. Верно $_correct из ${widget.quiz.questions.length}.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              kept
                  ? 'Лучший результат по этому уроку остаётся $best%.'
                  : 'Лучший результат: $best%.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('К уроку'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.picked,
    required this.reveal,
    required this.correct,
    required this.onPressed,
  });

  final String text;
  final bool picked;
  final bool reveal;
  final bool correct;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? background;
    if (reveal && correct) background = scheme.primaryContainer;
    if (reveal && picked && !correct) background = scheme.errorContainer;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(14),
      ),
      child: Text(text),
    );
  }
}
