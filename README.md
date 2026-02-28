# linguatrain

`linguatrain` is a fully language‑generic, YAML‑driven command‑line
vocabulary and phrase trainer with optional listening support and
built‑in spaced repetition scheduling.

It is designed to be:

-   Language‑agnostic
-   Pack‑driven (You configure and select your language choices)
-   CLI‑first
-   Extensible (Text-to-Speech, Spaced Repetition System, UI labels, and language metadata
    configurable)

------------------------------------------------------------------------

# Table of Contents

1.  Overview
1.  Getting Started
1.  YAML Pack Schema
1.  Mode Layering (How the Flags Work Together)
1.  Complete Options Reference
1.  Listening & Spoken Variants
1.  Piper TTS Setup
1.  Spaced Repetition System (SRS)
1.  Missed Pack Generation
1.  System Architecture
1. License

------------------------------------------------------------------------

# 1. Overview

A typical session works like this:

1.  Load a YAML pack
1.  Getting Started
1.  Normalize entries
1.  Select direction (source→target or target→source)
1.  Layer optional behaviors (match‑game, listening, SRS)
1.  Prompt → validate → score attempts
1.  Optionally update SRS state
1.  Optionally write a missed‑entries pack

All UI labels, language names, and TTS carrier phrases are defined in
pack metadata or user configuration.

There is no language‑specific logic in the engine.

------------------------------------------------------------------------
# Getting Started

This section explains the minimal setup required to run `linguatrain`,
where files live, and what must be configured.

------------------------------------------------------------------------

## Install Ruby

`linguatrain` requires Ruby 3.x or later.

Check your version:

``` bash
ruby -v
```

If needed, install Ruby using your preferred version manager (rbenv,
RVM, asdf) or your system package manager.

------------------------------------------------------------------------

## Clone the Repository

``` bash
git clone https://github.com/wbrisett/linguatrain.git
cd linguatrain
```

Run the CLI directly:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml
```

No additional gems are required beyond the Ruby standard library.

------------------------------------------------------------------------

## Create or Place a YAML Pack

A pack is a YAML file containing:

-   `metadata`
-   `entries`

Example structure:

``` bash
mkdir -p ~/linguatrain/packs
```

Example pack location:

    ~/linguatrain/packs/fi/

template pack location: 

    ~/linguatrain/packs/templates/linguatrain_pack_complete_template.yaml


Run it:

``` bash
ruby bin/linguatrain.rb ~/linguatrain/packs/finnish_everyday_phrases.yaml 5
```

------------------------------------------------------------------------

## Optional: User Configuration

User configuration is optional but it is highly recommended.

------------------------------------------------------------------------

### Linux and macOS

Default location:

    ~/.config/linguatrain/config.yaml

Create the directory:

``` bash
mkdir -p ~/.config/linguatrain
```

------------------------------------------------------------------------

### Windows

Default location:

    %APPDATA%\linguatrain\config.yaml

Typically resolves to:

    C:\Users\<YourUser>\AppData\Roaming\linguatrain\config.yaml

Create the directory in PowerShell:

``` powershell
mkdir $env:APPDATA\linguatrain
notepad $env:APPDATA\linguatrain\config.yaml
```

------------------------------------------------------------------------

### Example Configuration

``` yaml
runtime:
  audio_player: "afplay"   # macOS default

piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"

defaults:
  tts_template: "Target language: {text}."      # safe generic default
  ui_locale: "en"                               # optional; for your own UI defaults
```

------------------------------------------------------------------------

Default config location:

- Linux / macOS: `~/.config/linguatrain/config.yaml`
- Windows: `%APPDATA%\linguatrain\config.yaml`

---

# Configuration Structure

```yaml
runtime:
  audio_player: "afplay"

piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"

defaults:
  tts_template: "Target language: {text}."
  ui_locale: "en"
```

All sections are optional.  

If omitted, engine defaults are used.

---

# `runtime`

The `runtime` block defines execution-time behavior that is not
language-specific.

## `runtime.audio_player`

**Type:** string  
**Required:** No  
**Default:** platform-dependent

Defines the command used to play generated `.wav` files.

The command must:

- Accept a file path
- Be available on the system PATH (or use a full absolute path)

If the player cannot be executed, listening mode fails with an error.

### Audio Player Options by Platform

The `audio_player` setting controls how generated `.wav` files are
played.

Common options:

**macOS**

``` yaml
runtime:
  audio_player: "afplay"
