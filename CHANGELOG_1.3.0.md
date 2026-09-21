# Linguatrain 1.3.0

## Added

- Add a standalone Finnish Locative Cases module for complete-sentence
  production practice.
- Add support for all six Finnish locative cases: illative, inessive, elative,
  allative, adessive, and ablative.
- Add `--locative-cases` for practising complete Finnish sentences from English
  prompts.
- Add `--locative-question`, `--locative-case`, and `--locative-family` filters
  so exercises can focus on `mihin`, `missä`, `mistä`, individual grammatical
  cases, or the internal (`S`) and external (`L`) case families.
- Add progressive exercise assistance. Learners can use `h` to reveal the
  directional question, case family, grammatical case, and target form one
  step at a time, or `r` to reveal the complete answer.
- Add first-attempt, retry, and revealed-answer results, including a review list
  of missed exercises.
- Add a dedicated YAML schema that groups complete sentence productions by
  location lemma and locative family while retaining source provenance and
  learner-facing explanations.
- Add automatic Locative Cases pack detection and dedicated validation through
  `bin/validate_pack.rb --locative-cases`.
- Add validation for required fields, stable identifiers, answer lists, family
  codes, and the correct relationship between locative family, directional
  question, and grammatical case.
- Add a canonical Finnish Locative Cases example pack derived from *Suomen
  mestari 1*, Kappale 6 material.
- Add automated tests covering pack loading, filtering, scoring, exercise
  interaction, command-line behavior, and validation.

## Updated

- Require accurate Finnish diacritics in Locative Cases exercises.
  `--lenient-umlauts` is not supported because diacritics can change a word's
  meaning and grammatical form.
- Update the main README for Version 1.3.0 with an introduction to the Locative
  Cases module and its sentence-production learning model.
- Expand the Setup and Usage Guide and command-line options reference with
  Locative Cases commands, filters, hints, and examples.
- Expand the pack-validation documentation with Locative Cases validation
  instructions and schema rules.
- Expand the Translation Authoring Handbook's copy-ready full-pack prompt to
  include the canonical Locative Cases YAML file when producing Finnish
  learning material.
- Expand the LLM Authoring Specification so suitable Finnish full-pack sets
  include a Locative Cases companion pack automatically.
- Add detailed authoring requirements for source grounding, provenance,
  candidate coverage, natural sentence production, and production-specific
  explanations.
- Add module documentation explaining the YAML schema, learning model, filters,
  strict diacritics, authoring rules, validation, and automated test workflow.
