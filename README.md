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
2.  Getting Started
2.  YAML Pack Schema
3.  Mode Layering (How the Flags Work Together)
4.  Complete Options Reference
5.  Listening & Spoken Variants
6.  Piper TTS Setup
7.  Spaced Repetition System (SRS)
8.  Missed Pack Generation
9.  System Architecture
10. License

------------------------------------------------------------------------

# 1. Overview

A typical session works like this:

1.  Load a YAML pack
2.  Getting Started
2.  Normalize entries
3.  Select direction (source→target or target→source)
4.  Layer optional behaviors (match‑game, listening, SRS)
5.  Prompt → validate → score attempts
6.  Optionally update SRS state
7.  Optionally write a missed‑entries pack

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
git clone <your-repo-url>
cd linguatrain
```

Run the CLI directly:

``` bash
ruby bin/linguatrain.rb pack.yaml
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

    ~/linguatrain/packs/finnish_basics.yaml

Run it:

``` bash
ruby bin/linguatrain.rb ~/linguatrain/packs/finnish_basics.yaml 5
```

------------------------------------------------------------------------

## Optional: User Configuration

User configuration is optional but recommended.

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

### Minimal Example Configuration

``` yaml
runtime:
  audio_player: "afplay"   # macOS default

piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"

defaults:
  tts_template: "Target language: {text}."
```

------------------------------------------------------------------------

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

## metadata

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
    prompt_prefix: "englanniksi"
    target_prefix: "suomeksi"
    quiz_label: "Quiz"
    correct: "✅ Oikein!"
    try_again: "Yritä uudelleen."
    replay_hint: "(Kirjoita 'r' toistaaksesi äänen)"
    also_accepted_prefix: 'Myös käy:'
    phonetic_prefix: ääntämys
    correct_answer_prefix: "❌ Oikea vastaus:"
    correct_word_prefix: "❌ Oikea sana:"
    quit_message: "👋🏻 Lopetetaan. Kiitos!"
    quiz_label: Quiz
```
## TTS Template

Some Text-to-Speech engines (including Piper) can sound unnatural when
speaking isolated words, for example `ei`.

To improve clarity and natural prosody, `linguatrain` wraps the spoken
text in a configurable template during listening mode.

The template must include the placeholder:

    {text}

Example:

``` yaml
tts:
  template: "Suomeksi: {text}."
```

When listening mode runs, the engine replaces `{text}` with the word or
phrase being practiced.

This helps:

-   Improve rhythm and natural intonation
-   Reduce clipped or abrupt pronunciation
-   Increase intelligibility for short words

The engine does not modify the stored word or phrase. The template only
affects speech output and does not change answer validation.

If no template is specified, a default template is used.

## UI Metadata (`metadata.ui`)

The `ui` block allows packs to customize display labels used during a
quiz session.

These values affect console output only. They do not change validation
logic, scoring, SRS behavior, or language processing.

Example:

``` yaml

ui:
  prompt_prefix: "englanniksi"
  target_prefix: "suomeksi"
  quiz_label: "Quiz"
  correct: "✅ Oikein!"
  try_again: "Yritä uudelleen."
  replay_hint: "(Kirjoita 'r' toistaaksesi äänen)"
  also_accepted_prefix: "Myös käy:"
  phonetic_prefix: "ääntämys"
  correct_answer_prefix: "❌ Oikea vastaus:"
  correct_word_prefix: "❌ Oikea sana:"
  quit_message: "👋🏻 Lopetetaan. Kiitos!"
    
