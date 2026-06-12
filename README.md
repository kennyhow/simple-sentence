# Simple Sentence

Japanese vocabulary mining → Anki flashcards via LLM. Type a word (or kana), pick from candidate meanings, and the app generates a full Anki card with a natural example sentence, etymology, and fun facts — all in the background.

## Features

- **Kana → Kanji lookup** — type `はし` and see 橋 (bridge), 箸 (chopsticks), 端 (edge)
- **Multiple usage selection** — each word has several meanings; pick only the ones you want to mine
- **Background LLM calls** — fire a lookup and close the app; WorkManager handles it
- **Auto-push to AnkiDroid** — cards land directly in your deck via AnkiDroid's API
- **6 prompt templates** — general, anime, business, casual, literary, news
- **Rich cards** — JLPT level, pitch accent, etymology, fun facts, nuance
- **History** — all generated cards saved locally for review
- **TTS on flip** — AnkiDroid card template auto-speaks the word and sentence (no API keys needed)

## Quick Start

### Prerequisites

- Flutter SDK 3.10+
- Android Studio (for Android SDK + emulator)
- AnkiDroid installed on your device
- An LLM API key (any OpenAI-compatible provider: OpenAI, DeepSeek, Anthropic, etc.)

### Setup

```bash
# Clone
git clone <repo-url> simple-sentence
cd simple-sentence

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### First Launch

1. Open **Settings** → paste your API URL, API key, and model name
2. In AnkiDroid, create the note type (see [ANKI_SETUP.md](ANKI_SETUP.md))
3. Type a Japanese word or kana → tap **Look Up**
4. Pick a word, check the usages you want → **Generate Card**
5. Preview → **Add to AnkiDroid**

## Architecture

```
lib/
├── main.dart                    # Entry point, Material 3, WorkManager init
├── models/
│   └── card_models.dart         # WordUsage, CandidateWord, AnkiCard
├── services/
│   ├── llm_service.dart         # OpenAI-compatible chat completions
│   ├── anki_service.dart        # AnkiDroid intent (ADD_NOTE)
│   ├── settings_service.dart    # SharedPreferences persistence
│   └── workmanager_service.dart # Background tasks + notifications
└── screens/
    ├── home_screen.dart         # Word input + template selector
    ├── candidates_screen.dart   # Pick word + select usages
    ├── card_preview_screen.dart # Preview before pushing to Anki
    ├── settings_screen.dart     # API + deck configuration
    └── history_screen.dart      # Past generated cards
```

## LLM Flow

```
User types "たべる"
       │
       ▼
┌─────────────────────────────┐
│ Phase 1: Word Lookup        │  (background task)
│ Returns candidate words     │
│ with multiple usages,       │
│ etymology, fun facts, JLPT  │
└─────────────────────────────┘
       │
       ▼  User picks word + usages
┌─────────────────────────────┐
│ Phase 2: Card Generation    │  (background task)
│ Creates a natural sentence, │
│ tidbit, pushes to AnkiDroid │
└─────────────────────────────┘
       │
       ▼
   Anki card ready ✓
```

## AnkiDroid Integration

Cards are pushed via `com.ichi2.anki.api.ADD_NOTE` intent. The note type must exist in AnkiDroid with these 8 fields (in order):

| # | Field | Example |
|---|-------|---------|
| 1 | Word | 食べる |
| 2 | Reading | たべる |
| 3 | Sentence | 毎日朝ごはんを食べる。 |
| 4 | Sentence Reading | まいにちあさごはんをたべる。 |
| 5 | Sentence Translation | I eat breakfast every day. |
| 6 | Meaning | to eat |
| 7 | Part of Speech | v1, transitive |
| 8 | Notes | Etymology: ... \| Fun fact: ... \| JLPT: N5 |

Full card template with TTS and styling → [ANKI_SETUP.md](ANKI_SETUP.md)

## Configuration

| Setting | Default | Notes |
|---------|---------|-------|
| API URL | `https://api.openai.com/v1/chat/completions` | Any OpenAI-compatible endpoint |
| API Key | (empty) | Stored in SharedPreferences |
| Model | `gpt-4o` | Model name your provider expects |
| Deck Name | `Japanese Mining` | Created automatically if missing |
| Note Type | `Japanese Sentence` | Must exist in AnkiDroid |

## License

MIT
