# Word Explorer Design Specification

> Version: 0.9 "Frosty"
>
> Status: nearly stable, implementation-driven refinement expected

This document captures the current design contract for Linguatrain's
Word Explorer feature. It is intended to preserve the decisions made during
the design process so future implementation work does not need to rediscover
the same concepts.

Word Explorer began as a discussion about Finnish cases, but the underlying
feature is broader than cases or morphology. The learner's real question is:

> Why does this word look like this?

Word Explorer answers that question by helping the learner understand how an
encountered word relates to its base word, how it was formed, what it means in
context, and what related forms are useful to explore.

------------------------------------------------------------------------

# Core Philosophy

Word Explorer is a guided exploration system, not a quiz system.

The learner is not simply trying to pass or fail a prompt. They are exploring
relationships between word forms:

- what word they encountered
- what base word it comes from
- what it means in context
- how it was formed
- why that form is used
- what nearby forms can also be built from the same base word

The engine should optimize for discovery, retrieval, and understanding rather
than pass/fail testing.

The YAML describes the language. The Linguatrain engine creates the learning
experience.

------------------------------------------------------------------------

# Terminology

Use learner-facing terminology consistently.

Use:

- `word`
- `base word`
- `meaning`
- `formation`
- `why`

Avoid in learner-facing UI:

- `lemma`
- `root`
- `morphological analysis`

The YAML uses `base_word`, not `lemma`, because the learner is being asked for
the dictionary/basic form of the word.

Examples:

```text
autolla → auto
kieltä → kieli
minulle → minä
kirjoitetaan → kirjoittaa
```

`root` is not the same concept. A linguistic root or stem may be different from
the base word a learner would look up.

------------------------------------------------------------------------

# Learning Progression

Word Explorer has three learning modes:

```text
Recognize
    ↓
Build
    ↓
Apply
```

These modes are cognitive stages, not merely UI mechanics.

## Recognize

Recognize asks:

> What is this word?

The learner identifies the relationship between an encountered word and its
base word or meaning.

Example:

```text
Word:
autolla

Choose the base word:

- autolla
- auto
- autoon
- autossa
```

This mode may use multiple-choice presentation, but it should not be called
`match-game` in the Word Explorer UI. `recognize` describes the learning goal.

Recognize choices should be pedagogically close. Prefer distractors from the
same word family before falling back to unrelated base words. For example,
`minulla` should be tested against forms such as `minulla`, `minun`, and
`minulle`, not against unrelated words such as `aamupala`, `työ`, or
`lounasravintola`. The learner should have to recognize the base-word
relationship, not merely guess the only plausible option.

## Build

Build asks:

> How do I create the form I need?

The learner starts from a base word and produces a related form.

Use this prompt shape:

```text
Base word:
auto

Change auto to mean:
by car

Grammar:
Adessive — on / at / by means of
```

Do not use:

```text
Change it to mean:
```

The prompt should name the base word explicitly so the transformation is clear.

## Apply

Apply asks:

> Which form belongs here?

The learner chooses or produces the correct word or form in context.

Apply is more advanced than Recognize or Build because it requires the learner
to combine meaning, context, grammar, and usage.

Apply is not limited to Finnish cases. It asks the learner to recognize what the
situation requires:

| Word type | Apply question |
| --- | --- |
| Case forms | Which grammatical relationship fits this sentence? |
| Compounds | Which built word expresses this concept? |
| Derivations | Which derived word expresses this role or meaning? |
| Passive / voice | Which viewpoint or voice fits this sentence? |

Example:

```text
Complete the sentence:

Sitten Alex ajaa _____ kotiin.

Meaning:
by car
```

After a correct answer, Apply feedback should stay focused on context:

```text
✓ Correct.

Grammar:
Illative — into

Why it fits:
The sentence describes movement into the car, so Finnish uses the Illative form autoon.
```

Do not show formation, literal translation, or natural translation by default in
Apply success feedback. Those belong to Recognize and Build unless the learner
asks for details.

