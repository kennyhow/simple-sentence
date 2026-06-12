import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_models.dart';
import '../services/settings_service.dart';
import '../services/workmanager_service.dart';
import 'card_preview_screen.dart';

/// Screen showing candidate words from the LLM lookup.
/// User picks one word and selects which usages to mine.
class CandidatesScreen extends StatefulWidget {
  final String query;
  final List<CandidateWord> candidates;
  final SettingsService settings;
  final VoidCallback? onCardGenerated;

  const CandidatesScreen({
    super.key,
    required this.query,
    required this.candidates,
    required this.settings,
    this.onCardGenerated,
  });

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  // wordId -> set of selected usageIds
  final Map<String, Set<String>> _selectedUsages = {};
  String? _expandedWordId;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default: select first usage of first word
    if (widget.candidates.isNotEmpty) {
      final first = widget.candidates.first;
      _expandedWordId = first.id;
      _selectedUsages[first.id] = {first.usages.first.id};
    }
  }

  Future<void> _generateCard() async {
    // Find the word with selected usages
    CandidateWord? selectedWord;
    List<WordUsage> selectedUsagesList = [];

    for (final word in widget.candidates) {
      final usageIds = _selectedUsages[word.id];
      if (usageIds != null && usageIds.isNotEmpty) {
        selectedWord = word;
        selectedUsagesList =
            word.usages.where((u) => usageIds.contains(u.id)).toList();
        break;
      }
    }

    if (selectedWord == null || selectedUsagesList.isEmpty) {
      setState(() => _error = 'Please select at least one usage.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      await scheduleGenerateCard(
        word: selectedWord,
        selectedUsages: selectedUsagesList,
      );

      // Poll for result
      await _waitForCard(selectedWord, selectedUsagesList);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _waitForCard(
      CandidateWord word, List<WordUsage> usages) async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final raw = prefs.getString('last_generated_card');
      if (raw != null) {
        final card = AnkiCard.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        if (card.word == word.word) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CardPreviewScreen(
                card: card,
                settings: widget.settings,
                onCardPushed: widget.onCardGenerated,
              ),
            ),
          );
          return;
        }
      }
    }
    setState(() {
      _isGenerating = false;
      _error = 'Timed out. Check notification tray — the card may be ready.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.query}"'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.candidates.length,
              itemBuilder: (context, index) {
                final word = widget.candidates[index];
                final isExpanded = _expandedWordId == word.id;
                final selectedCount =
                    _selectedUsages[word.id]?.length ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word header
                      ListTile(
                        leading: Radio<String>(
                          value: word.id,
                          groupValue: _expandedWordId,
                          onChanged: (v) {
                            setState(() {
                              _expandedWordId = v;
                              // Auto-select first usage if none selected
                              if (_selectedUsages[word.id] == null ||
                                  _selectedUsages[word.id]!.isEmpty) {
                                _selectedUsages[word.id] = {
                                  word.usages.first.id
                                };
                              }
                            });
                          },
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: word.word,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '  ${word.reading}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (word.jlptLevel != null)
                              _chip(word.jlptLevel!),
                            if (word.pitchAccent != null)
                              _chip(word.pitchAccent!),
                            if (selectedCount > 0)
                              _chip('$selectedCount selected',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                          ],
                        ),
                        trailing: Icon(isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onTap: () {
                          setState(() {
                            _expandedWordId =
                                isExpanded ? null : word.id;
                            if (!isExpanded &&
                                (_selectedUsages[word.id] == null ||
                                    _selectedUsages[word.id]!.isEmpty)) {
                              _selectedUsages[word.id] = {
                                word.usages.first.id
                              };
                            }
                          });
                        },
                      ),

                      // Expanded usages
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        ...word.usages.map((usage) {
                          final isSelected =
                              _selectedUsages[word.id]?.contains(usage.id) ??
                                  false;
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                _selectedUsages[word.id] ??= {};
                                if (checked == true) {
                                  _selectedUsages[word.id]!.add(usage.id);
                                } else {
                                  _selectedUsages[word.id]!
                                      .remove(usage.id);
                                }
                              });
                            },
                            title: Text(
                              '${usage.meaning}  '
                              '(${usage.partOfSpeech})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (usage.nuance != null)
                                  Text(
                                    usage.nuance!,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                if (usage.exampleSentence != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    usage.exampleSentence!,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  if (usage.exampleReading != null)
                                    Text(
                                      usage.exampleReading!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(150),
                                      ),
                                    ),
                                  if (usage.exampleTranslation != null)
                                    Text(
                                      usage.exampleTranslation!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(150),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                            controlAffinity:
                                ListTileControlAffinity.leading,
                          );
                        }),
                        // Etymology & fun fact
                        if (word.etymology != null ||
                            word.funFact != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (word.etymology != null)
                                  Text(
                                    '📖 ${word.etymology}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (word.funFact != null)
                                  Text(
                                    '💡 ${word.funFact}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateCard,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Card'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, {Color? color}) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color ??
              Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      );
}
