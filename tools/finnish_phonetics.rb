# frozen_string_literal: true

module FinnishPhonetics
  module_function

  VOWELS = %w[a e i o u y ä ö].freeze
  DIPHTHONGS = %w[
    ai ei oi ui yi äi öi
    au eu iu ou
    ey äy öy
    ie uo yö
  ].freeze

  def render(text)
    return "" if text.nil? || text.strip.empty?

    parts = text.split("/").map(&:strip)
    parts.map { |part| render_phrase(part) }.join(" / ")
  end

  def render_phrase(phrase)
    phrase.split(/\s+/).map { |token| render_token(token) }.join(" ")
  end

  def render_token(token)
    clean = token.strip
    return clean if clean.empty?

    leading = clean[/\A[^\p{L}]*/] || ""
    trailing = clean[/[^\p{L}]*\z/] || ""
    core = clean.gsub(/\A[^\p{L}]*/, "").gsub(/[^\p{L}]*\z/, "")

    return token if core.empty?

    "#{leading}#{render_word(core.downcase)}#{trailing}"
  end

  def render_word(word)
    syllables = syllabify(word)
    return map_chunk(word).upcase if syllables.empty?

    syllables.each_with_index.map do |syl, idx|
      mapped = map_chunk(syl)
      idx.zero? ? mapped.upcase : mapped.downcase
    end.join("-")
  end

  def syllabify(word)
    chars = word.chars
    chunks = []
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

      consonants = +""
      j = i
      while j < chars.length && !vowel?(chars[j])
        consonants << chars[j]
        j += 1
      end

      if j >= chars.length
        syllable << consonants
        i = j
        chunks << syllable unless syllable.empty?
        break
      end

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

  def map_chunk(chunk)
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
      "eu" => "eu",
      "iu" => "iu",
      "ou" => "ou",
      "ey" => "ey",
      "äy" => "ai",
      "öy" => "oi",
      "ie" => "ie",
      "uo" => "uo",
      "yö" => "yö"
    }

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

    out
  end
end