Apply choices should be strong enough that the learner has to reason about the
context. Use at least four choices whenever enough plausible distractors exist.
The distractors should be valid related forms or concepts, not arbitrary wrong
answers.

For Apply mode, wrong-answer feedback should explain the learner's chosen form
in context:

```text
✗ Not quite.

Your answer:
autossa

Meaning:
in the car

Why it does not fit:
The sentence describes how Alex travels, not where Alex is located.

Correct form:
autolla

Grammar:
Adessive — on / at / by means of
```

This makes the wrong answer part of the lesson. The learner sees that the form
may be valid Finnish while still being wrong for the current situation.

------------------------------------------------------------------------

# YAML Schema

Word Explorer YAML is descriptive, not procedural. It should not contain
exercise definitions. It should contain the facts the engine needs to generate
recognition, build, apply, review, and guide experiences.

## Frosty 0.9 Skeleton

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

  # Optional: originating Translation pack
  source_pack: ''

# Grammar concepts used by entries in this pack.
# The technical term is shown, but the learner-facing meaning remains primary.
grammar:
  - key: ''
    name: ''
    plain_english: ''
    description: ''

entries:
  - id: ''

    # Context from the source material.
    # Optional for standalone or manually authored exploration.
    source:
      entry_id: ''
      chunk_id: ''
      text: ''
      literal: ''
      target: ''

    # The encountered word and its base form.
    word: ''
    base_word: ''
    type: ''

    # Meaning of this word in the current context.
    target: ''

    # Analysis of the encountered word.
    morphology:
      kind: ''

      # Language-specific properties appear only when applicable.
      case: ''
      ending: ''
      stem: ''
      number: ''
      person: ''
      tense: ''
      mood: ''
      voice: ''
      gender: ''
      parts: []
      suffix: ''

    # Optional assistance shown before revealing an answer.
    hint: ''

    # Learner-facing representation of how the word was formed.
    formation: ''

    # Short explanation of why this form is used here.
    explanation: ''

    # Optional semantic or grammatical role in the sentence.
    role: ''

    # Generated forms available for recognition, matching,
    # comparison, and productive word-building exercises.
    explorations:
      - word: ''
        target: ''

        morphology:
          kind: ''
          case: ''
          ending: ''
          stem: ''

        formation: ''
        explanation: ''

        # source | generated
        origin: generated

        # valid | limited | unsuitable
        status: valid

        # Optional explanation for limited or unsuitable forms.
        usage_note: ''

        # Optional authoring priority for practice selection.
        priority: ''

    # Contextual usage prompts for Apply mode.
    # Applications describe when a word or form fits a situation.
    applications:
      - id: ''

        # Usually contextual_choice.
        type: contextual_choice

        # Flexible metadata used to explain what kind of usage decision
        # the learner is practicing.
        reasoning:
          kind: ''
          relationship: ''

        source:
          text: ''
          literal: ''
          target: ''

        prompt:
          text: ''
          meaning: ''

        base_word: ''

        answer:
          word: ''

        # Minimum four choices for Apply mode whenever enough plausible
        # distractors exist. Choices should be valid related forms or concepts,
        # not arbitrary wrong answers.
        choices:
          - ''
          - ''
          - ''
          - ''
        grammar_refs: []

        explanation:
          why_it_fits: ''

        # Valid related words or forms that do not fit this context.
        distractors:
          - word: ''
            grammar: {}
            meaning: ''
            why_not: ''

    # Optional cross-references.
    vocabulary_ref: ''
    grammar_refs: []
```

------------------------------------------------------------------------

# Grammar Catalog

The top-level `grammar` section works like `persons` in conjugation packs. It
defines the grammar concepts the pack uses, while each entry references those
concepts by key.

Example:

```yaml
grammar:
  - key: adessive
    name: Adessive
    plain_english: 'on / at / by means of'
    description: >
      The Adessive commonly expresses location on or at something.
      It can also express the means of transportation or method used.
