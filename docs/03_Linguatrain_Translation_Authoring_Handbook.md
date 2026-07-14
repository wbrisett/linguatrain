# Linguatrain Translation Authoring Handbook

## Purpose

This handbook explains how to design high-quality Linguatrain translation packs. It describes the educational philosophy behind the translation module and the conventions authors should follow when creating new content.

The goal is **not** to model a textbook. The goal is to model the learning process a student goes through while decoding another language.

This handbook is written for human authors. Some sections include copy-ready LLM prompts because a human author may choose to use an LLM to draft Linguatrain material. Those prompts are authoring tools, not the source of authority. The human author remains responsible for selecting source material, reviewing translations, correcting linguistic errors, and deciding whether the final pack teaches well.

Throughout this handbook, the document **Meidän tavallinen päivä** is used as the canonical translation pack. For this reason, Finnish is frequently used in examples, although the authoring principles are language independent and apply to all languages supported by Linguatrain.

---

## 📚 Documentation

Use the guide that best matches what you're trying to accomplish.

| Guide | Purpose | Current |
|-------|---------|---------|
| **Quick Start Guide** | Install Linguatrain and study your first lesson in approximately 5–10 minutes. | |
| **Setup & Usage Guide** | Learn the CLI, configuration, study modes, speech support, and advanced features. | |
| **Authoring Handbook** | Learn how to create learning packs and understand Linguatrain's educational philosophy. | ✅ You are here |
| **Options Reference** | Quick reference for all Linguatrain command-line options. | |

---

## Table of Contents

