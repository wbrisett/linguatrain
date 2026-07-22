# Setup & Usage Guide

Learn how to use Linguatrain effectively after installation. This guide explains how to configure Linguatrain, organize your learning packs, choose the appropriate study modes, and build productive study sessions.

---

## 📚 Documentation

Use the guide that best matches what you're trying to accomplish.

| Guide | Purpose | Current |
|-------|---------|---------|
| **Quick Start Guide** | Install Linguatrain and study your first lesson in approximately 5–10 minutes. | |
| **Setup & Usage Guide** | Learn the CLI, configuration, study modes, speech support, and advanced features. | ✅ You are here |
| **Authoring Handbook** | Learn how to create learning packs and understand Linguatrain's educational philosophy. | |
| **Options-details** | Quick reference to all the options in Linguatrain. | |

---

# Introduction

If you've completed the **Quick Start Guide**, you've already installed Linguatrain and worked through your first lesson. This guide takes the next step by showing you how to make Linguatrain part of your regular language-learning routine.

Unlike many language-learning applications, Linguatrain isn't built around a single study method. Instead, it provides multiple study modes that reinforce the same material in different ways. You might begin by learning new vocabulary in Study mode, test yourself in Quiz mode, practice recognition with Listen mode, and finish with Speak or Shadow mode to improve pronunciation.

The goal is simple:

> Learn the same material from multiple perspectives until it becomes natural.

Throughout this guide you'll learn:

- how to configure Linguatrain
- how to organize your learning packs
- how to choose the most effective study mode
- how to combine study modes into productive learning sessions
- how speech recognition and text-to-speech integrate into your workflow
- how Linguatrain uses spaced repetition to determine what you should review next

This guide focuses on **using** Linguatrain effectively.

If you want to create your own learning packs, continue with the **Authoring Handbook** after completing this guide.

If you're looking for a complete list of command-line options, see **Options-details**.

---

# How Linguatrain Works

Linguatrain is based on a simple idea:

Reading the same material repeatedly isn't the most effective way to learn a language.

Instead, learning improves when you encounter the same question/answer pairs in different contexts over time.

For example, you might begin by studying a new vocabulary pack. Once you're comfortable with the material, you can switch to Quiz mode to practice active recall. Listen mode develops listening comprehension, while Speak and Shadow modes help improve pronunciation and confidence. Grammar-focused packs can then reinforce the same language through Conjugate and Transform exercises.

Each study mode develops a different language skill, but they all work with the same underlying learning material.

Rather than replacing one another, the study modes complement one another.

## Workflows

There isn't a single "correct" workflow. The best approach depends on what you're studying and what skill you're trying to improve.

### Beginning a New Lesson

When learning new vocabulary or phrases for the first time, begin by becoming familiar with the material before testing yourself.

```text
Study → Match Game → Quiz → Review
```

**Study** introduces the material. Think of it like reviewing a flashcard—you see the prompt first, then reveal the answer along with pronunciation guidance, hints, and notes.

**Match Game** develops recognition by asking you to identify the correct answer from several choices. It's an excellent bridge between studying new material and recalling it from memory.

**Quiz** develops active recall by asking you to produce the answer without assistance. This is where you discover what you've actually learned.

**Review** allows Linguatrain's spaced repetition system to schedule the question/answer pairs that need additional practice.

---

### Building Listening and Speaking Skills

Once you're comfortable recalling the material, begin incorporating speech into your study sessions.

```text
Quiz → Listen → Shadow → Speak
```

**Quiz** confirms that you can successfully recall the material before introducing speech.

**Listen** allows you to hear native-quality pronunciation while reinforcing listening comprehension.

**Shadow** asks you to immediately repeat what you hear. This develops pronunciation, rhythm, and confidence before your speech is evaluated. Spending time in Shadow mode often improves recognition accuracy when you later use Speak mode.

**Speak** uses Whisper speech recognition to evaluate your pronunciation. Because you've already practiced listening and shadowing the material, Whisper is more likely to recognize your speech accurately, allowing you to focus on refining your pronunciation rather than struggling with speech recognition.

---

### Practicing Grammar

Grammar is different from vocabulary. Linguatrain is designed to reinforce grammatical concepts you've already learned rather than teach them from scratch. New grammar is often introduced most effectively by a teacher, textbook, or other learning resource.

```text
Study → Conjugate → Transform → Review
```

**Study** introduces the grammatical concepts and examples you'll be practicing.

