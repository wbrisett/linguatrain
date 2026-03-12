
# Whisper Installation (for `--speak` mode)

## Overview

The `--speak` mode in Linguatrain allows you to **practice speaking answers aloud** instead of typing them.

When `--speak` is enabled, Linguatrain:

1. Records your voice
2. Uses **OpenAI Whisper** to transcribe what you said
3. Compares the transcription against the accepted answers

This allows you to practice **pronunciation and recall at the same time**.

---

# Requirements

`--speak` requires:

- Python 3.9+
- Whisper
- FFmpeg
- A working microphone

---

# 1. Install Python

Check if Python is installed:

```bash
python3 --version
```

If not installed, install it:

### macOS

```bash
brew install python
```

### Ubuntu / Debian

```bash
sudo apt install python3 python3-pip
```

---

# 2. Install FFmpeg

Whisper depends on FFmpeg for audio processing.

### macOS

```bash
brew install ffmpeg
```

### Ubuntu / Debian

```bash
sudo apt install ffmpeg
```

Verify installation:

```bash
ffmpeg -version
```

---

# 3. Install Whisper

Install Whisper using pip:

```bash
pip install openai-whisper
```

This will install:

- Whisper
- PyTorch
- dependencies needed for speech recognition

Verify installation:

```bash
python3 -c "import whisper; print('Whisper installed')"
```

---

# 4. First Whisper Model Download

The first time Whisper runs it will download a speech model automatically.

Typical models:

| Model | Size | Speed | Accuracy |
|------|------|------|------|
| tiny | ~75 MB | very fast | lowest |
| base | ~142 MB | fast | good |
| small | ~466 MB | slower | better |
| medium | ~1.5 GB | slow | very good |

Linguatrain typically uses the **`base`** model by default.

The model downloads automatically on first use.

---

# 5. Test Whisper

You can test Whisper independently:

```bash
python3 -m whisper audio.wav
```

If Whisper prints a transcription, it is working.

---

# 6. Using Speak Mode in Linguatrain

Example:

```bash
ruby linguatrain.rb packs/fi/finnish_numbers.yaml --speak
```

Workflow:

1. Prompt appears
2. Press **Enter** to start recording
3. Speak your answer
4. Whisper transcribes it
5. Linguatrain checks if the answer matches

Example session:

```
English: How are you?

🎤 Speak now...
🎙 Recording (5s window)...

🟡 Close enough
   Heard: Mita kuluu
```

---

# 7. Configuration (Optional)

Recording duration can be configured in the runtime configuration:

```yaml
runtime:
  audio_record_seconds: 5
```

Increasing this value allows longer spoken answers.

---

# 8. Troubleshooting

## Whisper not found

Install again:

```bash
pip install openai-whisper
```

## FFmpeg missing

Install FFmpeg:

```bash
brew install ffmpeg
```

or

```bash
sudo apt install ffmpeg
```

## Microphone not recording

Test microphone input:

```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

(macOS)

---

# Notes

Whisper transcription is **approximate**, so Linguatrain uses **lenient matching** when comparing spoken answers.

This allows minor pronunciation differences or transcription errors while still validating correct answers.

