# Linguatrain Options Reference

This document lists the command-line options by learning area, rather than as a flat list.

Command:

```bash
ruby bin/linguatrain.rb PACK.yaml [count|all] [options]
```

The positional value after the YAML path is the optional quiz size. For example, `pack.yaml 10` selects 10 entries, while `pack.yaml all` selects every available entry.
If no size is entered, Linguatrain uses the default selection behavior for the active mode.

## Complete Option Index

### Setup And Configuration

These options allow you to store your configuration files in locations other than the default location. This is useful when you have multiple configurations and do not want to keep modifying the same configuration file.


| Option | Purpose | Default |
|---|---|---:|
| `--config PATH` | Use a specific user config YAML file. | `LINGUATRAIN_CONFIG` or default config path |
| `--localisation PATH` | Use a specific localisation YAML file. | config/default |
| `--audio-player CMD` | Set the audio playback command. | config, usually `afplay` on macOS |

### Core Quiz Controls

| Option | Purpose | Default |
|---|---|---:|
| `--study` | Show/reveal study mode with no scoring. | off |
| `--reverse` | Practice target to source instead of source to target. | off |
| `--match-game` | Show multiple-choice style hints while still requiring typed answers. | off |
| `--match-options MODE` | Control match-game hint display: `auto`, `source`, `target`, or `both`. | `auto` |
| `--lenient-umlauts` | Accept `a` for `ä` and `o` for `ö`. Strongly discouraged except for temporary keyboard/accessibility issues. | off |

### Grammar And Pack Modes

| Option | Purpose | Default |
|---|---|---:|
| `--transform` | Run transform drills using prompt/cue grammar steps. | off |
| `--conjugate` | Run verb conjugation drills. | off |
| `--translation` | Run translation exercises. | off |
| `--translate` | Alias for `--translation`. | off |
| `--conversation` | Run conversation practice. | off |
| `--word-explorer` | Run Word Explorer exercises. | off |

### Conjugation Options

| Option | Purpose | Default |
|---|---|---:|
| `--negative` | With `--conjugate`, drill negative forms only. | off |
| `--both` | With `--conjugate`, drill positive and negative forms. | off |
| `--category KEY` | With `--conjugate`, include only verbs whose category key matches `KEY`. | none |
| `--identify-category` | With `--conjugate`, ask the learner to identify each verb's category before conjugating. | off |
| `--ask-category` | Alias for `--identify-category`. | off |
| `--drill-category` | Legacy alias for `--identify-category`. | off |

### Translation Options

| Option | Purpose | Default |
|---|---|---:|
| `--show-phonetic` | With `--translation`, show pronunciation guidance when available. | off |
| `--study --translation` | Walk through a translation pack without scoring, showing source text, chunks, literal renderings, natural translations, hints, and optional pronunciation. | off |

### Word Explorer Options

| Option | Purpose | Default |
|---|---|---:|
| `--recognize` | With `--word-explorer`, recognize word relationships. Also enables `--match-game`. | default Word Explorer mode |
| `--build` | With `--word-explorer`, build forms from base words. | off |
| `--apply` | With `--word-explorer`, apply forms in context. | off |

### Listening And TTS Options

| Option | Purpose | Default |
|---|---|---:|
| `--listen` | Speak the target language with Piper while the learner types. | off |
| `--listen-no-source` | Listening mode without showing the source prompt. | off |
| `--listen-no-english` | Alias for `--listen-no-source`. | off |
| `--listen-show-target` | With reverse listening, also show the written target-language text. | off |
| `--listen-require-source` | With listening, require the source-language meaning after the heard answer. | off |
| `--printed-voice` | Print the exact text sent to Piper. | off |
| `--tts-variant VAR` | Choose what Piper speaks: `prompt`, `source`, `written`, or `spoken`. | `prompt` |
| `--answer-variant VAR` | Choose accepted typed answers: `written`, `spoken`, or `either`. | `written` |
| `--show-variants` | Display written and spoken variants together when available. | off |
| `--piper-bin PATH` | Path to the Piper executable. | `PIPER_BIN` or config |
| `--piper-model PATH` | Path to the Piper `.onnx` model. | `PIPER_MODEL` or config |
| `--tts-template STR` | Template for text sent to Piper, for example `Suomeksi: {text}.` | config/default |