**Conjugate** reinforces verb forms through repeated practice. Depending on the language, exercises may include person, tense, mood, positive and negative forms, or other language-specific conjugation patterns.

**Transform** develops fluency by asking you to apply grammatical rules in context rather than simply memorizing forms.

**Review** allows Linguatrain's spaced repetition system to schedule the question/answer pairs that need additional practice.

---

### Translation Practice

Translation packs are designed for learners who want to think directly between languages.

```text
Vocabulary → Translation → Listen → Shadow
```

Vocabulary introduces important words and phrases.

Translation develops comprehension between two languages.

Listen reinforces recognition.

Shadow develops pronunciation and speaking confidence.

---

## Linguatrain's Question/Answer Model

Everything in Linguatrain is built around question/answer pairs.

A vocabulary entry is a question/answer pair.

A phrase is a question/answer pair.

A translation exercise is a question/answer pair.

A conjugation prompt is a question/answer pair.

A transformation exercise is a question/answer pair.

The study mode changes, but the underlying learning material remains consistent.

This allows you to practice the same content using multiple techniques without duplicating your learning packs.

---

## Learning Packs

A learning pack groups together related question/answer pairs.

For example, you might create separate learning packs for:

- Greetings
- Food
- Numbers
- Clothing
- Common Verbs
- Textbook Exercises
- French to German Translation Practice

Keeping learning packs focused makes it easier to study a specific topic and allows Linguatrain's spaced repetition system to schedule review more effectively.

---

## Spaced Repetition

Linguatrain includes a spaced repetition system (SRS) to help determine which question/answer pairs should appear in future review sessions.

As you answer a pair correctly, it is scheduled less frequently.

Pairs that you find more difficult return sooner.

Rather than repeatedly reviewing everything you've already mastered, Linguatrain encourages you to spend more time reinforcing material that still needs practice.

Short, regular study sessions are generally more effective than occasional marathon sessions.

For many learners, 15–30 minutes each day produces better long-term results than several hours once a week.

---

The remainder of this guide explores each study mode in detail, explains when to use it, and demonstrates how different modes work together to create effective study sessions.

# Configuration

Linguatrain is designed to require very little day-to-day configuration. Most users configure the application once, verify that speech support is working, and rarely need to modify the configuration again.

This chapter explains where Linguatrain stores its configuration, how it locates the configuration file, and the most commonly customized settings.

---

## Configuration File

Linguatrain stores its settings in a YAML configuration file.

The configuration file controls application behavior such as:

- audio playback
- speech recognition
- text-to-speech
- review settings
- default runtime behavior
- localisation
- storage locations

Because the configuration file uses YAML, it can be edited using any text editor.

---

## Configuration File Locations


### Linux/macOS

```text
~/.config/linguatrain/config.yaml
```

### Windows

```text
%APPDATA%\Linguatrain\config.yaml
```

Create the directory if it doesn't exist.

Example:

```yaml
runtime:
  audio_player: "afplay"

piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/fi_FI-harri-medium.onnx"

whisper:
  model: "base"
  language: "fi"

localisation: "localisation/en-US_fi-FI.yaml"

```
---

## Configuration Search Order

When Linguatrain starts, it searches for a configuration file.

Linguatrain searches several standard locations before falling back to its built-in defaults.

If no configuration file is found, Linguatrain uses built-in defaults.

---

## Runtime Configuration

The `runtime` section controls general application behavior.

Example:

```yaml
runtime:

  audio_player: "afplay"

  missed_output_dir: "/Users/example/Documents/linguatrain/missed"
```

Common settings include:

- preferred audio player
- directory used to store missed question/answer pairs
- runtime behaviour

Most users will never need to modify these values.

---

## Speech Recognition

The `speech` section configures offline speech recognition using Whisper.

Example:

```yaml
speech:
  bin: "/Users/example/Library/Python/3.9/bin/whisper"
  model: "small"
  language: "fi"
  duration: 5

  record_cmd: "ffmpeg -f avfoundation -i :0 -t {duration} -ac 1 -ar 16000 {output}"
```

The most commonly adjusted settings are:

- Whisper executable
- Whisper model
- recording duration
- recording device

If Whisper does not recognize your microphone correctly, verify your recording device before changing any other settings.

---

## Piper Text-to-Speech

The `piper` section configures offline text-to-speech using Piper.

Example:

```yaml
piper:

  bin: "/Users/example/venvs/piper/bin/piper"

  models:

    fi-FI: "/Users/example/tools/piper/models/fi_FI/harri/medium/fi_FI-harri-medium.onnx"

    es-MX: "/Users/example/tools/piper/models/es_MX/claude/high/es_MX-claude-high.onnx"
```

Each language is mapped to its corresponding Piper model.

Only the languages you intend to study need to be configured.

Complete piper installation guidelines can be found in: `/docs/speech/piper-setup.md`

---

## Localisation

Linguatrain's interface text is also configurable.

Example:

```yaml
localisation: localisation/en-US_fi-FI.yaml
```

Localisation files customise prompts, labels, and interface text without requiring changes to the application itself.

---

## Testing Your Configuration

Before using Speak or Shadow mode, verify that recording and speech recognition are working correctly.

After updating your configuration, it's a good idea to verify that everything works correctly.

For speech recognition:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

Record a short sample:

```bash
ffmpeg -f avfoundation -i :0 -t 5 -ac 1 -ar 16000 /tmp/lt_test.wav
```

Play it back:

```bash
afplay /tmp/lt_test.wav
```

Then test Whisper directly:

```bash
whisper /tmp/lt_test.wav --model small --language fi
```

If all of these steps succeed, Linguatrain should also be able to use speech recognition successfully.

---

## Configuration Tips

- Keep your configuration file under version control if you customise it extensively.
- Install only the Piper voices you actually need.
- Smaller Whisper models are faster. However, larger models generally provide better recognition.
- Use language codes such as `fi` where possible.
- Test speech independently before troubleshooting Linguatrain.

Complete whisper installation guidelines can be found in: `/docs/speech/whisper-installation.md`

---

# Learning Packs

Everything you study in Linguatrain is contained within a learning pack.

A learning pack groups together related question/answer pairs that teach a specific topic, lesson, or language skill.

A learning pack should focus on a single topic or learning objective.

For example, you might create separate learning packs for:

- Greetings
- Food
- Clothing
- Common Verbs
- Numbers
- Family
- Textbook Exercises
- French → German Translation Practice

Keeping learning packs focused makes them easier to study and easier to maintain.

---

## One Topic Per Pack

Although Linguatrain doesn't require a specific size for learning packs, smaller packs are generally easier to learn than very large ones.

For example:

```text
✓ Greetings

✓ Food

✓ Clothing

✓ Family
```

is usually preferable to:

```text
Everything I Learned This Month
```

Smaller packs are easier to review, easier to update, and easier to reuse in different study sessions.

---

## Different Types of Learning Packs

Linguatrain supports several different learning pack types.

Examples include:

- Vocabulary Packs
- Phrase Packs
- Translation Packs
- Conjugation Packs
- Transform Packs

Each pack type is designed for a different style of learning, but they all follow the same overall philosophy: present meaningful question/answer pairs that can be reinforced using multiple study modes.

The **Authoring Handbook** describes each pack type in detail.

---

## Naming Learning Packs

Choose names that clearly describe the contents.

Examples:

```text
sm1_chapter_04_vocabulary.yaml

common_finnish_verbs.yaml

restaurant_phrases.yaml

fr_de_presentation_practice.yaml
```

Avoid generic names such as:

```text
lesson.yaml

test.yaml

new.yaml
```

Clear names become increasingly valuable as your collection grows.

---

## Organising Learning Packs

Many learners find it useful to organise packs by language and topic.

Example:

```text
packs/
    fi/
        vocabulary/
        phrases/
        translation/
        grammar/
    es/
        vocabulary/
        phrases/
    fr/
        translation/
```

There is no required directory structure.

Use whatever organisation makes sense for your own workflow.

**Tip**: Store your packs outside the Linguatrain directory for maximum flexibility. 

---

## Reusing Learning Packs

One of the strengths of Linguatrain is that the same learning pack can be used in many different ways.

For example, a vocabulary pack might be studied using:

```text
Study → Quiz → Match Game → Review
```

Later, after you've become more comfortable with the material, you might revisit the same pack using:

```text
Quiz → Listen → Speak → Shadow
```

The learning pack remains exactly the same. By changing only the study mode, you reinforce the same material using different learning techniques without duplicating content.

This encourages repeated exposure to the same material from different perspectives without creating duplicate content.

---

## Building Your Library

Over time you'll probably build a personal library of learning packs.

Rather than creating one enormous collection, consider building many smaller, focused packs.

Advantages include:

- easier review
- better organisation
- simpler maintenance
- reusable content
- faster study sessions

