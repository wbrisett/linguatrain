# Linguatrain Pack Flipper (`flip_pack.rb`)

A utility script for generating a **reversed standard pack** from an existing Linguatrain YAML pack.

Instead of relying only on runtime reverse mode, this script creates a new pack file where the study direction is physically flipped:

- original `answer` values become the new `prompt`
- original `prompt` values become the new `answer`

This is useful when you want a **real reverse-direction pack** that can be edited, versioned, reviewed, and studied independently.

---

## What This Script Does

`flip_pack.rb` reads a standard Linguatrain YAML pack and writes out a flipped version.

### Example

## Original
```yaml
metadata:
  id: "fi_food"
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: "porridge"
    answer:
      - "puuro"
```

## Flipped
```yaml
metadata:
  id: "fi_food"
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: "puuro"
    answer:
      - "porridge"
```

---

## Why You Would Want to Use This

There are several cases where a flipped pack is better than simply using a runtime `--reverse` option.

### 1. Separate Study Assets
A flipped pack becomes its own file. That means you can:
- keep it in version control
- share it
- review it
- edit it independently

### 2. Independent SRS Behavior
If your workflow depends on pack structure rather than a runtime flag, a flipped pack gives you a true reverse-direction asset.

### 3. Better Editing Control
Sometimes the reverse direction needs different wording, different prompts, or cleanup after flipping. A generated flipped file gives you something concrete to refine.

### 4. Safer Multi-Answer Handling
This script expands entries with multiple answers into separate flipped entries, which is usually the cleanest way to reverse them.

Example:

## Original
```yaml
- id: "010"
  prompt: "hello"
  answer:
    - "hei"
    - "terve"
```

## Flipped
```yaml
- id: "010_1"
  prompt: "hei"
  answer:
    - "hello"

- id: "010_2"
  prompt: "terve"
  answer:
    - "hello"
```

That makes the reversed pack easier to study and easier to validate.

---

## Scope

This script supports:

- **standard word packs only**

It does **not** support:

- transform packs
- conjugate packs

If the pack metadata contains:

```yaml
drill_type: transform
```

or

```yaml
drill_type: conjugate
```

the script exits with an error.

---

## Safety Behavior

This script was designed to be safer than a naïve prompt/answer swap.

### It uses `YAML.safe_load`
This avoids unsafe YAML loading behavior.

### It does not overwrite by default
Unless you explicitly choose `--in-place`, it writes a new file.

### It rejects unsupported pack types
This prevents accidental corruption of transform or conjugation data.

### It removes direction-specific fields
When flipping a standard pack, the following fields are removed from each entry:

- `phonetic`
- `spoken`
- `alternate_prompts`

That is intentional. These fields often depend on the original direction and would usually be misleading or incorrect after flipping.

---

## Output File Behavior

By default, the script writes:

```text
<original_name>_flipped.yaml
```

Example:

```text
fi_food.yaml
```

becomes:

```text
fi_food_flipped.yaml
```

You can also choose:
- overwrite the input file with `--in-place`
- write to a specific file with `--output PATH`

---

## Usage

## Basic Usage
```bash
ruby flip_pack.rb path/to/pack.yaml
```

This writes a new file beside the original:

```text
path/to/pack_flipped.yaml
```

## Write to a Specific Output File
```bash
ruby flip_pack.rb path/to/pack.yaml --output path/to/reversed_pack.yaml
```

## Overwrite the Input File
```bash
ruby flip_pack.rb path/to/pack.yaml --in-place
```

Use this carefully.

## Show Help
```bash
ruby flip_pack.rb --help
```

---

## How the Script Handles Data

### Prompts
A prompt may be:
- a string
- an array

If it is a string, it becomes a one-item answer array in the flipped output.

### Answers
An answer may be:
- a string
- an array

If there are multiple answers, the script creates one flipped entry per answer.

### IDs
If an entry has only one answer, its ID is preserved.

If an entry has multiple answers, the script appends a suffix:

- `001_1`
- `001_2`
- `001_3`

This avoids collisions and keeps the flipped output deterministic.

---

## Example Walkthrough

## Input
```yaml
metadata:
  id: "fi_small_talk"
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: "thank you"
    answer:
      - "kiitos"

  - id: "002"
    prompt: "hello"
    answer:
      - "hei"
      - "terve"
    phonetic: "HEI"
    spoken:
      - "hei"
```

## Output
```yaml
metadata:
  id: "fi_small_talk"
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: "kiitos"
    answer:
      - "thank you"

  - id: "002_1"
    prompt: "hei"
    answer:
      - "hello"

  - id: "002_2"
    prompt: "terve"
    answer:
      - "hello"
```

Notice:
- `phonetic` was removed
- `spoken` was removed
- multiple answers were split into separate entries

---

## When This Script Is a Good Choice

Use `flip_pack.rb` when you want:

- a real reverse-direction YAML pack
- a file you can check into Git
- a pack you can hand-edit after flipping
- multi-answer reversal handled cleanly
- a safer alternative to a quick one-line data swap

It is especially useful when building study assets that you want to maintain long term.

---

## When Not to Use It

Do not use this script for:

- transform packs
- conjugation packs
- any pack where reverse-direction phonetics or notes need to be preserved automatically

In those cases, a purpose-built transformation would be better.

---

## Summary

`flip_pack.rb` is a practical utility for turning a standard Linguatrain pack into a clean reverse-direction pack.

It is useful because it gives you:

- a maintainable flipped YAML file
- cleaner handling of multiple answers
- safer pack generation
- explicit control over output

In short, this script is for cases where you want a **real reversed pack**, not just a temporary reversed quiz session.
