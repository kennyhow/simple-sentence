import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/card_models.dart';
import 'anki_content_provider.dart';

/// Pushes cards to AnkiDroid via Android Intents + Content Provider.
///
/// AnkiDroid accepts cards via the com.ichi2.anki.api.ADD_NOTE action.
/// The note type (model) must already exist in AnkiDroid.
///
/// After adding a card, we query the content provider to get the note ID,
/// which enables rotation (delete old → push new) later.
class AnkiService {
  static const _actionAddNote = 'com.ichi2.anki.api.ADD_NOTE';
  static const _defaultDeckName = 'Japanese Mining';
  static const _defaultModelName = 'Japanese Sentence';

  final AnkiContentProvider _provider = AnkiContentProvider();

  /// Push a card to AnkiDroid and return the card with its Anki note ID set.
  ///
  /// [deckName] — which deck to add to (created if doesn't exist)
  /// [modelName] — which note type to use (must exist in AnkiDroid)
  /// [tags] — tags to attach (e.g. ["N5", "verb"])
  ///
  /// Returns the card with [ankiNoteId] populated if the content provider
  /// is available, or null if the push failed.
  Future<AnkiCard?> addCard(
    AnkiCard card, {
    String deckName = _defaultDeckName,
    String modelName = _defaultModelName,
    List<String>? tags,
  }) async {
    final allTags = <String>[
      if (card.jlptLevel != null) card.jlptLevel!,
      if (card.partOfSpeech.isNotEmpty) card.partOfSpeech,
      'rotation-l${card.rotationLevel}',
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

      // Wait a moment for AnkiDroid to write the note, then query its ID
      await Future.delayed(const Duration(milliseconds: 500));
      final noteId = await _provider.findNoteId(
        word: card.word,
        sentence: card.sentence,
      );

      return card.copyWith(ankiNoteId: noteId);
    } catch (e) {
      return null;
    }
  }

  /// Delete a note from AnkiDroid by its ID.
  Future<bool> deleteNote(int noteId) => _provider.deleteNote(noteId);

  /// Check if AnkiDroid is installed and its content provider is accessible.
  /// Does NOT launch any intents — uses the content provider check only.
  Future<bool> isAvailable() => _provider.isAvailable();

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
    notes.add('Rotation: Level ${card.rotationLevel}');

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
