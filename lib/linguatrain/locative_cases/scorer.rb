# frozen_string_literal: true

module Linguatrain
  module LocativeCases
    class Scorer
      def score(answer, item)
        normalized_answer = normalize(answer)
        expected = Array(item[:answers] || item["answers"])
        matched_answer = expected.find { |candidate| normalize(candidate) == normalized_answer }

        {
          correct: !matched_answer.nil?,
          matched_answer: matched_answer,
          expected: expected
        }
      end

      private

      def normalize(value)
        value.to_s
          .unicode_normalize(:nfc)
          .downcase
          .gsub(/[[:punct:]]/, " ")
          .gsub(/\s+/, " ")
          .strip
      end
    end
  end
end
