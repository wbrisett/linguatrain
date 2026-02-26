# finn_quiz.rb

A tiny command-line Finnish vocabulary quizzer that reads words from a YAML file and quizzes you in multiple modes:

- **typing** (English shown → you type Finnish)
- **match-game** (English shown → you type Finnish, with 3 Finnish options shown)
- **listening** (Finnish is spoken via **Piper**; Finnish text is *hidden*)
  - `--listen` : Finnish is spoken, **English is shown**
  - `--listen-no-english` : Finnish is spoken, **English is hidden** (hard mode)

It tracks how many you got correct on the **1st** vs **2nd** try, and writes a “missed words” YAML file **only if you missed something**.

---

## 🚀 Quick Start

### 1. Run a basic quiz (no audio)

```bash
ruby finn_quiz.rb Example_yaml/finnish_days_of_week.yaml
```

Run a subset or all words:

```bash
ruby finn_quiz.rb Example_yaml/finnish_days_of_week.yaml 5
ruby finn_quiz.rb Example_yaml/finnish_days_of_week.yaml all
```

### 2. Run match-game mode

```bash
ruby finn_quiz.rb Example_yaml/finnish_days_of_week.yaml --match-game
```

### 3. Run listening mode (requires Piper)

If you have Piper installed and a Finnish voice model downloaded:

```bash
ruby finn_quiz.rb Example_yaml/finnish_days_of_week.yaml all \
  --listen-no-english \
  --match-game \
  --piper-bin /Users/you/venvs/piper/bin/piper \
  --piper-model /Users/you/tools/piper/models/fi_FI/harri/medium/fi_FI-harri-medium.onnx
```

Tip: you can press `r` during listening mode to replay the audio.


---

## Requirements

### Core
- **Ruby**: modern Ruby (tested with Ruby 4.x; Ruby 3.x should also be fine)
- **No external Ruby gems required** — standard library only:
  - `yaml`
  - `time`
  - `optparse`
  - `securerandom`

### Text-to-Speech (optional)
Listening modes require:
- **Piper TTS** (`piper` CLI)
- A **Piper voice model** (`.onnx` + matching `.onnx.json`)

---

## Install / Run

From the directory containing `finn_quiz.rb`:

```bash
ruby finn_quiz.rb path/to/words.yaml
```

Use a subset of words or all words:

```bash
ruby finn_quiz.rb path/to/words.yaml 10
ruby finn_quiz.rb path/to/words.yaml all
```

---

## Modes

### Typing mode (default)

```bash
ruby finn_quiz.rb words.yaml
```

You’ll see English and type Finnish.

### Match-game mode

Shows **three Finnish options**, but you still **type** the answer (better for spelling + memory).

```bash
ruby finn_quiz.rb words.yaml --match-game
```

### Listening mode (Finnish is spoken; text hidden)

**Listening with English shown**:

```bash
ruby finn_quiz.rb words.yaml all --listen   --piper-bin /path/to/piper   --piper-model /path/to/fi_FI-voice.onnx
```

**Listening with English hidden (hard mode)**:

```bash
ruby finn_quiz.rb words.yaml all --listen-no-english   --piper-bin /path/to/piper   --piper-model /path/to/fi_FI-voice.onnx
```

#### Tip: why we use a “carrier phrase”
Some TTS engines (including Piper) can sound odd on isolated single words (e.g., `ei`). In listening mode the script speaks a short phrase like:

> `Suomeksi: <word>.`

That improves naturalness and intelligibility.

---

## Options

### `--lenient-umlauts`
Allows `a` for `ä` and `o` for `ö` (useful early on). If you use the lenient spelling, you still get credit, but it reminds you that umlauts matter.

```bash
ruby finn_quiz.rb words.yaml --lenient-umlauts
```

### `--match-game`
Enable match-game mode:

```bash
ruby finn_quiz.rb words.yaml --match-game
```

### `--listen` / `--listen-no-english`
Enable listening mode. Requires Piper + a voice model.

