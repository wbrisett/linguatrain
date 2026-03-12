# Conjugate YAML Structure

## Purpose

Conjugate packs define verb‑conjugation drills for Linguatrain. These packs are used with `--conjugate` and are designed for grammar practice where the learner is given:

- a person
- a lemma (dictionary form)
- one or more expected conjugated forms

The format supports:

- positive-only drills
- negative-only drills
- both positive and negative drills
- multiple accepted answers for the same form
- backward compatibility with the earlier positive-only format

## Top-level structure

A conjugate pack uses this general structure:

```yaml
metadata:
  id: "pack_id"
  pack_name: "Human-readable name"
  drill_type: "conjugate"
  shuffle_persons: true

persons:
  - minä
  - sinä
  - hän
  - me
  - te
  - he

entries:
  - id: "entry_id"
    lemma: "lukea"
    forms:
      minä:
        positive:
          - "Minä luen"
          - "Luen"
        negative:
          - "Minä en lue"
          - "En lue"
```

## Required top-level keys

### metadata

Metadata describing the pack.

Required fields:

- `id`
- `pack_name`
- `drill_type`

Recommended fields:

- `shuffle_persons`

Example:

```yaml
metadata:
  id: "sm2_kpt_conjugation"
  pack_name: "Suomen Mestari 2 — KPT Conjugation"
  drill_type: "conjugate"
  shuffle_persons: true
```

### persons

An ordered list of the persons used by the pack.

These values are used to validate each entry. Every entry must provide forms for every listed person.

Example:

```yaml
persons:
  - minä
  - sinä
  - hän
  - me
  - te
  - he
```

### entries

A list of conjugation entries.

Each entry represents one lemma and all of its supported forms across the configured persons.

## Entry structure

Each entry should include:

- `id`
- `lemma`
- `forms`

Example:

```yaml
- id: "kpt_lukea"
  lemma: "lukea"
  forms:
    minä:
      positive:
        - "Minä luen"
        - "Luen"
      negative:
        - "Minä en lue"
        - "En lue"
```

### id

A unique identifier for the entry.

### lemma

The dictionary form of the verb.

Example:

```yaml
lemma: "lukea"
```

`lemma` is preferred over `verb`, though the loader currently supports `verb` for backward compatibility.

### forms

A mapping from person to conjugated forms.

Each listed person should map to a hash containing:

- `positive`
- `negative`

Each of those keys should contain either:

- a single string
- or an array of accepted strings

Example:

```yaml
forms:
  minä:
    positive:
      - "Minä luen"
      - "Luen"
    negative:
      - "Minä en lue"
      - "En lue"

  sinä:
    positive:
      - "Sinä luet"
    negative:
      - "Sinä et lue"
```

## Multiple accepted answers

Use arrays when more than one answer should be accepted.

Example:

```yaml
minä:
  positive:
    - "Minä ammun"
    - "Ammun"
  negative:
    - "Minä en ammu"
    - "En ammu"
```

## Recommended formatting rules

### Omit terminal punctuation

Store answers without a final period when possible.

Recommended:

```yaml
- "Minä luen"
```

### Keep person labels consistent

The keys under `forms` should match the values listed in `persons` exactly.

## Example pack

```yaml
metadata:
  id: "sm2_kpt_conjugation"
  pack_name: "Suomen Mestari 2 — KPT Conjugation"
  drill_type: "conjugate"
  shuffle_persons: true

persons:
  - minä
  - sinä
  - hän
  - me
  - te
  - he

entries:

  - id: "kpt_lukea"
    lemma: "lukea"

    forms:
      minä:
        positive:
          - "Minä luen"
          - "Luen"
        negative:
          - "Minä en lue"
          - "En lue"

      sinä:
        positive:
          - "Sinä luet"
        negative:
          - "Sinä et lue"

      hän:
        positive:
          - "Hän lukee"
        negative:
          - "Hän ei lue"

      me:
        positive:
          - "Me luemme"
        negative:
          - "Me emme lue"

      te:
        positive:
          - "Te luette"
        negative:
          - "Te ette lue"

      he:
        positive:
          - "He lukevat"
        negative:
          - "He eivät lue"
```

## CLI usage

```bash
ruby linguatrain.rb pack.yaml all --conjugate
ruby linguatrain.rb pack.yaml all --conjugate --negative
ruby linguatrain.rb pack.yaml all --conjugate --both
```

### Behavior

- `--conjugate` drills **positive forms**
- `--conjugate --negative` drills **negative forms**
- `--conjugate --both` drills **positive then negative**