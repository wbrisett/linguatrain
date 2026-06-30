# Linguatrain Translation YAML Design Guide

## Purpose

This document captures the design decisions behind the Translation
module schema.

The goal is **not** to model a textbook. The goal is to model the
process a learner goes through while decoding a foreign language.

------------------------------------------------------------------------

# Core Philosophy

Every translation exercise moves through three stages:

    Original language Text
        ↓
    Literal target language
        ↓
    Natural target language

The literal translation preserves the structure of the original
language.

The natural translation expresses the same idea in idiomatic English.

This distinction became one of the most important design decisions in
the module.

## Finnish Example: 

``Original``: Hyvä. Onko tämä paikka vapaa?

``Literal``: Good. Is this place free?

``Natural``: Good. Is this seat free?

------------------------------------------------------------------------

# Required Top-Level Metadata

``` yaml
metadata:
  id:
  title:
  type: translation
  format:
  version:
  schema_version:
  source_language:
  target_language:
```

These fields describe the document, not the learning content.

------------------------------------------------------------------------

# Entry Schema

Each exercise is an `entry`.

``` yaml
- id:
  type:           # optional
  speaker:        # optional
  source:
  phonetic:        # optional
  literal:
  target:
  chunks:
  vocabulary_refs:  # optional
  grammar:          # optional
    refs:           # optional
```

## Required

-   id
-   source
-   literal
-   target
-   chunks

## Optional

-   type
-   speaker
-   phonetic
-   vocabulary_refs
-   grammar


### Type Entries

Use `narrative` for non-spoken text such as introductions, scene-setting, exposition, signs, captions, or descriptive prose.

Use `dialogue` for spoken lines where a speaker is identified.


------------------------------------------------------------------------
### Narrative Entries

Translation documents are not limited to dialogue.

Many sources begin with scene-setting narration or descriptive prose before spoken dialogue begins.

Use `type: narrative` for non-spoken content.

Narrative entries omit the `speaker` field.

```yaml
- id: e001
  type: narrative

  source: "..."

  target: "..."
```

Narrative entries follow the same translation principles as dialogue entries, including chunking, literal translations, hints, vocabulary references, and grammar references.

-------
# Why Chunks Exist

Chunks are **not** arbitrary slices of text.

A good chunk is the smallest meaningful translation unit that a learner can
recognize, understand, and reuse later.

Example (using Finnish):

**Source line**

```
Anteeksi, onko täällä suomen kurssi?
```

**Chunks from the source**

```
Anteeksi
onko täällä
suomen kurssi
```

**Literal translation of each chunk**

```
Excuse me
Is here
Finnish course
```

When combined, those chunk translations produce the sentence's literal translation:

```
Excuse me, is here Finnish course?
```

Notice that the literal translation sounds unnatural in English. That is
intentional. Literal translations expose how the original language is
constructed before the learner moves on to the natural translation.

Each chunk should represent something a learner can recognize and reuse later.

------------------------------------------------------------------------

# Every Chunk Mirrors the Entry

``` yaml
chunks:
  - id:
    source:
    phonetic:      # optional
    literal:
    target:
    hint:
```

This recursive structure is intentional.

A learner first understands the chunk.

The sentence is then assembled from understood chunks.

------------------------------------------------------------------------

# Pronunciation / Phonetic Guidance

Translation entries may include an optional `phonetic` field. Chunks may also include their own optional `phonetic` field.

Use the singular field name:

```yaml
phonetic:
```

Do **not** use `phonetics` in new authoring examples.

`phonetic` is a beginner-friendly pronunciation guide for the `source` text. It is not a replacement for audio, IPA, or a formal linguistic transcription. Its purpose is to help the learner make a reasonable first attempt at reading the source-language text aloud.

Example:

