import 'package:flutter/material.dart';

import '../practice.dart';
import '../practice_select.dart';
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
            'Выберите тему: задания только из неё, $practiceSessionLength '
            'за подход. Сначала новые, среди них возвращаются те, где была '
            'ошибка. Прогресс уроков не меняется.',
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

/// Подход тренировки: короткая серия заданий с мгновенной обратной связью.
/// [buildSession] вызывается заново при «Ещё раз», поэтому состав меняется.
/// [onAnswered] получает результат каждого ответа (для истории тренировки).
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.title,
    required this.buildSession,
    this.onAnswered,
    this.showTopic = false,
  });

  final String title;
  final Future<List<PracticeItem>> Function() buildSession;
  final void Function(PracticeItem item, bool correct)? onAnswered;
  final bool showTopic;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final _input = TextEditingController();
  List<PracticeItem>? _items;
  Object? _error;
  var _index = 0;
  int? _picked;
  bool? _fillCorrect;
  var _correct = 0;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _items = null;
      _error = null;
      _index = 0;
      _picked = null;
      _fillCorrect = null;
      _correct = 0;
      _finished = false;
      _input.clear();
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

  void _answered(PracticeItem item, bool right) {
    if (right) _correct += 1;
    widget.onAnswered?.call(item, right);
  }

  void _choose(int option) {
    final items = _items;
    if (items == null || _picked != null) return;
    final item = items[_index];
    final right = option == (item.task as ChoiceTask).question.correctIndex;
    setState(() {
      _picked = option;
      _answered(item, right);
    });
  }

  void _check({required bool giveUp}) {
    final items = _items;
    if (items == null || _fillCorrect != null) return;
    final item = items[_index];
    final right = !giveUp && (item.task as FillTask).accepts(_input.text);
    setState(() {
      _fillCorrect = right;
      _answered(item, right);
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
        _fillCorrect = null;
        _input.clear();
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
    if (items.isEmpty) return _message('Для этой темы пока нет заданий.');
    if (_finished) return _result(context, items.length);
    return _task(context, items);
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

  Widget _task(BuildContext context, List<PracticeItem> items) {
    final item = items[_index];
    final task = item.task;
    final theme = Theme.of(context);
    final answered = task is ChoiceTask
        ? _picked != null
        : _fillCorrect != null;
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
          Text(task.prompt, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          switch (task) {
            ChoiceTask() => _choiceBody(task),
            FillTask() => _fillBody(context, task),
          },
          if (answered) ...[
            const SizedBox(height: 8),
            Text(task.explanation),
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

  Widget _choiceBody(ChoiceTask task) {
    final question = task.question;
    return Column(
      children: [
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
      ],
    );
  }

  Widget _fillBody(BuildContext context, FillTask task) {
    final theme = Theme.of(context);
    final result = _fillCorrect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('practice-code'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            task.code,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('practice-fill-input'),
          controller: _input,
          enabled: result == null,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_input.text.trim().isNotEmpty) _check(giveUp: false);
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Что вписать вместо $fillBlank',
          ),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 12),
        if (result == null)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('practice-fill-check'),
                  onPressed: _input.text.trim().isEmpty
                      ? null
                      : () => _check(giveUp: false),
                  child: const Text('Проверить'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const Key('practice-fill-giveup'),
                onPressed: () => _check(giveUp: true),
                child: const Text('Не знаю'),
              ),
            ],
          )
        else
          Container(
            key: const Key('practice-fill-result'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result
                  ? 'Верно: ${task.shownAnswer}'
                  : 'Правильный ответ: ${task.shownAnswer}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
      ],
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
