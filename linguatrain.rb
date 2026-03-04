#!/usr/bin/env ruby
# frozen_string_literal: true

# linguatrain.rb
# Language quiz CLI (typing / match-game / listening via Piper)

require "yaml"
require "time"
require "optparse"
require "securerandom"
require "digest"
require "fileutils"

# -----------------------------
# Utility
# -----------------------------

# Custom exception for quit handling (so SRS can be saved)
class QuitQuiz < StandardError; end

def say(msg = "")
  puts msg
end

# -----------------------------
# Deprecation warnings
# -----------------------------

$DEPRECATION_WARNED ||= {}

def warn_once(key, msg)
  return if ENV["LINGUATRAIN_NO_WARNINGS"]
  return if $DEPRECATION_WARNED[key]

  $DEPRECATION_WARNED[key] = true
  warn msg
end

# Emit a single formatted deprecation warning block per pack file.
def warn_pack_deprecations(pack_path, messages)
  return if ENV["LINGUATRAIN_NO_WARNINGS"]
  return if messages.nil? || messages.empty?

  key = "pack_deprecations_#{File.expand_path(pack_path)}"
  return if $DEPRECATION_WARNED[key]

  $DEPRECATION_WARNED[key] = true

  sep = "*" * 48
  warn sep
  warn "* DEPRECATION"
  warn "*"
  warn "* Pack file '#{pack_path}'"
  warn "*"
  warn "* Contains:"
  messages.each do |m|
    warn "* #{m}"
  end
  warn "*"
  warn sep
  warn ""
end

# -----------------------------
# Configuration (user config + pack metadata)
# -----------------------------

DEFAULT_USER_CONFIG_PATHS = [
  File.join(Dir.home, ".config", "linguatrain", "config.yaml"),
  # Back-compat with earlier naming/location
  File.join(Dir.home, ".config", "finn_quiz", "config.yaml")
].freeze

DEFAULT_UI = {
  language_name: "Language",
  quiz_label: "Quiz",
  correct: "✅ Correct!",
  try_again: "Try again.",
  correct_answer_prefix: "❌ Correct answer:",
  correct_word_prefix: "❌ Correct word:",
  replay_hint: "(Type 'r' to replay audio)",
  also_accepted_prefix: "Also accepted:",
  phonetic_prefix: "phonetic",
  prompt_prefix: "Prompt",
  source_language_name: "Source",
  target_language_name: "Target",
  target_prefix: "Answer",
  quit_message: "👋 Exiting quiz."
}.freeze

DEFAULT_TTS_TEMPLATE = "Target language: {text}."
DEFAULT_AUDIO_PLAYER = "afplay" # macOS default

def symbolize_keys_deep(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), out|
      key = k.is_a?(String) ? k.to_sym : k
      out[key] = symbolize_keys_deep(v)
    end
  when Array
    obj.map { |v| symbolize_keys_deep(v) }
  else
    obj
  end
end

# Deeply convert all hash keys to strings (for YAML output).
def stringify_keys_deep(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), out|
      key = k.is_a?(Symbol) ? k.to_s : k.to_s
      out[key] = stringify_keys_deep(v)
    end
  when Array
    obj.map { |v| stringify_keys_deep(v) }
  else
    obj
  end
end

def load_yaml_hash(path)
  return {} if path.nil?
  p = path.to_s.strip
  return {} if p.empty?
  return {} unless File.exist?(p)

  data = YAML.load_file(p)
  data = {} unless data.is_a?(Hash)
  symbolize_keys_deep(data)
rescue StandardError
  {}
end

def first_existing_path(paths)
  Array(paths).find { |p| p && !p.to_s.strip.empty? && File.exist?(p.to_s) }
end

def deep_merge_hash(a, b)
  a = (a || {}).dup
  (b || {}).each do |k, v|
    if a[k].is_a?(Hash) && v.is_a?(Hash)
      a[k] = deep_merge_hash(a[k], v)
    else
      a[k] = v
    end
  end
  a
end

# Helper to strip localisation-owned metadata from pack metadata when generating missed packs.
def strip_localisation_meta(pack_meta)
  m = (pack_meta || {}).dup
  m.delete(:ui)
  m.delete(:languages)
  m.delete(:tts)
  m
end

def resolve_user_config_path(cli_path)
  return cli_path if cli_path && !cli_path.to_s.strip.empty?
  env_path = ENV["LINGUATRAIN_CONFIG"]
  return env_path if env_path && !env_path.to_s.strip.empty?
  first_existing_path(DEFAULT_USER_CONFIG_PATHS)
end

def resolve_localisation_path(cli_path, user_cfg, user_cfg_path)
  # Precedence: CLI > ENV > config.yaml
  return cli_path if cli_path && !cli_path.to_s.strip.empty?

  env_path = ENV["LINGUATRAIN_LOCALISATION"]
  return env_path if env_path && !env_path.to_s.strip.empty?

  cfg_path = user_cfg.dig(:localisation)
  return nil if cfg_path.nil? || cfg_path.to_s.strip.empty?

  raw = cfg_path.to_s.strip

  # Absolute path: use as-is.
  return raw if raw.start_with?("/") || raw =~ /^[A-Za-z]:[\\\/]/

  # Relative path: try from current working directory first (repo-friendly),
  # then relative to the config.yaml directory (user-config-friendly).
  cwd_candidate = File.expand_path(raw, Dir.pwd)
  return cwd_candidate if File.exist?(cwd_candidate)

  if user_cfg_path && !user_cfg_path.to_s.strip.empty?
    cfg_dir = File.dirname(File.expand_path(user_cfg_path))
    cfg_candidate = File.expand_path(raw, cfg_dir)
    return cfg_candidate if File.exist?(cfg_candidate)
  end

  # Fall back to CWD-expanded path (caller validates existence)
  cwd_candidate
end

