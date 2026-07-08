# Changelog

All notable changes to Linguatrain are documented in this file.

The format is loosely based on **Keep a Changelog**, with releases grouped by
version.

---

## [1.1.5] – 2026-07-08

This release completes the first generation of the Translation authoring
ecosystem. Translation packs can now be accompanied by canonical Vocabulary and
Conjugation packs, allowing both human authors and LLMs to generate complete,
consistent learning content from a single source document.

* Introduce canonical Conjugation YAML format.
* Expand the Translation Authoring Handbook to support generation of complete companion Translation, Vocabulary, and Conjugation packs.
* Add canonical Conjugation YAML example.
* Improve canonical Translation and Vocabulary examples.
* Clarify semantic chunking guidance.
* Clarify vocabulary extraction rules.
* Clarify conjugation generation rules.
* Improve guidance for grammar and vocabulary references.
* Add LLM authoring guardrails to improve schema consistency.
* Add examples of common YAML authoring pitfalls and their correct forms.
* Clarify handling of symbolic values versus lexical vocabulary.
* Improve pronunciation (`phonetic`) documentation and examples.

---

## [1.1.4] - 2026-06-31

- Add optional `phonetic` field to translation entries and chunks.
- Preserve pronunciation data when loading translation packs.
- Add `--show-phonetic` translation option.
- Display pronunciation progressively:
  - full sentence at exercise start
  - missed chunks after incorrect answers
  - remaining chunks during retry
  - full sentence when showing the answer
- Improve pronunciation UI with aligned block formatting.
- Update translation authoring guide with pronunciation guidance.
- Add phonetic examples to the sample translation pack.

---

## [1.1.2] - 2026-06-30

- Vocabulary study now supports contextual learning notes.
- Vocabulary YAML supports notes/note fields.
- Study mode displays learner notes.
- Quiz mode displays notes after incorrect answers.
- Improved terminal presentation of notes.
- Updated authoring guide to generate companion vocabulary packs alongside translation packs.

---

## [1.1.1] – 2026-06-29

- Removed references in exercise.rb to classes never developed.

---


## [1.1.0] – 2026-06-29

This release introduces the Translation module and significantly expands the
documentation and authoring ecosystem.

### Added

- Translation learning mode (`--translation`)
- Translation YAML schema
- Translation Authoring Guide
- Canonical Translation YAML example
- Minimal and complete Translation YAML templates

### Updated

- Reorganized repository documentation
- Rewrote the README to focus on the overall architecture of Linguatrain
- Converted the previous README into a dedicated User Guide
- Expanded documentation for content authors
- Improved project organization and documentation structure

---

## [1.0.4] – 2026-03-26

### Added

- Conversation authoring utility

### Updated

- Repository cleanup
- Improved YAML validation
- Added README documentation for project utilities

---

## [1.0.3] – 2026-03-12

This release expands Linguatrain beyond vocabulary drills into grammar and
speech production.

### Added

- Speech recognition using Whisper (`--speak`)
- Verb conjugation drills (`--conjugate`)
- Sentence transformation exercises (`--transform`)

---

## [1.0.2] – 2026-03-04

### Updated

- Reorganized the README for improved clarity
- Moved detailed documentation into the `docs/` directory
- Fixed minor issues throughout the codebase

---

## [1.0.1] – 2026-03-03

### Added

- Study mode for learning new words and phrases

Can be combined with:

- `--listen`
- `--reverse`

### Updated

- Updated README documentation
- Updated YAML specification to match the implementation