```

Entries reference the key:

```yaml
morphology:
  kind: case
  case: adessive
  ending: '-lla'
```

The UI should show both the technical term and the plain-English meaning:

```text
Grammar:
Adessive — on / at / by means of
```

The technical term is important because teachers and textbooks use it. However,
the learner should not be forced to decode the task from the technical term
alone. The plain-English meaning remains the primary learning scaffold.

------------------------------------------------------------------------

# Example Entry: suomen

This example mirrors the current structure used in
`lib/linguatrain/word_explorer/examples/hei_ja_tervetuloa_word_explorer.yaml`.

```yaml
metadata:
  id: 'hei_ja_tervetuloa_word_explorer'
  title: 'Hei ja tervetuloa! — Word Explorer'
  type: word_explorer
  format: canonical
  version: 1
  schema_version: 1

  category: introduction
  chapter: 1

  source_pack: 'hei_ja_tervetuloa_translation'

grammar:
  - key: nominative
    name: Nominative
    plain_english: 'base form'
    description: >
      The Nominative is the basic form of the word.

  - key: genitive
    name: Genitive
    plain_english: 'of / belonging to'
    description: >
      The Genitive commonly marks possession or shows that one word modifies
      another word.

  - key: partitive
    name: Partitive
    plain_english: 'some / part of / unbounded'
    description: >
      The Partitive can mark an incomplete amount, an unbounded quality,
      or the object of certain expressions.

entries:
  - id: 'm001'

    source:
      text: 'Onko täällä suomen kurssi?'
      literal: 'Is here Finland-of course?'
      target: 'Is the Finnish course here?'

    word: 'suomen'
    base_word: 'suomi'
    type: 'noun'

    target: 'Finnish / of Finland'

    morphology:
      kind: 'case'
      case: 'genitive'
      ending: '-n'
      stem: 'suome-'

    hint: >
      This comes from the word for Finland or Finnish.

    formation: 'suomi → suome- + -n → suomen'

    explanation: >
      Suomen is the Genitive form of suomi. Here it modifies kurssi, so
      suomen kurssi means "Finnish course."

    role: 'modifier'

    explorations:
      - word: 'suomi'
        target: 'Finland / Finnish'
        morphology:
          kind: 'case'
          case: 'nominative'
          stem: 'suomi-'
        formation: 'suomi'
        explanation: 'This is the base word.'
        origin: generated
        status: valid

      - word: 'suomen'
        target: 'Finnish / of Finland'
        morphology:
          kind: 'case'
          case: 'genitive'
          ending: '-n'
          stem: 'suome-'
        formation: 'suomi → suome- + -n → suomen'
        explanation: 'The Genitive form modifies kurssi: suomen kurssi.'
        origin: source
        status: valid
        priority: high

      - word: 'suomea'
        target: 'Finnish language / some Finnish'
        morphology:
          kind: 'case'
          case: 'partitive'
          ending: '-a'
          stem: 'suome-'
        formation: 'suomi → suome- + -a → suomea'
        explanation: 'The Partitive form is used when talking about speaking or studying Finnish.'
        origin: generated
        status: valid
        priority: high

      - word: 'suomessa'
        target: 'in Finland'
        morphology:
          kind: 'case'
          case: 'inessive'
          ending: '-ssa'
          stem: 'suome-'
        formation: 'suomi → suome- + -ssa → suomessa'
        explanation: 'The Inessive form means "in Finland."'
        origin: generated
        status: valid
        priority: high

    applications:
      - id: 'suomen_course'
        type: contextual_choice
        reasoning:
          kind: case
          relationship: genitive_modifier
        source:
          text: 'Onko täällä suomen kurssi?'
          literal: 'Is here Finland-of course?'
          target: 'Is the Finnish course here?'

        prompt:
          text: 'Onko täällä _____ kurssi?'
          meaning: 'Is the Finnish course here?'

        base_word: 'suomi'

        answer:
          word: 'suomen'

        choices:
          - 'suomi'
          - 'suomen'
          - 'suomea'
          - 'suomessa'

        grammar_refs:
          - 'genitive'

        explanation:
          why_it_fits: >
            Suomen modifies kurssi. Finnish uses the Genitive form here to
            mean "Finnish course."

        distractors:
          - word: 'suomi'
            grammar:
              case: 'nominative'
            meaning: 'Finland / Finnish'
            why_not: >
              Suomi is the base form. The sentence needs a modifying form
              before kurssi.

          - word: 'suomea'
            grammar:
              case: 'partitive'
            meaning: 'Finnish language / some Finnish'
            why_not: >
              Suomea is commonly used when talking about speaking or studying
              Finnish. It does not modify kurssi to mean "Finnish course."

          - word: 'suomessa'
            grammar:
              case: 'inessive'
            meaning: 'in Finland'
            why_not: >
              Suomessa means "in Finland." The sentence is asking about a
              Finnish course, not a location in Finland.

    vocabulary_ref: 'suomi'

    grammar_refs:
      - 'genitive'