```yaml
- id: e001
  type: dialogue
  speaker: Alex
  source: "Anteeksi, onko täällä suomen kurssi?"
  phonetic: "AHN-tehk-see, OHN-koh TAAH-la SOO-oh-men KOORS-see?"
  literal: "Excuse me, is here Finnish course?"
  target: "Excuse me, is the Finnish course here?"
  chunks:
    - id: c001
      source: "Anteeksi"
      phonetic: "AHN-tehk-see"
      literal: "Excuse me"
      target: "Excuse me"

    - id: c002
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

```bash
--show-phonetic
```

When enabled, Linguatrain may display pronunciation:

- under the full source sentence at the start of an exercise
- for missed chunks after an incorrect answer
- for remaining chunks during retry
- when the learner asks to show the answer

This follows the general Linguatrain principle of progressive disclosure: show pronunciation when it helps the learner, but do not clutter the default translation exercise.

## Authoring Guidance for AI Agents

When generating translation YAML, include `phonetic` when pronunciation would help the learner. This is especially useful for beginner packs, textbook samples, dialogue, unfamiliar names, difficult compounds, and languages where spelling does not reliably predict pronunciation.

For Finnish beginner material, prefer readable approximations that preserve important learner distinctions:

- mark long vowels with doubled vowel letters where helpful, such as `TAAH-la` for `täällä`
- keep doubled consonants visible, such as `KOORS-see` for `kurssi`
- avoid overexplaining inside the `phonetic` field
- preserve distinctions that materially affect pronunciation in the source language
- keep the guide short enough to scan while translating
- use the same style consistently across entries and chunks
- if pronunciation cannot be represented clearly and reliably, omit `phonetic`

Bad:

```yaml
phonetic: "This is pronounced with a long ä sound and a long s..."
```

Good:

```yaml
phonetic: "TAAH-la"
```

Entry-level `phonetic` should cover the complete `source` sentence or line.

Chunk-level `phonetic` should cover only that chunk's `source`.

If the AI is not confident in a pronunciation guide, it should omit `phonetic` rather than invent an unreliable one.

------------------------------------------------------------------------

# Literal vs Natural Translation

Example:

Source

    pillin äänen

Literal

    whistle's sound

Natural

    the sound of a whistle

The literal, in this example, teaches how Finnish is constructed.

The natural translation, in this example, teaches how English expresses the same idea.

Both are valuable.

------------------------------------------------------------------------

# Chunking Guidelines

Chunking is one of the most important aspects of a translation document.

A chunk should represent a **complete unit of meaning** that a learner can understand, remember, and reuse in future sentences.

The goal is not to make the chunks as small as possible. The goal is to divide the sentence into pieces that naturally carry meaning.

Good chunks include:

- noun phrases
- verb phrases
- fixed expressions
- idiomatic expressions
- complete grammatical units

These guidelines are intentionally opinionated rather than prescriptive.

Understanding *why* a recommendation exists is more valuable than following it mechanically. If a different chunk boundary better serves the educational objective, prefer the educational outcome over rigid consistency.

Avoid:

- splitting a phrase that naturally belongs together
- making chunks so large that they become difficult to translate
- breaking apart expressions that learners will encounter again as a unit

## Good Examples

### Fixed expression

```text
Hauska tutustua
```

This is a complete expression meaning *"Nice to meet you."*

Although it contains two words, learners recognize and use it as a single phrase.

---

### Idiomatic greeting

```text
Mitä kuuluu?
```

This is a fixed greeting.

Teaching it as one unit helps the learner recognize it immediately in future conversations.

---

### Noun phrase

```text
suomen kurssi
```

This is a complete noun phrase.

The learner should associate the phrase with the concept "Finnish course" rather than translating each word independently every time.

---

### Verb phrase

```text
tuli katsomaan
```

These words express a single action:

> came to see

Separating them removes the relationship between the motion verb and the infinitive.

## Poor Examples

### Splitting a fixed expression

```text
Hauska
tutustua
```

Neither chunk represents the meaning the learner is trying to acquire.

The learner would first translate two unrelated pieces and then have to reconstruct the expression afterward.

The goal is to recognize **"Hauska tutustua"** immediately as one communicative phrase.

---

### Splitting a noun phrase

```text
suomen
kurssi
```

While technically correct, this creates unnecessary work.

The learner already knows:

- suomen → Finnish
- kurssi → course

The useful skill is recognizing the phrase:

> Finnish course

as a single concept.

## Guiding Principle

Whenever possible, chunk according to **meaning**, not simply by word boundaries.

A learner should be able to look at a chunk and think:

> "I've seen this before."

rather than:

> "Now I need to assemble these words back into a phrase."

------------------------------------------------------------------------

# The Role of the Translation Module

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

```
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

------------------------------------------------------------------------

## Building Towards Translation

Translation is not intended to be the learner's first exposure to new words.

Instead, it represents the next stage of learning.

A recommended learning sequence is:

```
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

## Companion Vocabulary Packs

A complete translation document should normally be accompanied by a vocabulary pack.

The translation document identifies useful words and phrases through `vocabulary_refs`. The companion vocabulary pack defines those references as studyable vocabulary entries. This lets the learner study the vocabulary first and then use the translation exercise to understand how those words combine in real sentences.

Recommended file pairing:

```text
suomen_mestari_1_kappale_01_translation.yaml
suomen_mestari_1_kappale_01_vocabulary.yaml
```

The translation pack remains focused on sentences, chunks, literal translations, natural translations, hints, and grammar references.

The vocabulary pack is where reusable lexical knowledge belongs: meanings, types, forms, pronunciation, literal structure, and short usage notes.

### Vocabulary Pack Shape

Companion vocabulary packs should use the normal Linguatrain vocabulary schema so they can be studied directly before the translation exercise.

```yaml
metadata:
  id: suomen_mestari_1_kappale_01_vocabulary
  title: Suomen Mestari 1 - Kappale 1 Vocabulary
  type: vocabulary
  format: canonical
  version: 1
  schema_version: 1
  source_pack: suomen_mestari_1_kappale_01_translation

