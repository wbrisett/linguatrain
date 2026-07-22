# Linguatrain LLM Authoring Specification

## A language-agnostic guide for generating Translation, Vocabulary, Conjugation,
## Word Explorer, and Word Explorer Guide packs

---

**Revision note (this version):** Added clarifications surfaced by
cross-comparing three independent LLM authoring attempts and three
independent evaluations of the same pack set. Changes, each marked "added
clarification" or "added" inline at its location: a concrete heuristic for
closed-class function-word candidate selection (§5.3); a worked verb+noun
idiom example for the compositionality test (§5.5); a lemma-identity
convention for reflexive/pronominal-only verbs (§5.4); an explicit ruling
that whole-category omission of polarity is not a permitted scope choice,
while other categories may still be legitimately scoped down (§6.5); a
previously-missing worked schema for individual `explorations[]` items
(§7.6); an explanation of the previously-unexplained `distractors[].grammar`
field (§7.7); a concrete before/after example for the sequence-indentation
rule, since common YAML library defaults do not satisfy it as written
(§3.2); and a mandatory mechanical re-scan step for the YAML reserved-word
quoting bug, added to the conformance pass (§10). No prior rule was
loosened or reversed — every change either fills a previously-silent gap or
makes an existing rule's boundary explicit where two careful readers had
been reaching different conclusions from the same text.

**Further clarification in this revision:** Added testable chunk-boundary
criteria (§4.3); a minimum pedagogical vocabulary floor and explicit
`answer` shape (§§5.2–5.3); Unicode-preserving identity and lexicalized-plural
rules (§§5.4, 5.8); explicit typing of conjugatable multi-word expressions
(§§5.9, 6.3, 6.7); exact, atomic Conjugation-form and accepted-variant rules
(§6.5.1); contiguous-source and layered-morphology rules, including agreement
and prefixes (§§7.4–7.5); consistent grammar-key reuse (§7.9); standalone
Guide wording and complete Guide category mapping (§7.11); and a reproducible
evaluation/scoring protocol (§11). These additions preserve the decisions
above while closing gaps that previously required an evaluator to invent a
rubric.

**Additional clarification (this revision):** Added §6.6.1, resolving
whether subject pronouns and clitics belong inside `forms` values. A
proposed patch had suggested banning subject pronouns from paradigm cells
outright; that blanket rule was rejected as linguistically incorrect for
non-pro-drop languages (it would make French answers like `rencontre`
stand in for a complete sentence, which they are not) and replaced with a
language-appropriate test: pro-drop languages omit the subject (unchanged
from the existing Finnish worked example), non-pro-drop languages include
it as part of each accepted form, and ordinary object clitics remain
out of scope for paradigm cells regardless of language, while an
inherently reflexive lemma's own reflexive clitic is required, not
optional. See §6.6.1 for the full rule and worked example.

---

## 0. What this document is

This document is written **for an LLM**, not for a human reader. It is the single
reference an LLM should consult when asked to generate Linguatrain learning packs
from a new source text, in any language. This includes the Translation,
Vocabulary, and Conjugation packs, and their generative companions, the Word
Explorer pack and the Word Explorer Guide (§7).

It supersedes ambiguities left open by the original Linguatrain Translation
Authoring Handbook. That handbook used Finnish as its only worked example, and
several of its rules were prose guidelines ("whenever practical," "should")
rather than closure rules. When multiple independent LLM authoring attempts were
run against the same source text, those open guidelines produced *silent
divergence*: internally consistent packs that were nonetheless incompatible with
one another the moment anyone tried to merge or cross-reference them. This
document closes those gaps and states, wherever a choice must be made, which
choice governs.

**This document must never be treated as language-specific.** Any example below
that uses a particular language (Finnish, Spanish, Hindi, Mandarin, etc.) is
illustrative only. The rule being illustrated always applies to every language
Linguatrain supports, including languages not yet seen in any example.

**REQUIREMENT:**
When the specification and your linguistic knowledge disagree, the specification is authoritative. Do not substitute your own judgment for an explicit requirement.

When uncertain, prefer omission over invention.

**Never** invent vocabulary, grammar, conjugations, hints, or linguistic
analysis merely to make a pack appear more complete.

A missing educational note is preferable to an incorrect one.

---

## 1. Core philosophy (read this before generating anything)

Every translation exercise moves through three stages:

```
Source-language text
        ↓
Literal target-language rendering
        ↓
Natural target-language rendering
```

The **literal** rendering preserves the structure of the source language, even
when it reads awkwardly in the target language. The **natural** rendering
expresses the same idea the way a fluent target-language speaker actually
would. Both are pedagogically necessary and serve different purposes — do not
collapse them into one, and do not let the literal rendering "improve" itself
into natural phrasing.

The learning progression across packs is:

```
Vocabulary → Translation → Morphology (Conjugation, Word Explorer, etc.) → Conversation
```

Model the learner working through the text like a classroom discussion, not a
database being indexed. A generated pack should feel like scaffolding a student
through decoding, not a mechanical transformation of the source text.


---

## 2. Pack relationship and authority

**The Translation pack is always canonical and is always created first.**
Vocabulary, Conjugation, and any other companion pack (Morphology/Word
Explorer, etc.) are *derived from* the Translation pack and must never
introduce a word, form, sentence, or grammatical claim that isn't already
present in — or directly implied by — the Translation pack's `source` text.

Do not combine the packs into a single document.
Deliver each pack in its own dedicated code block, artifact workspace, or file.

```
Translation Pack   (canonical, authored first, always from the source text)
        │
        ├── Vocabulary Pack       (derived from vocabulary_refs in the Translation pack)
        │       │
        │       └── Conjugation Pack   (derived from verb lemmas in the Vocabulary pack)
        │
        ├── Word Explorer Pack    (derived from entries/chunks in the Translation pack,
        │       │                  cross-referencing the Vocabulary pack where it exists)
        │       │
        │       └── Word Explorer Guide (word-explorer.md — generated FROM the
        │                                Word Explorer pack, never authored independently)
        │
        └── other future companion packs (derived the same way)
```

Word Explorer sits alongside Conjugation as a companion pack, not beneath it:
both derive from the Translation pack, and both may cross-reference the
Vocabulary pack, but neither derives from the other. The Word Explorer Guide
is the one exception to "every pack derives from the Translation pack" — it
derives from the Word Explorer pack instead, and must never introduce a fact
that isn't already present in that pack's YAML. See §7 for the full authoring
rules for both.

Order of operations for an LLM generating a full set of packs from a source
text:

1. Read the source text in full. Do not summarize or alter it.
2. Author the **Translation pack** first: metadata, entries, chunks, literal
   and natural translations, phonetic guidance (if applicable), hints,
   `vocabulary_refs`, and `grammar.refs`.
3. Collect every unique value referenced in `vocabulary_refs` across all
   entries. Author the **Vocabulary pack** from that exact list — no more, no
   fewer.
4. Collect every verb lemma present in the Vocabulary pack. Author the
   **Conjugation pack** from that exact list — no more, no fewer. Carry
   forward each entry's stem-alternation or inflectional-class note from
   its Vocabulary counterpart per §6.2.2.
5. If a **Word Explorer pack** is requested, author it from the Translation
   pack's entries and chunks per §7, cross-referencing the Vocabulary pack's
   ids via `vocabulary_ref` wherever one exists.
6. If a **Word Explorer Guide** is requested, generate it from the Word
   Explorer pack per §7.11 — never author it directly from the source text
   or Translation pack.
7. If a discrepancy is later found between a companion pack and the
   Translation pack, **the Translation pack wins**. Fix the companion pack.
   If the discrepancy is between the Word Explorer Guide and the Word
   Explorer pack, **the Word Explorer pack wins**.

