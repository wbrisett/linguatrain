# Conjugate YAML Structure

## Purpose

Conjugate packs define verb-conjugation drills for Linguatrain. These packs are used with `--conjugate` and are designed for grammar practice where the learner is given:

- a person
- a person gloss (e.g., hän — he/she)
- a lemma (dictionary form)
- a verb meaning
- one or more expected conjugated forms
- optional phonetic pronunciation aids

The format supports:

- positive-only drills
- negative-only drills
- both positive and negative drills
- multiple accepted answers
- person glosses for clarity
- lemma and per-form phonetics
- backward compatibility

---

## Top-level structure

```yaml
metadata:
  id: fi_verbs_type1_2_present_full
  name: Finnish Verb Types 1 & 2 Present Tense Full
  version: "1.3"
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
    present:
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
      minä: AH-yahn
      sinä: AH-yaht
      hän: AH-yah
      me: AH-yam-meh
      te: AH-yat-teh
      he: AH-ya-vaht
```

---

## Persons

Preferred structure:

```yaml
persons:
  - key: minä
    gloss: I
```

The `key` must match conjugation keys. The `gloss` is optional but recommended.

---

## Entries

Each entry represents one verb.

Recommended fields:

- lemma
- prompt
- type (optional)
- phonetic
- present or forms
- phonetics

---

## Prompt

Defines the meaning:

```yaml
prompt:
  - to drive
```

---

## Forms

Supports both `present` and `forms`.

### Positive-only shorthand

```yaml
present:
  minä: ajan
```

### Full structure

```yaml
present:
  minä:
    positive: ajan
    negative: en aja
```

Multiple answers:

```yaml
positive:
  - ajan
  - minä ajan
```

---

## Phonetics

### Lemma-level

```yaml
phonetic: AH-yah-ah
```

### Per-form

```yaml
phonetics:
  minä: AH-yahn
```

---

## CLI usage

```bash
ruby linguatrain.rb pack.yaml all --conjugate
ruby linguatrain.rb pack.yaml all --conjugate --negative
ruby linguatrain.rb pack.yaml all --conjugate --both
ruby linguatrain.rb pack.yaml all --conjugate --study
```

---

## Behavior

- --conjugate → positive
- --negative → negative
- --both → both
- --study → reveal mode

---

## Study mode output example

```
Conjugate the verb.

[ Person: hän — he/she ]
[ Verb: ajaa — to drive ]
🗣 ääntämys: AH-yah-ah

Finnish: ajaa (hän ajaa)
   (🗣 ääntämys: AH-yah)
```

---

## Formatting rules

- Match person keys exactly
- Use prompt for meaning
- Use phonetic fields consistently
- Use arrays for multiple answers
- Avoid punctuation in answers
