# linguatrain

`linguatrain` is a config-driven command-line vocabulary and phrase
trainer.

-   Packs are defined in YAML.
-   Source and target languages are defined per-pack.
-   Multiple drill modes are supported (typing, reverse, match-game,
    listening).
-   Listening mode uses Piper TTS (optional).
-   SRS scheduling is built-in (optional).

The tool is fully language-generic. All UI labels, language names, and
TTS carrier phrases are defined in pack metadata and user configuration.

------------------------------------------------------------------------

## Introduction

A typical session works like this:

1.  Load a YAML pack
2.  Normalize entries
3.  Select mode and direction (source→target or target→source)
4.  Optionally speak the target language via Piper
5.  Prompt → validate → score attempts
6.  Optionally update SRS state
7.  Optionally write a missed-entries pack

SRS and missed-entry generation are independent features.

------------------------------------------------------------------------

# YAML Pack Schema

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
```

## entries

``` yaml
entries:
  - id: "001"
    prompt: "How are you?"
    alternate_prompts:
      - "How's it going?"
      - "How are things?"
      - "How have you been?"
    answer:
      - "Mitä kuuluu?"
      - "Kuinka voit?"
    phonetic: "MI-tah KOO-loo / KOO-een-kah voyt"
```

------------------------------------------------------------------------

# Modes

## Modes Overview

| Mode / Flag | Direction | Audio | Hints | Typical Use |
|-------------|-----------|-------|-------|-------------|
| *(default)* | Source → Target | No | No | Basic typing practice |
| `--reverse` | Target → Source | No | No | Active recall of meanings |
| `--match-game` | Source → Target (or reverse) | No | 3 hints | Guided recall |
| `--listen` | Source → Target | Yes | Optional | Listening + typing |
| `--listen-no-source` | Target only (audio) | Yes | Optional | Pure listening comprehension |
| `--reverse --match-game` | Target → Source | No | 3 hints | Guided translation |
| `--reverse --listen` | Target → Source | Yes | No | Hear target, translate |
| `--reverse --listen --match-game` | Target → Source | Yes | 3 hints | Full stacked drill |

Modes may be stacked. Flags combine to layer behavior on top of the base typing loop.

## Mode Layering Explained

All modes build on the same base loop:

prompt → validate → score

Flags layer additional behavior on top of that loop.  
Stacking modes increases difficulty without changing the core logic.

---

### Match-game (Source → Target)

Adds three distractor hints, but you still type the full answer.

```bash
ruby bin/linguatrain.rb pack.yaml 3 --match-game
```
Example output:

```text
English → Finnish Quiz — 3 word(s) (mode: match-game)
--------------------------------------------------

[1/3]
englanniksi: Good decision.
Hints:
  - Hyvä päätös.
  - Kiitos.
  - Selvä.
suomeksi: hyvä päätös
✅ Oikein!
   (ääntämys: HY-vah PAE-tuhs)
```
What changed:

-	Three target-language distractors are shown
-	You still type the full answer (not multiple choice)
-	Validation and scoring are unchanged

### Match-game Reversed (Target → Source)

Now stack --reverse and --match-game.

```bash
ruby bin/linguatrain.rb pack.yaml 3 --reverse --match-game
```
Example output:
```text
Finnish → English Quiz — 3 word(s) (mode: match-game, Finnish→English)
--------------------------------------------------

[1/3]
suomeksi: Hyvä päätös.
Hints:
  - Thank you.
  - Good decision.
  - Clear.
englanniksi: good decision
✅ Oikein!

```
What changed:
-	Direction swapped (target shown first)
-	Hints remain in the target language
-	You must translate mentally before typing
-	Same scoring and attempt logic underneath

## Options Summary

  ------------------------------------------------------------------------
  Flag                     Purpose         Works With        Default
  ------------------------ --------------- ----------------- -------------
  `--reverse`              Swap            typing,           off
                           source/target   match-game,       
                           direction       listen            

  `--match-game`           Guided recall   typing, reverse,  off
                           with 3 hints    listen            

  `--match-options MODE`   Control hint    reverse +         auto
                           display in      match-game        
                           reverse                           
                           match-game                        

  `--listen`               Speak target    typing,           off
                           (source shown)  match-game        

  `--listen-no-source`     Speak target    typing,           off
                           (source hidden) match-game        

  `--lenient-umlauts`      Allow           typing only       off
                           simplified                        
                           characters                        

  `--srs`                  Enable spaced   any mode          off
                           repetition                        
  ------------------------------------------------------------------------

------------------------------------------------------------------------

## Typing Mode (default)

Source shown → type target.

``` bash
ruby bin/linguatrain.rb pack.yaml 3
```

Example output:

``` text
English → Finnish Quiz — 3 word(s) (mode: typing)
--------------------------------------------------

[1/3]
englanniksi: How are you?
suomeksi: mitä kuuluu
✅ Oikein!
   (ääntämys: MI-tah KOO-loo)
```

------------------------------------------------------------------------

## Reverse Mode (`--reverse`)

Target shown → type source.

``` bash
ruby bin/linguatrain.rb pack.yaml 3 --reverse
```

Example output:

``` text
Finnish → English Quiz — 3 word(s) (mode: typing, Finnish→English)
--------------------------------------------------

[1/3]
suomeksi: Kiitos.
englanniksi: Thank you
✅ Oikein!
```

------------------------------------------------------------------------

## Match-game Mode (`--match-game`)

Guided recall with three hints (you still type the answer).

``` bash
ruby bin/linguatrain.rb pack.yaml 3 --match-game
```

Example output:

``` text
English → Finnish Quiz — 3 word(s) (mode: match-game)
--------------------------------------------------

[1/3]
englanniksi: Good thing.
Hints:
  - Hyvä juttu.
  - Selvä.
  - Kiitos.
suomeksi: hyvä juttu
✅ Oikein!
```

------------------------------------------------------------------------

## Listening Mode (`--listen`)

Target spoken via Piper. Source is shown.

``` bash
ruby bin/linguatrain.rb pack.yaml 3 --listen
```

Example output:

``` text
English → Finnish Quiz — 3 word(s) (mode: typing, listen)
--------------------------------------------------

[1/3]
Audible Finnish: (listening…)
englanniksi: How are you?
(Kirjoita 'r' toistaaksesi äänen)
suomeksi: mitä kuuluu
✅ Oikein!
```

------------------------------------------------------------------------

## Listening Hard Mode (`--listen-no-source`)

Target spoken via Piper. Source hidden.

``` bash
ruby bin/linguatrain.rb pack.yaml 3 --listen-no-source
```

Example output:

``` text
English → Finnish Quiz — 3 word(s) (mode: typing, listen-no-source)
--------------------------------------------------

[1/3]
Audible Finnish: (listening…)
(Kirjoita 'r' toistaaksesi äänen)
suomeksi: kiitos
✅ Oikein!
```

------------------------------------------------------------------------

# System Architecture

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
  J -- yes --> K["Update SRS state (~/.config/linguatrain/srs/<pack>.yaml)"]
  J -- no --> L["Skip SRS"]
  K --> M{"Misses?"}
  L --> M
  M -- yes --> N["Write missed pack"]
  M -- no --> O["Finish session"]
```

------------------------------------------------------------------------

# License

This project is licensed under the Apache License 2.0. See `LICENSE` for
details.