entries:
  - id: tervetuloa
    prompt: tervetuloa
    answer: welcome
    type: phrase
    notes:
      - 'Often followed by the allative case: “kurssille” = “to the course”.'

  - id: kirjoittaa
    prompt: kirjoittaa
    answer:
      - to write
      - to spell
    type: verb
    notes:
      - 'In spelling questions, Finnish often uses passive “kirjoitetaan” = “is written/spelled”.'
```

Use `prompt` for the source-language word or phrase and `answer` for the target-language meaning.

Use the entry `id` as the canonical reference value used by `vocabulary_refs` in the translation document.

For example, this translation entry:

```yaml
vocabulary_refs:
  - tervetuloa
  - suomen kurssi
```

should point to vocabulary entries whose IDs match those references. If a reference contains spaces or characters that are awkward in IDs, prefer a normalized ID such as `suomen_kurssi`, and use that same normalized ID consistently in `vocabulary_refs`.

### Vocabulary Notes

Vocabulary `notes` should contain short, learner-useful observations that make the word or phrase easier to recognize, remember, or use.

Include notes for information that helps avoid common learner mistakes, such as:

- idiomatic usage
- common collocations
- compound word breakdowns
- important case usage
- common learner confusions
- words whose meaning differs from a similar-looking English word

Examples:

```yaml
notes:
  - '“Tässä on...” is often used when introducing someone or presenting something.'
```

```yaml
notes:
  - 'Compound: kurssi + päivä. Plural: kurssipäivät.'
```

```yaml
notes:
  - 'Can mean “place” generally or “seat” in a classroom context.'
```

Keep notes concise. They should add one useful teaching point, not become a grammar lesson. Longer grammatical explanations belong in grammar documentation or in a chunk hint when the learner needs that information to complete the translation.

---

## Preparing the Learner for Success

The objective is not to test whether a learner can guess unknown vocabulary.

Instead, the objective is to help the learner successfully read increasingly complex text.

Whenever practical, the vocabulary required for a translation document should already exist in one or more vocabulary packs. This allows the learner to approach the translation exercise with confidence, focusing on understanding how words combine rather than trying to discover the meaning of every unfamiliar word.

This does not mean every word must already be known.

Occasionally a translation exercise will introduce a new word or expression that has not yet appeared in a vocabulary pack. This is perfectly acceptable, especially when it helps maintain the natural flow of authentic material.

When this occurs, the translation document should provide an appropriate hint for that chunk. A well-written hint gives the learner just enough information to continue without immediately revealing the complete translation.

Hints should support learning, not replace it.

------------------------------------------------------------------------

# Hints

Hints exist to help the learner continue making progress without immediately revealing the answer.

A good hint provides just enough information for the learner to solve the remaining translation independently.

Hints should guide the learner, not replace the learning process.

---

## When to Use Hints

Hints are most valuable when they:

- explain an unfamiliar word or expression
- identify a fixed phrase or idiom
- clarify a chunk whose meaning is not immediately obvious
- provide enough context for the learner to continue translating

Hints should encourage another attempt rather than end the exercise.

---

## Good Hints

A good hint removes the immediate obstacle while allowing the learner to complete the translation.

Examples:

> `"täällä" means "here".`

> `"Mitä kuuluu?" is a common greeting meaning "How are you?"`

> `"Hauska tutustua" is a fixed expression used when meeting someone.`

> `"kirjoitetaan" literally means "is written" and is commonly used when asking how something is spelled.`

Each of these gives the learner enough information to continue translating the sentence without revealing the entire answer.

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

------------------------------------------------------------------------

# What Makes a Good Translation Document?

A good document should allow the learner to:

1.  Read the Finnish.
2.  Decode it chunk by chunk.
3.  Understand the literal structure.
4.  Produce natural English.
5.  Learn reusable phrases.
6.  Discover grammar naturally through references.

------------------------------------------------------------------------

# Final Design Principles

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

# Authoring Workflow

Linguatrain is designed as a framework rather than a content library.

While a representative translation document is included with the project, the expectation is that authors will create translation documents for the material they wish to study.

This section discusses where that material can come from and describes a workflow for producing high-quality translation documents.

## Human Source Material

The highest quality source material is content that has already been translated or authored by a language instructor, professional translator, or native speaker.

Examples include:

- language textbooks
- graded readers
- children's books
- professionally translated documents

```
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

