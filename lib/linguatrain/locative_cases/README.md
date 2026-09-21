# Locative Cases Module

Locative Cases is a standalone Linguatrain module for practicing the mechanics
of Finnish location forms through complete-sentence production.

The learner receives an English prompt and writes the entire Finnish sentence.
The exercise does not present suffix blanks and does not modify sentences at
runtime. Every prompt, accepted sentence, target form, and explanation is
authored and reviewed before practice.

## Learning Model

An entry groups natural sentence variants around one location lemma and one
locative family. This resembles a conjugation paradigm, but each production is
a complete sentence with a distinct meaning.

```text
Lehtelä
  mihin?  → Lehtelään  → Juna menee Lehtelään.
  missä?  → Lehtelässä → Juna on Lehtelässä.
  mistä?  → Lehtelästä → Juna lähtee Lehtelästä.
```

The six supported Finnish locative cases are:

| Family | To (`mihin`) | In/at (`missä`) | From (`mistä`) |
|---|---|---|---|
| Internal (`S`) | illative | inessive | elative |
| External (`L`) | allative | adessive | ablative |

## Running an Exercise

```bash
ruby bin/linguatrain.rb \
  lib/linguatrain/locative_cases/examples/suomen_mestari_1_kappale_6_locative_cases.yaml \
  all --locative-cases
```

The optional positional count limits the number of flattened productions:

```bash
ruby bin/linguatrain.rb pack.yaml 3 --locative-cases
```

## Practice Filters

Filter by the Finnish location question:

```bash
ruby bin/linguatrain.rb pack.yaml all --locative-cases --locative-question mihin
```

Filter by grammatical case:

```bash
ruby bin/linguatrain.rb pack.yaml all --locative-cases --locative-case inessive
```

Filter by family using either its code or name:

```bash
ruby bin/linguatrain.rb pack.yaml all --locative-cases --locative-family S
ruby bin/linguatrain.rb pack.yaml all --locative-cases --locative-family external
```

Repeated values within one dimension are alternatives. Different dimensions
are combined:

```bash
# mihin OR mistä
ruby bin/linguatrain.rb pack.yaml all --locative-cases \
  --locative-question mihin --locative-question mistä

# internal AND inessive
ruby bin/linguatrain.rb pack.yaml all --locative-cases \
  --locative-family S --locative-case inessive
```

## Exercise Assistance

The case is not displayed initially. The English prompt must first communicate
the required relationship. Help becomes progressively more explicit:

1. `mihin`, `missä`, or `mistä`;
2. family code and grammatical case;
3. the target inflected form;
4. the complete authored sentence.

Type `h` for the next hint, `r` to reveal the answer, or `q` to quit.

## Diacritics

Finnish diacritics are required. `--lenient-umlauts` is not supported with
`--locative-cases` because diacritics can change meaning and grammatical form.
Capitalization, punctuation, and whitespace are normalized, but `a` is never
treated as `ä`, and `o` is never treated as `ö`.

## YAML Schema

```yaml
metadata:
  id: "example_locative_cases"
  title: "Example Locative Cases"
  type: "locative_cases"
  practice: "sentence_production"
  version: 1
  schema_version: 1

entries:
  - id: "train_lehtela"
    lemma: "Lehtelä"
    family: "internal"
    family_code: "S"
    source:
      text: "Juna menee Lehtelään."
      reference: "Lesson reference"
    productions:
      - id: "to_lehtela"
        question: "mihin"
        case: "illative"
        prompt: "A train goes to Lehtelä."
        answer:
          - "Juna menee Lehtelään."
        target_form: "Lehtelään"
        explanation: "Lehtelään means 'to Lehtelä'; the illative marks the train's destination in this sentence."
```

### Entry Fields

| Field | Requirement | Purpose |
|---|---|---|
| `id` | required | Stable identifier for the grouped sentence family. |
| `lemma` | required | Base location form. |
| `family` | required | `internal` or `external`. |
| `family_code` | required | `S` for internal or `L` for external. |
| `source` | optional | Provenance for the real sentence or lesson that motivated the group; it does not prove that every authored production occurs verbatim. |
| `productions` | required | One or more complete-sentence exercises. |