Small learning packs also work particularly well with Linguatrain's spaced repetition system.

---

## Next Steps

Now that your configuration is complete and you understand how learning packs are organised, you're ready to begin using Linguatrain's study modes.

The next chapter introduces each study mode, explains when to use it, and demonstrates how they work together to build effective language-learning sessions.


---

# Study Modes

The strength of Linguatrain comes from reinforcing the same learning pack through multiple study modes. Each mode develops a different language skill, allowing you to revisit the same question/answer pairs from different perspectives.

Choose the study mode that best matches the skill you want to develop.

## Mode Compatibility

Modes in Linguatrain can often be used with other modes. This table summarizes the supported combinations.

| Option | Quiz | Study | Listen | Speak | Shadow | Match Game | Transform | Conjugate |
|--------|:----:|:-----:|:------:|:-----:|:------:|:----------:|:---------:|:----------:|
| `--reverse` | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✗ |
| `--listen` | ✓ | ✓ | — | ✗ | ✗ | ✓ | ✓ (study) | ✓ (study) |
| `--speak` | ✓ | ✗ | ✗ | — | ✗ | ✗ | ✗ | ✗ |
| `--shadow` | ✓ | ✗ | ✗ | ✗ | — | ✗ | ✗ | ✗ |

> When an unsupported combination is selected, Linguatrain exits with a clear error message. 

---

## Quiz Mode

### Purpose

Quiz mode is the default study mode. It presents a prompt and asks you to provide the correct answer from memory. This is active recall—the most effective way to determine whether you've truly learned something.

### Best used with

```text
Study → Quiz → Match Game → Review
```

### Command

```bash
linguatrain.rb pack.yaml
```

### Example

```text
% linguatrain.rb ~/linguatrain/finnish_numbers.yaml

Source → Target Quiz — 42 word(s) (mode: typing, Source→Target)
--------------------------------------------------

[1/42]
Prompt: six / 6
Answer: kuusi
✅ Correct!
   (Prompt: six / 6)
   (phonetic: KOOOOS-EE)

[2/42]
Prompt: zero / 0
Answer: nolla
✅ Correct!
   (Prompt: zero / 0)
   (phonetic: NOHLL-AH)

```

### Tips

- Use Quiz mode after studying new material.
- Don't worry about occasional mistakes.
- Quiz mode forms the foundation of most study sessions.

---

## Study Mode

### Purpose

Study mode introduces new material without immediately testing your recall. Each prompt is displayed together with its answer, pronunciation guidance, notes, and hints.

### Best used with

```text
Study → Quiz
```

### Command

```bash
linguatrain.rb pack.yaml --study
```

### Example

```text

% linguatrain.rb ~/linguatrain/finnish_numbers.yaml --study

Prompt → Answer Quiz — 42 item(s) (mode: study, Prompt→Answer)
--------------------------------------------------

[1/42]

Prompt: three hundred / 300

phonetic
  KOHLM-EH-SAH-TAA

Answer: kolmesataa

(Enter for next; q to quit): 

[2/42]

Prompt: fifty / 50

phonetic
  VEEEES-EE-KUEMM-EHNT-AE

Answer: viisikymmentä

(Enter for next; q to quit): 
```


### Tips

- Ideal for your first exposure to a new learning pack.
- Read notes before moving to Quiz mode.
- Focus on understanding rather than speed.

---

## Reverse Mode

### Purpose

Reverse mode swaps the prompt and answer. Instead of recognising the target language, you're asked to produce it.

### Best used with

```text
Quiz → Reverse → Review
```

### Command

```bash
linguatrain.rb pack.yaml --reverse
```

### Example

```

linguatrain % linguatrain.rb ~/linguatrain/finnish_numbers.yaml --reverse  07:29

Target → Source Quiz — 42 word(s) (mode: typing, Target→Source)
--------------------------------------------------

[1/42]
Answer: kaksisataa
Prompt: two hundred
✅ Correct!
   Also accepted: 200
   (Prompt: two hundred / 200)

[2/42]
Answer: yksi
Prompt: 1
✅ Correct!
   Also accepted: one
   (Prompt: one / 1)

```

### Tips

- Usually more challenging than Quiz mode.
- Excellent for strengthening active recall.

---

## Match Game

### Purpose

Match Game develops recognition by asking you to select the correct answer from several choices.

### Best used with

```text
Study → Quiz → Match Game
```

### Command

