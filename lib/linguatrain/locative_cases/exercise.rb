# frozen_string_literal: true

require_relative "scorer"

module Linguatrain
  module LocativeCases
    class Exercise
      HELP_WORDS = %w[h hint help].freeze
      ANSWER_WORDS = %w[r reveal].freeze
      QUIT_WORDS = %w[q quit].freeze

      def self.run(items, input: $stdin, output: $stdout)
        new(items, input: input, output: output).run
      end

      def initialize(items, input:, output:)
        @items = Array(items)
        @input = input
        @output = output
        @scorer = Scorer.new
        @stats = { total: 0, correct_first: 0, correct_retry: 0, revealed: 0 }
        @missed = []
        @quit = false
      end

      def run
        output.puts
        output.puts "Locative Cases — #{items.length} question(s)"
        output.puts "Produce the complete Finnish sentence."

        items.each_with_index do |item, index|
          break if quit?

          stats[:total] += 1
          run_item(item, index + 1, items.length)
        end

        [stats, missed]
      end

      private

      attr_reader :items, :input, :output, :scorer, :stats, :missed

      def run_item(item, index, total)
        attempts = 0
        hint_index = 0

        display_prompt(item, index, total)

        loop do
          answer = read_answer
          return if quit?

          normalized_command = answer.downcase.strip
          if HELP_WORDS.include?(normalized_command) || answer.strip.empty?
            hint_index = display_next_hint(item, hint_index)
            next
          end

          if ANSWER_WORDS.include?(normalized_command)
            reveal_answer(item)
            return
          end

          attempts += 1
          result = scorer.score(answer, item)

          if result[:correct]
            record_correct(attempts)
            display_correct(item)
            return
          end

          if attempts == 1
            output.puts "Try again. Produce the complete Finnish sentence."
            output.print "> "
          elsif hint_index < hints_for(item).length
            hint_index = display_next_hint(item, hint_index)
          else
            reveal_answer(item)
            return
          end
        end
      end

      def display_prompt(item, index, total)
        output.puts
        output.puts "-" * 50
        output.puts "[#{index}/#{total}]"
        output.puts
        output.puts "Location: #{item[:lemma]}"
        output.puts
        output.puts item[:prompt]
        output.puts
        output.print "> "
      end

      def read_answer
        raw = input.gets
        if raw.nil?
          @quit = true
          return ""
        end

        answer = raw.chomp
        @quit = true if QUIT_WORDS.include?(answer.downcase.strip)
        answer
      end

      def hints_for(item)
        [
          "Ask yourself: #{item[:question]}?",
          "Use the #{item[:family]} family (#{item[:family_code]}), #{item[:case]}.",
          "The target form is #{item[:target_form]}."
        ]
      end

      def display_next_hint(item, hint_index)
        hints = hints_for(item)

        if hint_index < hints.length
          output.puts "Hint: #{hints[hint_index]}"
          output.print "> "
          hint_index + 1
        else
          output.puts "No more hints. Type 'r' to reveal the answer, or try again."
          output.print "> "
          hint_index
        end
      end

      def record_correct(attempts)
        if attempts == 1
          stats[:correct_first] += 1
        else
          stats[:correct_retry] += 1
        end
      end

      def display_correct(item)
        output.puts "✅ Correct!"
        output.puts
        output.puts locative_summary(item)
      end

      def reveal_answer(item)
        stats[:revealed] += 1
        missed << item

        output.puts "Answer: #{item[:answers].first}"
        output.puts locative_summary(item)

        explanation = item[:explanation].to_s.strip
        output.puts explanation unless explanation.empty?
      end

      def locative_summary(item)
        "#{item[:target_form]} — #{item[:question]} / #{item[:case]} / #{item[:family_code]}"
      end

      def quit?
        @quit
      end
    end
  end
end