Steps 1–2 (and the Vocabulary pack's dependency on step 3) may be skipped
entirely via the alternate entry points in §2.1 (raw word list → Vocabulary
pack) and §2.2 (raw verb list → Conjugation pack). Outside of those two
named exceptions, never author a Vocabulary or Conjugation pack as a
freestanding exercise disconnected from a Translation pack's
`vocabulary_refs`.

Companion packs may refine, organize, or expand educational metadata.

They may **never** introduce new lexical content that is absent from the
Translation pack.

---

### 2.1 Alternate entry point: Vocabulary-only pack from a raw word list (resolved)

Everything above in §2 describes the default pipeline, where a Translation
pack is authored first from a full source text and companion packs derive
from it. That pipeline assumes a source text with sentences.

**A second, equally valid entry point exists:** an LLM may author a
Vocabulary pack directly from a **raw word list** — an unstructured,
possibly duplicated, possibly inconsistently-cased list of tokens extracted
from a lesson, with no accompanying sentences, chunks, or translations —
when no Translation pack exists and none is being requested.

In this mode:

- The raw word list is the terminal source of lexical authority, in place
  of `vocabulary_refs`. Every entry in the resulting Vocabulary pack must
  trace back to a token literally present in the list, after the
  preprocessing rules in §5.0. Nothing may be added that isn't there.
- `metadata.source_pack` (§5.1) has no valid value, since there is no
  Translation pack. Omit it and add `source_list:` instead, naming the raw
  file or lesson identifier the list came from.
- No Conjugation pack should be generated from this mode's output unless
  separately requested — §6.3's normal derivation still applies once a
  Vocabulary pack exists, but nothing here implies a Conjugation pack was
  asked for.

This mode does **not** relax any other rule in this specification —
lemma-identity (§5.4), candidate selection (§5.3), the compositionality
test (§5.5), or anything else still applies in full. It only removes the
requirement that a Translation pack precede the Vocabulary pack.

---

### 2.2 Alternate entry point: Conjugation pack directly from a raw verb list (resolved)

A third entry point exists, parallel to §2.1: an LLM may author a
**Conjugation pack directly from a raw verb list** — a plain list of verb
tokens (ideally, but not necessarily, already in citation/infinitive form),
with no accompanying Translation pack and no accompanying Vocabulary pack —
when neither of those packs exists and neither is being requested.

In this mode:

- The raw verb list is the terminal source of lexical authority for the
  Conjugation pack, standing in for "verbs already present in the
  companion Vocabulary pack" (§6.3). Every entry's `lemma` must trace back
  to a token literally present in the list, after the applicable
  preprocessing rules in §5.0 (case normalization, exact-duplicate
  removal, exclusion of non-lexical tokens, collapsing same-lemma surface
  forms, disambiguating confusable near-forms, and preserving list order).
  The §5.0 steps that exist specifically for non-verb material (e.g.
  §5.0.f metalinguistic-term flagging) still apply if such tokens turn up,
  but are unlikely to be needed for a list that is already verb-only.
- If a list token is not already a citation/infinitive form (e.g. a
  conjugated surface form), reduce it to its dictionary lemma before
  authoring the entry — the lemma-identity rule (§5.4) is not relaxed
  merely because there is no Vocabulary pack to anchor it.
- Multi-word verb expressions are evaluated the same way as they would be
  for a Vocabulary pack: apply the compositionality test (§5.5) to any
  list token that already presents multiple words together (a single raw-
  list line grouping several words is a strong signal, not the weak
  adjacency signal described in §5.0.2, which concerns *separate* list
  entries). Keep a genuine fixed verb expression as **one** Conjugation
  entry per §6.7 — do not split it into its component words.
- `metadata.source_pack` (§6.1) has no valid value, since there is no
  Vocabulary pack. Omit it and add `source_list:` instead, naming the raw
  file or lesson identifier the list came from — the same convention used
  in §2.1 for a Vocabulary pack authored this way.
- All other Conjugation pack rules still apply in full: candidate
  selection still excludes defective/impersonal verbs (§6.3), multi-word
  lemma consistency (§6.4), the completeness closure rule (§6.5), and
  language-specific structure (§6.6) are all unaffected by this entry
  point.
- This mode does not itself produce a Vocabulary pack, and does not
  require one to exist. A Vocabulary pack may still be authored from the
  same raw list separately (§2.1); if both are produced, their lemmas
  should agree, but generating one does not obligate generating the
  other.

---

## 3. Global YAML rules (apply to every pack type)

All YAML produced under this specification must be valid YAML 1.1 and parse
without modification.

### 3.1 Quoting rule (resolved)

Quote a value in single quotes **only** when it could otherwise be misparsed
by a YAML 1.1 parser as a non-string scalar. This includes:

- purely numeric-looking tokens (e.g. `001`, `2024`)
- YAML boolean/null keywords regardless of case (`yes`, `no`, `true`, `false`,
  `on`, `off`, `null`, `~`)
- strings containing a colon, a leading `-`, embedded quotation marks, or
  other YAML-significant characters
- strings with meaningful leading/trailing whitespace

Plain alphanumeric identifiers that cannot be misparsed (e.g. `e001`,
`herata`, `hablar`) **do not require quoting**, but may be quoted for
visual consistency within a single pack. Whichever convention is chosen
(quote everything vs. quote only when required), **apply it consistently
across every id in the pack** — do not mix conventions within one file.

### 3.2 Indentation and structure

- Sequence items (`-`) are indented exactly two spaces beneath their parent
  key. This is a common point of drift because many YAML libraries'
  *default* dump behavior produces the sequence item at the **same**
  indentation as its parent key, not two spaces beneath it — that default
  output does not satisfy this rule and must not be used as-is:

  ```yaml
  # Wrong — sequence item at the same indentation as its parent key
  # (this is what many YAML libraries produce by default)
  entries:
  - id: '001'

  # Correct — sequence item indented two spaces beneath its parent key
  entries:
    - id: '001'
  ```

  If generating YAML programmatically rather than writing it directly,
  check the library's actual output against this example rather than
  assuming a default configuration already complies.
- Field order within an object should follow the canonical order shown in
  this document's schema blocks. Do not reorder fields without reason.
- Equivalent content should serialize identically wherever it recurs
  (same quoting style, same indentation, same field order). Avoid
  incidental variation — it creates unnecessary diffs and makes packs harder
  to compare.

### 3.3 Multi-line or punctuated text

Any free-text value containing a colon, an embedded quote, or other
YAML-significant character must be quoted or written as a block scalar
(`>` or `|`).

---

## 4. Translation pack

### 4.1 Required top-level metadata

```yaml
metadata:
  id:              # unique, stable, quoted if needed per §3.1
  title:           # human-readable
  type: translation
  format:          # 'narrative' or 'conversation' — see §4.1.1
  version:         # increment on content change
  schema_version:  # increment only when this schema itself changes
```

#### 4.1.1 `format`

- `narrative` — continuous prose: stories, articles, descriptions,
  instructions, signage, or any text that is not primarily dialogue.
- `conversation` — content structured as spoken dialogue between two or more
  speakers.

A `conversation`-format pack may still contain individual `narrative`-type
entries (e.g. stage directions); `format` describes the whole pack, an
entry's `type` describes that one entry.

#### 4.1.2 Curated and full-coverage companion translation packs

For long source texts such as subtitle files, it is valid to produce two
translation packs with different learning purposes:

```text
*_translation.yaml       # curated study/gist translation
*_full_translation.yaml  # complete source coverage
```

The curated `*_translation.yaml` remains the canonical study pack for
Vocabulary, Conjugation, Word Explorer, and other derived companion packs. It
may intentionally combine, omit, or foreground lines to teach the most useful
structure and vocabulary.

The optional `*_full_translation.yaml` is a coverage companion. Its purpose is
to preserve every relevant source line in order, with a natural target-language
reading translation, so a learner can look up any subtitle line that was not
selected for the curated study pack. A full-coverage pack must:

- Use the same source text as the curated pack.
- Omit `source_language` and `target_language` from `metadata`.
- Preserve source order.
- State any intentional exclusions, such as a shared intro song that has its
  own reusable translation pack or a final credits slate.
- Avoid introducing new Vocabulary, Conjugation, or Word Explorer derivations
  unless the user explicitly requests a second companion-pack set from the full
  file.

### 4.2 Entry schema

```yaml
entries:
  - id:               # required, unique within the pack
    type:             # optional: 'narrative' or 'dialogue'
    speaker:          # optional, only for dialogue
    source:           # required — exact source-language text
    phonetic:         # optional — see §4.5
    literal:          # required — structural rendering, see §4.4
    target:           # required — natural rendering
    accepted:         # optional — alternate correct answers, see §4.6
    chunks:           # required — see §4.3
    vocabulary_refs:  # optional — lemma ids, see §4.7
    grammar:
      refs:           # optional — see §4.8
```

`source` must exactly match the source material: same spelling, same
punctuation, same word order, same symbolic notation (numerals, currency
signs, etc. are never rewritten as words — see §4.5.1).

### 4.3 Chunks

Every entry's `chunks` list mirrors the entry:

```yaml
chunks:
  - id:          # required, unique within the entry
    source:      # required — a contiguous slice of the entry's source
    phonetic:    # optional — required if the parent entry has phonetic
    literal:
    target:
    accepted:    # optional
    hint:        # optional
```

**Chunking guiding principle:** chunk by **meaning**, not by word count or
grammatical category. A chunk should be the largest reusable unit of meaning
a learner will recognize again — a noun phrase, a verb phrase, a fixed
expression, an idiom, or a complete grammatical unit. The learner should be
able to look at a chunk and think "I've seen this before," not "now I need to
reassemble these words."

Rules:

- Chunks must cover the entire source sentence and preserve source order.
  Never reorder chunks to make the target reading more natural.
- Do not split a fixed expression, idiom, or greeting across chunks.
- Do not merge unrelated ideas into one chunk simply to reduce chunk count.

**Operational boundary test (added clarification):** one chunk should express
one independently reusable speech act, proposition, fixed expression, or
tightly bound phrase. Split at a boundary when either side could be reused
without the other and each side still carries a recognizable idea. In
particular, separate two questions, two commands, a speech-reporting clause and
its quoted speech, or two coordinated propositions unless the whole sequence is
a lexicalized fixed expression. A whole sentence may be one chunk only when it
is genuinely atomic under this test; sentence length alone never decides it.
Repeated wording stays repeated: do not collapse two source occurrences into
one chunk, because chunks must still cover the source in order.

**How to apply this to any writing system, not just whitespace-segmented
ones:** the guiding question is always "what is the smallest span of source
text that carries one recognizable idea a learner can reuse?" — this
question is meaningful whether or not the source language uses spaces
between words. For a language that does not mark word boundaries with
whitespace (e.g. one written in a script segmented by syllables or
characters rather than spaces), the LLM must still identify meaningful units
using morpheme boundaries, known lexical items, and idiomatic groupings —
never by falling back to fixed-length character spans, and never by
inventing word boundaries that native speakers would not recognize. If the
LLM is not confident it can identify a defensible chunk boundary for a given
span, it should chunk more conservatively (a larger, safely whole unit)
rather than guess at a boundary that may not exist.

### 4.4 Literal vs. natural translation

The `literal` field's purpose is to teach the *source language's* structure,
not to produce elegant target-language prose. It should preserve source word
order and expose grammatical structure even when it reads oddly. The
`target` field is the one preferred, natural, fluent rendering; alternate
correct renderings belong in `accepted`, never crammed into `target`.

### 4.5 Phonetic / pronunciation guidance

`phonetic` is optional, beginner-facing pronunciation guidance for `source`
text — not IPA, not a full transcription, not a substitute for audio.
Include it at the entry level and, whenever the entry has it, at every
chunk level too (chunk phonetics cover only that chunk's `source`).

**Choosing what to mark (language-general principle):** different languages
put pronunciation difficulty in different places. Before choosing a
phonetic convention for a language, identify what actually causes learners
of *that specific language* to mispronounce it — this could be lexical
stress, vowel or consonant length, tone, nasalization, aspiration contrasts,
retroflex vs. dental place of articulation, consonant clusters, or something
else entirely. Mark **that** feature, consistently, throughout the pack.
Do not default to a stress-marking convention (e.g. capitalizing a stressed
syllable) just because it was useful for a previous language — that
convention is meaningless for a language whose difficulty isn't
stress-related, and applying it anyway produces guidance that looks
authoritative but teaches nothing real.

Concretely, before authoring phonetic guidance for a new language, decide
and state (to yourself, and consistently apply) which 1–3 phonological
features the convention for this pack will track. Examples of the kind of
decision to make — these are illustrations of the *process*, not a
checklist to apply mechanically to every language:

- A language with strong predictable word-stress and vowel/consonant length
  distinctions → mark stress and length.
- A tonal language → mark tone (e.g. numbered or diacritic tone marks), not
  stress.
- A language with aspiration or place-of-articulation contrasts that are
  invisible in ordinary transliteration → mark those contrasts explicitly
  rather than defaulting to plain transliteration that erases them.

If pronunciation cannot be represented clearly and reliably for a given
span, omit `phonetic` for that span rather than inventing unreliable
guidance.

#### 4.5.1 Symbolic values (numbers, dates, currency, etc.)

- `source` is authoritative and preserves the symbol exactly as written
  (e.g. a numeral stays a numeral). Never rewrite a symbol into its spelled
  lexical form in `source`.
- `phonetic`, if present, expands the symbol into what a native speaker
  would actually say aloud.
- A symbolic value is **never** lexical vocabulary. Do not create a
  vocabulary entry for the spoken-word form of a symbol that does not
  literally appear in `source` (e.g. a numeral in the source text does not
  generate a vocabulary entry for the number word).
- If the spoken form differs meaningfully from the written form, explain
  that relationship in a chunk `hint`, not by inventing a vocabulary entry.
- A bare grammatical affix or case-ending notation (e.g. a suffix
  alternation written out to illustrate a case ending, such as a pair of
  case-marker suffixes shown together) is never a vocabulary candidate — it
  describes morphology, not a lexical item, and belongs in a Conjugation or
  Morphology pack's structural notes if anywhere.


### 4.6 Accepted answers

`accepted` lists alternate correct renderings of `target` — synonyms,
articles, contractions, equally natural word order, regional variants. Every
accepted answer must be something a fluent speaker would actually say.
`accepted` is not a patch for a poorly chosen `target` or poor chunking; if a
chunk needs many accepted answers, reconsider the `target` or the chunk
boundary itself.

### 4.7 `vocabulary_refs`

References dictionary lemmas (never inflected surface forms) introduced or
reinforced by the entry. Only reference vocabulary that is pedagogically
important — do not reference every word in the sentence mechanically.

### 4.8 `grammar.refs`

Optional free-text labels pointing at reusable grammar topics (e.g.
`genitive_case`, `subject_pronoun_omission`).

**Status of grammar refs (resolved):** unless the LLM has been given an
actual grammar-topics pack/schema to resolve references against, `grammar.refs`
values are **free-text labels for future linking only** and are not currently
validated against any authority. Keep them short, consistent, and reusable
across entries in the same pack family so that a future grammar-topics pack
could adopt them without renaming, but do not treat "every grammar reference
resolves to a real topic" as a pass/fail condition unless such a pack
actually exists and was provided as an input.

---

## 5. Vocabulary pack

### 5.0 Preprocessing a raw word list before authoring entries (resolved)

A raw word list, unlike a Translation pack's `vocabulary_refs`, has not
already been curated. Before authoring any entries, the LLM must run the
list through this preprocessing sequence, in order:

**a. Normalize case.**
Lowercase every token unless it is a genuine proper noun, place name, or
other form that is lexically capitalized regardless of position.
Sentence-initial capitalization inherited from the original source text is
not linguistically meaningful and must be discarded (e.g. a discourse
particle or imperative that happened to start a sentence in the source
should not retain capitalization it has no other reason to carry).

**b. Remove exact duplicate tokens.**
Identical repeated tokens collapse to a single candidate before any further
processing.

**c. Exclude non-lexical tokens.**
Discard any token that is not itself a word: bare grammatical affix or
case-ending notation (e.g. a suffix pair written to illustrate a case
ending), stray punctuation, or formatting artifacts. See the amendment to
§4.5.1 below — this is the same principle already applied to symbolic
values, extended to bare morphology notation.

**d. Collapse same-lemma tokens.**
When multiple surviving tokens are surface forms of the same dictionary
lemma — an inflected form alongside its own base form, or several inflected
forms of the same word — merge them into **one** vocabulary entry. Prefer
the most contextually informative inflected surface form encountered for
`prompt` (an inflected form over a bare citation form, since that is closer
to what the learner actually saw). Record the base lemma and any other
encountered forms in `forms` per §5.4/§5.6. This is a raw-list-specific
elaboration of the existing lemma-identity rule in §5.4 — it does not change
that rule, it just tells the LLM how to satisfy it when starting from an
unsorted list instead of a single sentence.

**e. Disambiguate confusable near-forms using target-language knowledge.**
Because there is no sentence context to disambiguate automatically, two
tokens that look similar are not automatically the same lemma — surface
similarity is not evidence of shared identity (e.g. an inflected noun form
and an unrelated verb infinitive can share a stem by coincidence). The LLM
should apply standard dictionary knowledge of the target language to assign
each surviving token to its correct lemma. If a token's lemma is genuinely
ambiguous without more context, flag it for the human author rather than
silently guessing — this is the raw-list equivalent of §0's "prefer
omission over invention."

**f. Flag metalinguistic terms.**
A token that is itself a grammar term describing the lesson's grammar
(e.g. a word meaning "past tense" or "case") rather than being lesson
content is a judgment call, not a mechanical one. Default: exclude such
terms from the Vocabulary pack, since they describe the lesson rather than
belonging to it, and flag each excluded term for the human author to
confirm. Do not silently include or silently exclude without flagging —
this default can be overridden per lesson, but the override should be a
visible decision, not an accident.

**g. Preserve list order.**
Unless told otherwise, treat the list's line order as encounter order in
the original lesson and preserve that order for the resulting entries. Do
not alphabetize or otherwise reorder.

### 5.0.1 Supplying `answer` without an anchoring Translation pack (resolved)

In the default pipeline, `answer` values trace back to a Translation pack's
established `target` translation. In vocabulary-only mode there is no such
anchor. The LLM should supply the standard dictionary meaning(s) for each
lemma using its own linguistic knowledge of the target language.

This is **not** a violation of §0's "prefer omission over invention." That
principle guards against fabricating vocabulary or grammar that isn't
actually present in a source. Supplying the accepted dictionary gloss for a
real word that genuinely appears in the list is expected and required in
this mode — omission would produce an unusable pack, not a more careful
one.

**Gloss conservatism.** Without an anchoring sentence, there is nothing to
verify a secondary or unusual sense of a word against. Prefer the single
most common, central meaning of the lemma. Add a secondary sense to
`answer` only when it is a well-established alternate meaning of the same
word in ordinary usage — not merely a related or nearby concept in
English. A gloss that sounds plausible next to the primary meaning but
isn't independently a standard sense of the lemma should be left out
(e.g. do not pad a specialty/peculiarity entry with "curiosity" on the
theory that the concepts feel adjacent — that is a different word in the
target language).


### 5.0.2 Multi-word candidates from a raw list (resolved)

Adjacency in a raw list is a weak, unreliable signal. List order may
reflect appearance order in a lesson, but adjacent tokens in a
deduplicated, reordered candidate list are not guaranteed to have formed a
phrase together in the original source sentence.

Default to keeping tokens as **separate** entries (the normal §5.5 default)
unless the LLM has independent lexical knowledge that the sequence is a
genuine fixed idiom or grammatical unit in the target language. Do not
bundle two tokens into one multi-word entry merely because they appear
next to each other in the list.


### 5.0.3 One token, one entry — No Seeding (resolved)

A single token from the raw list may be **absorbed into at most one**
vocabulary entry. Once a token has been used — either as an entry's own
`prompt`, or as a component inside a multi-word phrase entry per §5.0.2 —
it is spent. It may not *also* seed a second, independent entry.

This matters most for a token that is a component of a bundled phrase
(e.g. a word that appears inside a fixed-expression entry) but is also a
common standalone word in its own right. Do not additionally generate a
freestanding entry for that word just because it is independently useful
vocabulary — the raw list is assumed to come from a curated source
(a textbook chapter or a teacher's list), so if the list only contains the
token once, treat that as a signal that one entry was intended, not two.

If the word is genuinely important enough to also warrant a standalone
entry, that is an editorial judgment for the human author to make
separately — not something the LLM should decide unilaterally by
duplicating a list token across two entries. When in doubt, keep the token
inside the phrase entry only, and mention the standalone word's core
meaning in that entry's `notes` if it aids recognition.

---

### 5.1 Metadata

```yaml
metadata:
  id:
  title:
  type: vocabulary
  format: canonical
  version:
  schema_version:
  source_pack:      # id of the Translation pack this was derived from
```

### 5.2 Entry schema

```yaml
entries:
  - id:         # required — canonical dictionary lemma, stable identity
    prompt:     # required — learner-facing form, normally the surface form encountered
    answer:     # required — YAML sequence with one or more target-language meanings
      - ...
    type:       # optional — noun, verb, adjective, phrase, etc.
    literal:    # optional
    phonetic:   # optional
    forms:      # optional — see §5.6
    heard_as:   # optional — recognition variants for speech input
    notes:      # optional — see §5.7
```

### 5.3 Candidate selection

Generate vocabulary entries **only** from lexical items that contribute to
comprehension of the source text: ordinary words, inflected words,
compounds, lexicalized fixed expressions, and grammatically meaningful items
(interjections, discourse markers, fixed expressions, conjunctions).

**Closed-class function words (added clarification):** subject pronouns,
basic articles, and other closed-class function words are not automatically
excluded, but default to *not* generating a standalone entry for one unless
it does at least one of the following: shows an irregular or notable surface
form (a contraction like `au`/`du`, a stem alternation, an exception to the
language's own pattern); carries a genuine false-friend or register risk; or
is needed as the anchor for a Word Explorer or Conjugation entry that
otherwise has nothing to attach to. A closed-class word that behaves exactly
as a learner would expect from the basic paradigm, with nothing notable to
say about it, does not need its own entry merely because it appears in the
source text. This keeps candidate selection anchored to instructional value
rather than mechanical coverage of every token — the same principle already
stated above, made concrete enough to apply consistently across authoring
attempts.

**Minimum pedagogical floor (added clarification):** candidate selection is
curated, but it must not become arbitrary under-selection. Include at least:

- every distinct lexical verb or fixed verbal predicate needed to understand a
  source proposition;
- every non-compositional expression needed to explain a natural translation;
- every recurring question word, greeting, or discourse item that anchors the
  same learnable formula at least twice in the source; and
- any lexical item required as the target of a retained cross-pack reference.

A single-use, transparent function word or content word may still be omitted
under the rules above. Record such exclusions during the §10 conformance pass
so “curated” does not become “silently discarded.”

**Never** generate an entry from a purely symbolic token: digits,
timestamps, dates, percentages, currency symbols, measurements,
punctuation, or formatting symbols (see §4.5.1).

**Never** auto-generate an entry for a named entity (person, company,
organization, product, event) unless it provides real instructional value
beyond simple identification — e.g. a place name that appears in a notable
inflected or declined form is a legitimate candidate; a personal name used
only as a subject is not.

**Never** generate an entry from a token that is only a case-ending or
  affix notation rather than a word (see the amended §4.5.1).

**Transparent cognates and identical glosses (resolved):** Do not include a
Vocabulary entry whose primary target-language answer is identical or
near-identical to the source-language `prompt` unless that entry has a
specific instructional reason in this source text. Lexical validity alone is
not enough; a quiz item like `public → public` teaches little unless the pack
also teaches something about pronunciation, agreement, inflection, register,
false-friend risk, idiomatic use, or a required cross-pack relationship.

Valid reasons to keep a transparent cognate or same-looking answer include:

- the word is a false friend, partial cognate, or register trap;
- the source form shows grammar the learner needs to notice, such as gender
  agreement, plural marking, case/declension, conjugation, derivation, or
  elision;
- pronunciation guidance is included because the same-looking form is
  predictably mispronounced by learners;
- the entry is needed as the `vocabulary_ref` for a Word Explorer entry that
  analyzes a real source form;
- the source text explicitly uses the item as part of a meaningful closed set
  being taught, such as warning colors or classification labels.

If such an entry is kept, add a concise `notes` item explaining the
instructional value. Otherwise, omit it from `vocabulary_refs` and from the
Vocabulary pack, even though the word is a real lexical item in the source
text.

Cultural references remain translation/context material and do **not** become vocabulary.

### 5.4 Lemma identity vs. surface form

- `id` is the stable dictionary lemma. It never changes based on which
  inflected form the learner encountered.
- `prompt` is normally the exact surface form the learner encountered in the
  source text, so they recognize it immediately from the reading. Record the
  relationship between the two in `forms`.
  
**Requirement:**
Vocabulary IDs **MUST** be lemmas.

**Rationale:**
Using lemmas guarantees stable cross-pack references.

```yaml
id: 'lemma_form'
prompt: encountered_surface_form
answer: meaning
forms:
  lemma: lemma_form
  <case_or_tense_label>: encountered_surface_form
```

**Reflexive/pronominal-only verbs (added clarification):** many languages
(French, Spanish, Italian, German, Russian, and others) have verbs that
exist only in reflexive/pronominal form — the citation form itself carries
the reflexive marker (French `s'inquiéter`, Spanish `arrepentirse`, German
`sich freuen`). For these, the stable lemma **includes** the reflexive
marker — normalize it into the `id` the same way any other multi-word lemma
is normalized (§5.8), e.g. `s_inquiéter`, not `inquiéter`. Do not drop the
reflexive marker merely because the conjugated forms show it as a separate,
subject-agreeing pronoun (`je m'inquiète`, `tu t'inquiètes`) — the paradigm
varying the pronoun is exactly like any other verb varying its personal
ending; it doesn't change what the dictionary citation form is. A verb that
exists in *both* a plain and a reflexive form (e.g. a transitive verb that
also has a distinct reflexive sense) is a different case and should be
evaluated on whether the two senses are the same lemma or two lemmas in the
target language's own dictionary tradition — but a verb with no non-reflexive
form at all always keeps the marker in its `id`.

**Unicode and lexicalized-number identity (added clarification):** preserve
the lemma's letters and diacritics in Unicode NFC. ID normalization changes
separators, not spelling: French `s'inquiéter` becomes `s_inquiéter`, never
`s_inquieter`. Use a plural as the stable lemma only when the expression is
lexicalized or conventionally dictionary-listed in the plural for the intended
sense; otherwise use the singular dictionary lemma and record the encountered
plural in `prompt`/`forms`.

### 5.5 Compositionality test for multi-word candidates (resolved)

When a multi-word sequence could plausibly be one entry or several separate
entries, apply this test:

> Bundle a multi-word sequence into a **single** vocabulary entry only when
> its meaning is non-compositional (not predictable from the sum of its
> parts) **or** it functions as a fixed grammatical unit that always appears
> together. Otherwise, keep the components as **separate** entries and note
> the collocation in one entry's `notes` field.

This test applies equally to fixed idioms, greetings, and any collocational
phrase the LLM is deciding whether to split.

**Worked example — a verb + noun idiom of state (not just verb + verb):**
A pattern that recurs across many languages is a literal-transitive-looking
verb combined with a noun to express a state or feeling — French `avoir
peur` ("to have fear" → "to be afraid"), `avoir faim` ("to be hungry"), or
the equivalent pattern in other languages. This is harder to judge than a
verb + verb idiom like `laisser tomber` because the noun half (`peur`,
`faim`) still looks and behaves like an ordinary noun elsewhere in the
source text. Apply the same test: if `avoir peur` means something other
than the sum of "to have" + "fear" would predict in the target language
(here, "to be afraid" rather than a literal possession of an emotion), and
the pairing is fixed rather than freely substitutable, treat it as **one**
entry (`avoir_peur`) — not as `avoir` and `peur` authored separately with a
note on one of them describing the other. Do not split the pair and then
separately document the idiom in prose; the compositionality test's outcome
should be reflected directly in how many entries exist, not patched over
with a note after the fact.

### 5.6 `forms`

Capture only educationally valuable forms that appear in the lesson,
illustrate an important pattern, or are likely to recur — not exhaustive
paradigms. Exhaustive paradigms belong in the Conjugation pack (verbs) or are
simply omitted (non-verbs). The presence of a `forms` section never changes
`id`, which always remains the canonical lemma.

### 5.7 `notes`

One concise, useful teaching point per note — idiomatic usage, a compound
breakdown, a common learner confusion, an important case usage. Not a
grammar lesson.

**Self-check against hint duplication (resolved):** before finalizing any
Translation-pack chunk `hint` that touches a word covered by a vocabulary
entry, check whether the hint restates a fact already present in that
vocabulary entry's `notes`. If it does, either delete the hint or rewrite it
to address something specific to *this chunk's context* (why this
construction appears here) rather than repeating the word's general
meaning. Vocabulary `notes` and Translation `hint`s must not carry duplicate
content.

### 5.7.1 Stem-alternation notes for verbs (resolved)

Vocabulary `notes` are surfaced to the learner during study, so a specific,
factual note about how a verb's own stem behaves is high-value study content
— this is a targeted exception to "not a grammar lesson" above, not a
relaxation of it. The distinction is between explaining *this word's*
alternation (welcome) and giving a general grammar lecture that isn't tied
to the entry (still out of scope).

**Required:** if a verb entry's citation form and its inflected forms
(whether recorded in this entry's own `forms` field or only appearing in
the companion Conjugation pack) differ by a systematic stem or consonant
alternation — e.g. Finnish KPT gradation (`kk→k`, `tt→t`, `nt→nn`, `ht→hd`,
`rt→rr`), a stem vowel drop, a `-ta/-tä → -tse-` shift, or the equivalent
pattern in another language — add one note naming the specific alternation
and giving a short example inflected form that illustrates it. Keep it to
the one alternation and one example; this is still one concise fact, not a
paradigm.

```yaml
notes:
  - 'KPT consonant gradation: ottaa uses tt → t gradation in weak forms, e.g. otan.'
```

If a verb has no such alternation (the stem is invariant across persons),
no stem-alternation note is needed — don't manufacture one where there's
nothing to explain.

**Multi-word/phrasal verb entries:** state plainly which word conjugates
and which stays fixed, e.g. `'Phrase verb: pukea conjugates, päälle stays
fixed.'` — this is more directly useful to a learner than a general
collocation remark, and should be the default phrasing for this case.

### 5.7.2 Inflectional-class notes and per-entry note load (resolved)

`notes` is not incidental commentary — it is the field that gets surfaced
to the learner during study, so it should carry whatever is genuinely
important to understand about the word, not just its meaning. Whether a
word belongs to a named inflectional class, and what that means for how it
inflects, is exactly that kind of information when the target language has
such a system.

**Requirement (language-agnostic):** When the target language groups words
of the entry's part of speech into named inflectional classes that
determine how the word inflects — Finnish's verb types, a Romance
language's conjugation groups, a Slavic declension class, or the
equivalent in any other language — give every entry belonging to such a
system a self-contained class note, stating the class and briefly showing
why it matters with one live inflected example. This applies to **every**
entry the system covers, including the regular/default class — knowing
"this is the regular pattern" is itself useful, not a null fact. Do not
invent a classification or draw class boundaries that the language's own
grammatical tradition doesn't recognize; if the target language has no such
system for this part of speech, no class note is added.

A class note is not a bare label. Naming the class without saying what it
means or showing it in action teaches nothing to a learner who doesn't
already have external reference material open:

```yaml
# Insufficient — a label, not a teaching note:
notes:
  - 'Finnish verb type: 1'

# Sufficient — states the class, what it means, and an example:
notes:
  - 'Type 1 verb: ajaa attaches personal endings directly to its stem, e.g. ajaa → ajan.'
```

**Managing note load.** This requirement will often produce more than one
candidate note for the same entry — an inflectional-class note alongside a
§5.7.1 stem-alternation note, or a lexical note. Before finalizing an
entry's `notes`:

- A stem/consonant alternation is usually a *consequence* of the entry's
  inflectional class, not an independent fact — merge the two into one
  note rather than stacking adjacent bullets that both describe the same
  underlying mechanism:

  ```yaml
  notes:
    - 'Type 1 verb: soittaa uses tt → t consonant gradation in weak forms, e.g. soitan.'
  ```

  not two separate bullets, one naming the type and one naming the
  gradation.
- Keep genuinely independent facts — an idiom, a collocation, a
  confusability warning — as their own bullet; merging unrelated facts into
  one sentence obscures both of them.
- As a rough ceiling, most entries should carry no more than two or three
  notes. If more distinct facts are genuinely warranted, prioritize (1) the
  inflectional-class note, then (2) the single most learner-relevant
  lexical note, and leave any remaining detail for the Conjugation pack or
  a later human editorial pass rather than stacking bullets a learner has
  to read through on the study screen.
- When both an inflectional-class note and a lexical/usage note are
  present on the same entry, put the inflectional-class note first.

### 5.7.2a Prefer lemma-specific phrasing over abstract suffix rules (resolved)

When writing an inflectional-class or stem-alternation note (§5.7.1,
§5.7.2), phrase the mechanism in terms of *this lemma*, not as an abstract
rule about an ending pattern. Naming the specific lemma in the descriptive
clause itself — not just in the trailing example — teaches the learner how
*this word* behaves, which is what they're actually trying to learn while
looking at this entry.

```yaml
# Prefer — names the lemma in the description itself:
notes:
  - 'Type 5 verb: häiritä uses the häiritse- stem before personal endings, e.g. häiritä → häiritsen.'

# Avoid — states an abstract suffix rule, with the lemma appearing only in the example:
notes:
  - 'Type 5 verb: an -itä infinitive takes an -itse- stem before personal endings, e.g. häiritä → häiritsen.'
```

- This is a phrasing preference, not a change to what information the
  note carries — both versions above state the same class, the same
  mechanism, and the same example. The difference is whether the sentence
  is *about the ending pattern* (abstract, requiring the learner to
  mentally substitute in the lemma) or *about the word itself* (concrete,
  already substituted). Prefer the latter.
- This phrasing preference applies equally to a merged class+alternation
  note (§5.7.2's note-load guidance) and to a multi-word/phrasal verb's
  "which word conjugates" note (§5.7.1) — name the lemma or the
  supporting word directly rather than describing its category in the
  abstract.
- Because the note is now already concrete, it carries forward into the
  Conjugation entry verbatim by default rather than requiring further
  trimming — see §6.2.2's updated carry-forward rule.

### 5.7.2b `'Stem: X'` note for languages with a bound-stem system (resolved)

When the companion Conjugation pack for this language records a top-level
`stem` field (§6.2.1a) — i.e. the language organizes verbs around a bound
stem that personal endings attach to — every verb Vocabulary entry must
carry a matching note in its own `notes`, in the form:

```yaml
notes:
  - 'Type 5 verb: häiritä uses the häiritse- stem before personal endings, e.g. häiritä → häiritsen.'
  - 'Stem: häiritse-'
```

- The note's text is exactly `Stem: ` followed by the same bound-stem
  string that will appear in the companion Conjugation entry's top-level
  `stem` field (§6.2.1a) — same hyphenation/quoting convention, character
  for character. A learner (or the Conjugation pack's author, working from
  this entry per §2's pipeline order) must be able to read the stem
  directly off this note without re-deriving it.
- **Placement:** the `'Stem: X'` note goes immediately after the
  inflectional-class note (§5.7.2) — and after a merged
  class+stem-alternation note, if the two were combined per §5.7.2's
  note-load guidance — but *before* any separate lexical/usage note (an
  idiom, a collocation, a sense distinction). The stem is a direct,
  mechanical consequence of the class just named; a lexical note is an
  unrelated fact about the word and belongs after it.
- This is a distinct field from the inflectional-class note itself, not a
  replacement for it — §5.7.2's requirement that every entry in a
  class-covered part of speech get a real, example-bearing class note
  still applies in full. `'Stem: X'` is a compact, learner-facing
  restatement of the same fact in a form that's easy to spot while
  drilling, not a substitute for explaining the mechanism in prose.
- **Whole-pack decision, not per-entry.** This mirrors §6.2.1a exactly:
  whether `'Stem: X'` notes are used at all depends on whether the
  language's Conjugation pack uses a top-level `stem` field, decided once
  for the whole pack pairing. If the Conjugation pack uses `stem`, every
  verb entry in the Vocabulary pack gets the note, irregular verbs
  included (using the same dominant-stem convention described in
  §6.2.1a). If the language has no bound-stem system, no Vocabulary entry
  gets this note either.
- If a verb Vocabulary entry is authored before its Conjugation
  counterpart exists yet (the normal §2 pipeline order), supply
  `'Stem: X'` at Vocabulary-authoring time using linguistic knowledge of
  the stem — not defer it and leave the note missing — since the
  Conjugation pack is required to carry a matching value forward from
  Vocabulary (§6.2.1a), not invent one first.

### 5.8 ID normalization for multi-word lemmas

When a lemma or vocabulary id contains spaces (or would be awkward as a raw
identifier), normalize it for the `id` field — typically by replacing spaces
with underscores. Use that **same normalized string** consistently in
`vocabulary_refs` in the Translation pack. Reserve the natural, spaced,
human-readable form only for display fields such as `prompt`, never for
`id` or for any field a companion pack must match against.

Normalization must preserve the lemma's Unicode spelling in NFC. Replace
separators such as spaces and apostrophes consistently, but never remove
diacritics, transliterate letters, or silently change case beyond the
language's dictionary convention. Cross-pack links compare the resulting
string exactly; downstream tools must not be expected to repair a lossy id.

### 5.9 Controlled `type` vocabulary (resolved)

Use one of the following canonical values for every entry's `type`. Do not
coin ad hoc variants:

```
noun, verb, adjective, adverb, pronoun, conjunction, postposition,
preposition, number, phrase, interjection, discourse_marker,
negative_auxiliary
```

If none of these genuinely fits a candidate word's part of speech, extend
this list itself (and note the addition at the pack level) rather than
inventing a one-off value for a single entry. Two entries of the same part
of speech within one pack, or across companion packs for the same language,
must use the same `type` string.

A fixed multi-word predicate that is eligible for a person/polarity paradigm
has `type: verb`, even though it contains spaces in display form. Use
`type: phrase` only for a non-verbal expression or fixed grammatical frame
that is not independently conjugated. Thus French `avoir_peur` and
`laisser_tomber` are verbs; their internal noun or particle does not turn the
entry into a generic phrase.

---

## 6. Conjugation pack

### 6.1 Metadata

```yaml
metadata:
  id:
  title:
  type: conjugation
  format: canonical
  version:
  schema_version:
  source_pack:      # id of the source Vocabulary pack
                     # (omit and use source_list instead in conjugation-only
                     # mode, §2.2, when authored from a raw verb list with
                     # no Vocabulary pack)
notes:               # optional — pack-level notes
  - ...
subjects:             # optional convenience list, language-appropriate
  - ...
```

### 6.2 Entry schema

```yaml
entries:
  - id:         # required
    lemma:      # required — canonical dictionary form of the verb
    gloss:      # required — base target-language meaning of the lemma, see §6.2.1b
    category:   # required — see §6.2.1
      key:      # required — internal identifier, stable, machine-facing
      label:    # required — display string, UI-facing
    stem:       # optional, language-dependent — the lemma's bound stem, see §6.2.1a
    notes:      # optional — see §6.2.2
      - ...
    forms:      # required — language-specific paradigm, see §6.5
      # <subject>:
      #   positive:
      #     forms:     # required — one or more accepted surface forms
      #       - ...
      #     meaning:   # required — target-language meaning for this person+polarity, see §6.5.1
      #   negative:
      #     forms:
      #       - ...
      #     meaning:
```

### 6.2.1 `category` is a required classification, not optional metadata (resolved)

Every conjugation entry, in every language and in every entry point (the
default pipeline or conjugation-only mode, §2.2), **must** declare a
`category` block with both a `key` and a `label`. This is not the same
thing as the grammatical categories discussed in §6.5 (tense, polarity,
person, and so on) — `category` here classifies *which conjugation class
or verb type the lemma itself belongs to*. It is the same inflectional-class
concept already required for Vocabulary notes in §5.7.2, now expressed as
structured data rather than prose. Linguatrain's drill engine and its
category-filtered quiz mode both key off this field directly (e.g. a
`--category type_2` filter), so a missing or malformed `category` block is
a functional break, not a cosmetic omission — both features depend on it.

- `key` is the internal, machine-facing identifier. It must be stable,
  language-appropriate, and safe to use as a CLI argument or filter value:
  lowercase, snake_case, no spaces or punctuation beyond underscores.
- `label` is the human-facing display string shown in the UI. It should
  read naturally to a learner of that language and follow that language's
  own conventions for capitalization and naming.
- The pairing of `key` and `label` for a given class must be identical,
  character-for-character, every time that class appears in the pack.
  Never let the same class drift between two different `key` spellings, or
  between two different `label` wordings, across entries.
- Every language classifies its verbs differently, and this field must
  reflect *that* language's own system, not a system borrowed from another
  language. Examples below are illustrative only — do not treat any single
  one as a template to force onto a different language:

  ```yaml
  # Finnish — numbered verb types, plus an irregular bucket
  category:
    key: type_2
    label: Type 2
  ```

  ```yaml
  # Spanish — infinitive ending class
  category:
    key: ar
    label: '-ar'
  ```

  ```yaml
  # German — strong vs. weak verbs
  category:
    key: strong
    label: Strong
  ```

  ```yaml
  # French — numbered verb groups
  category:
    key: group_2
    label: Second group
  ```

- Irregular, or otherwise class-defying, verbs are not exempt from this
  field. Give them their own language-appropriate `key`/`label` (e.g.
  Finnish `type_irregular` / `Irregular`) rather than omitting `category`
  or leaving it empty. This mirrors §5.7.2's rule that the regular/default
  class still gets a real note, not a bare label standing in for one —
  here, no entry is exempted from `category` at all.
- When a language's recognized classification already has a catch-all class
  for irregular or residual verbs (for example, the French third group), use
  that recognized class consistently. Do not split individual members into
  ad hoc `irregular` subclasses unless the pack documents a real,
  language-recognized subclass and applies it consistently; describe the
  lemma-specific irregularity in `notes` instead.
- If the target language genuinely has no named inflectional-class system
  for verbs, that is the one case `category` may be omitted — but this is
  a property of the language, decided once for the whole pack, not a
  per-entry choice. Never include `category` for some verbs in a pack and
  omit it for others.

### 6.2.1a `stem` — the lemma's bound stem (optional, language-dependent, resolved)

Some languages inflect verbs by attaching endings to a **bound stem** — a
form that isn't a free-standing word on its own (Finnish vartalo, and the
equivalent concept in many other agglutinative or fusional languages). When
the target language works this way, every Conjugation entry carries a
top-level `stem` field — a sibling of `lemma` and `category`, not a
property of the class:

```yaml
lemma: tarvita
category:
  key: type_5
  label: Type 5
stem: 'tarvitse-'
```

- `stem` belongs to the specific lemma, not to the class it belongs to.
  Two verbs in the same `category` can still have entirely different stems
  (compare `tarvita` → `tarvitse-` and `valita` → `valitse-`, both Type 5)
  — `category.key`/`label` describe the shared pattern; `stem` is this
  lemma's own instantiation of it. Do **not** nest `stem` inside
  `category`:

  ```yaml
  # Incorrect — stem is not a property of the class
  category:
    key: type_5
    label: Type 5
    stem: 'tarvitse-'
  ```

- **Deriving `stem` is type-dependent, not one universal recipe.** The
  earlier version of this rule ("strip the person-marking ending from
  minä-positive") is only safe for verb classes where minä-positive is
  already built on the paradigm-wide stem. For a class where minä-positive
  is a *weak-grade* form and other persons use the *strong grade*
  (consonant-gradating Type 1 verbs, in Finnish), stripping `-n` from
  minä silently records the weak grade as `stem` — which is wrong, and
  produces a different bug from nesting `stem` in `category`, but is just
  as much a correctness error.

  - **Types where personal endings attach to a stem that doesn't itself
    have a strong/weak alternation** (Finnish Types 2, 3, 4, 5, and
    irregulars): derive `stem` by stripping the person-marking ending from
    minä-positive, as before (`tarvitsen` minus `-n` → `tarvitse-`; `mennä`
    → `mene-`, recovering the epenthetic vowel Type 3 inserts; `herätä` →
    `herää-`, recovering Type 4's vowel doubling). This form is the same
    across every person in the paradigm for these classes, so any person
    would give the same answer.
  - **A class whose own citation form already contains the stem vowel, and
    which additionally undergoes KPT/cluster consonant gradation**
    (Finnish gradating Type 1 verbs — `ottaa`, `antaa`, `hiihtää`,
    `lähteä`, `lukea`, and similar): derive `stem` from the **citation
    form**, not from minä. Strip only the final vowel from the infinitive
    (`lähteä` minus `-ä` → `lähte-`; `ottaa` minus `-a` → `otta-`). This is
    the strong grade, matching `hän`/`he` in the paradigm. Do not derive it
    from minä-positive (`lähden` minus `-n` → `lähde-` is the *weak* grade
    and is the wrong value for `stem`). The weak-grade alternation itself
    still belongs in `notes` exactly as §5.7.1/§5.7.2 already require
    (`'Consonant gradation: nt → nn in weak-grade forms, e.g. antaa →
    annan.'`) — `stem` and the gradation note describe the same verb from
    two different, complementary angles, not the same fact twice.
  - **Telling the two cases apart:** compute both candidate stems (strip
    the final vowel from the infinitive; strip `-n` from minä-positive). If
    they're identical, there's no gradation to worry about and either
    method gives the same answer (e.g. `puhua` → `puhu-` both ways). If
    they differ, the language has a strong/weak distinction for this verb,
    and `stem` takes the citation-derived (strong) form.
  - This distinction is exactly why `lähteä` is genuinely a Type 1 verb,
    not Type 3, despite superficially resembling `mennä`: `mennä` minus
    `-nä` leaves nothing before the ending (`men-`), so the `-e-` in
    `mene-` is a real insertion — the Type 3 hallmark. `lähteä` minus `-ä`
    already leaves `lähte-` intact; the `t`→`d` it shows in `lähden` is
    ordinary consonant gradation, structurally identical to `hiihtää` →
    `hiihdän`, not a stem-insertion mechanism. Confusing a citation form
    that merely *contains* a vowel with one where a vowel was *inserted*
    is an easy category-classification mistake to make and worth checking
    explicitly rather than assuming from surface similarity.
- Mark `stem` as a bound form using the target language's own convention
  for an incomplete stem (a trailing hyphen for Finnish, e.g. `'herää-'`).
  Quote the value per §3.1.
- **Whole-pack decision, not per-entry**, exactly like `category` (§6.2.1).
  If any entry carries `stem`, every entry does — including irregular
  verbs, which get the dominant/regular-looking stem the paradigm is built
  from even though some persons deviate from it (e.g. Finnish `olla`'s
  `stem: 'ole-'` covers `olen`/`olet`/`olemme`/`olette`, even though
  `on`/`ovat` don't derive from it — the irregularity itself belongs in
  `notes`, not in a missing `stem`). If the target language has no
  bound-stem concept for verbs, omit `stem` for the whole pack.
- **Cross-pack consistency.** `stem` must match the companion Vocabulary
  entry's `'Stem: X'` note (§5.7.2b) exactly — same string, same
  quoting/hyphenation. This is a cross-pack consistency requirement in the
  same family as §6.4's multi-word `lemma` matching: a strict automated
  check should be able to compare the two values directly with no
  normalization step of its own.

### 6.2.1b `gloss` — the lemma's target-language meaning (required, resolved)

Every Conjugation entry carries a top-level `gloss`: the base
target-language meaning of the lemma, giving the entry a semantic anchor
independent of any specific inflected form.

```yaml
lemma: häiritä
gloss: to disturb
```

- `gloss` is the **primary sense only** — the first item in the companion
  Vocabulary entry's `answer` list (§5.2), not the full list of senses. If
  Vocabulary lists multiple senses (`to disturb`, `to bother`), `gloss`
  records only the first: `to disturb`. The full sense list is composed
  into the per-form `meaning` field instead (§6.5.1), not duplicated here.
- This matters because the subjects and polarities recorded in `forms`
  (§6.5) are not different tenses of different ideas — they are the same
  present-tense verb, varying only by grammatical person and polarity.
  `gloss` states, once, what that one idea is.
- In conjugation-only mode (§2.2), where there is no companion Vocabulary
  entry to draw from, derive `gloss` directly from the lemma using the
  same judgment that would otherwise produce a Vocabulary `answer` — a
  single, primary sense, not a list.
- Unlike `stem`, `gloss` is not conditional on the target language's
  morphology — every Conjugation pack, in every language, carries it.

### 6.2.2 Carrying grammar notes forward from Vocabulary (resolved)

A conjugation drill is exactly the moment a learner is most likely to get
a stem alternation wrong — more so than during vocabulary study, where the
word is being met rather than actively inflected. When a note already
exists on the source Vocabulary entry, it is wasted if it's stranded on a
screen the learner isn't looking at when the mistake happens.

This section covers carrying forward `notes` prose specifically. The
structured-data fields `stem` and `gloss` are populated independently, per
§6.2.1a and §6.2.1b respectively, with their own cross-pack consistency
requirements — they are not "carried forward as a note."

**In the default pipeline (§2), where a Conjugation pack is derived from a
Vocabulary pack:** if the source Vocabulary entry carries a stem-alternation
note (§5.7.1) or an inflectional-class note (§5.7.2), carry the same
grammatical fact forward into the corresponding Conjugation entry's own
`notes`. This is a requirement, not a nice-to-have — whenever such a note
exists in Vocabulary, its Conjugation counterpart must have one too.

- Do **not** carry forward purely lexical or usage notes (idioms,
  collocations, sense distinctions, register) — those are Vocabulary's
  concern and don't help a learner who is stuck on a conjugated form.
- **Carry the note forward verbatim by default.** Because notes are now
  written in lemma-specific phrasing (§5.7.2a) rather than as abstract
  suffix rules, the Vocabulary note is already concrete and already names
  this exact lemma and stem — it is not merely restating what `category`
  already encodes as structured data, the way a bare class label would.
  For example, a Vocabulary note reading:

  ```yaml
  notes:
    - 'Type 5 verb: häiritä uses the häiritse- stem before personal endings, e.g. häiritä → häiritsen.'
  ```

  carries forward into the Conjugation entry unchanged:

  ```yaml
  notes:
    - 'Type 5 verb: häiritä uses the häiritse- stem before personal endings, e.g. häiritä → häiritsen.'
  ```

  If an older-style abstract note is encountered (naming the ending
  pattern rather than the lemma, e.g. `'an -itä infinitive takes an
  -itse- stem...'`), trim it of the redundant `category`-name framing as
  this section previously required, but prefer rewriting it in
  lemma-specific phrasing per §5.7.2a instead of merely trimming it.
- If the Vocabulary note merged a class note and a stem-alternation note
  into one bullet per §5.7.2's note-load guidance, carry the merged fact
  forward as one note, verbatim, rather than re-splitting it into two.
- For a multi-word/phrasal verb entry, carry forward the "which word
  conjugates, which stays fixed" note (§5.7.1) essentially as-is — that
  framing is already conjugation-relevant and needs no trimming.
- If the source Vocabulary entry has no such note (an invariant stem, or a
  language with no inflectional-class system for this part of speech), add
  no note to the Conjugation entry either. Do not manufacture one where
  Vocabulary had nothing to say.
- In conjugation-only mode (§2.2), there is no Vocabulary entry to draw
  from, so this carry-forward requirement does not apply. `notes` remains
  available on a Conjugation entry in that mode for a genuinely
  conjugation-specific fact the author has independent grounds for, but
  nothing is fabricated to fill it.

### 6.3 Candidate selection

Generate a conjugation entry **only** for verbs already present in the
companion Vocabulary pack — never invent a verb the Vocabulary pack doesn't
reference, and never generate entries for nouns, adjectives, adverbs,
pronouns, particles, conjunctions, or fixed expressions. Each verb lemma
appears exactly once in the pack (one verb, one identity), regardless of how
many surface forms of it appeared in the source text.

Here “fixed expressions” means non-verbal expressions. A fixed multi-word
predicate marked `type: verb` under §5.9 is a verb candidate and must not be
excluded merely because its lemma contains more than one word.

Do **not** generate conjugation entries for defective or impersonal verbs.

In conjugation-only mode (§2.2), there is no companion Vocabulary pack;
candidates come directly from the raw verb list after the §5.0
preprocessing rules are applied, and the same restrictions in this section
still govern which lemmas may become entries.

### 6.4 Multi-word lemma consistency (resolved)

If the verb's lemma contains spaces (e.g. a phrasal/compound verb), the
conjugation entry's `lemma` field **must exactly match** the corresponding
vocabulary entry's normalized `id` string (per §5.8) — not the natural,
spaced form. Example pattern:

```yaml
# vocabulary pack
id: 'multi_word_lemma'
prompt: 'multi word lemma'

# conjugation pack — lemma matches the vocabulary id exactly, underscores and all
lemma: multi_word_lemma
```

A strict automated linker must be able to match these two files on that
string with no normalization step of its own. Reserve the natural spaced
form for display-only fields.

### 6.5 Completeness is a closure rule, not a guideline (resolved)

This section concerns paradigm coverage — which grammatical distinctions
`forms` includes. It is distinct from the required `category` classification
field defined in §6.2.1, which every entry carries regardless of what
`forms` covers.

If a grammatical category — polarity (positive/negative), grammatical
gender, a tense, a mood, a person, or any other category the language
distinguishes — is included for **any** verb in the conjugation pack, it
**must** be included for **every** verb in that pack. Partial coverage of a
category across entries within one pack is not permitted, even if the
missing cases feel less "practical" for a given verb.

This exists because partial coverage isn't a stylistic choice in a language
where that category is obligatory grammar (e.g. gender-marked verb forms in
a language that requires gender agreement) — a pack with holes in that
category cannot correctly generate valid sentences for the verbs it left
incomplete.

Before finalizing a conjugation pack, verify: pick the richest category
covered by any single entry, then confirm every other entry in the pack
covers that same category to the same depth. If it does not, either fill the
gap or remove that category from the whole pack rather than leaving it
partial.

**Can a category be dropped for the whole pack, not just left partial
(added clarification)?** The rule above forbids *partial* coverage — some
entries having a category and others not. It does not by itself forbid
omitting a category *entirely*, uniformly, across every entry. That
omission is a separate decision with a different bar depending on the
category:

- **Polarity (positive/negative) is not an optional category for any
  language that grammaticalizes negation** — which is effectively every
  language Linguatrain supports. A conjugation pack that never drills
  negative forms is missing a baseline learner need, not skipping a
  marginal refinement, and this is true regardless of how negation is
  formed (a separate word as in French `ne...pas`, a suffix, an auxiliary
  change, or something else). Omitting `negative` for the whole pack is a
  conformance failure, not a permitted scope choice, unless the target
  language has no productive way to negate a finite verb at all.
- **Other categories — a specific tense, mood, or a fine-grained honorific
  register — remain genuinely optional** in the sense that a pack scoped to
  "present tense only," stated as such in `metadata.notes`, is a legitimate,
  narrower pack rather than an incomplete one. The closure rule still
  governs *within* whatever scope is declared: if the pack covers present
  tense, it must cover present tense positive and negative for every verb,
  per the polarity rule above.

A pack-level note stating a scope decision (e.g. "present tense only") is
useful and welcome documentation, but it cannot exempt the pack from a
requirement — the same standard already stated in §0 for
specification-vs-judgment conflicts applies here as well: a documented
choice to skip a required category is still a conformance failure, not an
authorized exception.

### 6.5.1 `forms`/`meaning` structure for each subject and polarity (required, resolved)

Each subject's `positive` and `negative` value is not a bare list of
surface forms — it is an object with two required fields:

```yaml
forms:
  minä:
    positive:
      forms:
        - häiritsen
      meaning: I disturb / I bother
    negative:
      forms:
        - en häiritse
      meaning: I do not disturb / I do not bother
```

- The nested `forms` list is the same accepted-surface-form list this
  field has always held — one or more accepted variants for this subject
  and polarity.
- Every item in that list is one complete, exact surface form. Never encode
  alternatives inside one scalar with slash shorthand (`il/elle est`,
  `parle/parles`) or parenthetical optionality. Put each accepted form in its
  own list item, and use separate subject keys when the forms belong to
  different grammatical subjects.
- The accepted-form set is closed for the scope represented by that key: if
  the pack recognizes an equally standard spelling, register, or optional-
  particle variant for one applicable slot, include the corresponding valid
  variants for every other applicable slot where that same distinction
  exists. Do not add a lone convenience variant to one person while leaving
  the same productive series unavailable elsewhere. Dialectal or deliberately
  out-of-scope series may be omitted uniformly and documented at pack level.
- `meaning` is the exact target-language meaning of this specific
  subject+polarity combination, in the same target language used throughout
  the companion Vocabulary and Translation packs (English, in the worked
  examples throughout this spec). Compose it from every sense in the
  companion Vocabulary entry's `answer` list (§5.2 — contrast with
  `gloss`, §6.2.1b, which records the primary sense alone), joined with
  `" / "`, inflected for this subject, and — for negative polarity — using
  the target language's own negation pattern for that subject (English:
  `do not`/`does not` + the bare verb).
- This is a closure requirement in the same family as §6.5's paradigm
  coverage rule: if `meaning` is present for any form in the pack, it is
  present for every form in the pack. A pack does not mix the older
  bare-list style (`positive: [häiritsen]`) with this `{forms, meaning}`
  style, and does not supply `meaning` for some subjects/polarities while
  omitting it for others.
- English has no separate formal/informal or singular/plural second
  person; both `sinä` and `te` render as "you" in `meaning`. This is a
  genuine limitation of the target language, not an error to correct —
  don't invent an artificial distinction (like "you (plural)") that the
  target language doesn't actually make in ordinary usage. Follow the
  equivalent real distinction for any other target language instead.

### 6.6 Language-specific structure

`forms` should model the grammar of the language actually being taught, not
be forced into a template built for a different language family. A language
that marks person may organize `forms` by person; a language with rich
tense/mood distinctions may nest tense and mood above person; a language
without a dedicated negative verb inflection still records the required
positive/negative semantic contrast (§6.5), but its negative `forms` must use
the language's real native construction (particle, auxiliary, periphrasis,
or other mechanism), not an invented synthetic “negative conjugation.” The
objective is internal consistency within one pack and fidelity to the
language being taught — not uniform surface morphology across languages.

### 6.6.1 Subject pronouns and clitics in `forms` values (resolved)

`forms` values are conjugated surface *answers*, not bare stems — the test
for what belongs in each accepted string is not "the verb's ending" but
"what a native speaker would actually write or say as a complete, correct
answer for this subject and polarity."

**Pro-drop languages** — those where a finite verb with no expressed
subject is itself a complete, natural, grammatical utterance for that
person (Finnish, Spanish, Italian, and many others) — should omit the
subject pronoun from `forms`, exactly as the worked Finnish example
throughout this document already does (`häiritsen`, not `minä
häiritsen`). The subject is already represented structurally, by the key
under which the form is filed (§6.5.1); repeating it inside the string
makes the entry longer, not more complete or more correct.

**Non-pro-drop languages** — those where the grammar requires an expressed
subject for a bare finite verb to count as a complete, correct utterance
outside the imperative (French, English, German, and others) — must
include the subject as part of each accepted `forms` string. This is not
primarily about disambiguating homophonous forms (though it often has that
side effect — French `rencontre` alone is spelled identically for `je` and
`il/elle`); it is about grammatical completeness. `rencontre` alone is not
a correct French sentence-level answer to "how does *il* conjugate this
verb?" — `il rencontre` is the complete, correct answer, and omitting the
subject records an incomplete answer as if it were a complete one.

When one subject key covers more than one distinct subject word (for
example a combined `il_elle_on` key, used because these persons take an
identical verb ending in French), do not collapse the distinct subject
words into a single string and do not pick just one to stand in for all
three. Each is a separate, complete, accepted form and belongs in its own
list item, exactly per the existing rule against slash-shorthand and
parenthetical optionality (§6.5.1):

```yaml
forms:
  il_elle_on:
    positive:
      forms:
        - il rencontre
        - elle rencontre
        - on rencontre
      meaning: he/she/one meets
```

**Object and reflexive clitics are a separate question from subject
pronouns, and are governed differently:**

- An ordinary direct- or indirect-object clitic (French `me`, `te`, `le`,
  `lui`, and equivalents in other languages) is never part of a base
  paradigm cell. Object selection varies independently of the subject and
  polarity a Conjugation pack's person/polarity paradigm exists to teach —
  it belongs in Translation-pack sentence content or a dedicated Word
  Explorer entry, not baked into every cell of every verb's paradigm.
- A reflexive/pronominal clitic is different in kind. For a lemma that is
  reflexive-only (§5.4's `s_inquiéter`-style identity), the agreeing
  reflexive pronoun is an inseparable, subject-varying part of the verb's
  own conjugation — exactly like a personal ending — and must appear in
  every form (`je m'inquiète`, `tu t'inquiètes`, ...). It is not an
  optional clitic to strip out; the verb does not exist without it.

This resolves without contradicting this section's general principle:
pro-drop and non-pro-drop languages are each modeled according to what
that language's own grammar actually requires for a complete, correct
answer — not according to a single rule ("always include the subject" or
"never include the subject") imported wholesale from whichever language
happened to produce the first worked example.

### 6.7 Multi-word expressions

Where a language expresses a single idea as a fixed multi-word verb
expression, keep it as one conjugation entry rather than splitting it into
its component words — the same principle underlying §5.5.

Such an entry must be `type: verb` in Vocabulary (§5.9), must use the same
normalized identity in both packs (§6.4), and conjugates its verbal head under
§6.8. A non-verbal `type: phrase` entry is not conjugation-eligible.

### 6.8 Conjugating the head, not the supporting word (resolved)

In a multi-word verb expression, only the verb head is conjugated for
person and polarity across the paradigm. Any supporting word — a noun,
particle, adverb, or otherwise — is held invariant across all six persons.

That invariant form must be whatever form the expression actually requires
in the target language — not simply whatever surface form happened to
appear in the raw source (word list, sentence, or otherwise) the entry was
built from. Two supporting words that look similarly "given" in a raw
source can require different treatment:

- If the source already supplies the correct required form, carry it
  through unchanged (e.g. Finnish `tehdä ruokaa` — the partitive `ruokaa`
  is already correct, so it's copied as-is into every person: `teen
  ruokaa`, `teet ruokaa`, ... `tekevät ruokaa`).
- If the source supplies the wrong form, correct it before generating the
  paradigm, and flag the correction the same way a non-citation-form verb
  token is corrected and flagged under §5.4. (For example, Finnish
  `polttaa tupakka` — "to smoke" — requires a partitive object under the
  durative/consumption-verb pattern also seen in `syödä leipää` and `juoda
  vettä`; the nominative `tupakka` is wrong and must be corrected to
  `tupakkaa` before the paradigm is built, giving `poltan tupakkaa`,
  `poltat tupakkaa`, etc.)

This rule is deliberately language-agnostic: whatever grammatical
adjustment a given language's grammar requires of the supporting word in
this construction — case, agreement, mutation, or anything else — must be
reflected in the invariant form used throughout the paradigm. Do not
default to verbatim copying of the raw source's supporting word without
first checking whether the target language's grammar actually requires it
to appear in that form.

---

## 7. Word Explorer pack

Word Explorer is a companion pack, governed by the same authority rule as
§2: it is derived from, and must remain consistent with, the Translation
pack. It answers a different learner question than Vocabulary or
Conjugation do — not "what does this word mean" or "how does this verb
conjugate," but **"why does this word look like this?"** — by connecting an
encountered word back to its base word, showing how it was formed, and
generating nearby forms worth exploring.

Any other future companion pack not covered by this specification (a
grammar-topics pack, for instance) must still follow this same rule: derived
from, and consistent with, the Translation pack, with no cross-reference
presented as resolved unless a real target for it exists (§4.8).

### 7.0 Position in the pipeline

Word Explorer derives from the **Translation pack**, not the Vocabulary
pack — its entries are keyed to a specific encountered word inside a
specific source sentence, the same unit the Translation pack's `entries`
and `chunks` are keyed to. Unlike Conjugation, Word Explorer has no raw-list
alternate entry point in this specification: because every entry's `source`
must trace to real chunk-level context, Word Explorer cannot currently be
authored as a freestanding exercise the way §2.1/§2.2 permit for Vocabulary
and Conjugation. If asked to do so, flag the request rather than inventing
sentence context to satisfy the schema.

Word Explorer may cross-reference the Vocabulary pack (`vocabulary_ref`) and
the Conjugation pack (indirectly, via a shared `base_word`/`lemma`) where
those packs exist, but it does not require them to exist first. Producing a
Word Explorer pack without a companion Vocabulary pack is valid; leave
`vocabulary_ref` unset in that case rather than inventing an id that
resolves to nothing (§7.9).

### 7.1 Terminology (resolved)

Learner-facing text — `hint`, `explanation`, `formation`, `role`,
`why_it_fits`, `why_not`, and anything the UI would render to a learner —
must use `word` and `base_word`, never `lemma`, `root`, or `morphological
analysis`. These are the terms defined in the Word Explorer Design
Specification and they are a hard requirement, not a style preference: a
learner is being asked for the dictionary form they'd look up, not a
morphological abstraction.

This restriction applies only to learner-facing prose. Structured,
non-prose fields such as `morphology.stem` remain as specified — the schema
itself is allowed to use linguistic terms; the words shown to the learner
are not.

### 7.2 Metadata

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
  source_pack: ''
```

- `id` follows the same `<lesson>_word_explorer` naming convention already
  used by the Vocabulary/Conjugation/Translation packs for the same lesson
  (e.g. `hei_ja_tervetuloa_translation` → `hei_ja_tervetuloa_word_explorer`).
- `source_pack` names the Translation pack's `metadata.id` this pack derives
  from. It is required whenever a Translation pack exists — Word Explorer's
  no-raw-list rule (§7.0) means this field is never legitimately empty in
  practice.
- `category` and `chapter` are optional, free-form organizational metadata
  for whatever grouping the source material itself supplies; carry them
  forward from the Translation pack's own metadata if present there. **Do
  not invent a chapter number or course-sequence position that the source
  material doesn't state.** A Translation pack's source text arrives with
  no guaranteed information about which course it belongs to, where it sits
  in a sequence, or whether any other pack precedes or follows it — treat
  each Translation pack as standalone unless its own metadata says
  otherwise. If `chapter`/`category` aren't established by the source,
  omit them rather than inferring a plausible-looking number; this is a
  case where §0's "prefer omission over invention" applies directly, not
  a case for stating an inference. See §7.11.1 for why this matters
  specifically for the Guide's title and headings.

### 7.3 Grammar catalog

The top-level `grammar:` list works exactly like `subjects:` in a Conjugation
pack (§6.1) or `grammar.refs` targets in a Translation pack (§4.8): it is
the terminal set of grammar concepts this pack is allowed to reference, and
it must be defined once and referenced by key everywhere else.

```yaml
grammar:
  - key: ''
    name: ''
    plain_english: ''
    description: ''
```

- `key` is the machine identifier referenced by `morphology.case`,
  `grammar_refs`, and `applications[].grammar_refs` elsewhere in the pack.
- `name` is the technical term (e.g. "Adessive") — teachers and textbooks
  use this term, so it is kept, but it is never the *only* thing shown to
  the learner.
- `plain_english` is the primary learning scaffold shown alongside `name`
  (e.g. "on / at / by means of"). Every catalog entry requires one.
- `description` is a short teaching-facing explanation of what the concept
  does, in the same conservative, non-inventive spirit as a Vocabulary
  entry's `notes` (§5.7): state the mechanism, don't pad it.

**Closure rule:** every key referenced anywhere in this pack's entries
(`morphology.case`, `entry.grammar_refs`, any `applications[].grammar_refs`
or `distractors[].grammar`) must resolve to a `grammar` catalog entry
defined in this same pack. An unresolved key is a conformance failure
(§10), the same severity as an orphan `vocabulary_refs` target.

### 7.4 Entry schema

```yaml
entries:
  - id: ''

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

    morphology:
      kind: ''
      # language-specific properties below appear only when applicable —
      # never populate a property that doesn't apply to this kind (§7.5)
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
      prefix: ''
      suffix: ''
      derivational_base: ''

    hint: ''
    formation: ''
    explanation: ''
    role: ''

    explorations: []
    applications: []

    vocabulary_ref: ''
    grammar_refs: []
```

Field-by-field requirements beyond what's self-evident from the skeleton:

- `id` uses a pack-local sequence distinct from Translation/Vocabulary ids
  (the worked examples use `m001`, `m002`, ... — "m" for morphology — but
  any stable, unique, sequential scheme is acceptable as long as it is
  applied consistently within one pack).
- `source.entry_id` and `source.chunk_id`, when present, must resolve to a
  real Translation pack entry `id` and chunk `id`. `source.text`,
  `source.literal`, and `source.target` must match — not merely resemble —
  the corresponding Translation pack values for that entry/chunk. This is
  the Word Explorer analogue of the lemma-identity rule (§5.4): the source
  context is copied, not re-derived or re-worded.
- `word` is the exact encountered surface form from the source text and must
  be a contiguous substring of `source.text`. Never manufacture a normalized
  or reordered “encountered” form from discontinuous words. For inversion,
  clitics, separable particles, or other discontinuous constructions, choose
  an exact contiguous span that contains the construction being analyzed, or
  analyze one exact lexical component and explain the wider construction in
  `explanation`. Generated normalized forms belong in `explorations`, not in
  top-level `word`.
  `base_word` is its dictionary form — the value a learner would look up,
  which is also normally the companion Vocabulary entry's `id` when one
  exists (§7.9).
- `type` draws from the same controlled vocabulary as Vocabulary `type`
  (§5.9) wherever the concept overlaps (noun, verb, adjective, etc.).
- top-level `target` is the *contextual* meaning of `word` in this specific
  sentence — it may differ from a Vocabulary entry's general-purpose
  `answer` list the same way a Translation chunk's `target` can be more
  specific than a dictionary gloss.
- `hint` is optional assistance shown before the answer is revealed; see
  §7.8 for its conservatism rule.
- `formation` is a short, learner-facing derivation string in the fixed
  shape `base_word (+ stem/ending/prefix/suffix) → word`, e.g.
  `'suomi → suome- + -n → suomen'` or `'opettaa + -ja → opettaja'`. It must
  match what `morphology` actually encodes — don't show an ending in
  `formation` that isn't also recorded in `morphology.ending`/`suffix`.
- `explanation` states what the form means *and* why that form is used
  here — both halves are required, mirroring the two-part shape already
  used in the worked examples (contrast with `hint`, which only gestures
  toward the relationship without resolving it).
- `role` is a short semantic/grammatical role label (`modifier`,
  `possessor`, `agent_noun`, `passive_action`, etc.) — free text, not a
  controlled vocabulary, but it should stay consistent for the same
  relationship across entries in one pack (same spirit as §6.2.1's
  `category` consistency rule for Conjugation).

### 7.5 `morphology.kind` — controlled vocabulary (resolved)

`morphology.kind` must be one of:

| `kind` | Used for | Typical populated fields |
|---|---|---|
| `case` | Case-marked inflection of a noun, pronoun, or adjective | `case`, `ending`, `stem` |
| `compound` | Two or more whole words fused into one | `parts`, `number` (if the compound itself inflects, e.g. singular/plural) |
| `derivation` | A prefix and/or suffix builds a new word or meaning from a derivational base (often a different part of speech) | `prefix` and/or `suffix`, `derivational_base`, `source_type`, `result_type` |
| `agreement` | An adjective, determiner, or participle changes to agree with its controller without changing lexeme | `gender`, `number`, `ending`, `stem` |
| `verb_form` | A conjugated or non-finite verb form other than a plain personal paradigm slot already covered by Conjugation (passive, participle, infinitive, etc.) | `voice`, `tense`, `mood`, `form_type` |
| `base_word` | The unmarked citation form itself, used only *inside* `explorations` to represent the starting point of a word family | (none required beyond `kind`) |

For layered forms, top-level `kind` describes the relationship between the
encountered `word` and its dictionary `base_word`. Ordinary finite inflection
of a derived verb is therefore `verb_form` with the derived verb as
`base_word`; record the earlier prefix/suffix relationship in an exploration
or separate derivation entry only when that relationship is itself being
taught from source evidence. Do not label the same transformation both
`derivation` and `verb_form` merely because both occurred historically.

Do not populate a field this table doesn't list for a given `kind` unless
the language genuinely needs it (e.g. `gender` or `number` for a language
where case marking also carries gender/number agreement) — an unpopulated,
inapplicable field should be omitted entirely, not left as an empty string
(same "omission over invention" principle as §0).

This table is a starting set, not a closed list for all of Linguatrain's
languages — but within **one pack**, the same underlying concept must
always use the same `kind` value. Don't call one compound entry's kind
`compound` and another `compound_word`.

Recognize-mode boundary: `compound` entries are valid Word Explorer entries,
but they are excluded from base-word Recognize mode for now. The question
"Choose the base word" fits inflected, derived, and verb-form entries; it
does not fit compounds, whose learner-facing relationship is component
analysis (`herätys + kello → herätyskello`) rather than a single
surface-form-to-base-word relationship. Keep authoring compounds in the pack
for the Guide and future compound-specific exploration, but do not expect
them to appear in `--word-explorer --recognize` until a dedicated compound
interaction is defined.

### 7.6 `explorations` — the generative rule (resolved)

`explorations` is a small word family built outward from `base_word`, for
recognition and comparison. It follows the **same generative principle**
already established for Conjugation paradigms (§2, §6.3): a Word Explorer
entry may expand one encountered word into several related forms that were
never themselves in the source text, exactly as a Conjugation pack expands
one encountered verb into a full personal paradigm.

**Minimum required shape of one `explorations[]` item (added — this was
previously undocumented and left to inference):**

```yaml
explorations:
  - word: ''            # required — the surface form itself
    origin: source       # required — 'source' or 'generated', see below
    status: valid        # required — 'valid' | 'limited' | 'unsuitable'
    usage_note: ''       # required whenever status is not 'valid'; omit otherwise
    priority: ''         # optional — set only with a genuine pedagogical reason
```

This minimum shape is sufficient and is what most explorations should look
like. Do **not** additionally require or expect a full copy of the parent
entry's `target`/`morphology`/`formation`/`explanation` fields inside every
exploration item merely because those fields exist one level up on the
entry itself — that richer, per-exploration detail is optional elaboration,
not part of the required shape, and its absence is not a conformance
failure. If an author chooses to add `target` and/or a short `formation`
string to an individual exploration for extra clarity, that is permitted
enrichment, not a schema violation in either direction — but a validator
checking for spec conformance must treat only `word`, `origin`, and `status`
as unconditionally required; `usage_note` is conditionally required and
`priority` is optional exactly as annotated above.

- `origin: source` marks a form that is literally present in the Translation
  pack's source text (there should be exactly one such exploration per
  entry: `word` itself). `origin: generated` marks every other form.
- Every `origin: generated` form must be genuinely correct, well-formed
  language — the same conservatism that governs Vocabulary `answer` senses
  (§5.0.1) applies here: don't fabricate a plausible-looking form you
  haven't verified.
- `status: valid | limited | unsuitable` records whether a generated form is
  actually a good fit to show a learner. `usage_note` is **required**
  whenever `status` is not `valid` — explain the limitation or unsuitability
  the same way a `distractor.why_not` explains a wrong Apply answer (§7.7).
  A `status: limited`/`unsuitable` form with no `usage_note` is a
  conformance failure.
- `priority` is optional authoring guidance for the engine's practice
  selection (e.g. `high`) — set it only where you have a genuine pedagogical
  reason (source-attested forms and their most useful neighbors), not on
  every exploration by default.
- Do not generate every theoretically constructible form. Generate the
  forms that are close to the encountered word and useful for exploring
  that specific word family at the learner's current level — three to five
  explorations per entry is typical in the worked examples; there is no
  fixed minimum or maximum, but exhaustiveness is not the goal.
- Recognize-mode choices are strongest when `explorations` contains useful
  same-family alternatives. For `minulla`, good choices are `minä`,
  `minulla`, `minun`, and `minulle`; poor choices are unrelated words such
  as `aamupala`, `työ`, or `lounasravintola`. Author explorations so the
  engine can prefer meaningful nearby forms before falling back to unrelated
  pack-level distractors.

### 7.7 `applications` — Apply-mode contextual choices (resolved)

Each `applications[]` item is one contextual-choice exercise:

```yaml
applications:
  - id: ''
    type: contextual_choice
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
    choices: []
    grammar_refs: []
    explanation:
      why_it_fits: ''
    distractors:
      - word: ''
        grammar: {}
        meaning: ''
        why_not: ''
```

- `source` here follows the same copy-not-re-derive rule as `entry.source`
  (§7.4) — it should normally match the parent entry's `source` values
  exactly, since the application is testing the same source sentence.
- `prompt.text` must contain exactly one blank (`_____`) standing in for
  `answer.word`, and removing that blank and inserting `answer.word` back in
  must reproduce (or be a faithful cloze of) `source.text`.
- **Choice/distractor closure:** `choices` must contain `answer.word` plus
  every `distractors[].word`, and nothing else — no extra choices without a
  matching distractor explanation, no distractor without a corresponding
  choice. This is a closure rule in the same sense as §6.5: partial or
  mismatched coverage is a conformance failure, not a style issue.
- Use a **minimum of four choices** whenever enough plausible distractors
  exist (per the Word Explorer Design Specification). Fewer than four is
  acceptable only when the word family genuinely doesn't support more
  plausible distractors — don't pad with implausible ones to hit four.
- Every `distractors[].word` must be a real, valid form of the language
  (typically drawn from the same entry's `explorations`, or from the
  companion Vocabulary/Conjugation pack) — never an arbitrary wrong string.
  `why_not` must explain what the distractor form actually means and why
  it doesn't fit *this* context, not just assert that it's wrong — mirroring
  the worked examples, where a rejected form is still taught, not just
  dismissed.
- `explanation.why_it_fits` explains the correct answer the same way
  `entry.explanation` does — meaning plus reason, not meaning alone.
- **`distractors[].grammar` (added clarification — previously shown in the
  skeleton with no explanation of its content):** this is an optional,
  free-form map of the grammatical features that make the distractor wrong
  *when those features are the actual reason it's wrong* — e.g.
  `{gender: masculine}` when a distractor fails on gender agreement, or
  `{tense: present}` when a distractor fails because the context needs a
  different tense. Populate it only when a structured feature (not just
  prose) is genuinely useful for the engine to key off — for instance, to
  group distractors by the specific feature they get wrong across many
  entries. `grammar: {}` (empty) is a legitimate, conformant value when the
  distractor's problem isn't well captured by a simple feature/value pair —
  the prose in `why_not` is what's actually required to carry the
  explanation in every case; `grammar` is a structured supplement to it, not
  a replacement, and an empty `{}` is not itself a conformance failure as
  long as `why_not` does the explanatory work.

### 7.8 Hint conservatism (resolved)

`hint` must reference the grammatical relationship or word family the
answer belongs to, without stating the dictionary definition or resolving
the answer outright — the same rule already stated for Translation/
Vocabulary hints (§8): "using a hint to restate a dictionary definition
instead of explaining the grammatical form actually present." A Word
Explorer `hint` that simply repeats `target` or gives away `word` defeats
the point of Recognize/Build mode and is a conformance issue, not a
stylistic weakness.

### 7.9 Cross-references (resolved)

- `vocabulary_ref` must resolve to a real Vocabulary pack entry `id` when a
  Vocabulary pack exists for this lesson. It is normally equal to
  `base_word`, since both name the dictionary form. If no Vocabulary pack
  exists yet, omit `vocabulary_ref` rather than writing a forward reference
  to a pack that doesn't exist (§4.7's unresolved-reference handling
  applies here by the same logic).
- `grammar_refs` (entry-level) and `applications[].grammar_refs` must
  resolve to keys defined in this pack's own `grammar` catalog (§7.3), not
  to a Translation pack's `grammar.refs` catalog — the two catalogs are
  independent even when they name overlapping concepts, because Word
  Explorer's catalog is scoped to what this pack's entries actually use.
- Independence of authority does not justify gratuitous naming drift. When a
  Translation `grammar.refs` label and a Word Explorer grammar concept denote
  the same lesson-level concept, reuse the same normalized key where possible;
  use a different key only when the scopes or meanings genuinely differ.
- An entry with no applicable grammar concept (most `compound` and
  `derivation` entries) legitimately has an empty `grammar_refs: []` — do
  not force a grammar reference where none applies.

### 7.10 Consistency with Translation and Vocabulary (resolved)

Word Explorer must not contradict its sibling packs:

- If the Translation pack's chunk-level `hint` identifies a word as a
  compound (§4.3), Word Explorer must not analyze the same word under a
  different `morphology.kind`.
- If the Vocabulary pack records a verb as impersonal or gives it a
  particular inflectional class, a Word Explorer `verb_form` entry for that
  same verb must not imply a personal paradigm the Conjugation pack
  contradicts.
- Where a word appears in both the Vocabulary pack and Word Explorer, its
  primary sense (`answer[0]` in Vocabulary, `target` in Word Explorer)
  should agree in the base/uninflected case — Word Explorer's `target` may
  legitimately narrow to the contextual sense, but it should not conflict
  with the Vocabulary entry's own senses.

### 7.11 Word Explorer Guide (`word-explorer.md`) — generation rules (resolved)

The Word Explorer Guide is **Markdown generated from the Word Explorer
pack's YAML.** It is never authored independently, and it is never authored
directly from the Translation pack or source text — only from an already-
completed Word Explorer pack. If asked to produce a Guide before a Word
Explorer pack exists, produce the Word Explorer pack first.

**The Guide is scoped to exactly one Word Explorer pack.** A Translation
pack — and therefore its Word Explorer pack and Guide — carries no
guaranteed information about a course sequence, a chapter number, or its
relationship to any other pack. Never assume one exists. Concretely:

- One Word Explorer pack produces exactly one Guide document. Do not
  frame it as an entry in a "running log," a numbered lesson, or any other
  structure implying a known position relative to other packs.
- Never reference another pack's content in a Guide — no "the same pattern
  as Lesson 1," no assumed prior-lesson vocabulary, no cross-file links.
  If two Guides happen to cover related material, that's for the human
  author to notice and connect; the LLM has no basis for asserting it.
- If a person later wants to concatenate several standalone Guides into a
  combined reference document, that is their editorial decision, made
  outside this pipeline — not something this specification's output
  should presuppose or automate.

The Guide still follows a category-first layout, so that every form of the
same kind (every genitive, every compound, etc.) stacks up together for
study and comparison, rather than following source order.

#### 7.11.1 Document structure

```markdown
# <Language> morphology used in <title>

A standalone reference to the grammatical forms found in this text.
The populated categories below are drawn from this pack: ...

---

## <title>

### Cases

**<Case name> (<ending>)**
| Source-language form | Base word | Formation | Meaning | Where it appears |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

### Compounds
| Compound | Parts | Literal sense | Where it appears |
|---|---|---|---|

### Derivations
| Form | Base + affix | Function | Where it appears |
|---|---|---|---|

### Passive forms
| Source-language form | Base verb | Sense | Where it appears |
|---|---|---|---|

### Irregular stems
| Word | Nominative | Case stem | Why irregular |
|---|---|---|---|

**Notes:**
- ...
```

- `<title>` is the lesson/text name — the Word Explorer pack's own
  `metadata.title` with any generic pack-type suffix (e.g. "— Word
  Explorer") stripped, or equivalently the Translation pack's title. It
  names *this* pack's content, nothing more.
- `<Language>` is the source language established by the pack metadata or
  source material. Never copy “Finnish” from this illustrative template into
  a pack for another language.
- The `##` heading repeats `<title>` rather than numbering it. This looks
  redundant in a single-pack file, and that's fine — it exists as a
  stable, greppable anchor if a human later concatenates multiple
  standalone Guides by hand, not as a signal that this document expects to
  grow additional lesson sections on its own.
- **Never number this heading by chapter, lesson, or sequence position**
  (no "Lesson 2", no "Kappale 3") unless the Translation pack's own
  metadata explicitly states that number as an established fact about the
  source material, not an inference (§7.2).
- Do not invent a course name, series title, or textbook reference that
  isn't already established by the Translation/Vocabulary/Word Explorer
  metadata for this pack.
- The word "lesson" may appear as a generic noun, but the preferred
  boilerplate above describes the document as a standalone reference and
  does not imply a sequence. What's forbidden is a *numbered* reference (`Lesson 2`,
  `Kappale 3`) anywhere in the document, including inside that same intro
  paragraph's own parenthetical about omitted categories (e.g. "see Lesson
  2's Passive forms, below" is exactly the mistake to avoid — write "see
  the Passive forms note below" instead, with no number attached).

If a pack contains no entries of a given category (no `derivation` entries,
for instance), omit that category's heading entirely rather than emitting
an empty table.

#### 7.11.2 Category assignment (resolved)

Each Word Explorer entry maps to a row in exactly one **primary** table,
determined by `morphology.kind`:

| `morphology.kind` | Guide section |
|---|---|
| `case` | Cases |
| `compound` | Compounds |
| `derivation` | Derivations |
| `agreement` | Agreement |
| `verb_form` with `voice: passive` | Passive forms |
| `verb_form` (other voices/moods) | Verb forms, or a more specific language-appropriate verb-form section stated by the pack |

**Irregular stems is the one cross-cutting exception.** An entry also gets a
row in the Irregular stems table, *in addition to* its primary table, when
its `base_word`'s stem does not follow a predictable stem-plus-ending
pattern — the same test already used in the Vocabulary pack's stem-
alternation notes (§5.7.1) and Conjugation's irregular `category` (§6.2.1).
A pronoun like `minä` (stem `minu-`) or `tämä` (stem `tä-`) is the
canonical case: it earns a row in its case table (Genitive, Inessive, ...)
*and* a separate row in Irregular stems — not duplicated within either
table, only present once in each.

Do not invent an Irregular-stems row for a word whose stem is simply
predictable-but-unfamiliar-looking; the test is whether the case stem can be
derived by a general rule from the citation form, not whether the learner
happens to find it hard.

#### 7.11.3 Column derivation (resolved)

Populate each table's columns directly from the corresponding Word Explorer
entry — never re-derive or reword the underlying fact:

- **Cases** — Source-language form = `word`; Base word = `base_word`; Formation =
  `formation`; Meaning = `target`; Where it appears = a short italicized
  excerpt of `source.text` (the clause containing the form, not necessarily
  the full sentence).
- **Compounds** — Compound = `word`; Parts = `morphology.parts` joined with
  `" + "`; Literal sense = `target`; Where it appears = excerpt of
  `source.text`.
- **Derivations** — Form = `word`; Base + affix = the recorded
  `morphology.derivational_base` (or `base_word` when they are identical) plus
  `morphology.prefix` and/or `morphology.suffix`; Function = a short paraphrase of `explanation`
  (not a verbatim copy — the Guide is a study aid, not a duplicate of the
  YAML prose); Where it appears = excerpt of `source.text`.
- **Agreement** — Form = `word`; Base word = `base_word`; Features = the
  populated `gender`/`number`/`ending` fields; Meaning = `target`; Where it
  appears = excerpt of `source.text`.
- **Passive forms** — Source-language form = `word`; Base verb = `base_word`; Sense =
  `target`; Where it appears = excerpt of `source.text`.
- **Irregular stems** — Word = `base_word`; Nominative = `base_word`; Case
  stem = the `morphology.stem` recorded on the relevant case entry/entries
  for that base word; Why irregular = a short clause drawn from `hint` or
  `explanation`, never invented independently of what the YAML already
  says.

Within a category, group entries that share the same case/suffix/voice
under one subheading (`**Genitive (-n)**`, `**Partitive (-a/-ä)**`, etc.)
before moving to the next, rather than preserving the YAML's entry order —
this is what lets every genitive stack up together for comparison instead
of being scattered in source order.

#### 7.11.4 Notes section (resolved)

Each Guide's section ends with a short **Notes** bullet list — freeform
teaching observations that don't fit a table row (idiomatic asides, a
recurring pattern worth flagging, a contrast between two easily-confused
forms). Draw these only from what the entries' `hint`/`explanation` fields
already establish; do not introduce a new grammatical claim in the Notes
section that isn't traceable to the pack.

Notes must stay inside this pack's own content. Don't write "the same
pattern as Lesson 1" or otherwise compare to, assume, or reference another
pack's material — per §7.11's standalone-scope rule, there's no guaranteed
relationship between this pack and any other, and asserting one invents a
fact the source material never established.

#### 7.11.5 What the Guide must never do

- Never state a fact that isn't already present in the Word Explorer pack's
  YAML — the Guide is a reformatted view, not a second authoring pass.
- Never merge or split entries differently than the YAML defines them (one
  Word Explorer entry → its category-table row(s), per §7.11.2 — not an
  arbitrary regrouping).
- Never fabricate a "Where it appears" excerpt that doesn't match the
  entry's actual `source.text`.
- Never add a category not already established by this specification (or a
  documented, deliberate extension of it) without flagging the addition.
- Never number the document by chapter or lesson, and never reference
  another pack's Guide or content, unless the Translation pack's own
  metadata establishes that relationship as fact (§7.2, §7.11.1).

---

## 8. Common authoring mistakes to avoid

- **Overusing `accepted`** to patch a poorly chosen `target` instead of
  fixing the `target` or chunk itself.
- **Breaking the lemma invariant** — referencing an inflected surface form
  in `vocabulary_refs` or as a conjugation `lemma` instead of the dictionary
  form.
- **Using a hint to restate a dictionary definition** instead of explaining
  the grammatical form actually present in the source text (e.g. "X is the
  third-person singular present form of the verb Y," not "X = Y's
  meaning").
- **Over-naturalizing a literal translation** until it stops exposing
  source-language structure.
- **Splitting a semantic unit across chunk boundaries**, or reordering
  chunks to make the target reading flow better.
- **Duplicating the same educational fact** across vocabulary notes,
  hints, and literal translations — each field has exactly one job.
- **Producing exhaustive morphology in a Vocabulary entry's `forms`** —
  that belongs in the Conjugation pack.
- **Inconsistent phonetic conventions** within one pack.
- **Weak or exhaustive `vocabulary_refs`** — referencing every word
  mechanically rather than the pedagogically important ones.
- **Treating a symbolic token as lexical vocabulary** (see §4.5.1, §5.3).
- **Silent partial coverage of a grammatical category** in a Conjugation
  pack (see §6.5).
- **Omitting `category`, or leaving it partially populated,** on a
  Conjugation entry — including irregular or regular/default-class verbs
  — when the language has a named inflectional-class system (see §6.2.1).
- **Letting the same verb class's `key` or `label` drift** in spelling or
  wording between entries in the same Conjugation pack (see §6.2.1).
- **Leaving a Conjugation entry's `notes` empty when its source Vocabulary
  entry has a stem-alternation or inflectional-class note** — or copying
  that note verbatim including the now-redundant class-name framing
  instead of trimming it to the mechanism (see §6.2.2).
- **Mismatched multi-word identifiers** between a Vocabulary `id` and a
  Conjugation `lemma` (see §6.4).
- **Assuming a stress-marking phonetic convention transfers to any
  language** regardless of that language's actual pronunciation
  difficulties (see §4.5).
- **Nesting `stem` inside `category`** instead of as its own top-level
  field on the Conjugation entry (see §6.2.1a). `category` describes the
  class; `stem` belongs to the specific lemma.
- **Writing an inflectional-class or stem-alternation note as an abstract
  suffix rule** instead of naming the specific lemma in the descriptive
  clause (see §5.7.2a).
- **Omitting `gloss` on a Conjugation entry**, or letting it drift from
  the companion Vocabulary entry's primary sense (see §6.2.1b).
- **Flattening `forms.<subject>.<polarity>` back to a bare list of surface
  forms** instead of the required `{forms, meaning}` object, or supplying
  `meaning` for some subjects/polarities while omitting it for others (see
  §6.5.1).
- **Deriving `stem` from minä-positive for a gradating Type 1 verb**
  instead of from the citation form — minä is a weak-grade form for these
  verbs, so this silently records the wrong grade (see §6.2.1a). Check
  whether the two derivation methods agree before trusting either one.
- **Misclassifying a Type 1 verb whose citation form happens to contain a
  vowel before the ending as Type 3**, because its surface alternation
  looks similar to Type 3's epenthetic `-e-` insertion. Confirm whether the
  vowel is *already present* in the infinitive (Type 1, e.g. `lähteä` →
  `lähte-`) or *inserted* where the infinitive has none (Type 3, e.g.
  `mennä` → `mene-`) before assigning `category` (see §6.2.1a).
- **Using `lemma`, `root`, or "morphological analysis" in Word Explorer
  learner-facing text** instead of `word`/`base_word` (see §7.1).
- **Authoring a Word Explorer entry with no traceable `source.entry_id`/
  `chunk_id`**, or inventing sentence context to satisfy the schema instead
  of flagging that no Translation pack context exists (see §7.0, §7.4).
- **A Word Explorer `hint` that restates `target` or gives away `word`**
  instead of gesturing at the grammatical relationship (see §7.8).
- **An `origin: generated` exploration that isn't verified, well-formed
  language**, or a `status: limited`/`unsuitable` exploration missing its
  required `usage_note` (see §7.6).
- **Apply-mode `choices` that don't exactly match `answer.word` plus every
  `distractors[].word`** — extra choices with no distractor explanation, or
  distractors missing from `choices` (see §7.7).
- **A distractor `why_not` that only asserts the answer is wrong** instead
  of explaining what that form actually means and why it doesn't fit the
  context (see §7.7).
- **A `vocabulary_ref` or `grammar_refs` value that doesn't resolve** to a
  real Vocabulary entry or this pack's own `grammar` catalog (see §7.3,
  §7.9).
- **Generating the Word Explorer Guide directly from the source text**
  instead of from the completed Word Explorer pack, or stating a fact in
  the Guide that isn't already present in that pack's YAML (see §7.11).
- **Placing a word in the Guide's Irregular stems table just because it
  looks unfamiliar**, rather than because its case stem genuinely fails to
  follow a predictable rule (see §7.11.2).
- **Numbering a Guide by chapter or lesson, or referencing another pack's
  content** ("the same pattern as Lesson 1"), when the Translation pack's
  own metadata never established that sequence or relationship as fact
  (see §7.2, §7.11.1, §7.11.4). Treat every Translation pack as standalone
  by default.

---

## 9. Generation quality checklist

Run this checklist against every generated pack set before presenting it as
final.

### Educational quality
- ☐ Chunks are meaningful semantic units, in source order.
- ☐ Every chunk has `phonetic` if its parent entry has `phonetic`.
- ☐ `literal` genuinely exposes source-language structure; it has not been
  smoothed into natural phrasing.
- ☐ `target` reads as fluent, natural target-language prose.
- ☐ `literal` and `target` are clearly distinct from each other.
- ☐ Hints teach the grammatical form in context; they don't repeat a
  vocabulary note or a dictionary definition (§5.7).
- ☐ Every verb entry with a systematic stem/consonant alternation has a
  note naming it with an example form (§5.7.1); entries with an invariant
  stem don't have a manufactured one.
- ☐ Every multi-word/phrasal verb entry's note states plainly which word
  conjugates and which stays fixed (§5.7.1).
- ☐ Every entry whose part of speech has a named inflectional-class system
  in the target language carries a self-contained class note (§5.7.2) —
  including entries in the regular/default class — and no bare label
  stands in for it.
- ☐ A class note and a stem-alternation note describing the same
  mechanism are merged into one bullet, not stacked (§5.7.2); each
  entry's total note count stays within a reasonable ceiling (two to
  three, as a rough guide).
- ☐ Inflectional-class and stem-alternation notes name the specific lemma
  in the descriptive clause itself, not just in the trailing example
  (§5.7.2a).
- ☐ Transparent cognates or same-looking prompt/answer pairs are included
  only when they have a specific instructional reason, and that reason is
  stated in `notes` (§5.3).
- ☐ Targets with common, equally natural rewordings include at least one
  `accepted` alternative.

### Structural quality
- ☐ Required metadata is complete for every pack.
- ☐ Every id is unique within its pack and quoted per §3.1.
- ☐ Every Translation entry has chunks covering its full `source`.
- ☐ Every `vocabulary_refs` value resolves to a real Vocabulary entry `id`.
- ☐ `grammar.refs` values are treated as free-text future-linking labels
  unless a real grammar-topics pack was supplied (§4.8) — do not fail a
  pack for "unresolved" grammar refs in that case.
- ☐ The lemma invariant holds everywhere: `vocabulary_refs` and
  conjugation `lemma` values are always dictionary forms, never inflected
  surface forms.
- ☐ Multi-word Vocabulary `id`s and Conjugation `lemma`s match exactly,
  underscores and all (§6.4).

### Linguistic quality
- ☐ Vocabulary `id`s are dictionary lemmas; `prompt`s are the encountered
  surface forms.
- ☐ Morphological forms recorded anywhere are accurate for the language.
- ☐ Phonetic guidance, if present, tracks a feature that is actually
  relevant to mispronunciation in this specific language (§4.5), and is
  applied consistently throughout the pack.
- ☐ Symbolic source values (numbers, dates, currency, etc.) were never
  turned into vocabulary entries or rewritten in `source` (§4.5.1).

### Companion pack quality
- ☐ Every Conjugation entry declares a `category` with both `key` and
  `label` (§6.2.1) — including irregular and regular/default-class verbs —
  unless the target language has no named inflectional-class system at
  all, in which case `category` is omitted for the entire pack, not just
  some entries.
- ☐ The same class's `key` and `label` are spelled identically everywhere
  it recurs in the pack; no drift between entries.
- ☐ In the default pipeline, every Conjugation entry whose source
  Vocabulary entry has a stem-alternation or inflectional-class note
  carries the same fact forward into its own `notes` (§6.2.2) — verbatim
  by default, since the note is already lemma-specific (§5.7.2a); no note
  was invented where the Vocabulary entry had none.
- ☐ Every Conjugation entry's `lemma` traces back to a Vocabulary entry —
  or, in conjugation-only mode (§2.2), to a token in the raw verb list
  after preprocessing; see the Conjugation-only mode checklist below.
- ☐ Every verb lemma appears exactly once in the Conjugation pack.
- ☐ A grammatical category included for one verb in a Conjugation pack is
  included for every verb in that pack (§6.5) — no partial coverage.
- ☐ Multi-word vocabulary/conjugation candidates were bundled or split
  according to the compositionality test (§5.5), not by convenience.
- ☐ In every multi-word Conjugation entry, only the verb head varies
  across persons; the supporting word is invariant and in the form the
  target language's grammar actually requires — corrected from the raw
  source if necessary, not copied verbatim by default (§6.8).
- ☐ If any Conjugation entry carries a top-level `stem` field, every
  entry in the pack does, including irregular verbs; if the language has
  no bound-stem system, no entry carries it — and `stem` is never nested
  inside `category` (§6.2.1a).
- ☐ Every Conjugation entry's top-level `stem`, where present, matches its
  source Vocabulary entry's `'Stem: X'` note (§5.7.2b) exactly — same
  string, same quoting/hyphenation.
- ☐ For every gradating verb, `stem` was checked against both candidate
  derivations (citation-form-minus-final-vowel, and minä-positive-minus-`n`)
  before choosing — for a gradating Type 1 verb these differ and `stem`
  takes the citation-derived (strong) form, not the weak form minä happens
  to use (§6.2.1a).
- ☐ Every Vocabulary verb entry has a `'Stem: X'` note, placed immediately
  after the class note and before any lexical/usage note, whenever the
  language's Conjugation pack uses `stem`; no entry has one if the
  language doesn't.
- ☐ Every Conjugation entry has a `gloss` matching the companion
  Vocabulary entry's primary (first) `answer` sense (§6.2.1b).
- ☐ Every person's `positive` and `negative` value is a `{forms, meaning}`
  object, not a bare list; `meaning` is present for every person and
  polarity in the pack, or for none (§6.5.1).

### Word Explorer pack quality
- ☐ Every entry's `source.entry_id`/`chunk_id`/`text`/`literal`/`target`
  match a real Translation pack entry/chunk exactly (§7.4).
- ☐ Learner-facing fields (`hint`, `explanation`, `formation`, `role`,
  `why_it_fits`, `why_not`) use `word`/`base_word`, never `lemma`/`root`
  (§7.1).
- ☐ Every `morphology.kind` value is one of the controlled set in §7.5, and
  the same underlying concept uses the same `kind` value everywhere it
  recurs in the pack.
- ☐ No inapplicable `morphology` field is populated with an empty string;
  fields that don't apply to a given `kind` are omitted (§7.5).
- ☐ `formation` matches what `morphology` actually encodes (§7.4).
- ☐ Each entry has exactly one `origin: source` exploration (`word` itself);
  every other exploration is `origin: generated` and verified well-formed
  (§7.6).
- ☐ Every `status: limited`/`unsuitable` exploration carries a `usage_note`
  explaining the limitation (§7.6).
- ☐ Every application's `choices` equals `answer.word` plus every
  `distractors[].word`, exactly — no extras, no omissions (§7.7).
- ☐ Every `distractors[].why_not` explains the distractor's actual meaning
  and why it doesn't fit, not merely that it's wrong (§7.7).
- ☐ `prompt.text` contains exactly one blank standing in for `answer.word`,
  and reconstructs `source.text` when filled in (§7.7).
- ☐ Every `vocabulary_ref` resolves to a real Vocabulary entry, or is
  omitted if no Vocabulary pack exists (§7.9).
- ☐ Every `grammar_refs`/`applications[].grammar_refs` key resolves to this
  pack's own `grammar` catalog (§7.3), not a Translation pack's catalog.
- ☐ No Word Explorer entry contradicts its sibling Translation or
  Vocabulary entry's classification of the same word (§7.10).

### Word Explorer Guide quality (when generating `word-explorer.md`)
- ☐ The Guide was generated from a completed Word Explorer pack's YAML, not
  from the source text or Translation pack directly (§7.11).
- ☐ Every category present in the pack (Cases, Compounds, Derivations,
  Passive forms, Irregular stems) appears as a section; categories with no
  entries are omitted rather than shown empty (§7.11.1).
- ☐ Every entry appears in its primary table per §7.11.2, and additionally
  in Irregular stems only when its base word's case stem genuinely fails a
  predictable rule — not merely because it looks unfamiliar.
- ☐ Table columns were populated directly from the corresponding YAML
  fields per §7.11.3 — no re-derived or invented values.
- ☐ Entries sharing the same case/suffix/voice are grouped under one
  subheading before moving to the next, rather than left in YAML entry
  order (§7.11.3).
- ☐ Every "Where it appears" excerpt matches the entry's actual
  `source.text` (§7.11.5).
- ☐ Notes-section bullets trace to `hint`/`explanation` content already in
  the pack; no new grammatical claim was introduced (§7.11.4).
- ☐ The document is scoped to this one pack: no chapter/lesson number was
  invented for the title or heading, and no other pack's content is
  referenced or assumed, unless the Translation pack's own metadata states
  that relationship as fact (§7.2, §7.11.1, §7.11.4).

### Vocabulary-only mode (when authored from a raw word list)

- ☐ Every entry traces to a token literally present in the raw list, after
  preprocessing.
- ☐ Case has been normalized; no sentence-initial capitalization survives
  into `id` or `prompt` for words that aren't genuinely proper nouns.
- ☐ No duplicate tokens produced duplicate entries.
- ☐ Same-lemma surface forms were collapsed into one entry, not several.
- ☐ No entry was generated from a bare affix/case-ending notation.
- ☐ Confusable near-forms were checked against target-language dictionary
  knowledge, not merged or split by surface similarity alone.
- ☐ Metalinguistic/grammar-terminology tokens were flagged for the human
  author rather than silently included or excluded.
- ☐ `type` values are drawn from the controlled list in §5.9.
- ☐ `metadata.source_list` is present in place of `source_pack`.
- ☐ No list token was used to seed more than one entry (§5.0.3).
- ☐ Every `answer` sense is a standard, independently verifiable meaning of
  the lemma — not an adjacent or plausible-sounding gloss added without
  anchoring context (§5.0.1 gloss conservatism).

### Conjugation-only mode (when authored directly from a raw verb list)

- ☐ Every entry's `lemma` traces to a token literally present in the raw
  verb list, after the applicable §5.0 preprocessing steps.
- ☐ Any token that was a conjugated surface form, not already a citation
  form, was reduced to its dictionary lemma (§5.4) before authoring.
- ☐ A raw-list line already grouping multiple words was evaluated with the
  §5.5 compositionality test and, if a genuine fixed verb expression, kept
  as one entry (§6.7) rather than split into separate lemmas.
- ☐ No entry was generated for a defective or impersonal verb (§6.3).
- ☐ No list token was used to seed more than one entry (§5.0.3).
- ☐ `metadata.source_list` is present in place of `source_pack`.
- ☐ The completeness closure rule (§6.5) was checked across all entries in
  the pack exactly as it would be in the normal pipeline — this mode does
  not relax it.
- ☐ No Vocabulary pack was assumed or invented to exist; none is required
  by this mode, and none was silently fabricated to satisfy a rule written
  for the default pipeline.
  
**Coverage-accounting rule (clarified):**

Every lexical entity that survives preprocessing and candidate selection must
have exactly one documented destination. “Destination” does not always mean a
standalone record: inflected forms may be recorded under one lemma, and
components may be absorbed into one documented fixed expression under §5.5.
The required conservation check is therefore:

```text
surviving lexical entities
  = standalone entries
  + forms assigned to a lemma entry
  + components explicitly absorbed into a fixed expression
```

An entity intentionally excluded under §5.3 (for example, a transparent
single-use article) belongs in an exclusion log with the applicable rule and
is removed *before* this equation is checked. Any unexplained undercount,
double assignment, or duplicate standalone record is a critical validation
failure.

---

### Common LLM Failure modes

* Never silently discard an encountered lexical item.
* Never replace an encountered form with an inferred intermediate form unless the spec explicitly permits it.
* Every encountered form that survives preprocessing must either:
    * become an entry,
    * become a recorded form of another entry, or
    * be explicitly absorbed into a documented fixed expression.
* During §10 conformance, verify that every surviving token has exactly one destination.
  
### Semantic consistency

All generated packs **must not** contradict one another. 

* If Vocabulary says a verb is impersonal,
    Conjugation must not create a personal paradigm.
* If Translation identifies a word as a compound,
    Vocabulary should not analyze it differently.
* If Translation explains a grammatical construction,
    Vocabulary should not define it inconsistently.

### Final question

> Will this pack help the learner understand how the language works — not
> just what the sentence means?

If yes, the pack set is ready. If any checklist item above is unresolved,
fix it before presenting the result.

---

## 10. Conformance Pass (MANDATORY)

After generating all packs, perform one complete validation pass before emitting any YAML.

Translation

- all required fields present
- every chunk valid
- phonetics present where required
- accepted answers present where appropriate

Global (all packs, before any pack-specific checks below)

- every free-text value (`answer`, `prompt`, `target`, `literal`, `meaning`,
  `notes`, and any other quoted-or-not string field) has been re-scanned,
  as a distinct verification step separate from writing it, for a bare YAML
  1.1 reserved word (`yes`, `no`, `true`, `false`, `on`, `off`, `null`, `~`,
  in any case) per §3.1. This is not a rare edge case to watch for
  opportunistically — every one of these tokens is also an ordinary English
  word, so any `answer` value meaning "on," "off," "true," "false," "yes,"
  or "no" **will** trigger this exact failure if left unquoted, regardless
  of how unlikely it looks in context. Treat this as a mandatory scan of
  every affected field, not a spot-check.

Vocabulary

- every id is a lemma
- every vocabulary_ref resolves
- no prohibited entries
- no transparent cognate or identical/near-identical prompt-answer entry is
  included without a specific instructional `notes` item (§5.3)
- no duplicates
- every id preserves the lemma's NFC Unicode spelling and changes only the
  permitted separators (§5.8)
- every verb entry has a `'Stem: X'` note (§5.7.2b) if the language's
  Conjugation pack uses a top-level `stem` field (§6.2.1a) — for every
  verb entry if any, for none if the language has no bound-stem system

Conjugation

- every lemma exists in Vocabulary — or, in conjugation-only mode (§2.2),
  traces to the raw verb list after §5.0 preprocessing
- every entry has a `category` with both `key` and `label` present and
  non-empty (§6.2.1), unless the language has no inflectional-class system,
  in which case `category` is absent from every entry, not just some
- `key`/`label` pairs for the same class match exactly wherever they recur
- in the default pipeline, `notes` carries forward from the source
  Vocabulary entry's stem-alternation/inflectional-class note wherever one
  exists (§6.2.2), verbatim by default now that phrasing is lemma-specific
- every entry's top-level `stem`, if present, is present for every entry
  in the pack (§6.2.1a), including irregular verbs, and is never nested
  inside `category`
- every entry has a `gloss` matching its Vocabulary entry's primary sense
  (§6.2.1b)
- every person's `positive`/`negative` value is a `{forms, meaning}`
  object with `meaning` present for every person and polarity, or for
  none (§6.5.1)
- every nested `forms` item is one exact surface form; no item contains slash
  shorthand or parenthetical alternatives (§6.5.1)
- every paradigm is valid
- defective verbs handled correctly

**Value homogeneity:**

Every item in a nested Conjugation `forms` list must be an exact source-language
surface form. Metadata, commentary, target-language glosses, or operational
tokens are prohibited inside those lists. The sibling `meaning` field is
explicitly target-language learner text and is not subject to this
source-language-only restriction.


Word Explorer

- every entry's `source` fields match a real Translation entry/chunk
  exactly (§7.4)
- learner-facing fields use `word`/`base_word`, never `lemma`/`root` (§7.1)
- every `morphology.kind` is drawn from the controlled set (§7.5) and used
  consistently for the same concept throughout the pack
- every entry has exactly one `origin: source` exploration; all others are
  `origin: generated` and verified (§7.6)
- every non-`valid` exploration `status` carries a `usage_note` (§7.6)
- every application's `choices` exactly equals `answer.word` plus every
  `distractors[].word` (§7.7)
- every `vocabulary_ref` resolves to a real Vocabulary entry, or is absent
  (§7.9)
- every `grammar_refs` key resolves to this pack's own `grammar` catalog
  (§7.3)
- no Word Explorer entry contradicts its sibling Translation or Vocabulary
  entry (§7.10)
- every top-level `word` is an exact contiguous substring of its
  `source.text`; discontinuous or normalized constructions were not invented
  as encountered surface forms (§7.4)

Word Explorer Guide

- generated from the completed Word Explorer pack's YAML, not authored
  independently or drawn from the source text directly (§7.11)
- every populated category (Cases, Compounds, Derivations, Agreement, Passive
  forms, other Verb forms, and Irregular stems) is represented; empty
  categories are omitted (§7.11.1)
- category assignment follows §7.11.2, including the Irregular-stems
  cross-cutting rule
- every table cell traces to a specific field on its source entry (§7.11.3)
- every "Where it appears" excerpt matches the entry's actual `source.text`
- no invented chapter/lesson numbering and no reference to another pack's
  content, unless the Translation pack's own metadata establishes it as
  fact (§7.2, §7.11.1)

Cross-pack

- Translation is authoritative
- companion packs introduce no contradictions
- no orphan references
- every Conjugation top-level `stem` matches its source Vocabulary entry's
  `'Stem: X'` note exactly (§6.2.1a, §5.7.2b)
- every Conjugation `gloss` matches its source Vocabulary entry's primary
  `answer` sense (§6.2.1b)
- every Word Explorer `vocabulary_ref` resolves to the Vocabulary pack it
  claims to reference (§7.9)
- the Word Explorer Guide introduces no fact absent from the Word Explorer
  pack (§7.11.5)

---

## 11. Evaluation and scoring protocol

Use this section when evaluating an existing pack set. It makes evaluation
reproducible; it does not add authoring fields.

### 11.1 Evidence preflight

Before assigning scores:

1. Parse every YAML file and identify the specification revision used
   (version, date, or document hash when supplied).
2. Verify that every expected pack and Guide is present and that files are
   complete rather than truncated.
3. Build cross-reference maps for pack ids, entry ids, chunk ids,
   `vocabulary_refs`, `vocabulary_ref`, and grammar keys.
4. Separate findings into three evidence classes:
   - **conformance** — a testable MUST/required/closure rule;
   - **linguistic quality** — correctness or naturalness requiring language
     knowledge; and
   - **optional enrichment** — a permitted improvement whose absence is not a
     violation.
5. Cite every conformance finding by file, entry/chunk id (or line), field,
   and specification section. If the source material needed to judge exact
   coverage was not supplied, mark that check **not assessable** rather than
   assuming failure or success.

Optional enrichment may affect educational-value judgment modestly, but must
never be reported as a schema violation or scored as though it were required.
A validator must implement the required/optional boundary stated by this
document; stricter legacy validator behavior is evidence of validator drift,
not automatically evidence that the pack violates this specification.

### 11.2 Score scale

Score each applicable category from `0.0` to `10.0`, to one decimal place:

| Band | Meaning |
|---|---|
| `9.0–10.0` | Excellent: accurate, complete, consistent; only negligible issues |
| `7.0–8.9` | Good: usable and educational, with limited non-critical issues |
| `5.0–6.9` | Mixed: useful core, but repeated errors or one material gap |
| `3.0–4.9` | Poor: major omissions or errors substantially impair use |
| `0.0–2.9` | Failing: absent, unusable, or pervasively incorrect |

Start from evidence, not from `10` minus an arbitrary number of comments.
Repeated instances of one systematic defect should weigh more than one typo,
but should not be counted as unrelated defects. A critical structural failure
caps the directly affected category at `4.9`; a missing required companion
caps Companion integration and Pack consistency at `2.9`. Mark a category
`N/A` only when the source legitimately contains no applicable material (for
example, no conjugatable verb); do not convert `N/A` to zero. The overall score
is the unweighted mean of applicable categories unless an evaluation brief
states a different weighting in advance.

### 11.3 Category boundaries

| Category | Primary evidence |
|---|---|
| Translation quality | Fidelity of `source`, structural usefulness of `literal`, fluency and meaning of `target`/`accepted` |
| Chunking | Complete ordered coverage and the operational semantic-boundary test in §4.3 |
| Grammar hints | Accuracy, contextual usefulness, non-duplication, and not revealing the answer |
| Vocabulary quality | Candidate floor/exclusions, lemma identity, meanings, types, forms, and notes |
| Pack consistency | Cross-file identities, shared meanings/classifications, and absence of contradictions |
| Metadata | Required fields, correct types/source links, stable ids, and no invented course context |
| Companion integration | Resolved references and faithful Conjugation/Word Explorer/Guide derivation |
| Educational value | Scaffolding, useful contrasts, concision, coverage accounting, and learner-facing clarity |
| Conjugation accuracy | Candidate eligibility, class, paradigm forms, polarity, meanings, variants, and multi-word head behavior |

For each score, provide a one- or two-sentence evidence summary plus the most
important cited finding. Also report at least five strengths and five
weaknesses for the set as a whole; strengths must be evidenced features, and
weaknesses must distinguish violations from optional improvements.
