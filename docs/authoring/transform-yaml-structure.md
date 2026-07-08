# Transform YAML Structure

## Purpose

Transform packs define grammar-transformation drills for Linguatrain.

These packs are used with `--transform` and are designed for exercises where the learner is given:

- a prompt or context sentence
- optional notes, such as an English translation or grammar hint
- a cue
- one or more ordered transformation steps
- one or more accepted answers for each step

Transform packs are useful for workbook-style grammar practice, especially when the learner must actively rewrite or produce a sentence.

Common use cases include:

- positive → negative
- direct → polite/conditional
- infinitive-in-parentheses → conjugated sentence
- present → past
- singular → plural
- statement → question
- case or suffix practice
- multi-step grammar transformations under the same prompt

The transform engine does not infer grammar. The YAML declares the expected answer. Linguatrain displays the prompt, cue, optional notes, and instruction, then checks the learner's answer.

---

## Design principle

Transform mode is a general **sentence manipulation** engine.

The engine does not know what Finnish conditional, KPT, verb type, case, or politeness means. It only knows:

```yaml
prompt: ...
notes: ...
cue: ...
transform: ...
answer: ...
```

This keeps the engine language-agnostic.

For Finnish, this means the same transform system can support:

- `transform: positive`
- `transform: negative`
- `transform: conditional`
- `transform: present`
- `transform: past`
- `transform: question`

For other languages, the same structure could support:

- Spanish subjunctive
- German case changes
- French gender agreement
- Japanese politeness levels
- English tense transformations

The YAML controls all grammar behavior. The Linguatrain engine simply controls the flow of the drill itself.

---

## Top-level structure

A transform pack uses this general structure:

```yaml
metadata:
  id: "pack_id"
  name: "Human-readable name"
  version: "1.0"
  schema_version: 1
  drill_type: "transform"
  shuffle_cues: true

entries:
  - id: "entry_id"
    prompt: "Mitä Paula tekee viikonloppuna?"
    notes: "What does Paula do on the weekend?"
    cues:
      - cue: "soittaa pianoa"
        steps:
          - transform: "positive"
            answer:
              - "Paula soittaa pianoa"
          - transform: "negative"
            answer:
              - "Paula ei soita pianoa"
```

---

## Required top-level keys

### `metadata`

Metadata describing the pack.

Required fields:

- `id`
- `drill_type: transform`

Recommended fields:

- `name`
- `version`
- `schema_version`
- `shuffle_cues`
- `description`

Example:

```yaml
metadata:
  id: "fi_conditional_politeness_transform"
  name: "Finnish Conditional Politeness Transform"
  version: "1.0"
  schema_version: 1
  drill_type: "transform"
  shuffle_cues: false
```

### `entries`

A list of transform entries.

Each entry represents one shared prompt or context and one or more cues that will be drilled under that prompt.

---

## Entry structure

Each entry may include:

- `id`
- `prompt`
- `notes`
- `cues`

Example:

```yaml
- id: "001"
  prompt: "Haluan kahvia."
  notes: "I want coffee."
  cues:
    - cue: "Make this more polite."
      steps:
        - transform: "conditional"
          answer:
            - "Haluaisin kahvia."
```

### `id`

A unique identifier for the entry.

Example:

```yaml
id: "001"
```

### `prompt`

The shared sentence, question, context, or instruction shown to the learner.

Examples:

```yaml
prompt: "Mitä Paula tekee viikonloppuna?"
```

```yaml
prompt: "Haluan kahvia."
```

```yaml
prompt: "Herätyskello (soida) aamulla kello 7."
```

### `notes`

Optional learner-facing notes shown under the prompt.

This is useful for:

- English translations
- grammar hints
- literal meanings
- cultural notes
- teacher comments

Example:

```yaml
prompt: "Haluan kahvia."
notes: "I want coffee."
```

Terminal output:

```text
Haluan kahvia.
I want coffee.

[ Make this more polite. ]

Conditional:
> Haluaisin kahvia.
✅ Oikein!
```

Notes are controlled by localisation/UI configuration:

```yaml
ui:
  show_notes: true
```

To hide notes globally:

```yaml
ui:
  show_notes: false
```

If `show_notes` is omitted, the default is `true`.

### `cues`

A list of cue objects associated with the prompt.

Each cue becomes a drill item under the shared prompt.

---

## Cue structure

Each cue should include:

- `cue`
- `steps`

Example:

```yaml
- cue: "lähteä matkalle"
  steps:
    - transform: "positive"
      answer:
        - "Paula lähtee matkalle"
    - transform: "negative"
      answer:
        - "Paula ei lähde matkalle"
```

### `cue`

The lexical, semantic, or grammatical cue the learner should use.

Examples:

```yaml
cue: "soittaa pianoa"
cue: "lähteä matkalle"
cue: "Make this more polite."
cue: "Conjugate the verb(s) in parentheses correctly."
cue: "Use the conditional."
```

A cue does not need to be a single word. For workbook-style exercises, it can be an instruction.

---

## Step structure

Each step should include:

- `transform`
- `answer`

Example:

```yaml
- transform: "positive"
  answer:
    - "Paula lähtee matkalle"

- transform: "negative"
  answer:
    - "Paula ei lähde matkalle"
```

### `transform`

A short transformation identifier used by the CLI to select the correct instruction text.

Common values:

- `positive`
- `negative`
- `conditional`
- `present`
- `past`
- `question`

The transform identifier is not hardcoded grammar logic. It maps to localisation keys.

For example:

```yaml
transform: "conditional"
```

uses this localisation key:

```yaml
ui:
  transform_conditional_instruction: "Muuta lause konditionaaliin:"
```

If no localisation key exists, Linguatrain falls back to a simple generated label:

```text
Conditional:
```

### Recommended transform identifiers

Use short, stable identifiers.

Recommended:

```yaml
transform: "conditional"
transform: "present"
transform: "negative"
```

Avoid overly specific identifiers unless needed:

```yaml
transform: "make_this_more_polite_using_the_finnish_conditional"
```

The `cue` can carry the longer learner-facing instruction.

### `answer`

A single accepted answer or a list of accepted answers for that step.

Use an array when more than one response should be accepted.

Example:

```yaml
answer:
  - "Paula lähtee matkalle"
  - "Hän lähtee matkalle"
```

While answers may include punctuation, it is not required. The matching routine behaves the same with or without punctuation.

For example, if the YAML answer is:

`I want coffee.`

then both of the following are accepted as correct:

- `I want coffee.`
- `I want coffee`

---

## Multiple accepted answers

Use arrays whenever the learner may reasonably produce more than one correct response.

Example:

```yaml
- transform: "negative"
  answer:
    - "Paula ei soita pianoa"
    - "Hän ei soita pianoa"
```

This is useful when:

- a named subject and pronoun are both acceptable
- word order can vary
- both formal and spoken variants are acceptable
- punctuation should not matter
- multiple natural translations exist

---

## Example: positive and negative drill

```yaml
metadata:
  id: "sm2_transform_kpt"
  name: "Suomen Mestari 2 — Transform Drills"
  version: "1.0"
  schema_version: 1
  drill_type: "transform"
  shuffle_cues: true

entries:
  - id: "001"
    prompt: "Mitä Paula tekee viikonloppuna?"
    notes: "What does Paula do on the weekend?"
    cues:
      - cue: "soittaa pianoa"
        steps:
          - transform: "positive"
            answer:
              - "Paula soittaa pianoa"
              - "Hän soittaa pianoa"
          - transform: "negative"
            answer:
              - "Paula ei soita pianoa"
              - "Hän ei soita pianoa"
```

Terminal flow:

```text
Mitä Paula tekee viikonloppuna?
What does Paula do on the weekend?

[ soittaa pianoa ]

Positive:
> Paula soittaa pianoa
✅ Oikein!

Negative:
> Paula ei soita pianoa
✅ Oikein!
```

---

## Example: Finnish conditional politeness

This pattern is useful when practicing Finnish politeness through the conditional `-isi-` form.

