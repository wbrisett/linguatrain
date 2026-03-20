# Localisation Template Setup

Localisation templates define how linguatrain displays UI labels and optional text‑to‑speech carrier phrases for a specific language pair. They are optional, but recommended when you want the interface to appear in the learner's language.

Example localisation template:

```yaml
meta:
  id: 
  name: 

languages:
  source:
    code: 
    name: 
  target:
    code: 
    name: 

tts:
  template: 
ui:
  quiz_label: 
  correct: 
  try_again: 
  replay_hint: 
  also_accepted_prefix:
  phonetic_prefix: 
  prompt_prefix: 
  target_prefix:
  correct_answer_prefix: 
  correct_word_prefix: 
  quit_message: 
  no_mistakes: 
```

## meta

The `meta` block identifies the localisation file and provides a human‑readable description.

### meta.id

A unique identifier for this localisation configuration. It is used internally and should remain stable once published.

**Tip:** A good practice is to match the filename with the ID. 

### meta.name

This is simply a text label for you to easily identify what is in the configuration. 

**Example**

```yaml
meta:
  id: "en-US_fi-FI"
  name: "English → Finnish (Finnish UI)"
```

## languages

The language section is used to identify the source and target languages.

### languages.source 

This is the source language, it consists of two parts a `code` and `name`. The `code` should follow the BCP‑47 language tag format, while the name is a readable label. 

The name element is used in several places when running linguatrain. 

Example of language name in use: 

```text
English → Finnish Quiz — 38 word(s) (mode: typing, English→Finnish)
```
### languages.target 

The target language structure is identical to the source language block.

**Full Languages example**
```yaml
languages:
  source:
    code: "en-US"
    name: "English"
  target:
    code: "fi-FI"
    name: "Finnish"
```

The `code` fields identify the source and target languages.

They are used for:

-   Mapping Piper models via `config.yaml`
-   Organizing multi-language setups
-   Future extensibility

### Expected Format

Linguatrain accepts:

**ISO 639-1 (two-letter)**

    en
    fi
    es
    de

**BCP-47 language tags (recommended)**

    en-US
    fi-FI
    es-MX
    pt-BR

BCP-47 is preferred because it aligns with browsers, TTS engines, and
Piper model directories.

If unsure, use:

    language-REGION

Where:

-   `language` = ISO 639-1 code (lowercase)
-   `REGION` = ISO 3166 country code (uppercase)

Examples:

    fi-FI
    es-MX
    en-GB

#### Where to Find Language Codes

**ISO 639-1 language codes**

Official reference:
https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

**Common language code examples:**

| Language | Code |
|----------|------|
| English  | en   |
| Finnish  | fi   |
| Spanish  | es   |
| German   | de   |
| French   | fr   |

**ISO 3166 region codes**

Official reference: [ISO 3166-1 alpha-2 (Wikipedia)](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)

## tts
The `tts` section allows you to override the carrier phrase used when generating audio with text‑to‑speech.

### tts.template
This is the localisation override for text to speech. 

**Example**
```yaml
tts:
  template: "Suomeksi: {text}."
```
### ui
The `ui` section contains all interface labels that can be localised. 

**Example**
```yaml
ui:
  quiz_label: "Quiz"
  correct: "✅ Oikein!"
  try_again: "❌ Yritä uudelleen."
  replay_hint: "🔁 (Kirjoita 'r' toistaaksesi äänen)"
  also_accepted_prefix: "➕ Myös käy:"
  phonetic_prefix: "🗣 ääntämys:"
  prompt_prefix: "englanniksi"
  target_prefix: "suomeksi"
  correct_answer_prefix: "📘 Oikea vastaus:"
  correct_word_prefix: "📘 Oikea sana:"
  quit_message: "👋 Lopetetaan. Kiitos!"
  no_mistakes: "😊 Ei virheitä — hienoa!"
```

**Note:** Emojis are optional and used only for visual clarity. They are not required for localisation files.
