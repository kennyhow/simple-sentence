import 'package:flutter/services.dart';

/// Low-level AnkiDroid content provider access via platform channel.
///
/// AnkiDroid exposes a content provider at:
///   content://com.ichi2.anki.flashcards/notes
///
/// This class wraps query and delete operations that aren't possible
/// via the intent-based API alone.
class AnkiContentProvider {
  static const _channel = MethodChannel('com.simplesentence/anki_provider');

  /// Query AnkiDroid for a note by word + sentence fields.
  /// Returns the note ID if found, null otherwise.
  Future<int?> findNoteId({
    required String word,
    required String sentence,
  }) async {
    try {
      final result = await _channel.invokeMethod<int>('findNoteId', {
        'word': word,
        'sentence': sentence,
      });
      return result;
    } on MissingPluginException {
      return null; // Not on Android
    } catch (e) {
      return null;
    }
  }

  /// Delete a note from AnkiDroid by its ID.
  /// Returns true if successful.
  Future<bool> deleteNote(int noteId) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteNote', {
        'noteId': noteId,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if the content provider is accessible.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
