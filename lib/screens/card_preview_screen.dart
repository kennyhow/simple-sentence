import 'package:flutter/material.dart';
import '../models/card_models.dart';
import '../services/anki_service.dart';
import '../services/settings_service.dart';

/// Preview the generated card before pushing to AnkiDroid.
class CardPreviewScreen extends StatefulWidget {
  final AnkiCard card;
  final SettingsService settings;

  const CardPreviewScreen({
    super.key,
    required this.card,
    required this.settings,
  });

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  bool _pushed = false;
  bool _pushing = false;
  String? _error;

  Future<void> _pushToAnki() async {
    setState(() {
      _pushing = true;
      _error = null;
    });

    final anki = AnkiService();
    final pushedCard = await anki.addCard(
      widget.card,
      deckName: widget.settings.deckName,
      modelName: widget.settings.ankiModelName,
    );

    setState(() {
      _pushing = false;
      _pushed = pushedCard != null;
      if (pushedCard == null) {
        _error = 'AnkiDroid not available. Is it installed?';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Front of card
            _section(
              'Front',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.word,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.reading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.sentence,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    card.sentenceReading,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rotation info
            _section(
              'Sentence Difficulty',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Level', '${card.rotationLevel} — ${_levelLabel(card.rotationLevel)}'),
                  if (card.nextRotationLevel != null)
                    _field('Next rotation',
                        'Level ${card.nextRotationLevel} (${_levelLabel(card.nextRotationLevel!)}) '
                        'in ~${_daysUntilRotation(card)}'),
                  if (card.rotationLevel >= RotationConfig.maxLevel)
                    const Text(
                      '✓ Max difficulty reached',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Back of card
            _section(
              'Back',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Meaning', card.meaning),
                  _field('Part of Speech', card.partOfSpeech),
                  _field('Sentence Translation', card.sentenceTranslation),
                  if (card.nuance != null) _field('Nuance', card.nuance!),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Extra info
            if (card.etymology != null ||
                card.funFact != null ||
                card.jlptLevel != null ||
                card.pitchAccent != null)
              _section(
                'Extra Info',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.jlptLevel != null)
                      _field('JLPT Level', card.jlptLevel!),
                    if (card.pitchAccent != null)
                      _field('Pitch Accent', card.pitchAccent!),
                    if (card.etymology != null)
                      _field('Etymology', card.etymology!),
                    if (card.funFact != null)
                      _field('Fun Fact', card.funFact!),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            if (_pushed)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Added to AnkiDroid!',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _pushing ? null : _pushToAnki,
                  icon: _pushing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_pushing
                      ? 'Adding...'
                      : 'Add to AnkiDroid'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            const SizedBox(height: 8),

            // Done / new lookup
            OutlinedButton.icon(
              onPressed: () {
                // Pop back to home
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('New Lookup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(150),
                ),
              ),
            ),
            Expanded(
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );

  String _levelLabel(int level) {
    final config = RotationConfig.levels[level];
    return config?.label ?? 'Unknown';
  }

  String _daysUntilRotation(AnkiCard card) {
    final config = RotationConfig.levels[card.rotationLevel];
    if (config == null) return 'N/A';
    final elapsed = DateTime.now().difference(card.createdAt);
    final remaining = config.triggerAfter - elapsed;
    if (remaining.isNegative) return 'now';
    if (remaining.inDays > 0) return '${remaining.inDays}d';
    return '${remaining.inHours}h';
  }
}