def load_localisation(path)
  return {} if path.nil? || path.to_s.strip.empty?
  raise "Localisation file not found: #{path}" unless File.exist?(path)

  data = YAML.load_file(path)
  data = {} unless data.is_a?(Hash)
  loc = symbolize_keys_deep(data)

  # One file = one UI language. Validate required keys.
  missing = []
  missing << "languages.source.code" if loc.dig(:languages, :source, :code).to_s.strip.empty?
  missing << "languages.target.code" if loc.dig(:languages, :target, :code).to_s.strip.empty?
  missing << "ui" unless loc[:ui].is_a?(Hash)

  unless missing.empty?
    raise "Invalid localisation YAML (#{path}). Missing/invalid: #{missing.join(', ')}"
  end

  loc
end

def effective_meta(pack_meta, localisation)
  # Languages come from localisation; pack may still contain other metadata (back-compat).
  merged = deep_merge_hash({ languages: localisation[:languages] }, (pack_meta || {}))

  # If pack doesn't specify a TTS template, take localisation's default.
  if merged.dig(:tts, :template).to_s.strip.empty? && localisation.dig(:tts, :template)
    merged = deep_merge_hash(merged, { tts: { template: localisation.dig(:tts, :template) } })
  end

  merged
end

def resolve_piper_model(options, user_cfg, pack_meta)
  # CLI/ENV already landed in options[:piper_model]. If present, keep it.
  return options[:piper_model] if options[:piper_model] && !options[:piper_model].to_s.strip.empty?

  # Prefer per-language model mapping if we know the target language code.
  target_code = pack_meta.dig(:languages, :target, :code)
  mapped = user_cfg.dig(:piper, :models, target_code.to_sym) || user_cfg.dig(:piper, :models, target_code) if target_code
  return mapped if mapped && !mapped.to_s.strip.empty?

  # Fallback single model if provided.
  fallback = user_cfg.dig(:piper, :model)
  return fallback if fallback && !fallback.to_s.strip.empty?

  nil
end

def resolve_settings!(options, user_cfg, pack_meta)
  # Runtime
  options[:audio_player] ||= user_cfg.dig(:runtime, :audio_player) || DEFAULT_AUDIO_PLAYER

  # Piper
  options[:piper_bin] ||= user_cfg.dig(:piper, :bin)
  options[:piper_model] = resolve_piper_model(options, user_cfg, pack_meta)

  # TTS template: pack overrides user defaults
  options[:tts_template] ||= user_cfg.dig(:defaults, :tts_template)
  options[:tts_template] = pack_meta.dig(:tts, :template) || options[:tts_template] || DEFAULT_TTS_TEMPLATE

  # UI strings: defaults < localisation (one file = one UI language)
  ui = deep_merge_hash(DEFAULT_UI, options[:localisation_ui])

  # Provide language name if pack has it.
  ui[:language_name] = pack_meta.dig(:languages, :target, :name) if pack_meta.dig(:languages, :target, :name)

  ui[:source_language_name] = pack_meta.dig(:languages, :source, :name) if pack_meta.dig(:languages, :source, :name)
  ui[:target_language_name] = pack_meta.dig(:languages, :target, :name) if pack_meta.dig(:languages, :target, :name)
  ui[:target_prefix] ||= ui[:target_language_name] || ui[:language_name] || "Answer"

  options[:ui] = ui

  options
end

def prompt(msg)
  print msg
  STDOUT.flush
  input = STDIN.gets&.chomp

  return nil if input.nil?

  trimmed = input.strip.downcase

  if trimmed == "quit" || trimmed == "q"
    print "Are you sure you want to quit? (y/N): "
    STDOUT.flush
    confirm = STDIN.gets&.chomp

    if confirm && confirm.strip.downcase == "y"
      puts
      puts((defined?($UI) && $UI[:quit_message]) ? $UI[:quit_message] : "👋 Exiting quiz.")
      raise QuitQuiz
    else
      return ""  # Return empty input so quiz continues
    end
  end

  input
end

def normalize_basic(s)
  t = s.to_s.strip

  # Normalize Unicode to canonical form
  t = t.unicode_normalize(:nfkc) rescue t

  # Normalize curly quotes to straight quotes
  t = t.gsub(/[’‘]/, "'")
  t = t.gsub(/[“”]/, '"')

  t.downcase
end

def strip_terminal_punct(s)
  s.to_s.strip.sub(/[.!?]+\z/, "")
end

def normalize_lenient_umlauts(s)
  normalize_basic(s).tr("äö", "ao")
end

def pct(part, total)
  return 0.0 if total.to_i <= 0
  (part.to_f / total.to_f) * 100.0
end

# -----------------------------
# Text-to-Speech (Piper)
# -----------------------------

def ensure_terminal_punct(s)
  t = s.to_s.strip
  return t if t.empty?
  t =~ /[.!?]\z/ ? t : "#{t}."
end

def resolve_executable(cmd)
  return nil if cmd.nil?
  c = cmd.to_s.strip
  return nil if c.empty?

  # If an absolute/relative path was provided, trust it.
  return c if File.exist?(c)

  # Otherwise try PATH lookup.
  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
    next if dir.nil? || dir.empty?
    candidate = File.join(dir, c)
    return candidate if File.exist?(candidate)
  end

  nil
end

def piper_speak(text, piper_bin:, piper_model:)
  resolved_piper = resolve_executable(piper_bin)
  raise "Piper binary not found: #{piper_bin}.\nPATH=#{ENV.fetch('PATH', '')}" unless resolved_piper
  raise "Piper model not found: #{piper_model}" unless piper_model && File.exist?(piper_model)

  wav = File.join("/tmp", "linguatrain_tts_#{Process.pid}_#{SecureRandom.hex(4)}.wav")

  ok = IO.popen([resolved_piper, "-m", piper_model, "-f", wav], "r+") do |io|
    io.write(text.to_s)
    io.write("\n")
    io.close_write
    io.read
    true
  rescue StandardError
    false
  end

  raise "Piper failed to generate audio." unless ok && File.exist?(wav)

  # Audio playback (command can be a String or an Array of args)
  player = (defined?($AUDIO_PLAYER) && $AUDIO_PLAYER) ? $AUDIO_PLAYER : DEFAULT_AUDIO_PLAYER

  ok_play =
    if player.is_a?(Array)
      cmd = player.map(&:to_s)
      exe = resolve_executable(cmd.first)
      raise "Audio player not found: #{cmd.first}.\nPATH=#{ENV.fetch('PATH', '')}" unless exe
      system(exe, *cmd.drop(1), wav)
    else
      exe = resolve_executable(player.to_s)
      raise "Audio player not found: #{player}.\nPATH=#{ENV.fetch('PATH', '')}" unless exe
      system(exe, wav)
    end

  raise "Audio playback failed (#{player})." unless ok_play
