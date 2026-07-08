# Configuration File Setup

A configuration file is optional, but recommended if you want to enable features such as UI localisation or Text‑to‑Speech using Piper.

The file is a simple YAML document that defines paths and runtime settings used by linguatrain.

## Configuration Template

The following is a minimal configuration template:

```yaml
runtime:
  audio_player:

piper:
  bin:
  models:

# Global fallback settings
defaults:
  tts_template: "Target language: {text}."

localisation:
```

------------------------------------------------------------------------

## Config File Location

The following locations are where you should install the config.yaml file for linguatrain.

### Linux and macOS

Default location:

    ~/.config/linguatrain/config.yaml

Create the directory:

``` bash
mkdir -p ~/.config/linguatrain
```

------------------------------------------------------------------------

### Windows

Default location:

    %APPDATA%\linguatrain\config.yaml

Which typically resolves to:

    C:\Users\<YourUser>\AppData\Roaming\linguatrain\config.yaml

Create the directory in PowerShell:

``` powershell
mkdir $env:APPDATA\linguatrain
notepad $env:APPDATA\linguatrain\config.yaml
```

------------------------------------------------------------------------

#### runtime: audio_player

audio_player defines what audio player should be used to play the .wav file piper produces. 

- macOS: `"afplay"`
- Linux: a CLI audio player such as `"aplay"` or `"paplay"`
- Windows: PowerShell `.NET` Media.SoundPlayer


##### macOS and Linux

```yaml
runtime:
  audio_player: "afplay"
```  

##### Windows

Since Windows does not ship with a simple CLI WAV player like macOS or Linux. The most reliable approach is to use PowerShell’s built-in .NET audio player.

```yaml
runtime:
  audio_player: "powershell -c (New-Object Media.SoundPlayer '%s').PlaySync();"
```

#### `piper.bin`

Full path to the Piper executable.

#### `piper.models`

Maps a language code to the Piper voice model that should be used for that language.

The language code must match the code used in your localisation file or language pack. Typically this follows the **BCP‑47 format**, for example:

- `fi-FI`
- `es-MX`
- `es-AR`

Example configuration:

```yaml
piper:
  bin: "/path/to/piper"
  models:
    fi-FI: "/path/to/model.onnx"
```

Example for Spanish: 
```yaml
piper:
  bin: "/Users/wayneb/venvs/piper/bin/piper"
  
  models: 
    es-MX: "/Users/wayneb/tools/piper/models/es_MX/claude/high/es_MX-claude-high.onnx"
```

Windows example paths:

```yaml
piper:
  bin: "C:\\Users\\<YourUser>\\venvs\\piper\\Scripts\\piper.exe"
  models:
    fi-FI: "C:\\Users\\<YourUser>\\models\\fi_FI-harri-medium.onnx"
```

### defaults

The `defaults` block defines global fallback values used when language packs do not specify overrides.

#### `defaults.tts_template`

The `tts_template` defines a **carrier phrase** used when generating audio. Some text‑to‑speech engines perform poorly when asked to speak isolated words, so the template wraps the word or phrase in a short sentence.

The `{text}` placeholder is replaced with the target word or phrase.

In most cases, the default value is sufficient:

```yaml
defaults:
  tts_template: "Target language: {text}."   # safe generic default
```

### `localisation`

Specifies the localisation file used to translate UI labels and optional TTS templates.

This path typically points to a file inside the repository's `localisation/` directory, but it may reference any valid path on your system.

Example:

```yaml
localisation: "localisation/en-US_fi-FI.yaml"
```