### Production Fields

| Field | Requirement | Purpose |
|---|---|---|
| `id` | required | Stable identifier unique within the group. |
| `question` | required | `mihin`, `missä`, or `mistä`. |
| `case` | required | The grammatical case matching the family and question. |
| `prompt` | required | Natural English prompt shown to the learner. |
| `answer` | required | List of accepted complete Finnish sentences. |
| `target_form` | required | Inflected location form taught by this production. |
| `explanation` | optional | Short learner-facing explanation shown on reveal. |

## Source Grounding and Provenance

Grammatical correctness alone is not sufficient for an authored production.
Before finalizing a pack, classify each production during review as either:

- **source-attested** — the complete Finnish answer occurs verbatim in the
  supplied source; or
- **authored** — the answer is a new, verified sentence derived from
  source-established material.

This classification is an authoring audit rather than a serialized YAML field.
An attested target form inside a newly written sentence does not make that
whole sentence source-attested. Do not write `exactly as attested`, `as the
text states`, `used by the characters`, or a similar provenance claim unless
the exact source supports the complete claim and its speaker or narrator
attribution.

For every authored production, keep an evidence record in this form:

```text
production id → source entry/chunk or exact quotation → preserved fact
```

The evidence must support the new proposition's participant, object, location,
and spatial frame. A changed direction may be a transparent pedagogical
hypothetical — one source relationship can motivate the other two members of a
case triple — but the hypothetical must not be described as an event attested
in the story. Grammatical plausibility alone is not evidence. If a directly
attested proposition is available, prefer it over a weaker inference or a
recombination of details from unrelated sentences.

An authored production may change the locative relationship and the grammar
needed to express it, but it must preserve a coherent source-established
scenario. Its people, objects, identities, roles, and relationships must come
from the supplied material. Do not silently introduce a new content word or
turn a named person into a child, student, employee, or other plausible but
unstated identity merely to complete a case triple.

When the source contains a proposition directly modeling the needed
relationship, prefer it over recombining elements from weaker or unrelated
evidence. Canonical examples are schema and style references, not sentence
banks: independently justify any identical or near-identical production from
the current source.

## Explanation Quality

Every explanation should identify:

1. what the target form means in the production;
2. why its locative family and case fit the prompt; and
3. how the case relates to the particular action or spatial scene.

Apply a substitution test: if an explanation could be reused for another
location by changing only the form and case name, it is too generic. This is a
conformance failure, not merely a style preference.

```yaml
# Too generic
explanation: "Pihalle is the external mihin form for movement to the location."

# Source-specific
explanation: "Pihalle means 'into the yard'; piha uses the external family, and the allative marks the van's movement into the open yard area."
```

## Coverage Accounting

Inventory the useful location lemmas in the source before selecting entries.
When a companion Vocabulary pack exists, also collect every noun whose `forms`
records an inessive, illative, elative, adessive, allative, ablative, or other
clearly locative form. The union of the source scan and Vocabulary scan is the
default candidate list.

Include forms central to a source proposition, forms that demonstrate a new
family or stem behavior, and lemmas that support three natural grounded
contrasts. Keep an authoring-time exclusion log for every candidate left out,
with a pedagogical or naturalness reason. The log is not part of the YAML, but
it makes a narrow scope an explicit editorial choice rather than an accidental
omission. In an interactive workflow, show the candidate list and proposed
exclusions to the human author before generating the full pack.

## Authoring Rules

- Author natural complete sentences, not suffix-completion exercises.
- Give every change in locative meaning its own English prompt and Finnish
  answer. Do not reuse a prompt whose meaning no longer matches the case.
- Group productions only when they share the same lemma and locative family.
- Do not force a location through both S and L families merely to complete a
  table. Use the family natural to that place and meaning.
- Store every accepted answer as a complete sentence. A bare target form is
  not an accepted answer.
- Add alternatives only when they are genuinely natural equivalents of the
  complete prompt.
- Preserve the real sentence or lesson reference that motivated the practice
  group so authored variants can be reviewed against their source context.
