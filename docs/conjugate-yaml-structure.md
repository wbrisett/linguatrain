# Conjugate YAML Structure

## Purpose

Conjugate packs define verb-conjugation drills for Linguatrain. These
packs are used with `--conjugate` and are designed for grammar practice
where the learner is given:

-   a person
-   a lemma (dictionary form)
-   an optional gloss (meaning)
-   one or more expected conjugated forms

The format supports:

-   positive-only drills
-   negative-only drills
-   both positive and negative drills
-   multiple accepted answers for the same form
-   backward compatibility with earlier positive-only format

------------------------------------------------------------------------

## Top-level structure

A conjugate pack uses this general structure:

``` yaml
metadata:
  id: "english_read_conjugation"
  pack_name: "English Verb Example"
  drill_type: "conjugate"
  shuffle_persons: true

persons:
  - I
  - you
  - he/she
  - we
  - you (plural)
  - they

entries:
  - id: "001"
    lemma: "to read"
    gloss: "to read"
    forms:
      I:
        positive:
          - "I read"
        negative:
          - "I do not read"
          - "I don't read"
```

------------------------------------------------------------------------

## Example (Finnish)

``` yaml
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
    gloss: "to read"
    forms:
      minä:
        positive:
          - "Minä luen"
          - "Luen"
        negative:
          - "Minä en lue"
          - "En lue"
```

------------------------------------------------------------------------

## Required top-level keys

### metadata

Required: - id - drill_type

Recommended: - pack_name - shuffle_persons

------------------------------------------------------------------------

### persons

Ordered list of persons. Must match forms exactly.

------------------------------------------------------------------------

### entries

Each entry represents one verb.

------------------------------------------------------------------------

## Entry structure

Required: - id - lemma - forms

Recommended: - gloss

Optional: - notes

------------------------------------------------------------------------

### lemma

Dictionary form of the verb.

------------------------------------------------------------------------

### gloss

Short meaning shown during drills.

------------------------------------------------------------------------

### forms

Each person must include:

-   positive
-   negative

------------------------------------------------------------------------

## Multiple accepted answers

Use arrays for multiple valid answers.

------------------------------------------------------------------------

## Formatting rules

-   No trailing punctuation
-   Keep person labels consistent
-   Use gloss consistently

------------------------------------------------------------------------

## Example pack

``` yaml
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
    gloss: "to read"
    forms:
      minä:
        positive:
          - "Minä luen"
          - "Luen"
        negative:
          - "Minä en lue"
          - "En lue"
```

------------------------------------------------------------------------

## CLI usage

``` bash
ruby linguatrain.rb pack.yaml all --conjugate
ruby linguatrain.rb pack.yaml all --conjugate --negative
ruby linguatrain.rb pack.yaml all --conjugate --both
```

------------------------------------------------------------------------

## Behavior

-   --conjugate → positive
-   --negative → negative
-   --both → positive + negative