```yaml
metadata:
  id: "fi_conditional_politeness_transform"
  name: "Finnish Conditional Politeness Transform"
  version: "1.0"
  schema_version: 1
  drill_type: "transform"
  shuffle_cues: false

entries:
  - id: "001"
    prompt: "Haluan kahvia."
    notes: "I want coffee."
    cues:
      - cue: "Make this more polite."
        steps:
          - transform: "conditional"
            answer:
              - "Haluaisin kahvia."

  - id: "002"
    prompt: "Otan teetä."
    notes: "I will take tea."
    cues:
      - cue: "Make this more polite."
        steps:
          - transform: "conditional"
            answer:
              - "Ottaisin teetä."
```

Suggested localisation:

```yaml
ui:
  transform_conditional_instruction: "Muuta lause konditionaaliin:"
```

Without localisation, the fallback display is:

```text
Conditional:
```

---

## Example: worksheet-style present-tense conjugation

This is useful for teacher handouts where verbs appear in parentheses.

```yaml
metadata:
  id: "fi_yksi_tavallinen_paiva_transform"
  name: "Yksi tavallinen päivä — Present-Tense Sentence Transform"
  version: "1.0"
  schema_version: 1
  drill_type: "transform"
  shuffle_cues: false

entries:
  - id: "001"
    prompt: "Herätyskello (soida) aamulla kello 7."
    notes: "The alarm clock rings in the morning at 7."
    cues:
      - cue: "Conjugate the verb in parentheses correctly."
        steps:
          - transform: "present"
            answer:
              - "Herätyskello soi aamulla kello 7."

  - id: "002"
    prompt: "Minä (mennä) kurssille bussilla."
    notes: "I go to the course by bus."
    cues:
      - cue: "Conjugate the verb in parentheses correctly."
        steps:
          - transform: "present"
            answer:
              - "Minä menen kurssille bussilla."
```

Suggested localisation:

```yaml
ui:
  transform_present_instruction: "Kirjoita lause preesensissä:"
```

---

## Example: multi-step transform

A single cue can have multiple ordered steps.

```yaml
entries:
  - id: "001"
    prompt: "Mitä lapset tekevät koulussa?"
    notes: "What do the children do at school?"
    cues:
      - cue: "kirjoittaa"
        steps:
          - transform: "positive"
            answer:
              - "Lapset kirjoittavat koulussa"
          - transform: "negative"
            answer:
              - "Lapset eivät kirjoita koulussa"
```

Linguatrain will ask each step in order.

---

## CLI usage

Transform packs are used with `--transform`.

```bash
ruby linguatrain.rb pack.yaml --transform
ruby linguatrain.rb pack.yaml 5 --transform
ruby linguatrain.rb pack.yaml all --transform
```

Study mode reveals answers without scoring:

```bash
ruby linguatrain.rb pack.yaml --transform --study
```

Transform study mode may be combined with listening:

```bash
ruby linguatrain.rb pack.yaml --transform --study --listen
```

Current restrictions:

- `--transform` cannot be combined with `--match-game`
- `--transform` cannot be combined with `--speak`
- `--transform` cannot be combined with `--shadow`
- `--transform` cannot be combined with `--reverse`
- `--transform` cannot be combined with `--conversation`
- `--transform --listen` is only allowed with `--study`
- `--transform` does not support SRS yet

---

## Behavior

For each selected cue, the CLI shows:

- the shared prompt
- optional notes, if present and `show_notes` is enabled
- the cue in brackets
- each step in order

Example terminal flow:

```text
Haluan kahvia.
I want coffee.

[ Make this more polite. ]

Conditional:
> Haluaisin kahvia.
✅ Oikein!
```

Study mode flow:

```text
Haluan kahvia.
I want coffee.

[ Make this more polite. ]

Conditional:

(Enter to reveal; q to quit):

Finnish: Haluaisin kahvia.
```

---

## Localisation keys

Transform instructions are resolved from the `transform` value.

For a step like:

```yaml
transform: "conditional"
```

Linguatrain checks for:

```yaml
ui:
  transform_conditional_instruction: "..."
```