### Speaking And Shadowing Options

| Option | Purpose | Default |
|---|---|---:|
| `--speak` | Record the learner's spoken answer and score it with Whisper. | off |
| `--shadow` | Play target audio with Piper, then record and score the learner's speech. | off |
| `--speech-record-cmd CMD` | Shell command used to record audio. Supports `{output}` and `{duration}` placeholders. | `SPEECH_RECORD_CMD` or config |
| `--speech-bin PATH` | Path to Whisper or speech recognition executable. | `WHISPER_BIN`, `SPEECH_BIN`, or config |
| `--speech-model NAME` | Whisper model name. | `WHISPER_MODEL`, `SPEECH_MODEL`, or `base` |
| `--speech-language NAME` | Speech recognition language. | `WHISPER_LANGUAGE`, `SPEECH_LANGUAGE`, or `Finnish` |
| `--speech-duration N` | Seconds to record in speaking mode. | `SPEECH_DURATION` or mode default |

### Spaced Repetition Options

| Option | Purpose | Default |
|---|---|---:|
| `--srs` | Enable spaced repetition scheduling. | off |
| `--due` | With `--srs`, quiz only due items. | off |
| `--new N` | With `--srs`, include up to `N` new items. | `5` |
| `--reset-srs` | With `--srs`, reset scheduling state for this pack. | off |
| `--srs-file PATH` | Override the SRS state file path. | pack-derived |

### Diagnostics

Timing was originally designed for debugging and diagnostics. It can also help gauge recall speed. For example, if a learner times a vocabulary-style pack one week, then repeats the same pack a month later, the timing output can help show how quickly the material is being recalled and where practice should continue.

| Option | Purpose | Default |
|---|---|---:|
| `--timing` | Show timing metrics for quiz runs. | off |

## Core Concepts

### Count

The optional positional count is not an option flag:

```bash
ruby bin/linguatrain.rb pack.yaml 10
```

This asks Linguatrain to quiz 10 entries. Use `all` to include every entry:

```bash
ruby bin/linguatrain.rb pack.yaml all
```

### Study Mode

`--study` changes the session from scored recall to guided review. The learner sees a prompt, reveals the answer, optionally hears audio, then moves to the next item.

```bash
ruby bin/linguatrain.rb pack.yaml --study
```

Study mode is useful before active drilling. It does not update SRS and cannot be combined with scoring-oriented modes such as `--match-game`, `--speak`, or SRS.

Translation packs also support study mode:

```bash
ruby bin/linguatrain.rb translation_pack.yaml --study --translation
```

This is a read-through mode rather than a quiz. It walks through each translation entry and shows the source text, chunks, chunk-level literal and natural translations, hints, the full literal rendering, and the full natural answer. Add `--show-phonetic` to include pronunciation when the pack provides it.

### Reverse Mode

`--reverse` swaps the direction of the quiz.

```bash
ruby bin/linguatrain.rb pack.yaml 10 --reverse
```

For normal vocabulary packs, this means target to source instead of source to target. For example, if the source language is Spanish and the target language is English, reverse mode shows the vocabulary in English and asks for the Spanish item.

### Match Game

`--match-game` shows hints while still requiring a typed answer.

```bash
ruby bin/linguatrain.rb pack.yaml 10 --match-game
```

`--match-options MODE` controls what hints are shown:

| Mode | Behavior |
|---|---|
| `auto` | Choose the normal hint display for the current direction. |
| `source` | Show source-side hints when available. |
| `target` | Show target-side hints when available. |
| `both` | Show paired hints when available. |

### Lenient Umlauts

`--lenient-umlauts` is available, but it is generally a bad idea for language learning. Umlauts and other diacritics are not decoration; in many languages they change pronunciation, grammar, and meaning. Treating `a` as close enough to `ä`, or `o` as close enough to `ö`, can teach the wrong spelling and weaken the learner's ability to recognize real words.

Use this option only as a short-term workaround for keyboard or accessibility problems. For normal study, leave it off and learn the correct characters from the beginning.

## Conjugate

Conjugation mode drills verb morphology by combining a subject and a verb lemma.

```bash
ruby bin/linguatrain.rb packs/fi/conjugation/sm_conjugation_kpt.yaml all --conjugate
```

Positive forms are the default:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate
```

Negative-only drills:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate --negative
```

