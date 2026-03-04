# linguatrain

![Ruby](https://img.shields.io/badge/Ruby-3.x-red)
![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![CLI](https://img.shields.io/badge/interface-CLI-green)

`linguatrain` is a simple, flexible Ruby command-line language trainer powered by YAML files.

You bring the vocabulary.

You choose the difficulty.

It runs in your terminal.

At its core:

- You define language pairs using YAML 'packs'
- You practice in different modes (study, typing, match-game, listening)
- You can optionally enable Text-to-Speech and spaced repetition
- You can localize the UI labels to any language you like

**Example session:**

```text
English → Finnish Quiz — 5 word(s)

[1/5]
englanniksi: How are you?
suomeksi:
```
  
It's a structured language practice application that does exactly what you tell it to.

---

## Overview

`linguatrain` does not ship with full courses. Instead, it ships with example packs (mostly Finnish) that show you how things work.

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

### Add Spaced Repetition (Optional)

To enable lightweight spaced repetition tracking:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs
```

The engine will:

- Track what you get right
- Track what you miss
- Schedule reviews automatically

State is stored locally. 

## How do I limit session length?

If you only want to practice a limited number of items, you simply add that number after your pack path. 

**Example of limited question/answer pairs**

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5
```

Now your session is limited to five items. 

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

There’s also a `templates/` folder with starter pack YAML examples.

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

localisation: "localisation/en-US_fi-FI.yaml"
```

All configuration sections are optional.

If omitted, English defaults are used.

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
- [Configuration File](docs/config-file-setup.md)
- [YAML Pack Setup](docs/yaml-pack-setup.md)
- [Localisation Template Setup](docs/localisation-template-setup.md)
- [Command Options](docs/options-details.md)
- [Learner Phonetic Rules](docs/linguatrain_learner_phonetic_rules.md)
- 

------------------------------------------------------------------------

# System Architecture

``` mermaid
flowchart TD
  A["YAML pack"] --> B["Loader / Normalizer"]
  B --> C["Mode & Direction"]
  C --> D{"Study mode?"}
  D -- yes --> E["Display entry (no scoring)"]
  E --> F{"Listening enabled?"}
  F -- yes --> G["Piper speak target"]
  F -- no --> H["Skip audio"]
  G --> I["Next entry"]
  H --> I
  D -- no --> J{"Listening enabled?"}
  J -- yes --> K["Piper speak target"]
  J -- no --> L["Skip audio"]
  K --> M["Prompt user"]
  L --> M
  M --> N["Validate input"]
  N --> O["Score attempts"]
  O --> P{"SRS enabled?"}
  P -- yes --> Q["Update SRS state"]
  P -- no --> R["Skip SRS"]
  Q --> S{"Misses?"}
  R --> S
  S -- yes --> T["Write missed pack"]
  S -- no --> U["Finish session"]
```
------------------------------------------------------------------------


## License

Copyright © 2026 Wayne F. Brissette

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

See the LICENSE file for details.

