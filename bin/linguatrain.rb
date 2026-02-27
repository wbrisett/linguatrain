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

def resolve_user_config_path(cli_path)
  return cli_path if cli_path && !cli_path.to_s.strip.empty?
  env_path = ENV["LINGUATRAIN_CONFIG"]
  return env_path if env_path && !env_path.to_s.strip.empty?
  first_existing_path(DEFAULT_USER_CONFIG_PATHS)
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

  # UI strings: defaults < user < pack
  ui = deep_merge_hash(DEFAULT_UI, user_cfg.dig(:ui))
  ui = deep_merge_hash(ui, pack_meta.dig(:ui))

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

  # macOS playback
  player = (defined?($AUDIO_PLAYER) && $AUDIO_PLAYER) ? $AUDIO_PLAYER : DEFAULT_AUDIO_PLAYER
  ok_play = system(player.to_s, wav)
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
              # Ignore metadata blocks commonly named 'meta'
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
    # Legacy keys
    en = w["en"] || w[:en] || w["english"] || w[:english]
    fi = w["fi"] || w[:fi] || w["finnish"] || w[:finnish]
    phon = w["phon"] || w[:phon] || w["phonetic"] || w[:phonetic]

    # New schema keys
    prompt_v = w["prompt"] || w[:prompt]
    alt_prompts_v = w["alternate_prompts"] || w[:alternate_prompts]
    answer_v = w["answer"] || w[:answer]
    phonetic_v = w["phonetic"] || w[:phonetic]

    # If we have new-schema fields, map them into the legacy variables used below.
    if en.nil? && !prompt_v.nil?
      en = prompt_v
    end

    if fi.nil? && !answer_v.nil?
      fi = answer_v
    end

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

    raise "Invalid word entry: #{w.inspect}" if en_list.empty? || fi_list.empty?

    { en: en_list, fi: fi_list, phon: phon.to_s.strip }
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


def pick_distractors(pool, correct_list, field: :fi, n: 2)
  all_correct = correct_list.to_a
  candidates = pool.flat_map { |w| w[field] }.uniq - all_correct
  raise "Not enough distractors." if candidates.size < n
  candidates.sample(n)
end

# -----------------------------
# SRS (Spaced Repetition)
# -----------------------------

def word_id(w)
  Digest::SHA1.hexdigest("#{w[:en].join('|')}::#{w[:fi].join('|')}")
end

def default_srs_path(yaml_path)
  base = File.basename(yaml_path, File.extname(yaml_path))
  File.join(Dir.home, ".config", "finn_quiz", "srs", "#{base}.yaml")
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

# -----------------------------
# Quiz Engine
# -----------------------------

