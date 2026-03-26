#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/fi_phonetic.rb
#

# Goals:
# - learner-readable, non-IPA phonetics
# - stable output for study packs
# - easy YAML integration
#
# Usage:
#   ruby bin/fi_phonetic.rb "Helsingissä"
#   ruby bin/fi_phonetic.rb --yaml packs/fi/some_pack.yml
#   ruby bin/fi_phonetic.rb --yaml packs/fi/some_pack.yml --in-place
#
# Notes:
# - This is intentionally operational learner phonetics, not linguistic IPA.
# - Output conventions are optimized for consistency and readability.

require "optparse"
require "yaml"

module Linguatrain
  class FinnishBestPhonetics
    VOWELS = %w[a e i o u y ä ö å].freeze
    VOWEL_RE = /[aeiouyäöå]/i

    DIPHTHONGS = %w[
      aa ee ii oo uu yy ää öö
      ai ei oi ui yi äi öi
      au eu iu ou
      ey äy öy
      ie uo yö
    ].freeze

    # Two-character vowel mappings first, then single characters.
    PAIR_MAP = {
      "aa" => "ah",
      "ee" => "eh",
      "ii" => "ee",
      "oo" => "oh",
      "uu" => "oo",
      "yy" => "uu",
      "ää" => "ae",
      "öö" => "uh",
      "ai" => "ai",
      "ei" => "ei",
      "oi" => "oi",
      "ui" => "ui",
      "yi" => "ui",
      "äi" => "ai",
      "öi" => "oi",
      "au" => "ow",
      "eu" => "eu",
      "iu" => "iu",
      "ou" => "ou",
      "ey" => "ey",
      "äy" => "ai",
      "öy" => "oi",
      "ie" => "ie",
      "uo" => "uo",
      "yö" => "ue-uh"
    }.freeze

    CHAR_MAP = {
      "a" => "ah",
      "e" => "eh",
      "i" => "ee",
      "o" => "oh",
      "u" => "oo",
      "y" => "ue",
      "ä" => "ae",
      "ö" => "uh",
      "å" => "o",
      "j" => "y",
      "c" => "k",
      "q" => "k",
      "w" => "v",
      "x" => "ks",
      "z" => "ts"
    }.freeze

    CLUSTER_MAP = [
      [/ng/i, "ng"],
      [/nk/i, "nk"],
      [/ks/i, "ks"]
    ].freeze

    def self.phonetic(text)
      new.phonetic(text)
    end

    def phonetic(text)
      return "" if text.nil? || text.to_s.strip.empty?

      alternatives = text.split("/").map(&:strip).reject(&:empty?)
      return "" if alternatives.empty?

      alternatives.map { |part| phonetic_phrase(part) }.join(" / ")
    end

    private

    def phonetic_phrase(text)
      tokens = tokenize(text)

      out = tokens.map do |tok|
        if tok[:type] == :word
          word_to_phonetic(tok[:value])
        else
          tok[:value]
        end
      end

      out.join
         .gsub(/\s+([,.;:!?])/, '\1')
         .gsub(/([(\[])\s+/, '\1')
         .gsub(/\s+([)\]])/, '\1')
         .gsub(/\s{2,}/, " ")
         .strip
    end

    def tokenize(text)
      parts = text.scan(/[A-Za-zÄÖÅäöå]+|[^A-Za-zÄÖÅäöå]+/)
      parts.map do |part|
        if part.match?(/\A[A-Za-zÄÖÅäöå]+\z/)
          { type: :word, value: part }
        else
          { type: :other, value: part }
        end
      end
    end

    def word_to_phonetic(word)
      w = word.dup
      CLUSTER_MAP.each { |re, rep| w.gsub!(re, rep) }

      syllables = syllabify(w)
      return map_chunk(w).upcase if syllables.empty?

      phon_sylls = syllables.map { |syllable| map_chunk(syllable) }
      phon_sylls[0] = phon_sylls[0].upcase if phon_sylls[0]
      phon_sylls.join("-")
    end

    # Finnish-friendly syllabification:
    # - find onset
    # - consume nucleus including long vowels and known diphthongs
    # - between nuclei:
    #   - 0 consonants => hiatus split
    #   - 1 consonant => consonant starts next syllable
    #   - 2+ consonants => first closes previous, rest start next
    def syllabify(word)
      w = word.downcase
      return [w] unless w.match?(VOWEL_RE)

      chars = w.chars
      syllables = []
      i = 0

      while i < chars.length
        syllable = +""

        while i < chars.length && !vowel?(chars[i])
          syllable << chars[i]
          i += 1
        end

        if i < chars.length && vowel?(chars[i])
          syllable << chars[i]
          i += 1

          while i < chars.length && vowel?(chars[i])
            prev = syllable[-1]
            pair = "#{prev}#{chars[i]}"

            if prev == chars[i] || diphthong?(pair)
              syllable << chars[i]
              i += 1
            else
              break
            end
          end
        end

        break if syllable.empty?

        cons_start = i
        while i < chars.length && !vowel?(chars[i])
          i += 1
        end
        cons_cluster = chars[cons_start...i].join

        if i >= chars.length
          syllable << cons_cluster
          syllables << syllable
          break
        end

        if cons_cluster.empty?
          syllables << syllable
        elsif cons_cluster.length == 1
          syllables << syllable
          i = cons_start
        else
          syllable << cons_cluster[0]
          syllables << syllable
          i = cons_start + 1
        end
      end

      syllables.reject(&:empty?)
    end

    def map_chunk(chunk)
      s = chunk.downcase.gsub("-", "")
      out = +""
      i = 0

      while i < s.length
        two = s[i, 2]
        one = s[i, 1]

        if two && PAIR_MAP.key?(two)
          out << PAIR_MAP[two]
          i += 2
          next
        end

        out << (CHAR_MAP[one] || one)
        i += 1
      end

      out
    end

    def diphthong?(pair)
      DIPHTHONGS.include?(pair)
    end

    def vowel?(ch)
      VOWELS.include?(ch)
    end
  end
