# Linguatrain Learner Phonetic System (Finnish edition)

Version 1.0\
Author: Wayne Brissette

------------------------------------------------------------------------

## Purpose

This phonetic system is designed for **learner clarity**, not linguistic
precision. It prioritizes:

-   Fast visual parsing
-   Alignment with Finnish spelling
-   Clear long vowel and consonant marking
-   Compatibility with CLI drill workflows

It is intentionally **not IPA**.

------------------------------------------------------------------------

## Core Principles

### 1. Long Vowels Stay Doubled

Finnish vowel length is phonemic and must be preserved.

  Finnish   Learner Phonetic
  --------- ------------------
  asuu      AH-suu
  puhuu     PU-huu
  maa       maa
  jäätelö   YAE-teh-luh

Rule: - If Finnish has a double vowel, keep it doubled in phonetics.

------------------------------------------------------------------------

### 2. Double Consonants Are Explicit

Gemination (long consonants) is audible and must be visible.

  Finnish       Learner Phonetic
  ------------- ------------------
  Helsinki      HEL-sing-ki
  Helsingissä   HEL-sing-gis-sae
  maksaa        MAHK-sah
  kissa         KIS-sah

Rule: - Double consonants should be represented clearly. - If helpful
for clarity, split syllables visually (HEL-sing-gis-sae).

------------------------------------------------------------------------

### 3. Vowel Mapping

  Finnish   Learner Representation
  --------- ------------------------
  a         ah
  e         eh
  i         ee (short: i sound)
  o         oh
  u         oo (short: u sound)
  y         ue
  ä         ae
  ö         uh

Notes: - ä → ae (as in YAE-teh-luh) - ö → uh - y → ue (front rounded
vowel approximation)

------------------------------------------------------------------------

### 4. Stress

Finnish stress is always on the first syllable.

To reinforce this visually:

-   Capitalize the first syllable

Example: - jäätelöä → YAE-teh-luh-ah - puistossa → PUIS-tos-sah -
espanjalainen → ES-pan-yah-lai-nen

------------------------------------------------------------------------

### 5. Syllable Chunking

Use hyphens to: - Clarify rhythm - Show double consonants - Improve
readability in CLI output

Example: - Helsingissä → HEL-sing-gis-sae - rahaa → RAH-hah-ah

------------------------------------------------------------------------

## Non-Goals

This system does NOT aim to:

-   Represent IPA precision
-   Model subtle vowel quality differences
-   Capture dialect variation

It is optimized for: - Beginner learners - Rapid recall drills - CLI
readability

------------------------------------------------------------------------

## Optional Extension

Potential future enhancements:

-   Toggle system allowing IPA alternative

*Note*: As of now, I haven't planned on doing this, however if enough people want it, I'll investigate doing this. 

------------------------------------------------------------------------

## Philosophy

Operational \> Academic.

This system exists to help learners internalize Finnish pronunciation
quickly and consistently inside Linguatrain.