```

------------------------------------------------------------------------

## Supported UI Fields

All UI fields are optional. If omitted, the default values shown below
are used.

------------------------------------------------------------------------

### `quiz_label`

**Description**\
Text displayed in the session header.

**Default**\
`"Quiz"`

**Example**

Header output:

    English → Finnish Quiz — 10 word(s) (mode: typing)

If configured as:

``` yaml
quiz_label: "Drill"
```

Header becomes:

    English → Finnish Drill — 10 word(s) (mode: typing)

Cosmetic only.

------------------------------------------------------------------------

### `prompt_prefix`

**Description**\
Label displayed before the source-language prompt.

**Default**\
`"Prompt"`

------------------------------------------------------------------------

### `target_prefix`

**Description**\
Label displayed when requesting the target-language answer.

**Default**\
`"Answer"`\
(Or the language name if defined in the pack metadata.)

------------------------------------------------------------------------

### `correct`

**Description**\
Message displayed when the user provides a correct answer.

**Default**\
`"✅ Correct!"`

------------------------------------------------------------------------

### `try_again`

**Description**\
Message displayed after an incorrect first attempt (when retries are
allowed).

**Default**\
`"Try again."`

------------------------------------------------------------------------

### `correct_answer_prefix`

**Description**\
Prefix displayed when revealing the correct source-language answer in
reverse mode.

**Default**\
`"❌ Correct answer:"`

------------------------------------------------------------------------

### `correct_word_prefix`

**Description**\
Prefix displayed when revealing the correct target-language answer.

**Default**\
`"❌ Correct word:"`

------------------------------------------------------------------------

### `also_accepted_prefix`

**Description**\
Prefix displayed before alternate accepted answers.

**Default**\
`"Also accepted:"`

------------------------------------------------------------------------

### `phonetic_prefix`

**Description**\
Label displayed before phonetic output (if phonetics are enabled in the
pack).

**Default**\
`"phonetic"`

------------------------------------------------------------------------

### `replay_hint`

**Description**\
Instructional text shown in listening mode explaining how to replay
audio.

Displayed only when `--listen` mode is active.

**Default**\
`"(Type 'r' to replay audio)"`

------------------------------------------------------------------------

### `quit_message`

**Description**\
Message displayed when the user exits the session early (for example by
pressing `q`).

Displayed once at termination.

**Default**\
`"Session ended."`

------------------------------------------------------------------------


### Notes

-   All UI values are optional.
-   If omitted, engine defaults are used.
-   Pack-level UI overrides user configuration defaults.
-   UI settings affect display only and never change scoring or
    validation.


## Language Codes (`languages.source.code` / `languages.target.code`)

The `code` fields identify the source and target languages.

They are used for:

-   Mapping Piper models via `config.yaml`
-   Organizing multi-language setups
-   Future extensibility (for example, per-language defaults)

------------------------------------------------------------------------

### Expected Format

`linguatrain` expects language codes in one of the following standard
forms:

**ISO 639-1 (two-letter)**

    en
    fi
    es
    de

**BCP-47 language tags (recommended)**

    en-US
    en-GB
    fi-FI
    es-ES
    pt-BR

BCP-47 is the same format used by:

-   Web browsers
-   Many TTS engines
-   Piper voice model directories
-   IETF language tagging standards

If unsure, use:

    language-REGION

Where:

-   `language` = ISO 639-1 code (lowercase)
-   `REGION` = ISO 3166 country code (uppercase)

Examples:

    fi-FI
    es-MX
    en-GB

------------------------------------------------------------------------

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

------------------------------------------------------------------------

### How `linguatrain` Uses These Codes

If you configure Piper models like this:

``` yaml
piper:
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"
```

Then your pack must use:

``` yaml
languages:
  target:
    code: "fi-FI"
```

The `code` must match the key used in `config.yaml`.

If no matching model is found:

-   The fallback `piper.model` value is used (if defined)
-   Otherwise, `--listen` will exit with an error

------------------------------------------------------------------------

### Important Notes

-   `code` is required for proper TTS model resolution.
-   `name` is cosmetic and used only for UI display.
-   The engine does not validate codes against an official registry.
-   Consistency matters more than strict compliance.


## entries

``` yaml
entries:
  - id: "001"
    prompt: "How are you?"
    alternate_prompts:
      - "How's it going?"
      - "How have you been?"
    answer:
      - "Mitä kuuluu?"
      - "Kuinka voit?"
    spoken:
      - "Mites menee?"
    phonetic: "MI-tah KOO-loo"
```

### Field Summary

-   `prompt` --- source‑language text (string or array)
-   `alternate_prompts` --- additional accepted source variants
-   `answer` --- canonical (usually written/standard) target form
-   `spoken` --- optional colloquial/spoken variant
-   `phonetic` --- optional pronunciation guide

`answer` is always the canonical reference form.\
`spoken` is optional and never used unless explicitly enabled via flags.

Legacy schemas and mapping styles remain supported for backward
compatibility.

------------------------------------------------------------------------

# 3. Mode Layering (How the Flags Work Together)

All modes build on the same base loop:

    prompt → validate → score

Flags layer behavior on top of that loop.\
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

Adds three distractor hints.\
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

Target language is spoken via Piper.\
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
  ------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

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

https://huggingface.co/rhasspy/piper-voices

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

