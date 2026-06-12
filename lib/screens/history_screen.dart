import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_models.dart';
import '../services/settings_service.dart';
import 'card_preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  final SettingsService settings;

  const HistoryScreen({super.key, required this.settings});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AnkiCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('card_history') ?? [];
    setState(() {
      _cards = raw
          .map((j) =>
              AnkiCard.fromJson(jsonDecode(j) as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
  }

  int get _dueCount => _cards.where((c) => c.isDueForRotation() && c.ankiNoteId != null).length;

  String _levelLabel(int level) {
    final config = RotationConfig.levels[level];
    return config?.label ?? 'L$level';
  }

  Color _levelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF8BC34A); // green — simple
      case 2:
        return const Color(0xFFFFA726); // orange — natural
      case 3:
        return const Color(0xFFEF5350); // red — authentic
      default:
        return Colors.grey;
    }
  }

  IconData _levelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.school_outlined;
      case 2:
        return Icons.chat_bubble_outline;
      case 3:
        return Icons.auto_stories;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _cards.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildCardList(theme),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: theme.colorScheme.onSurface.withAlpha(60),
                ),
                const SizedBox(height: 16),
                Text(
                  'No cards yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Generated cards will appear here.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.search),
                  label: const Text('Look up a word'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _cards.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(theme);

        final card = _cards[index - 1];
        final isDue = card.isDueForRotation() && card.ankiNoteId != null;
        final isMaxLevel = card.rotationLevel >= RotationConfig.maxLevel;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardPreviewScreen(
                    card: card,
                    settings: widget.settings,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Rotation level badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _levelColor(card.rotationLevel).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _levelColor(card.rotationLevel).withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _levelIcon(card.rotationLevel),
                          size: 18,
                          color: _levelColor(card.rotationLevel),
                        ),
                        Text(
                          _levelLabel(card.rotationLevel),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _levelColor(card.rotationLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Card content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              card.word,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              card.reading,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                            const Spacer(),
                            if (card.jlptLevel != null)
                              _chip(card.jlptLevel!, theme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.sentence,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatDate(card.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withAlpha(100),
                              ),
                            ),
                            if (card.ankiNoteId == null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: theme.colorScheme.error.withAlpha(150),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'not pushed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.error.withAlpha(150),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (isDue)
                              _chip('due ⏰', theme,
                                  bgColor: const Color(0xFFFFF3E0),
                                  textColor: const Color(0xFFE65100)),
                            if (isMaxLevel)
                              _chip('max ✓', theme,
                                  bgColor: const Color(0xFFE8F5E9),
                                  textColor: const Color(0xFF2E7D32)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Text(
            '${_cards.length} card${_cards.length == 1 ? '' : 's'}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const Spacer(),
          if (_dueCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text(
                '$_dueCount due for rotation',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, ThemeData theme, {Color? bgColor, Color? textColor}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor ?? theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
