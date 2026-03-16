# frozen_string_literal: true

module Linguatrain
  module FinnishPhonetics
    module_function

    VOWELS = %w[a e i o u y ä ö].freeze
    DIPHTHONGS = %w[
      ai ei oi ui yi äi öi
      au eu iu ou
      ey äy öy
      ie uo yö
    ].freeze

    # Main entry point
    #
    # Examples:
    #   FinnishPhonetics.render("koira")
    #   # => "KOI-rah"
    #
    #   FinnishPhonetics.render("lentokone")
    #   # => "LEN-toh-koh-neh"
    #
    #   FinnishPhonetics.render("ystävä")
    #   # => "UUS-tah-vah"
    #
    #   FinnishPhonetics.render("rautatieasema/juna-asema")
    #   # => "ROW-tah-tee-ah-seh-mah / YOO-nah-ah-seh-mah"
    #
    def render(text)
      return "" if text.nil? || text.strip.empty?

      parts = text.split("/").map(&:strip)
      parts.map { |part| render_phrase(part) }.join(" / ")
    end

    def render_phrase(phrase)
      tokens = phrase.split(/\s+/)
      tokens.map { |token| render_token(token) }.join(" ")
    end

    def render_token(token)
      clean = token.strip
      return clean if clean.empty?

      leading = clean[/\A[^\p{L}]*/] || ""
      trailing = clean[/[^\p{L}]*\z/] || ""
      core = clean.gsub(/\A[^\p{L}]*/, "").gsub(/[^\p{L}]*\z/, "")

      return token if core.empty?

      phon = render_word(core.downcase)
      "#{leading}#{phon}#{trailing}"
    end

    def render_word(word)
      syllables = syllabify(word)
      return map_chunk(word).upcase if syllables.empty?

      syllables.each_with_index.map { |syl, idx|
        mapped = map_chunk(syl)
        idx.zero? ? mapped.upcase : mapped.downcase
      }.join("-")
    end

    # Very lightweight Finnish syllabification:
    # - preserve common diphthongs
    # - split before final consonant of an intervocalic consonant cluster
    # - first syllable stressed later via uppercase
    def syllabify(word)
      chars = word.chars
      chunks = []
      i = 0

      while i < chars.length
        syllable = +""

        # onset consonants
        while i < chars.length && !vowel?(chars[i])
          syllable << chars[i]
          i += 1
        end

        # vowel nucleus (with long vowels / diphthongs)
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

        # gather consonants between vowel groups
        consonants = +""
        j = i
        while j < chars.length && !vowel?(chars[j])
          consonants << chars[j]
          j += 1
        end

        # If end of word, absorb remaining consonants
        if j >= chars.length
          syllable << consonants
          i = j
          chunks << syllable unless syllable.empty?
          break
        end

        # If there are consonants before next vowel:
        # CV -> next syllable gets consonant
        # VCCV -> first consonant closes current syllable, rest move on
        if consonants.length >= 2
          syllable << consonants[0]
          i += 1
        end

        chunks << syllable unless syllable.empty?
      end

      chunks.reject(&:empty?)
    end

    def vowel?(char)
      VOWELS.include?(char)
    end

    def diphthong?(pair)
      DIPHTHONGS.include?(pair)
    end

    # Maps Finnish spelling to learner-friendly approximations.
    #
    # Style goals:
    # - readable for an English speaker
    # - stable and predictable
    # - not IPA
    #
    # Notes:
    # - ä -> ah
    # - ö -> uh
    # - y -> uu
    # - j -> y
    # - double vowels preserved by output flavor where practical
    #
    def map_chunk(chunk)
      s = chunk.dup

      # Order matters here
      s.gsub!("ng", "ng")
      s.gsub!("nk", "nk")
      s.gsub!("nj", "ny")

      # Finnish j is English y
      s.gsub!("j", "y")

      # Common letter mappings
      s.gsub!("a", "ah")
      s.gsub!("e", "eh")
      s.gsub!("i", "ee")
      s.gsub!("o", "oh")
      s.gsub!("u", "oo")
      s.gsub!("y", "uu")
      s.gsub!("ä", "ah")
      s.gsub!("ö", "uh")

      # Common long vowels and diphthongs override simpler mapping
      overrides = {
        "aa" => "ah",
        "ee" => "eh",
        "ii" => "ee",
        "oo" => "oh",
        "uu" => "oo",
        "yy" => "uu",
        "ää" => "ah",
        "öö" => "uh",

        "ai" => "ai",
        "ei" => "ei",
        "oi" => "oi",
        "ui" => "ui",
        "yi" => "ui",
        "äi" => "ai",
        "öi" => "oi",

        "au" => "ow",
        "eu" => "eh-oo",
        "iu" => "ee-oo",
        "ou" => "oh-oo",

        "ey" => "ey",
        "äy" => "ai",
        "öy" => "oi",

        "ie" => "ee-eh",
        "uo" => "oo-oh",
        "yö" => "uu-uh"
      }

      # Rebuild from original chunk so overrides are reliable
      rebuild_with_overrides(chunk, overrides)
    end

    def rebuild_with_overrides(chunk, overrides)
      out = +""
      i = 0

      while i < chunk.length
        two = chunk[i, 2]
        one = chunk[i, 1]

        if two && overrides.key?(two)
          out << overrides[two]
          i += 2
          next
        end

        out << case one
        when "a" then "ah"
        when "e" then "eh"
        when "i" then "ee"
        when "o" then "oh"
        when "u" then "oo"
        when "y" then "uu"
        when "ä" then "ah"
        when "ö" then "uh"
        when "j" then "y"
        else one
        end

        i += 1
      end

      compact_output(out)
    end

    def compact_output(text)
      text
        .gsub("eh-oo", "eu")
        .gsub("ee-oo", "iu")
        .gsub("ee-eh", "ie")
        .gsub("oo-oh", "uo")
        .gsub("uu-uh", "yö")
    end
  end
end