```bash
linguatrain.rb pack.yaml --match-game
```

### Example
### Example: Match Game

```text
Source → Target Quiz — 95 word(s) (mode: match-game, Source→Target)
--------------------------------------------------

[1/95]
Prompt: apteekki
Hints:
  - to want
  - pharmacy
  - food
Answer: pharmacy
✅ Correct!
   (phonetic: AHP-teek-kee)
   (Prompt: apteekki)

[2/95]
Prompt: minä
Hints:
  - with
  - I
  - after
Answer: with
Try again.
Hints:
  - with
  - I
  - after
Answer: after

❌ Correct word: I
phonetic: MEE-nah
```


### Tips

- Great for quick review sessions.
- Useful before moving into more demanding study modes.

---

## Listen Mode

### Purpose

Listen mode develops listening comprehension. Linguatrain speaks the prompt using Piper and asks you for its meaning.

### Best used with

```text
Quiz → Listen → Speak → Shadow
```

### Command

```bash
linguatrain.rb pack.yaml --listen /  linguatrain.rb pack.yaml --listen --reverse
```

**Note:** Depending on how your prompts and answers are arranged, you may need to use `--reverse` to hear the correct language spoken. 

### Example

```
% linguatrain.rb ~/linguatrain/finnish_numbers.yaml --listen --reverse

Target → Source Quiz — 42 word(s) (mode: typing, listen, Target→Source)
--------------------------------------------------

[1/42]
🎧 Listen:
(Type 'r' to replay audio)
Type what you heard: 8
Try again.
Type what you heard: 9    
✅ Correct!
   Also accepted: nine
   yhdeksän - (phonetic: UEHD-EHKS-AEN)
   (Prompt: nine / 9)

[2/42]
🎧 Listen:
(Type 'r' to replay audio)
Type what you heard: 11
✅ Correct!
   Also accepted: eleven
   yksitoista - (phonetic: UEKS-EET-OHEEST-AH)
   (Prompt: eleven / 11)
```

### Tips

- Press `r` to replay audio.
- Most effective after you've already learned the vocabulary.

---

## Speak Mode

### Purpose

Speak mode evaluates your pronunciation using Whisper speech recognition.

### Best used with

```text
Quiz → Listen → Speak
```

### Command

```bash
linguatrain.rb pack.yaml --speak
```

### Example

```
linguatrain % linguatrain.rb ~/linguatrain/finnish_numbers.yaml --speak    07:40

Source → Target Quiz — 42 word(s) (mode: speak, Source→Target)
--------------------------------------------------

[1/42]
Prompt: six / 6
🎤 Speak now...
Press Enter to start recording: 
🎙 Recording (5s window)...
Speak now...

✅ Correct!
   Heard: Kuusi!

```

### Tips

- Focus on pronunciation rather than speed.
- Whisper's transcription helps identify pronunciation issues.

---

## Shadow Mode

### Purpose

Shadow mode plays the target language and immediately asks you to repeat it. This develops pronunciation, rhythm, and confidence.

### Best used with

```text
Listen → Speak → Shadow
```

### Command

```bash
linguatrain.rb pack.yaml --shadow
```

### Example

```
linguatrain % linguatrain.rb ~/linguatrain/finnish_numbers.yaml --shadow

Target Shadow Quiz — 42 word(s) (mode: shadow)
--------------------------------------------------

[1/42]
🗣️ Shadow:
Prompt: zero / 0
   (phonetic: NOHLL-AH)
🎤 Speak now...
Press Enter to start recording: 
🎙 Recording (5s window)...
Speak now...

🟡 Close enough
   Heard: Nulla.

[2/42]
🗣️ Shadow:
Prompt: one / 1
   (phonetic: UEKS-EE)
🎤 Speak now...
Press Enter to start recording: 
🎙 Recording (5s window)...
Speak now...


❌ Correct word: yksi
phonetic: UEKS-EE
Heard: Uuuksii!

[3/42]
🗣️ Shadow:
Prompt: two / 2
   (phonetic: KAHKS-EE)
🎤 Speak now...
Press Enter to start recording: 
🎙 Recording (5s window)...
Speak now...


❌ Correct word: kaksi
phonetic: KAHKS-EE
Heard: Toxi.

[4/42]
🗣️ Shadow:
Prompt: three / 3
   (phonetic: KOHLM-EH)
🎤 Speak now...
Press Enter to start recording: 
🎙 Recording (5s window)...
Speak now...

✅ Correct!
   Heard: Kolme!

```

