
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

## What's New in Version 1.2.0


Version **1.2.0** introduces Linguatrain's new **word-explorer** module.

Word-explorer is the user-friendly way of saying morphology. All languages can benefit from the 
word-explorer module, but some benefit more than others. Finnish for example takes a base and depending
on direction (inside, outside, to, or from) changes word endings. A lot of language study tools simply 
have you study these as individual words, or in some cases just start using them without really explaining
why `talolta` was used instead of `talo`. Word-explorer takes a very different approach. Instead in conjunction 
with translated material, a word-explorer YAML pack is generated from the translation text and Linguatrain
allows you study and explore the base word in different modes. 

* `--recognize` : Recognize is designed to show you the word as it's used in the text and match it to its base. 
* `--apply` : Uses the base and asks you to pick the correct form of the base to fit into a sentence. 
* `--build` : Uses the base and asks you to change the form to match the question. 

Linguatrain itself is the learning engine; the YAML files contain the structured content that drives each module. To make Word Explorer useful in practice, I have spent a great deal of time developing strict LLM authoring guidelines for Linguatrain content packs.

The `05_Linguatrain_LLM_Authoring_Specification.md` file can be given to an LLM to generate high-quality draft material for the translation, vocabulary, conjugation, and word-explorer modules. The goal is not to replace live teachers, but to make it easier to turn existing course materials, textbooks, handouts, and real study needs into structured practice.

I know this workflow is useful because I am using Linguatrain while studying a language myself, and my language teacher has been impressed with the results.


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
