# Linguatrain Translation Authoring Handbook

## Purpose

This handbook explains how to design high-quality Linguatrain translation packs. It describes the educational philosophy behind the translation module and the conventions authors should follow when creating new content.

The goal is **not** to model a textbook. The goal is to model the learning process a student goes through while decoding another language.

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
  - [AI-Assisted Authoring](#ai-assisted-authoring)
  - [A Collaborative Process](#a-collaborative-process)
  - [Recommended Inputs](#recommended-inputs)
  - [Progressive Enrichment](#progressive-enrichment)
  - [Example Request](#example-request)
  - [Give the AI a Role](#give-the-ai-a-role)
  - [Review the Results](#review-the-results)
  - [AI Is an Assistant, Not an Authority](#ai-is-an-assistant-not-an-authority)

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

- [Common Authoring Mistakes](#common-authoring-mistakes)
  - [Overusing Accepted Answers](#overusing-accepted-answers)
  - [Breaking the Lemma Invariant](#breaking-the-lemma-invariant)
  - [Using Vocabulary Instead of Hints](#using-vocabulary-instead-of-hints)
  - [Making Literal Translations Too Natural](#making-literal-translations-too-natural)
  - [Splitting Semantic Units](#splitting-semantic-units)
  - [Reordering the Source](#reordering-the-source)
  - [Duplicating Information](#duplicating-information)
  - [Creating Exhaustive Morphology](#creating-exhaustive-morphology)
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
Morphology
      ↓
Conversation
```

- **Vocabulary** builds recognition of reusable words and phrases.
- **Translation** teaches how ideas are expressed in complete sentences.
- **Morphology** teaches how words are constructed to express meaning.
- **Conversation** teaches communication using the patterns learned.

**Note:** Morphology is a module currently under development.

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

## AI-Assisted Authoring

Modern AI systems have become remarkably capable language assistants.

While they should not be considered infallible, they are extremely effective at accelerating the creation of translation documents when used within a well-defined workflow.

The objective is not to replace the human author.

The objective is to allow the human author to spend their time improving educational quality instead of manually writing repetitive YAML.

```text
Source Material
        +
Canonical Example YAML
        +
Translation Design Guide
        ↓
AI Assistant
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

The AI assistant performs much of the mechanical work, including:

- generating the initial YAML structure
- suggesting chunk boundaries
- creating literal translations
- producing natural translations
- generating hints
- identifying vocabulary references
- creating a companion vocabulary pack from those references

Neither works as well in isolation.

The highest quality translation documents are produced through collaboration between a knowledgeable human author and an AI assistant.

The AI contributes speed, consistency, and scale.

The human contributes educational judgment, language expertise, and an understanding of how people learn.

---

## Recommended Inputs

The highest quality AI-generated translation documents are produced when the assistant is provided with:

1. The representative translation YAML document included with Linguatrain.
2. The representative vocabulary YAML document included with Linguatrain.
3. This Translation YAML Design Guide.
4. The new source material.

The example translation document is intentionally included with Linguatrain as a canonical reference implementation.

It demonstrates the expected structure, chunking style, literal translations, natural translations, hints, vocabulary references, and overall educational philosophy.

Rather than starting from an empty prompt, AI assistants should use this document as the baseline for all future translation documents.

The Translation YAML Design Guide explains *why* the example document was authored the way it was.

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
```

A minimal document containing only source and target text is still useful.

As time permits, additional educational content can be added incrementally without changing the overall structure of the document.

This allows translation documents to grow in educational value over time while remaining useful from the very beginning.

---

## Example Request

A request such as the following provides the AI with both the structure and the educational objective:

> I have attached five documents:
>
> 1. The canonical Translation YAML example.
> 2. The canonical Vocabulary YAML example.
> 3. The canonical Conjugation YAML example.
> 4. The Linguatrain Translation Authoring Handbook.
> 5. New source material.
>
> Using the canonical examples and the design guide as your reference, create three documents: a complete Translation YAML document, a complete Conjugation YAML document from the translation, and a companion Vocabulary YAML document for the supplied source material.
>
> Follow the schema and authoring philosophy described in the guide.
>
> Produce meaningful semantic chunks, optional `phonetic` pronunciation guidance, literal translations, natural translations, hints, vocabulary references, and grammar references where appropriate.
>
> Then collect the unique `vocabulary_refs` values and create studyable vocabulary entries using the normal vocabulary schema. Each vocabulary entry should include `prompt`, `answer`, and, where helpful, `type`, `literal`, `forms`, `phonetic`, and concise `notes`.
>
> The resulting YAML files should resemble the canonical examples in both structure and educational quality.
>
> Every note should either be quoted or emitted as a block scalar.

---

## Give the AI a Role

One technique that consistently improves results is to clearly define the role the AI should perform.

For example:

> Act as an experienced Linguatrain content author. Your objective is not simply to translate the text, but to create educational material that helps a learner understand the language. Follow the Translation YAML Design Guide and use the canonical example as the reference for style and structure.

Providing this context encourages the AI to make educational decisions rather than simply producing a direct translation.

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

The objective is not to ask the AI for perfection.

The objective is to produce a high-quality first draft that a human author can refine into an excellent learning resource.

---

## AI Is an Assistant, Not an Authority

This guide is intentionally opinionated. It reflects the workflow that proved successful while developing Linguatrain and while learning Finnish myself.

Finally, I can't stress enough that AI is a **helper**, not a magical wizard. It will make mistakes. It can present an answer with complete confidence that is simply wrong because it has missed a nuance, misunderstood the context, or chosen an incorrect interpretation. This is why collaboration and independent verification remain important.

Many years ago, when I worked for a technology company, our documentation was translated by one translation company and then independently reviewed by another. The goal wasn't to prove the first company was wrong; it was to improve quality through verification.

I recommend the same workflow here.

Let AI produce the first draft. Review it critically. If something doesn't feel right, verify it. Ask a native speaker. Consult a teacher. Compare another translation. Use language forums to verify individual sentences. Most people are happy to explain a few phrases, even if they aren't going to translate an entire book.

The purpose of AI is not to replace human expertise.

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
        ├── Morphology Pack (future)
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

## Authoring Guidance for AI Agents

When generating translation YAML, include `phonetic` when pronunciation
would help the learner. This is especially useful for beginner packs,
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

If the AI is not confident in a pronunciation guide, it should omit
`phonetic` rather than invent an unreliable one.

---

##Symbolic Values and Spoken Forms

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

When the spoken form differs from the written form because of symbolic notation, explain the explain the relationship between the written symbolic form and its natural spoken form in the translation hint.

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

### Creating a Vocabulary pack without Translation Using an LLM

There may be times when you want to create your own vocabulary list. This can be done manually or using assistance from an LLM agent.
When using an LLM agent you need to provide a proper prompt and provide the `05_Linguatrain_LLM_Authoring_Specification.md` file along with your 
vocabulary list.  

---

#### LLM prompt

When trying to get only a vocabulary pack out of an LLM you need to be very explicit with it. The following prompt has been
tested and will give you the best results. 

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

### Creating a Conjugation pack without Translation Using an LLM

There may be times when you want to create your own conjugation list. This can be done manually or using assistance from an LLM agent.
When using an LLM agent you need to provide a proper prompt and provide the `05_Linguatrain_LLM_Authoring_Specification.md` file along with your 
verb text list. Use a single verb per line in the text file. 

---

#### LLM prompt

When trying to get only a conjugation pack out of an LLM you need to be very explicit with the prompt to the LLM. The following prompt has been
tested and will give you the best results. 

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

# Morpholgy -- aka Word Explorer -- work in progress 

Word Explorer is not a grammar reference. It is a guide for understanding how individual words are formed and used in context. Each entry begins with a word encountered in authentic text and helps the learner discover its base word, meaning, formation, and purpose in the sentence.

## YAML design

v0.9 of the design

```yaml
metadata:
  id: ''
  title: ''
  type: word_explorer
  format: canonical
  version: 1
  schema_version: 1

  category: ''
  chapter: ''

  source_pack: ''        # Optional: originating Translation pack

dimensions:
  features:
    - base_word
    - meaning
    - formation
    - explanation

entries:

  - id: ''

    # Context (optional for standalone exploration)
    source:
      text: ''
      literal: ''
      target: ''

    # The word being explored
    word: ''
    base_word: ''
    type: ''

    # Meaning of this word in this context
    target: ''

    # Language-specific analysis
    morphology: {}

    # Learning support
    hint: ''

    # How the word was formed
    formation: ''

    # Why this form is used
    explanation: ''

    # Optional semantic role
    role: ''

    # Cross references
    vocabulary_ref: ''
    grammar_refs: []

```
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

The `forms` section is intended to capture useful forms—not complete paradigms.

Store only forms that:

- appear in the lesson,
- reinforce important grammar,
- or provide clear educational value.

Complete paradigms belong in the companion Conjugation pack.

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

Translation, vocabulary, and conjugation packs should function as a coherent learning system.

- ☐ Vocabulary entries support the translation pack.
- ☐ Conjugation entries correspond to vocabulary lemmas.
- ☐ Morphological forms complement—not replace—the Conjugation pack.
- ☐ Cross-references are complete and consistent.

---

## Final Question

Before publishing, ask one final question:

> **Will this pack help the learner understand how the language works—not just what the sentence means?**


If the answer is **yes**, the pack is ready for publication.

---

# Final Thoughts

This document and workflow wasn't designed to teach an AI how to write YAML.

It was designed to teach both human authors and AI assistants how to
think like a Linguatrain content author.

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
much more than asking an AI to translate a sentence or comparing my own
handwritten translations against an AI-generated answer. Both approaches
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

Whether the first draft is written by a human, an AI assistant,
or---most effectively---a collaboration between the two, the objective
remains the same:

> Help the learner understand the language, one meaningful idea at a
> time.


