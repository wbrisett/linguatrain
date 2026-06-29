# Linguatrain Engineering Journal

> This journal captures **why** architectural decisions were made. It is
> not a changelog. It records design discussions, alternatives
> considered, trade-offs, and the reasoning behind decisions.

------------------------------------------------------------------------

# 2026-06-26

## Major Theme

Over several design sessions, Linguatrain transitioned from being viewed
as a collection of study modes to a language-learning platform with a
coherent content architecture.

Many decisions below were discovered while authoring real content from
*Suomen Mestari*, rather than through speculative design.

----------------------------

# Engineering Journal

## 2026-06-29 — Translation Module Reaches Version 1.0

The Translation module reached what I consider its first stable design today.

Although the YAML schema evolved throughout development, the most significant discoveries were not about the schema itself—they were about how people learn a language.

---

## Discovery 1 — Translation is About Understanding, Not English

One of the earliest realizations was that the Translation module is not intended
to teach English.

Its purpose is to help the learner understand how ideas expressed in the source
language map onto their own language.

This shifted the module away from "find the correct English sentence" toward
"understand how this sentence is constructed."

That distinction influenced nearly every design decision that followed.

---

## Discovery 2 — Literal Translation is Educational Scaffolding

Initially the literal translation existed simply as additional metadata.

Over time it became clear that it serves a much more important purpose.

The literal translation forms the bridge between the source language and the
natural translation.

It intentionally preserves the structure of the original language, even when the
result sounds awkward in English.

That awkwardness is valuable—it exposes how the language actually works.

---

## Discovery 3 — Chunks are Semantic Units

Chunking proved to be the single most important aspect of the Translation
module.

A chunk is not simply a group of words.

It is the smallest meaningful translation unit that can be recognized and reused
by the learner.

This led to an important design guideline:

> Chunk meaningful ideas, not arbitrary words.

Well-chosen chunks allow learners to recognize recurring patterns across future
lessons.

---

## Discovery 4 — The Guide Became a Specification

The Translation Authoring Guide began as documentation describing the YAML
schema.

Over time it evolved into something much more valuable.

It now describes:

- the schema
- the educational philosophy
- recommended authoring practices
- chunking strategy
- AI-assisted workflows
- progressive enrichment

Rather than documenting the schema, the guide now specifies how high-quality
Translation YAML documents should be authored.

---

## Discovery 5 — AI Can Successfully Author Translation Documents

One of the goals of the Translation Authoring Guide was to determine whether it
communicated enough educational intent for an AI assistant to author useful
Translation YAML.

Independent authoring experiments were performed using multiple AI systems.

Each system was provided with:

- source material
- the Translation Authoring Guide
- a canonical Translation YAML document

Despite being developed independently, each system produced remarkably similar
results.

The differences were generally stylistic rather than architectural.

This provided confidence that the authoring guide communicates both the required
structure and the educational philosophy behind the Translation module.

---

## Discovery 6 — AI Works Best as a Collaborative Author

Throughout development it became clear that AI is neither an automatic converter
nor a replacement for human review.

Its greatest value lies in accelerating repetitive authoring tasks while the
human author focuses on educational quality.

The most successful workflow consistently followed this pattern:

```
Source Material
        ↓
AI-generated first draft
        ↓
Human review and refinement
        ↓
Final Translation YAML
```

Neither participant works as effectively in isolation.

The highest quality results come from collaboration.

---

## Discovery 7 — Every Module Should Teach One Cognitive Skill

Perhaps the most important architectural insight emerged near the end of the
project.

Rather than attempting to teach every aspect of a language simultaneously, each
module should focus on a single cognitive task.

For example:

```
Vocabulary
    ↓
Recognize words

Translation
    ↓
Understand sentence structure

Morphology
    ↓
Understand word construction

Conversation
    ↓
Apply language naturally
```

Each module becomes another layer in the learner's understanding rather than an
independent collection of exercises.

This principle is expected to guide future modules, particularly the planned
Morphology module.

---

## Discovery 8 — The Educational Philosophy Can Be Communicated

Perhaps the most encouraging outcome of the project was observing independent AI
systems consistently describe the Translation module using nearly identical
language.

Without prompting, they independently identified concepts such as:

- chunk meaningful ideas
- use literal translations as scaffolding
- separate grammar from translation
- progressively enrich content
- treat AI as a collaborative author

This suggests that the Translation Authoring Guide communicates not only *how*
to build Translation YAML, but *why* it is designed that way.

That represents a significant milestone for the project.

---

## Reflection

The Translation module ultimately became far more than a YAML schema.

It became an exploration of how structured content can support language
learning.

The guiding principle that emerged throughout its development was remarkably
simple:

> Structure should serve understanding, not constrain it.

