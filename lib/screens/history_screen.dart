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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(60)),
                      const SizedBox(height: 16),
                      Text(
                        'No cards yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Generated cards will appear here.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            card.jlptLevel ?? '?',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(card.word),
                        subtitle: Text(
                          card.sentence,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatDate(card.createdAt),
                          style: const TextStyle(fontSize: 11),
                        ),
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
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
