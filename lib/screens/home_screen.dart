import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_models.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../services/workmanager_service.dart';
import '../widgets/bunny_mascot.dart';
import '../widgets/carrot_counter.dart';
import '../widgets/emoji_rain.dart';
import '../widgets/screen_shake.dart';
import '../widgets/streak_display.dart';
import 'candidates_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settings;
  final ValueChanged<ThemeMode>? onThemeChanged;

  const HomeScreen({super.key, required this.settings, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _queryController = TextEditingController();
  final _contextController = TextEditingController();
  String _selectedTemplate = 'general';
  bool _isLoading = false;
  String? _error;
  BunnyState _bunnyState = BunnyState.idle;
  String? _bunnySpeech;
  final GlobalKey<CarrotCounterState> _carrotKey = GlobalKey();
  final GlobalKey<EmojiRainOverlayState> _emojiRainKey = GlobalKey();
  final GlobalKey<ScreenShakeState> _shakeKey = GlobalKey();
  final GlobalKey<StreakDisplayState> _streakKey = GlobalKey();
  late StreakService _streakService;
  final _random = Random();
  Timer? _idleTimer;
  Timer? _streakPollTimer;
  static const _idleTimeout = Duration(seconds: 30);

  static const _bunnyPhrases = [
    'ふわふわ！',
    'ぴょんぴょん！',
    'おいしい！',
    'にんじん！',
    'がんばって！',
    'すごい！',
    'わくわく！',
    'えへへ〜',
    'だいすき！',
    'うさぎ！',
  ];

  @override
  void initState() {
    super.initState();
    _streakService = StreakService(widget.settings.prefs);
    _resetIdleTimer();
    _pollStreakUpdates();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _streakPollTimer?.cancel();
    _queryController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_bunnyState == BunnyState.sleeping) {
      _wakeUp();
    }
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted && _bunnyState == BunnyState.idle) {
        setState(() {
          _bunnyState = BunnyState.sleeping;
          _bunnySpeech = 'zzz...';
        });
      }
    });
  }

  void _wakeUp() {
    setState(() {
      _bunnyState = BunnyState.idle;
      _bunnySpeech = null;
    });
  }

  /// Poll for streak updates from background tasks.
  void _pollStreakUpdates() {
    _streakPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_streak_update');
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final milestone = data['milestone_reached'] as bool? ?? false;
      final extended = data['streak_extended'] as bool? ?? false;

      // Refresh the display
      if (mounted) setState(() {});

      // Handle streak events
      if (milestone) {
        final streak = data['current_streak'] as int? ?? 0;
        _streakKey.currentState?.celebrateMilestone(streak);
        _celebrate(message: '${streak} day streak! 🎉');
        // Clear the update so we don't re-trigger
        await prefs.remove('last_streak_update');
      } else if (extended) {
        _streakKey.currentState?.bump();
        await prefs.remove('last_streak_update');
      }
    });
  }

  void _onQueryChanged() {
    _resetIdleTimer();
    setState(() {
      if (_queryController.text.isNotEmpty) {
        _bunnyState = BunnyState.hop;
        _bunnySpeech = 'おっ！';
      } else {
        _bunnyState = BunnyState.idle;
        _bunnySpeech = null;
      }
    });
  }

  void _celebrate({String? message}) {
    _resetIdleTimer();
    setState(() {
      _bunnyState = BunnyState.celebrate;
      _bunnySpeech = message ?? 'やった！🎉';
    });
    _emojiRainKey.currentState?.trigger();
    _shakeKey.currentState?.shake();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _bunnyState = BunnyState.idle;
          _bunnySpeech = null;
        });
      }
    });
  }

  Future<void> _lookup() async {
    _resetIdleTimer();
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    if (!widget.settings.isConfigured) {
      setState(() => _error = 'Please configure API settings first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _bunnyState = BunnyState.hop;
      _bunnySpeech = 'Searching... 🐾';
    });

    try {
      final contextText = _contextController.text.trim();
      await scheduleLookupWord(
        query: query,
        context: contextText.isNotEmpty ? contextText : null,
        templateName: _selectedTemplate != 'general' ? _selectedTemplate : null,
      );

      await _waitForResult(query);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
        _bunnyState = BunnyState.idle;
        _bunnySpeech = 'Oops! 😢';
      });
    }
  }

  Future<void> _waitForResult(String query) async {
    final prefs = await SharedPreferences.getInstance();
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

          _celebrate(message: 'Found ${candidates.length}! 🎉');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CandidatesScreen(
                query: query,
                candidates: candidates,
                settings: widget.settings,
                onCardGenerated: () => _carrotKey.currentState?.addCarrot(),
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
      _bunnyState = BunnyState.idle;
      _bunnySpeech = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐰 '),
            Text('Simple Sentence'),
          ],
        ),
        actions: [
          StreakDisplay(
            key: _streakKey,
            streakService: _streakService,
            onMilestoneCelebrate: () {
              _emojiRainKey.currentState?.trigger();
              _shakeKey.currentState?.shake();
            },
            onMilestoneMessage: (msg) {
              _resetIdleTimer();
              setState(() {
                _bunnyState = BunnyState.celebrate;
                _bunnySpeech = msg;
              });
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) {
                  setState(() {
                    _bunnyState = BunnyState.idle;
                    _bunnySpeech = null;
                  });
                }
              });
            },
          ),
          const SizedBox(width: 8),
          CarrotCounter(key: _carrotKey),
          const SizedBox(width: 4),
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
                  builder: (_) => SettingsScreen(
                    settings: widget.settings,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: EmojiRainOverlay(
        key: _emojiRainKey,
        active: false,
        child: ScreenShake(
          shakeKey: _shakeKey,
          child: Column(
            children: [
              // Bunny mascot area
              SizedBox(
                height: 110,
                child: Center(
                  child: BunnyMascot(
                    state: _bunnyState,
                    size: 90,
                    speechBubble: _bunnySpeech,
                    onSecretTap: () => _celebrate(message: 'ひみつ！🎊'),
                    onTap: () {
                      _resetIdleTimer();
                      final phrase = _bunnyPhrases[_random.nextInt(_bunnyPhrases.length)];
                      setState(() {
                        _bunnyState = BunnyState.hop;
                        _bunnySpeech = phrase;
                      });
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _bunnyState = BunnyState.idle;
                            _bunnySpeech = null;
                          });
                        }
                      });
                    },
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
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
                          suffixIcon: _queryController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _queryController.clear();
                                    _onQueryChanged();
                                  },
                                )
                              : null,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _lookup(),
                        onChanged: (_) => _onQueryChanged(),
                      ),
                      const SizedBox(height: 12),

                      // Template selector
                      DropdownButtonFormField<String>(
                        value: _selectedTemplate,
                        decoration: const InputDecoration(
                          labelText: 'Template',
                        ),
                        items: SettingsService.templates.entries.map((e) {
                          final label =
                              e.key[0].toUpperCase() + e.key.substring(1);
                          return DropdownMenuItem(
                              value: e.key, child: Text(label));
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTemplate = v ?? 'general'),
                      ),
                      const SizedBox(height: 12),

                      // Context / extra notes
                      TextField(
                        controller: _contextController,
                        decoration: const InputDecoration(
                          labelText: 'Context (optional)',
                          hintText: 'e.g. from anime, business, casual...',
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('🔍', style: TextStyle(fontSize: 18)),
                          label: Text(
                              _isLoading ? 'Looking up...' : 'Look Up 🥕'),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
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
                                '🐰 Tips',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              _tip('Type kana (e.g. はし) to see all kanji forms.'),
                              _tip('Type kanji (e.g. 食べる) for detailed usages.'),
                              _tip('Add context for more relevant sentences.'),
                              _tip('Tap the bunny for a surprise! 🐰✨'),
                              _tip('Tap 10 times fast for a secret! 🤫'),
                              _tip('Mine daily to build your streak! 🔥'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🥕 '),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