```

**Linux**

``` yaml
runtime:
  audio_player: "aplay"      # ALSA
```

or

``` yaml
runtime:
  audio_player: "paplay"     # PulseAudio
```

or

``` yaml
runtime:
  audio_player: "ffplay -nodisp -autoexit"
```

**Windows**

``` yaml
runtime:
  audio_player: "powershell -c (New-Object Media.SoundPlayer '%s').PlaySync();"
```

or (if installed and on PATH)

``` yaml
runtime:
  audio_player: "ffplay -nodisp -autoexit"
```

Note: The player must be available on your system PATH. You may also
provide a full absolute path to the executable.

------------------------------------------------------------------------

### Windows Example Configuration

``` yaml
runtime:
  audio_player: "ffplay -nodisp -autoexit"

piper:
  bin: "C:\Users\<YourUser>\venvs\piper\Scripts\piper.exe"
  models:
    fi-FI: "C:\Users\<YourUser>\models\fi_FI-harri-medium.onnx"
```

---

# `piper`

The `piper` block configures the Text-to-Speech backend.

Listening modes require Piper to be installed and configured.

## `piper.bin`

**Type:** string  
**Required:** Yes (for listening mode)

Absolute path to the Piper executable.

If omitted and listening is enabled, the program exits with an error.

Environment variable alternative:

- `PIPER_BIN`

---

## `piper.models`

**Type:** mapping of language code → file path  
**Required:** Yes (for listening mode)

Maps language codes (matching `metadata.languages.target.code`)
to `.onnx` model files.

The key must match the pack’s target language code exactly.

If no matching model is found:

- A fallback model may be used (if configured elsewhere)
- Otherwise, listening mode exits with an error

Environment variable alternative:

- `PIPER_MODEL` (single-model fallback)

---

# `defaults`

The `defaults` block defines global fallback values used when packs do
not specify overrides.

## `defaults.tts_template`

**Type:** string  
**Required:** No

Defines a global TTS carrier phrase.

The template must contain:

```
{text}
```

Precedence order:

1. Command-line flags (if provided)
2. Pack `metadata.tts.template`
3. `defaults.tts_template`
4. Engine internal default

This value affects speech output only.

---

## `defaults.ui_locale`

**Type:** string  
**Required:** No  
**Default:** "en"

Defines a preferred UI language for default labels when packs do not
provide `metadata.ui` overrides.

This setting does not alter pack metadata.

---

# Configuration Precedence

When the same behavior is defined in multiple places, the following
precedence applies (highest to lowest):

1. Command-line flags
2. Environment variables
3. Pack metadata
4. User configuration (`config.yaml`)
5. Engine internal defaults


------------------------------------------------------------------------

### Environment Variables (Optional)

You may also configure via environment variables instead of a config
file:

-   `PIPER_BIN`
-   `PIPER_MODEL`
-   `LINGUATRAIN_CONFIG`
-   `AUDIO_PLAYER`
-   `TTS_TEMPLATE`

Command-line flags always override configuration values.

------------------------------------------------------------------------

## 5. First Run (Typing Mode)

Minimal usage:

``` bash
ruby bin/linguatrain.rb pack.yaml 5
```

This runs:

-   Source → Target direction
-   Typing mode
-   No SRS
-   No listening

------------------------------------------------------------------------

## 6. Enable Spaced Repetition (Optional)

``` bash
ruby bin/linguatrain.rb pack.yaml all --srs
```

SRS state is stored automatically in:

Linux / macOS:

    ~/.config/linguatrain/srs/<pack_id>.yaml

Windows:

    %APPDATA%\linguatrain\srs\<pack_id>.yaml

No configuration is required.

------------------------------------------------------------------------

## 7. Enable Listening Mode (Requires Piper)

Listening requires:

-   Piper CLI installed
-   A voice model file (`.onnx` + `.onnx.json`)

You must configure:

-   `--piper-bin`
-   `--piper-model`

or define them in config or environment variables.

Example:

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --listen
```

If Piper is not configured correctly, the program will exit with an
error.

piper models are available for various languages here: 

- https://huggingface.co/rhasspy/piper-voices/tree/main

------------------------------------------------------------------------

## 8. Recommended Directory Layout

