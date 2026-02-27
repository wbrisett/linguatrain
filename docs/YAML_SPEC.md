# Linguatrain YAML Specification

Version 0.1 (Draft)

## 1. Overview

Linguatrain uses structured YAML data packs to define language training
content.

Each pack defines:

-   A source language\
-   A target language\
-   A collection of recall entries\
-   Optional metadata for learning behavior

The engine operates on structured recall between `source_lang` and
`target_lang`.

------------------------------------------------------------------------

## 2. Top-Level Structure

Each YAML file MUST define a `metadata` block and an `entries` list.

### Example

``` yaml
metadata:
  pack_name: "Finnish Basics"
  version: 1
  source_lang: "en"
  target_lang: "fi"
  author: "Wayne Brissette"
  description: "Core beginner vocabulary"

entries:
  - id: 001
    prompt: "It is cold."
    answer:
      - "On kylmä."
```

------------------------------------------------------------------------

## 3. Required Fields

### 3.1 Metadata Fields

  Field         Required   Description
  ------------- ---------- ---------------------------------
  pack_name     Yes        Human-readable name of the pack
  version       Yes        Integer schema version number
  source_lang   Yes        ISO 639-1 language code
  target_lang   Yes        ISO 639-1 language code

### 3.2 Entry Fields

Each entry MUST contain:

``` yaml
- id: <unique identifier>
  prompt: <string>
  answer:
    - <accepted answer>
```

Requirements:

-   `id` must be unique within the file\
-   `prompt` must be a string\
-   `answer` must be a list (even if only one answer)

------------------------------------------------------------------------

## 4. Optional Entry Fields

Entries MAY include additional structured metadata.

### Example

``` yaml
- id: 002
  prompt: "It is below zero."
  answer:
    - "On pakkasta."
  phonetic: "on pahk-kah-stah"
  notes: "Used for temperatures below 0°C"
  tags:
    - weather
    - temperature
  audio:
    tts: true
  srs:
    difficulty: 2
```

### Optional Fields

  Field      Type     Purpose
  ---------- -------- -------------------------
  phonetic   string   Pronunciation guide
  notes      string   Learning context
  tags       list     Categorization labels
  audio      object   Audio playback options
  srs        object   Spaced repetition hints

------------------------------------------------------------------------

## 5. Answer Handling

-   Answers are evaluated case-insensitively by default.\
-   Multiple accepted answers must be defined as a list.\
-   Future versions may support strict matching modes.

### Example

``` yaml
answer:
  - "Hyvää huomenta"
  - "Huomenta"
```

------------------------------------------------------------------------

## 6. Directionality

The engine may operate in multiple modes:

-   source → target\
-   target → source\
-   guided recall\
-   listening mode

Packs must support bidirectional recall unless explicitly restricted in
metadata.

------------------------------------------------------------------------

## 7. File Organization

Recommended pack structure:

    packs/
      fi/
        basics.yaml
      es/
        travel.yaml

Each file should contain one `metadata` block and one `entries` list.

------------------------------------------------------------------------

## 8. Versioning

-   `version` refers to the data pack schema version.\
-   Breaking schema changes must increment the version number.\
-   The engine must validate compatibility before loading a pack.

------------------------------------------------------------------------

## 9. Future Extensions (Reserved)

The specification reserves space for:

-   Grammar drills\
-   Multi-field prompts\
-   Cloze deletions\
-   Morphological variations\
-   Regional dialect variants

Future additions should remain backward-compatible whenever possible.
