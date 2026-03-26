# build_yaml.rb

Interactive CLI utility to create Linguatrain YAML packs without
hand-editing templates.

------------------------------------------------------------------------

## Overview

`build_yaml.rb` is a guided pack builder. It walks you through creating
a **standard Linguatrain pack** and outputs valid YAML compatible with
`validate_pack.rb`.

It is designed to: - reduce YAML errors - speed up pack creation -
provide a clean "blank page" workflow

------------------------------------------------------------------------

## Features (current version)

-   Interactive CLI wizard

-   Standard pack support

-   Auto-generated zero-padded entry IDs (`001`, `002`, ...)

-   Multiple accepted answers per entry

-   Optional fields:

    -   `alternate_prompts`
    -   `spoken`
    -   `phonetic`
    -   `tags`
    -   `author`
    -   `description`

-   Smart loop behavior:

    -   blank prompt → confirm exit
    -   blank optional fields → skip

-   Output validation hint after creation

-   File header with version:

        # created with build_yaml version dev_01

------------------------------------------------------------------------

## Usage

### Basic (interactive)

``` bash
ruby build_yaml.rb
```

You will be prompted for: - output filename - metadata - entries

*Note:* When providing the output filename, use the full path. 

------------------------------------------------------------------------

### With output file (recommended)

``` bash
ruby build_yaml.rb packs/fi/my_pack.yaml
```

or

``` bash
ruby build_yaml.rb --output packs/fi/my_pack.yaml
```

This skips the filename prompt.

------------------------------------------------------------------------

## Output Requirements

The output filename **must**: - end in `.yaml` or `.yml` - include a
filename (not just a directory)

Example:

``` bash
packs/fi/greetings.yaml   # ✅ valid
packs/fi/                # ❌ invalid
```

------------------------------------------------------------------------

## Entry Flow

Example session:

    Entry 001
    Prompt: Hello
    Answer 1: Hei
    Answer 2 (optional): Moi
    Alternate prompt: Hi
    Phonetic: hay / moy

    Entry 002
    Prompt: Good morning
    Answer 1: Hyvää huomenta

    Entry 003
    Prompt:
    Finish and write 2 entries? [y/N]

------------------------------------------------------------------------

## YAML Output Example

``` yaml
# created with build_yaml version dev_01
metadata:
  id: greetings
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: Hello
    answer:
      - Hei
      - Moi
    phonetic: hay / moy
```

------------------------------------------------------------------------

## Validation

After building a pack:

``` bash
ruby bin/validate_pack.rb packs/fi/my_pack.yaml
```

------------------------------------------------------------------------

## Limitations (current version)

-   Standard packs only
-   No conjugate or transform support yet
-   YAML formatting is functional, not optimized
-   No preview step before writing

------------------------------------------------------------------------

## Versioning

Each generated file includes:

    # created with build_yaml version <version>

This enables: - debugging - migration support - future compatibility
checks

------------------------------------------------------------------------

## Summary

`build_yaml.rb` provides a simple way to create Linguatrain packs
quickly.
