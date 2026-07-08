# YAML Pack Schema

## Top-Level Structure

```yaml
metadata:
  id: "pack_id"
  version: 1
entries:
  - id: "001"
    prompt: "Example prompt"
    answer:
      - "Example answer"
    phonetic: ""
```

------------------------------------------------------------------------

## Metadata (`metadata`)

The `metadata` block defines pack-level information and schema versioning.

## `id`

**Type:** string\
**Required:** Yes

Unique identifier for the pack.

-   Must be unique within your collection of packs.
-   Used internally for tracking and future extensibility.
-   Should remain stable once published.

------------------------------------------------------------------------

## `version`

**Type:** integer
**Required:** Yes
**Current supported value:** `1`

Defines the schema version.

Until a schema revision is announced, this should always be set to `1`.

------------------------------------------------------------------------


## Entries Schema

The `entries` array defines the learning items contained in the pack.

Each entry represents a prompt/answer pair with optional pronunciation guidance. Multiple answers may be provided, and any listed answer will be accepted as correct.

------------------------------------------------------------------------

## Entry Structure

```yaml
- id: "001"
  prompt: "Example prompt in source language."
  answer:
    - "Example answer in target language."
    - "alternative answer in target language."     
  phonetic: ""
```

Multiple answers can be provided. Any value in the list will be accepted as a correct answer.

------------------------------------------------------------------------

## Field Reference

### `id`

**Type:** string
**Required:** Yes

Unique identifier within the pack.

-   Must not be duplicated.
-   Used for SRS tracking and missed-pack generation.
-   Recommended format: zero-padded strings (`"001"`, `"002"`).

------------------------------------------------------------------------

### `prompt`

**Type:** string
**Required:** Yes
**Purpose:** The text shown to the user in the *source language*.

Behavior depends on mode:

-   In `typing` mode: prompt is shown; you type target language.
-   In `reverse` mode: target language is shown or spoken; you type in source.
-   In `match-game`: prompt anchors hint selection.
-   In `listen` mode: prompt may be spoken if TTS is enabled. This is overridden if localisation is used.

This field should contain natural, learner-facing text.

------------------------------------------------------------------------

### `answer`

**Type:** list of strings\
**Required:** Yes (must always be a list)

Even if only one accepted answer exists, it must be defined as a YAML
list:

```yaml
answer:
  - "Hyvää huomenta"
```

Multiple accepted answers:

```yaml
answer:
  - "Hei"
  - "Moi"
```

The engine will accept any string in the list as correct input.

------------------------------------------------------------------------

### `phonetic`

**Type:** string
**Required:** No
**Purpose:** Provides pronunciation guidance.

The phonetic value is displayed when:

- phonetic display is enabled in the UI configuration
- the correct answer is revealed

Example:

```yaml
phonetic: "HY-vah"
```

If this field is omitted or empty, no pronunciation hint will be displayed.
