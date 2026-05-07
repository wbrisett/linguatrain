#!/usr/bin/env ruby
# frozen_string_literal: true

# linguatrain.rb
# Language quiz CLI (typing / match-game / listening / speaking via Piper + Whisper)

require "yaml"
require "time"
require "optparse"
require "securerandom"
require "digest"
require "fileutils"
require "json"
require "pathname"

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
  quit_message: "👋 Exiting quiz.",
  printed_voice_prefix: "🗣 Printed voice",
  speak_now: "🎤 Speak now...",
  heard_prefix: "Heard",
  close_enough: "🟡 Close enough",
  recording_prefix: "🎙 Recording",
  press_enter_to_start: "Press Enter to start recording",
  recording_window_suffix: "window",
  transform_positive_instruction: "Use the positive form:",
  transform_negative_instruction: "Use the negative form:",
  conjugate_prompt: "Conjugate the verb.",
  conjugate_instruction: "Use the correct form:",
  conjugate_positive_instruction: "Use the positive form:",
  conjugate_negative_instruction: "Use the negative form:",
  show_notes: true
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

def resolve_relative_to_script(path)
  return path if Pathname.new(path).absolute?
  File.expand_path(path, __dir__)
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
  raw =
    if cli_path && !cli_path.to_s.strip.empty?
      cli_path.to_s.strip
    else
      env_path = ENV["LINGUATRAIN_LOCALISATION"]
      if env_path && !env_path.to_s.strip.empty?
        env_path.to_s.strip
      else
        cfg_path = user_cfg.dig(:localisation)
        return nil if cfg_path.nil? || cfg_path.to_s.strip.empty?
        cfg_path.to_s.strip
      end
    end

  # Absolute path: use as-is.
  return raw if Pathname.new(raw).absolute? || raw =~ /^[A-Za-z]:[\\\/]/

  # Relative path resolution order:
  # 1) current working directory (project-local override)
  # 2) directory of this script/repo (bundled localisation files)
  # 3) directory of the user config file (portable user config)
  cwd_candidate = File.expand_path(raw, Dir.pwd)
  return cwd_candidate if File.exist?(cwd_candidate)

  script_candidate = File.expand_path(raw, __dir__)
  return script_candidate if File.exist?(script_candidate)

  if user_cfg_path && !user_cfg_path.to_s.strip.empty?
    cfg_dir = File.dirname(File.expand_path(user_cfg_path))
    cfg_candidate = File.expand_path(raw, cfg_dir)
    return cfg_candidate if File.exist?(cfg_candidate)
  end

  # Fall back to the script-relative path so bundled resources still resolve
  # when called from arbitrary working directories.
  script_candidate
end



def load_localisation(path)
  return {} if path.nil? || path.to_s.strip.empty?
  raise "Localisation file not found: #{path} (resolved from input)" unless File.exist?(path)
  symbolize_keys_deep(YAML.load_file(path) || {})
end

def effective_meta(pack_meta, localisation)
  # Localisation owns languages; packs may still contain other metadata (back-compat).
  # IMPORTANT: localisation must win for languages so pack-level legacy fields can't silently flip directions.
  merged = deep_merge_hash((pack_meta || {}), { languages: localisation[:languages] })

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

  # Speech / Whisper
  options[:speech_record_cmd] ||= user_cfg.dig(:speech, :record_cmd)
  options[:speech_bin] ||= user_cfg.dig(:speech, :bin)
  options[:speech_model] ||= user_cfg.dig(:speech, :model)
  options[:speech_language] ||= user_cfg.dig(:speech, :language)
  options[:speech_duration] = user_cfg.dig(:speech, :duration) if options[:speech_duration].nil?

  # Final speech defaults (applied after config so config.yaml wins)
  options[:speech_model] ||= "base"
  options[:speech_language] ||= "Finnish"
  options[:speech_duration] = 3 if options[:speech_duration].nil?

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

# -----------------------------
# Speech Recognition & Scoring (Whisper)
# -----------------------------
def normalize_for_speech_compare(s)
  t = normalize_basic(strip_terminal_punct(s))
  t = t.gsub(/[,:;()\[\]{}"'”“’‘]/, " ")
  t = t.gsub(/\s+/, " ").strip
  t
end

def levenshtein_distance(a, b)
  a = a.to_s
  b = b.to_s

  return b.length if a.empty?
  return a.length if b.empty?

  prev = (0..b.length).to_a

  a.each_char.with_index(1) do |ca, i|
    curr = [i]
    b.each_char.with_index(1) do |cb, j|
      cost = (ca == cb ? 0 : 1)
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost
      ].min
    end
    prev = curr
  end

  prev[b.length]
end

def similarity_ratio(a, b)
  aa = normalize_for_speech_compare(a)
  bb = normalize_for_speech_compare(b)

  variants_a = [aa]
  variants_b = [bb]

  # ---------------------------------------------------------
  # Linguatrain: Finnish ASR tolerance layer
  #
  # Whisper often returns forms like:
  #   "misaasut" instead of "missä asut"
  #   "vita kulu" instead of "mitä kuuluu"
  #
  # To make speaking practice usable for learners we also
  # compare additional normalized variants:
  #   - spaces removed
  #   - umlauts normalized (ä→a, ö→o)
  #
  # If you ever want to disable this behavior, remove this
  # block and keep only the original aa/bb comparison above.
  # ---------------------------------------------------------

  variants_a << aa.gsub(" ", "")
  variants_b << bb.gsub(" ", "")

  variants_a << normalize_lenient_umlauts(aa)
  variants_b << normalize_lenient_umlauts(bb)

  best = 0.0

  variants_a.each do |va|
    variants_b.each do |vb|
      max_len = [va.length, vb.length].max
      next if max_len.zero?

      dist = levenshtein_distance(va, vb)
      score = 1.0 - (dist.to_f / max_len.to_f)
      best = score if score > best
    end
  end

  best
end

def shell_escape_single(value)
  "'#{value.to_s.gsub("'", %q('"'"'))}'"
end

def format_time(seconds)
  m = (seconds / 60).floor
  s = (seconds % 60).round
  "#{m}m #{s}s"
end


def build_record_command(template, output_path, duration)
  tpl = template.to_s.strip
  raise "Speech record command not configured." if tpl.empty?

  cmd = tpl.gsub("{output}", shell_escape_single(output_path.to_s))
  cmd = cmd.gsub("{duration}", duration.to_s)
  cmd
end

def record_speech_audio(record_cmd_template, duration: 3, ui: nil)
  wav = File.join("/tmp", "linguatrain_speak_#{Process.pid}_#{SecureRandom.hex(4)}.wav")
  cmd = build_record_command(record_cmd_template, wav, duration)

  start_label = (ui && ui[:press_enter_to_start]) ? ui[:press_enter_to_start] : "Press Enter to start recording"
  rec_label = (ui && ui[:recording_prefix]) ? ui[:recording_prefix] : "🎙 Recording"
  window_suffix = (ui && ui[:recording_window_suffix]) ? ui[:recording_window_suffix] : "window"

  # Wait for user to press Enter to start
  prompt("#{start_label}: ")

  say("#{rec_label} (#{duration.to_i}s #{window_suffix})...")
  say("Speak now...")

  pid = Process.spawn(cmd, out: File::NULL, err: File::NULL)

  begin
    sleep(duration.to_f)
    begin
      Process.kill("INT", pid)
    rescue Errno::ESRCH
      # already exited
    end
    Process.wait(pid)
  rescue Interrupt
    begin
      Process.kill("INT", pid)
    rescue Errno::ESRCH
      # already exited
    end
    Process.wait(pid) rescue nil
    raise
  end

  raise "Speech recording failed." unless File.exist?(wav) && File.size?(wav)

  wav
end

def whisper_transcribe(audio_path, speech_bin:, model:, language:)
  resolved = resolve_executable(speech_bin)
  raise "Speech recognizer not found: #{speech_bin}.\nPATH=#{ENV.fetch('PATH', '')}" unless resolved

  out_dir = File.join("/tmp", "linguatrain_whisper_#{Process.pid}_#{SecureRandom.hex(4)}")
  FileUtils.mkdir_p(out_dir)

  ok = system(
    resolved,
    audio_path,
    "--language", language.to_s,
    "--model", model.to_s,
    "--output_format", "json",
    "--output_dir", out_dir,
    "--fp16", "False",
    out: File::NULL,
    err: File::NULL
  )

  raise "Whisper transcription failed." unless ok

  json_path = File.join(out_dir, "#{File.basename(audio_path, File.extname(audio_path))}.json")
  raise "Whisper output JSON not found: #{json_path}" unless File.exist?(json_path)

  data = JSON.parse(File.read(json_path))
  text = data["text"].to_s.strip
  raise "Whisper returned an empty transcript." if text.empty?

  text
ensure
  FileUtils.rm_rf(out_dir) if out_dir && File.directory?(out_dir)
end

def speech_tokens(s)
  normalize_for_speech_compare(s)
    .split(/\s+/)
    .reject(&:empty?)
end

def stem_like_token(token)
  t = token.to_s.strip
  return t if t.empty?

  endings = %w[ssa ssä sta stä lla llä lta ltä lle na nä ksi t n a ä]
  endings.each do |ending|
    next unless t.length > ending.length + 2
    return t[0...-ending.length] if t.end_with?(ending)
  end

  t
end

def keyword_overlap_score(transcript, expected)
  heard = speech_tokens(transcript).map { |t| stem_like_token(t) }
  want = speech_tokens(expected).map { |t| stem_like_token(t) }

  return 0.0 if want.empty?

  matches = want.count { |tok| heard.include?(tok) }
  matches.to_f / want.length.to_f
end

def speech_match_result(transcript, expected_list, lenient:)
  kind, ok, matched = match_answer(transcript, expected_list, lenient: lenient)
  return [:exact, true, matched, 1.0, 1.0] if ok

  best_expected = nil
  best_similarity = -1.0
  best_overlap = -1.0

  expected_list.each do |candidate|
    similarity = similarity_ratio(transcript, candidate)
    overlap = keyword_overlap_score(transcript, candidate)

    if similarity > best_similarity
      best_similarity = similarity
      best_expected = candidate
    end

    best_overlap = overlap if overlap > best_overlap
  end

  close_threshold = lenient ? 0.72 : 0.80
  overlap_threshold = 0.66

  if best_similarity >= close_threshold
    [:close, true, best_expected, best_similarity, best_overlap]
  elsif best_overlap >= overlap_threshold
    [:close, true, best_expected, best_similarity, best_overlap]
  else
    [:no, false, best_expected, best_similarity, best_overlap]
  end
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

# Build the exact string we feed to Piper (so printed-voice matches audio).
def build_tts_spoken(text, template)
  tpl = template.to_s
  tpl = DEFAULT_TTS_TEMPLATE if tpl.strip.empty?
  tpl.gsub("{text}", ensure_terminal_punct(text.to_s.strip))
end

def maybe_printed_voice(ui, enabled, spoken_text)
  return unless enabled
  t = spoken_text.to_s.strip
  return if t.empty?

  label = (ui && ui[:printed_voice_prefix] ? ui[:printed_voice_prefix].to_s : "🗣 Printed voice").strip
  label = label.sub(/:\z/, "")
  say "#{label}: #{t}"
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



def conversation_speak_line(text, piper_bin:, piper_model:)
  spoken_text = ensure_terminal_punct(text)
  piper_speak(spoken_text, piper_bin: piper_bin, piper_model: piper_model)
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

# Helper: Speak a sequence of target texts with a small gap between.
def speak_target_sequence(texts, piper_bin:, piper_model:, template:, gap: 0.35)
  Array(texts).each_with_index do |text, idx|
    spoken = text.to_s.strip
    next if spoken.empty?

    speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: template)
    sleep(gap) if idx < Array(texts).length - 1
  end
