# frozen_string_literal: true

require_relative "scorer"

module Linguatrain
  module Translation
    class Exercise
      def initialize(entries, scorer:, input: $stdin, output: $stdout, show_phonetic: false, listen: false, speaker: nil)
      @entries = entries
      @scorer = scorer
      @input = input
      @output = output
      @show_phonetic = show_phonetic
      @listen = listen
      @speaker = speaker
      @quit_requested = false
    end

    def self.run(entries, scorer:, input: $stdin, output: $stdout, show_phonetic: false, listen: false, speaker: nil)
      new(
        entries,
        scorer: scorer,
        input: input,
        output: output,
        show_phonetic: show_phonetic,
        listen: listen,
        speaker: speaker
      ).run
    end

      def entry_source(entry)
        (entry["source"] || entry[:source]).to_s
      end

    def show_phonetic?
      @show_phonetic
    end

      def listen?
        @listen
      end

      def speaker
        @speaker
      end

      def speak_source(entry)
        return unless listen?
        return unless speaker

        source = entry_source(entry).to_s.strip
        return if source.empty?

        output.puts "🎧  #{source}"
        speaker.call(source)
      end

      def run
        entries.each do |entry|
          break if quit_requested?

          run_entry(entry)
        end
      end

      private

      attr_reader :entries, :scorer, :input, :output



      def display_chunk_phonetics(entry)
        chunks = Array(entry["chunks"] || entry[:chunks])

        rows = chunks.filter_map do |chunk|
          source = chunk["source"] || chunk[:source]
          phonetic = chunk["phonetic"] || chunk[:phonetic] || chunk["phonetics"] || chunk[:phonetics]

          source = source.to_s.strip
          phonetic = phonetic.to_s.strip

          next if source.empty? || phonetic.empty?

          [source, phonetic]
        end

        return if rows.empty?

        output.puts
        output.puts "Remaining pronunciation:"

        width = rows.map { |source, _phonetic| source.length }.max || 0
        rows.each do |source, phonetic|
          output.puts "#{source.ljust(width)}  #{phonetic}"
        end
      end

      def run_entry(entry)

        loop do
          display_prompt(entry)
          answer = read_answer

          if answer.downcase == "q" || answer.downcase == "quit"
            @quit_requested = true
            return
          end

          if answer.empty?
            if retry_mode?(entry)
              result = scorer.score("", entry)
              action = prompt_for_action(result)

              case action
              when :retry
                next
              when :show_hint
                display_hint(entry, result)
                next
              when :show_answer
                display_answer(entry)
                follow_up_action = prompt_after_answer(result)

                case follow_up_action
                when :retry
                  next
                when :next
                  return
                when :quit
                  @quit_requested = true
                  return
                end
              when :next
                return
              when :quit
                @quit_requested = true
                return
              end
            else
              output.puts "No answer entered. Moving to the next sentence."
              return
            end
          end

          if retry_mode?(entry) && ["h", "hint", "l", "literal", "literal hint"].include?(answer.downcase)
            display_hint(entry, scorer.score("", entry))
            next
          end

          result = scorer.score(answer, entry)
          display_result(result)

          if retry_mode?(entry) && !fully_correct?(result) && result.fetch(:correct).positive?
            entry = retry_entry(entry, result)
            next
          end

          if fully_correct?(result)
            display_answer(entry)
            follow_up_action = prompt_after_answer(result)

            case follow_up_action
            when :next
              return
            when :quit
              @quit_requested = true
              return
            end
          end

          action = prompt_for_action(result)

          case action
          when :retry
            entry = retry_entry(entry, result)
            next
          when :show_hint
            loop do
              display_hint(entry, result)
              follow_up_action = prompt_after_hint(result)

              case follow_up_action
              when :show_hint
                next
              when :retry
                entry = retry_entry(entry, result)
                break
              when :show_answer
                display_answer(entry)
                follow_up_action = prompt_after_answer(result)

                case follow_up_action
                when :retry
                  entry = retry_entry(entry, result)
                  break
                when :next
                  return
                when :quit
                  @quit_requested = true
                  return
                end
              when :next
                return
              when :quit
                @quit_requested = true
                return
              end
            end
            next
          when :show_answer
            display_answer(entry)
            follow_up_action = prompt_after_answer(result)

            case follow_up_action
            when :retry
              entry = retry_entry(entry, result)
              next
            when :next
              return
            when :quit
              @quit_requested = true
              return
            end
          when :next
            return
          when :quit
            @quit_requested = true
            return
          end
        end
      end

      def display_prompt(entry)
        retry_prompt = retry_mode?(entry)

        output.puts
        output.puts "-" * 50
        output.puts(retry_prompt ? "Remaining Translations" : "Translation Exercise")
        output.puts "-" * 50
        output.puts
        completed_matches_displayed = display_completed_matches(entry)

        if retry_prompt || completed_matches_displayed
          display_remaining_chunks(entry)
        else
          if listen? && !(entry["listened"] || entry[:listened])
            speak_source(entry)
          else
            output.puts entry_source(entry)
          end
        end

        if show_phonetic?
          if completed_matches_displayed
            display_chunk_phonetics(entry)
          else
            display_entry_phonetic(entry)
          end
        end

        output.puts
        output.print "> "
      end

      def display_remaining_chunks(entry)
        chunks = Array(entry["chunks"] || entry[:chunks])

        if chunks.empty?
          remaining = entry_source(entry).to_s.strip
          return if remaining.empty?

          output.puts "✗ #{remaining}"
          output.puts
          output.puts "-" * 50
          output.puts
          output.puts remaining
          return
        end

        chunks.each do |chunk|
          source = chunk["source"] || chunk[:source]
          source = source.to_s.strip
          next if source.empty?

          output.puts "✗ #{source}"
        end

        output.puts
        output.puts "-" * 50
        output.puts

        first_chunk = chunks.find do |chunk|
          source = chunk["source"] || chunk[:source]
          !source.to_s.strip.empty?
        end

        return unless first_chunk

        source = first_chunk["source"] || first_chunk[:source]
        output.puts source.to_s.strip
      end

      def display_completed_matches(entry)
        completed_matches = entry["completed_matches"] || entry[:completed_matches] || []
        return false if completed_matches.empty?

        completed_matches.each do |match|
          matched_text = match.fetch(:matched_text, nil)
          source = match[:source] || match["source"]

          if matched_text
            output.puts "✓ #{source} : #{matched_text}"
          else
            output.puts "✓ #{source}"
          end
        end

        output.puts
        true
      end

      def retry_entry(entry, result)

        missed = result.fetch(:missed)

        retry_source = missed.map { |match| match[:source] || match["source"] }.compact.join("\n")
        retry_chunks = missed.map do |match|
          chunk = {
            "id" => match[:id] || match["id"],
            "source" => match[:source] || match["source"],
            "targets" => match[:targets] || match["targets"] || [],
            "hint" => hint_for_chunk(entry, match),
            "phonetic" => phonetic_for_chunk(entry, match)
          }

          chunk.reject { |_key, value| value.nil? || (value.respond_to?(:empty?) && value.empty?) }
        end

        completed_matches = (entry["completed_matches"] || entry[:completed_matches] || []) +
                            result.fetch(:matches).select { |match| match.fetch(:matched) }

        entry.merge(
          "source" => retry_source,
          "chunks" => retry_chunks,
          "target" => entry["target"] || entry[:target],
          "completed_matches" => completed_matches,
          "listened" => true,
          "retry" => true
        )
      end

      def read_answer
        input.gets&.chomp.to_s.strip
      end

      def display_result(result)
        output.puts
        output.puts "-" * 50
        output.puts "Results"
        output.puts "-" * 50
        output.puts

        matches_to_display(result).each do |match|
          marker = match.fetch(:matched) ? "✓" : "✗"
          matched_text = match.fetch(:matched_text, nil)

          if match.fetch(:matched) && matched_text
            output.puts "#{marker} #{match.fetch(:source)} : #{matched_text}"
          else
            output.puts "#{marker} #{match.fetch(:source)}"
          end
          # Removed inline pronunciation for missed chunks
          # display_match_phonetic(result.fetch(:entry, {}), match) unless match.fetch(:matched)
        end

        # Show block pronunciation for missed chunks if enabled
        display_result_phonetics(result) if show_phonetic?

        output.puts
        output.puts "Score: #{result.fetch(:correct)}/#{result.fetch(:total)} (#{percentage(result)}%)"
      end

      def display_result_phonetics(result)
        entry = result.fetch(:entry, {})
        missed = result.fetch(:missed, [])

        rows = missed.filter_map do |match|
          source = match[:source] || match["source"]
          phonetic = phonetic_for_chunk(entry, match)

          source = source.to_s.strip
          phonetic = phonetic.to_s.strip

          next if source.empty? || phonetic.empty?

          [source, phonetic]
        end

        return if rows.empty?

        output.puts
        output.puts "Pronunciation:"

        width = rows.map { |source, _phonetic| source.length }.max || 0
        rows.each do |source, phonetic|
          output.puts "#{source.ljust(width)}  #{phonetic}"
        end
      end

      def matches_to_display(result)
        result.fetch(:matches)
      end

      def fully_correct?(result)
        result.fetch(:correct) == result.fetch(:total)
      end

      def prompt_for_action(result)
        loop do
          output.puts
          output.puts available_actions(result)
          output.print "Choice: "

          case read_answer.downcase
          when "h", "hint", "l", "literal", "literal hint"
            return :show_hint if hints_available?(result)

            output.puts "No hint is available for this sentence."
          when "r", "retry"
            return :retry if retry_available?(result)

            output.puts "There are no missed chunks to retry."
          when "s", "show", "show answer", "answer"
            return :show_answer
          when "n", "next"
            return :next
          when "q", "quit"
            return :quit
          else
            output.puts "Please choose one of the listed options."
          end
        end
      end

      def prompt_after_hint(result)
        loop do
          output.puts
          output.puts after_hint_actions(result)
          output.print "Choice: "

          case read_answer.downcase
          when "h", "hint", "l", "literal", "literal hint"
            return :show_hint if hints_available?(result)

            output.puts "No more hints are available for this sentence."
          when "r", "retry"
            return :retry if retry_available?(result)

            output.puts "There are no missed chunks to retry."
          when "s", "show", "show answer", "answer"
            return :show_answer
          when "n", "next"
            return :next
          when "q", "quit"
            return :quit
          else
            output.puts "Please choose one of the listed options."
          end
        end
      end

      def prompt_after_answer(result)
        loop do
          output.puts
          output.puts after_answer_actions(result)
          output.print "Choice: "

          case read_answer.downcase
          when "r", "retry"
            return :retry if retry_available?(result)

            output.puts "There are no missed chunks to retry."
          when "n", "next"
            return :next
          when "q", "quit"
            return :quit
          else
            output.puts "Please choose one of the listed options."
          end
        end
      end

      def available_actions(result)
        actions = []
        actions << "[H]int" if hints_available?(result)
        actions << "[R]etry" if retry_available?(result)
        actions << "[S]how answer"
        actions << "[N]ext"
        actions << "[Q]uit"
        actions.join("  ")
      end

      def after_hint_actions(result)
        actions = []
        actions << "[H]int" if hints_available?(result)
        actions << "[R]etry" if retry_available?(result)
        actions << "[S]how answer"
        actions << "[N]ext"
        actions << "[Q]uit"
        actions.join("  ")
      end

      def after_answer_actions(result)
        actions = []
        actions << "[R]etry" if retry_available?(result)
        actions << "[N]ext"
        actions << "[Q]uit"
        actions.join("  ")
      end

      def retry_mode?(entry)
        entry["retry"] || entry[:retry]
      end

      def retry_available?(result)
        result.fetch(:correct) < result.fetch(:total)
      end

      def hints_available?(result)
        !hints_for(result.fetch(:entry, {}), result.fetch(:missed, [])).empty?
      end

      def display_hint(entry, result = nil)
        missed = result ? result.fetch(:missed, []) : []
        hints = hints_for(entry, missed)

        output.puts
        output.puts "Hint:"

        if hints.empty?
          output.puts "No hint available."
          return
        end

        index = next_hint_index(entry, hints.length)
        output.puts hints[index]

        display_missed_chunk_phonetics(entry, missed) if show_phonetic?
      end

      def next_hint_index(entry, hint_count)
        @hint_indexes ||= Hash.new(0)
        key = entry["id"] || entry[:id] || entry_source(entry)
        index = @hint_indexes[key] % hint_count
        @hint_indexes[key] += 1
        index
      end

      def hints_for(entry, missed_chunks = [])
        hints = []

        Array(missed_chunks).each do |chunk|
          hint = hint_for_chunk(entry, chunk)

          source = chunk[:source] || chunk["source"]
          targets = chunk[:targets] || chunk["targets"] || chunk[:target] || chunk["target"]

          source = source.to_s.strip
          target = Array(targets).map { |x| x.to_s.strip }.reject(&:empty?).first

          if !hint.empty?
            hints << hint
            next
          end

          if !source.empty? && target && !target.empty?
            hints << "\"#{source}\" means \"#{target}\"."
          end
        end

        vocabulary = entry["vocabulary"] || entry[:vocabulary] || []
        Array(vocabulary).each do |item|
          if item.is_a?(Hash)
            word = item["word"] || item[:word]
            meaning = item["meaning"] || item[:meaning]

            word = word.to_s.strip
            meaning = meaning.to_s.strip

            if !word.empty? && !meaning.empty?
              hints << "#{word} means #{meaning}."
            elsif !word.empty?
              hints << word
            end
          else
            text = item.to_s.strip
            hints << text unless text.empty?
          end
        end

        grammar = entry["grammar"] || entry[:grammar]

        case grammar
        when Array
          grammar.each do |item|
            next unless item.is_a?(Hash)

            note = item["note"] || item[:note]
            note = note.to_s.strip
            hints << note unless note.empty?
          end
        when Hash
          notes = grammar["notes"] || grammar[:notes] || []

          Array(notes).each do |note|
            note = note.to_s.strip
            hints << note unless note.empty?
          end
        end

        literal = entry["literal"] || entry[:literal]
        literal = literal.to_s.strip
        hints << literal unless literal.empty?

        hints.uniq
      end

      def hint_for_chunk(entry, chunk)
        explicit_hint = chunk[:hint] || chunk["hint"]
        explicit_hint = explicit_hint.to_s.strip
        return explicit_hint unless explicit_hint.empty?

        chunk_id = chunk[:id] || chunk["id"]
        chunk_source = chunk[:source] || chunk["source"]

        matching_chunk = Array(entry["chunks"] || entry[:chunks]).find do |candidate|
          candidate_id = candidate["id"] || candidate[:id]
          candidate_source = candidate["source"] || candidate[:source]

          (!chunk_id.to_s.strip.empty? && candidate_id.to_s.strip == chunk_id.to_s.strip) ||
            (!chunk_source.to_s.strip.empty? && candidate_source.to_s.strip == chunk_source.to_s.strip)
        end

        return "" unless matching_chunk

        hint = matching_chunk["hint"] || matching_chunk[:hint]
        hint.to_s.strip
      end

      def display_answer(entry)
        output.puts

        literal = entry["literal"] || entry[:literal]
        literal = literal.to_s.strip

        unless literal.empty?
          output.puts "Literal:"
          output.puts literal
          output.puts
        end

        target = entry["target"] || entry[:target] || "No full target answer provided."

        output.puts "Answer:"
        output.puts target

        display_entry_phonetic(entry)
      end

      def display_entry_phonetic(entry)
        phonetic = entry["phonetic"] || entry[:phonetic] || entry["phonetics"] || entry[:phonetics]
        phonetic = phonetic.to_s.strip
        return if phonetic.empty?

        output.puts
        output.puts "Pronunciation:"
        output.puts phonetic
      end

      def display_match_phonetic(entry, match)
        return unless show_phonetic?

        phonetic = phonetic_for_chunk(entry, match)
        return if phonetic.empty?

        output.puts "  #{phonetic}"
      end

      def display_missed_chunk_phonetics(entry, missed_chunks)
        Array(missed_chunks).each do |chunk|
          phonetic = phonetic_for_chunk(entry, chunk)
          next if phonetic.empty?

          source = chunk[:source] || chunk["source"]
          source = source.to_s.strip

          output.puts
          if source.empty?
            output.puts "Pronunciation: #{phonetic}"
          else
            output.puts "Pronunciation for #{source}: #{phonetic}"
          end
        end
      end

      def phonetic_for_chunk(entry, chunk)
        explicit_phonetic = chunk[:phonetic] || chunk["phonetic"] || chunk[:phonetics] || chunk["phonetics"]
        explicit_phonetic = explicit_phonetic.to_s.strip
        return explicit_phonetic unless explicit_phonetic.empty?

        chunk_id = chunk[:id] || chunk["id"]
        chunk_source = chunk[:source] || chunk["source"]

        matching_chunk = Array(entry["chunks"] || entry[:chunks]).find do |candidate|
          candidate_id = candidate["id"] || candidate[:id]
          candidate_source = candidate["source"] || candidate[:source]

          (!chunk_id.to_s.strip.empty? && candidate_id.to_s.strip == chunk_id.to_s.strip) ||
            (!chunk_source.to_s.strip.empty? && candidate_source.to_s.strip == chunk_source.to_s.strip)
        end

        return "" unless matching_chunk

        phonetic = matching_chunk["phonetic"] || matching_chunk[:phonetic] || matching_chunk["phonetics"] || matching_chunk[:phonetics]
        phonetic.to_s.strip
      end

      def percentage(result)
        total = result.fetch(:total)
        return 0 if total.zero?

        ((result.fetch(:correct).to_f / total) * 100).round
      end

      def quit_requested?
        @quit_requested
      end
    end
  end
end
