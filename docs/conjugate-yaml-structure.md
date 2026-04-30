# Conjugate YAML Structure

## Purpose

Conjugate packs define verb-conjugation drills for Linguatrain.

These packs are used with `--conjugate` and are designed for grammar practice where the learner is given:

- a person
- an optional person gloss, such as `hän — he/she`
- a lemma, or dictionary form
- an optional verb gloss, such as `ajaa — to drive`
- one or more expected conjugated forms
- optional phonetic pronunciation aids

Examples in this document use Finnish, Spanish, German, and French, but the schema is language-agnostic. The same structure can be used for any language.

---

## Design principle

Linguatrain does **not infer grammar**.

The engine drills the forms declared in YAML. It does not generate negatives, stems, tenses, persons, or language-specific transformations.

This keeps the runtime engine:

- language independent
- predictable (no hidden transformations)
- inspectable (all behaviour is visible in the YAML itself)
- easy to validate
- safe for user-authored packs

Linguatrain separates content, generation, and delivery into independent layers.

Language-specific generation, such as creating Finnish negative forms from positive forms, belongs in external pack-authoring tools, not in the runtime engine.

---

## Minimal valid conjugate pack

```yaml
metadata:
  id: fi_basic_conjugation
  name: Finnish Basic Conjugation
  version: "1.0"
  drill_type: conjugate
  schema_version: 1
  shuffle_persons: false

persons:
  - minä
  - sinä
  - hän

entries:
  - lemma: ajaa
    prompt:
      - to drive
    forms:
      minä: ajan
      sinä: ajat
      hän: ajaa
```

This is positive-only shorthand. It works with:

```bash
linguatrain.rb pack.yaml --conjugate
linguatrain.rb pack.yaml --conjugate --study
```

It does **not** contain negative forms, so it cannot be used with:

```bash
linguatrain.rb pack.yaml --conjugate --negative
linguatrain.rb pack.yaml --conjugate --both
```

For negative or both-mode drills, use the full `positive` / `negative` structure.

---

## Fully featured conjugate pack

```yaml
metadata:
  id: fi_verbs_type1_2_present_full
  name: Finnish Verb Types 1 & 2 Present Tense Full
  version: "1.0"
  drill_type: conjugate
  schema_version: 1
  shuffle_persons: false

persons:
  - key: minä
    gloss: I
  - key: sinä
    gloss: you singular
  - key: hän
    gloss: he/she
  - key: me
    gloss: we
  - key: te
    gloss: you plural
  - key: he
    gloss: they

entries:
  - lemma: ajaa
    prompt:
      - to drive
    type: 1
    phonetic: AH-yah-ah
    forms:
      minä:
        positive: ajan
        negative: en aja
      sinä:
        positive: ajat
        negative: et aja
      hän:
        positive: ajaa
        negative: ei aja
      me:
        positive: ajamme
        negative: emme aja
      te:
        positive: ajatte
        negative: ette aja
      he:
        positive: ajavat
        negative: eivät aja
    phonetics:
      minä:
        positive: AH-yahn
        negative: en AH-yah
      sinä:
        positive: AH-yaht
        negative: et AH-yah
      hän:
        positive: AH-yah
        negative: ei AH-yah
      me:
        positive: AH-yam-meh
        negative: em-meh AH-yah
      te:
        positive: AH-yat-teh
        negative: et-teh AH-yah
      he:
        positive: AH-ya-vaht
        negative: ei-vät AH-yah
```

---

## Top-level keys

### `metadata`

Required:

- `id`
- `drill_type: conjugate`

Recommended:

- `name`
- `version`
- `schema_version`
- `shuffle_persons`

Example:

```yaml
metadata:
  id: fi_verbs_type1_2_present_full
  name: Finnish Verb Types 1 & 2 Present Tense Full
  version: "1.0"
  drill_type: conjugate
  schema_version: 1
  shuffle_persons: false
```

`shuffle_persons` controls whether each verb is drilled in the listed person order or in randomized person order.

---

## `persons`

The `persons` list defines the person keys used by every conjugation entry.

The keys must match the keys under each verb’s `forms` or `present` block exactly.

### Simple form

```yaml
persons:
  - minä
  - sinä
  - hän
```

This is valid and backward compatible.

### Extended form

```yaml
persons:
  - key: minä
    gloss: I
  - key: sinä
    gloss: you singular
  - key: hän
    gloss: he/she
```

This is recommended for learner-facing packs because it allows Linguatrain to display:

```text
[ Person: hän — he/she ]
```

### Supported person fields

```yaml
- key: minä
  gloss: I
```

