#!/usr/bin/env ruby
# frozen_string_literal: true

# bin/fi_phonetic.rb
#
# Learner phonetics generator for Finnish (non-IPA).
# - Syllable chunking with a practical Finnish heuristic
# - Capitalize first syllable for stress
# - ä -> ae, ö -> uh, y -> ue
#
# Usage:
#   ruby bin/fi_phonetic.rb "Helsingissä"
#   ruby bin/fi_phonetic.rb --yaml packs/fi/some_pack.yml --in-place
#
# Notes:
# - This is intentionally "operational" learner phonetics, not linguistic IPA.
# - Syllabification is heuristic but works well for typical beginner vocab/phrases.

require "optparse"
require "yaml"

module Linguatrain
  class FinnishLearnerPhonetics
    VOWELS = %w[a e i o u y ä ö å].freeze
    VOWEL_RE = /[aeiouyäöå]/i

    # Basic transliteration for learner readability.
    # Keep Finnish consonants as-is (mostly) but map:
    #   ä -> ae, ö -> uh, y -> ue
    #
    # Also: j is often clearer as "y" for English learners.
    CHAR_MAP = {
      "ä" => "ae",
      "ö" => "uh",
      "y" => "ue",
      "å" => "o",
      "j" => "y"
    }.freeze

    # Some small "learner-friendly" cluster tweaks (optional, conservative).
    # You can add more as you standardize.
    CLUSTER_MAP = [
      # maksaa: mak-saa often feels clearer as "mahk-saa" to learners
      # (this mirrors your earlier MAHK-sah style, without forcing 'ah' vowels)
      [/ks/i, "hk-s"]
    ].freeze

    def self.phonetic(text)
      new.phonetic(text)
    end

    def phonetic(text)
      tokens = tokenize(text)

      out = tokens.map do |tok|
        if tok[:type] == :word
          word_to_phonetic(tok[:value])
        else
          tok[:value]
        end
      end

      # Normalize whitespace around punctuation a bit
      out.join
         .gsub(/\s+([,.;:!?])/, '\1')
         .gsub(/([(\[])\s+/, '\1')
         .gsub(/\s+([)\]])/, '\1')
         .gsub(/\s{2,}/, " ")
         .strip
    end

    private

    def tokenize(text)
      # Split into "word" vs "non-word" so we preserve punctuation and spacing.
      # Words include Finnish letters.
      parts = text.scan(/[A-Za-zÄÖÅäöå]+|[^A-Za-zÄÖÅäöå]+/)
      parts.map do |p|
        if p.match?(/\A[A-Za-zÄÖÅäöå]+\z/)
          { type: :word, value: p }
        else
          { type: :other, value: p }
        end
      end
    end

    def word_to_phonetic(word)
      w = word.dup

      # Apply conservative cluster tweaks first (on the original spelling)
      CLUSTER_MAP.each { |re, rep| w.gsub!(re, rep) }

      # Syllabify using the *original* letters (including ä/ö/y) where possible,
      # but be resilient to inserted hyphens from cluster tweaks.
      syllables = syllabify(w)

      # Transliterate each syllable to learner representation
      phon_sylls = syllables.map { |sy| transliterate(sy) }

      # Capitalize first syllable to reinforce Finnish stress pattern
      phon_sylls[0] = phon_sylls[0].upcase if phon_sylls[0]

      phon_sylls.join("-")
    end

    def transliterate(syllable)
      s = syllable.downcase

      # If our cluster tweaks inserted hyphens, preserve them as syllable breaks
      # but keep consistent output (we re-join with "-")
      s = s.gsub("-", "")

      # Character-by-character map with fallback to original
      out = +""
      s.each_char do |ch|
        out << (CHAR_MAP[ch] || ch)
      end
      out
    end

    # Practical Finnish syllabification heuristic:
    # - Syllable nucleus is a vowel group (including double vowels)
    # - Between vowel groups:
    #   - 0 consonants: split between vowels
    #   - 1 consonant: consonant attaches to next syllable (boundary before it)
    #   - 2+ consonants: first consonant closes previous syllable, rest start next
    #
    # This handles most learner-level Finnish well.
    def syllabify(word)
      w = word.downcase

      # If the token has no vowels, return as a single "syllable"
      return [w] unless w.match?(VOWEL_RE)

      sylls = []
      i = 0
      n = w.length

      while i < n
        # Onset: consume leading consonants until first vowel
        onset_start = i
        i += 1 while i < n && !vowel?(w[i])
        onset = w[onset_start...i]

        # Nucleus: consume one or more vowels (vowel group)
        nucleus_start = i
        i += 1 while i < n && vowel?(w[i])
        nucleus = w[nucleus_start...i]

        # If we reached end, finalize
        if i >= n
          sylls << (onset + nucleus)
          break
        end

        # Look ahead: consonant cluster until next vowel
        cons_start = i
        i += 1 while i < n && !vowel?(w[i])
        cons_cluster = w[cons_start...i]

        # If no more vowels after this cluster, it all belongs to the last syllable
        if i >= n
          sylls << (onset + nucleus + cons_cluster)
          break
        end

        # There is another vowel later: decide boundary
        if cons_cluster.empty?
          # hiatus: split between vowels
          sylls << (onset + nucleus)
          # next loop begins at current i (which is at a vowel)
        elsif cons_cluster.length == 1
          # single consonant goes with next syllable
          sylls << (onset + nucleus)
          i = cons_start # rewind so consonant becomes onset of next syllable
        else
          # split cluster: first consonant closes previous
          sylls << (onset + nucleus + cons_cluster[0])
          i = cons_start + 1 # remaining consonants become onset
        end
      end

      sylls
    end

    def vowel?(ch)
      VOWELS.include?(ch)
    end
  end
end

# ---- CLI / YAML integration ----

options = {
  yaml: nil,
  in_place: false
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage:\n  ruby bin/fi_phonetic.rb \"Finnish text\"\n  ruby bin/fi_phonetic.rb --yaml path.yml [--in-place]\n"

  opts.on("--yaml PATH", "Update YAML pack entries in PATH (adds phonetic fields where missing)") do |v|
    options[:yaml] = v
  end

  opts.on("--in-place", "Write YAML changes back to file (otherwise print to STDOUT)") do
    options[:in_place] = true
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

parser.parse!(ARGV)

if options[:yaml]
  path = options[:yaml]
  data = YAML.safe_load(File.read(path), permitted_classes: [], aliases: true)

  entries = data["entries"] || []
  updated = 0

  entries.each do |entry|
    answers = entry["answer"]
    next unless answers.is_a?(Array)

    answers.each do |ans|
      next unless ans.is_a?(Hash)
      fi = ans["fi"]
      next unless fi.is_a?(String) && !fi.strip.empty?

      # Only add if missing/blank
      if !ans.key?("phonetic") || ans["phonetic"].to_s.strip.empty?
        ans["phonetic"] = Linguatrain::FinnishLearnerPhonetics.phonetic(fi)
        updated += 1
      end
    end
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

# Text mode
text = ARGV.join(" ").strip
if text.empty?
  warn parser.to_s
  exit 1
end

puts Linguatrain::FinnishLearnerPhonetics.phonetic(text)