Positive and negative drills:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate --both
```

Filter to one verb category:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate --category type_1
```

Ask the learner to identify the verb category before conjugating:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate --identify-category
```

When a conjugation pack includes `category`, `stem`, and `notes` metadata,
missed category, stem, or conjugated-form answers show a short explanation
after the correct answer. This helps connect the mistake to the verb type
pattern.

Example:

```text
❌ Correct answer: kävele-
Note:
  Verb type: Type 3
  Stem: kävele-
  Stem changes before personal endings, e.g. kävellä → kävelen.
```

Filter and identify together:

```bash
ruby bin/linguatrain.rb pack.yaml --conjugate --category type_1 --identify-category
```

`--ask-category` and `--drill-category` still work as aliases, but new docs should prefer `--identify-category`.

## Transform

Transform mode uses prompt/cue grammar steps. It is for exercises such as positive to negative, statement to question, or person changes.
The flexibility of transform allows YAML packs to mimic many different learning exercises without making huge modifications to the Linguatrain engine.
This is especially useful when working from a textbook exercise that does not quite fit conjugation or matching.

```bash
ruby bin/linguatrain.rb packs/fi/transform/sm_transform_kpt.yaml all --transform
```

Transform mode can be used with `--study`. Listening is only supported for transform drills when used with study mode.

## Translation

Translation mode uses structured translation packs with source text, hints, literal translations, notes, and accepted natural translations.

```bash
ruby bin/linguatrain.rb packs/fi/translations/sm_translation.yaml --translation
```

`--translate` is an alias:

```bash
ruby bin/linguatrain.rb packs/fi/translations/sm_translation.yaml --translate
```

Show pronunciation guidance when the pack provides it:

```bash
ruby bin/linguatrain.rb packs/fi/translations/sm_translation.yaml --translation --show-phonetic
```

Read through a translation pack without scoring:

```bash
ruby bin/linguatrain.rb packs/fi/translations/sm_translation.yaml --study --translation
```

Read through with pronunciation:

```bash
ruby bin/linguatrain.rb packs/fi/translations/sm_translation.yaml --study --translation --show-phonetic
```

In translation study mode, press Enter to move to the next entry or `q` to quit.

## Word Explorer

Word Explorer focuses on why a word has the form it has in a real sentence. It sits between vocabulary and full grammar study: vocabulary tells you what a word means, while Word Explorer helps you see how an encountered form relates to a base word, a grammar pattern, and the surrounding context.

```bash
ruby bin/linguatrain.rb pack.yaml --word-explorer
```

The modes form a learning ladder:

| Mode | Main Question | What The Learner Practices |
|---|---|---|
| `--recognize` | What is this word related to? | Identifying the base word or word-family relationship behind an encountered form. |
| `--build` | How do I create the form I need? | Starting from a base word and typing the correct related form for a given meaning or grammar cue. |
| `--apply` | Which form belongs here? | Choosing or producing the correct form in sentence context, using meaning, grammar, and usage together. |

Recognize mode is the default:

```bash
ruby bin/linguatrain.rb pack.yaml --word-explorer --recognize
```

Use this when the learner is still learning to see relationships between forms. For example, recognizing that `autolla` belongs to `auto`, or that an encountered word is a case form, compound, derivation, passive form, or another modeled word relationship.

Build mode asks the learner to produce forms:

```bash
ruby bin/linguatrain.rb pack.yaml --word-explorer --build
```

Use this when recognition is no longer enough and the learner should practice making the form from the base word. A typical prompt gives a base word, a target meaning, and a grammar cue, then asks for the transformed form.

Apply mode moves the form into context:

```bash
ruby bin/linguatrain.rb pack.yaml --word-explorer --apply
```

Use this when the learner is ready to decide which form belongs in a sentence. Apply is the most advanced Word Explorer mode because it requires context, meaning, and grammar to work together.

If no Word Explorer mode is given, Linguatrain uses recognize mode. `--recognize` also enables `--match-game`. Match game is only supported with recognize mode.

## Conversation

Conversation mode plays through dialogue-style material instead of isolated prompts.

```bash
ruby bin/linguatrain.rb pack.yaml --conversation
```

Conversation mode uses Piper audio settings because it speaks dialogue lines.

This is designed so the learner has a partner when studying alone.

## Listening And TTS

Listening mode adds Piper text-to-speech to the normal quiz flow. It is useful for training comprehension because the learner has to connect what they hear with the written answer, the source meaning, or both.

| Option | What It Changes | Best Used For |
|---|---|---|
| `--listen` | Speaks the target-language item while the learner answers. | Adding audio recognition to normal quiz practice. |
| `--listen-no-source` | Hides the source prompt so the learner relies on audio first. | Harder listening comprehension drills. |
| `--listen-no-english` | Older alias for `--listen-no-source`. | Backward compatibility. |
| `--listen-require-source` | After the heard-answer step, also asks for the source-language meaning. | Checking comprehension, not just sound recognition. |
| `--listen-show-target` | In reverse listening, also shows the written target-language text. | Bridging between heard language and written form. |
| `--printed-voice` | Prints the exact text sent to Piper. | Debugging TTS output or confirming what is being spoken. |
| `--tts-variant VAR` | Chooses which stored text Piper speaks. | Switching between prompt, written answer, and spoken variants. |
| `--answer-variant VAR` | Chooses which written/spoken variants are accepted as typed answers. | Practicing formal written forms, spoken forms, or both. |
| `--show-variants` | Displays written and spoken variants together when available. | Comparing written language with spoken usage. |
| `--piper-bin PATH` | Uses a specific Piper executable. | Local Piper setup. |
| `--piper-model PATH` | Uses a specific Piper voice model. | Selecting the target-language voice. |
| `--tts-template STR` | Wraps text before sending it to Piper. | Adding context such as `Suomeksi: {text}.` |

Basic listening:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen
```