`key` is required when using the extended form.

`gloss` is optional, but recommended.

---

## `entries`

Each entry represents one verb.

Recommended fields:

- `id`
- `lemma`
- `prompt`
- `type`
- `phonetic`
- `forms` or `present`
- `phonetics`
- `notes`

Only `lemma` and `forms` or `present` are required by the conjugate loader.

---

## `lemma`

The lemma is the dictionary form of the verb.

```yaml
lemma: ajaa
```

Displayed as:

```text
[ Verb: ajaa ]
```

If a prompt or gloss is present, it can display as:

```text
[ Verb: ajaa — to drive ]
```

---

## `prompt`

`prompt` supplies the learner-facing meaning or source-language cue.

```yaml
prompt:
  - to drive
```

The first prompt is used as the displayed verb gloss in conjugation mode.

Multiple prompts may be supplied:

```yaml
prompt:
  - to speak
  - to talk
```

Use `prompt` for learner-facing meanings. `gloss` and `english` are still supported by the loader, but `prompt` is preferred for current packs.

---

## `type`

`type` is optional metadata.

```yaml
type: 1
```

For Finnish packs, this can represent the Finnish verb type. The engine does not use this value for grammar. It is metadata for learners, validators, or pack-authoring tools.

---

## `phonetic`

`phonetic` is lemma-level pronunciation help.

```yaml
phonetic: AH-yah-ah
```

Displayed with the lemma:

```text
🗣 ääntämys: AH-yah-ah
```

This is separate from per-form `phonetics`.

---

## `forms` and `present`

Linguatrain accepts either `forms` or `present`.

Use `forms` for generic conjugation packs:

```yaml
forms:
  minä:
    positive: ajan
    negative: en aja
```

Use `present` when the pack is explicitly a present-tense pack:

```yaml
present:
  minä:
    positive: ajan
    negative: en aja
```

Internally, the engine treats `present` as an alias for `forms`.

---

## Positive-only shorthand

Positive-only shorthand is supported for simple packs:

```yaml
forms:
  minä: ajan
  sinä: ajat
  hän: ajaa
```

Equivalent `present` form:

```yaml
present:
  minä: ajan
  sinä: ajat
  hän: ajaa
```

This is valid for positive drills only.

It does not provide data for `--negative` or `--both`.

If you run a negative drill against a positive-only pack, Linguatrain reports that no negative forms were found.

---

## Positive and negative forms

For packs that support `--negative` or `--both`, each person must use nested polarity fields:

```yaml
forms:
  minä:
    positive: ajan
    negative: en aja
```

Values may be strings:

```yaml
positive: ajan
negative: en aja
```

or arrays:

```yaml
positive:
  - ajan
  - minä ajan
negative:
  - en aja
  - minä en aja
```

Use arrays when multiple answers should be accepted.

---

## `phonetics`

`phonetics` provides pronunciation help for conjugated forms.

### Polarity-aware phonetics

Recommended when the pack includes negative forms:

```yaml
phonetics:
  minä:
    positive: AH-yahn
    negative: en AH-yah
```

This allows study and quiz output to show the phonetic helper for the active polarity.

### Positive-only shorthand

This older form is still accepted:

```yaml
phonetics:
  minä: AH-yahn
```

The engine treats this as positive-only phonetics.

Use the nested form when the pack includes negative forms.

---

## Study mode output

With person, glosses, prompts, lemma phonetics, and polarity-aware phonetics, study mode can display:

```text
Conjugate the verb.

[ Person: hän — he/she ]
[ Verb: ajaa — to drive ]
🗣 ääntämys: AH-yah-ah

Use the positive form:

Finnish: ajaa (hän ajaa)
   (🗣 ääntämys: AH-yah)
```

Negative study mode can display:

```text
Conjugate the verb.

[ Person: minä — I ]
[ Verb: ajaa — to drive ]
🗣 ääntämys: AH-yah-ah

Use the negative form:

Finnish: en aja (minä en aja)
   (🗣 ääntämys: en AH-yah)
```

---

## Display controls

Conjugate packs can contain glosses and phonetics even when the learner no longer wants to see them during drills.

Display behavior is controlled through the **localisation file**, not the pack. This keeps the pack content reusable while allowing different learners or difficulty levels to choose how much help is shown.

Add these keys under the localisation file's `ui` block:

```yaml
ui:
  show_gloss: true
  show_phonetic: true
  show_conjugated_form: true  
```
**Note:** By default all are shown and don't necessarily need to be in the localisation file. 

### `show_gloss`

Controls whether person and verb glosses are shown.

