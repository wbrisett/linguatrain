# Linguatrain Pack Validator (`validate_pack.rb`)

A validation and auto-fix tool for Linguatrain YAML packs.

This script validates pack structure, metadata, and entries across all supported pack types:
- Standard (word) packs
- Transform packs
- Conjugation packs

It can also optionally generate a corrected version of a pack using the `--update` flag.

---

## Features

### Validation
- Ensures required top-level structure (`metadata`, `entries`)
- Validates metadata fields:
  - `id`
  - `version`
  - `schema_version`
- Validates entry structure depending on pack type
- Detects duplicate entry IDs
- Detects incorrect data types (for example, numeric values where strings are expected)
- Provides clear, actionable error messages

### Smart Error Messages
Instead of generic type errors, the validator provides contextual fixes:

Example:
```
Error: - id: '005' prompt: 06 must be a string. Use quotes to properly render this. "06"
```

### Auto-Fix Mode (`--update`)
- Writes a corrected YAML file alongside the original:
  ```
  your_pack.updated.yaml
  ```
- Fixes:
  - Missing `version` → set to `1`
  - Missing `schema_version` → set to `1`
  - Numeric values converted to properly quoted strings
  - Duplicate IDs resolved (`004` → `004dup`, `004dup2`, etc.)
- Preserves original formatting where possible (for example `05`, `06`, `05:00`)

### Batch Validation
- Validate entire directories recursively
- Optional CSV output for reporting

---

## Usage

### Validate a Single Pack
```
ruby validate_pack.rb path/to/pack.yaml
```

### Validate and Auto-Fix
```
ruby validate_pack.rb --update path/to/pack.yaml
```

### Validate All Packs in a Directory
```
ruby validate_pack.rb --all=./packs
```

### Validate All + CSV Report
```
ruby validate_pack.rb --all=./packs --csv=report.csv
```

### Strict Mode
```
ruby validate_pack.rb --strict path/to/pack.yaml
```

---

## Output Example

```
Linguatrain pack validation: my_pack.yaml

Updated YAML written to: my_pack.updated.yaml

Original file results:

Errors (2):
  - metadata missing required field: schema_version

  - Duplicate id "004" at entries[5] (already used at entries[3])

Result: FAIL (2 errors, 0 warnings)

Updated file results:

Result: PASS (0 errors, 0 warnings)
```

---

## Supported Pack Types

### Standard Pack (Default)
```
metadata:
  id: "example"
  version: 1
  schema_version: 1

entries:
  - id: "001"
    prompt: "Hello"
    answer:
      - "Hei"
```

### Transform Pack
Requires:
```
metadata:
  drill_type: transform
```

### Conjugation Pack
Requires:
```
metadata:
  drill_type: conjugate
```

---

## Common Issues Detected

### Missing Metadata
```
metadata missing required field: schema_version
```

### Numeric Values Instead of Strings
YAML interprets values like `05` or `05:00` as numbers.

Fix:
```
"05"
"05:00"
```

### Duplicate IDs
Automatically fixed in `--update` mode:
```
004 → 004dup
```

---

## Design Notes

- The validator is **non-destructive** by default
- `--update` never overwrites the original file
- The updated file is always written separately
- Validation is performed on both:
  - original file
  - updated file

---

## Exit Codes

- `0` → success (no errors)
- `1` → validation failed
- `2` → usage or input error

---

## Summary

`validate_pack.rb` is both:
- a **validator** (ensures pack correctness)
- a **fixer** (normalizes and repairs packs safely)

It is designed to support maintainable, high-quality Linguatrain content at scale.