### Tips

- Don't translate—imitate.
- Repeat difficult phrases several times.

---

## Conjugate Mode

### Purpose

Conjugate mode practices verb conjugations using positive, negative, or combined exercises.

### Best used with

```text
Study → Quiz → Conjugate → Transform
```

### Commands

```bash
linguatrain.rb pack.yaml --conjugate
linguatrain.rb pack.yaml --conjugate --negative
linguatrain.rb pack.yaml --conjugate --both
```

### Example

```linguatrain % linguatrain.rb ~/linguatrain/conjugate/sm_conjugation_kpt.yaml --conjugate

Target Conjugation Quiz — 20 verb(s) (120 items) (mode: conjugate, positive)
----------------------------------------------------------------------

[1/120]

Conjugate the verb.

[ Subject: te ]
[ Verb: ampua ]


Use the positive form:
> te ammutte
✅ Correct!


[2/120]

Conjugate the verb.

[ Subject: hän ]
[ Verb: ampua ]


Use the positive form:
> hän ampua
Try again.
> hän ampuu
✅ Correct!
```

```
linguatrain % linguatrain.rb ~/linguatrain/conjugate/sm_conjugation_kpt.yaml --conjugate --negative

Target Conjugation Quiz — 20 verb(s) (120 items) (mode: conjugate, negative)
----------------------------------------------------------------------

[1/120]

Conjugate the verb.

[ Subject: he ]
[ Verb: ampua ]


Use the negative form:
> he eivät ammu
✅ Correct!


```

```
linguatrain % linguatrain.rb ~/linguatrain/conjugate/sm_conjugation_kpt.yaml --conjugate --both   

Target Conjugation Quiz — 20 verb(s) (120 prompts, positive + negative) (mode: conjugate, both)
----------------------------------------------------------------------

[1/120]

Conjugate the verb.

[ Subject: he ]
[ Verb: ampua ]


Use the positive form:
> he ampuvat
✅ Correct!

Use the negative form:
> he eivät ammu
✅ Correct!

```


### Tips

- Practice positive forms before introducing negatives.
- `--both` provides excellent reinforcement.

---

## Transform Mode

### Purpose

Transform mode reinforces grammatical patterns by asking you to transform sentences rather than simply recalling vocabulary.

### Best used with

```text
Study → Quiz → Conjugate → Transform → Review
```

### Example

```
linguatrain % linguatrain.rb ~/linguatrain/transform/fi_paikansijat_local_cases_transform_packs/fi_paikansijat_sentence_choice_transform.yaml --transform

Target Transform Quiz — 8 item(s) (mode: transform)
----------------------------------------------------------------------

[1/8]

Soppa matkustaa Helsingistä ____.
["Movement from Helsinki to Pori."]

[ valitse sopiva vaihtoehto ]

Destination-choice:
> poriin
✅ Correct!


```

```
linguatrain % linguatrain.rb ~/linguatrain/transform/fi_conditional_politeness_transform.yaml --transform

Target Transform Quiz — 20 item(s) (mode: transform)
----------------------------------------------------------------------

[1/20]

Haluan kahvia.
I want coffee.

[ Make this more polite. ]

Conditional:
> Haluaisin kahvia.
✅ Correct!


[2/20]

Otan teetä.
I will take tea.

[ Make this more polite. ]

Conditional:
> Ottaisin teetä
✅ Correct!

```


### Tips

- Transform mode develops fluency.
- Particularly useful once you've completed the basics of a language.
- Transform is flexible schema allowing for many different types of practice. 

---

## Translation Mode

### Purpose

Translation mode works with multilingual translation packs. Source and target languages can be any supported language pair.

### Best used with

```text
Vocabulary → Translation Study → Translation Practice → Listen → Shadow
```

Use Translation Study first when the material is new. It lets you read through the source text, chunks, literal rendering, natural translation, hints, and pronunciation without being scored. Then use Translation Practice when you are ready to produce the translation yourself.

### Command

```bash
linguatrain.rb fr_de_translation_demo.yaml --translate
```

Read-through study mode:

```bash
linguatrain.rb fr_de_translation_demo.yaml --study --translation
```

Read-through study mode with pronunciation:

```bash
linguatrain.rb fr_de_translation_demo.yaml --study --translation --show-phonetic
```

### Example

Linguatrain is not limited to English-based study. This example uses French as the source language and German as the target language.