end

options = {
  yaml: nil,
  in_place: false,
  force: false
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage:
      ruby bin/fi_phonetic_best.rb "Finnish text"
      ruby bin/fi_phonetic_best.rb --yaml path.yml [--in-place]
  BANNER

  opts.on("--yaml PATH", "Update YAML pack entries in PATH") do |v|
    options[:yaml] = v
  end

  opts.on("--in-place", "Write YAML changes back to file (otherwise print to STDOUT)") do
    options[:in_place] = true
  end

  opts.on("--force", "Replace existing phonetic values instead of only filling blanks") do
    options[:force] = true
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

parser.parse!(ARGV)

def update_entry_phonetic!(entry, force: false)
  updated = 0

  # Newer simple pack shape:
  # answer:
  #   - "Hei"
  # phonetic: "HEI"
  if entry["answer"].is_a?(Array) && entry["phonetic"].to_s.strip.empty? || force
    answers = entry["answer"]
    first_string = answers.find { |item| item.is_a?(String) && !item.strip.empty? }
    if first_string
      if force || !entry.key?("phonetic") || entry["phonetic"].to_s.strip.empty?
        entry["phonetic"] = Linguatrain::FinnishBestPhonetics.phonetic(first_string)
        updated += 1
      end
    end
  end

  # Older nested answer object shape:
  # answer:
  #   - fi: "kaurapuuro"
  #     en: "oatmeal"
  #     phonetic: "KAU-ra-puu-ro"
  if entry["answer"].is_a?(Array)
    entry["answer"].each do |ans|
      next unless ans.is_a?(Hash)

      fi = ans["fi"]
      next unless fi.is_a?(String) && !fi.strip.empty?

      if force || !ans.key?("phonetic") || ans["phonetic"].to_s.strip.empty?
        ans["phonetic"] = Linguatrain::FinnishBestPhonetics.phonetic(fi)
        updated += 1
      end
    end
  end

  updated
end

if options[:yaml]
  path = options[:yaml]
  data = YAML.safe_load(File.read(path), permitted_classes: [], aliases: true)

  unless data.is_a?(Hash)
    warn "YAML root must be a mapping (Hash)"
    exit 1
  end

  entries = data["entries"]
  unless entries.is_a?(Array)
    warn "YAML file must contain an entries array"
    exit 1
  end

  updated = 0
  entries.each do |entry|
    next unless entry.is_a?(Hash)
    updated += update_entry_phonetic!(entry, force: options[:force])
  end

  out_yaml = YAML.dump(data)

  if options[:in_place]
    File.write(path, out_yaml)
    warn "Updated #{updated} phonetic field(s) in #{path}"
  else
    puts out_yaml
    warn "Would update #{updated} phonetic field(s) (use --in-place to write)"
  end
  exit 0
end

text = ARGV.join(" ").strip
if text.empty?
  warn parser.to_s
  exit 1
end

puts Linguatrain::FinnishBestPhonetics.phonetic(text)
