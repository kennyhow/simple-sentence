# Simple Sentence — AnkiDroid Note Type Setup

## Note Type: "Japanese Sentence"

### Fields (in order, all 8 required)

| # | Field Name | Purpose |
|---|-----------|---------|
| 1 | Word | Kanji form (e.g. 食べる) |
| 2 | Reading | Kana reading (e.g. たべる) |
| 3 | Sentence | Example sentence in Japanese |
| 4 | Sentence Reading | Kana reading of the sentence |
| 5 | Sentence Translation | English translation |
| 6 | Meaning | English meaning |
| 7 | Part of Speech | e.g. "v1, transitive" |
| 8 | Notes | Etymology, fun facts, JLPT, pitch accent, nuance |

---

## Card 1: Front Template

```html
<div class="card-front">
  <div class="word">{{Word}}</div>
  <div class="reading">{{Reading}}</div>
  
  <hr>
  
  <div class="sentence">{{Sentence}}</div>
  <div class="sentence-reading">{{Sentence Reading}}</div>
</div>
```

---

## Card 1: Back Template

```html
<div class="card-back">
  <div class="word-row">
    <span class="word">{{Word}}</span>
    <span class="reading">{{Reading}}</span>
    <span class="tts-btn">{{tts ja_JP voices=Apple_O-ren,Google_ja-JP:Word}}</span>
  </div>
  
  <hr>
  
  <div class="sentence-row">
    <div class="sentence">{{Sentence}}</div>
    <div class="sentence-reading">{{Sentence Reading}}</div>
    <span class="tts-btn">{{tts ja_JP voices=Apple_O-ren,Google_ja-JP:Sentence}}</span>
  </div>
  
  <hr>
  
  <div class="translation">{{Sentence Translation}}</div>
  
  <div class="details">
    <div class="detail-row"><span class="label">Meaning</span> {{Meaning}}</div>
    <div class="detail-row"><span class="label">Part of Speech</span> {{Part of Speech}}</div>
  </div>
  
  {{#Notes}}
  <div class="notes">{{Notes}}</div>
  {{/Notes}}
</div>

<script>
  // Auto-play word pronunciation on flip
  var wordElem = document.querySelector('.tts-btn');
  if (wordElem) {
    setTimeout(function() {
      wordElem.click();
    }, 300);
  }
</script>
```

---

## Styling (shared CSS)

```css
.card {
  font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic Pro', sans-serif;
  font-size: 18px;
  text-align: center;
  color: #1a1a2e;
  background-color: #fafafa;
  padding: 20px;
  max-width: 500px;
  margin: 0 auto;
}

.word {
  font-size: 42px;
  font-weight: 700;
  color: #16213e;
  margin-bottom: 4px;
}

.reading {
  font-size: 18px;
  color: #888;
  margin-bottom: 8px;
}

.sentence {
  font-size: 24px;
  font-weight: 500;
  color: #0f3460;
  margin: 12px 0 4px 0;
  line-height: 1.5;
}

.sentence-reading {
  font-size: 14px;
  color: #aaa;
  margin-bottom: 8px;
}

.translation {
  font-size: 18px;
  color: #555;
  font-style: italic;
  margin: 12px 0;
  padding: 8px;
  background: #f0f0f0;
  border-radius: 6px;
}

.details {
  text-align: left;
  margin-top: 12px;
  padding: 12px;
  background: #e8f0fe;
  border-radius: 8px;
}

.detail-row {
  margin: 4px 0;
  font-size: 15px;
}

.label {
  font-weight: 600;
  color: #16213e;
  margin-right: 8px;
}

.notes {
  text-align: left;
  margin-top: 10px;
  padding: 10px;
  background: #fff3cd;
  border-radius: 6px;
  font-size: 13px;
  color: #664d03;
  line-height: 1.4;
}

hr {
  border: none;
  border-top: 1px solid #e0e0e0;
  margin: 12px 0;
}

.tts-btn {
  display: inline-block;
  cursor: pointer;
  font-size: 20px;
  padding: 4px 8px;
  margin-left: 8px;
  vertical-align: middle;
  opacity: 0.6;
}

.tts-btn:hover {
  opacity: 1;
}

/* Night mode */
.nightMode .card {
  background-color: #1a1a2e;
  color: #e0e0e0;
}
.nightMode .word { color: #e94560; }
.nightMode .sentence { color: #f5f5f5; }
.nightMode .translation { background: #2a2a4a; color: #ccc; }
.nightMode .details { background: #16213e; }
.nightMode .notes { background: #3d3522; color: #ffc107; }
.nightMode hr { border-color: #333; }
```

---

## TTS Setup (one-time, on your phone)

1. Settings → System → Languages & input → Text-to-speech output
2. Select "Google Text-to-speech" as the engine
3. Tap the gear icon → Install voice data → Japanese
4. Done — no API keys, no internet required

The `{{tts ja_JP ...}}` tags render as speaker icons. Tap to hear the word or sentence spoken in Japanese. The back template auto-plays the word pronunciation 300ms after flipping.

---

## What the LLM generates

The app makes two LLM calls:

### Phase 1 — Word Lookup
Returns candidate words with:
- Word (kanji), reading (kana)
- Multiple usages (meaning, part of speech, example sentence, nuance)
- JLPT level (N5–N1)
- Pitch accent notation
- **Etymology** (historical origin of the word)
- **Fun fact** (cultural note, mnemonic, interesting trivia)

### Phase 2 — Card Generation
For the selected word + usages, generates:
- A fresh, natural example sentence with reading and translation
- **Tidbit** — a combined note blending etymology, fun facts, and cultural context

All of these land in the Anki card's **Notes** field (field #8), formatted as:
`Etymology: ... | Fun fact: ... | JLPT: N5 | Pitch: たべる [2] | Nuance: casual`

---

## App Settings Reference

| Setting | Default | Description |
|---------|---------|-------------|
| API URL | `https://api.openai.com/v1/chat/completions` | Any OpenAI-compatible endpoint |
| API Key | (empty) | Your API key |
| Model | `gpt-4o` | Model name |
| Deck Name | `Japanese Mining` | AnkiDroid deck to add cards to |
| Note Type | `Japanese Sentence` | Must match the note type created above |

## Prompt Templates

| Template | Effect |
|----------|--------|
| General | No special context |
| Anime | Prefers anime/manga-style example sentences |
| Business | Prefers formal/business Japanese |
| Casual | Prefers everyday conversation |
| Literary | Prefers novel/literary contexts |
| News | Prefers news/article-style sentences |
