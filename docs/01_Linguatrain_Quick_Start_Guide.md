# Linguatrain Quick Start Guide

## 📚 Documentation

Use the guide that best matches what you're trying to accomplish.

| Guide | Purpose | Current |
|-------|---------|---------|
| **Quick Start Guide** | Install Linguatrain and study your first lesson in approximately 5–10 minutes. | ✅ You are here |
| **Setup & Usage Guide** | Learn the CLI, configuration, study modes, speech support, and advanced features. | |
| **Authoring Handbook** | Learn how to create learning packs and understand Linguatrain's educational philosophy. | |
| **Options-details** | Quick reference to all the options in Linguatrain | |

---

## Prerequisites

Linguatrain intentionally minimizes external dependencies.

To get started you only need:

- Ruby 3.x or later
- Git

The core application uses only the Ruby standard library. Optional integrations such as Piper (text-to-speech) and Whisper (speech recognition) can be installed later. They are **not** required to begin using Linguatrain.

---

## 1. Clone the Repository

```bash
git clone https://github.com/wbrisett/linguatrain.git
cd linguatrain
```

---

## 2. Verify Your Ruby Installation

```bash
ruby --version
```

Ruby 3.x or later is recommended.

---

## 3. Run Your First Learning Pack

Linguatrain studies structured YAML learning packs.

The repository includes several sample packs. For this guide, we'll use the Spanish Basic Phrases pack.

```bash
ruby bin/linguatrain.rb packs/es/es_basic_phrases.yaml
```

If Linguatrain displays the first prompt from the sample pack, your installation is complete.

> **Tip**
>
> If you see:
>
> ```text
> Missing YAML file.
> ```
>
> Linguatrain was started without specifying a learning pack. Every study session begins by providing the path to a YAML learning pack.

You should see output similar to the following:

```text
Source → Target Quiz — 21 word(s) (mode: typing, Source→Target)
---------------------------------------------------------------

[1/21]

Prompt: I would like this

Answer:
```

---

## 4. Repository Layout

At this stage you only need to recognize a few important locations in the repository.

```text
linguatrain/
├── README.md
├── docs/
├── packs/
├── bin/
└── tools/
```

| Location | Purpose |
|----------|---------|
| **README.md** | Project overview and introduction (displayed on the GitHub project page). |
| **docs/** | User and developer documentation. |
| **packs/** | Sample learning packs and the location for your own learning content. |
| **bin/** | Executable command-line programs, including `linguatrain.rb`. |
| **tools/** | Utilities for creating, converting, and maintaining learning packs. |

---

## Optional Components

Linguatrain can optionally integrate with:

- **Piper** — Text-to-speech
- **Whisper** — Speech recognition

These components are not required to begin studying and can be installed at any time. Installation and configuration are covered in the **Setup & Usage Guide**.

---

# Congratulations!

Linguatrain is now installed and ready to use.

Continue with the guide that best matches what you would like to do next.

| If you want to... | Read |
|-------------------|------|
| Learn the CLI, study modes, configuration, and advanced features. | **Setup & Usage Guide** |
| Create your own learning packs. | **Authoring Handbook** |

**You’re now ready to begin your learning journey.**
