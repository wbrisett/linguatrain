# Changelog

All notable changes to Linguatrain are documented in this file.

The format is loosely based on **Keep a Changelog**, with releases grouped by
version.

---

## [1.2.1] 2026-07-22

### Added

- Add missed-answer explanations to conjugation drills when packs provide verb
  type, stem, and notes metadata.
- Add shuffled conjugation entry selection so drills no longer follow the YAML
  file order by default.
- Add `subjects` as the preferred conjugation pack field while retaining
  backwards compatibility with legacy `persons` packs.
- Add optional per-step `instruction` text for transform drills so packs can
  show clearer prompts than the generic transform label.
- Add translation study/read-through mode via `--study --translation`.
  This walks through translation packs without scoring, showing source text,
  chunks, literal renderings, natural translations, hints, and optional
  pronunciation.

### Updated

- Expand and clarify the Linguatrain LLM Authoring Specification for
  translation and companion-pack generation.
- Accept conjugation stems with or without a trailing hyphen in stem drills.
- Prefer `source` and `target` names for `--match-options`, while still
  accepting the older `fi` and `en` aliases.
- Accept transform entry `notes` in pack validation, matching the runtime and
  authoring docs.
- Document missed-answer conjugation explanations in the options reference and
  conjugation authoring guide.
- Document the `--study --translation` combination in the usage guide and
  options reference.

### Fixed

- Fix conjugation category-identification option handling so legacy aliases are
  normalized and category filtering uses `--category KEY`.

---

## [1.2.0] - 2026-07-14

This release introduces Word Explorer and completes a major pass over
Linguatrain's content-authoring system. Linguatrain now has a clearer path from
source material to structured Translation, Vocabulary, Conjugation, and Word
Explorer packs, with documentation written for human authors and a dedicated
specification for LLM-assisted content generation.

### Added

- Add the new Word Explorer module (`--word-explorer`) for exploring word forms
  in context.
- Add Word Explorer learning modes:
  - `--recognize` for matching encountered forms to their base words.
  - `--apply` for choosing the correct form in sentence context.
  - `--build` for producing forms from base words and prompts.
- Add Word Explorer YAML loading and exercise support.
- Add a Word Explorer pack template and canonical Finnish Word Explorer example.
- Add a generated Word Explorer Guide example.
- Add Word Explorer validation support to `validate_pack.rb`.
- Add the Linguatrain LLM Authoring Specification for generating Translation,
  Vocabulary, Conjugation, Word Explorer, and Word Explorer Guide content.
- Add a Word Explorer design specification documenting the feature philosophy,
  schema decisions, modes, and guide behavior.
- Add a subtitle-to-text helper tool for preparing source material.

### Updated

- Rewrite and expand the Translation Authoring Handbook so it works as a
  practical human authoring guide.
- Update the canonical Finnish Translation, Vocabulary, and Conjugation examples
  so they form a coherent companion content set.
- Update `build_yaml.rb` and its instructions for the current authoring
  workflow.
- Clarify the relationship between Translation, Vocabulary, Conjugation, Word
  Explorer, and generated guides.
- Update the README to describe Word Explorer and Linguatrain's content-first
  learning philosophy.

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