```

------------------------------------------------------------------------

# Translation Display

Translation context should be available, but it should not automatically give
away the answer.

Default display:

```text
Sentence:
Sitten Alex ajaa autolla kotiin.

Type 't' to show the natural language translation.
```

If the learner presses `t`, show:

```text
Natural language translation:
Then Alex drives home.
```

The literal translation should generally be withheld until after the answer:

```text
Literal:
Then Alex drives by-car home.
```

The distinction is intentional:

- `source.target` gives optional sentence context.
- `source.literal` teaches the construction after the learner has attempted the
  prompt.

------------------------------------------------------------------------

# UI Principles

The prompt should be minimal. The answer explanation can be rich.

Before answering, show only what the learner needs:

```text
Base word:
auto

Change auto to mean:
by car

Grammar:
Adessive — on / at / by means of
```

After answering, show the learning report:

```text
Meaning:
by car

Grammar:
Adessive — on / at / by means of

Formation:
auto + -lla → autolla

Literal:
Then Alex drives by-car home.

Natural language translation:
Then Alex drives home.

Why:
The Adessive ending -lla can express the means used to do something.
Here, autolla means "by car."
```

Use a pause between build-mode explorations:

```text
(Enter to continue; q to quit):
```

Word Explorer is not a rapid-fire drill. The learner needs time to absorb the
formation and explanation before moving to the next exploration.

Build and apply explorations should be shuffled at runtime. The YAML keeps the
authored order, but the exercise should not train the learner to expect the same
case or form sequence every time.

Use plain Unicode status marks:

```text
✓ Correct.
✗ Not quite.
```

Avoid emoji-style status marks:

```text
✅
❌
```

The grammar line should receive visual emphasis in the terminal. The learner
should mentally bind the technical term and the plain-English meaning:

```text
Adessive — on / at / by means of
```

------------------------------------------------------------------------

# Feedback and Wrong Answers

Wrong answers should be treated as learning opportunities.

If the learner gives another valid form, explain what that form means before
contrasting it with the requested meaning.

Example:

```text
Your answer:
autolle

Meaning:
to the car

The requested meaning was:
by car

Both are valid Finnish, but they communicate different ideas.
```

For structurally possible but unusual forms, explain the literal meaning first:

```text
This form literally means:
without a kiosk

