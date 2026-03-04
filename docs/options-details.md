# Complete Options Reference

| Flag | Purpose | Default |
|---|---|---:|
| `--study` | Enable study mode | off |
| `--reverse` | Swap direction | off |
| `--match-game` | Add 3 hints | off |
| `--match-options MODE` | Control hint source (`auto`, `source`, `target`) | `auto` |
| `--listen` | Speak target (source shown) | off |
| `--listen-no-source` | Speak target (source hidden) | off |
| `--listen-no-english` | Alias for `--listen-no-source` | off |
| `--lenient-umlauts` | Allow simplified characters (`a`→`ä`, `o`→`ö`) | off |
| `--tts-variant written\|spoken` | Choose what Piper speaks | `written` |
| `--answer-variant written\|spoken\|either` | Choose which answers are accepted | `written` |
| `--show-variants` | Display written and spoken variants together | off |
| `--srs` | Enable spaced repetition | off |
| `--due` | With SRS, quiz only due items | off |
| `--new N` | With SRS, include up to N new items | `5` |
| `--reset-srs` | Reset scheduling state | off |
| `--srs-file PATH` | Override SRS state file path | pack-derived |


  ----------------------------------------------------------------------------------

# Mode Layering (How the Flags Work Together)

With the exception of study mode, nearly all options can be used together. Study mode is not scored, so flags like `--srs` are not valid.

Each of the modes are described in this section. 

## Study Mode (`--study`)

Study mode disables scoring and validation and turns the session into
a guided review.

Instead of:

    prompt → validate → score

Study mode behaves like:

    show → reveal → optional audio → next

This is ideal for:

- Learning new vocabulary before testing
- Passive exposure and repetition
- Reviewing difficult material without pressure

Example:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --study         

English → Finnish Quiz — 28 item(s) (mode: study, English→Finnish)
--------------------------------------------------

[1/28]

englanniksi: Now this is under control. / We have this under control now.

                    (Enter to reveal; q to quit): 

suomeksi: Nyt tämä on hallinnassa.
(🗣 ääntämys: Newt TAH-muh on HAH-leen-nahs-sah)

(Enter for next; q to quit): 

```
You may combine study mode with:
-	`--listen`
-	`--reverse`

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --study --listen
```

In study mode:
-	Answers are not graded
-	SRS is not updated
-	Missed packs are not generated

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

Target language is spoken using Piper.

Source remains visible.

``` bash
ruby bin/linguatrain.rb pack.yaml 5 --listen
```

Listening + reverse:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5 --reverse --listen
```

------------------------------------------------------------------------

## Listening Hard Mode (`--listen-no-source`)

Target spoken. Source hidden.

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5 --listen-no-source
```

Alias: `--listen-no-english`

------------------------------------------------------------------------

## Listening + Match-Game (Recommended Beginner Mode)

This combination layers listening with guided recall.\
The learner hears the target language first, sees constrained hints, and
must still type the full answer.

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5 --listen --match-game
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

### `--lenient-umlauts`

**Warning:** This option is mainly for very early practice. In real Finnish, umlauts change meaning, so prefer learning the correct spelling as soon as you can.

Allows `a` for `ä` and `o` for `ö` (useful early on). If you use the
lenient spelling, you still get credit, but it reminds you that umlauts
matter.

------------------------------------------------------------------------

# `--match-options MODE`

`--match-options` is a fine-tuning control for edge cases, not a required setting for normal use.

## When should you use --match-options?

In most cases, you do not need to set this option. The default (auto) works well for typical packs and general drilling.

You should consider using --match-options only when your pack contains:

- Many entries with the same source prompt (for example, multiple translations of “Hi.” or “How are you?”)
- Many near-synonymous target answers
- Clusters of similar phrases where hints feel either too easy or unintentionally revealing
- Large community-contributed packs where structure and consistency vary

If match-game starts to feel “too obvious” or “too confusing,” that’s the signal to experiment with this flag.

In short:

- If hints feel too easy → try --match-options source
- If hints feel unhelpful or misleading → try --match-options target
- Otherwise → leave it on auto

For most people and most packs, auto is the correct setting.

— Real Examples Using `fi_everyday_phrases.yaml`

The examples in this readme come from the included finnish pack:
/packs/fi/finnish_everyday_phrases.yaml

This pack contains useful edge cases for match-game behavior:

- Multiple greetings ("Hi." → *Hei.*, *Moi.*)
- Multiple “How are you?” variants
- Near-synonymous phrases
- Formal vs informal constructions

---

# 1️⃣ Default: `--match-options auto`

```bash
ruby bin/linguatrain.rb /packs/fi/finnish_everyday_phrases.yaml 5 --match-game
```

### Behavior

Hints are drawn from the side you are expected to type.

## Example (Source → Target)

Prompt:

```
How are you?
```

Possible hints:

```
  - Mitä kuuluu?
  - Kuinka voit?
  - Hyvin, kiitos.
```

Why this works:

- Both entries 020 and 021 share the same English prompt.
- The distractor is a plausible conversational response.
- You still must type the full Finnish answer.

This feels production-oriented while remaining supportive.

---

# 2️⃣ Force Hints from `source`

