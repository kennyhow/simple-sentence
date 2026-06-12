import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A single usage/meaning for a candidate word.
class WordUsage {
  final String id;
  final String meaning;        // e.g. "to eat"
  final String partOfSpeech;   // e.g. "v1, transitive"
  final String? exampleSentence;
  final String? exampleReading;
  final String? exampleTranslation;
  final String? nuance;        // e.g. "casual", "humble form"

  WordUsage({
    String? id,
    required this.meaning,
    required this.partOfSpeech,
    this.exampleSentence,
    this.exampleReading,
    this.exampleTranslation,
    this.nuance,
  }) : id = id ?? _uuid.v4();

  factory WordUsage.fromJson(Map<String, dynamic> json) => WordUsage(
        id: json['id'] as String?,
        meaning: json['meaning'] as String,
        partOfSpeech: json['part_of_speech'] as String? ?? '',
        exampleSentence: json['example_sentence'] as String?,
        exampleReading: json['example_reading'] as String?,
        exampleTranslation: json['example_translation'] as String?,
        nuance: json['nuance'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meaning': meaning,
        'part_of_speech': partOfSpeech,
        if (exampleSentence != null) 'example_sentence': exampleSentence,
        if (exampleReading != null) 'example_reading': exampleReading,
        if (exampleTranslation != null)
          'example_translation': exampleTranslation,
        if (nuance != null) 'nuance': nuance,
      };
}

/// A candidate word returned by the LLM lookup.
class CandidateWord {
  final String id;
  final String word;           // kanji form, e.g. 食べる
  final String reading;        // kana reading, e.g. たべる
  final List<WordUsage> usages;
  final String? jlptLevel;     // e.g. "N5"
  final String? pitchAccent;   // e.g. "たべる [2]"
  final String? etymology;
  final String? funFact;

  CandidateWord({
    String? id,
    required this.word,
    required this.reading,
    required this.usages,
    this.jlptLevel,
    this.pitchAccent,
    this.etymology,
    this.funFact,
  }) : id = id ?? _uuid.v4();

  factory CandidateWord.fromJson(Map<String, dynamic> json) => CandidateWord(
        id: json['id'] as String?,
        word: json['word'] as String,
        reading: json['reading'] as String,
        usages: (json['usages'] as List<dynamic>)
            .map((u) => WordUsage.fromJson(u as Map<String, dynamic>))
            .toList(),
        jlptLevel: json['jlpt_level'] as String?,
        pitchAccent: json['pitch_accent'] as String?,
        etymology: json['etymology'] as String?,
        funFact: json['fun_fact'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'reading': reading,
        'usages': usages.map((u) => u.toJson()).toList(),
        if (jlptLevel != null) 'jlpt_level': jlptLevel,
        if (pitchAccent != null) 'pitch_accent': pitchAccent,
        if (etymology != null) 'etymology': etymology,
        if (funFact != null) 'fun_fact': funFact,
      };
}

/// A finalized Anki card, ready to be pushed.
class AnkiCard {
  final String id;
  final String word;
  final String reading;
  final String sentence;
  final String sentenceReading;
  final String sentenceTranslation;
  final String meaning;
  final String partOfSpeech;
  final String? etymology;
  final String? funFact;
  final String? jlptLevel;
  final String? pitchAccent;
  final String? nuance;
  final DateTime createdAt;

  /// AnkiDroid note ID (from content provider), used for rotation/deletion.
  final int? ankiNoteId;

  /// Rotation level: 1 = simple, 2 = natural, 3 = authentic.
  final int rotationLevel;

  /// Links rotated cards to their original (null for original cards).
  final String? parentCardId;

  AnkiCard({
    String? id,
    required this.word,
    required this.reading,
    required this.sentence,
    required this.sentenceReading,
    required this.sentenceTranslation,
    required this.meaning,
    required this.partOfSpeech,
    this.etymology,
    this.funFact,
    this.jlptLevel,
    this.pitchAccent,
    this.nuance,
    DateTime? createdAt,
    this.ankiNoteId,
    this.rotationLevel = 1,
    this.parentCardId,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  factory AnkiCard.fromJson(Map<String, dynamic> json) => AnkiCard(
        id: json['id'] as String?,
        word: json['word'] as String,
        reading: json['reading'] as String,
        sentence: json['sentence'] as String,
        sentenceReading: json['sentence_reading'] as String,
        sentenceTranslation: json['sentence_translation'] as String,
        meaning: json['meaning'] as String,
        partOfSpeech: json['part_of_speech'] as String,
        etymology: json['etymology'] as String?,
        funFact: json['fun_fact'] as String?,
        jlptLevel: json['jlpt_level'] as String?,
        pitchAccent: json['pitch_accent'] as String?,
        nuance: json['nuance'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        ankiNoteId: json['anki_note_id'] as int?,
        rotationLevel: json['rotation_level'] as int? ?? 1,
        parentCardId: json['parent_card_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'reading': reading,
        'sentence': sentence,
        'sentence_reading': sentenceReading,
        'sentence_translation': sentenceTranslation,
        'meaning': meaning,
        'part_of_speech': partOfSpeech,
        if (etymology != null) 'etymology': etymology,
        if (funFact != null) 'fun_fact': funFact,
        if (jlptLevel != null) 'jlpt_level': jlptLevel,
        if (pitchAccent != null) 'pitch_accent': pitchAccent,
        if (nuance != null) 'nuance': nuance,
        'created_at': createdAt.toIso8601String(),
        if (ankiNoteId != null) 'anki_note_id': ankiNoteId,
        'rotation_level': rotationLevel,
        if (parentCardId != null) 'parent_card_id': parentCardId,
      };

  /// Whether this card is due for rotation to the next level.
  bool isDueForRotation() {
    final config = RotationConfig.levels[rotationLevel];
    if (config == null) return false; // max level reached
    final age = DateTime.now().difference(createdAt);
    return age >= config.triggerAfter;
  }

  /// The next rotation level, or null if already at max.
  int? get nextRotationLevel =>
      rotationLevel < RotationConfig.levels.length ? rotationLevel + 1 : null;
}

/// Configuration for sentence rotation difficulty progression.
class RotationConfig {
  static const Map<int, LevelConfig> levels = {
    1: LevelConfig(
      label: 'Simple',
      triggerAfter: Duration(days: 3),
      styleDescription: 'short, simple, textbook-clear',
    ),
    2: LevelConfig(
      label: 'Natural',
      triggerAfter: Duration(days: 14),
      styleDescription: 'natural, slightly longer, colloquial, conversational',
    ),
    3: LevelConfig(
      label: 'Authentic',
      triggerAfter: Duration(days: 30),
      styleDescription:
          'authentic — news excerpts, literature, or conversation with idioms and natural phrasing',
    ),
  };

  /// Total number of rotation levels (including level 1).
  static int get maxLevel => levels.length;
}

class LevelConfig {
  final String label;
  final Duration triggerAfter;
  final String styleDescription;

  const LevelConfig({
    required this.label,
    required this.triggerAfter,
    required this.styleDescription,
  });
}

/// Input to the LLM lookup.
class LookupRequest {
  final String query;          // kana or kanji
  final String? context;       // optional: "from anime", "business", etc.
  final String? templateName;  // which prompt template to use

  LookupRequest({
    required this.query,
    this.context,
    this.templateName,
  });
}

/// Result of a lookup — a list of candidate words.
class LookupResult {
  final List<CandidateWord> candidates;
  final String rawResponse;

  LookupResult({
    required this.candidates,
    required this.rawResponse,
  });
}
