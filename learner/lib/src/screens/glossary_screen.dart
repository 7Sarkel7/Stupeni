import 'package:flutter/material.dart';

import '../glossary.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key, required this.load});

  final LoadGlossary load;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  late final Future<Glossary> _glossary = widget.load();
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Словарь жаргона')),
      body: FutureBuilder<Glossary>(
        future: _glossary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Словарь не открылся.\n\n${snapshot.error}'),
            );
          }
          final glossary = snapshot.data;
          if (glossary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _GlossaryBody(
            glossary: glossary,
            controller: _controller,
            query: _query,
            onQueryChanged: _setQuery,
          );
        },
      ),
    );
  }
}

class _GlossaryBody extends StatelessWidget {
  const _GlossaryBody({
    required this.glossary,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
  });

  final Glossary glossary;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = glossary.search(query);
    final rows = <Object>[];
    String? currentLetter;
    for (final entry in found) {
      if (entry.letter != currentLetter) {
        currentLetter = entry.letter;
        rows.add(currentLetter);
      }
      rows.add(entry);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            key: const Key('glossary-search'),
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Найти слово: запах, рантайм, NPE',
              border: const OutlineInputBorder(),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('glossary-clear'),
                      tooltip: 'Очистить',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              query.trim().isEmpty
                  ? 'Терминов: ${glossary.entries.length}'
                  : 'Найдено: ${found.length} из ${glossary.entries.length}',
              key: const Key('glossary-count'),
              style: theme.textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: found.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ничего не нашлось по запросу «${query.trim()}».\n'
                      'Попробуйте часть слова или английское название.',
                      key: const Key('glossary-empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          row,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    return _EntryCard(entry: row as GlossaryEntry);
                  },
                ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('glossary-entry-${entry.term}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.term, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              entry.original,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(entry.definition, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Пример: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: entry.example,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
