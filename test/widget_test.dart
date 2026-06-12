import 'package:flutter_test/flutter_test.dart';

import 'package:simple_sentence/models/card_models.dart';

void main() {
  group('Card models', () {
    test('WordUsage JSON round-trip', () {
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

    test('CandidateWord JSON round-trip', () {
      final word = CandidateWord(
        word: '食べる',
        reading: 'たべる',
        jlptLevel: 'N5',
        pitchAccent: 'たべる [2]',
        etymology: 'From 賜ぶ',
        funFact: 'Common verb',
        usages: [
          WordUsage(
            meaning: 'to eat',
            partOfSpeech: 'v1, transitive',
          ),
        ],
      );

      final json = word.toJson();
      final restored = CandidateWord.fromJson(json);

      expect(restored.word, '食べる');
      expect(restored.reading, 'たべる');
      expect(restored.jlptLevel, 'N5');
      expect(restored.pitchAccent, 'たべる [2]');
      expect(restored.usages.length, 1);
      expect(restored.usages.first.meaning, 'to eat');
    });

    test('AnkiCard JSON round-trip', () {
      final card = AnkiCard(
        word: '食べる',
        reading: 'たべる',
        sentence: '毎日朝ごはんを食べる。',
        sentenceReading: 'まいにちあさごはんをたべる。',
        sentenceTranslation: 'I eat breakfast every day.',
        meaning: 'to eat',
        partOfSpeech: 'v1, transitive',
        jlptLevel: 'N5',
        etymology: 'From 賜ぶ',
      );

      final json = card.toJson();
      final restored = AnkiCard.fromJson(json);

      expect(restored.word, '食べる');
      expect(restored.sentence, '毎日朝ごはんを食べる。');
      expect(restored.jlptLevel, 'N5');
      expect(restored.etymology, 'From 賜ぶ');
    });

    test('CandidateWord with multiple usages', () {
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
      expect(word.usages.map((u) => u.meaning).toList(),
          ['bridge', 'chopsticks', 'edge']);
    });
  });
}
