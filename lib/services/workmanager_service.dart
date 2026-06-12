import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/card_models.dart';
import 'llm_service.dart';
import 'anki_service.dart';
import 'settings_service.dart';

/// Background task names registered with WorkManager.
const _taskLookupWord = 'lookup_word';
const _taskGenerateCard = 'generate_card';
const _taskRotateCards = 'rotate_cards';

/// Callback dispatcher — must be a top-level function.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final data = inputData ?? <String, dynamic>{};
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      if (!settings.isConfigured) {
        return false;
      }

      final llm = LlmService(
        apiUrl: settings.apiUrl,
        apiKey: settings.apiKey,
        model: settings.model,
      );

      switch (taskName) {
        case _taskLookupWord:
          return await _handleLookupWord(data, llm, prefs);
        case _taskGenerateCard:
          return await _handleGenerateCard(data, llm, prefs);
        case _taskRotateCards:
          return await _handleRotateCards(llm, prefs);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  });
}

Future<bool> _handleLookupWord(
  Map<String, dynamic> inputData,
  LlmService llm,
  SharedPreferences prefs,
) async {
  final query = inputData['query'] as String;
  final context = inputData['context'] as String?;
  final templateName = inputData['template_name'] as String?;

  final request = LookupRequest(
    query: query,
    context: context,
    templateName: templateName,
  );

  final result = await llm.lookupWord(request);

  // Store result for the UI to pick up
  final resultsJson = jsonEncode({
    'query': query,
    'candidates': result.candidates.map((c) => c.toJson()).toList(),
    'timestamp': DateTime.now().toIso8601String(),
  });
  await prefs.setString('last_lookup_result', resultsJson);

  // Notify
  await _showNotification(
    'Lookup complete',
    'Found ${result.candidates.length} candidates for "$query"',
  );

  return true;
}

Future<bool> _handleGenerateCard(
  Map<String, dynamic> inputData,
  LlmService llm,
  SharedPreferences prefs,
) async {
  final wordJson = inputData['word'] as String;
  final usagesJson = inputData['selected_usages'] as String;
  final extraNotes = inputData['extra_notes'] as String?;

  final word = CandidateWord.fromJson(jsonDecode(wordJson) as Map<String, dynamic>);
  final selectedUsages = (jsonDecode(usagesJson) as List<dynamic>)
      .map((u) => WordUsage.fromJson(u as Map<String, dynamic>))
      .toList();

  final card = await llm.generateCard(
    word: word,
    selectedUsages: selectedUsages,
    extraNotes: extraNotes,
  );

  // Push to AnkiDroid and get the card with note ID
  final anki = AnkiService();
  final pushedCard = await anki.addCard(card);

  // Store the card with its Anki note ID (for rotation tracking)
  final storedCard = pushedCard ?? card;
  final storedJson = jsonEncode(storedCard.toJson());
  await prefs.setString('last_generated_card', storedJson);

  // Add to history (with note ID if available)
  final history = prefs.getStringList('card_history') ?? [];
  history.insert(0, storedJson);
  if (history.length > 200) history.removeLast();
  await prefs.setStringList('card_history', history);

  await _showNotification(
    'Card ready${pushedCard != null ? " ✓" : ""}',
    '${card.word}: ${card.sentence}${pushedCard != null ? "" : " (AnkiDroid not available)"}',
  );

  return true;
}

/// Handle card rotation: scan history for cards due for rotation,
/// generate harder sentences, replace old cards in AnkiDroid.
Future<bool> _handleRotateCards(
  LlmService llm,
  SharedPreferences prefs,
) async {
  final history = prefs.getStringList('card_history') ?? [];
  final anki = AnkiService();

  var rotated = 0;
  final updatedHistory = <String>[];

  for (final raw in history) {
    final card = AnkiCard.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);

    if (card.isDueForRotation() && card.ankiNoteId != null) {
      final nextLevel = card.nextRotationLevel;
      if (nextLevel == null) {
        updatedHistory.add(raw);
        continue;
      }

      try {
        // Generate harder sentence
        final newCard = await llm.generateRotatedCard(
          originalCard: card,
          targetLevel: nextLevel,
        );

        // Delete old note from AnkiDroid
        await anki.deleteNote(card.ankiNoteId!);

        // Push new card
        final pushed = await anki.addCard(newCard);
        if (pushed != null) {
          updatedHistory.add(jsonEncode(pushed.toJson()));
          rotated++;
        } else {
          updatedHistory.add(raw);
        }
      } catch (_) {
        updatedHistory.add(raw);
      }
    } else {
      updatedHistory.add(raw);
    }
  }

  await prefs.setStringList('card_history', updatedHistory);

  if (rotated > 0) {
    await _showNotification(
      'Cards rotated',
      '$rotated card${rotated > 1 ? 's' : ''} upgraded to harder sentences',
    );
  }

  return true;
}

Future<void> _showNotification(String title, String body) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings =
      InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'simple_sentence_channel',
        'Simple Sentence',
        channelDescription: 'Card generation notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

/// Schedule the word lookup background task.
Future<void> scheduleLookupWord({
  required String query,
  String? context,
  String? templateName,
}) async {
  await Workmanager().registerOneOffTask(
    'lookup_${DateTime.now().millisecondsSinceEpoch}',
    _taskLookupWord,
    inputData: {
      'query': query,
      if (context != null) 'context': context,
      if (templateName != null) 'template_name': templateName,
    },
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.append,
  );
}

/// Schedule the card generation background task.
Future<void> scheduleGenerateCard({
  required CandidateWord word,
  required List<WordUsage> selectedUsages,
  String? extraNotes,
}) async {
  await Workmanager().registerOneOffTask(
    'card_${DateTime.now().millisecondsSinceEpoch}',
    _taskGenerateCard,
    inputData: {
      'word': jsonEncode(word.toJson()),
      'selected_usages': jsonEncode(selectedUsages.map((u) => u.toJson()).toList()),
      if (extraNotes != null) 'extra_notes': extraNotes,
    },
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.append,
  );
}

/// Schedule periodic card rotation check (every 6 hours).
Future<void> scheduleRotationCheck() async {
  await Workmanager().registerPeriodicTask(
    'rotation_check',
    _taskRotateCards,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}