```
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

```
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

# A Collaborative Process

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

```
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

------
## Providing Context to an AI Assistant

The quality of AI-generated translation documents depends heavily on the quality of the information provided to the AI.

Simply asking an AI to:

> "Translate this into YAML."

is unlikely to produce the educational structure described in this guide.

Instead, provide the AI with enough context to understand both the format and the educational objective.

A successful authoring request should include:

1. The canonical translation YAML example.
2. The canonical vocabulary YAML example.
3. This Translation YAML Design Guide.
4. The new source material.
5. A clear statement describing the desired outcome.

The goal is not simply to obtain a translation.

The goal is to produce a translation document that helps someone learn the language.

---

### Example Request

A request such as the following provides the AI with both the structure and the educational objective:

> I have attached four documents:
>
> 1. The canonical Translation YAML example.
> 2. The canonical Vocabulary YAML example.
> 3. The Translation YAML Design Guide.
> 4. New source material.
>
> Using the canonical examples and the design guide as your reference, create both a complete Translation YAML document and a companion Vocabulary YAML document for the supplied source material.
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
> 


---

### Give the AI a Role

One technique that consistently improves results is to clearly define the role the AI should perform.

For example:

> Act as an experienced Linguatrain content author. Your objective is not simply to translate the text, but to create educational material that helps a learner understand the language. Follow the Translation YAML Design Guide and use the canonical example as the reference for style and structure.

Providing this context encourages the AI to make educational decisions rather than simply producing a direct translation.


---

### Review the Results

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


# Learning Progression

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
- **Conversation** teaches communication using the patterns learned elsewhere.

Each module complements the others while remaining focused on one learning objective.

> A good translation document should feel less like a static database and more like a scaffolded classroom discussion between a student and a teacher.

# A Final Thought

This workflow wasn't designed to teach an AI how to write YAML.

It was designed to teach both human authors and AI assistants how to think like a Linguatrain content author.

I have spent the better part of four decades working with technical content. Linguatrain exists because I couldn't find a language-learning program that treated content the way I believed it should be treated. Most applications focus on vocabulary, pronunciation, or conversation. Those are all important, but understanding a language requires more than memorizing words; it requires learning how ideas are expressed.

The Translation module began with a very simple question:

> *How can I take the content from my language textbook and truly understand it by translating it?*

As I worked on the idea, it became obvious that translation involved much more than asking an AI to translate a sentence or comparing my own handwritten translations against an AI-generated answer. Both approaches produce answers, but neither necessarily produces understanding.

A student and teacher don't work that way in a classroom.

They work through the material together.

They break difficult sentences into meaningful pieces. They discuss vocabulary. They examine how phrases fit together before assembling the complete translation.

That observation became the foundation of this translation schema.

As a content engineer, my instinct was to give that learning process structure. Meaningful chunks became first-class objects. Literal translations became an intermediate learning step rather than an afterthought. Hints became opportunities to guide rather than simply reveal answers. Over time, those ideas evolved into the workflow described in this document.

The result is a framework that is designed to help people learn from real content, not simply translate it.

The workflow is intentionally simple:

```
The schema defines the structure.

The canonical example demonstrates the style.

The design guide explains the educational philosophy.
```

Together, these three artifacts provide everything needed to produce consistent, high-quality translation documents.

Whether the first draft is written by a human, an AI assistant, or—most effectively—a collaboration between the two, the objective remains the same:

> Help the learner understand the language, one meaningful idea at a time.

---

## AI Is an Assistant, Not an Authority

This guide is intentionally opinionated. It reflects the workflow that proved successful while developing Linguatrain and while learning Finnish myself.

Finally, I can't stress enough that AI is a helper, not a magical wizard. It will make mistakes. It can present an answer with complete confidence that is simply wrong because it has missed a nuance, misunderstood the context, or chosen an incorrect interpretation. This is why collaboration and independent verification remain important.

Many years ago, when I worked for a technology company, our documentation was translated by one translation company and then independently reviewed by another. The goal wasn't to prove the first company was wrong; it was to improve quality through verification.

I recommend the same workflow here.

Let AI produce the first draft. Review it critically. If something doesn't feel right, verify it. Ask a native speaker. Consult a teacher. Compare another translation. Use language forums to verify individual sentences. Most people are happy to explain a few phrases, even if they aren't going to translate an entire book.

The purpose of AI is not to replace human expertise.

Its purpose is to accelerate the mechanical work so that the human author can focus on what matters most:

> Creating translation material that helps someone truly understand another language.