Finnish grammar allows this form to be constructed.
However, native speakers would rarely use it in everyday speech, so it is not
a useful choice here.
```

The goal is to teach judgment, not merely correctness.

------------------------------------------------------------------------

# Progressive Hints

Build mode should support optional assistance after an incorrect answer.

Do not automatically reveal the formation after the first mistake. The learner
should be allowed to think and retry, but the system should provide a path
forward.

Suggested hint levels:

## Level 1: Grammar Hint

```text
Hint:
The requested form uses the Adessive case.
```

## Level 2: Formation Hint

```text
Formation:
auto + -lla → autolla
```

## Level 3: Show Answer

```text
Answer:
autolla
```

Future scoring should distinguish:

- correct on first attempt
- correct after retry
- correct after hint
- answer revealed
- unresolved

These are different learning states.

------------------------------------------------------------------------

# Scoring

Score demonstrated skills independently.

In recognize mode, base-word recognition and meaning recognition are separate
skills:

```text
Base word:
  Correct 1st
  Correct 2nd
  Failed

Meaning:
  Correct 1st
  Correct 2nd
  Failed
```

In build mode, score form construction:

```text
Build:
  Correct 1st
  Correct 2nd
  Correct after hint
  Answer revealed
  Failed
```

Keep both views:

- words explored
- prompts answered

Example:

```text
Results from autolla_word_explorer
Words explored: 1

Build:
  Correct 1st: 4 (100.0%)
  Correct 2nd: 0 (0.0%)
  Failed:      0 (0.0%)

Overall prompts:
  Total:       4
  Correct 1st: 4 (100.0%)
  Correct 2nd: 0 (0.0%)
  Failed:      0 (0.0%)
```

------------------------------------------------------------------------

# Completion States

Use completion messages that match the Word Explorer philosophy.

## Perfect First Pass

```text
★ Excellent — you mastered this word on the first try.
```

## Completed After Retry

```text
✓ Word explored successfully.
  Keep exploring — retrieval strengthens with practice.
```

## Needs Review

```text
△ Exploration needs review.
  3 of 4 forms explored successfully.
```

Avoid saying "No mistakes" if the learner made mistakes but corrected them on a
later attempt.

Use "needs review" when the learner successfully explores some forms or prompts
but leaves at least one unresolved or revealed. This communicates progress
without pretending the exploration is complete.

------------------------------------------------------------------------

# Word Explorer Guide

The Word Explorer Guide is generated Markdown derived from the Word Explorer
YAML. It is not a separately authored source of truth.

The guide should group entries by useful learning patterns:

- cases
- compounds
- derivations
- passive forms
- irregular stems
- word families

The guide is reflective study material. The YAML remains canonical.

Compounds remain part of Word Explorer, but they are not currently included
in base-word Recognize mode. Recognize asks for a single base-word
relationship such as `minulla -> minä`; compounds ask a different question:
which components form the word, such as `herätys + kello -> herätyskello`.
Until a compound-specific interaction exists, compounds should appear in the
Word Explorer Guide and may be used by future modes, but should be skipped by
`--word-explorer --recognize`.

------------------------------------------------------------------------

# Generative Principle

Translation is canonical. Word Explorer is generative.

The Translation pack records what the learner encountered. Word Explorer may
expand an encountered word into additional useful forms, just as Conjugation
packs expand one encountered verb into a paradigm.

Example:

```text
Encountered:
kioskille

Explore:
kioski
kioskille
kioskiin
kioskissa
kioskista
kioskilla
kioskilta
```

Do not generate every theoretically valid form. Generate the forms that are
pedagogically valuable for the learner at this level.

The expansion should be close to the encountered word and useful for exploring
the word family.

------------------------------------------------------------------------

# Implementation Notes

Current expected command shape:

```bash
linguatrain file.yaml --word-explorer --recognize
linguatrain file.yaml --word-explorer --build
linguatrain file.yaml --word-explorer --apply
```

`--match-game` should not be the long-term Word Explorer mode name. Matching can
be a mechanic inside `--recognize`, but the mode should describe the learning
goal.

Current known implementation refinements:

- Keep prompt display compact.
- Pause between build-mode explorations.
- Add progressive hints.
- Improve wrong-answer explanations by identifying valid but wrong forms.
- Track hint-assisted answers separately from normal retries.
- Keep `base word` terminology consistent throughout learner-facing UI.