That principle now influences both the software architecture and the design of
every learning module that follows.

------------------------------------------------------------------------

# AD-0001 --- Framework vs. Content

## Problem

How should Linguatrain support many languages without becoming tightly
coupled to Finnish?

## Alternatives

-   Put language knowledge into the framework.
-   Keep the framework generic and move language intelligence into
    content and tooling.

## Decision

The framework remains language-agnostic.

Language-specific behavior belongs in content models and external tools.

## Consequences

This led directly to:

-   build_yaml.rb
-   fi_phonetic.rb
-   PACK_AUTHORING.md

------------------------------------------------------------------------

# AD-0002 --- CSV Pipeline

Diagram:

``` text
Photo
   ↓
ChatGPT
   ↓
CSV
   ↓
build_yaml.rb
   ↓
fi_phonetic.rb
   ↓
validate_pack.rb
```

Decision:

CSV is the canonical source for vocabulary and phrase packs.

Generated YAML is disposable.

Reason:

Editing generated YAML inevitably causes divergence.

------------------------------------------------------------------------

# AD-0003 --- Translation Architecture

Original assumption:

Translation == Dialog

Problem:

Books such as Juttuja Suomesta contain narrative text with no speakers.

Decision:

Translation is the generic content type.

Dialogs are one specialization.

Diagram:

``` text
                    Content
                       │
        ┌──────────────┴──────────────┐
        │                             │
   Vocabulary Pack              Translation Pack
                                      │
                           ┌──────────┴──────────┐
                           │                     │
                        Dialog              Narrative
                           │
                    ┌──────┴──────┐
                    │             │
             Conversation    Translation
```

Consequences:

Conversation consumes dialogs.

Translation consumes dialogs and narrative text.

------------------------------------------------------------------------

# AD-0004 --- Preserve Information

Question:

"What information might Future Wayne need?"

Decision:

Preserve rich metadata whenever it enables future learning modes.

Examples:

-   speaker
-   dialog turns
-   literal translations
-   chunks
-   vocabulary references
-   embedded vocabulary
-   grammar references

Do not implement future features prematurely. Do preserve the data
needed to build them.

------------------------------------------------------------------------

# AD-0005 --- One Tool, One Responsibility

Decision:

Each tool performs one job.

  Tool                             Responsibility
  -------------------------------- -----------------------
  build_yaml.rb                    CSV → YAML
  validate_pack.rb                 Validation
  fi_phonetic.rb                   Finnish pronunciation
  convert_apkg_to_linguatrain.rb   Anki migration

Rejected:

A monolithic builder that performs every step.

Reason:

Small composable tools are easier to maintain and extend.

------------------------------------------------------------------------

# AD-0006 --- Dialogs

Discovery:

Conversation mode already existed before dialog packs were formally
designed.

Conclusion:

Dialogs are a primary learning artifact.

One dialog should support multiple study modes.

Diagram:

``` text
Dialog
 │
 ├── Translation
 ├── Conversation
 ├── Shadow (future)
 ├── Roleplay (future)
 └── Listening (future)
```

Roleplay emerged naturally from preserving speakers and turns.

------------------------------------------------------------------------

# AD-0007 --- Learning Progression

Diagram:

``` text
Words
   ↓
Phrases
   ↓
Translation
   ↓
Conversation
   ↓
Shadow
   ↓
Roleplay
```

Observation:

These are not independent features.

They are successive stages of language acquisition.

Future development should preserve this progression.

------------------------------------------------------------------------

# AD-0008 — Saved Translation Chunks

Problem

During translation practice, learners often become blocked on a specific phrase or chunk rather than an entire sentence.

Traditional flashcard systems typically require the learner to remember which phrases caused difficulty and manually create additional study material later. This interrupts the learning process and makes targeted review difficult.

Alternatives Considered

Option A: Record incorrectly translated sentences automatically.

Rejected because the learner may have understood most of the sentence and struggled with only one phrase.

Option B: Allow learners to manually create flashcards after the exercise.

Rejected because it interrupts study flow and relies on the learner remembering what caused difficulty.

Option C: Allow the learner to mark individual chunks during the exercise.

Accepted.

Decision

Translation mode will support marking individual chunks for later review.

When a learner requests a hint or discovers a difficult chunk, they may choose Mark Chunk. The marked chunk is added to a temporary collection for the current session.

At the end of the session (or when quitting), Linguatrain generates a new YAML study pack containing all marked chunks.

Example Workflow

Translation Exercise
Hei!
En vielä.
Kello on täällä vasta puoli kahdeksan.
> Hi!
Results
✓ Hei!
✗ En vielä.
✗ Kello on täällä vasta puoli kahdeksan.
[H]int  [M]ark Chunk  [R]etry  [S]how Answer

The learner chooses Mark Chunk and selects:

1. En vielä.
2. Kello on täällä vasta puoli kahdeksan.

The selected chunk is saved for later review.

Generated Output

At the end of the session, Linguatrain generates a standard YAML study pack.

This allows the learner to review difficult chunks using the existing study engine without requiring any additional review mode.

Important Design Decision

The original translation or dialog pack is never modified.

Saved chunks are written to a new learner-owned pack.

This preserves the integrity of the original educational content while allowing personalized study material to evolve independently.

Rationale

This feature transforms moments of difficulty into future learning opportunities.

Instead of reviewing entire dialogs repeatedly, learners build a personalized collection of phrases they have demonstrated difficulty translating.

Over time, these generated packs become a highly individualized review resource based on actual performance rather than assumptions.

Future Possibilities

The same mechanism could eventually support:

* automatic spaced repetition scheduling
* statistics showing commonly marked chunks
* merging multiple sessions into a long-term review pack
* exporting learner-specific phrase books

The architecture intentionally preserves these possibilities without requiring them in the initial implementation.

------------------------------------------------------------------------


# AD-0008 — Saved Translation Chunks

Problem

During translation practice, learners often become blocked on a specific phrase or chunk rather than an entire sentence.

Traditional flashcard systems typically require the learner to remember which phrases caused difficulty and manually create additional study material later. This interrupts the learning process and makes targeted review difficult.

Alternatives Considered

Option A: Record incorrectly translated sentences automatically.

Rejected because the learner may have understood most of the sentence and struggled with only one phrase.

Option B: Allow learners to manually create flashcards after the exercise.

Rejected because it interrupts study flow and relies on the learner remembering what caused difficulty.

Option C: Allow the learner to mark individual chunks during the exercise.

Accepted.

Decision

Translation mode will support marking individual chunks for later review.

When a learner requests a hint or discovers a difficult chunk, they may choose Mark Chunk. The marked chunk is added to a temporary collection for the current session.

At the end of the session (or when quitting), Linguatrain generates a new YAML study pack containing all marked chunks.

Example Workflow

Translation Exercise
Hei!
En vielä.
Kello on täällä vasta puoli kahdeksan.
> Hi!
Results
✓ Hei!
✗ En vielä.
✗ Kello on täällä vasta puoli kahdeksan.
[H]int  [M]ark Chunk  [R]etry  [S]how Answer

The learner chooses Mark Chunk and selects:

1. En vielä.
2. Kello on täällä vasta puoli kahdeksan.

The selected chunk is saved for later review.

Generated Output

At the end of the session, Linguatrain generates a standard YAML study pack.

This allows the learner to review difficult chunks using the existing study engine without requiring any additional review mode.

Important Design Decision

The original translation or dialog pack is never modified.

Saved chunks are written to a new learner-owned pack.

This preserves the integrity of the original educational content while allowing personalized study material to evolve independently.

Rationale

This feature transforms moments of difficulty into future learning opportunities.

Instead of reviewing entire dialogs repeatedly, learners build a personalized collection of phrases they have demonstrated difficulty translating.

Over time, these generated packs become a highly individualized review resource based on actual performance rather than assumptions.

Future Possibilities

The same mechanism could eventually support:

* automatic spaced repetition scheduling
* statistics showing commonly marked chunks
* merging multiple sessions into a long-term review pack
* exporting learner-specific phrase books

The architecture intentionally preserves these possibilities without requiring them in the initial implementation.

------------------------------------------------------------------------

# AD-0009 — Stable Identifiers

Problem

As Linguatrain grows, learning content will be referenced by multiple modules, user-generated review packs, analytics, and future learning modes.

Text alone is not a reliable identifier. Sentences may change, translations may improve, and content may be reorganized over time.

Decision

Every first-class object within a content pack should have a stable identifier.

Examples include:

* translation turns
* dialog turns
* chunks
* vocabulary entries
* grammar entries (where applicable)

Identifiers exist for the architecture, not for the learner.

Rationale

Stable identifiers allow independent components of Linguatrain to reference content without depending on the text itself.

Examples include:

* Conversation mode
* Translation mode
* Shadow mode
* Roleplay
* Saved chunk review packs
* Learning analytics
* Future bookmarking and annotation
* Cross-references between content packs

Design Philosophy

A stable identifier represents the identity of a learning object rather than its current textual representation.

Content may evolve.

Identifiers should not.

This principle borrows heavily from structured content systems such as DITA, where addressability enables reuse, linking, and long-term maintainability.

-----------------------------------------------------------

## AD-0010 — Design Around Learning, Not Features

### Observation

Linguatrain development often begins with a feature request.

However, implementation should pause as soon as the educational workflow becomes clear.

### Example

The initial goal was to implement a Translation mode.