end

module TerminalStyle
  module_function

  def enabled?
    return false if ENV.key?("NO_COLOR")
    return false unless $stdout.tty?

    true
  rescue StandardError
    false
  end

  def wrap(code, text)
    s = text.to_s
    return s unless enabled?

    "\e[#{code}m#{s}\e[0m"
  end

  def bold(text)
    wrap("1", text)
  end

  def dim(text)
    wrap("2", text)
  end

  def cyan(text)
    wrap("36", text)
  end

  def yellow(text)
    wrap("33", text)
  end
end


def render_prompt_line(text)
  TerminalStyle.bold(text.to_s)
end


def render_cue_line(text)
  TerminalStyle.cyan("[ #{text.to_s} ]")
end


def render_instruction_line(text)
  TerminalStyle.yellow(text.to_s)
end

def render_gloss_line(text)
  TerminalStyle.dim(text.to_s)
end

def prompt_to_speak(ui, duration: nil)
  label = (ui && ui[:speak_now]) ? ui[:speak_now] : "🎤 Speak now..."
  say(label)
end

# -----------------------------
# YAML Loading
# -----------------------------

# Psych/YAML 1.1 can parse unquoted clock-like values such as 7:10 as
# sexagesimal integers (25800). Linguatrain treats prompts/answers as study
# text, so protect clock strings before loading the YAML document.
def load_yaml_preserving_clock_strings(path)
  text = File.read(path)

  protected_text = text.gsub(/(^\s*-\s*)(\d{1,2}:\d{2})(\s*(?:#.*)?$)/) do
    %(#{$1}'#{$2}'#{$3})
  end

  protected_text = protected_text.gsub(/(^\s*[^#\s][^:\n]*:\s*)(\d{1,2}:\d{2})(\s*(?:#.*)?$)/) do
    %(#{$1}'#{$2}'#{$3})
  end

  YAML.load(protected_text)
end

def load_pack(path)
  data = load_yaml_preserving_clock_strings(path)

  raw_entries =
    if data.is_a?(Array)
      data
    elsif data.is_a?(Hash)
      # New Linguatrain schema:
      #   metadata: {...}
      #   entries:  [ {id:, prompt:, alternate_prompts:, answer:, phonetic:}, ... ]
      #   transform packs:
      #     metadata.drill_type: transform
      #     entries: [ {id:, prompt:, cues:[{cue:, steps:[{transform:, answer:}, ...]}, ...]}, ... ]
      #   conjugate packs:
      #     metadata.drill_type: conjugate
      #     persons: ["minä", "sinä", "hän", "me", "te", "he"]
      #     entries: [ {id:, lemma:, forms:{"minä"=>{"positive"=>[...], "negative"=>[...]}, ...}}, ... ]
      pack_meta = data["metadata"] || data[:metadata] || {}

      # Back-compat: older packs used metadata.source_lang / metadata.target_lang.
      # If present, map them into metadata.languages.{source,target}.code so they
      # can override localisation languages via effective_meta().
      if pack_meta.is_a?(Hash)
        src_code = pack_meta["source_lang"] || pack_meta[:source_lang]
        tgt_code = pack_meta["target_lang"] || pack_meta[:target_lang]

        src_code = src_code.to_s.strip unless src_code.nil?
        tgt_code = tgt_code.to_s.strip unless tgt_code.nil?

        if (src_code && !src_code.empty?) || (tgt_code && !tgt_code.empty?)
          pack_meta["languages"] ||= {}
          pack_meta["languages"] = {} unless pack_meta["languages"].is_a?(Hash)

          if src_code && !src_code.empty?
            pack_meta["languages"]["source"] ||= {}
            pack_meta["languages"]["source"] = {} unless pack_meta["languages"]["source"].is_a?(Hash)
            pack_meta["languages"]["source"]["code"] = src_code
          end

          if tgt_code && !tgt_code.empty?
            pack_meta["languages"]["target"] ||= {}
            pack_meta["languages"]["target"] = {} unless pack_meta["languages"]["target"].is_a?(Hash)
            pack_meta["languages"]["target"]["code"] = tgt_code
          end
        end
      end

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

        if (pack_meta.key?("source_lang") || pack_meta.key?(:source_lang) || pack_meta.key?("target_lang") || pack_meta.key?(:target_lang))
          deprecations << "metadata.source_lang/metadata.target_lang. Move language codes into the localisation file (languages.source.code / languages.target.code)."
        end

        tts = pack_meta["tts"] || pack_meta[:tts]
        if tts.is_a?(Hash) && (tts.key?("template") || tts.key?(:template))
          deprecations << "metadata.tts.template. Move the default template into localisation (tts.template). Keep pack-level overrides only if truly pack-specific."
        end

        warn_pack_deprecations(path, deprecations)
      end

      entries = data["entries"] || data[:entries]
      persons_v = data["persons"] || data[:persons]
      drill_type = (pack_meta["drill_type"] || pack_meta[:drill_type]).to_s.strip.downcase
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

  if drill_type == "transform"
    transform_entries = raw_entries.map do |entry|
      entry_id = entry["id"] || entry[:id]
      prompt_v = entry["prompt"] || entry[:prompt]
      cues_v = entry["cues"] || entry[:cues]

      raise "Invalid transform entry: #{entry.inspect}" if prompt_v.nil? || cues_v.nil?

      prompt_text = prompt_v.to_s.strip
      raise "Invalid transform entry: #{entry.inspect}" if prompt_text.empty?
      raise "Invalid transform entry: #{entry.inspect}" unless cues_v.is_a?(Array) && !cues_v.empty?

      cues = cues_v.map do |cue_entry|
        cue_text = cue_entry["cue"] || cue_entry[:cue]
        steps_v = cue_entry["steps"] || cue_entry[:steps]

        raise "Invalid transform cue in entry '#{entry_id || prompt_text}': #{cue_entry.inspect}" if cue_text.nil? || steps_v.nil?

        cue_text = cue_text.to_s.strip
        raise "Invalid transform cue in entry '#{entry_id || prompt_text}': #{cue_entry.inspect}" if cue_text.empty?
        raise "Invalid transform cue in entry '#{entry_id || prompt_text}' for cue '#{cue_text}': #{cue_entry.inspect}" unless steps_v.is_a?(Array) && !steps_v.empty?

        steps = steps_v.map do |step|
          transform_v = step["transform"] || step[:transform]
          answer_v = step["answer"] || step[:answer]

          raise "Invalid transform step in entry '#{entry_id || prompt_text}' for cue '#{cue_text}': #{step.inspect}" if transform_v.nil? || answer_v.nil?

          answers =
            case answer_v
            when Array
              answer_v.map { |x| x.to_s.strip }.reject(&:empty?)
            else
              [answer_v.to_s.strip]
            end

          raise "Invalid transform step in entry '#{entry_id || prompt_text}' for cue '#{cue_text}': #{step.inspect}" if answers.empty?

          {
            transform: transform_v.to_s.strip.downcase,
            answer: answers
          }
        end

        {
          cue: cue_text,
          steps: steps
        }
      end

      derived_id = Digest::SHA1.hexdigest("#{prompt_text}::#{cues.map { |c| c[:cue] }.join('|')}")[0, 8]

      {
        id: (entry_id.nil? ? derived_id : entry_id.to_s.strip),
        prompt: prompt_text,
        notes: (entry["notes"] || entry[:notes] || "").to_s.strip,
        cues: cues
      }
    end

    { meta: symbolize_keys_deep(pack_meta), transform_entries: transform_entries }

  elsif drill_type == "conjugate"
    person_defs =
      case persons_v
      when Array
        persons_v.map do |x|
          if x.is_a?(Hash)
            key = (x["key"] || x[:key] || x["person"] || x[:person]).to_s.strip
            next nil if key.empty?
            { key: key, gloss: (x["gloss"] || x[:gloss] || x["english"] || x[:english] || "").to_s.strip }
          else
            key = x.to_s.strip
            next nil if key.empty?
            { key: key, gloss: "" }
          end
        end.compact
      else
        []
      end

    raise "Invalid conjugate pack: missing persons list" if person_defs.empty?

    persons = person_defs.map { |p| p[:key] }

    conjugate_entries = raw_entries.map do |entry|
      entry_id = entry["id"] || entry[:id]
      lemma_v = entry["lemma"] || entry[:lemma] || entry["verb"] || entry[:verb]
      gloss_v = entry["gloss"] || entry[:gloss] || entry["english"] || entry[:english]
      prompt_v = entry["prompt"] || entry[:prompt]
      notes_v = entry["notes"] || entry[:notes]
      type_v = entry["type"] || entry[:type]
      category_v = entry["category"] || entry[:category]
      forms_v = entry["forms"] || entry[:forms] || entry["present"] || entry[:present]
      phonetics_v = entry["phonetics"] || entry[:phonetics] || {}
      lemma_phonetic_v = entry["phonetic"] || entry[:phonetic]

      if (gloss_v.nil? || gloss_v.to_s.strip.empty?) && !prompt_v.nil?
        gloss_v = prompt_v.is_a?(Array) ? prompt_v.first : prompt_v
      end

      raise "Invalid conjugate entry: #{entry.inspect}" if lemma_v.nil? || forms_v.nil?

      lemma_text = lemma_v.to_s.strip
      raise "Invalid conjugate entry: #{entry.inspect}" if lemma_text.empty?
      raise "Invalid conjugate entry: #{entry.inspect}" unless forms_v.is_a?(Hash)

      forms = persons.each_with_object({}) do |person, out|
        raw = forms_v[person] || forms_v[person.to_sym]
        raise "Invalid conjugate entry for '#{lemma_text}': missing form for #{person}" if raw.nil?

        normalized =
          if raw.is_a?(Hash)
            pos_raw = raw["positive"] || raw[:positive]
            neg_raw = raw["negative"] || raw[:negative]

            raise "Invalid conjugate entry for '#{lemma_text}': missing positive form for #{person}" if pos_raw.nil?
            raise "Invalid conjugate entry for '#{lemma_text}': missing negative form for #{person}" if neg_raw.nil?

            positive_answers =
              case pos_raw
              when Array
                pos_raw.map { |x| x.to_s.strip }.reject(&:empty?)
              else
                [pos_raw.to_s.strip]
              end

            negative_answers =
              case neg_raw
              when Array
                neg_raw.map { |x| x.to_s.strip }.reject(&:empty?)
              else
                [neg_raw.to_s.strip]
              end

            raise "Invalid conjugate entry for '#{lemma_text}': empty positive form for #{person}" if positive_answers.empty?
            raise "Invalid conjugate entry for '#{lemma_text}': empty negative form for #{person}" if negative_answers.empty?

            {
              positive: positive_answers,
              negative: negative_answers
            }
          else
            # Backward compatibility: flat list means positive-only legacy form.
            positive_answers =
              case raw
              when Array
                raw.map { |x| x.to_s.strip }.reject(&:empty?)
              else
                [raw.to_s.strip]
              end

            raise "Invalid conjugate entry for '#{lemma_text}': empty form for #{person}" if positive_answers.empty?

            {
              positive: positive_answers,
              negative: []
            }
          end

        out[person] = normalized
      end

      derived_id = Digest::SHA1.hexdigest("#{lemma_text}::#{persons.join('|')}")[0, 8]

      gloss_text = gloss_v.nil? ? "" : gloss_v.to_s.strip
      category = {}

      if category_v.is_a?(Hash)
        category[:key] = (category_v["key"] || category_v[:key]).to_s.strip
        category[:label] = (category_v["label"] || category_v[:label]).to_s.strip
      elsif !type_v.nil?
        type_text = type_v.to_s.strip
        category[:key] = "type#{type_text}"
        category[:label] = "Type #{type_text}"
      end

      phonetics =
        if phonetics_v.is_a?(Hash)
          phonetics_v.each_with_object({}) do |(person, phonetic), out|
            person_key = person.to_s.strip
            next if person_key.empty?

            if phonetic.is_a?(Hash)
              positive_phonetic = (phonetic["positive"] || phonetic[:positive]).to_s.strip
              negative_phonetic = (phonetic["negative"] || phonetic[:negative]).to_s.strip

              values = {}
              values[:positive] = positive_phonetic unless positive_phonetic.empty?
              values[:negative] = negative_phonetic unless negative_phonetic.empty?
              out[person_key] = values unless values.empty?
            else
              phonetic_text = phonetic.to_s.strip
              out[person_key] = { positive: phonetic_text } unless phonetic_text.empty?
            end
          end
        else
          {}
        end

      {
        id: (entry_id.nil? ? derived_id : entry_id.to_s.strip),
        lemma: lemma_text,
        gloss: gloss_text,
        notes: notes_v,
        category: category,
        forms: forms,
        phonetics: phonetics,
        lemma_phonetic: (lemma_phonetic_v.nil? ? "" : lemma_phonetic_v.to_s.strip)
      }
    end

    {
      meta: symbolize_keys_deep(pack_meta),
      conjugate_persons: persons,
      conjugate_person_defs: person_defs,
      conjugate_entries: conjugate_entries
    }
  else
    raw_entries.map do |w|
      # Optional conversation speaker name (used by --conversation only)
      speaker_v = w["speaker"] || w[:speaker]
      # Preserve/assign entry id
      entry_id = w["id"] || w[:id]

      # Legacy and compatibility keys
      en = w["en"] || w[:en] || w["english"] || w[:english] || w["prompt"] || w[:prompt] || w["source"] || w[:source]
      fi = w["fi"] || w[:fi] || w["finnish"] || w[:finnish] || w["answer"] || w[:answer] || w["target"] || w[:target]
      spoken_v = w["spoken"] || w[:spoken]
      phon = w["phon"] || w[:phon] || w["phonetic"] || w[:phonetic]

      # Canonical schema keys
      prompt_v = w["prompt"] || w[:prompt] || w["source"] || w[:source]
      alt_prompts_v = w["alternate_prompts"] || w[:alternate_prompts] || w["also_accepted"] || w[:also_accepted]
      answer_v = w["answer"] || w[:answer] || w["target"] || w[:target]
      spoken_field_v = w["spoken"] || w[:spoken]
      phonetic_v = w["phonetic"] || w[:phonetic] || w["phon"] || w[:phon]

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

      # Canonical schema: include alternate_prompts as additional accepted prompt-side variants.
      # Compatibility aliases: source/target and also_accepted are accepted too.
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

      derived_id = Digest::SHA1.hexdigest("#{en_list.join('|')}::#{fi_list.join('|')}")[0, 8]
      {
        id: (entry_id.nil? ? derived_id : entry_id.to_s.strip),
        speaker: (speaker_v.nil? ? "" : speaker_v.to_s.strip),
        prompt: en_list,
        answer: fi_list,
        spoken: spoken_list,
        phonetic: phon.to_s.strip
      }
    end.then do |words|
      { meta: symbolize_keys_deep(pack_meta), words: words }
    end
  end
end

# Choose a label for the source/target side.
# If ui.prompt_prefix/ui.target_prefix is set to "auto" (or left blank),
# display the resolved language name instead.
def side_label(ui, side)
  ui ||= {}

  if side == :source
    prefix = ui[:prompt_prefix].to_s.strip
    lang_name = ui[:source_language_name].to_s.strip
  else
    prefix = ui[:target_prefix].to_s.strip
    lang_name = ui[:target_language_name].to_s.strip
  end

  if prefix.empty? || prefix.downcase == "auto"
    return lang_name.empty? ? (side == :source ? "Source" : "Target") : lang_name
  end

  prefix
end

def source_label(ui)
  side_label(ui, :source)
end

def target_label(ui)
  side_label(ui, :target)
end


def choose_words(words, count)
  return words.shuffle if count.nil? || count == "all"

  n = Integer(count)
  words.shuffle.take([n, words.length].min)
end

def flatten_transform_items(transform_entries, shuffle_cues: false)
  Array(transform_entries).flat_map do |entry|
    cues = Array(entry[:cues]).dup
    cues = cues.shuffle if shuffle_cues

    cues.map do |cue_entry|
      {
        entry_id: entry[:id],
        prompt: entry[:prompt].to_s,
        notes: entry[:notes].to_s,
        cue: cue_entry[:cue].to_s,
        steps: Array(cue_entry[:steps]).map do |step|
          {
            transform: step[:transform].to_s,
            answer: Array(step[:answer]).map { |x| x.to_s.strip }.reject(&:empty?)
          }
        end
      }
    end
  end
end

def choose_transform_items(items, count)
  return items if count.nil? || count == "all"

  n = Integer(count)
  items.take([n, items.length].min)
end

def conjugate_category(item)
  item[:category].is_a?(Hash) ? item[:category] : {}
end

def conjugate_category_label(item)
  c = conjugate_category(item)
  label = (c[:label] || c["label"]).to_s.strip
  key = (c[:key] || c["key"]).to_s.strip
  label.empty? ? key : label
end

def conjugate_category_answers(item)
  c = conjugate_category(item)
  key = (c[:key] || c["key"]).to_s.strip
  label = (c[:label] || c["label"]).to_s.strip
  extra = c[:answers] || c["answers"] || []

  answers = [key, label]
  [key, label].each do |v|
    n = v.to_s.strip.downcase
    next if n.empty?

    answers << n
    answers << n.gsub(/[-_]+/, " ")
    answers << n.gsub(/\s+/, "")

    if n =~ /\Atype\s*[-_]?\s*(\d+)\z/
      answers << Regexp.last_match(1)
      answers << "type #{Regexp.last_match(1)}"
      answers << "type#{Regexp.last_match(1)}"
    end
  end

  answers.concat(Array(extra))
  answers.map { |x| x.to_s.strip }.reject(&:empty?).uniq
end

def conjugate_category_prompt_label(ui)
  value = ui[:conjugate_category_prompt].to_s.strip if ui.is_a?(Hash)
  value.nil? || value.empty? ? "Verb category:" : value
end

# Helper: prompt for the source-language meaning after a correct listening answer
def prompt_source_meaning(word, ui:, lenient: false)
  source_answers = Array(word[:prompt]).map { |x| x.to_s.strip }.reject(&:empty?)
  return true if source_answers.empty?

  meaning_label = source_label(ui)
  prompt_text = ui[:listen_source_prompt].to_s.strip if ui.is_a?(Hash)
  prompt_text = "Type the #{meaning_label} meaning:" if prompt_text.nil? || prompt_text.empty?

  say render_instruction_line(prompt_text)

  1.upto(2) do |attempt|
    input = prompt("> ")
    _kind, ok, matched = match_answer(input, source_answers, lenient: lenient)

    if ok
      say(ui[:correct] || "✅ Correct!")
      others = source_answers - [matched]
      say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
      return true
    end

    say(ui[:try_again] || "Try again.") if attempt < 2
  end

  say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{source_answers.join(' / ')}"
  false
end

def drill_conjugate_category(item, ui:, lenient: false, study: false)
  expected = conjugate_category_answers(item)
  return true if expected.empty?

  say render_instruction_line(conjugate_category_prompt_label(ui))
  input = prompt("> ")
  _kind, ok, _matched = match_answer(input, expected, lenient: lenient)

  if ok
    say(ui[:correct] || "✅ Correct!") unless study

    return true
  end

  label = conjugate_category_label(item)

  if study
    say "#{ui[:correct_answer_prefix] || 'Correct answer:'} #{label}"

    return true
  end

  say(ui[:try_again] || "Try again.")
  input = prompt("> ")
  _kind, ok, _matched = match_answer(input, expected, lenient: lenient)

  if ok
    say(ui[:correct] || "✅ Correct!")

    true
  else
    say "#{ui[:correct_answer_prefix] || 'Correct answer:'} #{label}"

    false
  end
end

def flatten_conjugate_items(conjugate_entries, persons, shuffle_persons: false)
  Array(conjugate_entries).flat_map do |entry|
    ordered_persons = Array(persons).dup
    ordered_persons = ordered_persons.shuffle if shuffle_persons

    ordered_persons.map do |person|
      # Support both string and hash person definitions
      if person.is_a?(Hash)
        person_key = (person[:key] || person["key"]).to_s.strip
        person_gloss = (person[:gloss] || person["gloss"] || "").to_s.strip
      else
        person_key = person.to_s.strip
        person_gloss = ""
      end

      person_forms = entry[:forms][person_key] || entry[:forms][person_key.to_sym] || {}

      {
        entry_id: entry[:id],
        person: person_key,
        person_gloss: person_gloss,
        category: entry[:category] || {},
        lemma: entry[:lemma].to_s,
        gloss: entry[:gloss].to_s,
        notes: entry[:notes],
        phonetics: (entry[:phonetics] || {})[person_key] || {},
        lemma_phonetic: entry[:lemma_phonetic].to_s,
        forms: {
          positive: Array(person_forms[:positive] || person_forms["positive"])
                      .map { |x| x.to_s.strip }
                      .reject(&:empty?),
          negative: Array(person_forms[:negative] || person_forms["negative"])
                      .map { |x| x.to_s.strip }
                      .reject(&:empty?)
        }
      }
    end
  end
end

def choose_conjugate_entries(entries, count)
  return entries if count.nil? || count == "all"

  n = Integer(count)
  entries.take([n, entries.length].min)
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
  shuffled_new = new_words.shuffle
  unless due_only
    n_new = new_count.to_i
    n_new = 0 if n_new < 0
    selected.concat(shuffled_new.take(n_new))
  end

  # Fill remainder (optionally) from other buckets
  if !due_only
    selected.concat(shuffled_new.drop(n_new))
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

# Show all answer variants (written and spoken) for missed summary
def all_answer_variants_for_display(word)
  (Array(word[:answer]) + Array(word[:spoken]))
    .map { |x| x.to_s.strip }
    .reject(&:empty?)
    .uniq
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
def run_study(selected, reverse:, listen:, listen_no_english:, piper_bin:, piper_model:, tts_template:, ui:, tts_variant:, answer_variant:, show_variants:, printed_voice:)
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
      front_label = target_label(ui)
      say "#{front_label}: #{answer_text}"

      back_label = source_label(ui)
      say "#{back_label}: #{prompt_text}"
      say "(#{format_phonetic(ui, phon)})" unless phon.empty?
      say

      if listen
        maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken_target, tts_template))
        speak_target_prompt(spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{indent}#{ui[:replay_hint] || "(Type 'r' to replay audio)"}"
      end

      if listen
        prompt_with_replay("(Enter for next; 'r' to replay; q to quit): ", spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
      else
        prompt("(Enter for next; q to quit): ")
      end
    else
      # Source → Target: show source first (English), then reveal target (Finnish)
      front_label = source_label(ui)
      say "#{front_label}: #{prompt_text}" unless listen_no_english

      back_label = target_label(ui)
      say "#{back_label}: #{answer_text}"
      say "(#{format_phonetic(ui, phon)})" unless phon.empty?
      say

      if listen
        maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken_target, tts_template))
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

def run_transform_study(selected, ui:, listen: false, piper_bin: nil, piper_model: nil, tts_template: DEFAULT_TTS_TEMPLATE, printed_voice: false)
  say

  total_steps = selected.sum { |item| Array(item[:steps]).length }
  prompts_count = selected.map { |i| i[:prompt].to_s }.uniq.length
  prompt_label = prompts_count == 1 ? "prompt" : "prompts"

  mode = ["study", "transform"]
  mode << "listen" if listen

  say "#{ui[:target_language_name] || ui[:language_name] || 'Language'} Transform #{ui[:quiz_label] || 'Quiz'} — #{prompts_count} #{prompt_label} (#{total_steps} steps) (mode: #{mode.join(', ')})"
  say "-" * 70

  step_index = 0

  selected.each do |item|
    say
    say render_prompt_line(item[:prompt].to_s)

    if show_notes?(ui) && !item[:notes].to_s.strip.empty?
      say render_gloss_line(item[:notes].to_s)
    end

    say
    say render_cue_line(item[:cue].to_s)
    say

    Array(item[:steps]).each do |step|
      step_index += 1

      say "[#{step_index}/#{total_steps}]"
      say
      say render_instruction_line(transform_instruction_label(ui, step[:transform]))
      say

      prompt("(Enter to reveal; q to quit): ")
      say
      say "#{target_label(ui)}: #{Array(step[:answer]).join(' / ')}"
      say

      if listen
        spoken_target = Array(step[:answer]).first.to_s.strip
        unless spoken_target.empty?
          maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken_target, tts_template))
          speak_target_prompt(spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
          say((ui[:replay_hint] || "(Type 'r' to replay audio)"))
          prompt_with_replay("(Enter for next; 'r' to replay; q to quit): ", spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        else
          prompt("(Enter for next; q to quit): ")
        end
      else
        prompt("(Enter for next; q to quit): ")
      end

      say
    end
  end

  say
  say "Done."
end

def conjugate_person_display(item, show_gloss: true)
  person = item[:person].to_s.strip
  gloss = item[:person_gloss].to_s.strip
  return person unless show_gloss
  gloss.empty? ? person : "#{person} — #{gloss}"
end

def conjugate_verb_display(item, show_gloss: true)
  lemma = item[:lemma].to_s.strip
  gloss = item[:gloss].to_s.strip
  return lemma unless show_gloss
  gloss.empty? ? lemma : "#{lemma} — #{gloss}"
end

def conjugate_phonetic_for(item, polarity)
  phonetics = item[:phonetics]

  if phonetics.is_a?(Hash)
    return (phonetics[polarity.to_sym] || phonetics[polarity.to_s] || "").to_s.strip
  end

  phonetics.to_s.strip
end

def run_conjugate_study(selected, ui:, polarity: "positive", listen: false, piper_bin: nil, piper_model: nil, tts_template: DEFAULT_TTS_TEMPLATE, printed_voice: false, drill_category: false)
  say

  total_steps = selected.sum { |item| conjugate_polarities_for_item(item, polarity).length }

  verbs_count = selected.map { |i| i[:lemma] }.uniq.length

  mode = ["study", "conjugate", polarity]
  mode << "listen" if listen

  say "#{ui[:target_language_name] || ui[:language_name] || 'Language'} Conjugation #{ui[:quiz_label] || 'Quiz'} — #{verbs_count} verb(s) (#{total_steps} items) (mode: #{mode.join(', ')})"
  say "-" * 70

  step_index = 0

  selected.each do |item|
    polarities = conjugate_polarities_for_item(item, polarity)
    next if polarities.empty?

    expected_by_polarity = polarities.each_with_object({}) do |current_polarity, out|
      answers = Array(item.dig(:forms, current_polarity.to_sym) || item.dig(:forms, current_polarity))
                  .map { |x| x.to_s.strip }
                  .reject(&:empty?)
      out[current_polarity] = answers unless answers.empty?
    end

    next if expected_by_polarity.empty?

    if polarity.to_s == "both" && expected_by_polarity.key?("positive") && expected_by_polarity.key?("negative")
      positive_answers = expected_by_polarity["positive"]
      negative_answers = expected_by_polarity["negative"]

      start_step = step_index + 1
      end_step = step_index + 2
      step_index += 2

      say
      say "[#{start_step} & #{end_step}/#{total_steps}]"
      say
      say render_prompt_line((ui[:conjugate_prompt] || "Conjugate the verb.").to_s)
      say
      say render_cue_line("Person: #{conjugate_person_display(item, show_gloss: show_gloss?(ui))}")
      say render_cue_line("Verb: #{conjugate_verb_display(item, show_gloss: show_gloss?(ui))}")
      say
      drill_conjugate_category(item, ui: ui, lenient: false, study: true) if drill_category
      lemma_phonetic = item[:lemma_phonetic].to_s.strip
      if show_phonetic?(ui) && !lemma_phonetic.empty?
        say render_gloss_line(format_phonetic(ui, lemma_phonetic))
        say
      end
      say render_instruction_line(conjugate_instruction_label(ui, "positive"))
      positive_display = conjugate_answer_display(item, positive_answers, show_conjugated_form?(ui))
      say "#{target_label(ui)}: #{positive_display}"
      phonetic = conjugate_phonetic_for(item, "positive")
      say "   (#{format_phonetic(ui, phonetic)})" if show_phonetic?(ui) && !phonetic.empty?
      say
      say render_instruction_line(conjugate_instruction_label(ui, "negative"))

      negative_display = conjugate_answer_display(item, negative_answers, show_conjugated_form?(ui))
      say "#{target_label(ui)}: #{negative_display}"
      phonetic = conjugate_phonetic_for(item, "negative")
      say "   (#{format_phonetic(ui, phonetic)})" if show_phonetic?(ui) && !phonetic.empty?
      say

      if listen
        spoken_targets = [positive_answers.first.to_s.strip, negative_answers.first.to_s.strip].reject(&:empty?)

        unless spoken_targets.empty?
          if printed_voice
            spoken_targets.each do |spoken_target|
              maybe_printed_voice(ui, true, build_tts_spoken(spoken_target, tts_template))
            end
          end

          speak_target_sequence(spoken_targets, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
          say((ui[:replay_hint] || "(Type 'r' to replay audio)"))

          loop do
            input = prompt("(Enter for next; 'r' to replay; q to quit): ")
            break if input.nil? || !input.strip.casecmp("r").zero?

            speak_target_sequence(spoken_targets, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
          end
        else
          prompt("(Enter for next; q to quit): ")
        end
      else
        prompt("(Enter for next; q to quit): ")
      end
    else
      expected_by_polarity.each do |current_polarity, expected|
        next if expected.empty?

        step_index += 1

        say
        say "[#{step_index}/#{total_steps}]"
        say
        say render_prompt_line((ui[:conjugate_prompt] || "Conjugate the verb.").to_s)
        say
        say render_cue_line("Person: #{conjugate_person_display(item, show_gloss: show_gloss?(ui))}")
        say render_cue_line("Verb: #{conjugate_verb_display(item, show_gloss: show_gloss?(ui))}")
        say
        drill_conjugate_category(item, ui: ui, lenient: false, study: true) if drill_category
        lemma_phonetic = item[:lemma_phonetic].to_s.strip
        if show_phonetic?(ui) && !lemma_phonetic.empty?
          say render_gloss_line(format_phonetic(ui, lemma_phonetic))
          say
        end
        say render_instruction_line(conjugate_instruction_label(ui, current_polarity))
        say

        prompt("(Enter to reveal; q to quit): ")
        say
        expected_display = conjugate_answer_display(item, expected, show_conjugated_form?(ui))
        say "#{target_label(ui)}: #{expected_display}"
        phonetic = conjugate_phonetic_for(item, current_polarity)
        say "   (#{format_phonetic(ui, phonetic)})" if show_phonetic?(ui) && !phonetic.empty?
        say

        if listen
          spoken_target = expected.first.to_s.strip
          unless spoken_target.empty?
            maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken_target, tts_template))
            speak_target_prompt(spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
            say((ui[:replay_hint] || "(Type 'r' to replay audio)"))
            prompt_with_replay("(Enter for next; 'r' to replay; q to quit): ", spoken_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
          else
            prompt("(Enter for next; q to quit): ")
          end
        else
          prompt("(Enter for next; q to quit): ")
        end
      end
    end
  end

  say
  say "Done."
end
# -----------------------------
# Transform Engine
# -----------------------------

def transform_instruction_label(ui, transform)
  key = "transform_#{transform}_instruction".to_sym
  value = ui[key].to_s.strip if ui.is_a?(Hash)
  return value unless value.nil? || value.empty?

  transform.to_s.capitalize + ":"
end

def transform_step_stats(stats)
  total = stats[:correct_1] + stats[:correct_2] + stats[:failed]
  stats.merge(total: total)
end

def run_transform(selected, ui:, lenient:)
  stats = { correct_1: 0, correct_2: 0, failed: 0 }
  missed = []

  say
  say "#{ui[:target_language_name] || ui[:language_name] || 'Language'} Transform #{ui[:quiz_label] || 'Quiz'} — #{selected.length} item(s) (mode: transform)"
  say "-" * 70

  selected.each_with_index do |item, idx|
    say
    say "[#{idx + 1}/#{selected.length}]"
    say
    say render_prompt_line(item[:prompt].to_s)

    if show_notes?(ui) && !item[:notes].to_s.strip.empty?
      say render_gloss_line(item[:notes].to_s)
    end

    say
    say render_cue_line(item[:cue].to_s)
    say

    Array(item[:steps]).each do |step|
      instruction = transform_instruction_label(ui, step[:transform])
      say render_instruction_line(instruction)

      answer_ok = false

      1.upto(2) do |attempt|
        input = prompt("> ")
        kind, ok, matched = match_answer(input, step[:answer], lenient: lenient)

        if ok
          stats[attempt == 1 ? :correct_1 : :correct_2] += 1
          say(ui[:correct] || "✅ Correct!")
          others = step[:answer] - [matched]
          say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
          answer_ok = true
          break
        else
          say(ui[:try_again] || "Try again.") if attempt < 2
        end
      end

      unless answer_ok
        stats[:failed] += 1
        correct_display = Array(step[:answer]).join(" / ")
        say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{correct_display}"
        missed << {
          prompt: item[:prompt].to_s,
          cue: item[:cue].to_s,
          transform: step[:transform].to_s,
          answer: Array(step[:answer])
        }
      end

      say
    end
  end

  [transform_step_stats(stats), missed]
end

def conjugate_instruction_label(ui, polarity)
  key = "conjugate_#{polarity}_instruction".to_sym
  value = ui[key].to_s.strip if ui.is_a?(Hash)
  return value unless value.nil? || value.empty?

  case polarity.to_s
  when "positive"
    ui[:conjugate_positive_instruction].to_s.strip.empty? ? "Use the positive form:" : ui[:conjugate_positive_instruction].to_s
  when "negative"
    ui[:conjugate_negative_instruction].to_s.strip.empty? ? "Use the negative form:" : ui[:conjugate_negative_instruction].to_s
  else
    ui[:conjugate_instruction].to_s.strip.empty? ? "Use the correct form:" : ui[:conjugate_instruction].to_s
  end
end

def show_notes?(ui)
  !ui.is_a?(Hash) || ui.fetch(:show_notes, true) != false
end

def show_gloss?(ui)
  !ui.is_a?(Hash) || ui.fetch(:show_gloss, true) != false
end

def show_phonetic?(ui)
  !ui.is_a?(Hash) || ui.fetch(:show_phonetic, true) != false
end

def show_conjugated_form?(ui)
  !ui.is_a?(Hash) || ui.fetch(:show_conjugated_form, true) != false
end

def conjugate_answer_display(item, answers, show_conjugated_form)
  base = answers.join(" / ")
  return base unless show_conjugated_form
  return base if answers.empty?

  "#{base} (#{item[:person]} #{answers.first})"
end

def conjugate_polarities_for_item(item, requested)
  requested = requested.to_s.strip.downcase

  case requested
  when "negative"
    return ["negative"] unless Array(item.dig(:forms, :negative)).empty?
    []
  when "both"
    pols = []
    pols << "positive" unless Array(item.dig(:forms, :positive)).empty?
    pols << "negative" unless Array(item.dig(:forms, :negative)).empty?
    pols
  else
    return ["positive"] unless Array(item.dig(:forms, :positive)).empty?
    []
  end
end

def run_conjugate(selected, ui:, lenient:, polarity: "positive", drill_category: false)
  stats = { correct_1: 0, correct_2: 0, failed: 0 }
  missed = []

  selected_with_polarities = selected.map do |item|
    [item, conjugate_polarities_for_item(item, polarity)]
  end.reject do |_item, polarities|
    polarities.empty?
  end

  total_steps = selected_with_polarities.sum { |_item, polarities| polarities.length }

  if total_steps.zero?
    raise "No #{polarity} conjugation forms found. If this is a conjugate pack, make sure each person uses nested positive/negative forms instead of positive-only shorthand."
  end

  verbs_count = selected_with_polarities.map { |item, _polarities| item[:lemma] }.uniq.length

  say
  say "#{ui[:target_language_name] || ui[:language_name] || 'Language'} Conjugation #{ui[:quiz_label] || 'Quiz'} — #{verbs_count} verb(s) (#{total_steps} items) (mode: conjugate, #{polarity})"
  say "-" * 70

  selected_with_polarities.each_with_index do |(item, polarities), idx|
    say
    say "[#{idx + 1}/#{selected.length}]"
    say
    say render_prompt_line((ui[:conjugate_prompt] || "Conjugate the verb.").to_s)
    say
    say render_cue_line("Person: #{conjugate_person_display(item, show_gloss: show_gloss?(ui))}")
    say render_cue_line("Verb: #{conjugate_verb_display(item, show_gloss: show_gloss?(ui))}")
    say
    category_ok = drill_category ? drill_conjugate_category(item, ui: ui, lenient: lenient, study: false) : true
    stats[:failed] += 1 unless category_ok
    say if drill_category
    lemma_phonetic = item[:lemma_phonetic].to_s.strip
    if show_phonetic?(ui) && !lemma_phonetic.empty?
      say render_gloss_line(format_phonetic(ui, lemma_phonetic))
      say
    end
    say

    polarities.each do |current_polarity|
      instruction = conjugate_instruction_label(ui, current_polarity)
      expected = Array(item.dig(:forms, current_polarity.to_sym) || item.dig(:forms, current_polarity)).map { |x| x.to_s.strip }.reject(&:empty?)
      next if expected.empty?

      say render_instruction_line(instruction)
      answer_ok = false

      1.upto(2) do |attempt|
        input = prompt("> ")
        kind, ok, matched = match_answer(input, expected, lenient: lenient)

        if ok
          stats[attempt == 1 ? :correct_1 : :correct_2] += 1
          say(ui[:correct] || "✅ Correct!")
          others = expected - [matched]
          say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
          phonetic = conjugate_phonetic_for(item, current_polarity)
          say "   (#{format_phonetic(ui, phonetic)})" if show_phonetic?(ui) && !phonetic.empty?
          answer_ok = true
          break
        else
          say(ui[:try_again] || "Try again.") if attempt < 2
        end
      end

      unless answer_ok
        stats[:failed] += 1
        say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{expected.join(' / ')}"
        phonetic = conjugate_phonetic_for(item, current_polarity)
        say "#{format_phonetic(ui, phonetic)}" if show_phonetic?(ui) && !phonetic.empty?
        missed << {
          person: item[:person],
          lemma: item[:lemma],
          polarity: current_polarity,
          answer: expected
        }
      end

      say
    end
  end

  [stats.merge(total: total_steps), missed]
end

# -----------------------------
# Quiz Engine
# -----------------------------

def run_quiz(selected, pool:, lenient:, match_game:, listen:, listen_no_english:, listen_show_target:, reverse:, match_options:, piper_bin:, piper_model:, tts_template:, audio_player:, ui:, srs_enabled:, srs:, tts_variant:, answer_variant:, show_variants:, printed_voice:, speak:, shadow:, speech_record_cmd:, speech_bin:, speech_model:, speech_language:, speech_duration:, timing: false, listen_require_source: false)
  stats = { total: selected.length, correct_1: 0, correct_2: 0, failed: 0 }
  timings = []
  missed = []

  say
  mode = []
  primary_mode = if shadow
                   "shadow"
                 elsif speak
                   "speak"
                 elsif match_game
                   "match-game"
                 else
                   "typing"
                 end
  mode << primary_mode
  if listen
    mode << (listen_no_english ? "listen-no-english" : "listen")
  end
  src_name = ui[:source_language_name] || "Source"
  tgt_name = ui[:target_language_name] || ui[:language_name] || "Target"

  # Direction hint (belt and braces): show the active translation direction in mode list.
  unless shadow
    mode << (reverse ? "#{tgt_name}→#{src_name}" : "#{src_name}→#{tgt_name}")
  end

  title_dir = if shadow
                "#{tgt_name} Shadow"
              else
                reverse ? "#{tgt_name} → #{src_name}" : "#{src_name} → #{tgt_name}"
              end
  say "#{title_dir} #{ui[:quiz_label] || 'Quiz'} — #{stats[:total]} word(s) (mode: #{mode.join(', ')})"

  say "-" * 50

  selected.each_with_index do |w, idx|
    start_time = Time.now
    say
    say "[#{idx + 1}/#{stats[:total]}]"

    spoken = nil

    if reverse
      # Finnish → English mode
      if listen
        say "Audible #{target_label(ui)}: (listening…)"
        spoken = choose_tts_text(w, tts_variant)
        if reverse && listen_show_target
          visible_target =
            if show_variants
              format_variants_for_display(w)
            else
              expected_answer_list(w, answer_variant).join(" / ")
            end

          say "#{target_label(ui)}: #{visible_target}" unless visible_target.empty?
        end
        maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken, tts_template))
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        display_text =
          if show_variants
            format_variants_for_display(w)
          else
            expected_answer_list(w, answer_variant).sample
          end
        #label = ui[:target_prefix] || ui[:target_language_name] || ui[:language_name] || "Target"
        say "#{target_label(ui)}: #{display_text}"
      end
    else
      # Normal English → Finnish mode
      if listen
        say "Audible #{target_label(ui)}: (listening…)"
        spoken = choose_tts_text(w, tts_variant)
        maybe_printed_voice(ui, printed_voice, build_tts_spoken(spoken, tts_template))
        speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
        say "#{source_label(ui)}: #{w[:prompt].join(' / ')}" unless listen_no_english
        say(ui[:replay_hint] || "(Type 'r' to replay audio)")
      else
        if shadow
          shadow_display =
            if show_variants
              format_variants_for_display(w)
            else
              expected_answer_list(w, answer_variant).join(" / ")
            end

          say "#{target_label(ui)}: #{shadow_display}" unless shadow_display.empty?
          say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].to_s.strip.empty?
        else
          say "#{source_label(ui)}: #{w[:prompt].join(' / ')}"
        end
      end
    end

    answer_ok = false
    speech_transcript = nil
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

    speech_mode = speak || shadow

    1.upto(speech_mode ? 1 : 2) do |attempt|
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
                    meaning_label = source_label(ui)
                    prompt_with_replay("Type the #{meaning_label} meaning: ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                  else
                    prompt("#{source_label(ui)}: ")
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

            say "   (#{source_label(ui)}: #{w[:prompt].join(' / ')})"
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
                      heard_label = target_label(ui)
                      prompt_with_replay("Type what you heard (#{heard_label}): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                    else
                      prompt("#{target_label(ui)}: ")
                    end

            kind, ok, matched = match_answer(input, correct_list, lenient: lenient)

            if ok
              if listen_require_source && !prompt_source_meaning(w, ui: ui, lenient: false)
                break
              end

              stats[:"correct_#{attempt}"] += 1

              if kind == :umlaut_lenient
                say(ui[:correct] || "✅ Correct!")
              else
                say(ui[:correct] || "✅ Correct!")
              end

              others = correct_list - [matched]
              say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
              say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].empty?
              say "   (#{source_label(ui)}: #{w[:prompt].join(' / ')})"
              update_srs!(srs, wid, attempt == 1 ? 5 : 4) if srs_enabled
              answer_ok = true
              break
            else
              say(ui[:try_again] || "Try again.") if attempt < 2
            end
          end
      else
        input = if speech_mode
                  if shadow
                    shadow_target = choose_tts_text(w, tts_variant)
                    maybe_printed_voice(ui, printed_voice, build_tts_spoken(shadow_target, tts_template))
                    speak_target_prompt(shadow_target, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                  end
                  prompt_to_speak(ui, duration: speech_duration)
                  audio_path = record_speech_audio(speech_record_cmd, duration: speech_duration, ui: ui)
                  begin
                    transcript = whisper_transcribe(
                      audio_path,
                      speech_bin: speech_bin,
                      model: speech_model,
                      language: speech_language
                    )
                  rescue RuntimeError => e
                    if e.message.include?("empty transcript")
                      transcript = ""
                    else
                      raise
                    end
                  ensure
                    File.delete(audio_path) if audio_path && File.exist?(audio_path)
                  end
                  speech_transcript = transcript
                  transcript
                elsif listen
                  heard_label = target_label(ui)
                  meaning_label = source_label(ui)
                  prompt_with_replay(
                    reverse ? "Type the #{meaning_label} meaning: " : "Type what you heard (#{heard_label}): ",
                    spoken,
                    piper_bin: piper_bin,
                    piper_model: piper_model,
                    template: tts_template
                  )
                else
                  prompt(reverse ? "#{source_label(ui)}: " : "#{target_label(ui)}: ")
                end

        if reverse
          expected = w[:prompt]
          if speech_mode
            kind, ok, matched, speech_score, speech_overlap = speech_match_result(input, expected, lenient: false)
          else
            kind, ok, matched = match_answer(input, expected, lenient: false)
          end
        else
          expected = expected_answer_list(w, answer_variant)
          if speech_mode
            kind, ok, matched, speech_score, speech_overlap = speech_match_result(input, expected, lenient: lenient)
          else
            kind, ok, matched = match_answer(input, expected, lenient: lenient)
          end
        end

        if ok
          if !reverse && listen_require_source && !prompt_source_meaning(w, ui: ui, lenient: false)
            break
          end

          stats[:"correct_#{attempt}"] += 1

          if kind == :close
            say(ui[:close_enough] || "🟡 Close enough")
          elsif kind == :umlaut_lenient
            say(ui[:correct] || "✅ Correct!")
          else
            say(ui[:correct] || "✅ Correct!")
          end

         if speech_mode && speech_transcript && !speech_transcript.to_s.strip.empty?
            heard_label = (ui[:heard_prefix] || "Heard").to_s.sub(/:\z/, "")
            say "   #{heard_label}: #{speech_transcript}"
          end

          unless speech_mode
            if reverse
              others = expected - [matched]
              say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?

              # In reverse listen modes, reveal the written answer (and phonetic) after a correct response.
              say_reverse_listen_reveal(w, ui) if listen

              # Always show the source-side variants (English) for reverse mode after a correct response.
              say "   (#{source_label(ui)}: #{w[:prompt].join(' / ')})"
            else
              # Use the same answer set we validated against (written/spoken/either).
              others = expected - [matched]
              say "   #{ui[:also_accepted_prefix] || 'Also accepted:'} #{others.join(' / ')}" unless others.empty?
              say "   (#{source_label(ui)}: #{w[:prompt].join(' / ')})"
              say "   (#{format_phonetic(ui, w[:phonetic])})" unless w[:phonetic].empty?
            end
          end
          update_srs!(srs, wid, attempt == 1 ? 5 : 4) if srs_enabled
          answer_ok = true
          break
        else
          say(ui[:try_again] || "Try again.") if attempt < (speech_mode ? 1 : 2)
        end
      end
    end

    unless answer_ok
      say
      stats[:failed] += 1
      if reverse
        say "#{ui[:correct_answer_prefix] || '❌ Correct answer:'} #{w[:prompt].join(' / ')}"

        target_text =
          if show_variants
            format_variants_for_display(w)
          else
            expected_answer_list(w, answer_variant).join(" / ")
          end

        say "#{target_label(ui)}: #{target_text}"
        say "#{format_phonetic(ui, w[:phonetic])}" unless w[:phonetic].empty?
      else
        correct_display = expected_answer_list(w, answer_variant).join(" / ")
        say "#{ui[:correct_word_prefix] || '❌ Correct word:'} #{correct_display}"
        say "#{format_phonetic(ui, w[:phonetic])}" unless w[:phonetic].empty?
      end
      if speech_mode
        heard_label = (ui[:heard_prefix] || "Heard").to_s.sub(/:\z/, "")
        if speech_transcript && !speech_transcript.to_s.strip.empty?
          say "#{heard_label}: #{speech_transcript}"
        else
          say "#{heard_label}: (nothing recognized)"
        end
      end
      update_srs!(srs, wid, 2) if srs_enabled
      missed << w

    end
    elapsed = Time.now - start_time
    timings << elapsed if timing
  end
  if timing && !timings.empty?
    total_time = timings.sum
    avg = total_time / timings.size
    sorted = timings.sort
    median = sorted[timings.size / 2]

    say
    say "Timing"
    say "Total: #{format_time(total_time)}"
    say "Avg/item: #{avg.round(2)}s"
    say "Median: #{median.round(2)}s"
  end

  [stats, missed]
end

def run_conversation(entries, ui:, piper_bin:, piper_model:, tts_template:, listen:, printed_voice:, audio_player:)
  say
  say "Conversation — #{entries.length} lines"
  say "-" * 40

  entries.each do |w|
    speaker_name = (w[:speaker] || "").to_s.strip

    fi = (w[:answer] || []).first.to_s.strip
    en = (w[:prompt] || []).first.to_s.strip
    phon = w[:phonetic].to_s.strip
    spoken_text = ensure_terminal_punct(fi)

    next if fi.empty?

    say

    if listen
      maybe_printed_voice(ui, printed_voice, spoken_text)
      conversation_speak_line(
        spoken_text,
        piper_bin: piper_bin,
        piper_model: piper_model
      )
      pause = fi.strip.end_with?("?") ? 0.9 : 0.6
      sleep(pause) # slightly longer pause after questions
    end

    # Visual cue: always show the label 'Speaker', and if a speaker name exists,
    # include it before the Finnish line.
    if speaker_name.empty?
      say "Speaker: #{fi}"
    else
      say "Speaker: #{speaker_name}: #{fi}"
    end
    say " - (#{format_phonetic(ui, phon)})" unless phon.empty?
    say " - #{en}" unless en.empty?

    unless listen
      conversation_speak_line(
        spoken_text,
        piper_bin: piper_bin,
        piper_model: piper_model
      )
      pause = fi.strip.end_with?("?") ? 0.9 : 0.6
      sleep(pause) # slightly longer pause after questions
    end

    # Allow replay with 'r' before advancing
    loop do
      input = prompt("(Enter for next; 'r' to replay): ")
      break if input.nil? || input.strip.empty?

      if input.strip.casecmp("r").zero?
        maybe_printed_voice(ui, printed_voice, spoken_text)
        conversation_speak_line(
          spoken_text,
          piper_bin: piper_bin,
          piper_model: piper_model
        )

        next
      end

      break
    end
  end
end

# -----------------------------
# Output
# -----------------------------

def write_missed_file(input_path, pack_meta, stats, missed, lenient:, match_game:, listen:, listen_no_english:, reverse:, output_dir: nil)
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

  output_path =
    if output_dir && !output_dir.to_s.strip.empty?
      expanded_dir = File.expand_path(output_dir.to_s.strip)
      FileUtils.mkdir_p(expanded_dir)
      File.join(expanded_dir, filename)
    else
      filename
    end

  File.write(output_path, YAML.dump(payload))
  output_path
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
  listen_show_target: false,
  listen_require_source: false,
  reverse: false,
  study: false,
  conversation: false,
  transform: false,
  timing: false,
  conjugate: false,
  conjugate_polarity: "positive",
  drill_category: false,
  match_options: "auto",
  piper_bin: ENV["PIPER_BIN"],
  piper_model: ENV["PIPER_MODEL"],
  audio_player: ENV["AUDIO_PLAYER"],
  tts_template: ENV["TTS_TEMPLATE"],
  tts_variant: "written",          # written|spoken (controls what Piper speaks when --listen)
  answer_variant: "written",       # written|spoken|either (controls what is accepted as correct typed answer)
  show_variants: false,            # show written/spoken together when available
  printed_voice: false,            # with --listen, also print the exact text sent to Piper
  ui: nil,
  count: nil,
  srs: false,
  srs_due_only: false,
  srs_new: 5,
  srs_reset: false,
  srs_file: nil,
  speak: false,
  shadow: false,
  speech_record_cmd: ENV["SPEECH_RECORD_CMD"],
  speech_bin: ENV["WHISPER_BIN"] || ENV["SPEECH_BIN"],
  speech_model: ENV["WHISPER_MODEL"] || ENV["SPEECH_MODEL"],
  speech_language: ENV["WHISPER_LANGUAGE"] || ENV["SPEECH_LANGUAGE"],
  speech_duration: (ENV.key?("SPEECH_DURATION") ? ENV["SPEECH_DURATION"].to_i : nil),
  missed_output_dir: nil,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby linguatrain.rb <yaml_file> [count|all] [options]"

  opts.on("--config PATH", "Path to user config YAML (or set LINGUATRAIN_CONFIG)") { |v| options[:config] = v }
  opts.on("--localisation PATH", "Path to localisation YAML (overrides config.yaml localisation)") { |v| options[:localisation] = v }
  opts.on("--audio-player CMD", "Audio player command (default from config; macOS: afplay)") { |v| options[:audio_player] = v }

  opts.on("--lenient-umlauts", "Allow a for ä and o for ö") { options[:lenient] = true }
  opts.on("--match-game", "Enable multiple choice mode") { options[:match_game] = true }
  opts.on("--listen", "Listening mode: speak target language (Piper) and type what you heard") { options[:listen] = true }
  opts.on("--timing", "Show timing metrics for quiz runs") do
    options[:timing] = true
  end

  opts.on("--printed-voice", "With --listen, also print the exact text sent to Piper") do
    options[:printed_voice] = true
  end

  opts.on("--listen-no-source", "Listening mode without showing source prompt") do
    options[:listen] = true
    options[:listen_no_english] = true
  end
  opts.on("--listen-show-target", "With --listen, also show the written target-language text") do
    options[:listen] = true
    options[:listen_show_target] = true
  end
  opts.on("--listen-require-source", "With --listen, also require typing the source-language meaning after what you heard") do
    options[:listen] = true
    options[:listen_no_english] = true
    options[:listen_require_source] = true
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

  opts.on("--conversation", "Conversation mode: play lines sequentially with TTS") do
    options[:conversation] = true
  end

  opts.on("--transform", "Transform mode: prompt with cue-based grammar steps") do
    options[:transform] = true
  end

  opts.on("--conjugate", "Conjugation mode: person + verb grammar drills") do
    options[:conjugate] = true
  end

  opts.on("--negative", "With --conjugate, drill only negative forms") do
    options[:conjugate_polarity] = "negative"
  end

  opts.on("--both", "With --conjugate, drill both positive and negative forms") do
    options[:conjugate_polarity] = "both"
  end

  opts.on("--speak", "Speaking mode: record your voice and score it with Whisper") do
    options[:speak] = true
  end

  opts.on("--shadow", "Shadow mode: play target audio with Piper, then record your voice and score it with Whisper") do
    options[:shadow] = true
  end

  opts.on("--speech-record-cmd CMD", "Shell command to record speech audio. Use {output} and {duration} placeholders") do |v|
    options[:speech_record_cmd] = v
  end

  opts.on("--speech-bin PATH", "Path to whisper executable (or set WHISPER_BIN / SPEECH_BIN)") do |v|
    options[:speech_bin] = v
  end

  opts.on("--speech-model NAME", "Whisper model name (default: base)") do |v|
    options[:speech_model] = v.to_s.strip
  end

  opts.on("--speech-language NAME", "Whisper language name (default: Finnish)") do |v|
    options[:speech_language] = v.to_s.strip
  end

  opts.on("--speech-duration N", Integer, "Seconds to record in --speak mode (default: 3)") do |v|
    options[:speech_duration] = v
  end

  opts.on("--drill-category", "With --conjugate, ask for the declared verb category before the conjugation") do
    options[:drill_category] = true
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

if options[:study]
  abort("--study cannot be combined with --match-game") if options[:match_game]
  abort("--study cannot be combined with --lenient-umlauts") if options[:lenient]
  abort("--study cannot be combined with --speak") if options[:speak]
  abort("--study cannot be combined with --conversation") if options[:conversation]
  abort("--study cannot be combined with --reverse when used with --conjugate") if options[:conjugate] && options[:reverse]

  if options[:srs] || options[:srs_due_only] || options[:srs_reset] || options[:srs_file]
    abort("--study ignores SRS. Remove --srs/--due/--new/--reset-srs/--srs-file.")
  end
end

abort("--speak cannot be combined with --match-game") if options[:speak] && options[:match_game]
abort("--speak cannot be combined with --listen") if options[:speak] && options[:listen]
abort("--speak cannot be combined with --conversation") if options[:speak] && options[:conversation]
abort("--speak cannot be combined with --shadow") if options[:speak] && options[:shadow]
abort("--shadow cannot be combined with --match-game") if options[:shadow] && options[:match_game]
abort("--shadow cannot be combined with --listen") if options[:shadow] && options[:listen]
abort("--shadow cannot be combined with --conversation") if options[:shadow] && options[:conversation]
abort("--listen-require-source cannot be combined with --reverse") if options[:listen_require_source] && options[:reverse]
abort("--listen-require-source cannot be combined with --speak") if options[:listen_require_source] && options[:speak]
abort("--listen-require-source cannot be combined with --shadow") if options[:listen_require_source] && options[:shadow]

if options[:transform]
  abort("--transform cannot be combined with --match-game") if options[:match_game]

  abort("--transform cannot be combined with --speak") if options[:speak]
  abort("--transform cannot be combined with --shadow") if options[:shadow]
  abort("--transform cannot be combined with --reverse") if options[:reverse]
  abort("--transform cannot be combined with --listen unless used with --study") if options[:listen] && !options[:study]
  abort("--transform cannot be combined with --conversation") if options[:conversation]

  if options[:srs] || options[:srs_due_only] || options[:srs_reset] || options[:srs_file]
    abort("--transform does not support SRS yet. Remove --srs/--due/--new/--reset-srs/--srs-file.")
  end
end

if options[:conjugate]
  abort("--conjugate cannot be combined with --match-game") if options[:match_game]
  abort("--conjugate cannot be combined with --listen unless used with --study") if options[:listen] && !options[:study]
  abort("--conjugate cannot be combined with --speak") if options[:speak]
  abort("--conjugate cannot be combined with --shadow") if options[:shadow]
  abort("--conjugate cannot be combined with --reverse") if options[:reverse]
  abort("--conjugate cannot be combined with --conversation") if options[:conversation]
  abort("--conjugate cannot be combined with --transform") if options[:transform]
  unless %w[positive negative both].include?(options[:conjugate_polarity].to_s)
    abort("--conjugate polarity must be one of: positive, negative, both")
  end

  if options[:srs] || options[:srs_due_only] || options[:srs_reset] || options[:srs_file]
    abort("--conjugate does not support SRS yet. Remove --srs/--due/--new/--reset-srs/--srs-file.")
  end
end

pack = load_pack(yaml_path)
pack_meta = pack[:meta] || {}
words = pack[:words] || []
transform_entries = pack[:transform_entries] || []
conjugate_entries = pack[:conjugate_entries] || []
conjugate_persons = pack[:conjugate_persons] || []
conjugate_person_defs = pack[:conjugate_person_defs] || conjugate_persons

user_cfg_path = resolve_user_config_path(options[:config])
user_cfg = load_yaml_hash(user_cfg_path)
loc_path = resolve_localisation_path(options[:localisation], user_cfg, user_cfg_path)

loc = load_localisation(loc_path)
localisation = loc

$LOCALISATION_ID = begin
                     src = loc.dig(:languages, :source, :code)
                     tgt = loc.dig(:languages, :target, :code)
                     (src && !src.to_s.strip.empty? && tgt && !tgt.to_s.strip.empty?) ? "#{src}_#{tgt}" : nil
                   end

# Make localisation UI available to resolve_settings!
options[:localisation_ui] = localisation[:ui] || {}

# Effective meta includes localisation languages + (optional) localisation TTS template.
effective_pack_meta = effective_meta(pack_meta, localisation)

resolve_settings!(options, user_cfg, effective_pack_meta)
pack_meta = effective_pack_meta


# Provide globals for small helpers.
$UI = options[:ui] || DEFAULT_UI
$AUDIO_PLAYER = options[:audio_player]

if options[:listen] || options[:conversation] || options[:shadow]
  abort("--listen/--conversation/--shadow requires Piper settings: provide --piper-bin/--piper-model, set PIPER_BIN/PIPER_MODEL, or configure ~/.config/linguatrain/config.yaml") unless options[:piper_bin] && options[:piper_model]
end

if options[:speak] || options[:shadow]
  abort("--speak/--shadow requires --speech-record-cmd (or speech.record_cmd in config.yaml)") if options[:speech_record_cmd].to_s.strip.empty?
  abort("--speak/--shadow requires Whisper settings: provide --speech-bin, set WHISPER_BIN/SPEECH_BIN, or configure speech.bin in config.yaml") if options[:speech_bin].to_s.strip.empty?
end

options[:missed_output_dir] ||= user_cfg.dig(:runtime, :missed_output_dir)

srs_enabled = options[:srs] && !options[:study]
srs_path = options[:srs_file] || default_srs_path(yaml_path, pack_meta)

srs = srs_enabled ? load_srs(srs_path) : { "meta" => {}, "items" => {} }

if options[:transform]
  abort("This pack does not contain transform entries.") if transform_entries.empty?
elsif options[:conjugate]
  abort("This pack does not contain conjugate entries.") if conjugate_entries.empty?
else
  drill_type = pack_meta[:drill_type].to_s.strip.downcase
  abort("This pack is a transform pack. Use --transform.") if drill_type == "transform"
  abort("This pack is a conjugate pack. Use --conjugate.") if drill_type == "conjugate"
end

if options[:transform]
  shuffle_cues = !!pack_meta[:shuffle_cues]
  transform_items = flatten_transform_items(transform_entries, shuffle_cues: shuffle_cues)
  selected = choose_transform_items(transform_items, options[:count])
elsif options[:conjugate]
  shuffle_persons = !!pack_meta[:shuffle_persons]
  selected_entries = choose_conjugate_entries(conjugate_entries, options[:count])
  selected = flatten_conjugate_items(selected_entries, conjugate_person_defs, shuffle_persons: shuffle_persons)
elsif srs_enabled
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
  if options[:shadow]
    if options[:count].nil? || options[:count] == "all"
      selected = words
    else
      selected = words.take(Integer(options[:count]))
    end
  else
    selected = choose_words(words, options[:count])
  end
end
# Conversation mode and shadow mode should always follow the pack order (no shuffling / no SRS ordering).
if options[:conversation]
  if options[:count].nil? || options[:count] == "all"
    selected = words
  else
    selected = words.take(Integer(options[:count]))
  end
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

  if options[:conversation]
    run_conversation(
      selected,
      ui: options[:ui] || DEFAULT_UI,
      piper_bin: options[:piper_bin],
      piper_model: options[:piper_model],
      tts_template: options[:tts_template],
      listen: options[:listen],
      printed_voice: options[:printed_voice],
      audio_player: options[:audio_player]
    )
    exit(0)
  end

  if options[:transform] && !options[:study]
    stats, missed = run_transform(
      selected,
      ui: options[:ui] || DEFAULT_UI,
      lenient: options[:lenient]
    )

    say
    say "-" * 50
    results_label = pack_meta[:id].to_s.strip
    results_label = pack_meta[:pack_name].to_s.strip if results_label.empty?
    say(results_label.empty? ? "Results" : "Results from #{results_label}")
    say "Total steps: #{stats[:total]}"
    say "Correct 1st: #{stats[:correct_1]} (#{pct(stats[:correct_1], stats[:total]).round(1)}%)"
    say "Correct 2nd: #{stats[:correct_2]} (#{pct(stats[:correct_2], stats[:total]).round(1)}%)"
    say "Failed: #{stats[:failed]} (#{pct(stats[:failed], stats[:total]).round(1)}%)"

    if missed.any?
      say
      say "Missed steps (quick review):"
      missed.each_with_index do |m, missed_idx|
        say "#{missed_idx + 1}. #{m[:prompt]}"
        say "   [ #{m[:cue]} ]"
        say "   #{m[:transform]} → #{Array(m[:answer]).join(' / ')}"
        say
      end
    else
      say
      puts $UI[:no_mistakes] || "😊 No mistakes — nice work!"
    end

    exit(0)
  end



  if options[:study]
    if options[:conjugate]
      run_conjugate_study(
        selected,
        ui: options[:ui] || DEFAULT_UI,
        polarity: options[:conjugate_polarity],
        listen: options[:listen],
        drill_category: options[:drill_category],
        piper_bin: options[:piper_bin],
        piper_model: options[:piper_model],
        tts_template: options[:tts_template],
        printed_voice: options[:printed_voice]
      )
    elsif options[:transform]
      run_transform_study(
        selected,
        ui: options[:ui] || DEFAULT_UI,
        listen: options[:listen],
        piper_bin: options[:piper_bin],
        piper_model: options[:piper_model],
        tts_template: options[:tts_template],
        printed_voice: options[:printed_voice]
      )
    else
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
        show_variants: options[:show_variants],
        printed_voice: options[:printed_voice]
      )
    end

    # Study mode has no scoring/missed packs.
    exit(0)
  end

  if options[:conjugate]
    stats, missed = run_conjugate(
      selected,
      ui: options[:ui] || DEFAULT_UI,
      lenient: options[:lenient],
      polarity: options[:conjugate_polarity],
      drill_category: options[:drill_category]
    )

    say
    say "-" * 50
    results_label = pack_meta[:id].to_s.strip
    results_label = pack_meta[:pack_name].to_s.strip if results_label.empty?
    say(results_label.empty? ? "Results" : "Results from #{results_label}")
    say "Total steps: #{stats[:total]}"
    say "Correct 1st: #{stats[:correct_1]} (#{pct(stats[:correct_1], stats[:total]).round(1)}%)"
    say "Correct 2nd: #{stats[:correct_2]} (#{pct(stats[:correct_2], stats[:total]).round(1)}%)"
    say "Failed: #{stats[:failed]} (#{pct(stats[:failed], stats[:total]).round(1)}%)"

    if missed.any?
      say
      say "Missed items (quick review):"
      missed.each_with_index do |m, missed_idx|
        say "#{missed_idx + 1}. #{m[:person]} + #{m[:lemma]} (#{m[:polarity]})"
        say "   #{Array(m[:answer]).join(' / ')}"
        say
      end
    else
      say
      puts $UI[:no_mistakes] || "😊 No mistakes — nice work!"
    end

    exit(0)
  end

  stats, missed = run_quiz(
    selected,
    pool: words,
    lenient: options[:lenient],
    match_game: options[:match_game],
    listen: options[:listen],
    listen_no_english: options[:listen_no_english],
    listen_show_target: options[:listen_show_target],
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
    show_variants: options[:show_variants],
    printed_voice: options[:printed_voice],
    speak: options[:speak],
    shadow: options[:shadow],
    speech_record_cmd: options[:speech_record_cmd],
    speech_bin: options[:speech_bin],
    speech_model: options[:speech_model],
    speech_language: options[:speech_language],
    speech_duration: options[:speech_duration],
    timing: options[:timing],
    listen_require_source: options[:listen_require_source]
  )

  say
  say "-" * 50
  results_label = pack_meta[:id].to_s.strip
  results_label = pack_meta[:pack_name].to_s.strip if results_label.empty?
  say(results_label.empty? ? "Results" : "Results from #{results_label}")
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
      reverse: options[:reverse],
      output_dir: options[:missed_output_dir]
    )

    say
    say "Missed words saved to: #{outfile}"
    say
    say "Missed items (quick review):"
    missed.each_with_index do |w, idx|
      source_text = w[:prompt].join(" / ")
      target_text = all_answer_variants_for_display(w).join(" / ")

      if options[:reverse]
        say "#{idx + 1}. #{target_label(options[:ui])}: #{target_text}"
        say "   #{source_label(options[:ui])}: #{source_text}"
      else
        say "#{idx + 1}. #{source_label(options[:ui])}: #{source_text}"
        say "   #{target_label(options[:ui])}: #{target_text}"
      end

      say
    end
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