```bash
ruby finn_quiz.rb words.yaml --listen --piper-bin ... --piper-model ...
ruby finn_quiz.rb words.yaml --listen-no-english --piper-bin ... --piper-model ...
```

### `--piper-bin PATH` / `--piper-model PATH`
Provide Piper and model paths explicitly:

```bash
ruby finn_quiz.rb words.yaml all --listen   --piper-bin /Users/you/venvs/piper/bin/piper   --piper-model /Users/you/tools/piper/models/fi_FI-harri-medium.onnx
```

You can also set environment variables instead of passing flags every time:

```bash
export PIPER_BIN="$HOME/venvs/piper/bin/piper"
export PIPER_MODEL="$HOME/tools/piper/models/fi_FI/harri/medium/fi_FI-harri-medium.onnx"
```

Then run:

```bash
ruby finn_quiz.rb words.yaml all --listen-no-english --match-game
```

---

## macOS: Make Piper Environment Variables Persistent (zsh)

On macOS, the default shell is `/bin/zsh`.
If you only run `export ...` in a terminal, those variables exist **only for that session**.

To make them available in all new terminal windows/tabs:

### 1. Confirm your shell

```bash
echo $SHELL
```
If it returns `/bin/zsh`, continue.

### 2. Add the variables to your shell config

Edit your zsh configuration:

```code
nano ~/.zshrc
```
add: 

```code
export PIPER_BIN="$HOME/venvs/piper/bin/piper"
export PIPER_MODEL="$HOME/tools/piper/models/fi_FI/harri/medium/fi_FI-harri-medium.onnx"
```

Reload:

```code
source ~/.zshrc
```
Optional: Ensure IDE / login-shell support

Some macOS setups and IDEs (e.g., JetBrains) use login shells.

To ensure the variables are available everywhere, also add the same lines to:

```code
nano ~/.zprofile
```

Verify

Open a new terminal and run:

```bash
echo $PIPER_BIN
echo $PIPER_MODEL
```

If both print correctly, your environment is set.

---

## How many attempts?

The script currently allows **2 attempts per word**:

- “Correct 1st” → got it on attempt 1
- “Correct 2nd” → got it on attempt 2
- Miss both → **Failed** and recorded to the missed list

To change this later, look for:

```ruby
1.upto(2) do |attempt|
```

---

## YAML format

The script supports **two YAML shapes**:

1) **Mapping (Hash)** form (recommended)
2) **List (Array)** form

Each entry needs:
- English: `en` (or hash key in mapping form)
- Finnish: `fi`
- Optional: `phon` (phonetic hint)

### Finnish can be a string *or a list* (synonyms supported)

```yaml
- en: "It’s sunny."
  fi:
    - "Aurinko paistaa."
    - "On aurinkoista."
  phon: "AU-rin-ko PAI-staa / On AU-rin-kois-ta"
```

When an entry has multiple acceptable Finnish answers, the quiz accepts any of them and, after a correct answer, prints:

- `Also accepted: ...`

### 1) Mapping (Hash) form (recommended)

```yaml
Monday:
  fi: maanantai
  phon: MAAN-AHN-TAI

Weekend:
  fi:
    - viikonloppu
    - viikonloppuna
  phon: VEE-KON-LOP-PU / VEE-KON-LOP-PU-na
```

### 2) List (Array) form

```yaml
- en: Monday
  fi: maanantai
  phon: MAAN-AHN-TAI

- en: Weekend
  fi: viikonloppu
  phon: VEE-KON-LOP-PU
```

---

## Output files (missed words)

If you miss at least one word, the script writes:

```
<base>_missed_YYYYMMDD_HHMMSS.yaml
```

Example:

```
finnish_days_of_week_missed_20260218_082428.yaml
```

If you miss nothing, it prints:

```
😊 Ei virheitä — hienoa työtä!
```

…and **no file is written**.

Missed-file payload includes:
- `meta` (timestamp, source file, flags)
- `stats`
- `missed` (the missed entries)

---

## Example sessions