ensure
  File.delete(wav) if wav && File.exist?(wav)
end

def speak_target_prompt(text, piper_bin:, piper_model:, template: DEFAULT_TTS_TEMPLATE)
  spoken = template.gsub("{text}", ensure_terminal_punct(text.to_s.strip))
  piper_speak(spoken, piper_bin: piper_bin, piper_model: piper_model)
end

# In listen modes, allow the user to type 'r' to replay the audio.
# Returns the user's non-replay input (may be nil on EOF).
def prompt_with_replay(msg, spoken_text, piper_bin:, piper_model:, template:)
  loop do
    input = prompt(msg)
    return nil if input.nil?

    if input.strip.casecmp("r").zero?
      speak_target_prompt(spoken_text, piper_bin: piper_bin, piper_model: piper_model, template: template)
      next
    end

    return input
  end
end

# -----------------------------
# YAML Loading
# -----------------------------

def load_pack(path)
  data = YAML.load_file(path)

  raw_entries =
    if data.is_a?(Array)
      data
    elsif data.is_a?(Hash)
      # New Linguatrain schema:
      #   metadata: {...}
      #   entries:  [ {id:, prompt:, alternate_prompts:, answer:, phonetic:}, ... ]
      pack_meta = data["metadata"] || data[:metadata] || {}

      # Deprecation: localisation now owns UI strings and language metadata.
      # Packs should contain only pack identity + entries (and optional overrides).
      if pack_meta.is_a?(Hash)
        deprecations = []

        if (pack_meta.key?("ui") || pack_meta.key?(:ui))
          deprecations << "metadata.ui. Move UI strings into a localisation file (localisation/*.yaml) and reference it via config.yaml 'localisation:' or --localisation."
        end

        if (pack_meta.key?("languages") || pack_meta.key?(:languages))
          deprecations << "metadata.languages. Move language codes/names into the localisation file (localisation/*.yaml)."
        end

        tts = pack_meta["tts"] || pack_meta[:tts]
        if tts.is_a?(Hash) && (tts.key?("template") || tts.key?(:template))
          deprecations << "metadata.tts.template. Move the default template into localisation (tts.template). Keep pack-level overrides only if truly pack-specific."
        end

        warn_pack_deprecations(path, deprecations)
      end

      entries = data["entries"] || data[:entries]
      if entries.is_a?(Array)
        entries
      else
        # Legacy support (kept for backward compatibility):
        # A) {items: [ ... ], meta: {...}}  -> use items
        # B) {pairs: [ {a:{fi,en,phon}, b:{fi,en,phon}}, ... ], meta:{...}} -> expand pairs
        # C) Mapping form: "English" => {fi:, phon:}
        # D) Grouped form: "Group name" => [ {english/en:, finnish/fi:, ...}, ... ]

        items = data["items"] || data[:items]
        if items.is_a?(Array)
          items
        else
          pairs = data["pairs"] || data[:pairs]
          if pairs.is_a?(Array)
            pairs.flat_map do |p|
              a = p["a"] || p[:a] || {}
              b = p["b"] || p[:b] || {}

              [a, b].map do |side|
                {
                  "en" => side["en"] || side[:en] || side["english"] || side[:english],
                  "fi" => side["fi"] || side[:fi] || side["finnish"] || side[:finnish],
                  "phon" => side["phon"] || side[:phon] || side["phonetic"] || side[:phonetic]
                }
              end
            end
          else
            data.flat_map do |key, v|
              # Ignore top-level metadata blocks commonly named 'meta'
              next [] if key.to_s.strip.downcase == "meta"

              v ||= {}

              if v.is_a?(Array)
                v
              elsif v.is_a?(Hash)
                fi_val = v["fi"] || v[:fi] || v["finnish"] || v[:finnish]
                phon_val = v["phon"] || v[:phon] || v["phonetic"] || v[:phonetic]
                fi_val.nil? ? [] : [{ "en" => key, "fi" => fi_val, "phon" => phon_val }]
              else
                []
              end
            end
          end
        end
      end
    else
      raise "Unsupported YAML structure."
    end

  pack_meta ||= {}

  raw_entries.map do |w|
    # Preserve/assign entry id
    entry_id = w["id"] || w[:id]

    # Legacy keys
    en = w["en"] || w[:prompt] || w["english"] || w[:english]
    fi = w["fi"] || w[:answer] || w["finnish"] || w[:finnish]
    spoken_v = w["spoken"] || w[:spoken]
    phon = w["phon"] || w[:phonetic] || w["phonetic"] || w[:phonetic]

    # New schema keys
    prompt_v = w["prompt"] || w[:prompt]
    alt_prompts_v = w["alternate_prompts"] || w[:alternate_prompts]
    answer_v = w["answer"] || w[:answer]
    spoken_field_v = w["spoken"] || w[:spoken]
    phonetic_v = w["phonetic"] || w[:phonetic]

    # If we have new-schema fields, map them into the legacy variables used below.
    if en.nil? && !prompt_v.nil?
      en = prompt_v
    end

    if fi.nil? && !answer_v.nil?
      fi = answer_v
    end

    # Optional spoken/colloquial form (generic; used by listening mode when present)
    spoken_v = spoken_field_v if (spoken_v.nil? || spoken_v.to_s.strip.empty?) && !spoken_field_v.nil?

    if (phon.nil? || phon.to_s.strip.empty?) && !phonetic_v.nil?
      phon = phonetic_v
    end

    raise "Invalid word entry: #{w.inspect}" if en.nil? || fi.nil?

    en_list =
      case en
      when Array
        en.map { |x| x.to_s.strip }.reject(&:empty?)
      else
        [en.to_s.strip]
      end

    # New schema: include alternate_prompts as additional accepted English variants.
    if alt_prompts_v.is_a?(Array)
      en_list.concat(alt_prompts_v.map { |x| x.to_s.strip }.reject(&:empty?))
    elsif alt_prompts_v.is_a?(String) && !alt_prompts_v.strip.empty?
      en_list << alt_prompts_v.strip
    end

    en_list = en_list.uniq

    fi_list =
      case fi
      when Array
        fi.map { |x| x.to_s.strip }.reject(&:empty?)
      else
        [fi.to_s.strip]
      end

    spoken_list =
      case spoken_v
      when Array
        spoken_v.map { |x| x.to_s.strip }.reject(&:empty?)
      when NilClass
        []
      else
        [spoken_v.to_s.strip].reject(&:empty?)
      end

    raise "Invalid word entry: #{w.inspect}" if en_list.empty? || fi_list.empty?

    # Preserve pack entry id when present; otherwise derive a stable short id.
    derived_id = Digest::SHA1.hexdigest("#{en_list.join('|')}::#{fi_list.join('|')}")[0, 8]
    { id: (entry_id.nil? ? derived_id : entry_id.to_s.strip), prompt: en_list, answer: fi_list, spoken: spoken_list, phonetic: phon.to_s.strip }
  end.then do |words|
    { meta: symbolize_keys_deep(pack_meta), words: words }
  end
