# build_yaml.rb

Interactive CLI utility to create hand-authored Linguatrain YAML packs
without starting from a blank template.

------------------------------------------------------------------------

## Overview

`build_yaml.rb` is a guided pack builder for the two YAML formats that
are intended to be comfortable for humans to author directly:

- Vocabulary packs
- Conjugation packs

Translation and Word Explorer YAML are advanced/generated authoring
formats and are not built by this tool.

------------------------------------------------------------------------

## Usage

### Vocabulary Pack

```bash
ruby tools/build_yaml.rb --vocab packs/fi/my_vocabulary.yaml
```

Vocabulary mode is the default, so this also works:

```bash
ruby tools/build_yaml.rb packs/fi/my_vocabulary.yaml
```

The builder prompts for pack metadata, then each vocabulary entry:

- `id`
- `prompt`
- `answer`
- optional `type`
- optional `alternate_prompts`
- optional `spoken`
- optional `phonetic`
- optional `notes`
- optional `forms`

### Vocabulary From CSV

```bash
ruby tools/build_yaml.rb --vocab --csv input.csv packs/fi/my_vocabulary.yaml
```

Required CSV columns:

- `prompt`
- `answer`

Optional CSV columns:

- `id`
- `type`
- `alternate_prompts`
- `spoken`
- `phonetic`
- `notes`
- `form_<label>`

List-like CSV fields may use semicolons, pipes, or new lines.

Example:

```csv
id,prompt,answer,type,phonetic,form_partitive_singular
päivä,päivä,day,noun,PAI-vah,päivää
```

### Conjugation Pack

```bash
ruby tools/build_yaml.rb --conjugate packs/fi/my_conjugation.yaml
```

The builder prompts for pack metadata, a `persons` list, then each
conjugation entry:

- `id`
- `lemma`
- optional `gloss`
- positive forms for each person
- negative forms for each person

Generated conjugation packs include both:

```yaml
type: conjugation
drill_type: conjugate
```

This makes the pack intent clear to the runtime and to validation tools.

------------------------------------------------------------------------

## Output Requirements

The output filename must:

- end in `.yaml` or `.yml`
- include a filename, not just a directory

Example:

```bash
packs/fi/greetings.yaml
```

------------------------------------------------------------------------

## Validation

After building a vocabulary pack:

```bash
ruby bin/validate_pack.rb packs/fi/my_vocabulary.yaml
```

After building a conjugation pack:

```bash
ruby bin/validate_pack.rb --conjugate packs/fi/my_conjugation.yaml
```

------------------------------------------------------------------------

## Versioning

Each generated file includes:

```yaml
# created with build_yaml version: dev_03
```

This helps future migration and debugging.
