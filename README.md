
# Linguatrain

*A content-driven framework for language learning.*

![Ruby](https://img.shields.io/badge/Ruby-3.x-red)
![License](https://img.shields.io/badge/license-Apache%202.0-blue)
![CLI](https://img.shields.io/badge/interface-CLI-green)

Linguatrain is a Ruby command-line application that teaches languages using
structured YAML content packs.

Linguatrain is designed for learners, teachers, and content authors who want
full control over the material they study.

Rather than fixed courses, Linguatrain separates the learning engine from the
learning content, allowing learners, teachers, and content authors to build
reusable learning material tailored to their own goals.


## A Quick Example

```text
--------------------------------------------------
Translation Mode
--------------------------------------------------

Anteeksi, onko täällä suomen kurssi?

> excuse me

✓ Anteeksi : Excuse me

Remaining translation:

onko täällä
suomen kurssi
```

Instead of immediately grading a complete sentence, Linguatrain progressively guides the learner through meaningful pieces of language.

## Why Linguatrain?

- YAML-driven content
- Multiple learning modules
- Progressive learning philosophy
- Offline after installation
- AI-friendly authoring
- Human-friendly authoring
- Content-first architecture

## What's New in Version 1.3.0

Version **1.3.0** introduces Linguatrain's new **Locative Cases** module.

The Finnish language uses different word endings to express location and
movement. These endings distinguish whether something is inside a place or at
an external location, and whether someone or something is moving to it, staying
there, or moving away from it. Together, these meanings are expressed through
six locative cases: illative, inessive, elative, allative, adessive, and
ablative.

The Locative Cases module is designed to help learners practise these forms in
complete, natural Finnish sentences. Given an English prompt, the learner must
produce the whole Finnish sentence and choose the correct location form from
the meaning and context. This trains the mechanics of the cases without
reducing the exercise to filling in a suffix.

Practice material is prepared in YAML files and includes useful grammatical
information such as the location word, locative family, directional question,
and case. Exercises can therefore be focused on `mihin`, `missä`, or `mistä`,
on an individual grammatical case, or on the internal or external family.

As with Linguatrain's other modules, the learning engine is separate from the
content. Teachers, learners, and content authors can create targeted sentence
sets from real study material while keeping the module independent of
Translation, Word Explorer, Sentence Explorer, and Conjugation.

## Locative Cases Module

Locative Cases is a standalone Finnish sentence-production module. It groups
natural sentence variants around one location lemma, then asks the learner to
produce complete Finnish sentences for `mihin`, `missä`, and `mistä` meanings.

```text
A train goes to Lehtelä.
> Juna menee Lehtelään.
```

The module supports the three internal cases (illative, inessive, elative) and
the three external cases (allative, adessive, ablative). Exercises are authored
in YAML before practice; the runtime does not generate sentences or reduce the
task to suffix blanks.

Run the bundled example with:

```bash
ruby bin/linguatrain.rb \
  lib/linguatrain/locative_cases/examples/suomen_mestari_1_kappale_6_locative_cases.yaml \
  all --locative-cases
```

See `lib/linguatrain/locative_cases/README.md` for the schema, filters,
authoring rules, and validation instructions.


## Educational Philosophy

Linguatrain is designed to help learners understand language, not simply memorize answers.

Each learning module focuses on a single learning objective while revealing one additional layer of linguistic structure.

```text
Vocabulary
      ↓
Grammar
      ↓
Translation
      ↓
Morphology
      ↓
Conversation
      ↓
Listening / Speaking
```

## Documentation

Linguatrain includes extensive documentation for users, content authors, and contributors. Most documentation lives under the `docs/` directory.


### Getting Started

See the documents under `docs/`.

### Content Authoring

Linguatrain includes comprehensive documentation for creating reusable learning
content, including:

- Translation Authoring Guide
- Locative Cases authoring and usage guide
- Translation templates
- Canonical Translation example
- Pack authoring guides
- Validation tools

### Additional Documentation

See the `/docs` directory for installation, configuration, speech setup, pack authoring, validation, and other topics.

## Installation

See the User Guide for installation and configuration instructions.

## Learn More

For complete documentation, including installation, configuration, content authoring, design philosophy, and advanced usage, see:

- `/docs/user_guide.md`