def run_quiz(selected, pool:, lenient:, match_game:, listen:, listen_no_english:, reverse:, match_options:, piper_bin:, piper_model:, tts_template:, audio_player:, ui:, srs_enabled:, srs:)
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
  say "#{ui[:source_language_name] || 'Source'} → #{ui[:target_language_name] || ui[:language_name] || 'Target'} #{ui[:quiz_label] || 'Quiz'} — #{stats[:total]} word(s) (mode: #{mode.join(', ')})"
  say "-" * 50

  selected.each_with_index do |w, idx|
    say
    say "[#{idx + 1}/#{stats[:total]}]"

    spoken = nil

    if reverse
      # Finnish → English mode
      if listen
        say "Audible #{ui[:target_language_name] || ui[:language_name] || 'Target'}: (listening…)"
        spoken = w[:fi].sample
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        spoken = w[:fi].sample
        say "#{ui[:target_language_name] || ui[:language_name] || 'Target'}: #{spoken}"
      end
    else
      # Normal English → Finnish mode
      if listen
        say "Audible #{ui[:target_language_name] || ui[:language_name] || 'Target'}: (listening…)"
        spoken = w[:fi].sample
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{ui[:prompt_prefix] || 'Prompt'}: #{w[:en].join(' / ')}" unless listen_no_english
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        say "#{ui[:prompt_prefix] || 'Prompt'}: #{w[:en].join(' / ')}"
      end
    end

    answer_ok = false
    wid = word_id(w)

    reverse_match_options = nil
    if match_game && reverse
      correct_list = w[:en]

      shown_correct = correct_list.sample
      style = if shown_correct =~ /^\d+$/
                :digit
              else
                :word
              end

      distractor_words = (pool - [w]).sample(2)

      distractors = distractor_words.map do |dw|
        variants = dw[:en]
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
      correct_list = w[:fi]
      shown_correct = correct_list.sample
      distractors = pick_distractors(pool, correct_list, field: :fi, n: 2)
      forward_match_options = ([shown_correct] + distractors).shuffle
    end

    1.upto(2) do |attempt|
      if match_game
        if reverse
          # Finnish → English match-game (stable options across attempts)
          correct_list = w[:en]
          options_list = reverse_match_options

          display_mode = match_options
          display_mode = "en" if display_mode == "auto"

          say "Hints:"

          # Build a lookup from English variant -> Finnish sample
          en_to_fi = {}
          pool.each do |ww|
            ww[:en].each do |env|
              en_to_fi[env] ||= ww[:fi].first
            end
          end

          if display_mode == "both"
            options_list.each do |opt|
              fi_hint = en_to_fi[opt]
              say "  - #{fi_hint} → #{opt}"
            end
          elsif display_mode == "fi"
            options_list.each do |opt|
              fi_hint = en_to_fi[opt]
              say "  - #{fi_hint}"
            end
          else
            options_list.each { |opt| say "  - #{opt}" }
          end

          input = if listen
                    prompt_with_replay("Type the English meaning: ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                  else
                    prompt("#{ui[:source_language_name] || ui[:prompt_prefix] || 'Prompt'}: ")
                  end

          kind, ok, matched = match_answer(input, correct_list, lenient: false)

          if ok
            stats[:"correct_#{attempt}"] += 1
            say(ui[:correct] || "✅ Correct!")
            others = correct_list - [matched]
            say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
            say "   (#{ui[:phonetic_prefix] || 'phonetic'}: #{w[:phon]})" unless w[:phon].empty?
            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:en].join(' / ')})"
            update_srs!(srs, wid, attempt == 1 ? 4 : 3) if srs_enabled
            answer_ok = true
            break
          else
            say(ui[:try_again] || "Try again.") if attempt < 2
          end

        else
          # English → Finnish match-game (stable hints across attempts)
          correct_list = w[:fi]
          options_list = forward_match_options

          say "Hints:"
          options_list.each { |opt| say "  - #{opt}" }

          input = if listen
                    prompt_with_replay("Type what you heard (Finnish): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
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
            say "   (#{ui[:phonetic_prefix] || 'phonetic'}: #{w[:phon]})" unless w[:phon].empty?
            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:en].join(' / ')})"
            update_srs!(srs, wid, attempt == 1 ? 4 : 3) if srs_enabled
            answer_ok = true
            break
          else
            say(ui[:try_again] || "Try again.") if attempt < 2
          end
        end
      else
        input = if listen
                  prompt_with_replay(reverse ? "Type the English meaning: " : "Type what you heard (Finnish): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                else
                  prompt(reverse ? "#{ui[:source_language_name] || ui[:prompt_prefix] || 'Prompt'}: " : "#{ui[:target_prefix] || 'Answer'}: ")
                end

        if reverse
          expected = w[:en]
          kind, ok, matched = match_answer(input, expected, lenient: false)
        else
          kind, ok, matched = match_answer(input, w[:fi], lenient: lenient)
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
          else
            others = w[:fi] - [matched]
            say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
            say "   (#{ui[:prompt_prefix] || 'Prompt'}: #{w[:en].join(' / ')})"
          end

          say "   (#{ui[:phonetic_prefix] || 'phonetic'}: #{w[:phon]})" unless w[:phon].empty?
          update_srs!(srs, wid, attempt == 1 ? 4 : 3) if srs_enabled
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
        say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{w[:en].join(' / ')}"
      else
        say "#{ui[:correct_word_prefix] || '❌ Correct word:'} #{w[:fi].join(' / ')}#{w[:phon].empty? ? '' : " (#{w[:phon]})"}"
      end
      update_srs!(srs, wid, 1) if srs_enabled
      missed << w
    end
  end

  [stats, missed]
end

# -----------------------------
# Output
# -----------------------------

def write_missed_file(input_path, stats, missed, lenient:, match_game:, listen:, listen_no_english:)
  base = File.basename(input_path, File.extname(input_path))
  filename = "#{base}_missed_#{Time.now.strftime('%Y%m%d_%H%M%S')}.yaml"

  payload = {
    meta: {
      generated_at: Time.now.iso8601,
      source_file: File.expand_path(input_path),
      lenient_umlauts: lenient,
      match_game: match_game,
      listen: listen,
      listen_no_english: listen_no_english
    },
    stats: stats,
    missed: missed
  }

  File.write(filename, YAML.dump(payload))
  filename
end

# -----------------------------
# Main
# -----------------------------

options = {
  config: nil,
  lenient: false,
  match_game: false,
  listen: false,
  listen_no_english: false,
  reverse: false,
  match_options: "auto",
  piper_bin: ENV["PIPER_BIN"],
  piper_model: ENV["PIPER_MODEL"],
  audio_player: ENV["AUDIO_PLAYER"],
  tts_template: ENV["TTS_TEMPLATE"],
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
  opts.on("--audio-player CMD", "Audio player command (default from config; macOS: afplay)") { |v| options[:audio_player] = v }

  opts.on("--lenient-umlauts", "Allow a for ä and o for ö") { options[:lenient] = true }
  opts.on("--match-game", "Enable multiple choice mode") { options[:match_game] = true }
  opts.on("--listen", "Listening mode: speak target language (Piper) and type what you heard") { options[:listen] = true }

  opts.on("--listen-no-english", "Listening mode without showing English translation") do
    options[:listen] = true
    options[:listen_no_english] = true
  end

  opts.on("--reverse", "Practice Finnish → English instead of English → Finnish") do
    options[:reverse] = true
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

pack = load_pack(yaml_path)
pack_meta = pack[:meta] || {}
words = pack[:words] || []

user_cfg_path = resolve_user_config_path(options[:config])
user_cfg = load_yaml_hash(user_cfg_path)

resolve_settings!(options, user_cfg, pack_meta)

# Provide globals for small helpers.
$UI = options[:ui] || DEFAULT_UI
$AUDIO_PLAYER = options[:audio_player]

if options[:listen]
  abort("--listen requires Piper settings: provide --piper-bin/--piper-model, set PIPER_BIN/PIPER_MODEL, or configure ~/.config/linguatrain/config.yaml") unless options[:piper_bin] && options[:piper_model]
end

srs_enabled = options[:srs]
srs_path = options[:srs_file] || default_srs_path(yaml_path)

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
    srs: srs
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
      stats,
      missed,
      lenient: options[:lenient],
      match_game: options[:match_game],
      listen: options[:listen],
      listen_no_english: options[:listen_no_english]
    )

    say
    say "Missed words saved to: #{outfile}"
  else
    say
    say "😊 No mistakes — nice work!"
  end
rescue QuitQuiz
  say "SRS progress saved." if srs_enabled
  exit(0)
ensure
  save_srs(srs_path, srs) if srs_enabled
end
