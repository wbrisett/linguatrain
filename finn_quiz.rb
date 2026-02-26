#!/usr/bin/env ruby
# frozen_string_literal: true

# finn_quiz.rb
# Language quiz CLI (typing / match-game / listening via Piper)

require "yaml"
require "time"
require "optparse"
require "securerandom"

# -----------------------------
# Utility
# -----------------------------

def say(msg = "")
  puts msg
end

def prompt(msg)
  print msg
  STDOUT.flush
  STDIN.gets&.chomp
end

def normalize_basic(s)
  s.to_s.strip.downcase
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

  wav = File.join("/tmp", "finn_quiz_tts_#{Process.pid}_#{SecureRandom.hex(4)}.wav")

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
  ok_play = system("afplay", wav)
  raise "Audio playback failed (afplay)." unless ok_play
ensure
  File.delete(wav) if wav && File.exist?(wav)
end

def speak_target_prompt(text, piper_bin:, piper_model:, template: "Suomeksi: {text}.")
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

def load_words(path)
  data = YAML.load_file(path)

  raw_entries =
    if data.is_a?(Array)
      data
    elsif data.is_a?(Hash)
      # Support multiple top-level shapes:
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
    else
      raise "Unsupported YAML structure."
    end

  raw_entries.map do |w|
    en = w["en"] || w[:en] || w["english"] || w[:english]
    fi = w["fi"] || w[:fi] || w["finnish"] || w[:finnish]
    phon = w["phon"] || w[:phon] || w["phonetic"] || w[:phonetic]

    raise "Invalid word entry: #{w.inspect}" if en.to_s.strip.empty? || fi.nil?

    fi_list =
      case fi
      when Array
        fi.map { |x| x.to_s.strip }.reject(&:empty?)
      else
        [fi.to_s.strip]
      end

    raise "Invalid word entry: #{w.inspect}" if fi_list.empty?

    { en: en.to_s.strip, fi: fi_list, phon: phon.to_s.strip }
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


def pick_distractors(pool, correct_fi_list, n: 2)
  all_correct = correct_fi_list.to_a
  candidates = pool.flat_map { |w| w[:fi] }.uniq - all_correct
  raise "Not enough distractors." if candidates.size < n
  candidates.sample(n)
end

# -----------------------------
# Quiz Engine
# -----------------------------

def run_quiz(selected, pool:, lenient:, match_game:, listen:, listen_no_english:, piper_bin:, piper_model:, tts_template:)
  stats = { total: selected.length, correct_1: 0, correct_2: 0, failed: 0 }
  missed = []

  say
  mode = []
  mode << (match_game ? "match-game" : "typing")
  if listen
    mode << (listen_no_english ? "listen-no-english" : "listen")
  end
  say "Finnish Quiz — #{stats[:total]} word(s) (mode: #{mode.join(', ')})"
  say "-" * 50

  selected.each_with_index do |w, idx|
    say
    say "[#{idx + 1}/#{stats[:total]}]"

    spoken = nil
    if listen
      say "Audible Finnish: (listening…)"
      spoken = w[:fi].sample
      speak_target_prompt(spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
      say "English: #{w[:en]}" unless listen_no_english
      say "(Type 'r' to replay audio)"
    else
      say "English: #{w[:en]}"
    end

    answer_ok = false

    1.upto(2) do |attempt|
      if match_game
        correct_list = w[:fi]
        shown_correct = correct_list.sample

        distractors = pick_distractors(pool, correct_list, n: 2)
        options = ([shown_correct] + distractors).shuffle

        say "Options:"
        options.each { |opt| say "  - #{opt}" }

        input = if listen
                  prompt_with_replay("Type what you heard (Finnish): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                else
                  prompt("Type the Finnish word: ")
                end

        kind, ok, matched = match_answer(input, correct_list, lenient: lenient)

        if ok
          stats[:"correct_#{attempt}"] += 1

          if kind == :umlaut_lenient
            say "✅ Hyvä! Muista: ä ja ö ovat tärkeitä 😉"
          else
            say "✅ Oikein!"
          end

          others = correct_list - [matched]
          say "   Also accepted: #{others.join(' / ')}" unless others.empty?
          say "   (phonetic: #{w[:phon]})" unless w[:phon].empty?

          answer_ok = true
          break
        else
          say "Yritä uudelleen." if attempt < 2
        end
      else
        input = if listen
                  prompt_with_replay("Type what you heard (Finnish): ", spoken, piper_bin: piper_bin, piper_model: piper_model, template: tts_template)
                else
                  prompt("Finnish: ")
                end

        kind, ok, matched = match_answer(input, w[:fi], lenient: lenient)

        if ok
          stats[:"correct_#{attempt}"] += 1

          if kind == :umlaut_lenient
            say "✅ Hyvä! Muista: ä ja ö ovat tärkeitä 😉"
          else
            say "✅ Oikein!"
          end

          others = w[:fi] - [matched]
          say "   Also accepted: #{others.join(' / ')}" unless others.empty?
          say "   (phonetic: #{w[:phon]})" unless w[:phon].empty?

          answer_ok = true
          break
        else
          say "Yritä uudelleen." if attempt < 2
        end
      end
    end

    unless answer_ok
      stats[:failed] += 1
      say "❌ Oikea sana: #{w[:fi].join(' / ')}#{w[:phon].empty? ? '' : " (#{w[:phon]})"}"
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
  lenient: false,
  match_game: false,
  listen: false,
  listen_no_english: false,
  piper_bin: ENV["PIPER_BIN"],
  piper_model: ENV["PIPER_MODEL"],
  tts_template: ENV["TTS_TEMPLATE"] || "Suomeksi: {text}.",
  count: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby finn_quiz.rb <yaml_file> [count|all] [options]"

  opts.on("--lenient-umlauts", "Allow a for ä and o for ö") { options[:lenient] = true }
  opts.on("--match-game", "Enable multiple choice mode") { options[:match_game] = true }
  opts.on("--listen", "Listening mode: speak Finnish (Piper) and type what you heard") { options[:listen] = true }

  opts.on("--listen-no-english", "Listening mode without showing English translation") do
    options[:listen] = true
    options[:listen_no_english] = true
  end

  opts.on("--piper-bin PATH", "Path to piper executable (or set PIPER_BIN env var)") { |v| options[:piper_bin] = v }
  opts.on("--piper-model PATH", "Path to Piper .onnx model (or set PIPER_MODEL env var)") { |v| options[:piper_model] = v }
  opts.on("--tts-template STR", "TTS template, e.g. 'Suomeksi: {text}.' (or set TTS_TEMPLATE)") { |v| options[:tts_template] = v }
end

parser.parse!

yaml_path = ARGV.shift or abort("Missing YAML file.")
options[:count] = ARGV.shift

if options[:listen]
  abort("--listen requires --piper-bin (or PIPER_BIN) and --piper-model (or PIPER_MODEL)") unless options[:piper_bin] && options[:piper_model]
end

words = load_words(yaml_path)
selected = choose_words(words, options[:count])

stats, missed = run_quiz(
  selected,
  pool: words,
  lenient: options[:lenient],
  match_game: options[:match_game],
  listen: options[:listen],
  listen_no_english: options[:listen_no_english],
  piper_bin: options[:piper_bin],
  piper_model: options[:piper_model],
  tts_template: options[:tts_template]
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
  say "😊 Ei virheitä — hienoa työtä!"
end
