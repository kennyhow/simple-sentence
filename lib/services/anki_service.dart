import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/card_models.dart';

/// Pushes cards to AnkiDroid via Android Intents.
///
/// AnkiDroid accepts cards via the com.ichi2.anki.api.ADD_NOTE action.
/// The note type (model) must already exist in AnkiDroid.
class AnkiService {
  static const _actionAddNote = 'com.ichi2.anki.api.ADD_NOTE';
  static const _defaultDeckName = 'Japanese Mining';
  static const _defaultModelName = 'Japanese Sentence';

  /// Push a card to AnkiDroid.
  ///
  /// [deckName] — which deck to add to (created if doesn't exist)
  /// [modelName] — which note type to use (must exist in AnkiDroid)
  /// [tags] — tags to attach (e.g. ["N5", "verb"])
  ///
  /// Returns true if the intent was sent successfully.
  Future<bool> addCard(
    AnkiCard card, {
    String deckName = _defaultDeckName,
    String modelName = _defaultModelName,
    List<String>? tags,
  }) async {
    final allTags = <String>[
      if (card.jlptLevel != null) card.jlptLevel!,
      if (card.partOfSpeech.isNotEmpty) card.partOfSpeech,
      ...?tags,
    ];

    final fields = _buildFields(card);

    final intent = AndroidIntent(
      action: _actionAddNote,
      arguments: {
        'deckName': deckName,
        'modelName': modelName,
        'fields': fields,
        'tags': allTags,
      },
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
      return true;
    } catch (e) {
      // AnkiDroid not installed or API not available
      return false;
    }
  }

  /// Check if AnkiDroid is installed and its API is available.
  Future<bool> isAvailable() async {
    try {
      final intent = AndroidIntent(
        action: 'com.ichi2.anki.api.ADD_NOTE',
        arguments: {'deckName': '__test__', 'modelName': '__test__', 'fields': ['', '', '', '', '', '', '', '']},
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Build the fields array matching the "Japanese Sentence" note type.
  ///
  /// Expected fields (customize to match your AnkiDroid note type):
  ///   0: Word (kanji)
  ///   1: Reading (kana)
  ///   2: Sentence
  ///   3: Sentence Reading
  ///   4: Sentence Translation
  ///   5: Meaning
  ///   6: Part of Speech
  ///   7: Notes (etymology, fun facts, JLPT, pitch accent, nuance)
  List<String> _buildFields(AnkiCard card) {
    final notes = <String>[];
    if (card.etymology != null && card.etymology!.isNotEmpty) {
      notes.add('Etymology: ${card.etymology}');
    }
    if (card.funFact != null && card.funFact!.isNotEmpty) {
      notes.add('Fun fact: ${card.funFact}');
    }
    if (card.jlptLevel != null) {
      notes.add('JLPT: ${card.jlptLevel}');
    }
    if (card.pitchAccent != null) {
      notes.add('Pitch: ${card.pitchAccent}');
    }
    if (card.nuance != null) {
      notes.add('Nuance: ${card.nuance}');
    }

    return [
      card.word,
      card.reading,
      card.sentence,
      card.sentenceReading,
      card.sentenceTranslation,
      card.meaning,
      card.partOfSpeech,
      notes.join(' | '),
    ];
  }
}
