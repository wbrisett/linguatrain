# Linguatrain Design Principles

> *"The best software architecture is discovered from the problem
> domain, not imposed upon it."*

This document captures the enduring design principles behind
Linguatrain. These principles are intended to outlive individual
implementations, languages, and technologies.

------------------------------------------------------------------------

# Design Principle #1

## Generalize the Framework. Specialize the Learning Experience.

Linguatrain is built on a simple philosophy:

> **Generalize the framework. Specialize the learning experience.**

The framework should remain language-agnostic. It should not contain
assumptions about Finnish, German, Italian, Japanese, or any other
language. The core engine should provide reusable learning modes,
scheduling, validation, and infrastructure.

However, language agnostic does **not** mean language ignorant.

Every language has its own structure, traditions, and pedagogical
challenges. A language learning system should respect those differences
rather than forcing every language into a single model.

Finnish naturally lends itself to explicit morphology, rich inflection,
carefully structured dialogs, and pronunciation that can be generated
algorithmically. Other languages may require entirely different
approaches.

The distinction is intentional:

-   **Framework** → generic and reusable.
-   **Content model** → adaptable to the language.
-   **Authoring tools** → free to evolve around the language.
-   **Learning experience** → optimized for how that language is
    actually learned.

Examples include:

-   Finnish morphology packs.
-   Dialog packs supporting conversation, translation, shadowing, and
    future roleplay.
-   Language-specific pronunciation generators (`fi_phonetic.rb`).
-   Authoring workflows that mirror established textbooks such as
    *Suomen Mestari*.

These adaptations belong outside the core framework. They enrich the
learner's experience without compromising the portability of the engine.

The framework should never dictate how a language is learned.

**The language should inform how the framework teaches it.**

------------------------------------------------------------------------

# Design Principle #2

## Separate Framework and Content

The Linguatrain repository contains the framework.

Course material, textbooks, vocabulary packs, dialogs, and other
educational content should live independently from the framework
whenever practical.

Benefits include:

-   reusable tooling
-   cleaner repositories
-   independent versioning
-   easier community contribution

------------------------------------------------------------------------

# Design Principle #3

## One Responsibility Per Tool

Every tool should perform one well-defined task.

Examples:

-   `build_yaml.rb` → build YAML from generic CSV.
-   `validate_pack.rb` → validate pack structure.
-   `fi_phonetic.rb` → add Finnish pronunciation.
-   `convert_apkg_to_linguatrain.rb` → migrate Anki decks.

Small tools compose better than one monolithic application.

------------------------------------------------------------------------

# Design Principle #4

## Build From Real Content

Avoid designing abstractions in isolation.

Instead:

1.  Build real learning content.
2.  Observe recurring patterns.
3.  Extract the abstraction.
4.  Refactor the framework.

Real educational content is the best architecture review.

------------------------------------------------------------------------

# Design Principle #5

## Optimize for Learning

Implementation convenience should never outweigh pedagogy.

Questions should always include:

-   Does this help the learner?
-   Does this reflect how the language is naturally taught?
-   Does this preserve useful context?

If there is tension between elegant code and effective learning, prefer
the learner.

------------------------------------------------------------------------

# Design Principle #6

## Preserve Information

When information may enable future learning modes, preserve it.

Examples:

-   speaker
-   dialog turns
-   chunks
-   literal translations
-   vocabulary references
-   grammar references

Future capabilities should emerge naturally from the data model.

------------------------------------------------------------------------

# Design Principle #7

## Discover, Don't Invent

Linguatrain evolves through iterative design.

Architecture should emerge from:

-   textbooks
-   real learners
-   actual study sessions
-   engineering discussion

Rather than attempting to predict every future requirement, preserve
clean abstractions that allow the project to grow naturally.

------------------------------------------------------------------------

# Design Principle #8 

## Teach Understanding, Not Answers

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

-------------------------------------------------------------------

## Summary

Linguatrain is not designed to make every language behave identically.

It is designed to provide each language with the engineering support
necessary to teach that language well while maintaining a common,
reusable foundation.

> **Generalize the framework. Specialize the learning experience.**