Within the first design session the discussion shifted toward:

- chunking
- hints
- retries
- dialogs
- narratives
- saved chunks
- roleplay

The feature became secondary.

The learning experience became primary.

### Decision

When designing new capabilities, prioritize improving the learner's experience over completing the feature as originally envisioned.

The software exists to support learning.

Features exist only insofar as they improve that learning experience.

--------------

## 2026-06-26 — First End-to-End Translation Exercise

Today marked the first successful end-to-end execution of Linguatrain's Translation mode using the opening dialogue from *Suomen Mestari 1*, Chapter 1.

Although the original objective was simply to build a translation exercise, the implementation process fundamentally changed our understanding of how translation content should be modeled.

### Major Architectural Decisions

#### Semantic Chunking

The most significant design decision was moving away from arbitrary sentence segmentation toward **semantic chunking**.

Rather than splitting text by words or grammatical boundaries, chunks are authored as the smallest independently learnable semantic units.

Examples:

| Avoid | Prefer |
|-------|--------|
| `onko täällä suomen kurssi` | `onko` / `täällä` / `suomen kurssi` |
| `Hauska` + `tutustua` | `Hauska tutustua` |
| `Kiitos` + `samoin` | `Kiitos samoin` |

A chunk may be:

- a single word
- a collocation
- an idiomatic phrase
- a reusable expression

The determining factor is **pedagogical value**, not textual size.

This philosophy mirrors DITA's concept of semantic reuse: the reusable unit is whatever represents a complete concept.

---

### Progressive Translation

The Translation exercise no longer behaves like a traditional "right or wrong" translation test.

Instead it progressively guides the learner.

Example workflow:

```
Kiva / Minä olen / Alex / Kuka / sinä olet

> Nice. I am Alex
```

Results:

```
✓ Kiva
✓ Minä olen
✓ Alex
✗ Kuka
✗ sinä olet
```

Retry:

```
✓ Kiva : Nice
✓ Minä olen : I am
✓ Alex : Alex

Kuka / sinä olet

> Who are you?
```

Only the remaining unknown concepts require translation.

Previously mastered concepts remain visible as positive reinforcement.

---

### Progressive Hint Strategy

Hints now follow a deliberate instructional progression.

1. Chunk-specific hint
2. Chunk translation
3. Vocabulary information
4. Grammar information
5. Literal translation

For example:

```
Hint:

"sinä olet" means "you are".
```

followed later by

```
Literal:

Nice. I am Alex. Who you are?
```

The learner receives progressively stronger assistance without immediately revealing the answer.

---

### Partial Success

One of today's most important observations was psychological rather than technical.

Traditional flashcard systems typically produce:

```
Wrong.
```

Linguatrain instead communicates:

```
You successfully translated these concepts.

Only these concepts still need work.
```

The learner experiences continual progress rather than repeated failure.

---

## ## Teach Understanding, Not Answers

Linguatrain is designed to help learners understand why an answer is correct,
not simply whether it is correct.

Every learning module should expose one additional layer of linguistic
structure.

Examples:

- Vocabulary exposes reusable words.
- Translation exposes sentence structure.
- Morphology exposes word construction.
- Conversation exposes communication.

Rather than overwhelming learners with complete linguistic theory, each module
acts as a cognitive bridge between what the learner already understands and the
next concept they need to discover.

### Translation as a Learning Model

Today's work reinforced that Linguatrain is not modeling flashcards.

It is modeling relationships between semantic learning objects.

The content hierarchy is becoming:

```
Vocabulary
        ↓
Semantic Chunks
        ↓
Translation Turns
        ↓
Dialogues
        ↓
Role Play
```

Each layer reinforces the previous one.

---

### Engineering Observation

Several hours were spent debating chunk boundaries.

The resulting Translation exercise demonstrated that this effort was worthwhile.

Without semantic chunking, retry would have consisted of retranslating entire sentences.

With semantic chunking, retry focuses only on concepts that remain unmastered.

This validates the decision to author content according to learning concepts rather than sentence structure.

---

### Design Principle

> **Chunk for learning, not for parsing.**

A chunk is the smallest semantic unit that can be independently recognized, translated, or reused.

Chunk boundaries are determined by pedagogy rather than grammar, punctuation, or a fixed number of words.

This principle is expected to guide all future Translation content authored for Linguatrain.

---------

# Lessons Learned

The most valuable architectural decisions were not invented.

They emerged while building real educational content.

Whenever implementation convenience conflicted with pedagogy, the
learner won.

------------------------------------------------------------------------

# Open Questions

-   Semantic vs grammatical chunking.
-   Dialog schema refinements after Chapter 1.
-   Roleplay interaction model.
-   Audio metadata for speakers.
-   Cross-linking dialog packs to vocabulary packs.
