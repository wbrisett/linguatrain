<file name=0 path=README.md># linguatrain

A YAML-driven CLI language trainer for vocabulary, grammar, listening, and speaking practice.

![Ruby](https://img.shields.io/badge/Ruby-3.x-red)
![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![CLI](https://img.shields.io/badge/interface-CLI-green)

`linguatrain` is a flexible Ruby command-line language trainer powered by YAML packs.

Instead of fixed courses, you define the vocabulary and phrases you want to learn, and Linguatrain drills them using multiple learning modes — including typing, listening, grammar transformations, conjugation practice, conversation simulation, and spoken responses.

Everything runs directly in your terminal.

## Key Features

- YAML-driven language packs — study exactly the vocabulary you choose
- Multiple learning modes: study, typing, listening, grammar drills
- Sentence transformation drills (`--transform`)
- Verb conjugation drills (`--conjugate`)
- Conversation simulation (`--conversation`)
- Speech practice using Whisper (`--speak`)
- Optional text-to-speech with Piper (`--listen`)
- Lightweight spaced repetition (`--srs`)
- Fully localizable interface
- Runs entirely in the terminal

---

## Quick Demo

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --listen --match-game
```
```text
English → Finnish Quiz

[1/38]

englanniksi: How are you?

🎧 (audio plays)

Hints:
  - tämä
  - suomen kurssi
  - Mitä kuuluu?

suomeksi:
> Mitä kuuluu?

✅ Oikein!
```

One command.

Vocabulary → listening → recall → feedback

## Why Linguatrain Exists

Many language-learning tools are built around fixed courses or rigid vocabulary sets.

Linguatrain takes a different approach: you control the study material.

Instead of adapting your learning to a predefined curriculum, you create small YAML packs containing the words, phrases, and grammar patterns you actually want to practice.

This makes it easy to:

- drill vocabulary from textbooks or classes
- practice grammar patterns such as transformations and conjugations
- rehearse conversation exchanges
- combine listening, speaking, and recall in one workflow

Linguatrain is designed for learners who want **full control over their language practice**, while still benefiting from structured drills and progressive difficulty.

## Learning Modes Overview

Linguatrain is designed around the idea that **language learning progresses through several stages**. Each mode in the tool maps to a specific stage of skill development.

Typical progression:

```
study → typing → listen → match-game → transform → conjugate → conversation → speak
```

| Stage | Skill Being Trained | Linguatrain Mode |
|------|--------------------|------------------|
| Recognition | Seeing and understanding vocabulary | `--study` |
| Recall | Producing the word or phrase | default typing mode |
| Listening comprehension | Recognizing spoken language | `--listen` |
| Guided recall | Recall with constrained hints | `--match-game` |
| Grammar transformation | Producing correct sentence structures | `--transform` |
| Morphology | Producing correct verb forms | `--conjugate` |
| Dialogue | Responding in conversational context | `--conversation` |
| Speech production | Speaking answers aloud | `--speak` |

These modes can be layered together to progressively increase difficulty and realism.

Example beginner progression:

```
--study
--listen
--listen --match-game
(default typing)
--transform
--conjugate
--conversation
--speak
```

---

## Overview

`linguatrain` does not ship with full courses. Instead, it includes example packs that show you how things work.

The idea is simple:

You write your own packs — words and phrases you actually care about — and the engine drills them in progressively harder ways.

A pack entry looks like this:

```yaml
- id: "017"
  prompt: "Nice to meet you"
  answer:
    - "Hauska tutustua"
  phonetic: "HOWS-kah TOO-toos-too-ah"

- id: "018"
  prompt: "Likewise"
  answer:
    - "Kiitos samoin"
  phonetic: "KEE-tohs SAH-moyn"
```

The `prompt` is what you see.

The `answer` is what you type. 

That’s it.

It can be a single word. 

It can be a full sentence.  

You control the content.

---

## Language Packs Repository

Maintained language packs and localisation files also live in the separate Linguatrain Language Packs repository. Contributions to shared language content should go there.

https://github.com/wbrisett/linguatrain_language_packs

---

## Quick Start

```bash
git clone https://github.com/wbrisett/linguatrain.git
cd linguatrain
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml
```

Once you've cloned the repo, you can run a pack immediately:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml
```

You’ll see something like:

```text
English → Finnish Quiz — 38 word(s) (mode: typing, English→Finnish)
--------------------------------------------------

[8/38]
englanniksi: Likewise
suomeksi:
```

Now you type the answer.

If you get it wrong:

```text
suomeksi: Kiitos
Yritä uudelleen.
suomeksi: Kiitos samoin
✅ Oikein!
   (englanniksi: Likewise)
   (ääntämys: KEE-tohs SAH-moyn)
```

It gives you a second try before marking it wrong.

At the end of a session, you get a summary — and anything you missed is written to a new YAML file so you can practice just those later.

---


---

## 📁 Project Structure

```
linguatrain/
├── bin/              # CLI entry points and utility scripts
├── docs/             # Detailed documentation and specifications
├── localisation/     # UI labels and language pair configurations
├── packs/            # Language learning content (YAML packs)
├── tools/            # Internal utilities (e.g., phonetic processing)
├── linguatrain.rb    # Main application entry point
└── README.md
```

### bin/
Command-line scripts and utilities.

- linguatrain.rb → main CLI launcher  
- validate_pack.rb → validates YAML structure  
- flip_pack.rb → reverses prompt/answer  
- add_finnish_phonetics.rb → enriches packs with phonetics  

---

### docs/
Deep-dive documentation and system design.

Includes:
- YAML schemas (standard, conjugate, transform)  
- phonetic rules  
- Piper / Whisper setup  
- configuration details  

---

### localisation/
Defines UI text and language pair mappings.

Examples:
- en-US_fi-FI.yaml  
- en-US_es-MX.yaml  

---

### packs/
All learning content lives here.

```
packs/
├── fi/         # Finnish packs
├── es/         # Spanish packs
└── templates/  # Starter templates for new packs
```

Each pack is a YAML file with:
- metadata  
- entries  
- optional phonetics  
- optional transforms  

---

### tools/
Internal helper scripts not directly exposed via CLI.

Example:
- finnish_phonetics.rb  

---

### Root Files

- linguatrain.rb → main runtime entry  
- CHANGELOG.md → version history  
- LICENSE / NOTICE → legal  
- README.md → project overview  

---

## Core Concepts

- Pack → YAML-based learning unit  
- Drill Type → standard, conjugate, transform  
- Cue / Step → transform mechanics  
- Phonetics → learner-friendly pronunciation layer  

---


## Reverse the Direction

Want to flip the practice and use Finnish → English instead? Just use `--reverse`.

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --reverse
```

Now it shows:

```text
suomeksi: Kiitos samoin
englanniksi:
```

Same pack. Same content.

Just flipped.

---

## Start in Study Mode (Flashcards)

If you're learning new material, you should start with `--study`:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --study
```

This turns linguatrain into a flashcard flow:

```text
englanniksi: Hi / Hey

(Enter to reveal)

suomeksi: Moi
(ääntämys: MOY)
```

No grading, no pressure, just exposure and repetition.

Best of all, you can combine this with `--reverse` if you want to study in the opposite direction.

---

## Add Hints (Match Game)

Once you're comfortable with the material, simply add light pressure with `--match-game`:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --match-game
```

Now you’ll see hints:

```text
englanniksi: How are you?
Hints:
  - tämä
  - suomen kurssi
  - Mitä kuuluu?
suomeksi:
```

You still have to type the full answer, but now you have hints that narrow the possible answers.

This is especially useful early on when recall is still shaky.

---

### Add Listening (Text-to-Speech)

If you have Piper installed, you can enable audio:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --listen
```

Now the target language is spoken before you answer.

You can stack this with:

- `--match-game`
- `--reverse`
- `--study`
- `--srs`

You can make it as easy or as hard as you like.

---

### Speak Your Answers (Speech Recognition)

Linguatrain can also validate **spoken answers** using the `--speak` option.

In this mode the program:

1. Records your voice
2. Uses **Whisper speech recognition** to transcribe what you said
3. Compares the transcription to the accepted answers

Example:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --speak
```

Example interaction:

```text
English: How are you?

🎤 Speak now...
🎙 Recording (5s window)...

🟡 Close enough
   Heard: Mita kuluu
```

Installation instructions for Whisper are available in:

`docs/whisper-installation.md`

---

### Add Spaced Repetition (Optional)

To enable lightweight spaced repetition tracking:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs
```

The engine will:

- Track what you get right
- Track what you miss
- Schedule reviews automatically

The SRS state is stored locally. 

## How do I limit session length?

If you only want to practice a limited number of items, you simply add that number after your pack path. 

**Example of limited question/answer pairs**

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5
```

Now your session is limited to five items. 

---

## Grammar Practice Modes

Linguatrain also supports structured grammar drills in addition to vocabulary practice.

### Transform Mode (`--transform`)

Transform mode is designed for **sentence transformation exercises** similar to those found in many language textbooks.

In these drills you are given a **context prompt** and a **cue**, and you must transform that cue into a grammatically correct sentence. This is useful for practicing grammatical changes such as:

- positive → negative
- question → statement
- person changes
- verb form changes

Many languages require words to change form depending on what you are expressing (for example verb conjugation or negation). Transform mode focuses on practicing those changes in full sentences.

You are given:

- a prompt (context question)
- a cue
- one or more required transformations

Example:

```bash
ruby bin/linguatrain.rb packs/fi/transform/sm_transform_kpt.yaml all --transform
```
You must transform the cue into a complete sentence using the requested grammatical form. Linguatrain does not perform automatic translation — you must produce the correct sentence.

Example transformation exercise:

```text
Prompt: What does Paula do on the weekend?
Cue: play the piano

Positive:
Paula plays the piano.

Negative:
Paula does not play the piano.
```

Example session using Finnish:
```text
Mitä Paula tekee viikonloppuna?

[ soittaa pianoa ]

Anna myönteinen vastaus:
> Paula soittaa pianoa.

Anna kielteinen vastaus:
> Paula ei soita pianoa.
```


The YAML format for transform packs is documented here:

`docs/transform-yaml-structure.md`


---

### Conjugation Mode (`--conjugate`)

Conjugation mode drills **verb morphology** by combining a person and a verb lemma.

Example:

```bash
ruby bin/linguatrain.rb packs/fi/conjugation/sm_conjugation_kpt.yaml all --conjugate
```

Example session:

```text
Conjugate the verb.

[ minä ]
[ lukea ]

Anna myönteinen muoto:
> Minä luen
```

Optional polarity drills:

Positive only:

```
--conjugate
```

Negative only:

```
--conjugate --negative
```

Both forms:

```
--conjugate --both
```

The YAML structure for conjugation packs is documented in:

`docs/conjugate-yaml-structure.md`

---

### Conversation Mode (`--conversation`)

Conversation mode allows Linguatrain to simulate short dialogues.

Instead of isolated prompts, you respond to conversational exchanges.

Example:

```bash
ruby bin/linguatrain.rb packs/fi/conversations/greetings.yaml --conversation
```

Example interaction:

```text
Hei!

> Hei!

Mitä kuuluu?

> Hyvää, kiitos.
```

This mode is useful for practicing **real conversational responses** rather than simple translations.

---

## Getting Started

Let’s walk through the minimal setup.

### 1. Install Ruby

You need Ruby 3.x or later.

Check:

```bash
ruby -v
```

If you need to install it, use your preferred version manager (`rbenv`, `RVM`, `asdf`) or your system package manager.

No additional gems are required as everything runs on the Ruby standard library.

---

### 2. Clone the Repository

```bash
git clone https://github.com/wbrisett/linguatrain.git
cd linguatrain
```

Run a pack immediately:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml
```

That’s enough to get started, although if you don't know Finnish, probably best to use: 

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --study
```

---

### 3. Understanding the Folder Layout

Here’s what matters:

```text
linguatrain/
├── bin/              # CLI and helper utilities
├── packs/            # Your YAML packs live here
├── localisation/     # Optional UI language files
├── docs/             # YAML spec and deeper documentation
└── README.md
```

The important directory is:

```text
packs/
```

That’s where your study material lives.

You can organize packs however you like. As a best practice, use two-letter language codes:

```text
packs/
  fi/
  es/
  de/
```

Starter pack templates are maintained in both this repository and the Linguatrain Language Packs repository. Shared language-pack files are also maintained in the Linguatrain Language Packs repository.

---

### 4. Creating Your Own Pack

A minimal pack looks like this:

```yaml
metadata:
  id: "my_first_pack"
  version: 1

entries:
  - id: "001"
    prompt: "Good morning"
    answer:
      - "Hyvää huomenta"
```

**Important:** Some prompts may have multiple valid answers.  
If multiple answers are defined in the YAML, any of them will be accepted as correct.

Save it anywhere and run:

```bash
ruby bin/linguatrain.rb my_pack.yaml
```

That’s all you need. 

Without localisation of the UI elements it looks like this: 

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 

Source → Target Quiz — 28 word(s) (mode: typing, Source→Target)
--------------------------------------------------

[1/28]
Prompt: Pretty good. / Quite good. / Doing pretty well.
Answer: 
```

#### Customising the UI (localisation) 

Localisation files define UI labels and TTS behavior for a language pair. Unlike study packs, these files belong in the `localisation/` directory rather than `packs/`.

A starter localisation template is provided so you can create new language-pair UI files consistently.

Recommended naming:

```text
localisation/
  en-US_fi-FI.yaml
  en-US_es-MX.yaml
```

The template should be renamed to match the source and target language pair. For example:

```text
en-US_fi-FI.yaml
```

Use this template as a starting point for:
- language metadata
- TTS formatting
- quiz UI labels
- optional conjugate and transform drill labels

---

### 5. Optional Configuration

You do **not** need configuration to run `linguatrain`.

However, if you want:

- Default localisation
- Piper integration
- Custom audio player
- Global TTS templates

You should create a config file.

### Default locations

**Linux / macOS**

```text
~/.config/linguatrain/config.yaml
```

**Windows**

```text
%APPDATA%\linguatrain\config.yaml
```

Create the directory if it doesn’t exist.

Example:

```yaml
runtime:
  audio_player: "afplay"

piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"

whisper:
  model: "base"
  language: "fi"

localisation: "localisation/en-US_fi-FI.yaml"
```

All configuration sections are optional. 

If omitted, English defaults are used.

### Whisper configuration (for `--speak`)

If you want to use speech recognition, configure Whisper:

```yaml
whisper:
  model: "base"
  language: "fi"
```

The model name corresponds to the Whisper model installed on your system.
Common choices are:

- tiny
- base
- small

See [Whisper installation](docs/whisper-installation.md) for installation details.

---

That’s it.

You can now:

- Run packs
- Write your own content
- Flip directions
- Add hints
- Enable listening
- Enable spaced repetition

Everything else in this `/docs` directory explains deeper mechanics and advanced options.

Start simple. Add complexity when you need it.

------------------------------------------------------------------------

## Documentation

Additional documentation for configuration, Piper setup, and language pack creation
is available in the [`docs`](docs/) directory.

Key guides include:

- [Basic Setup](docs/basic_setup.md)
- [Piper Setup](docs/piper-setup.md)
- [Whisper / Speech Setup](docs/whisper-installation.md)
- [Configuration File](docs/config-file-setup.md)
- [YAML Pack Setup](docs/yaml-pack-setup.md)
- [Transform YAML Format](docs/transform-yaml-structure.md)
- [Conjugation YAML Format](docs/conjugate-yaml-structure.md)
- [Localisation Template Setup](docs/localisation-template-setup.md)
- [Command Options](docs/options-details.md)
- [Learner Phonetic Rules](docs/linguatrain_learner_phonetic_rules.md)

------------------------------------------------------------------------

# System Architecture

``` mermaid
flowchart TD
  A["YAML pack"] --> B["Loader / Normalizer"]
  B --> C["Pack type / drill type"]
  C --> D{"Mode selected?"}

  D -- study --> E["Study flow"]
  D -- typing / match-game / listen --> F["Standard quiz flow"]
  D -- transform --> G["Transform flow"]
  D -- conjugate --> H["Conjugation flow"]
  D -- conversation --> I["Conversation flow"]
  D -- speak --> J["Speech flow"]

  E --> E1["Display entry"]
  E1 --> E2{"Listening enabled?"}
  E2 -- yes --> E3["Piper speak target"]
  E2 -- no --> E4["Reveal only"]
  E3 --> E5["Next entry"]
  E4 --> E5

  F --> F1["Select words"]
  F1 --> F2{"Listening enabled?"}
  F2 -- yes --> F3["Piper speak target"]
  F2 -- no --> F4["Show prompt"]
  F3 --> F5["Prompt user"]
  F4 --> F5
  F5 --> F6["Validate typed input"]
  F6 --> F7["Score attempts"]
  F7 --> F8{"SRS enabled?"}
  F8 -- yes --> F9["Update SRS state"]
  F8 -- no --> F10["Skip SRS"]
  F9 --> F11{"Misses?"}
  F10 --> F11
  F11 -- yes --> F12["Write missed pack"]
  F11 -- no --> F13["Finish session"]

  G --> G1["Flatten transform items"]
  G1 --> G2["Show prompt + cue"]
  G2 --> G3["Run ordered transform steps"]
  G3 --> G4["Validate answers"]
  G4 --> G5["Report missed steps"]

  H --> H1["Flatten conjugation items"]
  H1 --> H2["Show person + lemma"]
  H2 --> H3["Run positive / negative / both"]
  H3 --> H4["Validate answers"]
  H4 --> H5["Report missed items"]

  I --> I1["Run conversation sequence"]
  I1 --> I2{"Listening enabled?"}
  I2 -- yes --> I3["Piper speak line"]
  I2 -- no --> I4["Show line only"]
  I3 --> I5["Advance / replay"]
  I4 --> I5

  J --> J1["Record speech"]
  J1 --> J2["Whisper transcription"]
  J2 --> J3["Compare transcript to answers"]
  J3 --> J4["Score attempts"]
  J4 --> J5{"SRS enabled?"}
  J5 -- yes --> J6["Update SRS state"]
  J5 -- no --> J7["Skip SRS"]
```
------------------------------------------------------------------------


## License

Copyright © 2026 Wayne F. Brissette

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

See the LICENSE file for details.

[LICENSE](LICENSE)
</file>