end


def choose_words(words, count)
  return words.shuffle if count.nil? || count == "all"

  n = Integer(count)
  words.shuffle.take([n, words.length].min)
end

# -----------------------------
# Matching Logic
# -----------------------------

def match_answer(user, expected_list, lenient:)
  user_n = normalize_basic(strip_terminal_punct(user))
  exp_norms = expected_list.map { |e| normalize_basic(strip_terminal_punct(e)) }

  if (idx = exp_norms.index(user_n))
    return [:exact, true, expected_list[idx]]
  end
  return [:no, false, nil] unless lenient

  user_l = normalize_lenient_umlauts(strip_terminal_punct(user))
  exp_len = expected_list.map { |e| normalize_lenient_umlauts(strip_terminal_punct(e)) }

  if (idx = exp_len.index(user_l))
    return [:umlaut_lenient, true, expected_list[idx]]
  end

  [:no, false, nil]
end


def pick_distractors(pool, correct_list, field: :answer, n: 2)
  all_correct = correct_list.to_a

  candidates =
    pool.flat_map do |w|
      case field
      when :either
        Array(w[:answer]) + Array(w[:spoken])
      else
        Array(w[field])
      end
    end
        .map { |x| x.to_s.strip }
        .reject(&:empty?)
        .uniq - all_correct

  raise "Not enough distractors." if candidates.size < n
  candidates.sample(n)
end


# -----------------------------
# SRS (Spaced Repetition)
# -----------------------------

def word_id(w)
  Digest::SHA1.hexdigest("#{w[:prompt].join('|')}::#{w[:answer].join('|')}")
end

def default_srs_path(yaml_path, pack_meta = {})
  pack_id = pack_meta.dig(:id)
  base =
    if pack_id && !pack_id.to_s.strip.empty?
      pack_id.to_s.strip
    else
      File.basename(yaml_path, File.extname(yaml_path))
    end

  File.join(Dir.home, ".config", "linguatrain", "srs", "#{base}.yaml")
end

def load_srs(path)
  return { "meta" => {}, "items" => {} } unless path && File.exist?(path)
  data = YAML.load_file(path)
  data.is_a?(Hash) ? data : { "meta" => {}, "items" => {} }
rescue StandardError
  { "meta" => {}, "items" => {} }
end

def save_srs(path, srs)
  return unless path
  FileUtils.mkdir_p(File.dirname(path))
  srs["meta"] ||= {}
  srs["items"] ||= {}
  srs["meta"]["updated_at"] = Time.now.iso8601
  File.write(path, YAML.dump(srs))
end

def due?(item)
  due_at = item["due_at"]
  return true if due_at.nil? || due_at.to_s.strip.empty?
  Time.parse(due_at) <= Time.now
rescue StandardError
  true
end

def ensure_srs_item!(srs, id)
  srs["items"] ||= {}
  srs["items"][id] ||= {
    "reps" => 0,
    "interval_days" => 0,
    "ease" => 2.5,
    "due_at" => Time.now.iso8601,
    "lapses" => 0
  }
end

