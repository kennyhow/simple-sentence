import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _deckController;
  late TextEditingController _ankiModelController;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController =
        TextEditingController(text: widget.settings.apiUrl);
    _apiKeyController =
        TextEditingController(text: widget.settings.apiKey);
    _modelController =
        TextEditingController(text: widget.settings.model);
    _deckController =
        TextEditingController(text: widget.settings.deckName);
    _ankiModelController =
        TextEditingController(text: widget.settings.ankiModelName);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _deckController.dispose();
    _ankiModelController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settings.apiUrl = _apiUrlController.text.trim();
    widget.settings.apiKey = _apiKeyController.text.trim();
    widget.settings.model = _modelController.text.trim();
    widget.settings.deckName = _deckController.text.trim();
    widget.settings.ankiModelName = _ankiModelController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- API Section ---
          _sectionHeader('LLM API'),
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API URL',
              hintText: 'https://api.openai.com/v1/chat/completions',
              border: OutlineInputBorder(),
              helperText:
                  'OpenAI-compatible chat completions endpoint',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: !_showKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    _showKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _showKey = !_showKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4o',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // --- Anki Section ---
          _sectionHeader('AnkiDroid'),
          TextField(
            controller: _deckController,
            decoration: const InputDecoration(
              labelText: 'Deck Name',
              hintText: 'Japanese Mining',
              border: OutlineInputBorder(),
              helperText:
                  'Deck will be created if it doesn\'t exist',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ankiModelController,
            decoration: const InputDecoration(
              labelText: 'Note Type (Model)',
              hintText: 'Japanese Sentence',
              border: OutlineInputBorder(),
              helperText:
                  'Must already exist in AnkiDroid with fields:\n'
                  'Word, Reading, Sentence, Sentence Reading,\n'
                  'Sentence Translation, Meaning, Part of Speech, Notes',
            ),
          ),
          const SizedBox(height: 24),

          // --- AnkiDroid Note Type Setup ---
          _sectionHeader('AnkiDroid Note Type Setup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create this note type in AnkiDroid first:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Open AnkiDroid → Manage note types'),
                  const Text('2. Add → name it "Japanese Sentence"'),
                  const Text(
                      '3. Add these fields (in order):'),
                  const SizedBox(height: 4),
                  const Text('   • Word'),
                  const Text('   • Reading'),
                  const Text('   • Sentence'),
                  const Text('   • Sentence Reading'),
                  const Text('   • Sentence Translation'),
                  const Text('   • Meaning'),
                  const Text('   • Part of Speech'),
                  const Text('   • Notes'),
                  const SizedBox(height: 8),
                  const Text(
                    '4. Design your cards using these fields',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