- [Foundations](#foundations)
  - [Core Philosophy](#core-philosophy)
  - [Learning Progression](#learning-progression)
  - [The Role of the Translation Module](#the-role-of-the-translation-module)
  - [The Translation Process](#the-translation-process)
  - [Why This Matters](#why-this-matters)
  - [Building Towards Translation](#building-towards-translation)
  - [Learning with Companion Vocabulary Packs](#learning-with-companion-vocabulary-packs)
  - [Preparing the Learner for Success](#preparing-the-learner-for-success)
  - [Authoring Workflow](#authoring-workflow)
  - [Human Source Material](#human-source-material)
  - [Multilingual Source Material](#multilingual-source-material)
  - [Using an LLM to Draft Learning Packs](#using-an-llm-to-draft-learning-packs)
  - [A Collaborative Process](#a-collaborative-process)
  - [What to Give the LLM](#what-to-give-the-llm)
  - [Progressive Enrichment](#progressive-enrichment)
  - [Copy-Ready Full-Pack Prompt](#copy-ready-full-pack-prompt)
  - [Review the Results](#review-the-results)
  - [The LLM Is an Assistant, Not an Authority](#the-llm-is-an-assistant-not-an-authority)

- [Translation](#translation)
  - [Translation Is Canonical](#translation-is-canonical)
  - [Required Top-Level Metadata](#required-top-level-metadata)
  - [Entry Field Definitions](#entry-field-definitions)
  - [Every Chunk Mirrors the Entry](#every-chunk-mirrors-the-entry)
  - [Chunking Guidelines](#chunking-guidelines)
  - [Literal vs Natural Translation](#literal-vs-natural-translation)
  - [Pronunciation / Phonetic Guidance](#pronunciation--phonetic-guidance)
  - [Choosing Accepted Answers](#choosing-accepted-answers)
  - [Hints](#hints)
  - [What Makes a Good Translation Document?](#what-makes-a-good-translation-document)
  - [Final Design Principles](#final-design-principles)

- [Vocabulary](#vocabulary)
  - [Vocabulary Packs](#vocabulary-packs)
  - [Vocabulary Entry Schema](#vocabulary-entry-schema)
  - [Field Definitions](#field-definitions)
  - [Vocabulary Candidate Selection and Normalization](#vocabulary-candidate-selection-and-normalization)
  - [Guiding Principle](#guiding-principle)
  - [Educational Priority](#educational-priority)
  - [Candidate Selection](#candidate-selection)
  - [Surface Form First](#surface-form-first)
  - [Lemma Identity](#lemma-identity)
  - [Named Entities](#named-entities)
  - [Canonical Lemma Principle](#canonical-lemma-principle)
  - [Vocabulary Entry Enrichment](#vocabulary-entry-enrichment)
  - [Morphological Forms](#morphological-forms)
  - [Vocabulary Notes](#vocabulary-notes)
  - [Vocabulary Pack Shape](#vocabulary-pack-shape)

- [Conjugation](#conjugation)
  - [Conjugation Packs](#conjugation-packs)
  - [Conjugation Entry Schema](#conjugation-entry-schema)
  - [Field Definitions](#field-definitions-1)
  - [Conjugation Pack Generation](#conjugation-pack-generation)
  - [Guiding Principle](#guiding-principle-1)
  - [Educational Priority](#educational-priority-1)
  - [Candidate Selection](#candidate-selection-1)
  - [Canonical Lemma Only](#canonical-lemma-only)
  - [One Verb, One Identity](#one-verb-one-identity)
  - [Complete Paradigms](#complete-paradigms)
  - [Language-Specific Structure](#language-specific-structure)
  - [Deriving a Conjugation Pack](#deriving-a-conjugation-pack)
  - [Multi-word Expressions](#multi-word-expressions)
  - [Conjugation Pack Shape](#conjugation-pack-shape)

- [Word Explorer](#word-explorer)
  - [Word Explorer Packs](#word-explorer-packs)
  - [Word Explorer Entry Schema](#word-explorer-entry-schema)
  - [Field Definitions](#field-definitions-2)
  - [Word Explorer Pack Generation](#word-explorer-pack-generation)
  - [Creating a Word Explorer Pack (and Guide) with an LLM](#creating-a-word-explorer-pack-and-guide-with-an-llm)
  - [Guiding Principle](#guiding-principle-2)
  - [Educational Priority](#educational-priority-2)
  - [Candidate Selection](#candidate-selection-2)
  - [Explorations Are Not Complete Paradigms](#explorations-are-not-complete-paradigms)
  - [Irregular Stems](#irregular-stems)
  - [Deriving a Word Explorer Pack](#deriving-a-word-explorer-pack)
  - [The Word Explorer Guide](#the-word-explorer-guide-word-explorermd)
  - [Word Explorer Pack Shape](#word-explorer-pack-shape)

- [Common Authoring Mistakes](#common-authoring-mistakes)
  - [Overusing Accepted Answers](#overusing-accepted-answers)
  - [Breaking the Lemma Invariant](#breaking-the-lemma-invariant)
  - [Using Vocabulary Instead of Hints](#using-vocabulary-instead-of-hints)
  - [Making Literal Translations Too Natural](#making-literal-translations-too-natural)
  - [Splitting Semantic Units](#splitting-semantic-units)
  - [Reordering the Source](#reordering-the-source)
  - [Duplicating Information](#duplicating-information)
  - [Creating Exhaustive Morphology](#creating-exhaustive-morphology)
  - [Distractors Without Reasons](#distractors-without-reasons)
  - [Inventing Chapter Continuity](#inventing-chapter-continuity)
  - [Authoring the Word Explorer Guide by Hand](#authoring-the-word-explorer-guide-by-hand)
  - [Inconsistent Phonetics](#inconsistent-phonetics)
  - [Weak Vocabulary References](#weak-vocabulary-references)
  - [Vocabulary Notation Entries](#vocabulary-notation-entries)
  - [Forgetting the Educational Goal](#forgetting-the-educational-goal)
  - [YAML Serialization Rules](#yaml-serialization-rules)

- [Author Quality Checklist](#author-quality-checklist)
  - [Educational Quality](#educational-quality)
  - [Structural Quality](#structural-quality)
  - [Linguistic Quality](#linguistic-quality)
  - [Companion Pack Quality](#companion-pack-quality)
  - [Word Explorer Quality](#word-explorer-quality)
  - [Final Question](#final-question)

- [Final Thoughts](#final-thoughts)
---

# Foundations

## Core Philosophy

Every translation exercise moves through three stages:

    Original language Text
        ↓
    Literal target language
        ↓
    Natural target language

The literal translation preserves the structure of the original language.

The natural translation expresses the same idea in idiomatic English.

This distinction became one of the most important design decisions in the module.

### Finnish Example

`Original`: Hyvä. Onko tämä paikka vapaa?

`Literal`: Good. Is this place free?

`Natural`: Good. Is this seat free?

---

## Learning Progression

Each Linguatrain module focuses on a single cognitive task rather than trying to teach everything at once.

```text
Vocabulary
      ↓
Translation
      ↓
Word Explorer (morphology)
      ↓
Conversation
```

- **Vocabulary** builds recognition of reusable words and phrases.
- **Translation** teaches how ideas are expressed in complete sentences.
- **Word Explorer (morphology)** teaches why one encountered form was used in one specific sentence, while Conjugation teaches complete verb paradigms.
- **Conversation** teaches communication using the patterns learned.
 
Each module complements the others while remaining focused on one learning objective.

> A good translation document should feel less like a static database and more like a scaffolded classroom discussion between a student and a teacher.

---

## The Role of the Translation Module

The Translation module is where language learning begins to move beyond vocabulary.

Vocabulary exercises teach individual words and short phrases.

Translation teaches the learner how those words combine to express complete ideas.

Rather than asking:

> "What does this word mean?"

the learner begins asking:

> "How do these words work together to express this idea?"

This is an important transition.

The learner is no longer memorizing isolated vocabulary. They are learning to read.

---

## The Translation Process

Every entry encourages the learner to work through the text in stages.

```text
Source Text
      ↓
Meaningful Chunks
      ↓
Literal Translation
      ↓
Natural Translation
```

This mirrors how experienced language learners naturally approach unfamiliar text.

The learner first understands each meaningful part of the source text.

Those parts are then assembled into a correct and natural translation in the target language.

---

## Why This Matters

The objective is not simply to produce a correct translation.

The objective is to understand how the source language expresses ideas.

By working through meaningful chunks, the learner begins to recognise common phrases, sentence patterns, and expressions that appear repeatedly in authentic material.

Over time, these patterns become familiar, reducing the need to translate word by word.

The learner gradually transitions from decoding individual words to recognising complete ideas directly.

---

## Building Towards Translation

Translation is not intended to be the learner's first exposure to new words.

Instead, it represents the next stage of learning.

A recommended learning sequence is:

```text
Vocabulary
      ↓
Translation
      ↓
Reading
```

The vocabulary module introduces individual words, their meanings, pronunciation, and common usage.

The translation module then asks the learner to apply that knowledge by combining those words into meaningful phrases and complete ideas.

Finally, reading reinforces those same words and expressions through repeated exposure in authentic material.

---

## Learning with Companion Vocabulary Packs

A complete translation document should normally be accompanied by a vocabulary pack.

The translation document identifies useful words and phrases through `vocabulary_refs`. The companion vocabulary pack defines those references as studyable vocabulary entries. This lets the learner study the vocabulary first and then use the translation exercise to understand how those words combine in real sentences.

Recommended file pairing:

```text
suomen_mestari_1_kappale_01_translation.yaml
suomen_mestari_1_kappale_01_vocabulary.yaml
```

The translation pack remains focused on sentences, chunks, literal translations, natural translations, hints, and grammar references.

The vocabulary pack is where reusable lexical knowledge belongs: meanings, types, forms, pronunciation, literal structure, and short usage notes.

---

## Preparing the Learner for Success

The objective is not to test whether a learner can guess unknown vocabulary.

Instead, the objective is to help the learner successfully read increasingly complex text.

Whenever practical, the vocabulary required for a translation document should already exist in one or more vocabulary packs. This allows the learner to approach the translation exercise with confidence, focusing on understanding how words combine rather than trying to discover the meaning of every unfamiliar word.

This does not mean every word must already be known.

Occasionally a translation exercise will introduce a new word or expression that has not yet appeared in a vocabulary pack. This is perfectly acceptable, especially when it helps maintain the natural flow of authentic material.

When this occurs, the translation document should provide an appropriate hint for that chunk. A well-written hint gives the learner just enough information to continue without immediately revealing the complete translation.

Hints should support learning, not replace it.

---

## Authoring Workflow

Linguatrain is designed as a framework rather than a content library.

While a representative translation document is included with the project, the expectation is that authors will create translation documents for the material they wish to study.

This section discusses where that material can come from and describes a workflow for producing high-quality translation documents.

---

## Human Source Material

The highest quality source material is content that has already been translated or authored by a language instructor, professional translator, or native speaker.

Examples include:

- language textbooks
- graded readers
- children's books
- professionally translated documents

```text
Human Expertise
        ↓
Source Material
        ↓
Translation YAML
```

Human-authored material often contains subtle linguistic and cultural nuances that are difficult to reproduce automatically. Whenever practical, these sources should be preferred.

---

## Multilingual Source Material

An excellent source of beginner material is multilingual content that already exists in everyday life.

Examples include:

- public signs
- museum plaques
- transportation information
- multilingual instructions
- visitor information

```text
Parallel Text
        ↓
Translation YAML
        ↓
Progressive Enrichment
```

These sources rarely provide literal translations or chunk boundaries, but they have usually been translated by professional translators or native speakers.

A simple source/target translation document is still valuable and can be enriched over time with chunking, hints, literal translations, and vocabulary references.

> **Note:** Don't overlook official websites. Many government agencies, companies, museums, transportation providers, and other organizations offer language toggles that provide professionally translated versions of the same content. While these translations are not always literal, they are typically of high quality and can provide an inexpensive source of excellent parallel text for translation exercises.

---

## Using an LLM to Draft Learning Packs

Modern LLMs have become remarkably capable language assistants.

While they should not be considered infallible, they are extremely effective at accelerating the creation of translation documents when used within a well-defined workflow.

The objective is not to replace the human author.

The objective is to allow the human author to spend their time improving educational quality instead of manually writing repetitive YAML.

In this workflow, the human author prepares the source material, gives the LLM the relevant Linguatrain examples and specification, reviews the draft, and decides what is good enough to publish or study.

```text
Source Material
        +
Canonical Example YAML
        +
Translation Design Guide
        ↓
LLM Draft
        ↓
Translation YAML Draft
        ↓
Human Review
        ↓
Final Translation YAML
```

---

## A Collaborative Process

The translation schema is intentionally designed for collaborative authoring.

The human author provides educational intent, reviews the resulting document, and ensures that it teaches effectively.

The LLM can perform much of the mechanical drafting work, including:

- generating the initial YAML structure
- suggesting chunk boundaries
- creating literal translations
- producing natural translations
- generating hints
- identifying vocabulary references
- creating a companion vocabulary pack from those references

Neither works as well in isolation.

The highest quality translation documents are produced when a knowledgeable human author uses the LLM draft as a starting point, then reviews and improves it.

The LLM contributes speed, consistency, and scale.

The human contributes educational judgment, language expertise, and an understanding of how people learn.

---

## What to Give the LLM

The highest quality LLM drafts are produced when the human author provides:

1. The representative translation YAML document included with Linguatrain.
2. The representative vocabulary YAML document included with Linguatrain.
3. The representative conjugation YAML document included with Linguatrain. 
4. The representative word-explorer YAML document included with Linguatrain.
5. The representative word-explorer markdown document included with Linguatrain. 
6. The 05_Linguatrain_LLM_Authoring_Specification markdown document included with Linguatrain.  
7. The new source material.

The example translation document is intentionally included with Linguatrain as a canonical reference implementation.

It demonstrates the expected structure, chunking style, literal translations, natural translations, hints, vocabulary references, and overall educational philosophy.

Rather than starting from an empty prompt, give the LLM these references so it has a concrete baseline for structure, style, and educational intent.

The 05_Linguatrain_LLM_Authoring_Specification is written specifically for LLMs, not human readers. Attach it when prompting an LLM so the generated draft follows Linguatrain's schema and quality rules as closely as possible.

Together, the example document and the design guide communicate both the syntax and the educational intent of the translation schema.

---

## Progressive Enrichment

Translation documents do not need to be perfect on the first pass.

```text
Minimal Translation

source
target

        ↓

Enhanced Translation

source
literal
target
chunks

        ↓

Complete Translation

source
literal
target
chunks
hints
vocabulary_refs
grammar_refs

        +

Companion Vocabulary Pack

prompt
answer
type
notes
forms

        +

Companion Conjugation Pack

lemma
forms

        +

Companion Word Explorer Pack

source
word
base_word
morphology
explorations
applications

        ↓

Word Explorer Guide

generated from the Word Explorer pack — never authored independently
```

A minimal document containing only source and target text is still useful.

As time permits, additional educational content can be added incrementally without changing the overall structure of the document.

This allows translation documents to grow in educational value over time while remaining useful from the very beginning.

---

## Copy-Ready Full-Pack Prompt

Use this request when you're starting from new source material and want the full pipeline — Translation, Vocabulary, Conjugation, Word Explorer, and the Word Explorer Guide — in one pass. The narrower requests for generating just one pack type live in their own sections ([Vocabulary](#creating-a-vocabulary-pack-without-translation-using-an-llm), [Conjugation](#creating-a-conjugation-pack-without-translation-using-an-llm), [Word Explorer](#creating-a-word-explorer-pack-and-guide-with-an-llm)).

Copy the following prompt into the LLM after attaching the listed files. Edit the lesson identifiers, title, and source material description before sending it.

```Text
Attached:
1. The canonical Translation YAML example.
2. The canonical Vocabulary YAML example.
3. The canonical Conjugation YAML example.
4. The canonical Word Explorer YAML example.
5. The canonical Word Explorer Guide (Markdown) example.
6. 05_Linguatrain_LLM_Authoring_Specification.md — the authoring spec.
7. New source material — a text file, or an image of the source text block.

Task: Using the attached specification and canonical examples as your
reference, generate a complete set of five Linguatrain learning packs for
the attached source material: a Translation pack, a Vocabulary pack, a
Conjugation pack, a Word Explorer pack, and a Word Explorer Guide. Use the
canonical examples only as a structural/style reference — do not copy or
reuse any of their lexical content.

If the source material is an image rather than plain text, first
transcribe it exactly as it appears, preserving original spelling,
diacritics, and line breaks. Flag any character you're not fully
confident about — easily confused diacritics, an unclear scan, ambiguous
punctuation — as a short list before doing anything else, so I can confirm
or correct the transcription. Do not proceed past this step on a guessed
transcription; every downstream pack inherits whatever the source text
says.

Follow this order of operations:

1. Author the Translation pack first: meaningful semantic chunks, optional
   `phonetic` pronunciation guidance, literal translations, natural
   translations, hints, `vocabulary_refs`, and `grammar_refs`.
2. Collect every unique `vocabulary_refs` value and author the Vocabulary
   pack from that exact list — no more, no fewer. Each entry should
   include `prompt`, `answer`, and, where helpful, `type`, `literal`,
   `forms`, `phonetic`, and concise `notes`.
3. Collect every verb lemma in the Vocabulary pack and author the
   Conjugation pack from that exact list — no more, no fewer.
4. Author the Word Explorer pack from the Translation pack's entries and
   chunks, cross-referencing the Vocabulary pack's ids via
   `vocabulary_ref` wherever one exists. Not every word needs an entry —
   select the words that best illustrate cases, compounds, derivations,
   passive forms, and irregular stems. Report the list of words you
   selected, with a brief reason for each, before generating full entries,
   so I can confirm the selection.
5. Generate the Word Explorer Guide from that finished YAML, grouped by
   category. The Guide is scoped to this one pack only: no invented
   chapter or lesson numbering, and no reference to any other pack's
   content, unless the source material itself states that relationship as
   fact.

Lesson identifiers for this set of packs:
- id: '[e.g. suomen_mestari_1_kappale_5]' — used as the base for each
  pack's own id (`..._translation`, `..._vocabulary`, `..._conjugation`,
  `..._word_explorer`)
- title: '[e.g. Kappale 5]'
- version: 1
- schema_version: 1

Do not invent a `chapter` or `category` value anywhere in this set unless
the source material itself states one as fact — omit rather than infer.

Every note, hint, and explanation should either be quoted or emitted as a
block scalar.

Before presenting the final output, run the conformance checklist from the
attached spec — including the Word Explorer pack quality and Word Explorer
Guide quality subsections — and confirm it passes. Then present all five
files, each in its own labeled code block.
```

---

## Review the Results

Even with a well-defined workflow, every generated document should be reviewed.

Look for questions such as:

- Are the chunk boundaries meaningful?
- Are literal translations truly literal?
- Does the natural translation sound natural?
- If `phonetic` fields are included, are they concise, consistent, and useful for a beginner?
- Do chunk-level `phonetic` values match only the chunk source, not the full sentence?
- Do the hints encourage another attempt?
- Are vocabulary references complete?
- Does every `vocabulary_refs` item have a matching companion vocabulary entry?
- Are vocabulary notes concise and useful?
- Does the vocabulary pack use `prompt` and `answer` so it can be studied directly?
- Would I enjoy learning from this document?

The objective is not to ask the LLM for perfection.

The objective is to produce a high-quality first draft that a human author can refine into an excellent learning resource.

---

## The LLM Is an Assistant, Not an Authority

This guide is intentionally opinionated. It reflects the workflow that proved successful while developing Linguatrain and while learning Finnish myself.

Finally, I can't stress enough that an LLM is a **helper**, not an authority. It will make mistakes. It can present an answer with complete confidence that is simply wrong because it has missed a nuance, misunderstood the context, or chosen an incorrect interpretation. This is why collaboration and independent verification remain important.

Many years ago, when I worked for a technology company, our documentation was translated by one translation company and then independently reviewed by another. The goal wasn't to prove the first company was wrong; it was to improve quality through verification.

I recommend the same workflow here.

Let the LLM produce the first draft. Review it critically. If something doesn't feel right, verify it. Ask a native speaker. Consult a teacher. Compare another translation. Use language forums to verify individual sentences. Most people are happy to explain a few phrases, even if they aren't going to translate an entire book.

The purpose of the LLM is not to replace human expertise.

Its purpose is to accelerate the mechanical work so that the human author can focus on what matters most:

> Creating translation material that helps someone truly understand another language.

---

# Translation

The Translation pack is the foundation of every Linguatrain lesson.

It is the canonical educational artifact from which all companion learning packs are derived. While vocabulary packs teach individual words and conjugation packs teach grammatical patterns, the Translation pack teaches learners how those pieces come together to express complete ideas.

Every design decision described in this chapter—from metadata and schema design to chunking, literal translations, hints, and pronunciation guidance—exists to support that educational objective.

A well-designed Translation pack should enable a learner to progress from recognizing individual words to understanding complete sentences while gradually developing an intuition for how the language expresses meaning.

---

## Translation Is Canonical

The translation pack is the canonical educational source for a lesson.

All companion learning packs are derived from the translation pack and should remain consistent with it.

Translation packs establish:

- the source text,
- semantic chunking,
- literal translations,
- natural translations,
- vocabulary references,
- grammar references,
- and the overall educational flow.

Companion packs expand upon this foundation rather than redefining it. Companion packs should never introduce concepts that are not supported by the translation pack itself.

```
Translation Pack
        │
        ├── Vocabulary Pack
        │
        ├── Conjugation Pack
        │
        ├── Word Explorer Pack (morphology)
```

If a discrepancy exists between a translation pack and one of its companion packs, the translation pack is considered canonical.

Companion packs should be updated to maintain consistency.

---

## Required Top-Level Metadata

The `metadata` section describes the translation pack itself rather than the educational content contained within it.

Every translation pack must include the following metadata.

```yaml
metadata:
  id:                   must always be enclosed in single quotes.
  title:
  type: translation
  format:
  version:
  schema_version:
```

---

### `id`

A unique identifier for the translation pack.

**Must**

- be unique across all translation packs.
- remain stable once published.
- be suitable for referencing from companion packs.
- be enclosed in single quotes.
- 
**Should**

- be lowercase.
- use underscores rather than spaces.
- describe the content rather than the file name.

Example:

```yaml
id: 'suomen_mestari_1_chapter_2_translation'
```

---

### `title`

A human-readable title displayed to learners and authors.

This field is intended for presentation rather than internal references.

**Should**

- clearly identify the lesson or source material.
- use natural capitalization.
- be descriptive.

Example:

```yaml
title: Suomen Mestari 1 – Chapter 2
```

---

### `type`

Identifies the type of Linguatrain pack.

For this handbook the value is always

```yaml
translation
```

**Must**

Always be

```yaml
translation
```

No other values are valid for translation packs.

---

### `format`

Describes the organizational structure of the translation pack.

The format determines how the content is presented to the learner.

Valid values are:

- `narrative`
- `conversation`

Use `narrative` for continuous prose, stories, articles, descriptions, instructions, signs, or other text that is not primarily dialogue.

Use `conversation` for content structured as spoken dialogue between two or more speakers.

**Must**

Use one of the two supported values:

```yaml
format: narrative
```

or

```yaml
format: conversation
```

No other values are currently valid.

**Note**: metadata.format describes the structure of the entire translation pack, while an entry’s type describes the role of an individual entry within that structure. A conversation pack may legitimately contain both dialogue and narrative entries.

---

### `version`

The content version of the pack.

Increment this value whenever the educational content changes.

Examples include:

- corrected translations
- revised chunking
- updated hints
- added vocabulary references

Do not increment the version for unrelated tooling changes.

---

### `schema_version`

The version of the Linguatrain Translation Schema used to author the file.

Unlike `version`, this value tracks the schema itself rather than the educational content.

For the current edition of this handbook, all translation packs **must** use:

```yaml
schema_version: 1
```

This value only changes when the Linguatrain Translation Schema itself changes. Individual lesson revisions, corrections, new hints, improved chunking, or additional vocabulary references do **not** affect the schema version.

A pack may have:

```yaml
version: 8
schema_version: 1
```

indicating that the lesson has undergone multiple content revisions while continuing to conform to Schema Version 1.


---

## Entry Field Definitions

Each exercise is represented by a single `entry`.

Every field exists for a specific educational purpose. Authors should not duplicate information across fields or repurpose fields for unrelated content.

```yaml
- id:               # must always be enclosed in single quotes.
  type:             # optional
  speaker:          # optional
  source:
  phonetic:         # optional
  literal:
  target:
  chunks:
  vocabulary_refs:  # optional
  grammar:          # optional
    refs:           # optional
```

**Important**: The runtime accepts additional formats for backwards compatibility. Authors **must** produce only the canonical schema described in this handbook.

### Required Fields

- id                # must always be enclosed in single quotes.
- source
- literal
- target
- chunks

### Optional Fields

- type
- accepted
- speaker
- phonetic
- vocabulary_refs
- grammar

---

## Field Definitions

### `id`

A unique identifier for the entry and **must** always be enclosed in single quotes..

**Must**

- be unique within the translation pack.
- remain stable once published.
- be treated as an identifier rather than a sequence number.
- be enclosed in single quotes.

**Should**

- be short and human-readable.
- follow the naming conventions established by the pack.

This field is used internally for references and progress tracking.

---

### `type`

Describes the nature of the text.

Valid values are:

- `narrative`
- `dialogue`

Use `narrative` for non-spoken text such as:

- introductions
- scene descriptions
- exposition
- signs
- captions
- narration

Use `dialogue` for spoken language where a speaker is identified.

**Must not**

Use any other value.

If omitted, the entry is treated as ordinary instructional content.

---

### `accepted`

Optional alternative translations that should be considered correct.

Translation is not an exact science.

Many source phrases can be translated naturally in more than one way.

The `accepted` field allows Linguatrain to recognize valid learner responses while still presenting a single preferred translation in `target`.

**May**

Include alternative translations that:

- preserve the original meaning,
- sound natural in English,
- differ only in wording or style,
- or represent common regional variations.

Examples include:

```yaml
target: soccer

accepted:
  - football
```

```yaml
target: 'at 7:15'

accepted:
  - 'at seven fifteen'
  - 'at seven-fifteen'
  - 'at 7:15 AM'
```

```yaml
target: I am at work

accepted:
  - I work
```

**Should not**

Use `accepted` to compensate for poor chunking or incorrect translations.

Every accepted answer should be something a fluent speaker would naturally say.

---

### `speaker`

Identifies the speaker for dialogue entries.

This field should only be used when the text is spoken by an identifiable person or character.

Do not use this field for narration or descriptive text.

---

### `source`

The original language text presented to the learner.

This is the canonical source from which all other educational content is derived.

**Must**

- exactly match the source material.
- preserve spelling and punctuation.
- preserve word order.

Do not simplify or rewrite the original language.

---

### `phonetic`

Optional pronunciation guidance.

This field exists solely to help beginning learners pronounce unfamiliar text.

It is not intended to replace listening practice.

If provided, pronunciation should follow the phonetic conventions defined for the language being authored.

---

### `literal`

A structural translation that exposes how the source language expresses meaning.

Literal translations intentionally preserve source-language structure, even when the resulting English sounds unnatural.

Their purpose is to help learners understand how the language works.

**Should**

- preserve word order where practical.
- expose grammatical structure.
- avoid rewriting into natural English.

Literal translations are educational tools—not polished translations.

---

### `target`

The preferred natural translation.

This should represent how a fluent speaker would naturally express the idea in English.

**Should**

- sound natural.
- preserve the intended meaning.
- avoid unnecessary literal wording.

There should be one preferred translation.

Alternative acceptable answers belong in the appropriate answer fields, not here.

---

### `chunks`

A list of semantic translation units used during interactive translation.

Chunks are one of the defining features of Linguatrain.

They allow learners to build a sentence piece by piece while receiving targeted feedback.

**Must**

- preserve the original word order.
- represent meaningful language units.
- cover the entire source sentence.

**Should**

- be the largest reusable semantic unit.
- keep fixed expressions together.
- avoid splitting verb phrases unnecessarily.

Chunks should be divided according to meaning—not grammar.

---

### `vocabulary_refs`

References to vocabulary entries introduced or reinforced by this sentence.

These references connect the translation pack to the companion vocabulary pack.

**Must**

- reference dictionary lemmas.
- contain only valid vocabulary IDs.

Do not reference inflected forms.

---

### `grammar`

Optional references to grammar topics demonstrated by the sentence.

Grammar references connect the learner to reusable grammar explanations without embedding lengthy grammar discussions inside each entry.

Grammar entries should explain structure, usage, or patterns—not individual vocabulary.

  **Source line**

  `Anteeksi, onko täällä suomen kurssi?`

  **Chunks from the source**

  `Anteeksi onko täällä suomen kurssi`

  **Literal translation of each chunk**

  `Excuse me Is here Finnish course`

  When combined, those chunk translations
  produce the sentence's literal
  translation:

  `Excuse me, is here Finnish course?`

  Notice that the literal translation
  sounds unnatural in English. That is
  intentional. Literal translations expose
  how the original language is constructed
  before the learner moves on to the
  natural translation.

  Each chunk should represent something a
  learner can recognize and reuse later.
  
---

## Every Chunk Mirrors the Entry

``` yaml
chunks:
  - id:            # must always be enclosed in single quotes.
    source:
    phonetic:      # optional
    literal:
    target:
    hint:
```

This recursive structure is intentional.

A learner first understands the chunk.

The sentence is then assembled from understood chunks.

---

## Chunking Guidelines

Chunking is one of the most important aspects of a translation document.

A chunk should represent a **complete unit of meaning** that a learner
can understand, remember, and reuse in future sentences.

The goal is not to make the chunks as small as possible. The goal is to
divide the sentence into pieces that naturally carry meaning.

Good chunks include:

-   noun phrases
-   verb phrases
-   fixed expressions
-   idiomatic expressions
-   complete grammatical units

These guidelines are intentionally opinionated rather than prescriptive.

Understanding *why* a recommendation exists is more valuable than
following it mechanically. If a different chunk boundary better serves
the educational objective, prefer the educational outcome over rigid
consistency.

Avoid:

-   splitting a phrase that naturally belongs together
-   making chunks so large that they become difficult to translate
-   breaking apart expressions that learners will encounter again as a
    unit

### Good Examples

### Fixed expression

``` text
Hauska tutustua
```

This is a complete expression meaning *"Nice to meet you."*

Although it contains two words, learners recognize and use it as a
single phrase.

---

### Idiomatic greeting

``` text
Mitä kuuluu?
```

This is a fixed greeting *"How are you?"*.

Teaching it as one unit helps the learner recognize it immediately in
future conversations.

---

### Noun phrase

``` text
suomen kurssi
```

This is a complete noun phrase *"Finnish course"*.

The learner should associate the phrase with the concept "Finnish
course" rather than translating each word independently every time.

---

### Verb phrase

``` text
tuli katsomaan
```

These words express a single action:

> came to see

Separating them removes the relationship between the motion verb and the
infinitive.

### Poor Examples

### Splitting a fixed expression

``` text
Hauska
tutustua
```

Neither chunk represents the meaning the learner is trying to acquire.

The learner would first translate two unrelated pieces and then have to
reconstruct the expression afterward.

The goal is to recognize **"Hauska tutustua"** immediately as one
communicative phrase.

---

### Chunk by Meaningful Units

Chunks should represent complete ideas whenever possible.

**Poor:**

```text
suomen
kurssi

Finnish
course
```

**Better:**

```text
suomen kurssi

Finnish course
```

Although either version is technically correct, **suomen kurssi** is a single noun phrase. Presenting it as one chunk encourages learners to recognize the complete concept rather than reconstructing it from individual words.

---

**Good:**

```text
hyvää huomenta

good morning
```

A greeting is typically understood as a single expression rather than two independent words.

---

**Good:**

```text
minun mielestäni

in my opinion
```

This common expression is best learned as a single unit because its meaning is more useful than the individual words in isolation.

Split a phrase into smaller chunks only when your instructional goal is to teach its internal grammar or structure rather than the expression itself.

---

### Guiding Principle

Whenever possible, chunk according to **meaning**, not simply by word
boundaries.

A learner should be able to look at a chunk and think:

> "I've seen this before."

rather than:

> "Now I need to assemble these words back into a phrase."

---

### Chunking Example

The following entry from **Meidän tavallinen päivä**, provided as the canonical document, demonstrates
effective chunking. Notice that each chunk represents a complete
semantic unit while also introducing useful vocabulary and grammar
references.

``` yaml
source: Minulla on vaimo ja kaksi lasta.
target: I have a wife and two children.
literal: On me is wife and two children.

chunks:
  - source: Minulla on
    target: I have
    hint: Finnish possession uses subject pronoun + on.

  - source: vaimo
    target: wife

  - source: ja
    target: and

  - source: kaksi lasta
    target: two children
    hint: After numbers, Finnish uses the partitive singular.
```

This example illustrates semantic chunking, targeted hints, and
supporting grammar references without overwhelming the learner. It
should be viewed as the preferred style for future translation packs.

---

### Literal vs Natural Translation

Example:

Source

    pillin äänen

Literal

    whistle's sound

Natural

    the sound of a whistle

The literal, in this example, teaches how Finnish is constructed.

The natural translation, in this example, teaches how English expresses
the same idea.

Both are valuable.

### The Purpose of Literal Translation

The `literal` translation is one of the defining features of Linguatrain.

The purpose of the `literal` field is to teach the source language—not to produce elegant English.

A literal translation reveals how the source language expresses meaning by preserving its structure, even when the resulting English sounds unusual or awkward.

The learner can then compare the literal translation with the natural translation to understand both how the language works and how the same idea is naturally expressed in English.

---

## Pronunciation / Phonetic Guidance

Translation entries may include an optional `phonetic` field. Chunks may
also include their own optional `phonetic` field.

Use the singular field name:

``` yaml
phonetic:
```

`phonetic` is a beginner-friendly pronunciation guide for the `source`
text. It is not a replacement for audio, IPA, or a formal linguistic
transcription. Its purpose is to help the learner make a reasonable
first attempt at reading the source-language text aloud.

Every chunk **must** contain its own phonetic field whenever pronunciation guidance is provided for the parent entry. Chunk phonetics should correspond exactly to only the chunk text.

Example:

``` yaml
- id: 'e001'
  type: dialogue
  speaker: Alex
  source: "Anteeksi, onko täällä suomen kurssi?"
  phonetic: "AHN-tehk-see, OHN-koh TAAH-la SOO-oh-men KOORS-see?"
  literal: "Excuse me, is here Finnish course?"
  target: "Excuse me, is the Finnish course here?"
  chunks:
    - id: 'c001'
      source: "Anteeksi"
      phonetic: "AHN-tehk-see"
      literal: "Excuse me"
      target: "Excuse me"

    - id: 'c002'
      source: "onko"
      phonetic: "OHN-koh"
      literal: "is?"
      target:
        - "is"
        - "is it"
        - "is there"
```

## When Linguatrain Displays Pronunciation

Pronunciation is intentionally hidden unless the learner requests it.

In translation mode, the learner can enable pronunciation with:

``` bash
--show-phonetic
```

When enabled, Linguatrain may display pronunciation:

-   under the full source sentence at the start of an exercise
-   for missed chunks after an incorrect answer
-   for remaining chunks during retry
-   when the learner asks to show the answer

This follows the general Linguatrain principle of progressive
disclosure: show pronunciation when it helps the learner, but do not
clutter the default translation exercise.

## Pronunciation Guidance to Include in LLM Prompts

When asking an LLM to generate translation YAML, tell it to include `phonetic` when pronunciation would help the learner. This is especially useful for beginner packs,
textbook samples, dialogue, unfamiliar names, difficult compounds, and
languages where spelling does not reliably predict pronunciation.

For Finnish beginner material, prefer readable approximations that
preserve important learner distinctions:

-   mark long vowels with doubled vowel letters where helpful, such as
    `TAAH-la` for `täällä`
-   keep doubled consonants visible, such as `KOORS-see` for `kurssi`
-   avoid overexplaining inside the `phonetic` field
-   preserve distinctions that materially affect pronunciation in the
    source language
-   keep the guide short enough to scan while translating
-   use the same style consistently across entries and chunks
-   if pronunciation cannot be represented clearly and reliably, omit
    `phonetic`

Bad:

``` yaml
phonetic: "This is pronounced with a long ä sound and a long s..."
```

Good:

``` yaml
phonetic: "TAAH-la"
```

Entry-level `phonetic` should cover the complete `source` sentence or
line.

Chunk-level `phonetic` should cover only that chunk's `source`.

If the LLM is not confident in a pronunciation guide, it should omit
`phonetic` rather than invent an unreliable one.

---

## Symbolic Values and Spoken Forms

Source Text is Authoritative

The source field is authoritative and must preserve the original text exactly as it appears in the source material.

Do not replace symbolic values with lexical words.

**Correct**
```yaml
source: kello 6
```
**Incorrect**
```yaml
source: kello kuusi
```

## Phonetic Represents the Spoken Source Language

The phonetic field represents how the source text is naturally spoken, not how it is written.

When the source contains symbolic values, such as numbers, times, dates, currency, percentages, measurements, or other symbolic notation. The phonetic field must expand those symbols into the words a native speaker would actually say.

**Examples (Finnish)**
```yaml
source: kello 6
phonetic: KEHL-loh KOO-see
```

```yaml
source: kello 7.15
phonetic: KEHL-loh SAYT-seh-mahn VEE-see-tois-tah
```

```yaml
source: 15 €
phonetic: VEE-see-tois-tah EUR-oh-ah
```

The learner should be able to read the phonetic aloud naturally even when the source contains symbols.

## Vocabulary Extraction

Symbolic values are never considered lexical vocabulary.

Do not create vocabulary entries solely because a symbolic value appears.

**Incorrect**
```yaml
source: kello 6

vocabulary_refs:
  - kuusi
```
**correct**
```yaml
source: kello 6

vocabulary_refs:
  - kello
```
**Important**: The lexical word kuusi does not occur in the source text and is not extracted as vocabulary. Do not infer lexical vocabulary from symbolic notation, even when the spoken pronunciation is known.

## Translation Hints

When the spoken form differs from the written form because of symbolic notation, explain the relationship between the written symbolic form and its natural spoken form in the translation hint.

**Example:**

```yaml
hint: >
  Kello introduces clock time. Although the source uses the numeral "6",
  Finnish speakers read it aloud as "kuusi".
```
The source field preserves what the learner sees. The phonetic field represents what the learner hears.

The phonetic field is a pronunciation aid, not a transliteration. It should represent natural spoken source language even when doing so requires expanding symbols into their spoken lexical forms.

### Design Invariant

* The source field preserves what the learner sees.
* The phonetic field represents what the learner hears.
* The vocabulary pack contains only lexical items that actually appear in the source text (or their lemmas).

These responsibilities are intentionally different and must not be merged.

---

## Choosing Accepted Answers

Accepted answers should improve the learner's experience without lowering educational standards.

Good accepted answers account for:

- articles ("a", "the")
- contractions
- common synonyms
- regional vocabulary
- alternative time expressions
- equally natural word order

Examples:

```yaml
target: 'at 6:00'

accepted:
  - at six
  - "at six o'clock"
```

```yaml
target: football

accepted:
  - soccer
```

```yaml
target: We swim for two hours.

accepted:
  - We swim two hours.
```

Avoid adding accepted answers that:

- change the meaning,
- weaken grammar,
- or encourage unnatural English.

The goal is to recognize valid learner responses—not every conceivable translation.


---

## Hints

Hints exist to help the learner continue making progress without
immediately revealing the answer.

A good hint provides just enough information for the learner to solve
the remaining translation independently.

Hints should guide the learner, not replace the learning process.

---

## When to Use Hints

Hints are most valuable when they:

-   explain an unfamiliar word or expression
-   identify a fixed phrase or idiom
-   clarify a chunk whose meaning is not immediately obvious
-   provide enough context for the learner to continue translating

Hints should encourage another attempt rather than end the exercise.

---

## Good Hints

A good hint removes the immediate obstacle while allowing the learner to
complete the translation.

Examples:

> `"täällä" means "here".`

> `"Mitä kuuluu?" is a common greeting meaning "How are you?"`

> `"Hauska tutustua" is a fixed expression used when meeting someone.`

> `"kirjoitetaan" literally means "is written" and is commonly used when asking how something is spelled.`

Each of these gives the learner enough information to continue
translating the sentence without revealing the entire answer.

---

## Poor Hints

Hints should not become grammar lessons.

Avoid explanations such as:

> Several paragraphs explaining Finnish interrogatives.

or

> A complete discussion of the passive voice.

These belong elsewhere.

The learner asked for a hint, not a chapter of a grammar textbook.

---

## A Design Principle

A learner should finish reading a hint thinking:

> "I know enough to try again."

not

> "The exercise has already been solved for me."

---

## What Makes a Good Translation Document?


A good document should allow the learner to:

1.  Read the original language.
2.  Decode it chunk by chunk.
3.  Understand the literal structure.
4.  Produce natural English, or other secondary language.
5.  Learn reusable phrases.
6.  Discover grammar naturally through references.

---

## Final Design Principles

-   Model the learner, not the textbook.
-   Literal translation is a learning tool, not documentation.
-   Chunk meaningful phrases rather than isolated words.
-   Keep grammar explanations separate from translation.
-   Prefer simple, consistent YAML over clever abstractions.
-   Make every entry independent and reusable.

This schema is intended to support dialogues, stories, museum signs,
recipes, news articles, and other real-world content without
modification.

---
# Vocabulary

The companion Vocabulary pack bridges the gap between recognizing words in a translation and building a reusable mental lexicon.

While the Translation pack teaches how ideas are expressed in complete sentences, the Vocabulary pack teaches the individual words, phrases, and expressions that make those sentences possible.

Vocabulary entries should prepare the learner for future translation exercises by introducing meaningful lexical items, preserving their relationship to their underlying dictionary forms, and providing just enough enrichment to make each entry a reusable learning resource.

---

## Vocabulary Packs

Vocabulary packs are derived from the vocabulary introduced or reinforced within the translation pack.

Vocabulary entries should:

- follow the Lemma Invariant,
- contain only dictionary lemmas as their canonical identity,
- provide meaningful educational enrichment,
- and support the learner's understanding of the translation.

---

### Creating a Vocabulary Pack without Translation Using an LLM

There may be times when you want to create your own vocabulary list without first creating a Translation pack. This can be done manually or with help from an LLM.

When using an LLM, provide the `05_Linguatrain_LLM_Authoring_Specification.md` file along with your vocabulary list.

---

#### Copy-Ready Vocabulary Prompt

Copy the following prompt into the LLM after attaching the listed files. Edit the metadata values before sending it.

```Text
Attached:
1. Linguatrain_LLM_Authoring_Specification.md — the authoring spec
2. [canonical_example_vocabulary].yaml — a canonical Vocabulary pack, for style/structure reference
3. [raw_word_list].txt — the raw word list to generate from

Task: Using §2.1 and §5.0 of the attached specification (vocabulary-only
mode — no Translation pack exists or is wanted here), generate a new
canonical Vocabulary pack YAML file from the attached raw word list. Use
the attached canonical example only as a structural/style reference — do
not copy or reuse any of its lexical content.

Lesson metadata for this pack:
- id: '[name of txt file]'
- title: '[Select a name for this YAML file]'
- source_list: [raw_word_list filename]
- version: 1
- schema_version: 1

Before producing the YAML, run the §5.0 preprocessing steps explicitly
(case normalization, dedup, exclusion of non-lexical tokens, same-lemma
collapsing, near-form disambiguation, metalinguistic-term flagging) and
report anything you flagged under §5.0(e) or §5.0(f) — ambiguous lemmas or
metalinguistic terms — as a short list before the YAML, so I can confirm
those calls. Then run the §9 conformance checklist (including the
vocabulary-only-mode subsection) and confirm it passes before presenting
the final YAML in a single code block.
```



---

## Vocabulary Entry Schema

Every vocabulary entry represents a single reusable lexical item.

Each field exists for a specific educational purpose. Authors should include only the fields that improve the learner's understanding of the word or phrase.

```yaml
- id:             # must always be enclosed in single quotes.
  prompt:
  answer:
  type:           # optional
  literal:        # optional
  phonetic:       # optional
  forms:          # optional
  heard_as:       # optional
  notes:          # optional
```

**Required Fields**

- `id`
- `prompt`
- `answer`

**Optional Fields**

- `type`
- `literal`
- `phonetic`
- `forms`
- `heard_as`
- `notes`

---

## Field Definitions

### `id`

The canonical dictionary form (lemma) used as the stable identity for the vocabulary entry.

This value is referenced by `vocabulary_refs` in Translation packs and serves as the canonical identifier for companion learning packs.

---

### `prompt`

The learner-facing vocabulary item.

This will normally contain the exact surface form encountered in the source text, allowing learners to immediately recognize the word they just read.

---

### `answer`

One or more acceptable meanings in the learner's language.

The first answer should normally be the preferred translation.

Additional answers may be included when they represent equally common meanings.

---

### `type`

An optional classification describing the lexical item.

Examples include:

- noun
- verb
- adjective
- adverb
- pronoun
- conjunction
- phrase
- postposition
- number
- proper_noun

---

### `literal`

An optional literal explanation when it provides educational value.

Most vocabulary entries do not require this field.

---

### `phonetic`

Optional pronunciation guidance intended for beginning learners.

Pronunciation should be concise, readable, and consistent throughout the pack.

---

### `forms`

Optional educational morphology connecting the encountered surface form back to the canonical lemma.

Include only forms that improve learning.

Complete paradigms belong in the companion Conjugation pack.

---

### `heard_as`

Optional alternate spellings or pronunciations that improve speech recognition.

This field exists primarily to improve Whisper recognition and should contain plausible recognition variants rather than alternate meanings.

---

### `notes`

Optional learner-focused observations.

Notes should remain concise and teach one useful idea rather than becoming a grammar lesson.

---

## Vocabulary Candidate Selection and Normalization

Before generating vocabulary entries, authors SHALL perform lexical analysis on the source text to identify studyable vocabulary candidates.

---

## Guiding Principle

The companion vocabulary pack is a learning resource, not a dictionary.

Vocabulary entries should teach the lexical forms that the learner actually encounters while preserving links to their underlying dictionary forms.

The goal is not to build a comprehensive dictionary, but to help learners recognize, understand, and remember the forms they see while reading.

---

## Educational Priority

When deciding between the encountered form and the dictionary form, prioritize the learner's experience.

The learner should immediately recognize the vocabulary item from the source text while still being able to discover its underlying dictionary form through the associated morphological information.

The vocabulary pack teaches the language the learner encountered.

The lemma exists to support linking, morphology, conjugation, search, and future lessons.

---

## Candidate Selection

Vocabulary entries **must** be generated only from lexical items and other meaningful units that contribute to the comprehension in the source text. 

Candidate lexical items include:

- ordinary words
- inflected words
- compounds
- lexicalized fixed expressions
- words carrying meaningful grammatical information including:
  - interjections
  - discourse markers
  - fixed expressions
  - conjunctions

Do **not** generate vocabulary entries from non-lexical symbolic tokens.

Examples include:

- digits
- timestamps
- dates
- percentages
- currencies
- measurements
- punctuation
- formatting symbols

### Example (Finnish)

Source text:

```text
Minulla on vaimo ja kaksi lasta.
```

Generates:

```yaml
- id: 'kaksi'
  prompt: kaksi
  answer:
    - two
    - "2"
```

because **kaksi** is a lexical item appearing in the source.

### Example (English)

Source text:

```text
The meeting starts at 7:15.
```

Must **not** generate:

```yaml
- id: 'seven'
- id: 'fifteen'
```

The source contains a timestamp, not the lexical words *seven* or *fifteen*.

Translation exercises may explain timestamps, but symbolic values do not generate vocabulary entries.

---

## Surface Form First

When the learner encounters an inflected or derived form, the vocabulary entry should teach **that encountered form**.

The `prompt` field SHALL normally contain the exact surface form appearing in the source text.

The learner should immediately recognize the vocabulary item from the reading passage.

### Example (Finnish)

Source:

```text
Minulla on...
```

```yaml
id: 'minä'
prompt: Minulla
answer: I have / on me

forms:
  lemma: minä
  adessive: Minulla
```

---

### Example (Spanish)

Source:

```text
Hablo español.
```

```yaml
id: 'hablar'
prompt: hablo
answer: I speak

forms:
  lemma: hablar
  present_1sg: hablo
```

---

### Example (German)

Source:

```text
Die Häuser sind alt.
```

```yaml
id: 'Haus'
prompt: Häuser
answer: houses

forms:
  lemma: Haus
  plural: Häuser
```

The learner studies the encountered form while the system preserves the underlying dictionary form.

---

## Lemma Identity

The `id` uniquely identifies the dictionary form (lemma). It exists as the stable identifier for the entry and must always be enclosed in single quotes.

The `prompt` identifies the surface form presented to the learner.

These intentionally represent different concepts.

### Example (Finnish)

```yaml
id: 'mennä'
prompt: menemme

forms:
  lemma: mennä
  present_1pl: menemme
```

### Example (Spanish)

```yaml
id: 'ir'
prompt: vamos

forms:
  lemma: ir
  present_1pl: vamos
```

The learner studies the encountered form while Linguatrain links related forms back to a single dictionary entry.

---

## Named Entities

Named entities should not automatically generate vocabulary entries.

Examples include:

- people
- companies
- organizations
- products
- events

Named entities are **normally excluded** from vocabulary generation. They may be included only when they provide measurable instructional value beyond simple identification.

Common examples include place names that appear in inflected forms.

### Example (Finnish)

Source:

```text
Asun Helsingissä.
```

YAML entry:

```yaml
id: 'Helsinki'
prompt: Helsingissä
answer: in Helsinki

type: place

forms:
  lemma: Helsinki
  inessive: Helsingissä

notes:
  - The ending -ssä expresses location inside something ("in").
```

### Counterexample

Source:

```text
Tuula kävelee kotiin.
```

Should **not** generate:

```yaml
id: 'Tuula'
prompt: Tuula
answer: Tuula
```

because the learner gains no meaningful vocabulary or grammatical insight.

---

## Canonical Lemma Principle

Every vocabulary entry is anchored to a single canonical dictionary form (lemma).

The `id` identifies this canonical form and serves as the stable identity used for linking translation packs, vocabulary packs, conjugation packs, and future companion packs.

The learner-facing `prompt` may contain either the lemma or the encountered surface form, depending on the educational goals described in the Vocabulary Pack Generation section.

This separation allows multiple encountered forms to share a single lexical identity while presenting learners with the language exactly as it appeared in the source text.


---

## Vocabulary Entry Enrichment

After selecting the vocabulary candidates, enrich each entry so it becomes a reusable learning resource rather than a simple dictionary definition.

The companion vocabulary pack should help learners understand the lesson, recognize the same words in future readings, and prepare for future Linguatrain exercise types.

### Enrichment

Depending on the lexical item, enrich the vocabulary entry with information such as:

- phonetic pronunciation
- alternate accepted translations
- literal meanings where helpful
- usage notes
- common learner mistakes
- compound-word breakdowns
- `heard_as` values for Whisper recognition
- pedagogically useful morphological forms

Not every entry requires every field.

Include only information that improves the learner's understanding of the word.

---

## Morphological Forms

When a vocabulary entry appears in an inflected form within the lesson, record that relationship in the `forms` section whenever it provides meaningful instructional value.

The `forms` section connects the learner's encountered surface form with the vocabulary entry's canonical lemma.

This allows learners to recognize the form they encountered while preserving a single lexical identity for linking, search, morphology, and future lessons.

For example, if the learner encounters:

```text
Minulla on kaksi lasta.
```

the vocabulary entry remains anchored to the canonical lemma:

```yaml
id: 'lapsi'
prompt: lasta
answer: child

forms:
  lemma: lapsi
  partitive_singular: lasta
```

Likewise:

```text
Asun Helsingissä.
```

becomes:

```yaml
id: 'Helsinki'
prompt: Helsingissä
answer: in Helsinki

type: place

forms:
  lemma: Helsinki
  inessive: Helsingissä

notes:
  - The ending -ssä expresses location inside something ("in").
```

The learner studies the encountered form while Linguatrain preserves the canonical identity.

---

### Guidelines

The `forms` section is intended to capture **educationally valuable** forms—not complete grammatical paradigms.

Prefer forms that:

- appear in the lesson
- illustrate an important grammatical pattern
- reinforce morphology introduced elsewhere
- are likely to be encountered again by learners

Avoid exhaustive declensions or conjugations.

Complete paradigms belong in the companion Conjugation pack.

---

### Canonical Identity

The presence of a `forms` section never changes the vocabulary entry's identity.

The `id` always remains the canonical dictionary lemma.

Correct:

```yaml
id: 'kahvi'
```

Not:

```yaml
id: 'kahvia'
```

The learner-facing `prompt` may contain the encountered surface form, but the vocabulary entry always retains a single canonical identity for cross-referencing throughout Linguatrain.

---


## Vocabulary Notes

Vocabulary `notes` should contain short, learner-useful observations
that make the word or phrase easier to recognize, remember, or use.

Include notes for information that helps avoid common learner mistakes,
such as:

-   idiomatic usage
-   common collocations
-   compound word breakdowns
-   important case usage
-   common learner confusions
-   words whose meaning differs from a similar-looking English word

Examples:

``` yaml
notes:
  - '“Tässä on...” is often used when introducing someone or presenting something.'
```

``` yaml
notes:
  - 'Compound: kurssi + päivä. Plural: kurssipäivät.'
```

``` yaml
notes:
  - 'Can mean “place” generally or “seat” in a classroom context.'
```

Keep notes concise. They should add one useful teaching point, not
become a grammar lesson. Longer grammatical explanations belong in
grammar documentation or in a chunk hint when the learner needs that
information to complete the translation.

---
### Vocabulary Pack Shape

Companion vocabulary packs should use the normal Linguatrain vocabulary
schema so they can be studied directly before the translation exercise.

``` yaml
metadata:
  id: 'suomen_mestari_1_kappale_01_vocabulary'
  title: Suomen Mestari 1 - Kappale 1 Vocabulary
  type: vocabulary
  format: canonical
  version: 1
  schema_version: 1
  source_pack: suomen_mestari_1_kappale_01_translation

entries:
  - id: 'tervetuloa'
    prompt: tervetuloa
    type: phrase
    notes:
      - 'Often followed by the allative case: “kurssille” = “to the course”.'

  - id: 'kirjoittaa'
    prompt: kirjoittaa
    answer:
      - to write
      - to spell
    type: verb
    notes:
      - 'In spelling questions, Finnish often uses passive “kirjoitetaan” = “is written/spelled”.'
```

Use `prompt` for the source-language word or phrase and `answer` for the
target-language meaning.

Use the entry `id` as the canonical reference value used by
`vocabulary_refs` in the translation document.

For example, this translation entry:

``` yaml
vocabulary_refs:
  - tervetuloa
  - suomen kurssi
```

should point to vocabulary entries whose IDs match those references. If
a reference contains spaces or characters that are awkward in IDs,
prefer a normalized ID such as `suomen_kurssi`, and use that same
normalized ID consistently in `vocabulary_refs`.


---

# Conjugation

The companion Conjugation pack teaches learners how verbs change as they are used in different grammatical contexts.

While the Translation pack teaches how complete ideas are expressed and the Vocabulary pack teaches individual lexical items, the Conjugation pack focuses exclusively on verb morphology. Its purpose is to help learners recognize and produce the patterns that govern verb inflection in the target language.

Conjugation packs are always derived from the companion Vocabulary pack, which in turn is derived from the Translation pack. They should never introduce verbs that are not referenced by the lesson's vocabulary.

---

## Conjugation Packs

Conjugation packs are derived from the verb lemmas referenced within the companion vocabulary pack.

Conjugation entries should:

- follow the Canonical Lemma Principle,
- contain only dictionary-form verbs (lemmas),
- provide complete conjugation paradigms appropriate for the target language,
- reinforce the verb forms introduced by the translation pack,
- and support the learner's understanding of the translation.

---

## Conjugation Entry Schema

Every conjugation entry represents a single canonical verb.

Each field exists to support a specific aspect of verb study. Authors should include only language-appropriate conjugation data while maintaining a consistent structure throughout the pack.

```yaml
metadata:
  id:                 # always single quote IDs
  title:
  type: conjugation
  format: canonical
  version:
  schema_version:
  source_pack:

persons:
  - ...

entries:
  - id:                # always single quote IDs
    lemma:
    forms:
```

### Required Metadata

- `id`                # always single quote IDs
- `title`
- `type`
- `format`
- `version`
- `schema_version`
- `source_pack`

### Required Entry Fields

- `id`                 # always single quote IDs
- `lemma`
- `forms`

---

## Field Definitions

### `id`

A unique identifier for the conjugation entry **must** always be enclosed in single quotes.

This identifier is local to the conjugation pack and should remain stable once published.

---

### `lemma`

The canonical dictionary form of the verb.

This is the identity of the conjugation entry and should always match the lemma referenced by the companion Vocabulary pack.

---

### `forms`

The language-specific conjugation paradigm.

The exact structure depends on the target language, but should consistently represent the verb's inflected forms according to the established Linguatrain conjugation schema.

---

### `persons`

An optional top-level convenience list describing the grammatical persons represented throughout the conjugation pack.

Languages that organize conjugations differently may use an alternative structure while preserving consistency throughout the pack.

For example, Finnish naturally organizes verbs by grammatical person:

```yaml
forms:
  minä:
  sinä:
  hän:
  me:
  te:
  he:
```

Spanish might additionally organize forms by tense and mood:

```yaml
forms:
  present:
    yo:
    tú:
    él:
    nosotros:
    vosotros:
    ellos:

  preterite:
    yo:
    tú:
    ...
```

French could distinguish moods such as the indicative and subjunctive:

```yaml
forms:
  indicative:
    present:
    imperfect:
    future:

  subjunctive:
    present:
```

German might include strong/weak verb patterns, separable prefixes, or participle forms alongside the primary conjugation tables.

The exact organization should reflect the grammatical structure of the language rather than forcing all languages into a single universal schema.

---

### Positive and Negative Forms

Languages that distinguish affirmative and negative verb forms should include both whenever practical.

Example:

```yaml
minä:
  positive:
    - syön
  negative:
    - en syö
```

Languages without dedicated negative verb forms should instead represent the grammatical distinctions that are natural to that language.

---



## Conjugation Pack Generation

Before generating a conjugation pack, authors SHALL identify the canonical verb lemmas referenced by the companion vocabulary pack.

Conjugation packs are derived from the vocabulary pack—not directly from the translation text.

---

### Creating a Conjugation Pack without Translation Using an LLM

There may be times when you want to create your own conjugation list without first creating Translation and Vocabulary packs. This can be done manually or with help from an LLM.

When using an LLM, provide the `05_Linguatrain_LLM_Authoring_Specification.md` file along with your verb text list. Use a single verb per line in the text file.

---

#### Copy-Ready Conjugation Prompt

Copy the following prompt into the LLM after attaching the listed files. Edit the metadata values before sending it.

```Text

Attached:
1. 05_Linguatrain_LLM_Authoring_Specification.md — the authoring spec
2. [canonical_example_conjugation].yaml — a canonical Conjugation pack, for style/structure reference
3. [raw_verb_list].txt — the raw verb list to generate from

Task: Using §2.2 and the applicable parts of §5.0 of the attached
specification (conjugation-only mode — no Translation pack and no
Vocabulary pack exist or are wanted here), generate a new canonical
Conjugation pack YAML file from the attached raw verb list. Use the
attached canonical example only as a structural/style reference — do not
copy or reuse any of its lexical content or paradigm values.

Lesson metadata for this pack:
- id: [e.g. 'suomen_mestari_1_kappale_5_conjugation']
- title: [e.g. Kappale 5 — Conjugation]
- source_list: [raw_verb_list filename]
- version: 1
- schema_version: 1

Before producing the YAML, run the applicable §5.0 preprocessing steps
explicitly (case normalization, dedup, exclusion of non-lexical tokens,
same-lemma collapsing, near-form disambiguation, metalinguistic-term
flagging) and report anything you flagged as ambiguous lemmas or
metalinguistic terms — as a short list before the YAML, so I can confirm
those calls.

Also report, as part of that same list:
- Any token that was not already a citation/infinitive form and had to be
  reduced to its dictionary lemma (§5.4).
- Any raw-list line that already grouped multiple words, the §5.5
  compositionality-test call you made on it, and whether it was kept as
  one entry (§6.7) or split.
- Any verb excluded as defective or impersonal (§6.3).

State which grammatical categories (polarity, tense, mood, person, etc.)
you intend to cover for this pack before generating entries, since §6.5
requires that whatever categories are included for one verb must be
included for every verb — flag this choice explicitly so I can confirm it
before you generate the full paradigm set.

Then run the §9 conformance checklist (including the conjugation-only-mode
subsection) and confirm it passes before presenting the final YAML in a
single code block.
```

---

## Guiding Principle

The companion conjugation pack teaches **how verbs change**, not what they mean.

Vocabulary teaches meaning.

Translation teaches usage.

Conjugation teaches patterns.

The goal is not to document every possible verb form, but to help learners recognize and produce the forms they will encounter while reading and speaking.

---

## Educational Priority

Conjugation packs should reinforce the verbs introduced by the lesson while preparing the learner to recognize those same verbs in new grammatical contexts.

The learner already knows what the verb means.

The conjugation pack teaches how the language transforms that verb across persons, numbers, tenses, moods, or other language-specific categories.

---

## Candidate Selection

Conjugation entries **must** be generated only from verbs referenced by the companion vocabulary pack.

Every verb should appear only once within a conjugation pack.

Do **not** generate conjugation entries for:

- nouns
- adjectives
- adverbs
- pronouns
- particles
- conjunctions
- fixed expressions
- symbolic tokens

Only lexical verbs generate conjugation entries.

---

## Canonical Lemma Only

Every conjugation entry SHALL be anchored to the dictionary form (lemma).

The encountered surface form is never used as the identity of the conjugation entry.

### Example (Finnish)

Translation:

```text
Herään aikaisin.
```

Vocabulary:

```yaml
id: 'herätä'
prompt: Herään
```

Conjugation:

```yaml
id: 'herätä'
lemma: herätä
```

### Example (Spanish)

Translation:

```text
Hablo español.
```

Vocabulary:

```yaml
id: 'hablar'
prompt: hablo
```

Conjugation:

```yaml
id: 'hablar'
lemma: hablar
```

The translation teaches **hablo**.

The vocabulary preserves the relationship.

The conjugation pack teaches the entire verb **hablar**.

---

## One Verb, One Identity

A verb may appear many times throughout a lesson in different forms.

Only one conjugation entry should exist.

Example:

```text
menen
menimme
menisit
meni
```

all reference:

```yaml
id: 'mennä'
lemma: mennä
```

The lesson may encounter many forms.

The conjugation pack teaches one canonical verb.

---

## Complete Paradigms

Unlike the vocabulary pack, the conjugation pack should provide complete paradigms appropriate for the language.

For example, a Finnish verb might include:

- infinitive
- present
- past
- conditional
- imperative
- perfect
- negative forms

A Spanish verb might include:

- infinitive
- present indicative
- preterite
- imperfect
- future
- conditional
- subjunctive
- imperative

The exact paradigm depends on the language and the Linguatrain conjugation schema.

The objective is consistency within a language—not identical structures across languages.

---

## Language-Specific Structure

Conjugation packs should model the grammar of the language being studied.

Do not force one language into another language's grammatical framework.

For example:

- Finnish includes negative verb constructions.
- German distinguishes strong and weak verb patterns.
- Spanish contains multiple past tenses and moods.
- French includes numerous irregular stem changes.

Each conjugation pack should faithfully represent the language rather than attempting to normalize grammatical differences.

---

## Deriving a Conjugation Pack

Translation packs naturally identify the verbs that should become
conjugation exercises.

Every verb encountered during translation is a candidate for inclusion in a
conjugation pack.

For example, a translation pack might contain the following verb lemmas:

```text
olla      (Finnish)   - to be
herätä    (Finnish)   - to wake up
manger    (French)    - to eat
gehen     (German)    - to go
hablar    (Spanish)   - to speak
```

The exact verbs will depend on the source material and the target language.

### Always Use Dictionary Forms

Conjugation exercises should always begin with the verb's dictionary form
(lemma), never the inflected form that happened to appear in the lesson.

For example:

| Language | Form in Translation | Conjugation Entry |
|----------|---------------------|-------------------|
| Finnish | herään | herätä |
| French | mange | manger |
| German | geht | gehen |
| Spanish | hablo | hablar |

Using the lemma allows learners to practice the complete verb rather than
memorizing only the specific form encountered in the lesson.

### Include Positive and Negative Forms

When the target language distinguishes between affirmative and negative verb
forms, include both forms in the conjugation pack whenever practical.

For example:

```yaml
lemma: syödä

forms:
  minä:
    positive:
      - syön
    negative:
      - en syö
```

Practicing both forms helps learners develop fluency by reinforcing multiple
common patterns for the same verb.

Some languages do not have separate negative verb forms. In those languages,
authors should instead include the forms that best represent the language's
core conjugation patterns.

---

## Multi-word Expressions

Many languages contain expressions that are most naturally learned as a single
unit rather than as individual words.

Examples include:

| Language | Expression | Meaning |
|----------|------------|---------|
| Finnish | *käydä suihkussa* | to take a shower |
| English | take a shower | to shower |
| French | *avoir besoin de* | to need |
| German | *spazieren gehen* | to go for a walk |
| Spanish | *tener ganas de* | to feel like |

Whenever possible, preserve these expressions as complete units rather than
splitting them into separate vocabulary items or conjugation exercises.

Doing so helps learners acquire the language as it is naturally used rather
than as isolated grammatical pieces.

---

## Conjugation Pack Shape

The conjugation pack defines how Linguatrain represents verb paradigms for a particular language.

Each entry should use the canonical lemma as its identity and provide a complete, language-appropriate set of conjugated forms following the established conjugation schema.

The exact structure of the conjugation data will vary by language, but every conjugation pack should:

- use dictionary-form verbs as the canonical identity,
- provide consistent paradigms across all entries,
- faithfully model the target language,
- avoid mixing grammatical systems from different languages,
- and remain synchronized with the companion Vocabulary and Translation packs.

The conjugation schema defines **how verbs inflect**. It does not redefine meaning, introduce new vocabulary, or duplicate information that belongs in the Translation or Vocabulary packs.

---

# Word Explorer

Word Explorer is not a grammar reference. It is a guide for understanding how individual words are formed and used in context.

Where Vocabulary teaches what a word means, and Conjugation teaches how a verb inflects across its whole paradigm, Word Explorer answers a narrower, more specific question:

> *Why does this word look like this — right here, in this sentence?*

Each entry begins with a single word the learner actually encountered in the source text. From that one word, Word Explorer helps the learner discover its base word, how it was formed, why that particular form was chosen for this sentence, and a small set of related forms worth comparing it to.

This is the module behind Linguatrain's **Apply mode**, where a learner sees a sentence with a blank and must choose the correct form of a word from several real, plausible alternatives:

```text
Sentence:
Onko täällä _____ kurssi?

Meaning:
Is the Finnish course here?

Choose the correct form of suomi:

- suomea
- suomi
- suomen
- suomessa
```

Choosing wrong doesn't just mark the answer incorrect — it explains *why* the chosen form doesn't fit here. Choosing right explains why it does. That explanation, in both directions, is the heart of Word Explorer.

---

## Word Explorer Packs

Word Explorer packs are derived from the sentences and chunks already present in the companion Translation pack.

Word Explorer entries should:

- begin with a word the learner actually encountered in a specific sentence,
- trace back to that sentence and chunk, word for word,
- connect the encountered form to its base word (dictionary form),
- explain how the form was built and why it was used,
- and, where useful, generate a small set of related forms for comparison.

Unlike Vocabulary and Conjugation, Word Explorer has **no standalone raw-list mode**. An entry is only meaningful in the context of a real sentence, so it always requires a companion Translation pack to derive from. If no Translation pack exists yet, one must be authored first.

Word Explorer packs may also reference the companion Vocabulary pack (`vocabulary_ref`), but they don't require it. A Translation pack alone is enough to begin.

---

## Word Explorer Entry Schema

Every Word Explorer entry represents one encountered word, examined once, in its actual sentence.

```yaml
metadata:
  id: ''                 # always single quote IDs
  title: ''
  type: word_explorer
  format: canonical
  version: 1
  schema_version: 1
  category: ''            # optional
  chapter: ''             # optional
  source_pack: ''         # the Translation pack this pack derives from

grammar:
  - key: ''
    name: ''
    plain_english: ''
    description: ''

entries:
  - id: ''                # always single quote IDs

    source:
      entry_id: ''
      chunk_id: ''
      text: ''
      literal: ''
      target: ''

    word: ''
    base_word: ''
    type: ''

    target: ''

    morphology: {}

    hint: ''
    formation: ''
    explanation: ''
    role: ''

    explorations: []
    applications: []

    vocabulary_ref: ''
    grammar_refs: []
```

### Required Metadata

- `id`
- `title`
- `type`
- `format`
- `version`
- `schema_version`
- `source_pack`

### Required Entry Fields

- `id`
- `source`
- `word`
- `base_word`
- `target`
- `morphology`

### Optional Entry Fields

- `type`
- `hint`
- `formation`
- `explanation`
- `role`
- `explorations`
- `applications`
- `vocabulary_ref`
- `grammar_refs`

> **A note on schema history:** an earlier draft of this schema explored a top-level `dimensions.features` block. That idea didn't survive contact with a real pack — it added a layer of indirection without giving an author or a learner anything they actually needed. The `grammar` catalog above, along with `explorations` and `applications`, replaced it once the schema was actually built and tested end to end. If you find an older document describing `dimensions`, treat this one as current.

---

## Field Definitions

### `source`

The sentence context this word was encountered in.

`entry_id` and `chunk_id` point back to the exact Translation pack entry and chunk the word came from. `text`, `literal`, and `target` are copied — not re-derived or reworded — from that Translation entry, so the learner sees the same sentence they'd see in the Translation exercise.

---

### `word`

The exact surface form encountered in the source sentence.

---

### `base_word`

The dictionary form of `word` — the form a learner would look up. This is normally the same value used as the companion Vocabulary entry's `id`, when one exists.

---

### `type`

An optional part-of-speech classification, using the same values as the companion Vocabulary pack (noun, verb, adjective, and so on).

---

### `target`

The contextual meaning of `word` in this specific sentence. This can be more specific than a Vocabulary entry's general-purpose meaning, the same way a Translation chunk's meaning can narrow to fit its sentence.

---

### `morphology`

The language-specific analysis of how `word` was formed from `base_word`.

Every `morphology` block has a `kind`, describing what *sort* of formation this is:

| `kind` | Used for |
|---|---|
| `case` | A case-marked form of a noun, pronoun, or adjective |
| `compound` | Two or more whole words fused into one |
| `derivation` | A suffix builds a new word or meaning from a base word |
| `verb_form` | A conjugated or non-finite verb form outside a plain personal paradigm — passive, participle, infinitive, and so on |
| `base_word` | The unmarked citation form itself — used only inside `explorations`, to represent the starting point of a word family |

The remaining fields inside `morphology` (`case`, `ending`, `stem`, `parts`, `suffix`, and so on) depend on the `kind` and the language. Populate only the ones that genuinely apply — an empty field is worse than an absent one.

---

### `hint`

Optional learning support shown before the answer is revealed.

A good hint points at the grammatical relationship without giving away the answer. "This is a form of the word for 'I'" is a hint. "This means 'on me'" is the answer.

---

### `formation`

A short, learner-facing line showing how `word` was built from `base_word`:

```text
base_word (+ stem/ending/suffix) → word
```

For example: `suomi → suome- + -n → suomen`.

---

### `explanation`

States what the form means *and* why that specific form is used here. Both halves matter — this is the field that turns a bare grammatical label into something the learner can actually reason with.

---

### `role`

An optional short label for the word's semantic or grammatical role in the sentence — `possessor`, `destination`, `compound_noun`, and so on. Free text, but it should stay consistent for the same relationship across a pack.

---

### `explorations`

A small word family built outward from `base_word`, for recognition and comparison.

Explorations are not a complete paradigm. They're a handful of forms — typically three to five — chosen because they're close to the encountered word and worth comparing to it. One exploration (`word` itself) is marked `origin: source`, meaning it's literally the form the learner encountered. The rest are `origin: generated`: genuinely correct forms constructed to round out the comparison, the same way a Conjugation pack builds a full paradigm outward from one encountered verb form.

```yaml
explorations:
  - word: 'minä'
    target: 'I'
    origin: generated
    status: valid

  - word: 'minulla'
    target: 'on me / I have'
    origin: source
    status: valid
```

A generated form that isn't a great fit for this particular sentence can still be worth including — that's often exactly the point, since it becomes a distractor in `applications` — but it needs a `status` other than `valid` and a `usage_note` explaining why it doesn't fit.

---

### `applications`

One or more contextual-choice exercises: the mechanism behind Apply mode.

Each application presents the learner with a sentence, a blank, and several choices. One choice is correct; the rest are real, plausible, wrong-for-this-context forms, each with its own explanation of why it doesn't fit.

```yaml
applications:
  - id: ''
    prompt:
      text: 'Minulla on vaimo ja kaksi _____.'
      meaning: 'I have a wife and two children.'
    answer:
      word: 'lasta'
    choices: ['lapsi', 'lasta', 'lapset', 'lapsia']
    explanation:
      why_it_fits: '...'
    distractors:
      - word: 'lapsi'
        meaning: 'child'
        why_not: '...'
```

The quality of an application lives almost entirely in its `why_not` explanations. A distractor that's just marked wrong teaches nothing. A distractor whose `why_not` explains what it actually means, and why that meaning doesn't belong in this sentence, teaches the learner something they'll remember the next time they see it.

---

### `vocabulary_ref` and `grammar_refs`

Cross-references into the companion Vocabulary pack and this pack's own `grammar` catalog, respectively.

`vocabulary_ref` should resolve to a real Vocabulary entry when one exists, and should simply be omitted when it doesn't — never a forward reference to a pack that hasn't been written yet.

`grammar_refs` points at keys defined in this pack's own top-level `grammar` list, not at a Translation pack's grammar catalog. The two are related in spirit but scoped independently — a Word Explorer pack's `grammar` list only needs to cover the concepts this pack's entries actually use.

---

## Word Explorer Pack Generation

Before generating a Word Explorer pack, authors SHALL identify the Translation pack it will derive from.

Word Explorer packs are derived from the sentences and chunks in the Translation pack — not from a raw word list, and not from the Vocabulary pack directly, though they may reference it.

---

### Creating a Word Explorer Pack (and Guide) with an LLM

Word Explorer is a two-part deliverable: the YAML pack itself, and the human-readable **Word Explorer Guide** — a Markdown document generated *from* that YAML, never authored independently (see [The Word Explorer Guide](#the-word-explorer-guide-word-explorermd) below). A single LLM request can reasonably produce both.

Word Explorer packs can be drafted from an existing Translation pack, or directly from new source material: a plain text file, or an image of a text block — a textbook page, a sign, a worksheet. If you're starting from an image, the LLM needs to transcribe it accurately before anything else can be built on top of it. The prompt below asks for that explicitly, because a single misread diacritic (an *a* for an *ä*, or a dropped double letter) will quietly propagate through every downstream pack.

---

#### Copy-Ready Word Explorer Prompt

Copy the following prompt into the LLM after attaching the listed files. Edit the metadata values before sending it.

```Text
Attached:
1. 05_Linguatrain_LLM_Authoring_Specification.md — the authoring spec
2. [canonical_example]_word_explorer.yaml — a canonical Word Explorer pack, for style/structure reference
3. [canonical_example]_word_explorer.md — a canonical Word Explorer Guide, for style/structure reference
4. Either:
   a. [translation_pack].yaml (and [vocabulary_pack].yaml, if it exists) — the
      pack(s) to derive the Word Explorer pack from, OR
   b. [source_material].txt, or an image of the source text block — if no
      Translation pack exists yet

Task: Using §7 of the attached specification, generate a canonical Word
Explorer pack YAML file and its companion Word Explorer Guide (Markdown)
for the attached material. Use the attached canonical examples only as a
structural/style reference — do not copy or reuse any of their lexical
content.

If I attached an image instead of a Translation pack, first transcribe the
text exactly as it appears — preserve original spelling, diacritics, and
line breaks. Flag any character you're not fully confident about (easily
confused diacritics, unclear scans, ambiguous punctuation) as a short list
before doing anything else, so I can confirm or correct the transcription.
Do not proceed past this step on a guessed transcription.

If no Translation pack exists yet, produce one first, following the
Translation pack conventions already established in this handbook and the
attached spec, and present it for review before continuing to Word
Explorer.

Lesson metadata for this pack:
- id: '[e.g. suomen_mestari_1_kappale_5_word_explorer]'
- title: '[e.g. Kappale 5 — Word Explorer]'
- source_pack: '[the Translation pack id this derives from]'
- version: 1
- schema_version: 1

Do not invent a `chapter` or `category` value unless the source material
itself states one as fact (§7.2). Omit rather than infer.

Select entries the way §7's Guiding Principle and Candidate Selection
sections describe: not every word in the source text needs an entry.
Choose the words that best illustrate cases, compounds, derivations,
passive forms, and irregular stems — the same five categories the Guide is
organized around — and are worth a learner's attention. Report the list of
words you selected, and briefly why, before generating full entries, so I
can confirm the selection.

For each entry, generate `explorations` (§7.6) and at least one
`applications` contextual-choice exercise with a minimum of four choices
where plausible distractors exist (§7.7). Every distractor needs a
`why_not` that explains what it actually means, not just that it's wrong.

Then generate the Word Explorer Guide (§7.11) from that YAML, grouped by
category, with entries sharing a case/suffix/voice stacked under one
subheading. Remember the Guide is scoped to this one pack only: no chapter
or lesson numbering, and no reference to any other pack's content
(§7.11.1, §7.11.4).

Finally, run the §9 conformance checklist (the Word Explorer pack quality
and Word Explorer Guide quality subsections) and confirm it passes before
presenting the final YAML and Markdown, each in its own code block.
```

---

## Guiding Principle

The companion Word Explorer pack teaches **why a word takes the form it does** — not what the word means, and not its full paradigm.

Vocabulary teaches meaning.

Translation teaches usage.

Conjugation teaches complete verb paradigms.

Word Explorer teaches the *reasoning*: the connection between a base word and the specific form a sentence required.

The goal is not to analyze every word in the source text. The goal is to pick the words whose formation genuinely teaches something, and explain that formation clearly enough that the learner starts recognizing the same pattern elsewhere.

---

## Educational Priority

Word Explorer packs should reinforce the words the lesson already introduced, while teaching the learner to reason about form rather than simply recognize it.

The learner already knows, or is learning, what the word means — from Vocabulary.

The learner already knows how it's used in a sentence — from Translation.

Word Explorer teaches the *why*: why this ending, why this compound, why this stem changed shape.

---

## Candidate Selection

Word Explorer entries should be generated only from words that illustrate one of the five categories used throughout this handbook and the companion Guide:

- **Cases** — a case-marked noun, pronoun, or adjective worth understanding
- **Compounds** — two or more words fused into one
- **Derivations** — a suffix that builds a new word or meaning from a base word
- **Passive forms** — the impersonal "is done" construction, where the language has one
- **Irregular stems** — a base word whose case stem can't be derived by a general rule

Not every word needs an entry, and not every sentence needs to be mined for morphology. A Word Explorer pack that tries to analyze every word in a text stops being a guide and becomes an exhaustive grammar reference — precisely what this module is not (see [Creating Exhaustive Morphology](#creating-exhaustive-morphology)).

Choose the words that teach something a learner will actually use again.

---

## Explorations Are Not Complete Paradigms

Unlike the Conjugation pack, Word Explorer's `explorations` are intentionally incomplete.

A Conjugation entry for *olla* teaches all six persons, positive and negative. A Word Explorer entry for *minulla* teaches three or four nearby forms of *minä* — enough to show the pattern, not enough to replace the Conjugation or Vocabulary pack's job.

If you find yourself listing every case a noun can take, or every person a verb can be conjugated in, inside an `explorations` block, that content belongs in the Conjugation pack instead.

---

## Irregular Stems

Some base words don't just add an ending to their dictionary form — they shift shape first. Finnish pronouns are a familiar example: *minä* becomes *minu-* before any case ending; *tämä* becomes *tä-*.

Word Explorer, and its companion Guide, flag these separately, because they're the forms a learner has to memorize directly rather than derive from a rule they already know.

The test is strict, and worth stating plainly: a stem is irregular only when it **cannot be derived by a general rule** from the citation form. Ordinary consonant gradation (*ruoka → ruoan*) is not irregular — it's a well-documented, productive pattern that applies across many words, even though it can look dramatic to a beginner. A pronoun stem that simply doesn't match its nominative, or a handful of small numbers whose case stems each have to be learned individually, are the real irregular cases.

Don't flag a word as irregular just because a learner might find it hard. Flag it because the rule genuinely doesn't exist.

---

## Deriving a Word Explorer Pack

Translation packs naturally identify candidate words for Word Explorer, the same way they identify candidate verbs for Conjugation.

For example, a Translation pack might contain the following candidates:

```text
suomalainen   (suomi + -lainen)      — a derivation worth explaining
herätyskello  (herätys + kello)      — a compound worth explaining
minulla       (minä → minu- + -lla)  — a case form built on an irregular stem
kahdelta      (kaksi → kahde- + -lta) — a clock-time ablative
```

Each of these earns a Word Explorer entry because it teaches something a learner will see again — a productive suffix, a compound pattern, an irregular pronoun stem, a fixed clock-time construction — not simply because the word appears in the text.

### Every Entry Traces to a Real Sentence

A Word Explorer entry's `source` must point to an entry and chunk that genuinely exist in the Translation pack, with `text`, `literal`, and `target` copied exactly — never invented sentence context to satisfy the schema.

If a word you want to explore doesn't actually appear in the Translation pack's source text, it doesn't belong in this pack. Word Explorer has no standalone mode for a reason: every entry's authority comes from the sentence it was found in.

---

## The Word Explorer Guide (`word-explorer.md`)

The Word Explorer pack is built for the application: entries, explorations, applications, and cross-references, all structured for a study session inside Linguatrain.

The **Guide** is built for the human: a plain Markdown document, organized by grammatical category instead of source order, so every genitive, every compound, every irregular stem in the lesson stacks up together for comparison — closer to a set of study notes than an interactive exercise.

The Guide is always **generated from the completed Word Explorer pack**, never authored by hand and never drawn directly from the source text. If the YAML changes, regenerate the Guide from it rather than patching the Markdown independently — the two should never be allowed to drift apart.

### Category Tables

The Guide organizes entries into the same five categories used for candidate selection:

```markdown
### Cases

**Partitive (-a/-ä)**
| Finnish form | Base word | Formation | Meaning | Where it appears |
|---|---|---|---|---|
| **lasta** | lapsi | lapsi → **las-** + **-a** | child (some, after a number) | *kaksi lasta.* |

### Compounds
| Compound | Parts | Literal sense | Where it appears |
|---|---|---|---|
| **herätyskello** | herätys + kello | alarm clock | *herätyskello soi.* |
```

A category with no entries in a given pack is simply omitted — an empty table teaches nothing.

One category is a cross-cutting exception: **Irregular stems**. A word can appear once in its normal category table (Cases, most often) *and* once in the Irregular stems table — never duplicated within a single table, but legitimately present in both.

### Scope: One Pack, One Guide

A Translation pack, and therefore its Word Explorer pack and Guide, carries no guaranteed information about a course sequence, a chapter number, or its relationship to any other lesson. Treat every pack as standalone.

Concretely, this means the Guide:

- is never numbered by chapter or lesson unless the Translation pack's own metadata states that number as fact, not an inference,
- never references another pack's content ("the same pattern as the previous lesson"),
- and is never framed as one entry in an ongoing, cumulative document the LLM assembles automatically.

If you later want to combine several standalone Guides into one reference document, that's a deliberate editorial decision made by hand, not something this pipeline should presuppose.

### Notes

Each Guide ends with a short **Notes** section: freeform observations that don't fit neatly into a table row. These should trace directly back to a `hint` or `explanation` already present in the YAML. The Guide reformats the pack's own content; it doesn't add new grammatical claims of its own.

---

## Word Explorer Pack Shape

The Word Explorer pack defines how Linguatrain represents individual word formations for a particular lesson.

Every Word Explorer pack should:

- derive its entries from real sentences in a companion Translation pack,
- connect each encountered word to its base word and explain how one became the other,
- select entries for what they teach, not for exhaustive coverage,
- generate a small set of comparison forms rather than a complete paradigm,
- provide contextual-choice exercises whose wrong answers teach as much as the right one,
- and produce a companion Guide that reformats — never re-authors — the same content for human review.

The Word Explorer schema defines **why a word looks the way it does**. It does not redefine meaning, introduce new vocabulary, or duplicate the complete paradigms that belong in the Conjugation pack.

---

# Common Authoring Mistakes

Even experienced authors occasionally make mistakes that produce technically valid YAML while reducing educational quality, consistency, or long-term maintainability.

Most of these mistakes are subtle. They rarely cause the translation pack to fail validation, but they can make lessons more difficult to study, harder to maintain, or inconsistent with the educational philosophy described in this handbook.

The following sections highlight the most common authoring mistakes encountered while developing Linguatrain. Review them before considering any Translation, Vocabulary, or Conjugation pack complete.

---

## Overusing Accepted Answers

The `accepted` field exists to recognize equally correct responses.

It is not a substitute for improving the preferred translation.

If many accepted answers are required, reconsider whether the `target` translation is truly the best canonical translation.

---

## Breaking the Lemma Invariant

❌ Incorrect

```yaml
vocabulary_refs:
  - lasta
```

✅ Correct

```yaml
vocabulary_refs:
  - lapsi
```

Vocabulary references always point to dictionary lemmas.

---

## Using Vocabulary Instead of Hints

❌ Incorrect

```yaml
hint: 'herätä = to wake up'
```

✅ Better

```yaml
hint: Herää is the present-tense form of the Finnish Type 4 verb herätä.
```

### Hints Should Explain the Form Being Studied

Hints should normally describe the grammatical form that appears in the source text rather than simply restating the dictionary form.

Examples:

**Finnish**

```yaml
❌ hint: 'Herää = wakes up'

✅ hint: Herää is the present-tense form of the Finnish Type 4 verb herätä.
```

**German**

```
❌ hint: 'Kindern = children'

✅ hint: Kindern is the dative plural form of the noun Kind.
```

**Spanish**

```
❌ hint: 'Habla = speaks'

✅ hint: Habla is the third-person singular present form of the verb hablar.
```

**French**

```
❌ hint: 'Vais = go'

✅ hint: Vais is the first-person singular present form of the verb aller.
```

**Important** : Prefer recognizable language patterns over linguistic terminology unless the terminology itself is the learning objective.

```
❌ hint: Finnish expresses possession with an adessive possessor plus on.

✅ hint: 'Finnish expresses possession as <person> + on (using the adessive case).'
```

---

## Making Literal Translations Too Natural

❌ Incorrect

```text
After the meal
```

✅ Better

```text
Food's after
```

Literal translations should reveal how the source language expresses meaning, even when the English sounds unnatural.

### Literal translations should

- preserve the original word order whenever practical.
- preserve grammatical relationships.
- expose unusual constructions.
- remain faithful to the structure of the source language.

### Literal translations should not

- be rewritten into natural English.
- hide grammatical differences between the source language and English.
- prioritize readability over educational value.

Remember that the `target` field already provides the natural translation.

The `literal` field exists to answer a different question:

> **"How is this idea expressed in the source language?"**

---

### Example

**Finnish**

Source:

```text
Ruoan jälkeen
```

Literal:

```text
Food's after
```

Natural:

```text
After the meal
```

Although *After the meal* is better English, it hides the fact that Finnish expresses the phrase using a postposition.

The literal translation intentionally preserves that structure so the learner can recognize it in future sentences.

---

**German**

Source:

```text
Ich habe Hunger.
```

Literal:

```text
I have hunger.
```

Natural:

```text
I am hungry.
```

The literal translation reveals that German expresses this idea using *have*, while the natural translation demonstrates how English normally says it.

---

**Spanish**

Source:

```text
Tengo frío.
```

Literal:

```text
I have cold.
```

Natural:

```text
I am cold.
```

Again, the literal translation exposes the underlying structure, while the natural translation demonstrates fluent English.

---

## Splitting Semantic Units

❌ Incorrect

```text
teen

keittiössä

aamupalaa
```

✅ Better

```text
teen aamupalaa

keittiössä
```

or

```text
teen keittiössä aamupalaa
```

Chunk boundaries should follow meaning rather than individual words or grammatical categories.

---

## Reordering the Source

Chunks should always preserve the original source order.

Do not rearrange words simply because the English translation reads more naturally.

---

## Duplicating Information

Avoid repeating the same educational information in multiple places.

For example:

- vocabulary explains words,
- hints explain grammar,
- literal translations explain structure,
- natural translations demonstrate fluent language.

Each field has a single educational purpose.

---

## Creating Exhaustive Morphology

The Vocabulary pack's `forms` field, and the Word Explorer pack's `explorations` field, are both intended to capture useful forms—not complete paradigms.

Store only forms that:

- appear in the lesson,
- reinforce important grammar,
- or provide clear educational value.

Complete paradigms belong in the companion Conjugation pack.

---

## Distractors Without Reasons

An `applications` distractor that is only marked as wrong teaches nothing.

A `why_not` field should explain what the distractor form actually means and why that meaning doesn't fit this particular sentence—not simply assert that the answer is incorrect.

The wrong answer is often as educational as the right one, but only if the explanation does the work.

---

## Inventing Chapter Continuity

A Translation pack carries no guaranteed information about a course sequence, a chapter number, or its relationship to any other pack.

Do not infer a `chapter` or `category` value that the source material doesn't state as fact, and do not let a Word Explorer Guide reference another lesson's content ("the same pattern as the previous lesson"). Treat every pack as standalone unless told otherwise.

---

## Authoring the Word Explorer Guide by Hand

The Word Explorer Guide is generated from the completed Word Explorer pack—never authored independently, and never drawn directly from the source text.

If the YAML changes, regenerate the Guide from it. A hand-edited Guide that has drifted from its YAML is worse than no Guide at all, because it looks authoritative while being wrong.

---

## Inconsistent Phonetics

If phonetic guidance is provided, use the same pronunciation convention throughout the entire pack.

Do not invent new pronunciation styles for individual entries.

---

## Weak Vocabulary References

Only reference vocabulary that is introduced, reinforced, or pedagogically important.

Avoid creating unnecessary references simply because a word appears in the sentence.

---

## Vocabulary Notation Entries

Vocabulary entries should teach lexical items, not notation, abbreviations, or decoding conventions. Abbreviations may be explained in hints or notes, but should not become vocabulary prompts unless the abbreviation itself is the study target.


## Forgetting the Educational Goal

Linguatrain is designed to teach language—not merely translate text.

Whenever two equally valid approaches exist, choose the one that provides the better learning experience.

## YAML Serialization Rules

All YAML produced under this specification **must** be valid YAML 1.1 and parse successfully without modification.

These rules exist to ensure portability, readability, and consistent behavior across parsers, editors, and automated tooling.

---

### String Quoting

The following values **must** always be enclosed in single quotes (`'...'`):

- `id`
- `prompt`
- strings that may be interpreted as YAML keywords or other scalar types
- strings containing colons (`:`), embedded quotation marks, or other YAML-significant characters

For example:

Incorrect:

```yaml
id: no
```

Correct:

```yaml
id: 'no'
```

Quoting removes ambiguity and prevents accidental interpretation as non-string scalar values.

---

### Quoting Text Values

Free-form text should be enclosed in single quotes whenever it contains YAML-significant characters.

Examples include:

- colons (`:`)
- embedded quotation marks
- leading or trailing whitespace
- other characters that could alter YAML parsing

Example:

```yaml
notes:
  - 'The suffix "-ssa" indicates location inside something.'
```

---

### Indentation

Indentation must be consistent throughout the document.

Sequence items (`-`) **must** be indented exactly two spaces beneath their parent key.

Correct:

```yaml
notes:
  - 'Common beginner mistake.'
  - 'Often confused with...'
```

Incorrect:

```yaml
notes:
- 'Common beginner mistake.'
```

Consistent indentation improves readability and prevents parser errors.

---

### Stable Serialization

Equivalent content should be serialized consistently.

Avoid unnecessary variation in:

- quoting style
- indentation
- whitespace
- field ordering
- list ordering

Consistent serialization simplifies review, reduces version-control noise, and makes documents easier to compare.

---

### Canonical Field Ordering

Within each object, fields should appear in the canonical order illustrated throughout this handbook.

Do not reorder fields unless the schema explicitly requires it.

A consistent field order improves readability and produces documents with a predictable structure.

---

# Author Quality Checklist

Before publishing or using a Linguatrain learning pack, perform one final review.

The objective is not merely to produce valid YAML, but to produce educational content that is structurally consistent, linguistically accurate, and genuinely helpful to the learner.

This checklist summarizes the principles presented throughout this handbook and serves as a final validation before a Translation, Vocabulary, or Conjugation pack is considered complete.

---

## Educational Quality

The pack should teach the language, not merely translate it.

- ☐ Chunks represent meaningful semantic units.
- ☐ Chunk order matches the original source text.
- ☐ Every chunk has a phonetic when the parent has a phonetic.
- ☐ Literal translations reveal the structure of the source language.
- ☐ Natural translations read as fluent English.
- ☐ Literal and natural translations are clearly distinct.
- ☐ Hints teach grammar, usage, or learning strategies rather than repeating vocabulary.
- ☐ Vocabulary references reinforce important words without becoming exhaustive.

---

## Structural Quality

The pack should conform to the canonical Linguatrain schema.

- ☐ Required metadata is complete.
- ☐ Entry identifiers are unique.
- ☐ Every translation entry contains semantic chunks.
- ☐ Every `vocabulary_ref` resolves to a valid vocabulary entry.
- ☐ Every grammar reference resolves to a valid grammar topic.
- ☐ The Lemma Invariant is maintained throughout the pack.
- ☐ The YAML follows the canonical schema described in this handbook.

---

## Linguistic Quality

The language content should be internally consistent and pedagogically useful.

- ☐ Vocabulary entries use dictionary lemmas.
- ☐ Morphological forms are accurate.
- ☐ Compound words include helpful literal breakdowns where appropriate.
- ☐ Phonetic guidance is consistent throughout the pack.
- ☐ Literal translations preserve grammatical structure.
- ☐ Natural translations preserve meaning without becoming overly literal.

---

## Companion Pack Quality

Translation, vocabulary, conjugation, and Word Explorer packs should function as a coherent learning system.

- ☐ Vocabulary entries support the translation pack.
- ☐ Conjugation entries correspond to vocabulary lemmas.
- ☐ Morphological forms complement—not replace—the Conjugation pack.
- ☐ Word Explorer entries trace to a real Translation entry and chunk.
- ☐ Word Explorer `explorations` stay a small comparison set, not a full paradigm.
- ☐ Cross-references are complete and consistent.

---

## Word Explorer Quality

- ☐ Every entry was chosen because it teaches something—a case, a compound, a derivation, a passive form, or a genuine irregular stem—not because the word simply appeared in the text.
- ☐ Every `applications` distractor has a `why_not` that explains its actual meaning, not just that it's wrong.
- ☐ No `chapter` or `category` value was invented; either the source material states it as fact, or it's omitted.
- ☐ The Word Explorer Guide was generated from the finished YAML, grouped by category, and scoped to this one pack—no invented chapter numbering, no reference to another pack's content.

---

## Final Question

Before publishing, ask one final question:

> **Will this pack help the learner understand how the language works—not just what the sentence means?**


If the answer is **yes**, the pack is ready for publication.

---

# Final Thoughts

This document and workflow were not designed to teach an LLM how to write YAML.

It was designed to teach human authors how to think like Linguatrain content authors, whether they write packs by hand or use an LLM to draft them.

I have spent the better part of four decades working with technical
content. Linguatrain exists because I couldn't find a language-learning
program that treated content the way I believed it should be treated.
Most applications focus on vocabulary, pronunciation, or conversation.
Those are all important, but understanding a language requires more than
memorizing words; it requires learning how ideas are expressed.

The Translation module began with a very simple question:

> *How can I take the content from my language textbook and truly
> understand it by translating it?*

As I worked on the idea, it became obvious that translation involved
much more than asking an LLM to translate a sentence or comparing my own
handwritten translations against an LLM-generated answer. Both approaches
produce answers, but neither necessarily produces understanding.

A student and teacher don't work that way in a classroom.

They work through the material together.

They break difficult sentences into meaningful pieces. They discuss
vocabulary. They examine how phrases fit together before assembling the
complete translation.

That observation became the foundation of this translation schema.

As a content engineer, my instinct was to give that learning process
structure. Meaningful chunks became first-class objects. Literal
translations became an intermediate learning step rather than an
afterthought. Hints became opportunities to guide rather than simply
reveal answers. Over time, those ideas evolved into the workflow
described in this document.

The result is a framework that is designed to help people learn from
real content, not simply translate it.

The workflow is intentionally simple:

    The schema defines the structure.

    The canonical example demonstrates the style.

    The design guide explains the educational philosophy.

Together, these three artifacts provide everything needed to produce
consistent, high-quality translation documents.

Whether the first draft is written by a human, drafted with an LLM,
or refined through collaboration between the two, the objective
remains the same:

> Help the learner understand the language, one meaningful idea at a
> time.