Linux / macOS:

    ~/
      linguatrain/
        packs/
          finnish.yaml
          spanish.yaml

      .config/
        linguatrain/
          config.yaml
          srs/
            finnish.yaml

Windows:

    C:\Users\<YourUser>\
      linguatrain\
        packs\
          finnish.yaml
          spanish.yaml

      AppData\Roaming\
        linguatrain\
          config.yaml
          srs\
            finnish.yaml

This structure is optional but keeps packs, configuration, and SRS state
organized.


---

# 2. YAML Pack Schema

## Top-Level Structure

``` yaml
metadata:
  id: "pack_id"
  version: 1
  languages:
    source:
      code: "en"
      name: "English"
    target:
      code: "fi-FI"
      name: "Finnish"
  tts:
    template: "Suomeksi: {text}."
  ui:
    quiz_label: "Quiz"
    prompt_prefix: "Prompt"
    target_prefix: "Answer"
    correct: "✅ Correct!"
    try_again: "Try again."
    replay_hint: "(Type 'r' to replay audio)"
    also_accepted_prefix: "Also accepted:"
    phonetic_prefix: "phonetic"
    correct_answer_prefix: "❌ Correct answer:"
    correct_word_prefix: "❌ Correct word:"
    quit_message: "Session ended."

entries:
  - id: "001"
    prompt: "Example prompt"
    answer:
      - "Example answer"
    phonetic: ""
    notes: ""
    tags: []
    audio:
      tts: true
    srs:
      difficulty: 1
```

------------------------------------------------------------------------

# Metadata (`metadata`)

The `metadata` block defines pack-wide configuration and behavior.

## `id`

**Type:** string\
**Required:** Yes

Unique identifier for the pack.

-   Must be unique within your collection of packs.
-   Used internally for tracking and future extensibility.
-   Should remain stable once published.

------------------------------------------------------------------------

## `version`

**Type:** integer
**Required:** Yes
**Current supported value:** `1`

Defines the schema version.

Until a schema revision is announced, this should always be set to `1`.

------------------------------------------------------------------------

## `languages`

Defines the source and target languages used in the pack.

``` yaml
languages:
  source:
    code: "en"
    name: "English"
  target:
    code: "fi-FI"
    name: "Finnish"
```

### `code`

The `code` fields identify the source and target languages.

They are used for:

-   Mapping Piper models via `config.yaml`
-   Organizing multi-language setups
-   Future extensibility

#### Expected Format

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

### Where to Find Language Codes

**ISO 639-1 language codes**

Official reference:
https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

Common examples:

Language   Code
  ---------- ------
English    en
Finnish    fi
Spanish    es
German     de
French     fr

**ISO 3166 region codes**

Official reference: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2


#### Model Resolution Behavior

If Piper models are configured as:

``` yaml
piper:
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"
```

Then the pack must use:

``` yaml
languages:
  target:
    code: "fi-FI"
```

The `code` must match the key used in `config.yaml`.

If no matching model is found:

-   A fallback model may be used (if defined)
-   Otherwise, `--listen` exits with an error

#### Notes

-   `code` is required for proper TTS resolution.
-   `name` is cosmetic and used for UI display only.
-   Codes are not validated against an official registry.
-   Consistency matters more than strict compliance.

------------------------------------------------------------------------

# Text-to-Speech Configuration (`metadata.tts`)

## TTS Template

Some Text-to-Speech engines (including Piper) can sound unnatural when
speaking isolated words, for example `ei`.

To improve clarity and natural prosody, Linguatrain wraps spoken text in
a configurable template during listening mode.

The template must include the placeholder:

    {text}

Example:

``` yaml
tts:
  template: "Suomeksi: {text}."
```

At runtime, `{text}` is replaced with the word or phrase being
practiced.

This helps:

-   Improve rhythm and intonation
-   Reduce clipped pronunciation
-   Increase intelligibility for short words

The template affects speech output only. It does not modify stored
content or change validation logic.

If no template is specified, a default template is used.

------------------------------------------------------------------------

# UI Configuration

The `ui` block allows packs to override console labels and messages.

UI settings affect display only.

They do not change validation, scoring, SRS behavior, or language logic.

All UI fields are optional. Engine defaults are used if omitted.

------------------------------------------------------------------------

## Supported UI Fields

### `quiz_label`

Displayed in the session header.

Default:

    "Quiz"