```text
French source:
Le soir, nous faisons souvent quelque chose ensemble.

German target:
Abends machen wir oft etwas zusammen.
```

Example YAML:

```yaml
metadata:
  category: Example Translation
  chapter: Multilingual Demo

translations:
  - id: evening_together
    source: "Le soir, nous faisons souvent quelque chose ensemble."
    target: "Abends machen wir oft etwas zusammen."
    literal: "In the evening, we often do something together."
    natural: "In the evenings we often do something together."
```

**Additional example**

```text

--------------------------------------------------
Translation Exercise
--------------------------------------------------

🎧  Minä olen Lauri Mäkelä. Olen suomalainen mies ja isä.

> I am Lauri Mäkelä.

--------------------------------------------------
Results
--------------------------------------------------

✓ Minä olen Lauri Mäkelä : I am Lauri Mäkelä
✗ Olen suomalainen mies
✗ ja isä

Score: 1/3 (33%)

[H]int  [R]etry  [S]how answer  [N]ext  [Q]uit

Choice: r

--------------------------------------------------
Remaining Translations
--------------------------------------------------

✓ Minä olen Lauri Mäkelä : I am Lauri Mäkelä
✗ Olen suomalainen mies
✗ ja isä

--------------------------------------------------

Olen suomalainen mies

> I am a Finnish man

--------------------------------------------------
Results
--------------------------------------------------

✓ Olen suomalainen mies : I am a Finnish man
✗ ja isä

Score: 1/2 (50%)

--------------------------------------------------
Remaining Translations
--------------------------------------------------

✓ Minä olen Lauri Mäkelä : I am Lauri Mäkelä
✓ Olen suomalainen mies : I am a Finnish man
✗ ja isä

--------------------------------------------------

ja isä

> and father

--------------------------------------------------
Results
--------------------------------------------------

✓ ja isä : and father

Score: 1/1 (100%)

Literal:
I am Lauri Mäkelä. Am Finnish man and father.

Answer:
I am Lauri Mäkelä. I am a Finnish man and father.

Pronunciation:
MEE-nah OH-lehn LAU-ree MAH-keh-lah. OH-lehn SOO-oh-mah-lai-nehn MEE-ehs yah EE-sah

[N]ext  [Q]uit

```

### Tips

- Translation mode is not limited to English.
- Literal and natural translations can both be included.
- Use `--study --translation` to walk through a translation pack without a text editor or scoring.
- Add `--show-phonetic` when you want pronunciation during a translation read-through.
- Combine Translation mode with Listen and Shadow for additional reinforcement.

---

# Speech Modes

Linguatrain integrates two offline speech technologies:

- **Piper** — text-to-speech (TTS)
- **Whisper** — speech-to-text (STT)

Linguatrain uses these tools as building blocks rather than replacing their documentation. Installation, model selection, configuration, and advanced tuning are covered in the dedicated **Piper Guide** and **Whisper Guide**. This manual focuses on how those technologies are used inside Linguatrain.

## Listen Mode

**Purpose**

Practice listening comprehension.

**Workflow**

1. Piper speaks the target-language word or phrase.
2. You identify what you heard.
3. Linguatrain checks your response.

```bash
linguatrain.rb pack.yaml --listen
```

## Speak Mode

**Purpose**

Practice speaking the target language.

**Workflow**

1. Linguatrain displays the prompt.
2. You speak the target-language answer.
3. Whisper transcribes your speech.
4. Linguatrain compares the transcription with the expected answer.

```bash
linguatrain.rb pack.yaml --speak
```

## Shadow Mode

**Purpose**

Improve pronunciation, rhythm, and fluency through immediate repetition.

**Workflow**

1. Piper speaks the target-language prompt.
2. You immediately repeat it aloud.
3. Whisper transcribes your response.
4. Linguatrain compares the transcription with the expected target-language answer.

```bash
linguatrain.rb pack.yaml --shadow
```

## Troubleshooting

If speech modes are not behaving as expected:

- Verify that Piper works independently.
- Verify that Whisper can successfully transcribe a recording.
- Replay the prompt (`r`) when available.
- Speak naturally rather than spelling words.
- Remember that Whisper is a transcription engine—not a pronunciation grader. An occasional transcription error can result in an otherwise correct pronunciation being marked incorrect.

For installation instructions, supported models, configuration options, and performance tuning, refer to the dedicated Piper and Whisper documentation.

---

# Choosing the Right Mode