```bash
ruby bin/linguatrain.rb /packs/fi/finnish_everyday_phrases.yaml 5 --match-game --match-options source
```

Hints are always drawn from the English prompt side.

## Example (Reverse Mode)

```bash
ruby bin/linguatrain.rb /packs/fi/finnish_everyday_phrases.yaml 5 --reverse --match-game --match-options source
```

You see:

```
Hyvä päätös.
```

Hints:

```
  - Good decision.
  - Good thing.
  - Good day.
```

Why this matters:

- Entries 006 and 009 both begin with “Hyvä …”
- Seeing similar English options forces semantic discrimination
- Prevents simply recognizing Finnish shape patterns

This mode strengthens meaning recall rather than pattern recognition.

---

# 3️⃣ Force Hints from `target`

```bash
ruby bin/linguatrain.rb /packs/fi/finnish_everyday_phrases.yaml 5 --match-game --match-options target
```

Hints always come from the Finnish answer side.

## Example (Greetings cluster)

Prompt:

```
Hi.
```

Possible hints:

```
  - Hei.
  - Moi.
  - Hyvää päivää.
```

Relevant entries:

- 014 → Hei.
- 018 → Moi.
- 015 → Hyvää päivää.

Why this is powerful:

- All are plausible greetings.
- Forces you to recall the exact register (casual vs formal).
- Reduces accidental cueing from English synonyms.

This mode is ideal for:

- High-overlap vocabulary
- Register drills
- Early fluency building

---

# 4️⃣ Listening + Match-Game + Target Hints

```bash
ruby bin/linguatrain.rb /packs/fi/finnish_everyday_phrases.yaml 5 --listen --match-game --match-options target
```

You hear:

```
(Suomeksi: Mitä kuuluu?)
```

Visible hints:

```
  - Mitä kuuluu?
  - Kuinka voit?
  - Hyvin, kiitos.
```

Why this combination works:

- Audio first → recognition
- Constrained Finnish hint list → reduces overload
- Full typing required → active recall
- Replay available

This is an ideal beginner-to-intermediate bridge mode.

---

# 5️⃣ Where `--match-options` Makes the Biggest Difference

### Case A: Duplicate English Prompts

Entries 020 and 021:

```
"How are you?"
→ Mitä kuuluu?
→ Kuinka voit?
```

Using `source` hints would not help here (same English string).
Using `target` hints makes the contrast clear.

---

### Case B: Greeting Density

Your pack contains:

- Hei.
- Moi.
- Moi moi.
- Hyvää päivää.
- Hyvästi.

Target-side hints create meaningful discrimination.
Source-side hints would collapse to similar English meanings.

---

# Practical Guidance

| Mode | Best Use |
|------|----------|
| auto | General drilling |
| source | Meaning precision |
| target | Register / production precision |
| target + listen | Recognition → recall bridge |
| source + reverse | Hard semantic discrimination |

---

# Summary

`--match-options` does not change validation logic.
It changes *how cognitive load is shaped* during match-game.

In packs like `fi_everyday_phrases.yaml`, where:

- greetings overlap,
- English prompts duplicate,
- register matters,

explicit control over hint origin meaningfully changes learning outcomes.

---

## Stacking Example

Full stacked drill:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 10 --reverse --listen --match-game --srs
```

Study with listening (no scoring or SRS updates):

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 10 --study --listen
```

Each flag layers behavior independently.

------------------------------------------------------------------------


# Listening & Spoken Variants

By default:

-   `--listen` speaks the canonical `answer` form
-   Only `answer` is accepted as correct

The engine does not automatically transform written forms into spoken variants.

Piper reads exactly what is stored.

## Speak colloquial forms

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 10 --listen --tts-variant spoken
```

If `spoken` exists, it is spoken.\
If missing, it falls back to `answer`.

## Practice spoken production

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 10 --listen --tts-variant spoken --answer-variant spoken
```

## Accept either form

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5 --answer-variant either
```

## Show both variants (display only)

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml 5 --show-variants
```

------------------------------------------------------------------------

# About the Spaced Repetition System (SRS)

Inspired by SM‑2 (Anki / SuperMemo).

**Note**: The implementation is a simplified SRS system and not as complex as a tool like Anki.

Each word stores:

-   `reps`
-   `interval_days`
-   `ease`
-   `due_at`
-   `lapses`

Performance rules:

-   Correct 1st try → larger interval growth
-   Correct 2nd try → smaller growth
-   Failure → reset + ~10 minute retry

## Storage Location

    ~/.config/linguatrain/srs/<pack>.yaml

Override:

    --srs-file PATH

## Usage

Enable:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs
```

Due only:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs --due
```

Limit new words:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs --new 10
```

Reset scheduling:

``` bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml all --srs --reset-srs
```

**Important**: When --srs is enabled, SRS state is updated as each entry is graded and is saved on exit. If the session ends early (quit, interrupt, or error), progress up to the last completed item is preserved.

------------------------------------------------------------------------

# Missed Pack Generation

At the end of a session, missed words are written to a timestamped YAML
file containing:

-   Original metadata
-   Generation details
-   Session stats
-   Failed entries only

This allows focused follow‑up drilling.

------------------------------------------------------------------------

