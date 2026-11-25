import 'package:flutter/material.dart';

import '../practice.dart';
import 'lesson_screen.dart';

class PracticeTopicsScreen extends StatelessWidget {
  const PracticeTopicsScreen({
    super.key,
    required this.topics,
    required this.onOpenTopic,
  });

  final List<PracticeTopic> topics;
  final void Function(PracticeTopic topic) onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Тренировка по теме')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Выберите тему: вопросы только из неё, до $practiceSessionLength '
            'за подход. Прогресс уроков не меняется.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final topic in topics) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: Key('practice-topic-${topic.id}'),
                title: Text(topic.title),
                subtitle: Text(topic.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenTopic(topic),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Подход тренировки: короткая серия вопросов с мгновенной обратной связью.
/// [buildSession] вызывается заново при «Ещё раз», поэтому порядок меняется.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.title,
    required this.buildSession,
    this.showTopic = false,
  });

  final String title;
  final Future<List<PracticeItem>> Function() buildSession;
  final bool showTopic;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  List<PracticeItem>? _items;
  Object? _error;
  var _index = 0;
  int? _picked;
  var _correct = 0;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _items = null;
      _error = null;
      _index = 0;
      _picked = null;
      _correct = 0;
      _finished = false;
    });
    try {
      final items = await widget.buildSession();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _choose(int option) {
    final items = _items;
    if (items == null || _picked != null) return;
    setState(() {
      _picked = option;
      if (option == items[_index].question.correctIndex) _correct += 1;
    });
  }

  void _advance() {
    final items = _items!;
    setState(() {
      if (_index + 1 >= items.length) {
        _finished = true;
      } else {
        _index += 1;
        _picked = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_error != null) {
      return _message(
        'Тренировка не открылась: $_error',
        action: FilledButton(onPressed: _start, child: const Text('Повторить')),
      );
    }
    if (items == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) return _message('Для этой темы пока нет вопросов.');
    if (_finished) return _result(context, items.length);
    return _question(context, items);
  }

  Widget _message(String text, {Widget? action}) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _question(BuildContext context, List<PracticeItem> items) {
    final item = items[_index];
    final question = item.question;
    final theme = Theme.of(context);
    final last = _index + 1 >= items.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}: ${_index + 1} из ${items.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          LinearProgressIndicator(value: _index / items.length),
          const SizedBox(height: 16),
          if (widget.showTopic) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                key: const Key('practice-topic-chip'),
                label: Text(item.topic.title),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(question.prompt, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QuizOptionButton(
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
              key: const Key('practice-next'),
              onPressed: _advance,
              child: Text(last ? 'Готово' : 'Дальше'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _result(BuildContext context, int total) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Верно $_correct из $total.',
              key: const Key('practice-result'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('practice-again'),
              onPressed: _start,
              child: const Text('Ещё раз'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }
}
