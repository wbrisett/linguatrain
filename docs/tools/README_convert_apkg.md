# convert_apkg_to_linguatrain.rb

## Overview

`convert_apkg_to_linguatrain.rb` is a utility script that converts Anki
`.apkg` decks into a draft Linguatrain-compatible YAML pack.

This tool is **not** intended to provide a perfect or lossless
conversion. Instead, it produces a **starting point** that can be
reviewed, cleaned up, and enhanced to take advantage of Linguatrain's
richer training model.

------------------------------------------------------------------------

## Philosophy

Linguatrain is not a flashcard clone. While Anki decks are card-based,
Linguatrain supports:

-   Structured prompts and answers
-   Multiple accepted variants
-   Spoken vs written forms
-   Transform and conjugation drills
-   Speech and listening workflows

Because of this, imported content should be treated as **raw material**,
not final content.

------------------------------------------------------------------------

## Features

-   Extracts notes from `.apkg` (Anki package)
-   Converts fields into:
    -   `prompt`
    -   `answer` (array)
-   Attempts to preserve:
    -   sample sentences
    -   media references (where possible)
-   Outputs:
    -   `pack.yaml` (Linguatrain format)
    -   `manifest.csv` (optional inspection/debugging)

------------------------------------------------------------------------

## Requirements

You will need Ruby and the following gems:

-   `sqlite3`
-   `rubyzip`

### Install dependencies

``` bash
gem install sqlite3
gem install rubyzip
```

------------------------------------------------------------------------

## Usage

``` bash
ruby convert_apkg_to_linguatrain.rb path/to/deck.apkg [output_dir]
```

### Behavior

-   If `output_dir` is provided → files are written there
-   If not provided → a directory is created next to the `.apkg` file
    using the deck name

Example:

``` bash
ruby convert_apkg_to_linguatrain.rb Finnish_Sentences.apkg
```

Creates:

    Finnish_Sentences/
      pack.yaml
      manifest.csv

------------------------------------------------------------------------

## Output Format

Example entry:

``` yaml
- id: '001'
  prompt: Hello
  answer:
    - Hei
  notes:
    sample_fi: Hei, mitä kuuluu?
    sample_en: Hi, how are you?
```

------------------------------------------------------------------------

## Limitations

-   Anki decks vary widely in structure
-   Field mapping is heuristic-based
-   HTML content may require cleanup
-   Media handling is best-effort
-   No guarantee of semantic correctness

------------------------------------------------------------------------

## Recommended Workflow

1.  Convert deck using this script
2.  Review generated YAML
3.  Clean up:
    -   duplicates
    -   awkward prompts
    -   inconsistent answers
4.  Enhance into Linguatrain-native structures:
    -   add alternate prompts
    -   add spoken variants
    -   restructure into transform/conjugation packs

------------------------------------------------------------------------

## Notes

This tool is intentionally kept outside the main Linguatrain CLI to:

-   preserve architectural boundaries
-   avoid implying Anki compatibility
-   encourage thoughtful content design

------------------------------------------------------------------------

## License

Use freely as part of the Linguatrain project.