Example header:

    English → Finnish Quiz — 10 word(s) (mode: typing)

------------------------------------------------------------------------

### `prompt_prefix`

Label before the source-language prompt.

Default:

    "Prompt"

------------------------------------------------------------------------

### `target_prefix`

Label before the target-language answer input.

Default:

    "Answer"

If language metadata is defined, the engine may use the language name
instead.

------------------------------------------------------------------------

### `correct`

Message displayed after a correct answer.

Default:

    "✅ Correct!"

------------------------------------------------------------------------

### `try_again`

Displayed after an incorrect first attempt (if retries are enabled).

Default:

    "Try again."

------------------------------------------------------------------------

### `correct_answer_prefix`

Prefix used when revealing the correct source-language answer.

Default:

    "❌ Correct answer:"

------------------------------------------------------------------------

### `correct_word_prefix`

Prefix used when revealing the correct target-language word.

Default:

    "❌ Correct word:"

------------------------------------------------------------------------

### `also_accepted_prefix`

Displayed before alternate accepted answers.

Default:

    "Also accepted:"

------------------------------------------------------------------------

### `phonetic_prefix`

Label before phonetic output.

Default:

    "phonetic"

------------------------------------------------------------------------

### `replay_hint`

Instruction shown in listening mode explaining how to replay audio.

Default:

    "(Type 'r' to replay audio)"

Displayed only when `--listen` mode is active.

------------------------------------------------------------------------

### `quit_message`

Displayed when the session ends early.

Default:

    "Session ended."

------------------------------------------------------------------------

# Entries Schema

The `entries` array defines individual learning units.

Each entry represents one atomic prompt/answer pair with optional
pronunciation, tagging, audio, and SRS metadata.

------------------------------------------------------------------------

## Entry Structure

``` yaml
- id: "001"
  prompt: "Example prompt in source language."
  answer:
    - "Example answer in target language."
  phonetic: ""
  notes: ""
  tags: []
  audio:
    tts: true
  srs:
    difficulty: 1
```

------------------------------------------------------------------------

## Field Reference

### `id`

**Type:** string
**Required:** Yes

Unique identifier within the pack.

-   Must not be duplicated.
-   Used for SRS tracking and missed-pack generation.
-   Recommended format: zero-padded strings (`"001"`, `"002"`).

------------------------------------------------------------------------

### `prompt`

**Type:** string
**Required:** Yes
**Purpose:** The text shown to the user in the *source language*.

Behavior depends on mode:

-   In `typing` mode: prompt is shown; user types target language.
-   In `reverse` mode: target language is shown or spoken; user types
    source.
-   In `match-game`: prompt anchors hint selection.
-   In `listen` mode: prompt may be spoken if TTS is enabled.

This field should contain natural, learner-facing text.

------------------------------------------------------------------------

### `answer`

**Type:** list of strings\
**Required:** Yes (must always be a list)

Even if only one accepted answer exists, it must be defined as a YAML
list:

``` yaml
answer:
  - "Hyvää huomenta"
```

Multiple accepted answers:

``` yaml
answer:
  - "Hei"
  - "Moi"
```

The engine will accept any string in the list as correct input.

------------------------------------------------------------------------

### `phonetic`

**Type:** string
**Required:** No
**Purpose:** Provides pronunciation guidance.

Displayed only if:

-   The UI configuration includes phonetic display
-   Or when showing correct answers

Example:

``` yaml
phonetic: "HY-vah"
```

If empty or omitted, no pronunciation guidance is shown.

------------------------------------------------------------------------

### `notes`

**Type:** string
**Required:** No
**Purpose:** Supplemental learning context.

Use this for:

-   Grammar explanations
-   Usage notes
-   Cultural context
-   Formal vs informal distinctions

Displayed when reviewing correct answers or when configured in the UI
layer.

Example:

``` yaml
notes: "Formal greeting used in emails."
```


------------------------------------------------------------------------

### `tags`

**Type:** list of strings
**Required:** No
**Purpose:** Logical grouping and filtering.

Used for:

-   Subset selection
-   Thematic drilling
-   Future expansion features

Example:

``` yaml
tags:
  - "greeting"
  - "formal"
```

If unused, define as:

``` yaml
tags: []
```


------------------------------------------------------------------------

### `audio`

**Type:** object
**Required:** No
**Purpose:** Controls speech behavior per entry.

