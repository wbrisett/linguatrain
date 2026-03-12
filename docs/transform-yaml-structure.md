# Transform YAML Structure

## Purpose

Transform packs define grammar-transformation drills for Linguatrain. These packs are used with `--transform` and are designed for exercises where the learner is given:

- a prompt or context sentence
- a cue
- one or more ordered transformation steps
- one or more accepted answers for each step

This format is useful for workbook-style grammar practice, especially when the learner must produce:

- positive forms
- negative forms
- multiple ordered responses under the same prompt
- sentence transformations based on a cue

## Top-level structure

A transform pack uses this general structure:

```yaml
metadata:
  id: "pack_id"
  pack_name: "Human-readable name"
  drill_type: "transform"
  shuffle_cues: true

entries:
  - id: "entry_id"
    prompt: "Mitä Paula tekee viikonloppuna?"
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

## Required top-level keys

### metadata

Metadata describing the pack.

Required fields:

- `id`
- `pack_name`
- `drill_type`

Recommended fields:

- `shuffle_cues`

Example:

```yaml
metadata:
  id: "sm2_transform_kpt"
  pack_name: "Suomen Mestari 2 — Transform Drills (KPT verbs)"
  drill_type: "transform"
  shuffle_cues: true
```

### entries

A list of transform entries.

Each entry represents one shared prompt or context and one or more cues that will be drilled under that prompt.

## Entry structure

Each entry should include:

- `id`
- `prompt`
- `cues`

Example:

```yaml
- id: "sm2_kpt_001"
  prompt: "Mitä Paula tekee viikonloppuna?"

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

### id

A unique identifier for the entry.

### prompt

The shared question, context, or instruction shown to the learner.

Example:

```yaml
prompt: "Mitä Paula tekee viikonloppuna?"
```

### cues

A list of cue objects associated with the prompt.

Each cue becomes a drill item under the shared prompt.

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

### cue

The lexical or grammatical cue the learner should use.

Examples:

```yaml
cue: "soittaa pianoa"
cue: "lähteä matkalle"
cue: "kirjoittaa"
cue: "nukkua"
```

### steps

An ordered list of transformations to perform for the cue.

Each step should include:

- `transform`
- `answer`

## Step structure

Example:

```yaml
- transform: "positive"
  answer:
    - "Paula lähtee matkalle"

- transform: "negative"
  answer:
    - "Paula ei lähde matkalle"
```

### transform

A short transformation identifier used by the CLI to select the correct instruction text.

Common values:

- `positive`
- `negative`

These are mapped to UI strings through localisation, for example:

- `transform_positive_instruction`
- `transform_negative_instruction`

### answer

A single accepted answer or a list of accepted answers for that step.

Use an array when more than one response should be accepted.

Example:

```yaml
answer:
  - "Paula lähtee matkalle"
  - "Hän lähtee matkalle"
```

## Multiple accepted answers

Use arrays whenever the learner may reasonably produce more than one correct response.

This is especially useful when both a named subject and a pronoun are acceptable.

Example:

```yaml
- transform: "negative"
  answer:
    - "Paula ei soita pianoa"
    - "Hän ei soita pianoa"
```

## Recommended formatting rules

### Omit terminal punctuation

Store answers without a final period when possible.

Recommended:

```yaml
- "Paula lähtee matkalle"
```

Less preferred:

```yaml
- "Paula lähtee matkalle."
```

The matcher tolerates punctuation, but punctuation-free canonical forms are easier to maintain.

### Keep transforms consistent

Use the same transform identifiers across packs when they mean the same thing.

For example, prefer `positive` and `negative` consistently instead of mixing in variants such as `affirmative` or `neg`.

### Keep cues focused

A cue should usually represent the one thing the learner must operate on. Avoid packing multiple unrelated cues into one string.

Recommended:

```yaml
cue: "soittaa pianoa"
```

Less clear:

```yaml
cue: "soittaa pianoa / lähteä matkalle"
```

## Example pack

```yaml
metadata:
  id: "sm2_transform_kpt"
  pack_name: "Suomen Mestari 2 — Transform Drills (KPT verbs)"
  drill_type: "transform"
  shuffle_cues: true

entries:
  - id: "sm2_kpt_001"
    prompt: "Mitä Paula tekee viikonloppuna?"

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

      - cue: "lähteä matkalle"
        steps:
          - transform: "positive"
            answer:
              - "Paula lähtee matkalle"
              - "Hän lähtee matkalle"
          - transform: "negative"
            answer:
              - "Paula ei lähde matkalle"
              - "Hän ei lähde matkalle"

  - id: "sm2_kpt_002"
    prompt: "Mitä lapset tekevät koulussa?"

    cues:
      - cue: "kirjoittaa"
        steps:
          - transform: "positive"
            answer:
              - "Lapset kirjoittavat koulussa"
          - transform: "negative"
            answer:
              - "Lapset eivät kirjoita koulussa"

      - cue: "nukkua"
        steps:
          - transform: "positive"
            answer:
              - "Lapset nukkuvat koulussa"
          - transform: "negative"
            answer:
              - "Lapset eivät nuku koulussa"
```

## CLI usage

Transform packs are used with `--transform`.

Examples:

```bash
ruby linguatrain.rb pack.yaml all --transform
ruby linguatrain.rb pack.yaml 5 --transform
```

### Behavior

For each selected cue, the CLI shows:

- the shared prompt
- the cue in brackets
- each step in order

Example terminal flow:

```text
Mitä Paula tekee viikonloppuna?

[ soittaa pianoa ]

Anna myönteinen vastaus:
> Paula soittaa pianoa

Anna kielteinen vastaus:
> Paula ei soita pianoa
```

## Backward compatibility

Transform packs are a newer structured format and are intended to be explicit.

Unlike standard vocabulary packs, transform packs are not designed to fall back to simple `prompt` / `answer` pairs. The loader expects:

- `metadata.drill_type: conjugate` for conjugate packs
- `metadata.drill_type: transform` for transform packs

If a transform pack is missing `prompt`, `cues`, `steps`, `transform`, or `answer`, the loader will reject it as invalid.

## Validation expectations

A well-formed transform pack should satisfy all of the following:

- `metadata.drill_type` is `transform`
- `entries` exists and is a non-empty array
- every entry has `id`
- every entry has `prompt`
- every entry has `cues`
- every cue has `cue`
- every cue has `steps`
- every step has `transform`
- every step has `answer`
- each answer list contains at least one non-empty string

## Design notes

This structure is intentionally more explicit than a simple flashcard format.

Why:

- it supports multi-step grammar practice
- it maps closely to workbook exercises
- it keeps the prompt and cue relationship clear
- it supports multiple accepted answers without ambiguity
- it localises transformation instructions cleanly through the UI layer

Transform packs are especially useful for drills where the learner must perform controlled grammar production rather than simple translation recall.