Linguatrain provides several study modes, each designed to reinforce a
different aspect of language learning. While every mode can be used
independently, selecting the right mode for your current objective will
make your study sessions more effective.

The recommendations provide a good starting point. As you become
more familiar with Linguatrain, you will naturally develop a workflow
that best matches your own learning style.

------------------------------------------------------------------------

## Learning New Vocabulary

When learning new words or phrases for the first time, begin with
**Study Mode**. Study Mode introduces new material without the pressure
of scoring, allowing you to focus on understanding the relationship
between the source and target languages.

Once the vocabulary begins to feel familiar, move to **Match Game**
before attempting a traditional quiz.

### Recommended progression

1.  Study Mode
2.  Match Game
3.  Quiz Mode
4.  Listen Mode
5.  Speak Mode
6.  Shadow Mode

Match Game provides an excellent bridge between passive study and active
recall. Because the correct answer is selected from a small number of
choices, you can concentrate on recognizing vocabulary without worrying
about perfect spelling. Once recognition becomes automatic, move to Quiz
Mode where you must recall and type the answer yourself.

Combine Quiz Mode with `--reverse` to practice recognizing vocabulary in both directions. This helps develop recognition in both your source and target languages. This enables you to naturally recognize words and phrases in both directions.


| Mode | Primary Skill |
|------|---------------|
| **Study** | Recognition |
| **Match Game** | Recognition and discrimination |
| **Quiz** | Active recall |
| **Listen** | Listening comprehension |
| **Speak** | Spoken recall |
| **Shadow** | Pronunciation, rhythm, and fluency |

## Grammar and Conjugation

Grammar requires repetition and pattern recognition more than simple
memorization.

Use **Transform Mode** for sentence transformations and structured
grammar exercises. Use **Conjugation Mode** to practice verb forms and
reinforce grammatical patterns.

### Recommended progression

1.  Study Mode
2.  Transform or Conjugation Mode
3.  Review difficult items as needed

------------------------------------------------------------------------

## Translation Practice

Translation Mode develops the ability to construct complete sentences
rather than simply recalling isolated vocabulary.

Unlike vocabulary drills, Translation Mode evaluates longer responses,
provides meaningful feedback, and allows retries before revealing the
correct translation.

Translation packs can also be reviewed with `--study --translation`. This
walk-through mode is useful before active translation practice because it
shows the source text, chunks, literal renderings, natural translations,
hints, and optional pronunciation without scoring the learner.

Translation Mode is most effective after becoming reasonably familiar
with the vocabulary and grammar used in the lesson.

------------------------------------------------------------------------

## Studying Alongside a Textbook

Linguatrain works exceptionally well alongside a classroom course or
self-study textbook.

A typical workflow is:

1.  Read the textbook lesson.
1.  Create Linguatrain pack for the lesson.* 
2.  Study the corresponding Linguatrain pack.
3.  Complete Match Game.
4.  Complete the Quiz.
5.  Practice with Listen, Speak, or Shadow Mode.
6.  Return to the textbook exercises.

'*' **Note**: See the YAML Schema Guide and the Authoring Guide for instructions on creating your own Linguatrain content. 

------------------------------------------------------------------------

## Pronunciation Practice

Pronunciation develops through repeated exposure and repeated speaking.

### Speak Mode

Speak Mode displays a prompt and asks you to say the correct answer
aloud. Whisper transcribes your speech and Linguatrain compares the
transcription with the expected answer.

### Shadow Mode

Shadow Mode plays the target-language audio using Piper. Immediately
repeat what you hear before comparing your speech with Whisper's
transcription.

Shadow Mode helps improve pronunciation, rhythm, timing, and speaking
fluency.

------------------------------------------------------------------------

## Reviewing Previously Learned Material

Once vocabulary becomes familiar, regular review is more valuable than
repeatedly studying new material.

Quiz Mode provides active recall practice, while Listen, Speak, and
Shadow reinforce listening comprehension, pronunciation, and spoken
production.

When using Spaced Repetition, Linguatrain automatically selects material
that is ready for review, allowing you to concentrate your study time
where it provides the greatest benefit.

------------------------------------------------------------------------

## There Is No Single "Correct" Workflow

Every learner studies differently.

Experiment with the different modes and build a workflow that matches
your learning style. Linguatrain is designed to support many different
approaches rather than requiring a single prescribed method.

---

## License

Copyright © 2026 Wayne F. Brissette

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

See the LICENSE file for details.

[LICENSE](LICENSE)
