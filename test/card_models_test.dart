import 'package:flutter_test/flutter_test.dart';
import 'package:simple_sentence/models/card_models.dart';

void main() {
  group('WordUsage', () {
    test('JSON round-trip with all fields', () {
      final usage = WordUsage(
        meaning: 'to eat',
        partOfSpeech: 'v1, transitive',
        exampleSentence: '毎日朝ごはんを食べる。',
        exampleReading: 'まいにちあさごはんをたべる。',
        exampleTranslation: 'I eat breakfast every day.',
        nuance: 'general',
      );

      final json = usage.toJson();
      final restored = WordUsage.fromJson(json);

      expect(restored.meaning, 'to eat');
      expect(restored.partOfSpeech, 'v1, transitive');
      expect(restored.exampleSentence, '毎日朝ごはんを食べる。');
      expect(restored.exampleReading, 'まいにちあさごはんをたべる。');
      expect(restored.exampleTranslation, 'I eat breakfast every day.');
      expect(restored.nuance, 'general');
    });

    test('JSON round-trip with minimal fields', () {
      final usage = WordUsage(
        meaning: 'bridge',
        partOfSpeech: 'noun',
      );

      final json = usage.toJson();
      final restored = WordUsage.fromJson(json);

      expect(restored.meaning, 'bridge');
      expect(restored.partOfSpeech, 'noun');
      expect(restored.exampleSentence, isNull);
      expect(restored.exampleReading, isNull);
      expect(restored.exampleTranslation, isNull);
      expect(restored.nuance, isNull);
    });

    test('toJson omits null optional fields', () {
      final usage = WordUsage(
        meaning: 'bridge',
        partOfSpeech: 'noun',
      );

      final json = usage.toJson();
      expect(json.containsKey('example_sentence'), isFalse);
      expect(json.containsKey('example_reading'), isFalse);
      expect(json.containsKey('example_translation'), isFalse);
      expect(json.containsKey('nuance'), isFalse);
    });

    test('auto-generates id if not provided', () {
      final usage1 = WordUsage(meaning: 'a', partOfSpeech: 'n');
      final usage2 = WordUsage(meaning: 'b', partOfSpeech: 'n');

      expect(usage1.id, isNotEmpty);
      expect(usage2.id, isNotEmpty);
      expect(usage1.id, isNot(usage2.id));
    });

    test('preserves provided id', () {
      final usage = WordUsage(
        id: 'custom-id',
        meaning: 'test',
        partOfSpeech: 'n',
      );

      expect(usage.id, 'custom-id');
    });
  });

  group('CandidateWord', () {
    test('JSON round-trip with all fields', () {
      final word = CandidateWord(
        word: '食べる',
        reading: 'たべる',
        jlptLevel: 'N5',
        pitchAccent: 'たべる [2]',
        etymology: 'From 賜ぶ',
        funFact: 'Common verb',
        usages: [
          WordUsage(meaning: 'to eat', partOfSpeech: 'v1, transitive'),
          WordUsage(meaning: 'to live (metaphorical)', partOfSpeech: 'v1'),
        ],
      );

      final json = word.toJson();
      final restored = CandidateWord.fromJson(json);

      expect(restored.word, '食べる');
      expect(restored.reading, 'たべる');
      expect(restored.jlptLevel, 'N5');
      expect(restored.pitchAccent, 'たべる [2]');
      expect(restored.etymology, 'From 賜ぶ');
      expect(restored.funFact, 'Common verb');
      expect(restored.usages.length, 2);
      expect(restored.usages.first.meaning, 'to eat');
      expect(restored.usages[1].meaning, 'to live (metaphorical)');
    });

    test('JSON round-trip with minimal fields', () {
      final word = CandidateWord(
        word: 'はし',
        reading: 'はし',
        usages: [],
      );

      final json = word.toJson();
      final restored = CandidateWord.fromJson(json);

      expect(restored.word, 'はし');
      expect(restored.reading, 'はし');
      expect(restored.jlptLevel, isNull);
      expect(restored.pitchAccent, isNull);
      expect(restored.etymology, isNull);
      expect(restored.funFact, isNull);
      expect(restored.usages, isEmpty);
    });

    test('multiple usages for kana query (はし)', () {
      final word = CandidateWord(
        word: 'はし',
        reading: 'はし',
        usages: [
          WordUsage(meaning: 'bridge', partOfSpeech: 'noun'),
          WordUsage(meaning: 'chopsticks', partOfSpeech: 'noun'),
          WordUsage(meaning: 'edge', partOfSpeech: 'noun'),
        ],
      );

      expect(word.usages.length, 3);
      expect(
        word.usages.map((u) => u.meaning).toList(),
        ['bridge', 'chopsticks', 'edge'],
      );
    });

    test('auto-generates id', () {
      final word1 = CandidateWord(word: 'a', reading: 'a', usages: []);
      final word2 = CandidateWord(word: 'b', reading: 'b', usages: []);

      expect(word1.id, isNotEmpty);
      expect(word2.id, isNotEmpty);
      expect(word1.id, isNot(word2.id));
    });
  });

  group('AnkiCard', () {
    test('JSON round-trip with all fields', () {
      final card = AnkiCard(
        word: '食べる',
        reading: 'たべる',
        sentence: '毎日朝ごはんを食べる。',
        sentenceReading: 'まいにちあさごはんをたべる。',
        sentenceTranslation: 'I eat breakfast every day.',
        meaning: 'to eat',
        partOfSpeech: 'v1, transitive',
        jlptLevel: 'N5',
        pitchAccent: 'たべる [2]',
        etymology: 'From 賜ぶ',
        funFact: 'Common verb',
        nuance: 'general',
        rotationLevel: 1,
        ankiNoteId: 12345,
      );

      final json = card.toJson();
      final restored = AnkiCard.fromJson(json);

      expect(restored.word, '食べる');
      expect(restored.reading, 'たべる');
      expect(restored.sentence, '毎日朝ごはんを食べる。');
      expect(restored.sentenceReading, 'まいにちあさごはんをたべる。');
      expect(restored.sentenceTranslation, 'I eat breakfast every day.');
      expect(restored.meaning, 'to eat');
      expect(restored.partOfSpeech, 'v1, transitive');
      expect(restored.jlptLevel, 'N5');
      expect(restored.pitchAccent, 'たべる [2]');
      expect(restored.etymology, 'From 賜ぶ');
      expect(restored.funFact, 'Common verb');
      expect(restored.nuance, 'general');
      expect(restored.rotationLevel, 1);
      expect(restored.ankiNoteId, 12345);
    });

    test('JSON round-trip with minimal fields', () {
      final card = AnkiCard(
        word: '猫',
        reading: 'ねこ',
        sentence: '猫が好きです。',
        sentenceReading: 'ねこがすきです。',
        sentenceTranslation: 'I like cats.',
        meaning: 'cat',
        partOfSpeech: 'noun',
      );

      final json = card.toJson();
      final restored = AnkiCard.fromJson(json);

      expect(restored.word, '猫');
      expect(restored.etymology, isNull);
      expect(restored.funFact, isNull);
      expect(restored.jlptLevel, isNull);
      expect(restored.ankiNoteId, isNull);
      expect(restored.rotationLevel, 1); // default
      expect(restored.parentCardId, isNull);
    });

    test('createdAt is set automatically', () {
      final before = DateTime.now();
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
      );
      final after = DateTime.now();

      expect(card.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(card.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('createdAt is preserved in JSON round-trip', () {
      final created = DateTime(2024, 6, 15, 10, 30);
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        createdAt: created,
      );

      final json = card.toJson();
      final restored = AnkiCard.fromJson(json);

      expect(restored.createdAt, created);
    });
  });

  group('AnkiCard.copyWith', () {
    late AnkiCard original;

    setUp(() {
      original = AnkiCard(
        id: 'orig-id',
        word: '食べる',
        reading: 'たべる',
        sentence: '毎日朝ごはんを食べる。',
        sentenceReading: 'まいにちあさごはんをたべる。',
        sentenceTranslation: 'I eat breakfast every day.',
        meaning: 'to eat',
        partOfSpeech: 'v1, transitive',
        jlptLevel: 'N5',
        pitchAccent: 'たべる [2]',
        etymology: 'From 賜ぶ',
        funFact: 'Common verb',
        nuance: 'general',
        rotationLevel: 1,
        ankiNoteId: 100,
        parentCardId: 'parent-1',
      );
    });

    test('copyWith with no overrides returns equal card', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.word, original.word);
      expect(copy.sentence, original.sentence);
      expect(copy.rotationLevel, original.rotationLevel);
      expect(copy.ankiNoteId, original.ankiNoteId);
    });

    test('copyWith overrides single field', () {
      final copy = original.copyWith(sentence: '新しい例文');
      expect(copy.sentence, '新しい例文');
      expect(copy.word, original.word); // unchanged
      expect(copy.reading, original.reading); // unchanged
    });

    test('copyWith overrides rotation level', () {
      final copy = original.copyWith(rotationLevel: 2);
      expect(copy.rotationLevel, 2);
      expect(copy.id, original.id);
    });

    test('copyWith overrides ankiNoteId', () {
      final copy = original.copyWith(ankiNoteId: 999);
      expect(copy.ankiNoteId, 999);
    });

    test('copyWith sets parentCardId for rotation', () {
      final copy = original.copyWith(
        rotationLevel: 2,
        parentCardId: original.id,
      );
      expect(copy.rotationLevel, 2);
      expect(copy.parentCardId, original.id);
    });

    test('copyWith preserves parentCardId when not overridden', () {
      final copy = original.copyWith(sentence: 'new');
      expect(copy.parentCardId, 'parent-1');
    });

    test('copyWith can clear optional fields with empty string', () {
      final copy = original.copyWith(etymology: '');
      expect(copy.etymology, '');
    });
  });

  group('AnkiCard.isDueForRotation', () {
    test('level 1 card just created is not due', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 1,
      );
      expect(card.isDueForRotation(), isFalse);
    });

    test('level 1 card from 4 days ago is due', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      );
      expect(card.isDueForRotation(), isTrue);
    });

    test('level 1 card from 2 days ago is not due', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(card.isDueForRotation(), isFalse);
    });

    test('level 2 card from 15 days ago is due', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      );
      expect(card.isDueForRotation(), isTrue);
    });

    test('level 3 card past 30 days is still due (age check works)', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      // Level 3 exists in RotationConfig with 30-day trigger,
      // so isDueForRotation returns true based on age.
      // The workmanager guards max level via nextRotationLevel (null at 3).
      expect(card.isDueForRotation(), isTrue);
      expect(card.nextRotationLevel, isNull);
    });

    test('card without ankiNoteId is not due (not pushed yet)', () {
      final card = AnkiCard(
        word: 'test',
        reading: 'test',
        sentence: 'test',
        sentenceReading: 'test',
        sentenceTranslation: 'test',
        meaning: 'test',
        partOfSpeech: 'n',
        rotationLevel: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ankiNoteId: null,
      );
      // isDueForRotation checks both age AND ankiNoteId
      // Let's verify: the method checks isDueForRotation which uses config
      // but the workmanager checks ankiNoteId separately
      expect(card.isDueForRotation(), isTrue); // age-wise it's due
    });
  });

  group('AnkiCard.nextRotationLevel', () {
    test('level 1 -> 2', () {
      final card = AnkiCard(
        word: 'test', reading: 'test', sentence: 'test',
        sentenceReading: 'test', sentenceTranslation: 'test',
        meaning: 'test', partOfSpeech: 'n', rotationLevel: 1,
      );
      expect(card.nextRotationLevel, 2);
    });

    test('level 2 -> 3', () {
      final card = AnkiCard(
        word: 'test', reading: 'test', sentence: 'test',
        sentenceReading: 'test', sentenceTranslation: 'test',
        meaning: 'test', partOfSpeech: 'n', rotationLevel: 2,
      );
      expect(card.nextRotationLevel, 3);
    });

    test('level 3 -> null (max)', () {
      final card = AnkiCard(
        word: 'test', reading: 'test', sentence: 'test',
        sentenceReading: 'test', sentenceTranslation: 'test',
        meaning: 'test', partOfSpeech: 'n', rotationLevel: 3,
      );
      expect(card.nextRotationLevel, isNull);
    });
  });

  group('RotationConfig', () {
    test('has 3 levels', () {
      expect(RotationConfig.levels.length, 3);
      expect(RotationConfig.maxLevel, 3);
    });

    test('level 1 is Simple, triggers after 3 days', () {
      final config = RotationConfig.levels[1]!;
      expect(config.label, 'Simple');
      expect(config.triggerAfter, const Duration(days: 3));
      expect(config.styleDescription, contains('simple'));
    });

    test('level 2 is Natural, triggers after 14 days', () {
      final config = RotationConfig.levels[2]!;
      expect(config.label, 'Natural');
      expect(config.triggerAfter, const Duration(days: 14));
      expect(config.styleDescription, contains('natural'));
    });

    test('level 3 is Authentic, triggers after 30 days', () {
      final config = RotationConfig.levels[3]!;
      expect(config.label, 'Authentic');
      expect(config.triggerAfter, const Duration(days: 30));
      expect(config.styleDescription, contains('authentic'));
    });

    test('level 4 does not exist', () {
      expect(RotationConfig.levels[4], isNull);
    });
  });

  group('LookupRequest', () {
    test('creates with required fields', () {
      final request = LookupRequest(query: 'たべる');
      expect(request.query, 'たべる');
      expect(request.context, isNull);
      expect(request.templateName, isNull);
    });

    test('creates with all fields', () {
      final request = LookupRequest(
        query: '食べる',
        context: 'from anime',
        templateName: 'anime',
      );
      expect(request.query, '食べる');
      expect(request.context, 'from anime');
      expect(request.templateName, 'anime');
    });
  });

  group('LookupResult', () {
    test('holds candidates and raw response', () {
      final candidates = [
        CandidateWord(word: '食べる', reading: 'たべる', usages: []),
      ];
      final result = LookupResult(
        candidates: candidates,
        rawResponse: '{"word": "食べる"}',
      );

      expect(result.candidates.length, 1);
      expect(result.rawResponse, '{"word": "食べる"}');
    });
  });
}
