# Getting Started

Let’s walk through the minimal setup.

## 1. Install Ruby

You need Ruby 3.x or later.

Check:

```bash
ruby -v
```

If you need to install it, use your preferred version manager (`rbenv`, `RVM`, `asdf`) or your system package manager.

No additional gems are required as everything runs on the Ruby standard library.

---

## 2. Clone the Repository

```bash
git clone https://github.com/wbrisett/linguatrain.git
cd linguatrain
```

Run a pack immediately:

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml
```

That’s enough to get started, although if you don't know Finnish, probably best to use: 

```bash
ruby bin/linguatrain.rb packs/fi/finnish_everyday_phrases.yaml --study
```

---

## 3. Understanding the Folder Layout

Here’s what matters:

```text
linguatrain/
├── bin/              # CLI and helper utilities
├── packs/            # Your YAML packs live here
├── localisation/     # Optional UI language files
├── docs/             # YAML spec and deeper documentation
└── README.md
```

The important directory is:

```text
packs/
```

That’s where your study material lives.

You can organize it as you like, however as best practice, use the two letter language code:

```text
packs/
  fi/
  es/
  de/
```

There’s also a `templates/` folder with starter pack YAML examples.

---

## More Details

For more details see:

- Piper Setup
- Config File Setup
- YAML Pack Setup
- Localisation Templates
- Command Options
