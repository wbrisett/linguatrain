# frozen_string_literal: true

module Linguatrain
  module Translation
    class Scorer
      def score(answer, entry)
        answer_words = normalize(answer).split
        claimed_positions = {}

        prepared = chunks_for(entry).map do |chunk|
          targets = Array(chunk["targets"] || chunk[:targets]).dup
          target = chunk["target"] || chunk[:target]
          literal = chunk["literal"] || chunk[:literal]
          targets << target unless target.to_s.strip.empty?
          targets << literal unless literal.to_s.strip.empty?
          targets = targets.map { |value| value.to_s.strip }.reject(&:empty?).uniq

          { chunk: chunk, targets: targets }
        end

        matches = Array.new(prepared.length)

        # Exact matches have first claim on answer words. This prevents a later
        # fuzzy match from reusing text that already completed another chunk.
        prepared.each_with_index do |item, index|
          exact = find_exact_match(answer_words, item[:targets], claimed_positions)
          next unless exact

          claim_range!(claimed_positions, exact[:start], exact[:length])
          matches[index] = result_for(item, matched_target: exact[:target])
        end

        prepared.each_with_index do |item, index|
          next if matches[index]

          near = best_near_match(answer_words, item[:targets], claimed_positions)
          if near
            claim_range!(claimed_positions, near[:start], near[:length])
            matches[index] = result_for(item, near_match: near)
          else
            matches[index] = result_for(item)
          end
        end

        correct = matches.count { |match| match[:matched] }

        {
          total: matches.length,
          correct: correct,
          missed: matches.reject { |match| match[:matched] },
          matches: matches,
          entry: entry
        }
      end

      private

      def chunks_for(entry)
        chunks = entry["chunks"] || entry[:chunks]
        return chunks if chunks && !chunks.empty?

        source = entry["source"] || entry[:source]
        target = entry["target"] || entry[:target]
        literal = entry["literal"] || entry[:literal]

        fallback = {
          "source" => source,
          "targets" => [target, literal].map { |value| value.to_s.strip }.reject(&:empty?).uniq
        }

        hint = entry["hint"] || entry[:hint]
        fallback["hint"] = hint unless hint.to_s.strip.empty?

        [fallback]
      end

      def normalize(text)
        text.to_s
            .downcase
            .gsub(/[[:punct:]]/, " ")
            .gsub(/\s+/, " ")
            .strip
      end

      def phrase_matches?(normalized_answer, normalized_target)
        answer_words = normalized_answer.split
        target_words = normalized_target.split

        return false if answer_words.empty? || target_words.empty?
        return answer_words == target_words if answer_words.length == target_words.length
        return false if target_words.length > answer_words.length

        answer_words.each_cons(target_words.length).any? do |window|
          window == target_words
        end
      end

      def find_exact_match(answer_words, targets, claimed_positions)
        Array(targets).each do |target|
          expected_words = normalize(target).split
          next if expected_words.empty? || answer_words.length < expected_words.length

          answer_words.each_cons(expected_words.length).with_index do |window, start|
            next unless window == expected_words
            next unless range_available?(claimed_positions, start, expected_words.length)

            return { target: target, start: start, length: expected_words.length }
          end
        end

        nil
      end

      # Identify an attempted chunk without silently accepting it. A near match
      # must preserve the phrase shape and at least one exact anchor word. It may
      # contain one differing form, or two independent one-letter misspellings.
      # This remains deliberately stricter than general fuzzy sentence matching.
      def best_near_match(answer_words, targets, claimed_positions = {})
        return nil if answer_words.empty?

        candidates = Array(targets).flat_map do |target|
          expected_words = normalize(target).split
          next [] if expected_words.length < 2 || answer_words.length < expected_words.length

          answer_words.each_cons(expected_words.length).filter_map.with_index do |window, start|
            next unless range_available?(claimed_positions, start, expected_words.length)

            differences = window.zip(expected_words).filter_map.with_index do |(actual, expected), index|
              next if actual == expected

              {
                index: index,
                actual: actual,
                expected: expected,
                distance: edit_distance(actual, expected)
              }
            end

            exact_words = expected_words.length - differences.length
            next if differences.empty? || exact_words < 1

            plausible =
              if differences.length == 1
                expected_words.length >= 3 || differences.first[:distance] <= 3
              elsif differences.length == 2
                expected_words.length >= 3 && differences.all? { |difference| difference[:distance] == 1 }
              else
                false
              end
            next unless plausible

            total_distance = differences.sum { |difference| difference[:distance] }

            {
              actual: window.join(" "),
              expected: target,
              corrections: differences,
              distance: total_distance,
              start: start,
              length: expected_words.length
            }
          end
        end

        candidates.min_by { |candidate| candidate[:distance] }
      end

      def result_for(item, matched_target: nil, near_match: nil)
        chunk = item[:chunk]
        result = {
          source: chunk["source"] || chunk[:source],
          targets: item[:targets],
          matched: !matched_target.nil?,
          matched_text: matched_target,
          status: matched_target ? :correct : (near_match ? :near : :missing)
        }

        if near_match
          result[:near_text] = near_match[:actual]
          result[:expected_text] = near_match[:expected]
          result[:corrections] = near_match[:corrections]
        end

        chunk_id = chunk["id"] || chunk[:id]
        chunk_hint = chunk["hint"] || chunk[:hint]
        chunk_guidance = chunk["guidance"] || chunk[:guidance]
        result[:id] = chunk_id unless chunk_id.to_s.strip.empty?
        result[:hint] = chunk_hint unless chunk_hint.to_s.strip.empty?
        result[:guidance] = chunk_guidance if chunk_guidance.is_a?(Hash)
        result
      end

      def range_available?(claimed_positions, start, length)
        (start...(start + length)).none? { |position| claimed_positions[position] }
      end

      def claim_range!(claimed_positions, start, length)
        (start...(start + length)).each { |position| claimed_positions[position] = true }
      end

      def edit_distance(left, right)
        previous = (0..right.length).to_a

        left.each_char.with_index(1) do |left_char, row|
          current = [row]
          right.each_char.with_index(1) do |right_char, column|
            substitution = previous[column - 1] + (left_char == right_char ? 0 : 1)
            insertion = current[column - 1] + 1
            deletion = previous[column] + 1
            current << [substitution, insertion, deletion].min
          end
          previous = current
        end

        previous.last
      end
    end
  end
end