Examples:

```yaml
ui:
  transform_positive_instruction: "Anna myönteinen vastaus:"
  transform_negative_instruction: "Anna kielteinen vastaus:"
  transform_conditional_instruction: "Muuta lause konditionaaliin:"
  transform_present_instruction: "Kirjoita lause preesensissä:"
  show_notes: true
```

If a key is missing, Linguatrain falls back to:

```text
Positive:
Negative:
Conditional:
Present:
```

---

## Display controls

### `show_notes`

Controls whether `notes:` are displayed in transform mode.

Default:

```yaml
ui:
  show_notes: true
```

Hide notes:

```yaml
ui:
  show_notes: false
```

When `show_notes: true`:

```text
Haluan kahvia.
I want coffee.
```

When `show_notes: false`:

```text
Haluan kahvia.
```

This is useful for progressive learning:

1. Start with English notes visible.
2. Drill until the transform becomes familiar.
3. Set `show_notes: false` to remove the scaffold.

---

## Recommended formatting rules

### Omit terminal punctuation when possible

For simple grammar drills, punctuation-free canonical answers are easier to maintain.

Recommended:

```yaml
- "Paula lähtee matkalle"
```

Also acceptable:

```yaml
- "Paula lähtee matkalle."
```

The matcher tolerates terminal punctuation.

### Keep transforms consistent

Use the same transform identifiers across packs when they mean the same thing.

Recommended:

```yaml
transform: "conditional"
```

Less consistent:

```yaml
transform: "polite"
transform: "isi"
transform: "would"
```

Choose one reusable label and document it.

### Keep cues focused

A cue should usually represent the one thing the learner must operate on.

Recommended:

```yaml
cue: "Make this more polite."
```

Less clear:

```yaml
cue: "make polite / conditional / maybe request"
```

### Use notes for meaning, not cue text

Recommended:

```yaml
prompt: "Haluan kahvia."
notes: "I want coffee."
cue: "Make this more polite."
```

Less clear:

```yaml
prompt: "Haluan kahvia. / I want coffee."
cue: "Make this more polite."
```

Keeping `notes` separate lets learners hide/show translations globally.

---

## Backward compatibility

Transform packs are explicit structured packs.

Unlike standard vocabulary packs, transform packs are not designed to fall back to simple `prompt` / `answer` pairs.

The loader expects:

- `metadata.drill_type: transform`
- top-level `entries`
- `prompt`
- `cues`
- `steps`
- `transform`
- `answer`

The `notes` field is optional. Older transform packs without `notes` remain valid.

If a transform pack is missing `prompt`, `cues`, `steps`, `transform`, or `answer`, the loader rejects it as invalid.

---

## Validation expectations

A well-formed transform pack should satisfy all of the following:

- `metadata.drill_type` is `transform`
- `entries` exists and is a non-empty array
- every entry has `id`
- every entry has `prompt`
- every entry may optionally have `notes`
- every entry has `cues`
- every cue has `cue`
- every cue has `steps`
- every step has `transform`
- every step has `answer`
- each answer list contains at least one non-empty string

---

## Design notes

This structure is intentionally more explicit than a simple flashcard format.

Why:

- it supports multi-step grammar practice
- it maps closely to workbook exercises
- it supports teacher handouts and sentence-rewrite drills
- it keeps prompt, notes, and cue separate
- it supports multiple accepted answers without ambiguity
- it localises transformation instructions cleanly through the UI layer
- it allows scaffolding to be hidden through `show_notes`

Transform packs are especially useful for drills where the learner must perform controlled grammar production rather than simple translation recall.

Linguatrain has been built from the start around one simple rule:

> **Do not hide language-specific grammar inside the Linguatrain engine.**

Instead, the YAML file contains all transformation behavior explicitly, where it can be reviewed, corrected, extended, and updated without modifying the Linguatrain codebase itself.

This allows the engine to remain stable and language-agnostic while lesson content and grammar behavior can evolve independently over time.

The result is a flexible system where lessons, drills, and grammar rules can adapt freely without requiring changes to the underlying tooling.