# frozen_string_literal: true

module Linguatrain
  module Translation
    class Scorer
      def score(answer, entry)
        normalized_answer = normalize(answer)

        matches = chunks_for(entry).map do |chunk|
          targets = chunk.fetch("targets", [])

          matched_target = targets.find do |target|
            phrase_matches?(normalized_answer, normalize(target))
          end

          result = {
            source: chunk.fetch("source"),
            targets: targets,
            matched: !matched_target.nil?,
            matched_text: matched_target
          }

          chunk_id = chunk["id"] || chunk[:id]
          chunk_hint = chunk["hint"] || chunk[:hint]

          result[:id] = chunk_id unless chunk_id.to_s.strip.empty?
          result[:hint] = chunk_hint unless chunk_hint.to_s.strip.empty?

          result
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
        entry.fetch("chunks") do
          [
            begin
              fallback = {
                "source" => entry.fetch("source"),
                "targets" => [entry.fetch("target")]
              }

              hint = entry["hint"] || entry[:hint]
              fallback["hint"] = hint unless hint.to_s.strip.empty?

              fallback
            end
          ]
        end
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
    end
  end
end