``` yaml
audio:
  tts: true
```

#### `tts`

**Type:** boolean
**Default:** false if omitted

When `true`, this entry is eligible for Text-to-Speech playback when:

-   `--listen` mode is active
-   Reverse + listening is active
-   Any speech-triggering mode is enabled

If omitted or false, the entry will never trigger TTS.

------------------------------------------------------------------------

### `srs`

**Type:** object
**Required:** No
**Purpose:** Spaced Repetition scheduling metadata.

``` yaml
srs:
  difficulty: 1
```

#### `difficulty`

**Type:** integer
**Recommended Range:** 1--5
**Default:** 1 if omitted

Represents relative learning difficulty.

Value   Meaning
  ------- --------------------------------
1       Very easy / high frequency
2       Easy
3       Moderate
4       Difficult
5       Very difficult / low frequency

The engine may use this value to:

-   Adjust initial review intervals
-   Bias session selection
-   Modify repetition frequency

------------------------------------------------------------------------

# Design Principles

-   All optional fields may be omitted safely.
-   Schema is forward-compatible.
-   Each entry is self-contained.
-   UI fields affect display only.
-   TTS templates affect speech output only.
-   SRS metadata influences scheduling only.

------------------------------------------------------------------------

# 3. Mode Layering (How the Flags Work Together)

All modes build on the same base loop:

    prompt → validate → score

Flags layer behavior on top of that loop.

Stacking modes increases difficulty without changing core validation
logic.

## Base Typing Mode (default)

Source shown → type target.

``` bash
ruby bin/linguatrain.rb pack.yaml 5
```

------------------------------------------------------------------------

## Reverse Mode (`--reverse`)

Target shown → type source.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --reverse
```

Direction swaps. Everything else stays the same.

------------------------------------------------------------------------

## Match‑Game (`--match-game`)

Adds three distractor hints.

You still type the full answer.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --match-game
```

Reverse + match‑game:

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --reverse --match-game
```

Hints adapt to direction automatically.

------------------------------------------------------------------------

## Listening (`--listen`)

Target language is spoken via Piper.

Source remains visible.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --listen
```

Listening + reverse:

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --reverse --listen
```

------------------------------------------------------------------------

## Listening Hard Mode (`--listen-no-source`)

Target spoken. Source hidden.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --listen-no-source
```

Alias: `--listen-no-english`

------------------------------------------------------------------------

## Listening + Match-Game (Recommended Beginner Mode)

This combination layers listening with guided recall.\
The learner hears the target language first, sees constrained hints, and
must still type the full answer.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --listen --match-game
```

Example:

``` text
English → Finnish Quiz — 5 word(s) (mode: match-game, listen, English→Finnish)
--------------------------------------------------

[1/5]
Audible Finnish: (listening…)
Prompt: How are you?
Hints:
  - Mitä kuuluu?
  - Kuinka voit?
  - Mites menee?
(Type 'r' to replay audio)
Answer: mitä kuuluu
✅ Correct!
   Also accepted: kuinka voit? / mites menee?
   (phonetic: MI-tah KOO-loo)
```

### Why This Mode Is Powerful

-   The word or phrase is heard first
-   Hints reduce cognitive overload
-   The learner must still type the full answer
-   Audio can be replayed
-   Encourages recognition → recall progression

------------------------------------------------------------------------

### Localized UI Example (Finnish)

``` text
Englanti → Suomi Harjoitus — 5 word(s) (mode: match-game, listen, Englanti→Suomi)
--------------------------------------------------

[1/5]
Audible Suomi: (kuuntelu…)
englanniksi: How are you?
Vihjeet:
  - Mitä kuuluu?
  - Kuinka voit?
  - Mites menee?
(Type 'r' to replay audio)
suomeksi: mitä kuuluu
✅ Oikein!
   Hyväksytään myös: kuinka voit? / mites menee?
   (ääntämys: MI-tah KOO-loo)