When enabled:

```text
[ Person: hän — he/she ]
[ Verb: ajaa — to drive ]
```

When disabled:

```text
[ Person: hän ]
[ Verb: ajaa ]
```

### `show_phonetic`

Controls whether lemma-level and answer-level phonetic helpers are shown.

When enabled:

```text
🗣 ääntämys: AH-yah-ah
Finnish: ajaa (hän ajaa)
   (🗣 ääntämys: AH-yah)
```

When disabled:

```text
Finnish: ajaa (hän ajaa)
```

### `show_conjugated_form`

Controls whether the full person + conjugated form is shown next to the answer.

When enabled:

```text
Finnish: ajaa (hän ajaa)
```

When disabled:

```text
Finnish: ajaa
```

### Defaults

If these keys are omitted, Linguatrain uses the learner-friendly defaults:

```yaml
ui:
  show_gloss: true
  show_phonetic: true
  show_conjugated_form: true
```

A more advanced learner might use:

```yaml
ui:
  show_gloss: false
  show_phonetic: false
  show_conjugated_form: true
```

This keeps the full conjugated phrase visible while hiding meaning and pronunciation aids.

---

## Cross-language examples

The same schema works across languages because the engine does not infer grammar.

### Finnish

```yaml
minä:
  positive: ajan
  negative: en aja
```

### Spanish

```yaml
yo:
  positive: como
  negative: no como
```

### German

```yaml
ich:
  positive: fahre
  negative: fahre nicht
```

### French

```yaml
je:
  positive: mange
  negative: ne mange pas
```

The YAML declares the forms. The engine drills them.

---

## CLI usage

```bash
linguatrain.rb pack.yaml --conjugate
linguatrain.rb pack.yaml --conjugate --negative
linguatrain.rb pack.yaml --conjugate --both
linguatrain.rb pack.yaml --conjugate --study
linguatrain.rb pack.yaml --conjugate --negative --study
linguatrain.rb pack.yaml --conjugate --both --study
```

Optional count argument:

```bash
linguatrain.rb pack.yaml 10 --conjugate
linguatrain.rb pack.yaml all --conjugate --study
```

---

## Behavior

| Option | Behavior |
|---|---|
| `--conjugate` | drills positive forms by default |
| `--negative` | drills negative forms only |
| `--both` | drills positive and negative forms |
| `--study` | reveal-only study mode, no scoring |
| `--study --both` | shows both positive and negative forms for each person/verb pair |

---

## Validation expectations

A valid conjugate pack should satisfy these rules:

- `metadata.drill_type` must be `conjugate`.
- `persons` must be top-level.
- `entries` must be top-level.
- Every person key must exist for every verb entry.
- Every entry must define `lemma`.
- Every entry must define either `forms` or `present`.
- Packs intended for `--negative` must define negative forms.
- Packs intended for `--both` must define positive and negative forms.
- Empty answer values should be avoided.
- `persons[*].key` values must match the form keys exactly.

---

## Common errors

### `Invalid conjugate pack: missing persons list`

Likely cause: `persons` is not top-level.

Incorrect:

```yaml
metadata:
  id: bad_pack
  drill_type: conjugate
  persons:
    - minä
```

Correct:

```yaml
metadata:
  id: good_pack
  drill_type: conjugate

persons:
  - minä
```

### No negative forms found

Likely cause: the pack uses positive-only shorthand.

Positive-only:

```yaml
forms:
  minä: ajan
```

Negative-compatible:

```yaml
forms:
  minä:
    positive: ajan
    negative: en aja
```

---

## Formatting rules

- Use spaces, not tabs.
- Keep top-level keys at column 1.
- Keep person keys consistent.
- Avoid trailing punctuation in answers unless punctuation is part of the expected answer.
- Use arrays for multiple accepted answers.
- Use `prompt` for learner-facing meanings.
- Use `phonetic` for lemma pronunciation.
- Use `phonetics` for conjugated-form pronunciation.
- Use nested `positive` / `negative` when a pack should support `--negative` or `--both`.

---

## Future extensibility

This schema allows additional categories without changing the engine, provided the engine is taught how to select and display them.

Possible future extensions:

```yaml
forms:
  minä:
    present_positive: ajan
    present_negative: en aja
    past_positive: ajoin
    past_negative: en ajanut
```

or:

```yaml
forms:
  minä:
    positive: ajan
    negative: en aja
    question: ajanko
```

**Important:** language-specific inference is not added to the runtime engine. This is a very intentional design decision. Instead language-specific generation is always added to the external pack-authoring tools. This keeps the engine language agnostic. 
