# Linguatrain Pack Authoring Guide

## Purpose

Linguatrain packs should keep content clean, consistent, and language-agnostic. The runtime framework should not contain textbook-specific or language-specific assumptions.

## General principles

- Keep the framework separate from the content.
- Prefer small, composable tools over one large content pipeline.
- Keep `build_yaml.rb` language-agnostic.
- Put language-specific enrichment in separate tools, such as `fi_phonetic.rb`.
- Treat Anki conversion as a migration task, not as normal pack building.

## Cross-reference documents

```
Content Authoring Guide
        ↓
Translation Authoring Guide
        ↓
Translation Templates
        ↓
Canonical Example
```

## File naming

Use lowercase filenames with zero-padded chapter numbers.

```text
suomen_mestari_1_kappale_01_sanasto.yaml
suomen_mestari_1_kappale_01_fraasit.yaml
suomen_mestari_1_kappale_01_dialog_translate.yaml
```

Use `.yaml`, not `.YAML`.

## Core chapter pack types

For textbook-based courses, mirror the textbook structure where practical.

```text
kappale_01_sanasto.yaml            # vocabulary
kappale_01_fraasit.yaml            # fixed phrases and situational expressions
kappale_01_dialog_translate.yaml   # chapter dialogue for the translation module
```

Future pack types may include:

```text
kappale_01_transform.yaml          # grammar as sentence transformations
kappale_01_morfologia.yaml         # word-building and morphology
kappale_01_listen.yaml             # listening practice
kappale_01_shadow.yaml             # shadowing practice
```

## English style

Use American English for original Linguatrain content.

Prefer:

```text
color
center
favorite
defense
license
traveled
canceled
```

Avoid mixing British and American spelling unless quoting a source or using an official name.

## Translation style

Vocabulary and phrase packs should use natural English first.

Prefer:

```yaml
prompt: "Ole hyvä!"
answer:
  - "You're welcome!"
```

Avoid overly literal translations in vocabulary and phrase packs.

Literal translations belong in translation packs:

```yaml
source: "Anteeksi, onko täällä suomen kurssi?"
target: "Excuse me, is the Finnish course here?"
literal: "Excuse me, is here Finnish course?"
```

## CSV source format

The CSV importer should support simple, language-neutral columns.

Recommended columns:

```csv
prompt,answer,category,notes
```

Rules:

- `prompt` is the study prompt.
- `answer` may contain multiple acceptable answers separated by semicolons.
- `category` is optional but encouraged.
- `notes` is optional and should be pedagogically useful.
- Unknown columns should be ignored by the builder when possible.

Example:

```csv
prompt,answer,category,notes
Hei!,hi; hello,greeting,
paikka,place; seat,noun,
onko,is...?; are...?,grammar,Yes/no question form of olla.
```

## Phonetics

Do not generate phonetics inside `build_yaml.rb`.

Use a language-specific enrichment tool after building the YAML:

```bash
ruby build_yaml.rb --csv suomen_mestari_1_kappale_01_sanasto.csv
ruby fi_phonetic.rb suomen_mestari_1_kappale_01_sanasto.yaml
ruby validate_pack.rb suomen_mestari_1_kappale_01_sanasto.yaml
```

This keeps the builder usable for Finnish, German, Italian, and future languages.

## Categories

Categories are optional metadata, but they are useful for filtering and future study modes.

Suggested examples:

```text
greeting
farewell
courtesy
response
food
introduction
weekday
school
location
question word
pronoun
verb
noun
adjective
```

## Notes

Use notes only when they help the learner.

Good notes:

```yaml
notes:
  - "Singular you."
  - "Yes/no question form of olla."
```

Avoid notes that merely repeat the answer.

## Grammar packs

Grammar should usually be represented as transformations, not passive facts.

Example:

```yaml
prompt: "Tämä on vapaa."
instruction: "Make this a yes/no question."
answer:
  - "Onko tämä vapaa?"
```

Grammar teaches how to build or change a sentence.

## Morphology packs

Morphology should focus on word-building.

**Important** : This module is under development. 

## Anki conversion

Keep Anki conversion separate.

```bash
ruby convert_apkg_to_linguatrain.rb deck.apkg
```

Anki decks vary widely in field order, note models, media handling, and HTML. Keep that complexity out of `build_yaml.rb`.

-----------------

## Translation Packs

Translation packs are fundamentally different from vocabulary packs.

Their purpose is not to teach English.

Their purpose is to help the learner understand how ideas are expressed in the
target language.

Translation packs should follow the Translation Authoring Guide.

Do not duplicate translation design rules in this document. Instead, this guide
defines where translation packs fit within the overall Linguatrain ecosystem.

---------------

## Choose the Right Pack Type

Before creating a new pack, ask yourself:

"What is the learner trying to learn?"

If the goal is...

- learning vocabulary → Vocabulary pack
- understanding sentences → Translation pack
- manipulating grammar → Transform pack
- building word forms → Morphology pack *under development*
- practicing conversation → Conversation pack

Choose the pack type that matches the learner's objective rather than trying to
teach everything in a single pack.

----------

## Source of Truth

The CSV files are the canonical source for vocabulary and phrase packs.

Generated YAML files should not normally be edited by hand.

If content changes are required:

1. Update the CSV.
2. Rebuild the YAML with `build_yaml.rb`.
3. Regenerate phonetics.
4. Validate the pack.

