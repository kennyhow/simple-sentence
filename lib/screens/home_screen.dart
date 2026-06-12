import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_models.dart';
import '../services/settings_service.dart';
import '../services/workmanager_service.dart';
import 'candidates_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settings;

  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _queryController = TextEditingController();
  final _contextController = TextEditingController();
  String _selectedTemplate = 'general';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    if (!widget.settings.isConfigured) {
      setState(() => _error = 'Please configure API settings first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contextText = _contextController.text.trim();
      await scheduleLookupWord(
        query: query,
        context: contextText.isNotEmpty ? contextText : null,
        templateName: _selectedTemplate != 'general' ? _selectedTemplate : null,
      );

      // Poll for result (in a real app, use a stream/notification tap)
      // For now, we wait and check SharedPreferences
      await _waitForResult(query);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _waitForResult(String query) async {
    final prefs = await SharedPreferences.getInstance();
    // Poll for up to 60 seconds
    for (var i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final raw = prefs.getString('last_lookup_result');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['query'] == query) {
          if (!mounted) return;
          final candidates = (data['candidates'] as List<dynamic>)
              .map((c) => CandidateWord.fromJson(c as Map<String, dynamic>))
              .toList();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CandidatesScreen(
                query: query,
                candidates: candidates,
                settings: widget.settings,
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
    }
    setState(() {
      _isLoading = false;
      _error = 'Timed out waiting for result. Check notification tray.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Sentence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(settings: widget.settings),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(settings: widget.settings),
                ),
              );
              setState(() {}); // refresh in case settings changed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Query input
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Word or kana',
                hintText: 'e.g. 食べる or たべる',
                border: const OutlineInputBorder(),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _queryController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _lookup(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Template selector
            DropdownButtonFormField<String>(
              initialValue: _selectedTemplate,
              decoration: const InputDecoration(
                labelText: 'Template',
                border: OutlineInputBorder(),
              ),
              items: SettingsService.templates.entries.map((e) {
                final label = e.key[0].toUpperCase() + e.key.substring(1);
                return DropdownMenuItem(value: e.key, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _selectedTemplate = v ?? 'general'),
            ),
            const SizedBox(height: 12),

            // Context / extra notes
            TextField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: 'Context (optional)',
                hintText: 'e.g. from anime, business, casual...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Lookup button
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _lookup,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Looking up...' : 'Look Up'),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Tips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _tip('Type kana (e.g. はし) to see all possible kanji forms.'),
                    _tip('Type kanji (e.g. 食べる) to get detailed usages.'),
                    _tip('Add context to get more relevant example sentences.'),
                    _tip('The lookup runs in the background — you can close the app.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