Harder listening without the source prompt:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen-no-source
```

Comprehension check after the heard answer:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --listen-require-source
```

This mode is especially useful when the learner can recognize the sounds but still needs practice connecting them back to meaning.

Show the written target text in reverse listening:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --reverse --listen --listen-show-target
```

Print exactly what is sent to Piper, which is helpful when checking templates or variant selection:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --printed-voice
```

Choose what Piper speaks with `--tts-variant`:

| Value | Behavior |
|---|---|
| `prompt` or `source` | Speak the source prompt. |
| `written` | Speak the written answer form. |
| `spoken` | Speak the spoken variant, falling back to written if missing. |

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --tts-variant spoken
```

Choose what typed answers are accepted with `--answer-variant`:

| Value | Behavior |
|---|---|
| `written` | Accept written answer forms. |
| `spoken` | Accept spoken variants, falling back to written if missing. |
| `either` | Accept either written or spoken variants. |

```bash
ruby bin/linguatrain.rb pack.yaml 10 --answer-variant either
```

Display written and spoken variants for comparison:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --show-variants
```

Piper setup can come from the config file, environment variables, or command-line options:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --piper-bin /path/to/piper --piper-model /path/to/model.onnx
```

Customize the text wrapped around each spoken item:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --listen --tts-template 'Suomeksi: {text}.'
```

`--listen`, `--conversation`, and `--shadow` require Piper settings.

## Speaking And Shadowing

Speaking modes move practice from typing into pronunciation. They use a recorder command to capture the learner's voice, then Whisper attempts to recognize what was said.

| Option | What It Changes | Best Used For |
|---|---|---|
| `--speak` | Records the learner's spoken answer and scores it with Whisper. | Practicing recall and pronunciation without typing. |
| `--shadow` | Plays the target phrase or word with Piper first, then records the learner repeating it and scores the result with Whisper. | Pronunciation training: hear a native-like model, repeat it, and check whether your speech is recognizable. |
| `--speech-record-cmd CMD` | Sets the shell command used to record learner audio. | Connecting Linguatrain to the local microphone/recording tool. |
| `--speech-bin PATH` | Sets the Whisper or speech-recognition executable. | Choosing the speech recognizer. |
| `--speech-model NAME` | Chooses the Whisper model. | Balancing speed and recognition quality. |
| `--speech-language NAME` | Tells Whisper which language to listen for. | Improving recognition accuracy for the target language. |
| `--speech-duration N` | Sets how many seconds to record. | Giving shorter or longer phrases enough time. |

