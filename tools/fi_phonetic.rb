#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/fi_phonetic.rb
#
# Beginner-friendly Finnish pronunciation helper for Linguatrain.
#
# This intentionally does not emit IPA. It creates stable, learner-readable
# pronunciation hints such as:
#   olla      -> OHL-lah
#   kirja     -> KEER-yah
#   kirjasto  -> KEER-yahs-toh
#   läpikulku -> LAP-ee-KOOL-koo
#
# Usage:
#   ruby tools/fi_phonetic.rb "Helsingissä"
#   ruby tools/fi_phonetic.rb --yaml packs/fi/some_pack.yaml
#   ruby tools/fi_phonetic.rb --yaml packs/fi/some_pack.yaml --output out.yaml
#   ruby tools/fi_phonetic.rb --yaml packs/fi/some_pack.yaml --in-place
#   ruby tools/fi_phonetic.rb --yaml packs/fi/some_pack.yaml --field prompt --key phonetics --force
#
# YAML behavior:
# - Default input field is entry["prompt"], because Linguatrain Finnish packs usually
#   prompt with Finnish and answer with English.
# - Default output key is "phonetics".
# - Also supports older nested answer shapes where answer items contain { "fi" => ... }.

require "optparse"
require "yaml"

module Linguatrain
  class FinnishPhonetic
    VOWELS = "aeiouyäöå".chars.freeze

    DIPHTHONGS = %w[
      ai ei oi ui yi äi öi
      au eu iu ou äy öy ey
      ie uo yö
    ].freeze

    OVERRIDES = {
      "olla" => "OHL-lah",
      "ei" => "AY",
      "se" => "SEH",
      "hän" => "HAN",
      "minä" => "MEE-na",
      "sinä" => "SEE-na",
      "mikä" => "MEE-ka",
      "ja" => "yah",
      "tämä" => "TA-ma",
      "tehdä" => "TEH-da",
      "tie" => "TEE-eh",
      "tietää" => "TEE-eh-taa",
      "tulla" => "TOOL-lah",
      "haluta" => "HAH-loo-tah",
      "niin" => "NEEN",
      "saada" => "SAH-dah",
      "pitää" => "PEE-taa",
      "mutta" => "MOOT-tah",
      "hyvä" => "HUU-va",
      "mennä" => "MEN-na",
      "vain" => "VINE",
      "kaikki" => "KIKE-kee",
      "jos" => "yohs",
      "nyt" => "NUUT",
      "joka" => "YOH-kah",
      "sana" => "SAH-nah",
      "sanoa" => "SAH-noh-ah",
      "kun" => "koon",
      "kuin" => "koo-een",
      "nähdä" => "NAH-da",
      "antaa" => "AHN-tah",
      "tuo" => "TOO-oh",
      "täällä" => "TAAL-la",
      "kiitos" => "KEE-tohs",
      "mies" => "MEE-ehs",
      "hei" => "HAY",
      "kuka" => "KOO-kah",
      "katsoa" => "KAHT-soh-ah",
      "isä" => "EE-sa",
      "lähteä" => "LAHT-eh-ah",
      "yksi" => "UUK-see",
      "äiti" => "AI-tee",
      "kuulla" => "KOOL-lah",
      "hyvin" => "HUU-veen",
      "apu" => "AH-poo",
      "anteeksi" => "AHN-tehk-see",
      "poika" => "POY-kah",
      "päivä" => "PAI-va",
      "työ" => "TUU-uh",
      "kaksi" => "KAHK-see",
      "siellä" => "SEE-el-la",
      "ymmärtää" => "UUM-mar-taa",
      "nimi" => "NEE-mee",
      "lapsi" => "LAHP-see",
      "takaisin" => "TAH-kah-ee-seen",
      "nainen" => "NIGH-nen",
      "uusi" => "OO-see",
      "ajaa" => "AH-yah",
      "ajatella" => "AH-yah-tehl-lah",
      "ystävä" => "UUS-ta-va",
      "tyttö" => "TUUT-tuh",
      "auto" => "OW-toh",
      "elää" => "EH-laa",
      "elämä" => "EH-la-ma",
      "käyttää" => "KAYT-taa",
      "jäädä" => "YAA-da",
      "kirja" => "KEER-yah",
      "kirjasto" => "KEER-yahs-toh",
      "läpi" => "LAP-ee",
      "kulku" => "KOOL-koo",
      "läpikulku" => "LAP-ee-KOOL-koo",
      "alue" => "AH-loo-eh",
      "yksityinen" => "UUK-see-too-yee-nen",
      "yksityisalue" => "UUK-see-too-yees-AH-loo-eh"
    }.freeze

    LETTER_SOUNDS = {
      "a" => "ah", "e" => "eh", "i" => "ee", "o" => "oh", "u" => "oo",
      "y" => "uu", "ä" => "a", "ö" => "uh", "å" => "oh",
      "b" => "b", "c" => "k", "d" => "d", "f" => "f", "g" => "g",
      "h" => "h", "j" => "y", "k" => "k", "l" => "l", "m" => "m",
      "n" => "n", "p" => "p", "q" => "k", "r" => "r", "s" => "s",
      "t" => "t", "v" => "v", "w" => "v", "x" => "ks", "z" => "ts"
    }.freeze

    WORD_RE = /[[:alpha:]ÄÖÅäöå]+(?:-[[:alpha:]ÄÖÅäöå]+)*/

    def self.phonetic(text)
      new.phonetic(text)
    end

    def phonetic(text)
      return "" if text.nil? || text.to_s.strip.empty?

      raw_text = text.to_s.dup
      raw_text.force_encoding("UTF-8")
      clean_text = raw_text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      clean_text.split("/").map(&:strip).reject(&:empty?).map do |part|
        phonetic_phrase(part)
      end.join(" / ")
    end

    private

    def phonetic_phrase(text)
      text.scan(/#{WORD_RE}|[^[:alpha:]ÄÖÅäöå]+/).map do |token|
        token.match?(/\A#{WORD_RE}\z/) ? phonetic_word(token) : token
      end.join.gsub(/\s+([,.;:!?])/, '\\1').gsub(/\s{2,}/, " ").strip
    end

    def phonetic_word(word)
      normalized = normalize_word(word)
      return "" if normalized.empty?
      return OVERRIDES[normalized] if OVERRIDES.key?(normalized)

      syllables = syllabify(normalized).map { |s| pronounce_syllable(s) }
      return "" if syllables.empty?

      syllables[0] = syllables[0].upcase
      syllables.join("-")
    end

    def normalize_word(word)
      raw_word = word.to_s.dup
      raw_word.force_encoding("UTF-8")
      raw_word.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
          .strip.downcase.gsub(/\A[^[:alpha:]ÄÖÅäöå]+|[^[:alpha:]ÄÖÅäöå]+\z/, "")
    end

    def vowel?(char)
      VOWELS.include?(char)
    end

    def consonant?(char)
      char.match?(/[[:alpha:]ÄÖÅäöå]/) && !vowel?(char)
    end

    def split_vowel_group(group)
      return [group] if group.length <= 1
      return [group] if group.chars.uniq.length == 1
      return [group] if DIPHTHONGS.include?(group)

      group.chars
    end

    def expanded_units(word)
      units = []
      i = 0

      while i < word.length
        if vowel?(word[i])
          start = i
          i += 1
          i += 1 while i < word.length && vowel?(word[i])
          split_vowel_group(word[start...i]).each { |unit| units << unit }
        else
          units << word[i]
          i += 1
        end
      end

      units
    end

    def syllabify(word)
      units = expanded_units(word)
      vowel_indexes = units.each_index.select { |i| units[i].chars.any? { |char| vowel?(char) } }
      return [word] if vowel_indexes.length <= 1

      syllables = []
      start = 0

      vowel_indexes.each_cons(2) do |v1, v2|
        cluster_start = v1 + 1
        cluster_end = v2 - 1
        cluster_len = cluster_end >= cluster_start ? cluster_end - cluster_start + 1 : 0

        boundary = if cluster_len <= 0
                     v1
                   elsif cluster_len == 1
                     cluster_start - 1
                   else
                     cluster_end - 1
                   end

        syllables << units[start..boundary].join
        start = boundary + 1
      end

      syllables << units[start..].join
      syllables.reject(&:empty?)
    end

    def vowel_sound(group)
      return LETTER_SOUNDS.fetch(group, group) if group.length == 1
      return vowel_sound(group[0]) if group.chars.uniq.length == 1

      case group
      when "ai", "äi" then "ai"
      when "ei" then "ay"
      when "oi" then "oy"
      when "ui" then "oo-ee"
      when "yi" then "uu-ee"
      when "öi" then "uh-ee"
      when "au" then "ow"
      when "eu" then "eh-oo"
      when "iu" then "ee-oo"
      when "ou" then "oh-oo"
      when "äy" then "ay"
      when "öy" then "uh-ee"
      when "ie" then "ee-eh"
      when "uo" then "oo-oh"
      when "yö" then "uu-uh"
      else group.chars.map { |char| LETTER_SOUNDS.fetch(char, char) }.join
      end
    end

    def pronounce_syllable(syllable)
      out = []
      i = 0

      while i < syllable.length
        char = syllable[i]

        if vowel?(char)
          start = i
          i += 1
          i += 1 while i < syllable.length && vowel?(syllable[i])
          out << vowel_sound(syllable[start...i])
          next
        end

        if i + 1 < syllable.length && syllable[i + 1] == char && consonant?(char)
          out << LETTER_SOUNDS.fetch(char, char) * 2
          i += 2
        else
          out << LETTER_SOUNDS.fetch(char, char)
          i += 1
        end
      end

      out.join.gsub("eeh", "ee").gsub("ohh", "oh").gsub("ooh", "oo")
    end
  end
end

options = {
  yaml: nil,
  output: nil,
  in_place: false,
  force: false,
  field: "prompt",
  key: "phonetics"
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage:
      ruby tools/fi_phonetic.rb "Finnish text"
      ruby tools/fi_phonetic.rb --yaml path.yaml [--output out.yaml]
      ruby tools/fi_phonetic.rb --yaml path.yaml --in-place

    Options:
  BANNER

  opts.on("--yaml PATH", "Read and update a Linguatrain YAML pack") { |v| options[:yaml] = v }
  opts.on("--output PATH", "Write YAML output to PATH") { |v| options[:output] = v }
  opts.on("--in-place", "Write YAML changes back to the input file") { options[:in_place] = true }
  opts.on("--force", "Replace existing phonetics/phonetic values") { options[:force] = true }
  opts.on("--field NAME", "Entry field to phoneticize; default: prompt") { |v| options[:field] = v }
  opts.on("--key NAME", "Output key; default: phonetics") { |v| options[:key] = v }
  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

parser.parse!(ARGV)

def add_entry_phonetics!(entry, options)
  return 0 unless entry.is_a?(Hash)

  updated = 0
  key = options[:key]
  source_value = entry[options[:field]]

  if source_value.is_a?(String) && !source_value.strip.empty?
    if options[:force] || !entry.key?(key) || entry[key].to_s.strip.empty?
      entry[key] = Linguatrain::FinnishPhonetic.phonetic(source_value)
      updated += 1
    end
  end

  # Backward-compatible nested answer shape:
  # answer:
  #   - fi: kaurapuuro
  #     en: oatmeal
  #     phonetic: KOW-rah-poo-roh
  if entry["answer"].is_a?(Array)
    entry["answer"].each do |answer_item|
      next unless answer_item.is_a?(Hash)

      fi = answer_item["fi"]
      next unless fi.is_a?(String) && !fi.strip.empty?

      if options[:force] || !answer_item.key?("phonetic") || answer_item["phonetic"].to_s.strip.empty?
        answer_item["phonetic"] = Linguatrain::FinnishPhonetic.phonetic(fi)
        updated += 1
      end
    end
  end

  updated
end

if options[:yaml]
  path = options[:yaml]

  unless File.exist?(path)
    warn "YAML input not found: #{path}"
    exit 1
  end

  data = YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [], aliases: true)
  unless data.is_a?(Hash) && data["entries"].is_a?(Array)
    warn "YAML root must be a mapping with an entries array"
    exit 1
  end

  updated = data["entries"].sum { |entry| add_entry_phonetics!(entry, options) }
  out_yaml = YAML.dump(data)

  if options[:in_place]
    File.write(path, out_yaml, encoding: "UTF-8")
    warn "Updated #{updated} phonetic field(s) in #{path}"
  elsif options[:output]
    File.write(options[:output], out_yaml, encoding: "UTF-8")
    warn "Updated #{updated} phonetic field(s); wrote #{options[:output]}"
  else
    puts out_yaml
    warn "Would update #{updated} phonetic field(s). Use --in-place or --output to write."
  end

  exit 0
end

text = ARGV.join(" ").strip
if text.empty?
  warn parser.to_s
  exit 1
end

puts Linguatrain::FinnishPhonetic.phonetic(text)
