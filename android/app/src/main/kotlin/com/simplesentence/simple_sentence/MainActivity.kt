package com.simplesentence.simple_sentence

import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.simplesentence/anki_provider"
    private val ANKI_AUTHORITY = "com.ichi2.anki.flashcards"
    private val NOTES_URI = Uri.parse("content://$ANKI_AUTHORITY/notes")

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "findNoteId" -> {
                        val word = call.argument<String>("word") ?: ""
                        val sentence = call.argument<String>("sentence") ?: ""
                        findNoteId(word, sentence, result)
                    }
                    "deleteNote" -> {
                        val noteId = call.argument<Int>("noteId") ?: 0
                        deleteNote(noteId, result)
                    }
                    "isAvailable" -> {
                        result.success(isProviderAvailable())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun findNoteId(word: String, sentence: String, result: MethodChannel.Result) {
        try {
            // AnkiDroid content provider columns:
            // _id, GUID, MID (model id), MOD (modification time), USN, TAGS, FLDS, SFLD, CSUM, FLAGS, DATA
            // FLDS contains all field values separated by \x1f (unit separator)
            val cursor: Cursor? = contentResolver.query(
                NOTES_URI,
                arrayOf("_id", "FLDS"),
                null, null, null
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getLong(0)
                    val fields = it.getString(1) ?: ""
                    val fieldValues = fields.split("\u001f")

                    // Field 0 = Word, Field 2 = Sentence
                    if (fieldValues.size >= 3 &&
                        fieldValues[0] == word &&
                        fieldValues[2] == sentence) {
                        result.success(id.toInt())
                        return
                    }
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun deleteNote(noteId: Int, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse("$NOTES_URI/$noteId")
            val deleted = contentResolver.delete(uri, null, null)
            result.success(deleted > 0)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun isProviderAvailable(): Boolean {
        return try {
            val cursor = contentResolver.query(NOTES_URI, null, null, null, null)
            cursor?.close()
            true
        } catch (e: Exception) {
            false
        }
    }
}