Basic speaking mode:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --speak
```

Shadow mode is especially useful because it gives the learner a model to use immediately before they speak. Piper plays the phrase or word as it should sound, the learner repeats it, and Whisper checks whether the pronunciation was close enough to be recognized.

**Note**: Piper voices and Whisper models can behave differently by language, microphone, and phrase length. Test a few combinations to find the voice and recognition settings that work best for your learning setup.

```bash
ruby bin/linguatrain.rb pack.yaml 10 --shadow
```

Speech recording and recognition can be configured from the command line:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --speak \
  --speech-record-cmd 'rec {output} trim 0 {duration}' \
  --speech-bin /path/to/whisper \
  --speech-model base \
  --speech-language Finnish \
  --speech-duration 3
```

`--speak` and `--shadow` require a speech recording command. `--shadow` also requires Piper settings because it plays the target audio before recording.

## Spaced Repetition

SRS tracks scheduling state for vocabulary-style quiz items. It helps turn a pack into an ongoing review loop by prioritizing due material while still introducing a controlled number of new items.

| Option | What It Changes | Best Used For |
|---|---|---|
| `--srs` | Enables spaced repetition scheduling for the pack. | Long-term review instead of one-off drilling. |
| `--due` | Limits the session to items that are currently due. | Daily review sessions. |
| `--new N` | Allows up to `N` new items into an SRS session. | Controlling how much new material enters review. |
| `--reset-srs` | Clears scheduling state for this pack. | Starting over after changing a pack or resetting practice history. |
| `--srs-file PATH` | Uses a specific SRS state file. | Keeping separate schedules, testing, or storing state outside the default location. |

Enable SRS:

```bash
ruby bin/linguatrain.rb pack.yaml all --srs
```

Only quiz due items:

```bash
ruby bin/linguatrain.rb pack.yaml all --srs --due
```

Limit new items:

```bash
ruby bin/linguatrain.rb pack.yaml all --srs --new 10
```

Reset scheduling state for a pack:

```bash
ruby bin/linguatrain.rb pack.yaml all --srs --reset-srs
```

Use a specific SRS file:

```bash
ruby bin/linguatrain.rb pack.yaml all --srs --srs-file ~/.config/linguatrain/srs/custom.yaml
```

When SRS is enabled, progress is saved as entries are graded. If the session ends early, progress up to the last completed item is preserved.

## Setup And Diagnostics

Use a specific config file:

```bash
ruby bin/linguatrain.rb pack.yaml --config ~/.config/linguatrain/config.yaml
```

Use a specific localisation file:

```bash
ruby bin/linguatrain.rb pack.yaml --localisation localisation/en-US_fi-FI.yaml
```

Use a specific audio player:

```bash
ruby bin/linguatrain.rb pack.yaml --audio-player afplay
```

Show per-run timing metrics:

```bash
ruby bin/linguatrain.rb pack.yaml 10 --timing
```

## Common Compatibility Notes

Some modes intentionally do not combine.

| Combination | Status |
|---|---|
| `--study` with SRS | Not supported; study is not scored. |
| `--study` with `--translation` | Supported as a read-through mode with no scoring. |
| `--study` with `--match-game`, `--lenient-umlauts`, `--speak`, or `--conversation` | Not supported. |
| `--conjugate` with `--match-game`, `--speak`, `--shadow`, `--reverse`, `--conversation`, `--transform`, `--translation`, or SRS | Not supported. |
| `--conjugate --listen` | Supported only with `--study`. |
| `--transform --listen` | Supported only with `--study`. |
| `--word-explorer` with `--listen`, `--speak`, `--shadow`, `--reverse`, `--conversation`, `--transform`, `--conjugate`, `--translation`, or SRS | Not supported. |
| `--match-game` with Word Explorer | Supported only with recognize mode. |
| `--speak` with `--listen`, `--match-game`, `--conversation`, `--translation`, or `--shadow` | Not supported. |
| `--shadow` with `--listen`, `--match-game`, `--reverse`, `--conversation`, or `--translation` | Not supported. |
| `--listen-require-source` with `--reverse`, `--speak`, or `--shadow` | Not supported. |
| `--translation` with `--match-game`, `--conversation`, or `--reverse` | Not supported. |

## Missed Pack Generation

For scored vocabulary-style sessions, missed words are written to a timestamped YAML file at the end of the session. The missed pack contains the original metadata, generation details, session stats, and failed entries so the learner can run a focused follow-up drill.