```

------------------------------------------------------------------------

## Stacking Example

Full stacked drill:

``` bash
ruby bin/linguatrain.rb pack.yaml 10 --reverse --listen --match-game --srs
```

Each flag layers behavior independently.

------------------------------------------------------------------------

# 4. Complete Options Reference

  ------------------------------------------------------------------------------------------------
  Flag                                       Purpose                    Default
  ------------------------------------------ -------------------------- --------------------------
  `--reverse`                                Swap direction             off

  `--match-game`                             Add 3 hints                off

  `--match-options MODE`                     Control hint display       auto

  `--listen`                                 Speak target (source       off
                                             shown)                     

  `--listen-no-source`                       Speak target (source       off
                                             hidden)                    

  `--listen-no-english`                      Alias                      off

  `--lenient-umlauts`                        Allow simplified           off
                                             characters                 

  `--tts-variant written|spoken`             Choose what Piper speaks   written

  `--answer-variant written|spoken|either`   Choose accepted answers    written

  `--show-variants`                          Display written/spoken     off
                                             together                   

  `--srs`                                    Enable spaced repetition   off

  `--due`                                    With SRS, only quiz due    off
                                             items                      

  `--new N`                                  Include up to N new SRS    5
                                             items                      

  `--reset-srs`                              Reset scheduling state     off

  `--srs-file PATH`                          Override SRS state file    pack‑derived

  ----------------------------------------------------------------------------------

# 5. Listening & Spoken Variants

By default:

-   `--listen` speaks the canonical `answer` form
-   Only `answer` is accepted as correct

The engine does not transform written forms into spoken forms
automatically.\
Piper reads exactly what is stored.

## Speak colloquial forms

``` bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --tts-variant spoken
```

If `spoken` exists, it is spoken.\
If missing, it falls back to `answer`.

## Practice spoken production

``` bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --tts-variant spoken --answer-variant spoken
```

## Accept either form

``` bash
ruby bin/linguatrain.rb pack.yaml 10 --answer-variant either
```

## Show both variants (display only)

``` bash
ruby bin/linguatrain.rb pack.yaml 10 --show-variants
```

------------------------------------------------------------------------

# 6. Piper TTS Setup

Listening modes require:

-   Piper CLI (`piper`)
-   Voice model (`.onnx` + `.onnx.json`)

## macOS Installation

``` bash
python3 -m venv ~/venvs/piper
source ~/venvs/piper/bin/activate
pip install piper-tts
```

Models are available at:

https://huggingface.co/rhasspy/piper-voices/tree/main

Example model path:

    fi/fi_FI/harri/medium/

Smoke test:

``` bash
echo "Hei." | piper -m model.onnx -f /tmp/test.wav
afplay /tmp/test.wav
```

------------------------------------------------------------------------

# 7. Spaced Repetition System (SRS)

Inspired by SM‑2 (Anki / SuperMemo).

Each word stores:

-   `reps`
-   `interval_days`
-   `ease`
-   `due_at`
-   `lapses`

Performance rules:

-   Correct 1st try → larger interval growth
-   Correct 2nd try → smaller growth
-   Failure → reset + \~10 minute retry

## Storage Location

    ~/.config/linguatrain/srs/<pack>.yaml

Override:

    --srs-file PATH

## Usage

Enable:

``` bash
ruby bin/linguatrain.rb pack.yaml all --srs
```

Due only:

``` bash
ruby bin/linguatrain.rb pack.yaml all --srs --due
```

Limit new words:

``` bash
ruby bin/linguatrain.rb pack.yaml all --srs --new 10
```

Reset scheduling:

``` bash
ruby bin/linguatrain.rb pack.yaml all --srs --reset-srs
```

------------------------------------------------------------------------

# 8. Missed Pack Generation

At the end of a session, missed words are written to a timestamped YAML
file containing:

-   Original metadata
-   Generation details
-   Session stats
-   Failed entries only

This allows focused follow‑up drilling.

------------------------------------------------------------------------

# 9. System Architecture

``` mermaid
flowchart TD
  A["YAML pack"] --> B["Loader / Normalizer"]
  B --> C["Mode & Direction"]
  C --> D{"Listening enabled?"}
  D -- yes --> E["Piper speak target"]
  D -- no --> F["Skip audio"]
  E --> G["Prompt user"]
  F --> G
  G --> H["Validate input"]
  H --> I["Score attempts"]
  I --> J{"SRS enabled?"}
  J -- yes --> K["Update SRS state"]
  J -- no --> L["Skip SRS"]
  K --> M{"Misses?"}
  L --> M
  M -- yes --> N["Write missed pack"]
  M -- no --> O["Finish session"]
```

------------------------------------------------------------------------

# 10. License

Copyright © 2026 Wayne F. Brissette

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

See the LICENSE file for details.