def update_srs!(srs, id, quality)
  item = ensure_srs_item!(srs, id)
  q = quality.to_i
  now = Time.now

  reps = item["reps"].to_i
  interval = item["interval_days"].to_i
  ease = item["ease"].to_f

  if q < 3
    item["lapses"] = item["lapses"].to_i + 1
    item["reps"] = 0
    item["interval_days"] = 0
    item["due_at"] = (now + 10 * 60).iso8601
    return
  end

  # SM-2 style ease update
  ease += (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  ease = 1.3 if ease < 1.3

  reps += 1
  interval =
    if reps == 1
      1
    elsif reps == 2
      6
    else
      [(interval * ease).round, 1].max
    end

  item["ease"] = ease
  item["reps"] = reps
  item["interval_days"] = interval
  item["due_at"] = (now + interval * 86_400).iso8601
end

def select_words_srs(words, count, srs, new_count:, due_only: false)
  now = Time.now

  due_words = []
  new_words = []
  other_words = []

  words.each do |w|
    id = word_id(w)
    item = srs.dig("items", id)

    if item.nil?
      new_words << w
    elsif due?(item)
      due_words << w
    else
      other_words << w
    end
  end

  selected = []

  # Due first
  selected.concat(due_words.shuffle)

  # Then new
  unless due_only
    n_new = new_count.to_i
    n_new = 0 if n_new < 0
    selected.concat(new_words.shuffle.take(n_new))
  end

  # Fill remainder (optionally) from other buckets
  if !due_only
    selected.concat(new_words.shuffle.drop(new_count.to_i))
    selected.concat(other_words.shuffle)
  end

  selected = selected.uniq

  return selected if count.nil? || count == "all"

  n = Integer(count)
  selected.take([n, selected.length].min)
end

def choose_tts_text(word, tts_variant)
  v = tts_variant.to_s.strip.downcase
  if v == "spoken" && word[:spoken] && !word[:spoken].empty?
    word[:spoken].sample
  else
    word[:answer].sample
  end
end

def expected_answer_list(word, answer_variant)
  v = answer_variant.to_s.strip.downcase

  written = word[:answer] || []
  spoken  = word[:spoken] || []

  case v
  when "spoken"
    spoken.empty? ? written : spoken
  when "either"
    (written + spoken).map { |x| x.to_s.strip }.reject(&:empty?).uniq
  else
    written
  end
end

def format_variants_for_display(word)
  written = (word[:answer] || []).first.to_s.strip
  spoken  = (word[:spoken] || []).first.to_s.strip

  return written if spoken.empty?
  return spoken if written.empty?

  "#{written} / #{spoken}"
end


# Helper for phonetic label
def phonetic_label(ui)
  (ui && ui[:phonetic_prefix] ? ui[:phonetic_prefix].to_s : "phonetic").strip
end

def format_phonetic(ui, phon)
  label = phonetic_label(ui)
  label = label.sub(/:\z/, "")
  "#{label}: #{phon}"
end

def say_reverse_listen_reveal(w, ui)
  fi = (w[:answer] || []).first.to_s.strip
  phon = w[:phonetic].to_s.strip
  return if fi.empty?

  if phon.empty?
    say "   #{fi}"
  else
    say "   #{fi} - (#{format_phonetic(ui, phon)})"
  end
end

def centered_prompt(indent, text)
  prompt("#{indent}#{text}")
end

# ----------------------------
# Study Engine
# ----------------------------
def run_study(selected, reverse:, listen:, listen_no_english:, piper_bin:, piper_model:, tts_template:, ui:, tts_variant:, answer_variant:, show_variants:)
  say

  src_name = ui[:source_language_name] || "Source"
  tgt_name = ui[:target_language_name] || ui[:language_name] || "Target"

  title_dir = reverse ? "#{tgt_name} → #{src_name}" : "#{src_name} → #{tgt_name}"
  mode = ["study"]
  mode << "listen" if listen
  mode << (reverse ? "#{tgt_name}→#{src_name}" : "#{src_name}→#{tgt_name}")

  say "#{title_dir} #{ui[:quiz_label] || 'Quiz'} — #{selected.length} item(s) (mode: #{mode.join(', ')})"
  say "-" * 50

  width = (IO.console.winsize[1] rescue 80)
  indent = " " * [((width - 40) / 2), 0].max

  selected.each_with_index do |w, idx|
    say
    say "[#{idx + 1}/#{selected.length}]"
    say

    prompt_text = w[:prompt].join(" / ")
    answer_text =
      if show_variants
        format_variants_for_display(w)
      else
        expected_answer_list(w, answer_variant).join(" / ")
      end
    phon = w[:phonetic].to_s.strip

    # Audio always speaks the TARGET side (tgt language).
    spoken_target = choose_tts_text(w, tts_variant)

    if reverse
      # Target → Source: show target first (Finnish), then reveal source (English)
      front_label = ui[:target_prefix] || tgt_name
      say "#{front_label}: #{answer_text}"
      say

      if listen
        speak_target_prompt(spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{indent}#{ui[:replay_hint] || "(Type 'r' to replay audio)"}"
      end

      centered_prompt(indent, "(Enter to reveal; q to quit): ")
      say

      back_label = ui[:prompt_prefix] || src_name
      say "#{back_label}: #{prompt_text}"
      say "(#{format_phonetic(ui, phon)})" unless phon.empty?
      say

      if listen
        prompt_with_replay("(Enter for next; 'r' to replay; q to quit): ", spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
      else
        prompt("(Enter for next; q to quit): ")
      end
    else
      # Source → Target: show source first (English), then reveal target (Finnish)
      front_label = ui[:prompt_prefix] || src_name
      say "#{front_label}: #{prompt_text}" unless listen_no_english
      say

      centered_prompt(indent, "(Enter to reveal; q to quit): ")
      say

      back_label = ui[:target_prefix] || tgt_name
      say "#{back_label}: #{answer_text}"
      say "(#{format_phonetic(ui, phon)})" unless phon.empty?
      say

      if listen
        speak_target_prompt(spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{indent}#{ui[:replay_hint] || "(Type 'r' to replay audio)"}"
        prompt_with_replay("(Enter for next; 'r' to replay; q to quit): ", spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
      else
        prompt("(Enter for next; q to quit): ")
      end
    end
  end

  say
  say "Done."
end

# -----------------------------
# Quiz Engine
# -----------------------------

def run_quiz(selected, pool:, lenient:, match_game:, listen:, listen_no_english:, reverse:, match_options:, piper_bin:, piper_model:, tts_template:, audio_player:, ui:, srs_enabled:, srs:, tts_variant:, answer_variant:, show_variants:)
  stats = { total: selected.length, correct_1: 0, correct_2: 0, failed: 0 }
  missed = []

  say
  mode = []
  mode << (match_game ? "match-game" : "typing")
  if listen
    mode << (listen_no_english ? "listen-no-english" : "listen")
  end
  src_name = ui[:source_language_name] || "Source"
  tgt_name = ui[:target_language_name] || ui[:language_name] || "Target"

  # Direction hint (belt and braces): show the active translation direction in mode list.
  mode << (reverse ? "#{tgt_name}→#{src_name}" : "#{src_name}→#{tgt_name}")

  title_dir = reverse ? "#{tgt_name} → #{src_name}" : "#{src_name} → #{tgt_name}"
  say "#{title_dir} #{ui[:quiz_label] || 'Quiz'} — #{stats[:total]} word(s) (mode: #{mode.join(', ')})"

  say "-" * 50

  selected.each_with_index do |w, idx|
    say
    say "[#{idx + 1}/#{stats[:total]}]"

    spoken = nil

    if reverse
      # Finnish → English mode
      if listen
        say "Audible #{ui[:target_language_name] || ui[:language_name] || 'Target'}: (listening…)"
        spoken = choose_tts_text(w, tts_variant)
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        display_text =
          if show_variants
            format_variants_for_display(w)
          else
            expected_answer_list(w, answer_variant).sample
          end
        label = ui[:target_prefix] || ui[:target_language_name] || ui[:language_name] || "Target"
        say "#{label}: #{display_text}"
      end
    else
      # Normal English → Finnish mode
      if listen
        say "Audible #{ui[:target_language_name] || ui[:language_name] || 'Target'}: (listening…)"
        spoken = choose_tts_text(w, tts_variant)
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')}" unless listen_no_english
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        say "#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')}"
      end
    end

    answer_ok = false
    wid = word_id(w)

    reverse_match_options = nil
    if match_game && reverse
      correct_list = w[:prompt]

      shown_correct = correct_list.sample
      style = if shown_correct =~ /^\d+$/
                :digit
              else
                :word
              end

      distractor_words = (pool - [w]).sample(2)

      distractors = distractor_words.map do |dw|
        variants = dw[:prompt]
        preferred = variants.find do |v|
          style == :digit ? v =~ /^\d+$/ : v =~ /[A-Za-z]/
        end
        preferred || variants.first
      end

      correct_variant = correct_list.find do |v|
        style == :digit ? v =~ /^\d+$/ : v =~ /[A-Za-z]/
      end || shown_correct

      reverse_match_options = ([correct_variant] + distractors).shuffle
    end

    forward_match_options = nil
    if match_game && !reverse
      variant_field =
        case answer_variant.to_s.strip.downcase
        when "spoken" then :spoken
        when "either" then :either
        else :answer
        end
      correct_list = expected_answer_list(w, answer_variant)
      shown_correct = correct_list.sample
      distractors = pick_distractors(pool, correct_list, field: variant_field, n: 2)
      forward_match_options = ([shown_correct] + distractors).shuffle
    end

    1.upto(2) do |attempt|
          if match_game
            if reverse
          # Finnish → English match-game (stable options across attempts)
          correct_list = w[:prompt]
          options_list = reverse_match_options

          display_mode = match_options
          display_mode = "en" if display_mode == "auto"

          say "Hints:"

          # Build a lookup from English variant -> Finnish sample
          prompt_to_answer = {}
          pool.each do |ww|
            ww[:prompt].each do |pv|
              prompt_to_answer[pv] ||= ww[:answer].first
            end
          end

          if display_mode == "both"
            options_list.each do |opt|
              fi_hint = prompt_to_answer[opt]
              say "  - #{fi_hint} → #{opt}"
            end
          elsif display_mode == "fi"
            options_list.each do |opt|
              fi_hint = prompt_to_answer[opt]
              say "  - #{fi_hint}"
            end
          else
            options_list.each { |opt| say "  - #{opt}" }
          end

          input = if listen
                    prompt_with_replay("Type the English meaning: ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                  else
                    prompt("#{ui[:prompt_prefix] || ui[:source_language_name] || 'Prompt'}: ")
                  end

          kind, ok, matched = match_answer(input, correct_list, lenient: false)

          if ok
            stats[:"correct_#{attempt}"] += 1
            say(ui[:correct] || "✅ Correct!")
            others = correct_list - [matched]
            say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
            # In reverse listen modes, reveal the written answer (and phonetic) after a correct response.
            if listen
              say_reverse_listen_reveal(w, ui)
            else
              say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].empty?
            end

            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')})"
            update_srs!(srs, wid, attempt == 1 ? 5 : 4) if srs_enabled
            answer_ok = true
            break
          else
            say(ui[:try_again] || "Try again.") if attempt < 2
          end

          else
            # English → target match-game (stable hints across attempts)
            correct_list = expected_answer_list(w, answer_variant)
            options_list = forward_match_options

            say "Hints:"
            options_list.each { |opt| say "  - #{opt}" }

            input = if listen
                      heard_label = ui[:target_prefix] || tgt_name
                      prompt_with_replay("Type what you heard (#{heard_label}): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                    else
                      prompt("#{ui[:target_prefix] || 'Answer'}: ")
                    end

            kind, ok, matched = match_answer(input, correct_list, lenient: lenient)

            if ok
              stats[:"correct_#{attempt}"] += 1

              if kind == :umlaut_lenient
                say(ui[:correct] || "✅ Correct!")
              else
                say(ui[:correct] || "✅ Correct!")
              end

              others = correct_list - [matched]
              say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
              say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].empty?
              say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')})"
              update_srs!(srs, wid, attempt == 1 ? 5 : 4) if srs_enabled
              answer_ok = true
              break
            else
              say(ui[:try_again] || "Try again.") if attempt < 2
            end
          end
      else
        input = if listen
                  heard_label = ui[:target_prefix] || tgt_name
                  meaning_label = ui[:prompt_prefix] || src_name
                  prompt_with_replay(
                    reverse ? "Type the #{meaning_label} meaning: " : "Type what you heard (#{heard_label}): ",
                    spoken,
                    piper_bin: piper_bin,
                    piper_model: piper_model,
                    template: tts_template
                  )
                else
                  prompt(reverse ? "#{ui[:prompt_prefix] || ui[:source_language_name] || 'Prompt'}: " : "#{ui[:target_prefix] || 'Answer'}: ")
                end

        if reverse
          expected = w[:prompt]
          kind, ok, matched = match_answer(input, expected, lenient: false)
        else
          expected = expected_answer_list(w, answer_variant)
          kind, ok, matched = match_answer(input, expected, lenient: lenient)
        end

        if ok
          stats[:"correct_#{attempt}"] += 1

          if kind == :umlaut_lenient
            say(ui[:correct] || "✅ Correct!")
          else
            say(ui[:correct] || "✅ Correct!")
          end

          if reverse
            others = expected - [matched]
            say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?

            # In reverse listen modes, reveal the written answer (and phonetic) after a correct response.
            say_reverse_listen_reveal(w, ui) if listen

            # Always show the source-side variants (English) for reverse mode after a correct response.
            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')})"
          else
            # Use the same answer set we validated against (written/spoken/either).
            others = expected - [matched]
            say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:prompt].join(' / ')})"
            say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].empty?
          end
          update_srs!(srs, wid, attempt == 1 ? 5 : 4) if srs_enabled
          answer_ok = true
          break
        else
          say(ui[:try_again] || "Try again.") if attempt < 2
        end
      end
    end

    unless answer_ok
      stats[:failed] += 1
      if reverse
        say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{w[:prompt].join(' / ')}"
      else
        correct_display = expected_answer_list(w, answer_variant).join(" / ")
        say "#{ui[:correct_word_prefix] || '❌ Correct word:'} #{correct_display}#{w[:phonetic].empty? ? '' : " (#{w[:phonetic]})"}"
      end
      update_srs!(srs, wid, 2) if srs_enabled
      missed << w
    end
  end

  [stats, missed]
end

# -----------------------------
# Output
# -----------------------------

def write_missed_file(input_path, pack_meta, stats, missed, lenient:, match_game:, listen:, listen_no_english:, reverse:)
  base = (pack_meta && pack_meta[:id] && !pack_meta[:id].to_s.strip.empty?) ? pack_meta[:id].to_s.strip : File.basename(input_path, File.extname(input_path))
  filename = "#{base}_missed_#{Time.now.strftime('%Y%m%d_%H%M%S')}.yaml"

  # Build metadata for the missed pack by copying the original pack metadata,
  # then adding a small generation block.
  base_meta = strip_localisation_meta(pack_meta)
  missed_meta = deep_merge_hash(base_meta || {}, {
    id: "#{base}_missed",
    generated: begin
      g = {
        generated_at: Time.now.iso8601,
        source_pack_id: (pack_meta || {}).dig(:id),
        source_file: File.expand_path(input_path),
        localisation: (defined?($LOCALISATION_ID) ? $LOCALISATION_ID : nil),
        stats: stats,
        options: {
          lenient_umlauts: lenient,
          match_game: match_game,
          listen: listen,
          listen_no_source: listen_no_english,
          reverse: reverse
        }
      }
      g.delete_if { |_, v| v.nil? }
      g
    end
  })

  entries = missed.map do |w|
    entry = {
      "id" => (w[:id] && !w[:id].to_s.strip.empty?) ? w[:id].to_s.strip : Digest::SHA1.hexdigest("#{w[:prompt].join('|')}::#{w[:answer].join('|')}")[0, 8],
      "prompt" => w[:prompt].first,
      "answer" => w[:answer]
    }

    alts = w[:prompt].drop(1)
    entry["alternate_prompts"] = alts unless alts.empty?

    spoken = w[:spoken]
    entry["spoken"] = spoken if spoken.is_a?(Array) && !spoken.empty?

    phon = w[:phonetic].to_s.strip
    entry["phonetic"] = phon unless phon.empty?

    entry
  end

  payload = {
    "metadata" => stringify_keys_deep(missed_meta),
    "entries" => entries
  }

  File.write(filename, YAML.dump(payload))
  filename
end

# -----------------------------
# Main
# -----------------------------

options = {
  config: nil,
  localisation: nil,
  lenient: false,
  match_game: false,
  listen: false,
  listen_no_english: false,
  reverse: false,
  study: false,
  match_options: "auto",
  piper_bin: ENV["PIPER_BIN"],
  piper_model: ENV["PIPER_MODEL"],
  audio_player: ENV["AUDIO_PLAYER"],
  tts_template: ENV["TTS_TEMPLATE"],
  tts_variant: "written",          # written|spoken (controls what Piper speaks when --listen)
  answer_variant: "written",       # written|spoken|either (controls what is accepted as correct typed answer)
  show_variants: false,            # show written/spoken together when available
  ui: nil,
  count: nil,
  srs: false,
  srs_due_only: false,
  srs_new: 5,
  srs_reset: false,
  srs_file: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby linguatrain.rb <yaml_file> [count|all] [options]"

  opts.on("--config PATH", "Path to user config YAML (or set LINGUATRAIN_CONFIG)") { |v| options[:config] = v }
  opts.on("--localisation PATH", "Path to localisation YAML (overrides config.yaml localisation)") { |v| options[:localisation] = v }
  opts.on("--audio-player CMD", "Audio player command (default from config; macOS: afplay)") { |v| options[:audio_player] = v }

  opts.on("--lenient-umlauts", "Allow a for ä and o for ö") { options[:lenient] = true }
  opts.on("--match-game", "Enable multiple choice mode") { options[:match_game] = true }
  opts.on("--listen", "Listening mode: speak target language (Piper) and type what you heard") { options[:listen] = true }

  opts.on("--listen-no-source", "Listening mode without showing source prompt") do
    options[:listen] = true
    options[:listen_no_english] = true
  end
  opts.on("--tts-variant VAR", "With --listen, speak: written|spoken (default: written)") do |v|
    options[:tts_variant] = v.to_s.strip.downcase
  end

  opts.on("--answer-variant VAR", "Accept answers as: written|spoken|either (default: written)") do |v|
    options[:answer_variant] = v.to_s.strip.downcase
  end

  opts.on("--show-variants", "Show both written and spoken forms when available") do
    options[:show_variants] = true
  end
  # Backward-compatible alias
  opts.on("--listen-no-english", "Alias for --listen-no-source") do
    options[:listen] = true
    options[:listen_no_english] = true
  end

  opts.on("--reverse", "Practice target → source instead of source → target") do
    options[:reverse] = true
  end

  opts.on("--study", "Study mode: show one side, then reveal the other (no scoring)") do
    options[:study] = true
  end

  opts.on("--match-options MODE", "Match-game options display: auto|fi|en|both (default: auto)") do |v|
    options[:match_options] = v.to_s.strip.downcase
  end

  opts.on("--piper-bin PATH", "Path to piper executable (or set PIPER_BIN env var)") { |v| options[:piper_bin] = v }
  opts.on("--piper-model PATH", "Path to Piper .onnx model (or set PIPER_MODEL env var)") { |v| options[:piper_model] = v }
  opts.on("--tts-template STR", "TTS template, e.g. 'Suomeksi: {text}.' (or set TTS_TEMPLATE)") { |v| options[:tts_template] = v }
  opts.on("--srs", "Enable spaced repetition scheduling") { options[:srs] = true }
  opts.on("--due", "With --srs, only quiz due items") { options[:srs_due_only] = true }
  opts.on("--new N", Integer, "With --srs, include up to N new items (default: 5)") { |v| options[:srs_new] = v }
  opts.on("--reset-srs", "With --srs, reset scheduling state for this pack") { options[:srs_reset] = true }
  opts.on("--srs-file PATH", "Override SRS state file location") { |v| options[:srs_file] = v }
end

parser.parse!

yaml_path = ARGV.shift or abort("Missing YAML file.")
options[:count] = ARGV.shift

# Study mode is intentionally simple: ignore match-game, lenient umlauts, and SRS.
if options[:study]
  abort("--study cannot be combined with --match-game") if options[:match_game]
  abort("--study cannot be combined with --lenient-umlauts") if options[:lenient]

  if options[:srs] || options[:srs_due_only] || options[:srs_reset] || options[:srs_file]
    abort("--study ignores SRS. Remove --srs/--due/--new/--reset-srs/--srs-file.")
  end
end

pack = load_pack(yaml_path)
pack_meta = pack[:meta] || {}
words = pack[:words] || []

user_cfg_path = resolve_user_config_path(options[:config])
user_cfg = load_yaml_hash(user_cfg_path)

loc_path = resolve_localisation_path(options[:localisation], user_cfg, user_cfg_path)
localisation = load_localisation(loc_path)
$LOCALISATION_ID = localisation.dig(:meta, :id)

# Make localisation UI available to resolve_settings!
options[:localisation_ui] = localisation[:ui] || {}

# Effective meta includes localisation languages + (optional) localisation TTS template.
effective_pack_meta = effective_meta(pack_meta, localisation)

resolve_settings!(options, user_cfg, effective_pack_meta)
pack_meta = effective_pack_meta


# Provide globals for small helpers.
$UI = options[:ui] || DEFAULT_UI
$AUDIO_PLAYER = options[:audio_player]

if options[:listen]
  abort("--listen requires Piper settings: provide --piper-bin/--piper-model, set PIPER_BIN/PIPER_MODEL, or configure ~/.config/linguatrain/config.yaml") unless options[:piper_bin] && options[:piper_model]
end

srs_enabled = options[:srs] && !options[:study]
srs_path = options[:srs_file] || default_srs_path(yaml_path, pack_meta)

srs = srs_enabled ? load_srs(srs_path) : { "meta" => {}, "items" => {} }

if srs_enabled
  srs["meta"] ||= {}
  srs["meta"]["source_file"] = File.expand_path(yaml_path)
  srs["meta"]["generated_at"] ||= Time.now.iso8601

  if options[:srs_reset]
    srs["items"] = {}
  end

  selected = select_words_srs(
    words,
    options[:count],
    srs,
    new_count: options[:srs_new],
    due_only: options[:srs_due_only]
  )
else
  selected = choose_words(words, options[:count])
end
if srs_enabled
  due_count = 0
  new_count = 0

  words.each do |w|
    id = word_id(w)
    item = srs.dig("items", id)

    if item.nil?
      new_count += 1
    elsif due?(item)
      due_count += 1
    end
  end

  say
  say "SRS Status — Due: #{due_count} | New: #{new_count}"
  say
end
begin

  if options[:study]
    run_study(
      selected,
      reverse: options[:reverse],
      listen: options[:listen],
      listen_no_english: options[:listen_no_english],
      piper_bin: options[:piper_bin],
      piper_model: options[:piper_model],
      tts_template: options[:tts_template],
      ui: options[:ui] || DEFAULT_UI,
      tts_variant: options[:tts_variant],
      answer_variant: options[:answer_variant],
      show_variants: options[:show_variants]
    )

    # Study mode has no scoring/missed packs.
    exit(0)
  end

  stats, missed = run_quiz(
    selected,
    pool: words,
    lenient: options[:lenient],
    match_game: options[:match_game],
    listen: options[:listen],
    listen_no_english: options[:listen_no_english],
    reverse: options[:reverse],
    match_options: options[:match_options],
    piper_bin: options[:piper_bin],
    piper_model: options[:piper_model],
    tts_template: options[:tts_template],
    audio_player: options[:audio_player],
    ui: options[:ui] || DEFAULT_UI,
    srs_enabled: srs_enabled,
    srs: srs,
    tts_variant: options[:tts_variant],
    answer_variant: options[:answer_variant],
    show_variants: options[:show_variants]
  )

  say
  say "-" * 50
  say "Results"
  say "Total: #{stats[:total]}"
  say "Correct 1st: #{stats[:correct_1]} (#{pct(stats[:correct_1], stats[:total]).round(1)}%)"
  say "Correct 2nd: #{stats[:correct_2]} (#{pct(stats[:correct_2], stats[:total]).round(1)}%)"
  say "Failed: #{stats[:failed]} (#{pct(stats[:failed], stats[:total]).round(1)}%)"

  if missed.any?
    outfile = write_missed_file(
      yaml_path,
      pack_meta,
      stats,
      missed,
      lenient: options[:lenient],
      match_game: options[:match_game],
      listen: options[:listen],
      listen_no_english: options[:listen_no_english],
      reverse: options[:reverse]
    )

    say
    say "Missed words saved to: #{outfile}"
  else
    say
    puts $UI[:no_mistakes] || "😊 No mistakes — nice work!"
  end
rescue QuitQuiz
  say "SRS progress saved." if srs_enabled
  exit(0)
ensure
  save_srs(srs_path, srs) if srs_enabled
end
