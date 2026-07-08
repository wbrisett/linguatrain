# Installing Piper and Piper Voice Models *(optional)*

'piper` is used for Text-to-Speech. In order to use `--listen` you must have Piper installed and configured. 

Listening modes require Piper to be installed and configured.

------------------------------------------------------------------------

## Install Python (if needed)

Piper requires Python 3.9 or later.

Check your version:

``` bash
python3 --version
```

If Python is not installed, download it from:

https://www.python.org/downloads/

------------------------------------------------------------------------

## Create a Virtual Environment (Recommended)

Creating an isolated virtual environment keeps Piper separate from your system Python.

### macOS / Linux

``` bash
python3 -m venv ~/venvs/piper
source ~/venvs/piper/bin/activate
```

### Windows (PowerShell)

``` powershell
python -m venv $env:USERPROFILE\venvs\piper
$env:USERPROFILE\venvs\piper\Scripts\Activate.ps1
```

------------------------------------------------------------------------

### Install Piper TTS

Once your virtual environment is activated:

``` bash
pip install --upgrade pip
pip install piper-tts
```

Verify installation:

``` bash
piper --help
```

If installed correctly, Piper will print usage instructions.

------------------------------------------------------------------------

## Download Voice Models

Official Piper voices are hosted here:

https://huggingface.co/rhasspy/piper-voices/tree/main

Each voice requires:

-   A `.onnx` model file
-   A matching `.onnx.json` configuration file

It is best to download medium and high resolution voice models. 

## Example: Finnish (Harri Medium)

Navigate to:

    fi/fi_FI/harri/medium/

Download:

-   `fi_FI-harri-medium.onnx`
-   `fi_FI-harri-medium.onnx.json`

Place them in a directory such as:

    ~/models/piper/fi-FI/

------------------------------------------------------------------------

## Test the Voice Model

From your activated environment:

``` bash
echo "Hei maailma." | piper -m ~/models/piper/fi-FI/fi_FI-harri-medium.onnx -f test.wav
```

Play the file:

### macOS

``` bash
afplay test.wav
```

### Linux

``` bash
aplay test.wav
```

### Windows

``` powershell
start test.wav
```

If you hear speech, the installation is successful.