### Match-game (typing)

```text
Finnish Quiz — 8 word(s) (mode: match-game)
--------------------------------------------------

[1/8] English: Thursday
Options:
  - keskiviikko
  - viikonloppu
  - torstai
Type the Finnish word: torstai
✅ Oikein!
   (phonetic: TORS-TAI)

--------------------------------------------------
Results
Total: 8
Correct 1st: 6 (75.0%)
Correct 2nd: 2 (25.0%)
Failed: 0 (0.0%)

😊 Ei virheitä — hienoa työtä!
```

### Listening + match-game (no English)

```text
Finnish Quiz — 8 word(s) (mode: match-game, listen-no-english)
--------------------------------------------------

[1/8]
Audible Finnish: (listening…)
Options:
  - maanantai
  - tiistai
  - viikonloppu
Type what you heard (Finnish): viikonloppu
✅ Oikein!
   (phonetic: VEE-KON-LOP-PU)

--------------------------------------------------
Results
Total: 8
Correct 1st: 7 (87.5%)
Correct 2nd: 1 (12.5%)
Failed: 0 (0.0%)
```

---

## Piper TTS setup

### Where Piper lives (project + ecosystem)
- Piper development is maintained at **https://github.com/OHF-Voice/piper1-gpl** 
- `piper-tts` is distributed on PyPI and installs a `piper` CLI tool
### macOS (recommended): install via Python venv + pip

```bash
python3 -m venv ~/venvs/piper
source ~/venvs/piper/bin/activate
python -m pip install -U pip
pip install piper-tts
piper --help | head
```

Your Piper executable will typically be:

- `~/venvs/piper/bin/piper`

### Windows (recommended): install via Python venv + pip

In PowerShell:

```powershell
py -m venv $HOME\venvs\piper
$HOME\venvs\piper\Scripts\Activate.ps1
python -m pip install -U pip
pip install piper-tts
piper --help
```

Your Piper executable will typically be:

- `%USERPROFILE%\venvs\piper\Scripts\piper.exe` (or `piper` script)

> Note: This Ruby script currently uses macOS `afplay` for audio playback.
> For Windows, you’ll need to either:
> - run Piper to produce WAV and play it with PowerShell, or
> - patch `piper_speak` to use a Windows player.
>
> PRs welcome — the architecture already cleanly isolates playback in `piper_speak`.

### Downloading voice models

A Piper model is **two files**:
- `*.onnx`
- `*.onnx.json` (matching config)

The canonical model collection is **rhasspy/piper-voices** on Hugging Face. 

#### Example: Finnish (fi_FI) — Harri (medium)
Files live under:

- `fi/fi_FI/harri/medium/` 

Download both files into a directory, e.g.:

```bash
mkdir -p ~/tools/piper/models/fi_FI/harri/medium
cd ~/tools/piper/models/fi_FI/harri/medium

curl -L -o fi_FI-harri-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fi/fi_FI/harri/medium/fi_FI-harri-medium.onnx"

curl -L -o fi_FI-harri-medium.onnx.json \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fi/fi_FI/harri/medium/fi_FI-harri-medium.onnx.json"
```

Smoke test:

```bash
echo "Ei kiitos." | piper -m ~/tools/piper/models/fi_FI/harri/medium/fi_FI-harri-medium.onnx -f /tmp/test.wav
afplay /tmp/test.wav
```

---

## Troubleshooting

### “Not enough distractors.”
In match-game mode, the script needs enough **unique** Finnish words in the pool to generate distractors.

Fix: add more vocabulary, or run match-game only on a larger YAML set.

### “Piper binary not found” (common in IDEs)
If you run from IntelliJ/JetBrains IDEs, your shell `export` variables may not carry over.

Fix:
- Set `PIPER_BIN` and `PIPER_MODEL` in the IDE Run Configuration environment, **or**
- Pass `--piper-bin` and `--piper-model` directly as flags.

---

## License / Notes

Personal utility script. Adjust as you like. Kiitos & have fun learning 🇫🇮