- Audit every production as source-attested or authored; never describe an
  authored sentence as attested merely because its target form occurs in the
  source.
- Map every authored production to an exact source entry/chunk or quotation and
  state the attested fact preserved. A directional contrast may be a transparent
  hypothetical, but its semantic frame must remain source-supported and it must
  not be described as an attested event.
- Keep every authored sentence inside a coherent semantic frame established by
  the source, with no invented identity, role, object, or relationship.
- Use source-attested content lemmas. If a new content lemma is genuinely
  unavoidable, document it for human review rather than adding it silently.
- Prefer a directly attested proposition over a plausible recombination of
  participants and locations from unrelated source sentences.
- Write explanations that include contextual meaning, case/family reason, and
  the production-specific action or spatial relationship. An explanation that
  differs from another only by swapped form and case names is a conformance
  failure and must be rewritten.
- Treat canonical examples as structural references and independently justify
  any identical or near-identical sentence from the current source.
- Build the candidate inventory from both the source and locative forms in the
  companion Vocabulary pack, and record why every excluded candidate was left
  out.
- Verify every Finnish sentence and inflected form before practice.

## Validation

```bash
ruby bin/validate_pack.rb --locative-cases pack.yaml
```

The validator checks required fields, identifiers, answer-list shape, family
and family-code consistency, and the correct relationship between each
question and grammatical case. Source provenance, semantic grounding,
explanation specificity, and candidate coverage still require the manual
authoring audits above.

## Development and Automated Tests

The files in the repository's top-level `test/` directory are automated
development tests for the Locative Cases module. They are not practice packs
or commands that learners need during ordinary use. They exist to catch
regressions when the module, command-line interface, validator, or canonical
example is changed.

The test files cover different parts of the module:

| Test file | What it verifies |
|---|---|
| `test/locative_cases_pack_test.rb` | YAML normalization, stable production identifiers, inherited entry metadata, filtering, and rejection of malformed entries. |
| `test/locative_cases_scorer_test.rb` | Complete-sentence matching, normalization of capitalization and punctuation, and strict Finnish diacritics. |
| `test/locative_cases_exercise_test.rb` | First-attempt and retry scoring, progressive hints, answer reveal with `r`, and quitting with `q`. |
| `test/locative_cases_cli_test.rb` | End-to-end command-line behavior, mode selection, filters, count limits, and rejection of `--lenient-umlauts`. |
| `test/locative_cases_validator_test.rb` | Acceptance of valid packs and detection of invalid family, question, and grammatical-case combinations. |

### Running the Complete Suite

From the repository root, run:

```bash
ruby -Itest -e 'Dir["test/locative_cases_*_test.rb"].sort.each { |file| require_relative file }'
```

Minitest prints the number of runs and assertions. A successful run ends with
zero failures, zero errors, and zero skipped tests. Any failure includes the
test name, the expected behavior, and the observed result.

### Running One Test File

Run a single file while working on one area. For example, after changing answer
comparison or diacritic handling, run:

```bash
ruby -Itest test/locative_cases_scorer_test.rb
```

Replace the filename with any of the five test files listed above. Running one
file gives faster, more focused feedback, but the complete suite should still
be run before publishing or committing a change.

### When to Run the Tests

Run the suite after:

- changing code under `lib/linguatrain/locative_cases/`;
- changing Locative Cases options or routing in `linguatrain.rb`;
- changing Locative Cases validation in `bin/validate_pack.rb`;
- updating the canonical example pack used by the tests; or
- fixing a bug, so the corresponding test can demonstrate that it does not
  return later.

Pack validation and automated tests serve different purposes. Run
`bin/validate_pack.rb` to check the structure of a particular authored YAML
pack. Run the automated tests to check that Linguatrain itself continues to
load, filter, validate, score, and present Locative Cases exercises correctly.

## Module Boundary

Locative Cases owns this sentence-production workflow. It does not call or
extend Translation, Word Explorer, Sentence Explorer, Transform, or
Conjugation. Shared conventions are reused only where they improve consistency.
