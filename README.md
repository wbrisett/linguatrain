
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

## What's New in Version 1.1.0

Version **1.1.0** introduces Linguatrain's new **Translation** module.

Rather than asking learners to translate an entire sentence at once, Translation
Mode breaks language into meaningful chunks, helping learners understand how
ideas are constructed before assembling the complete translation.

Version 1.1.0 also introduces a complete content authoring ecosystem for
Translation, including:

- A structured Translation YAML schema
- A comprehensive Translation Authoring Guide
- Canonical examples and reusable templates
- AI-assisted authoring workflows
- Validation tools for creating consistent, high-quality content

Translation is the first Linguatrain module to include a complete content
architecture—from schema and templates to documentation and authoring
guidelines—and establishes the foundation for future learning modules such as
Morphology.


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
Morphology (planned)
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
