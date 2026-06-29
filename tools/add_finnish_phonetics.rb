#!/usr/bin/env ruby
# frozen_string_literal: true
# add_finnish_phonetics.rb
#
# Adds beginner-friendly Finnish pronunciation hints to a Linguatrain YAML pack.
# This intentionally does NOT use IPA. It produces approximations like:
#   olla      -> OHL-lah
#   kirja     -> KEER-yah
#   kirjasto  -> KEER-yahs-toh
#   läpikulku -> LAP-ee-KOOL-koo
#
# Usage:
#   ruby add_finnish_phonetics.rb INPUT.yaml [OUTPUT.yaml]
#
# Notes:
# - Finnish stress is normally on the first syllable, so the first syllable is uppercased.
# - This is a practical learner aid, not a linguistic transcription.
# - Add hand corrections to OVERRIDES as Linguatrain grows.

require "yaml"
require "optparse"

VOWELS = "aeiouyäö".chars.freeze
BACK_VOWELS = "aou".chars.freeze
FRONT_VOWELS = "äöy".chars.freeze
NEUTRAL_VOWELS = "ei".chars.freeze

# Common Finnish diphthongs. Long vowels are handled separately.
DIPHTHONGS = %w[
  ai ei oi ui yi äi öi
  au eu iu ou äy öy ey
  ie uo yö
].freeze

# Hand-tuned overrides. Keep this small and explicit.
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
  "yksityinen" => "UUK-see-too-yee-nen"
}.freeze

LETTER_SOUNDS = {
  "a" => "ah",
  "e" => "eh",
  "i" => "ee",
  "o" => "oh",
  "u" => "oo",
  "y" => "uu",
  "ä" => "a",
  "ö" => "uh",
  "b" => "b",
  "c" => "k",
  "d" => "d",
  "f" => "f",
  "g" => "g",
  "h" => "h",
  "j" => "y",
  "k" => "k",
  "l" => "l",
  "m" => "m",
  "n" => "n",
  "p" => "p",
  "q" => "k",
  "r" => "r",
  "s" => "s",
  "t" => "t",
  "v" => "v",
  "w" => "v",
  "x" => "ks",
  "z" => "ts",
  "å" => "oh"
}.freeze

def vowel?(char)
  VOWELS.include?(char)
end

def consonant?(char)
  char.match?(/[[:alpha:]]/) && !vowel?(char)
end

def normalize_word(word)
  word.to_s.strip.downcase.gsub(/[[:punct:]]+\z/, "")
end

def vowel_groups(word)
  groups = []
  i = 0

  while i < word.length
    if vowel?(word[i])
      start = i
      i += 1
      i += 1 while i < word.length && vowel?(word[i])
      groups << [start, i - 1]
    else
      i += 1
    end
  end

  groups
end

def split_vowel_group(group)
  return [group] if group.length <= 1
  return [group] if group.chars.uniq.length == 1 # long vowel: aa, ää, ii, etc.
  return [group] if DIPHTHONGS.include?(group)

  # Otherwise split the sequence into separate syllable nuclei.
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
  return [word] if vowel_indexes.empty?
  return [word] if vowel_indexes.length == 1

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
                 # Keep the final consonant with the next syllable.
                 cluster_end - 1
               end

    syllables << units[start..boundary].join
    start = boundary + 1
  end

  syllables << units[start..].join
  syllables.reject(&:empty?)
end

def sound_for_vowel_group(group)
  return "ah" if group == "a"
  return "eh" if group == "e"
  return "ee" if group == "i"
  return "oh" if group == "o"
  return "oo" if group == "u"
  return "uu" if group == "y"
  return "a" if group == "ä"
  return "uh" if group == "ö"

  # Long vowels.
  return sound_for_vowel_group(group[0]) if group.chars.uniq.length == 1

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
  else
    group.chars.map { |char| LETTER_SOUNDS.fetch(char, char) }.join
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
      out << sound_for_vowel_group(syllable[start...i])
      next
    end

    # Double consonants are learner-useful; keep them visible but not ridiculous.
    if i + 1 < syllable.length && syllable[i + 1] == char && consonant?(char)
      out << LETTER_SOUNDS.fetch(char, char) * 2
      i += 2
    else
      out << LETTER_SOUNDS.fetch(char, char)
      i += 1
    end
  end

  spoken = out.join

  # A few readability cleanups for English-speaker hints.
  spoken
    .gsub("eeh", "ee")
    .gsub("ohh", "oh")
    .gsub("ooh", "oo")
    .gsub("ahl", "ahl")
end

def beginner_phonetics(word)
  normalized = normalize_word(word)
  return "" if normalized.empty?
  return OVERRIDES[normalized] if OVERRIDES.key?(normalized)

  syllables = syllabify(normalized).map { |s| pronounce_syllable(s) }
  return "" if syllables.empty?

  syllables[0] = syllables[0].upcase
  syllables.join("-")
end

def add_phonetics_to_pack(input_path, output_path, replace: true)
  pack = YAML.load_file(input_path)
  entries = Array(pack["entries"])

  entries.each do |entry|
    next unless entry.is_a?(Hash)

    prompt = entry["prompt"]
    next if prompt.to_s.strip.empty?
    next if entry.key?("phonetics") && !replace

    entry["phonetics"] = beginner_phonetics(prompt)
  end

  File.write(output_path, YAML.dump(pack))
end

options = {
  replace: true
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby add_finnish_phonetics.rb INPUT.yaml [OUTPUT.yaml] [options]"

  opts.on("--keep-existing", "Do not replace entries that already have phonetics") do
    options[:replace] = false
  end
end.parse!

if ARGV.length < 1 || ARGV.length > 2
  warn "Usage: ruby add_finnish_phonetics.rb INPUT.yaml [OUTPUT.yaml] [--keep-existing]"
  exit 1
end

input_path = ARGV[0]
output_path = ARGV[1]

unless File.exist?(input_path)
  warn "Input YAML not found: #{input_path}"
  exit 1
end

unless output_path
  base = File.basename(input_path, File.extname(input_path))
  output_path = File.join(File.dirname(input_path), "#{base}_beginner_phonetics.yaml")
end

add_phonetics_to_pack(input_path, output_path, replace: options[:replace])
puts "Wrote #{output_path}"
