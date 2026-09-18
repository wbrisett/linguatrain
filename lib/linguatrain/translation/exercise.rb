# frozen_string_literal: true

require_relative "scorer"

module Linguatrain
  module Translation
    class Exercise
    def initialize(entries, scorer:, input: $stdin, output: $stdout, show_phonetic: false, listen: false, speaker: nil, embedded: false, guidance: nil)
      @entries = entries
      @scorer = scorer
      @input = input
      @output = output
      @show_phonetic = show_phonetic
      @listen = listen
      @speaker = speaker
      @embedded = embedded
      @guidance_mode = guidance.to_s.strip.downcase
      @quit_requested = false
    end

    def self.run(entries, scorer:, input: $stdin, output: $stdout, show_phonetic: false, listen: false, speaker: nil, embedded: false, guidance: nil)
      new(
        entries,
        scorer: scorer,
        input: input,
        output: output,
        show_phonetic: show_phonetic,
        listen: listen,
        speaker: speaker,
        embedded: embedded,
        guidance: guidance
      ).run
    end

    def self.study(entries, scorer:, input: $stdin, output: $stdout, show_phonetic: false, listen: false, speaker: nil)
      new(
        entries,
        scorer: scorer,
        input: input,
        output: output,
        show_phonetic: show_phonetic,
        listen: listen,
        speaker: speaker
      ).study
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


        quit_requested? ? :quit : :complete
      end

      def study
        total = entries.length

        entries.each_with_index do |entry, index|
          break if quit_requested?

          display_study_entry(entry, index + 1, total)
          output.puts
          output.print "Press Enter for next, or q to quit: "

          answer = read_answer
          @quit_requested = true if answer.downcase == "q" || answer.downcase == "quit"
        end
      end

      private

      attr_reader :entries, :scorer, :input, :output

      def embedded?
        @embedded
      end



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
        return run_guided_entry(entry) if progressive_guidance?

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
            return if embedded?

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

      def progressive_guidance?
        @guidance_mode == "progressive"
      end

      def run_guided_entry(entry)
        display_prompt(entry)
        answer = read_answer

        if quit_answer?(answer)
          @quit_requested = true
          return
        end

        guided_commands = ["h", "hint", "s", "show", "show answer", "answer"]
        initial_command = answer.downcase if guided_commands.include?(answer.downcase)
        scored_answer = initial_command ? "" : answer
        result = scorer.score(scored_answer, entry)
        display_guided_result(result)

        unresolved = result.fetch(:matches).reject { |match| match[:matched] }
        unresolved.sort_by! { |match| match[:status] == :near ? 0 : 1 }
        initial_partial = unresolved.find do |match|
          exact_guided_partial?(answer, guided_chunk_from_match(match))
        end

        independent = result.fetch(:correct)
        corrected = 0
        revealed = 0
        completed = result.fetch(:matches).each_with_object({}) do |match, memo|
          next unless match[:matched]

          memo[guided_completion_key(match)] = match[:matched_text]
        end

        unresolved.each_with_index do |match, index|
          partial_answer = match.equal?(initial_partial) ? scored_answer : nil
          queued_command = index.zero? ? initial_command : nil
          outcome = coach_guided_chunk(
            match,
            remaining: unresolved.length - index,
            initial_partial: partial_answer,
            initial_command: queued_command
          )

          case outcome.fetch(:status)
          when :independent
            independent += 1
            completed[guided_completion_key(match)] = outcome.fetch(:answer)
          when :corrected
            corrected += 1
            completed[guided_completion_key(match)] = outcome.fetch(:answer)
          when :revealed
            revealed += 1
            completed[guided_completion_key(match)] = outcome.fetch(:answer)
          when :quit
            @quit_requested = true
            return
          end
        end

        output.puts
        output.puts "Completed:"
        guided_chunks(entry).each do |chunk|
          answer = completed[guided_completion_key(chunk)]
          next if answer.to_s.empty?

          output.puts "✓ #{chunk["source"] || chunk[:source]} : #{answer}"
        end
        output.puts
        output.puts "Correct independently: #{independent}"
        output.puts "Correct after guidance: #{corrected}"
        output.puts "Answers revealed: #{revealed}"
      end

      def display_guided_result(result)
        output.puts
        output.puts "-" * 50
        output.puts "Guided results"
        output.puts "-" * 50
        output.puts

        result.fetch(:matches).each do |match|
          case match[:status]
          when :correct
            output.puts "✓ #{match[:source]} : #{match[:matched_text]}"
          when :near
            output.puts "△ #{match[:source]} — almost correct"
          else
            output.puts "○ #{match[:source]} — not answered yet"
          end
        end
      end

      def coach_guided_chunk(match, remaining:, initial_partial: nil, initial_command: nil)
        chunk = guided_chunk_from_match(match)
        current_match = match
        hint_index = 0
        displayed_diagnostic = nil
        revealed_correction = false
        require_complete_action = false
        guidance_used = false
        queued_command = initial_command
        verb_misses = verb_correction?(current_match) ? 1 : 0
        conjugation_help_offered = false

        output.puts
        output.puts remaining > 1 ? "Let’s repair this action first." : "Let’s finish the remaining action."
        unless initial_partial.to_s.empty?
          output.puts "✅ #{initial_partial.strip}"
          require_complete_action = true
        end

        loop do
          diagnostic = guided_error_signature(current_match)
          if current_match[:status] == :near && diagnostic != displayed_diagnostic
            display_near_diagnostic(current_match)
            guidance_used = true
            displayed_diagnostic = diagnostic
          end
          if queued_command
            answer = queued_command
            queued_command = nil
          else
            output.puts
            prompt = if require_complete_action
                       "Now write the complete sentence (action) in Finnish:"
                     elsif current_match[:status] == :near
                       "Correct this word in Finnish:"
                     else
                       "Write this action in Finnish:"
                     end
            output.puts prompt
            display_guided_controls
            output.print "> "
            answer = read_answer
          end

          return { status: :quit } if quit_answer?(answer)

          if %w[h hint].include?(answer.downcase) || answer.empty?
            hints = guided_hints_for(chunk, current_match)
            if hint_index < hints.length
              output.puts "Hint: #{hints[hint_index]}"
              guidance_used = true
              hint_index += 1
            else
              output.puts "No more hints are available. Type s to reveal the answer."
            end
            next
          end

          if ["s", "show", "show answer", "answer"].include?(answer.downcase)
            correction = focused_guided_correction(current_match)
            unless correction
              revealed_answer = canonical_chunk_target(chunk)
              output.puts "Answer: #{revealed_answer}"
              return { status: :revealed, answer: revealed_answer }
            end

            answer = correction[:expected]
            revealed_correction = true
            output.puts "Answer: #{answer}"
          end

          correction = focused_guided_correction(current_match)
          if correction && guided_words(answer).length == 1
            if normalize_guided_text(answer) == normalize_guided_text(correction[:expected])
              output.puts "✅ #{answer.strip}"
              repaired_answer = apply_guided_correction(current_match, correction)
              attempt = score_guided_chunk(repaired_answer, chunk)
              attempted_match = attempt.fetch(:matches).first

              if attempted_match[:matched]
                current_match = attempted_match
                require_complete_action = true
                hint_index = 0
                displayed_diagnostic = nil
                next
              end

              current_match = attempted_match
              hint_index = 0
              displayed_diagnostic = nil
              next
            end

            if verb_correction?(current_match)
              verb_misses += 1
              if verb_misses >= 2 && !conjugation_help_offered
                conjugation_help_offered = true
                help_status = offer_guided_conjugation_help(current_match)
                return { status: :quit } if help_status == :quit
                guidance_used = true if help_status == :completed
              end
            end
            current_match = guided_word_retry_match(current_match, correction, answer)
            hint_index = 0
            displayed_diagnostic = nil
            next
          end

          attempt = score_guided_chunk(answer, chunk)
          attempted_match = attempt.fetch(:matches).first

          if attempted_match[:matched]
            output.puts "✅ #{attempted_match[:matched_text]}"
            status = if revealed_correction
                       :revealed
                     elsif guidance_used
                       :corrected
                     else
                       :independent
                     end
            return { status: status, answer: attempted_match[:matched_text] }
          end

          if exact_guided_partial?(answer, chunk)
            output.puts "✅ #{answer.strip}"
            require_complete_action = true
            current_match = attempted_match
            hint_index = 0
            displayed_diagnostic = nil
            next
          end

          require_complete_action = false
          current_match = attempted_match
          attempted_verb = if verb_correction?(current_match)
                             guidance_component_for(
                               current_match[:guidance],
                               focused_guided_correction(current_match)[:expected]
                             )
                           else
                             attempted_guided_verb_component(current_match, answer)
                           end
          if attempted_verb
            verb_misses += 1
            if verb_misses >= 2 && !conjugation_help_offered
              conjugation_help_offered = true
              help_status = offer_guided_conjugation_help(current_match, component: attempted_verb)
              return { status: :quit } if help_status == :quit
              guidance_used = true if help_status == :completed
            end
          end
          hint_index = 0
          displayed_diagnostic = nil
          if current_match[:status] == :missing
            output.puts "Not quite. Type h for a hint, or try again."
          end
        end
      end

      def display_near_diagnostic(match)
        output.puts "Almost correct:"

        Array(match[:corrections]).first(1).each do |correction|
          output.puts "  You wrote: #{correction[:actual]}"

          component = guidance_component_for(match[:guidance], correction[:expected])
          unless component
            output.puts "- This word is close, but its form is not correct."
            next
          end

          role = guidance_value(component, :role)
          lemma = guidance_value(component, :lemma)
          verb_type = guidance_value(component, :verb_type)
          grammatical_case = guidance_value(component, :case)
          person = guidance_value(component, :person)
          number = guidance_value(component, :number)

          base_label = role == "verb" ? "Base verb" : "Base noun"
          output.puts "- #{base_label}: #{lemma}" unless lemma.empty?
          output.puts "- Verb type: #{verb_type.sub(/\Atype\s+/i, '')}" if role == "verb" && !verb_type.empty?
          grammatical_form = [person, number].reject(&:empty?).join("-person ")
          output.puts "- Required form: #{grammatical_form}" unless grammatical_form.empty?
          output.puts "- Required case: #{grammatical_case}" unless grammatical_case.empty?
        end
      end

      def guided_chunk_from_match(match)
        {
          "id" => match[:id],
          "source" => match[:source],
          "targets" => match[:targets],
          "hint" => match[:hint],
          "guidance" => match[:guidance]
        }.reject { |_key, value| value.nil? }
      end

      def guided_hints_for(chunk, match = nil)
        guidance = chunk["guidance"] || {}
        components = Array(guidance_value_raw(guidance, :components))
        verb = components.find { |component| guidance_value(component, :role) == "verb" }
        corrections = Array(match && match[:corrections])

        unless corrections.empty?
          targeted = corrections.flat_map do |correction|
            component = guidance_component_for(guidance, correction[:expected])
            Array(guidance_value_raw(component || {}, :hints))
          end.map { |hint| hint.to_s.strip }.reject(&:empty?).uniq
          return targeted unless targeted.empty?
        end

        authored = Array(guidance_value_raw(guidance, :hints)).map { |hint| hint.to_s.strip }.reject(&:empty?)
        return add_verb_type_to_base_hint(authored, verb) unless authored.empty?

        subject = components.find { |component| guidance_value(component, :role) == "subject" }
        hints = [chunk["source"].to_s.strip]
        hints << "Base verb: #{guidance_value(verb, :lemma)}." if verb
        if subject
          subject_form = guidance_value(subject, :form)
          hints << "Subject: #{subject_form}; use the matching verb form." unless subject_form.empty?
        end
        add_verb_type_to_base_hint(hints.reject(&:empty?), verb)
      end

      def add_verb_type_to_base_hint(hints, verb)
        raw_type = guidance_value(verb || {}, :verb_type)
        return hints if raw_type.empty?

        verb_type = raw_type.sub(/\Atype\s+/i, "")
        hints.map do |hint|
          next hint unless hint.match?(/\Abase verb:/i)
          next hint if hint.match?(/\btype\s+#{Regexp.escape(verb_type)}\s+verb\b/i)

          punctuated = hint.end_with?(".") ? hint : "#{hint}."
          "#{punctuated} Type #{verb_type} verb."
        end
      end

      def guided_error_signature(match)
        return "missing" unless match[:status] == :near

        Array(match[:corrections]).map do |correction|
          [correction[:index], correction[:actual], correction[:expected]].join(":")
        end.join("|")
      end

      def guidance_component_for(guidance, expected_form)
        components = Array(guidance_value_raw(guidance || {}, :components))
        components.find do |component|
          guidance_value(component, :form).downcase == expected_form.to_s.downcase
        end
      end

      def guidance_value(hash, key)
        guidance_value_raw(hash || {}, key).to_s.strip
      end

      def guidance_value_raw(hash, key)
        return nil unless hash.is_a?(Hash)

        hash[key] || hash[key.to_s]
      end

      def canonical_chunk_target(chunk)
        Array(chunk["targets"] || chunk[:targets]).first.to_s
      end

      def score_guided_chunk(answer, chunk)
        scorer.score(
          answer,
          { "chunks" => [chunk], "source" => chunk["source"], "target" => canonical_chunk_target(chunk) }
        )
      end

      def focused_guided_correction(match)
        return nil unless match[:status] == :near

        Array(match[:corrections]).first
      end

      def apply_guided_correction(match, correction)
        words = guided_words(match[:near_text])
        words[correction[:index]] = correction[:expected]
        words.join(" ")
      end

      def guided_word_retry_match(match, correction, answer)
        retry_correction = correction.merge(actual: normalize_guided_text(answer))
        match.merge(corrections: [retry_correction])
      end

      def verb_correction?(match)
        correction = focused_guided_correction(match)
        return false unless correction

        component = guidance_component_for(match[:guidance], correction[:expected])
        guidance_value(component || {}, :role) == "verb"
      end

      def attempted_guided_verb_component(match, answer)
        components = Array(guidance_value_raw(match[:guidance] || {}, :components))
        verbs = components.select { |component| guidance_value(component, :role) == "verb" }
        words = guided_words(answer).select { |word| word.length >= 3 }
        return nil if verbs.empty? || words.empty?

        candidates = verbs.product(words).filter_map do |component, word|
          expected_forms = [
            guidance_value(component, :form),
            guidance_value(component, :lemma)
          ].map { |value| normalize_guided_text(value) }.reject { |value| value.length < 3 }.uniq

          distances = expected_forms.filter_map do |expected|
            next unless word[0] == expected[0]

            distance = guided_edit_distance(word, expected)
            threshold = [2, (expected.length * 0.45).floor].max
            distance if distance <= threshold
          end
          next if distances.empty?

          [component, distances.min]
        end

        candidates.min_by { |_component, distance| distance }&.first
      end

      def guided_edit_distance(left, right)
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

      def offer_guided_conjugation_help(match, component: nil)
        correction = focused_guided_correction(match)
        component ||= guidance_component_for(match[:guidance], correction && correction[:expected])
        aid = guidance_value_raw(component || {}, :conjugation)
        forms = guidance_value_raw(aid || {}, :forms)
        return :unavailable unless forms.is_a?(Hash) && !forms.empty?

        lemma = guidance_value(component, :lemma)
        output.puts
        loop do
          output.puts "Would you like to practice conjugating #{lemma} before continuing? [y - yes]  [n - no]  [q - quit]"
          output.print "> "
          choice = read_answer.downcase
          return :quit if quit_answer?(choice)
          return :declined if %w[n no].include?(choice)
          break if %w[y yes].include?(choice)

          output.puts "Please enter y, n, or q."
        end

        run_guided_conjugation_help(lemma, forms)
      end

      def run_guided_conjugation_help(lemma, forms)
        output.puts
        output.puts "Conjugation practice — #{lemma}"
        output.puts "Practice each present-tense form."

        forms.each do |subject, raw_form|
          expected = if raw_form.is_a?(Hash)
                       guidance_value_raw(raw_form, :form) || guidance_value_raw(raw_form, :positive)
                     else
                       raw_form
                     end
          expected = Array(expected).first.to_s.strip
          next if expected.empty?

          output.puts
          output.puts "Subject: #{subject}"
          correct = false

          2.times do |attempt|
            output.puts "[q - quit]"
            output.print "> "
            answer = read_answer
            if quit_answer?(answer)
              @quit_requested = true
              return :quit
            end

            if normalize_guided_text(answer) == normalize_guided_text(expected)
              output.puts "✅ Correct!"
              correct = true
              break
            end

            output.puts "Try again." if attempt.zero?
          end

          output.puts "Answer: #{expected}" unless correct
        end

        output.puts
        output.puts "Conjugation practice complete. Return to the image action."
        :completed
      end

      def guided_words(text)
        normalize_guided_text(text).split
      end

      def exact_guided_partial?(answer, chunk)
        answer_words = guided_words(answer)
        return false if answer_words.empty?

        is_target_subset = Array(chunk["targets"] || chunk[:targets]).any? do |target|
          target_words = guided_words(target)
          next false if answer_words.length >= target_words.length

          target_words.each_cons(answer_words.length).any? { |words| words == answer_words }
        end
        return false unless is_target_subset

        return true if answer_words.length > 1

        components = Array(guidance_value_raw(chunk["guidance"] || {}, :components))
        components.any? do |component|
          guidance_value(component, :role) != "subject" &&
            normalize_guided_text(guidance_value(component, :form)) == answer_words.first
        end
      end

      def guided_chunks(entry)
        chunks = Array(entry["chunks"] || entry[:chunks])
        return chunks unless chunks.empty?

        [{
          "source" => entry["source"] || entry[:source],
          "targets" => [entry["target"] || entry[:target]]
        }]
      end

      def guided_completion_key(item)
        id = item["id"] || item[:id]
        return "id:#{id}" unless id.to_s.empty?

        source = item["source"] || item[:source]
        "source:#{source}"
      end

      def normalize_guided_text(text)
        text.to_s
            .downcase
            .gsub(/[[:punct:]]/, " ")
            .gsub(/\s+/, " ")
            .strip
      end

      def quit_answer?(answer)
        %w[q quit].include?(answer.to_s.downcase)
      end

      def display_prompt(entry)
        retry_prompt = retry_mode?(entry)

        output.puts
        output.puts "-" * 50
        output.puts(retry_prompt ? "Remaining Translations" : "Translation Exercise")
        output.puts "-" * 50
        output.puts
        display_focus_cue(entry)
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
        display_guided_controls if progressive_guidance?
        output.print "> "
      end

      def display_guided_controls
        output.puts "[h - help]  [s - show answer]  [q - quit]"
      end

      def display_focus_cue(entry)
        marker = (entry["focus_marker"] || entry[:focus_marker]).to_s.strip
        return if marker.empty?

        output.puts "Look at marker #{marker}."
        output.puts
      end

      def display_study_entry(entry, index, total)
        output.puts
        output.puts "-" * 50
        output.puts "Translation Study #{index}/#{total}"
        output.puts "-" * 50
        output.puts

        if listen?
          speak_source(entry)
        else
          output.puts "Source:"
          output.puts entry_source(entry)
        end

        output.puts
        display_study_chunks(entry)
        display_answer(entry)
      end

      def display_study_chunks(entry)
        chunks = Array(entry["chunks"] || entry[:chunks])
        return if chunks.empty?

        output.puts "Chunks:"

        chunks.each_with_index do |chunk, index|
          output.puts if index.positive?

          source = chunk["source"] || chunk[:source]
          literal = chunk["literal"] || chunk[:literal]
          target = chunk["target"] || chunk[:target]
          targets = chunk["targets"] || chunk[:targets]
          hint = chunk["hint"] || chunk[:hint]
          phonetic = chunk["phonetic"] || chunk[:phonetic] || chunk["phonetics"] || chunk[:phonetics]
          target_text = target.to_s.strip
          target_text = Array(targets).map { |item| item.to_s.strip }.reject(&:empty?).join(" / ") if target_text.empty?

          output.puts "- #{source}"
          output.puts "  literal: #{literal}" unless literal.to_s.strip.empty?
          output.puts "  target: #{target_text}" unless target_text.empty?
          output.puts "  pronunciation: #{phonetic}" if show_phonetic? && !phonetic.to_s.strip.empty?
          output.puts "  hint: #{hint}" unless hint.to_s.strip.empty?
        end
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
