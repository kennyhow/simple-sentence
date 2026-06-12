import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_models.dart';

/// Generic LLM service — provider-agnostic, configured via settings.
class LlmService {
  final String apiUrl;
  final String apiKey;
  final String model;
  final http.Client _client;

  LlmService({
    required this.apiUrl,
    required this.apiKey,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Look up a word (kana or kanji) and return candidate words with usages.
  Future<LookupResult> lookupWord(LookupRequest request) async {
    final prompt = _buildLookupPrompt(request);
    final rawResponse = await _callApi(prompt);
    final candidates = _parseLookupResponse(rawResponse);
    return LookupResult(candidates: candidates, rawResponse: rawResponse);
  }

  /// Generate a full Anki card for a specific word + selected usages.
  Future<AnkiCard> generateCard({
    required CandidateWord word,
    required List<WordUsage> selectedUsages,
    String? extraNotes,
  }) async {
    final prompt = _buildCardPrompt(word, selectedUsages, extraNotes);
    final rawResponse = await _callApi(prompt);
    return _parseCardResponse(rawResponse, word, selectedUsages);
  }

  String _buildLookupPrompt(LookupRequest request) {
    final contextHint =
        request.context != null ? '\nContext/preference: ${request.context}' : '';
    return '''You are a Japanese language tutor. The user is learning Japanese (Japanese → English).

Given the input "$request.query", identify the most common Japanese words this could refer to.$contextHint

Return a JSON array of candidate words. For each word, include multiple common usages/meanings. Format:

[
  {
    "word": "食べる",
    "reading": "たべる",
    "jlpt_level": "N5",
    "pitch_accent": "たべる [2]",
    "etymology": "Originally from 賜ぶ (tabu, 'to receive humbly')...",
    "fun_fact": "The polite form 食べます is one of the first verbs taught...",
    "usages": [
      {
        "meaning": "to eat",
        "part_of_speech": "v1, transitive",
        "example_sentence": "毎日朝ごはんを食べる。",
        "example_reading": "まいにちあさごはんをたべる。",
        "example_translation": "I eat breakfast every day.",
        "nuance": "general, neutral"
      },
      {
        "meaning": "to live (metaphorical)",
        "part_of_speech": "v1, transitive",
        "example_sentence": "彼は音楽を食べて生きている。",
        "example_reading": "かれはおんがくをたべていきている。",
        "example_translation": "He lives on music (lit. eats music).",
        "nuance": "metaphorical, literary"
      }
    ]
  }
]

Rules:
- If the input is kana-only, include ALL common kanji forms (e.g. はし → 橋, 箸, 端)
- Include at least 2 usages per word if they exist
- Keep example sentences natural and level-appropriate
- Etymology and fun_fact are optional but appreciated
- Return ONLY valid JSON, no markdown wrapping, no explanation
- For kana-only queries, return at most 8 candidate words
- For kanji queries, return 1-3 candidate words with all their usages''';
  }

  String _buildCardPrompt(
      CandidateWord word, List<WordUsage> selectedUsages, String? extraNotes) {
    final usageDescriptions = selectedUsages
        .map((u) => '- ${u.meaning} (${u.partOfSpeech})${u.nuance != null ? " [${u.nuance}]" : ""}')
        .join('\n');

    return '''You are a Japanese language tutor creating an Anki flashcard.

Word: ${word.word} (${word.reading})
Selected usages:
$usageDescriptions
${extraNotes != null ? '\nUser notes: $extraNotes' : ''}

Create a flashcard with a simple, natural Japanese sentence that demonstrates the word's usage. Return JSON:

{
  "sentence": "自然な日本語の例文",
  "sentence_reading": "しぜんなにほんごのれいぶん",
  "sentence_translation": "A natural Japanese example sentence.",
  "tidbit": "An interesting fact, etymology note, or cultural context about this word."
}

Rules:
- The sentence should be short and natural (JLPT-appropriate)
- If multiple usages were selected, try to pick the most common one for the sentence
- tidbit can combine etymology, fun facts, and cultural notes
- Return ONLY valid JSON, no markdown wrapping''';
  }

  Future<String> _callApi(String prompt) async {
    // OpenAI-compatible chat completions API
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 4096,
    });

    final response = await _client.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw LlmException(
        'API returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw LlmException('No choices in API response');
    }

    return (choices[0]['message']['content'] as String).trim();
  }

  List<CandidateWord> _parseLookupResponse(String raw) {
    // Strip markdown code fences if present
    String jsonStr = raw.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceFirst(RegExp(r'^```\w*\n?'), '');
      jsonStr = jsonStr.replaceFirst(RegExp(r'\n?```$'), '');
    }

    final parsed = jsonDecode(jsonStr);
    if (parsed is List) {
      return parsed
          .map((e) => CandidateWord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw LlmException('Expected JSON array, got ${parsed.runtimeType}');
  }

  AnkiCard _parseCardResponse(
      String raw, CandidateWord word, List<WordUsage> selectedUsages) {
    String jsonStr = raw.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceFirst(RegExp(r'^```\w*\n?'), '');
      jsonStr = jsonStr.replaceFirst(RegExp(r'\n?```$'), '');
    }

    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final primaryUsage = selectedUsages.first;

    return AnkiCard(
      word: word.word,
      reading: word.reading,
      sentence: data['sentence'] as String,
      sentenceReading: data['sentence_reading'] as String,
      sentenceTranslation: data['sentence_translation'] as String,
      meaning: primaryUsage.meaning,
      partOfSpeech: primaryUsage.partOfSpeech,
      etymology: word.etymology,
      funFact: data['tidbit'] as String? ?? word.funFact,
      jlptLevel: word.jlptLevel,
      pitchAccent: word.pitchAccent,
      nuance: primaryUsage.nuance,
    );
  }

  void dispose() => _client.close();
}

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => 'LlmException: $message';
}
