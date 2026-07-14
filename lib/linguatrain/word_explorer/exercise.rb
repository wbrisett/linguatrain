# frozen_string_literal: true

module Linguatrain
  module WordExplorer
    class Exercise
      def self.run(entries, pool:, grammar:, input: $stdin, output: $stdout, mode: :recognize, match_game: false, lenient: false)
        new(
          entries,
          pool: pool,
          grammar: grammar,
          input: input,
          output: output,
          mode: mode,
          match_game: match_game,
          lenient: lenient
        ).run
      end

      def initialize(entries, pool:, grammar:, input:, output:, mode:, match_game:, lenient:)
        @entries = Array(entries)
        @pool = Array(pool)
        @grammar = Array(grammar).each_with_object({}) { |item, out| out[item[:key].to_s] = item }
        @input = input
        @output = output
        @mode = normalize_mode(mode)
        @match_game = match_game
        @lenient = lenient
        @stats = {
          words_explored: 0,
          dimensions: {},
          overall: empty_score
        }
        @missed = []
      end

      def run
        active_entries =
          case mode
          when :build
            build_family_entries
          when :recognize
            recognizable_entries
          else
            entries
          end

        output.puts
        output.puts "Word Explorer — #{active_entries.length} word(s) (mode: #{mode})"
        output.puts "-" * 70

        active_entries.each_with_index do |entry, idx|
          break unless run_entry(entry, idx, active_entries.length)
        end

        [stats, missed]
      end

      private

      attr_reader :entries, :pool, :grammar, :input, :output, :mode, :stats, :missed

      def normalize_mode(value)
        mode = value.to_s.strip.downcase.tr("-", "_")
        return :build if mode == "build"
        return :apply if mode == "apply"

        :recognize
      end

      def match_game?
        @match_game
      end

      def lenient?
        @lenient
      end

      def run_entry(entry, idx, total)
        stats[:words_explored] += 1

        output.puts
        output.puts "-" * 50 if mode == :recognize
        output.puts "[#{idx + 1}/#{total}]"
        output.puts

        case mode
        when :build
          run_build_entry(entry)
        when :apply
          run_apply_entry(entry)
        else
          run_recognize_entry(entry)
        end
      end

      def run_recognize_entry(entry)
        if match_game?
          run_match_entry(entry)
        else
          run_guided_entry(entry)
        end
      end

      def run_guided_entry(entry)
        translation_state = { shown: false }

        display_word(entry)

        return false unless ask_typed(
          "What is the base word?",
          [entry[:base_word]],
          hint: entry[:hint],
          missed_payload: entry,
          translation_entry: entry,
          translation_state: translation_state,
          dimension: :base_word
        )

        return false unless ask_typed(
          "What does #{entry[:word]} mean here?",
          [entry[:target]],
          missed_payload: entry,
          translation_entry: entry,
          translation_state: translation_state,
          dimension: :meaning
        )

        display_report(entry)
        continue?
      end

      def run_match_entry(entry)
        translation_state = { shown: false }

        display_word(entry)

        choices = choice_list(entry[:base_word], base_word_distractors(entry))
        correct = ask_choice("Choose the base word:", choices, entry[:base_word], entry, translation_state, dimension: :base_word)
        return false if stats[:aborted]

        display_report(entry)
        continue?
      end

      def run_build_entry(entry)
        translation_state = { shown: false }
        explorations = buildable_explorations(entry)
        translation_entry = entry[:source_contexts] ? nil : entry

        display_base_word(entry)

        if explorations.empty?
          output.puts "No exploration forms available for this word."
          output.puts
          return continue?
        end

        explorations.each_with_index do |exploration, exploration_idx|
          display_exploration_header(entry, exploration_idx, explorations.length)

          ok = ask_typed_answer(
            [exploration[:word]],
            missed_payload: exploration_missed_payload(entry, exploration),
            translation_entry: translation_entry,
            translation_state: translation_state,
            context_entry: entry,
            hint_entry: exploration,
            dimension: :build,
            prompt_renderer: -> { display_build_prompt(entry, exploration, translation_state) }
          )
          return false unless ok

          display_exploration_report(exploration) unless ok == :review_displayed
          return false if exploration_idx < explorations.length - 1 && !continue_exploration?
        end

        continue?
      end

      def run_apply_entry(entry)
        applications = applicable_applications(entry)

        display_base_word(entry)

        if applications.empty?
          output.puts "No application contexts available for this word."
          output.puts
          return continue?
        end

        applications.each_with_index do |application, application_idx|
          translation_state = { shown: false }
          answer_word = application_answer_word(application)
          answer_exploration = application_answer_exploration(entry, application)

          display_exploration_header(entry, application_idx, applications.length)

          ok = ask_typed_answer(
            [answer_word],
            missed_payload: application_missed_payload(entry, application, answer_exploration),
            translation_entry: application,
            translation_state: translation_state,
            context_entry: entry,
            hint_entry: answer_exploration,
            dimension: :apply,
            prompt_renderer: -> { display_apply_prompt(entry, application, answer_exploration, translation_state) },
            wrong_answer_renderer: ->(answer) { display_application_wrong_answer(entry, application, answer) }
          )
          return false unless ok

          display_application_report(application, answer_exploration) unless ok == :review_displayed
          return false if application_idx < applications.length - 1 && !continue_exploration?
        end

        continue?
      end

      def ask_typed_answer(expected, missed_payload: nil, optional: false, translation_entry: nil, translation_state: nil, context_entry: nil, hint_entry: nil, dimension: nil, prompt_renderer: nil, wrong_answer_renderer: nil)
        last_answer = ""
        attempts = 0
        hint_level = 0
        hint_used = false
        expected_answer = Array(expected).first

        while attempts < 2
          prompt_renderer.call if prompt_renderer

          answer = prompt("> ")
          if quit?(answer)
            stats[:aborted] = true
            return false
          end

          if translation_requested?(answer)
            display_translation(translation_entry, translation_state)
            next
          end

          if hint_requested?(answer)
            hint_used = true
            hint_level += 1
            if display_answer_hint(hint_entry || context_entry, hint_level, expected: expected_answer) == :answer_revealed
              record_score(dimension, :answer_revealed) unless optional
              missed << missed_payload if missed_payload && !optional
              return true
            end
            help_result = handle_typed_help_menu(
              expected,
              expected_answer: expected_answer,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used,
              missed_payload: missed_payload,
              optional: optional,
              translation_entry: translation_entry,
              translation_state: translation_state,
              context_entry: context_entry,
              hint_entry: hint_entry,
              dimension: dimension,
              wrong_answer_renderer: wrong_answer_renderer
            )
            attempts = help_result[:attempts]
            hint_level = help_result[:hint_level]
            hint_used = help_result[:hint_used]
            return false if help_result[:status] == :aborted
            return :review_displayed if help_result[:status] == :review_displayed
            return true if help_result[:status] == :completed
            next
          end

          last_answer = answer

          if matches?(answer, expected)
            record_typed_success(dimension, attempts, hint_used, optional)
            return true
          end

          attempts += 1

          if attempts < 2
            output.puts terminal_red("✗ Not quite.")
            output.puts
            wrong_answer_renderer.call(answer) if wrong_answer_renderer
            help_result = handle_typed_help_menu(
              expected,
              expected_answer: expected_answer,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used,
              missed_payload: missed_payload,
              optional: optional,
              translation_entry: translation_entry,
              translation_state: translation_state,
              context_entry: context_entry,
              hint_entry: hint_entry,
              dimension: dimension,
              wrong_answer_renderer: wrong_answer_renderer
            )
            attempts = help_result[:attempts]
            hint_level = help_result[:hint_level]
            hint_used = help_result[:hint_used]
            return false if help_result[:status] == :aborted
            return :review_displayed if help_result[:status] == :review_displayed
            return true if help_result[:status] == :completed
          end
        end

        record_score(dimension, :failed) unless optional
        missed << missed_payload if missed_payload && !optional
        output.puts terminal_red("✗ Not quite.")
        output.puts
        if wrong_answer_renderer
          wrong_answer_renderer.call(last_answer)
          output.puts "Expected answer:"
          output.puts expected_answer
          output.puts
        else
          explain_typed_miss(last_answer, expected_answer, context_entry)
        end
        true
      end

      def ask_typed(label, expected, hint: "", missed_payload: nil, optional: false, translation_entry: nil, translation_state: nil, dimension: nil)
        1.upto(2) do |attempt|
          output.puts label
          output.puts "Type 'h' for a hint." unless hint.to_s.strip.empty?
          display_translation_prompt(translation_entry, translation_state)
          output.puts

          answer = prompt("> ")
          if quit?(answer)
            stats[:aborted] = true
            return false
          end

          if translation_requested?(answer)
            display_translation(translation_entry, translation_state)
            redo
          end

          if hint_requested?(answer)
            display_hint(hint)
            redo
          end

          if matches?(answer, expected)
            record_score(dimension, attempt == 1 ? :correct_1 : :correct_2) unless optional
            output.puts terminal_green("✓ Correct.")
            output.puts
            return true
          end

          output.puts terminal_red("✗ Try again.") if attempt < 2
        end

        record_score(dimension, :failed) unless optional
        missed << missed_payload if missed_payload && !optional
        output.puts terminal_red("✗ Not quite.")
        output.puts "Correct answer: #{Array(expected).first}"
        output.puts
        true
      end

      def ask_choice(label, choices, expected, entry, translation_state, dimension: nil)
        hint_used = false

        loop do
          output.puts label
          output.puts

          choices.each do |choice|
            output.puts "- #{choice}"
          end
          output.puts
          output.puts "Type 'h' for a hint." unless entry[:hint].to_s.strip.empty?
          display_translation_prompt(entry, translation_state)
          output.puts

          answer = prompt("> ")
          if quit?(answer)
            stats[:aborted] = true
            return false
          end

          if translation_requested?(answer)
            display_translation(entry, translation_state)
            next
          end

          if hint_requested?(answer)
            hint_used = true
            display_hint(entry[:hint])
            next
          end

          selected = selected_choice(answer, choices)
          if selected && matches?(selected, [expected])
            record_score(dimension, hint_used ? :correct_hint : :correct_1)
            output.puts terminal_green("✓ Correct.")
            output.puts
            return true
          end

          record_score(dimension, :failed)
          missed << entry
          explain_wrong_choice(selected, expected, entry)
          return false
        end
      end

      def empty_score
        { total: 0, correct_1: 0, correct_2: 0, correct_hint: 0, answer_revealed: 0, failed: 0 }
      end

      def dimension_score(dimension)
        key = dimension || :other
        stats[:dimensions][key] ||= empty_score
      end

      def record_score(dimension, result)
        dimension_score(dimension)[:total] += 1
        dimension_score(dimension)[result] += 1
        stats[:overall][:total] += 1
        stats[:overall][result] += 1
      end

      def display_context(entry)
        source = entry[:source] || {}
        text = source[:text].to_s.strip

        return if text.empty?

        output.puts "Context:"
        output.puts text
        output.puts
      end

      def display_translation_prompt(entry, translation_state)
        return if natural_translation(entry).empty?
        return if translation_state && translation_state[:shown]
        return if translation_state && translation_state[:prompted]

        output.puts "Type 't' for translation."
        translation_state[:prompted] = true if translation_state
        true
      end

      def display_translation(entry, translation_state = nil)
        translation = natural_translation(entry)
        return if translation.empty?
        return if translation_state && translation_state[:shown]

        output.puts
        output.puts "Natural language translation:"
        output.puts translation
        output.puts
        translation_state[:shown] = true if translation_state
      end

      def natural_translation(entry)
        source = entry && entry[:source] || {}
        source[:target].to_s.strip
      end

      def display_word(entry)
        output.puts terminal_blue("Word:")
        output.puts terminal_blue(entry[:word].to_s)
        output.puts
      end

      def display_base_word(entry)
        output.puts terminal_blue("Base word:")
        output.puts terminal_blue(entry[:base_word].to_s)
        output.puts
      end

      def display_exploration_header(entry, index, total)
        output.puts "-" * 50
        output.puts "Exploring #{entry[:base_word]} — #{index + 1}/#{total}"
        output.puts
      end

      def display_build_prompt(entry, exploration, translation_state)
        output.puts "Change #{entry[:base_word]} to mean:"
        output.puts exploration[:target]
        output.puts
        display_grammar_summary(exploration, description: false)
        output.puts if !entry[:source_contexts] && display_translation_prompt(entry, translation_state)
      end

      def display_apply_prompt(entry, application, _answer_exploration, translation_state)
        prompt = application[:prompt] || {}
        sentence = prompt[:text].to_s.strip
        meaning = prompt[:meaning].to_s.strip
        choices = application_choices(entry, application)

        unless sentence.empty?
          output.puts "Sentence:"
          output.puts sentence
          output.puts
        end

        unless meaning.empty?
          output.puts "Meaning:"
          output.puts meaning
          output.puts
        end

        output.puts "Choose the correct form of #{application_base_word(entry, application)}:"
        output.puts
        choices.each { |choice| output.puts "- #{choice}" }
        output.puts
      end

      def display_report(entry)
        output.puts "Base word:"
        output.puts entry[:base_word]
        output.puts

        grammar_item = grammar_item_for(entry)
        if grammar_item
          output.puts "Grammar:"
          output.puts terminal_cyan("#{grammar_item[:name]} — #{grammar_item[:plain_english]}")
          output.puts grammar_item[:description] unless grammar_item[:description].to_s.strip.empty?
          output.puts
        end

        formation = entry[:formation].to_s.strip
        unless formation.empty?
          output.puts "Formation:"
          output.puts formation
          output.puts
        end

        target = entry[:target].to_s.strip
        unless target.empty?
          output.puts "Meaning:"
          output.puts target
          output.puts
        end

        display_context(entry)
        display_source_translations(entry)

        explanation = entry[:explanation].to_s.strip
        unless explanation.empty?
          output.puts "Why:"
          output.puts explanation
          output.puts
        end
      end

      def display_exploration_report(exploration)
        target = exploration[:target].to_s.strip
        unless target.empty?
          output.puts "Meaning:"
          output.puts target
          output.puts
        end

        display_grammar_summary(exploration, description: false)

        formation = exploration[:formation].to_s.strip
        unless formation.empty?
          output.puts "Formation:"
          output.puts formation
          output.puts
        end

        explanation = exploration[:explanation].to_s.strip
        unless explanation.empty?
          output.puts "Why:"
          output.puts explanation
          output.puts
        end
      end

      def display_application_report(application, answer_exploration)
        display_grammar_summary(answer_exploration, description: false) if answer_exploration

        explanation = application_why_it_fits(application)
        return if explanation.empty?

        output.puts "Why it fits:"
        output.puts explanation
        output.puts
      end

      def display_grammar_summary(item, description: true)
        grammar_item = grammar_item_for(item)
        return unless grammar_item

        output.puts "Grammar:"
        output.puts terminal_cyan("#{grammar_item[:name]} — #{grammar_item[:plain_english]}")
        if description
          description_text = grammar_item[:description].to_s.strip
          output.puts description_text unless description_text.empty?
        end
        output.puts
      end

      def display_hint(hint)
        hint = hint.to_s.strip
        if hint.empty?
          output.puts "No hint available."
        else
          output.puts
          output.puts "Hint:"
          output.puts hint
        end
        output.puts
      end

      def display_answer_hint(item, hint_level, expected: nil)
        output.puts
        formation = item && item[:formation].to_s.strip
        explanation = item && item[:explanation].to_s.strip

        if hint_level >= 3 && !expected.to_s.strip.empty?
          output.puts "Answer:"
          output.puts expected
          output.puts
          return :answer_revealed
        elsif hint_level == 1 && (grammar_item = grammar_item_for(item))
          output.puts "Hint:"
          output.puts "#{grammar_item[:name]} — #{grammar_item[:plain_english]}"
          description = grammar_item[:description].to_s.strip
          output.puts description unless description.empty?
        elsif hint_level <= 2 && !formation.empty?
          output.puts "Formation hint:"
          output.puts formation
        elsif !explanation.empty?
          output.puts "Hint:"
          output.puts explanation
        else
          output.puts "Hint:"
          output.puts "No additional hint available."
        end

        output.puts
      end

      def handle_typed_help_menu(expected, expected_answer:, attempts:, hint_level:, hint_used:, missed_payload:, optional:, translation_entry:, translation_state:, context_entry:, hint_entry:, dimension:, wrong_answer_renderer: nil)
        loop do
          display_typed_help_menu(hint_entry || context_entry, hint_level)

          answer = prompt("> ")
          if quit?(answer)
            stats[:aborted] = true
            return {
              status: :aborted,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used
            }
          end

          if translation_requested?(answer)
            display_translation(translation_entry, translation_state)
            next
          end

          if show_answer_requested?(answer)
            display_revealed_answer(expected_answer)
            record_score(dimension, :answer_revealed) unless optional
            missed << missed_payload if missed_payload && !optional
            return {
              status: :review_displayed,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used
            }
          end

          if hint_requested?(answer)
            if next_hint_available?(hint_entry || context_entry, hint_level)
              hint_used = true
              hint_level += 1
              display_answer_hint(hint_entry || context_entry, hint_level, expected: expected_answer)
            else
              output.puts
              output.puts "No more hints available."
              output.puts
            end
            next
          end

          if matches?(answer, expected)
            record_typed_success(dimension, attempts, hint_used, optional)
            return {
              status: :completed,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used
            }
          end

          attempts += 1
          if attempts >= 2
            record_score(dimension, :failed) unless optional
            missed << missed_payload if missed_payload && !optional
            output.puts terminal_red("✗ Not quite.")
            output.puts
            if wrong_answer_renderer
              wrong_answer_renderer.call(answer)
              output.puts "Expected answer:"
              output.puts expected_answer
              output.puts
            else
              explain_typed_miss(answer, expected_answer, context_entry)
            end
            return {
              status: :review_displayed,
              attempts: attempts,
              hint_level: hint_level,
              hint_used: hint_used
            }
          end

          output.puts terminal_red("✗ Not quite.")
          output.puts
          wrong_answer_renderer.call(answer) if wrong_answer_renderer
        end
      end

      def display_typed_help_menu(item, hint_level)
        actions = []
        if next_hint_available?(item, hint_level)
          actions << (hint_level.zero? ? "[h] Hint" : "[h] More help")
        end
        actions << "[s] Show answer"

        output.puts actions.join("  ")
        output.puts
      end

      def record_typed_success(dimension, attempts, hint_used, optional)
        result =
          if attempts.zero? && !hint_used
            :correct_1
          elsif hint_used
            :correct_hint
          else
            :correct_2
          end
        record_score(dimension, result) unless optional
        output.puts terminal_green("✓ Correct.")
        output.puts
      end

      def display_revealed_answer(expected)
        output.puts
        output.puts "Answer:"
        output.puts expected
        output.puts
      end

      def hint_available?(item)
        return false unless item

        !item[:formation].to_s.strip.empty? ||
          !item[:explanation].to_s.strip.empty? ||
          !!grammar_item_for(item)
      end

      def next_hint_available?(item, hint_level)
        hint_available?(item) && hint_level < 2
      end

      def explain_wrong_choice(selected, expected, entry)
        output.puts
        output.puts terminal_red("✗ Not quite.")
        output.puts

        output.puts "Expected answer:"
        output.puts expected
        output.puts
      end

      def continue?
        answer = prompt("(Enter for next; q to quit): ")
        !quit?(answer)
      end

      def continue_exploration?
        answer = prompt("(Enter to continue; q to quit): ")
        output.puts
        if quit?(answer)
          stats[:aborted] = true
          return false
        end

        true
      end

      def prompt(label)
        output.print(label)
        value = input.gets
        value.nil? ? "q" : value.to_s.strip
      end

      def quit?(value)
        %w[q quit].include?(value.to_s.strip.downcase)
      end

      def hint_requested?(value)
        %w[h hint ?].include?(value.to_s.strip.downcase)
      end

      def show_answer_requested?(value)
        %w[s show answer reveal].include?(value.to_s.strip.downcase)
      end

      def translation_requested?(value)
        %w[t translate translation].include?(value.to_s.strip.downcase)
      end

      def matches?(value, expected)
        expected.any? do |item|
          normalize(value) == normalize(item) ||
            (lenient? && normalize_lenient(value) == normalize_lenient(item))
        end
      end

      def normalize(value)
        value.to_s.strip.downcase.gsub(/[[:punct:]]+\z/, "")
      end

      def normalize_lenient(value)
        normalize(value)
          .unicode_normalize(:nfd)
          .gsub(/\p{Mn}/, "")
          .unicode_normalize(:nfc)
      end

      def grammar_item_for(entry)
        morphology = entry[:morphology] || {}
        key = morphology["case"].to_s
        key = morphology[:case].to_s if key.empty?
        grammar[key]
      end

      def base_word_distractors(entry)
        distractors = []

        add_base_word_distractors(distractors, family_form_distractors(entry).shuffle, entry)
        add_base_word_distractors(distractors, same_type_base_word_distractors(entry).shuffle, entry)
        add_base_word_distractors(distractors, general_base_word_distractors(entry).shuffle, entry)

        distractors.first(3)
      end

      def recognizable_entries
        entries.reject { |entry| morphology_kind(entry) == "compound" }
      end

      def family_form_distractors(entry)
        values = []
        values << entry[:word]
        values.concat(entry[:explorations].map { |item| item[:word] })

        pool.each do |item|
          next unless matches?(item[:base_word], [entry[:base_word]])

          values << item[:word]
          values.concat(Array(item[:explorations]).map { |exploration| exploration[:word] })
        end

        values
      end

      def same_type_base_word_distractors(entry)
        entry_type = entry[:type].to_s.strip
        return [] if entry_type.empty?

        recognizable_entries
          .select { |item| item[:type].to_s.strip == entry_type }
          .map { |item| item[:base_word] }
      end

      def general_base_word_distractors(entry)
        recognizable_entries.map { |item| item[:base_word] }
      end

      def add_base_word_distractors(distractors, candidates, entry)
        candidates.each do |candidate|
          value = candidate.to_s.strip
          next if value.empty?
          next if matches?(value, [entry[:base_word]])
          next if distractors.any? { |existing| matches?(value, [existing]) }

          distractors << value
          break if distractors.length >= 3
        end
      end

      def morphology_kind(item)
        morphology = item[:morphology] || {}
        kind = morphology["kind"].to_s
        kind = morphology[:kind].to_s if kind.empty?
        kind
      end

      def valid_explorations(entry)
        Array(entry[:explorations]).select { |item| item[:status].to_s == "valid" && !item[:word].to_s.empty? }
      end

      def build_family_entries
        families = {}

        entries.each do |entry|
          base_word = entry[:base_word].to_s.strip
          next if base_word.empty?

          key = normalize(base_word)
          if families.key?(key)
            families[key][:explorations] = merge_family_explorations(
              families[key][:explorations],
              entry[:explorations]
            )
            families[key][:source_contexts] << entry[:source]
          else
            families[key] = entry.merge(
              explorations: merge_family_explorations(entry[:explorations]),
              source_contexts: [entry[:source]]
            )
          end
        end

        families.values.each do |entry|
          contexts = entry[:source_contexts].compact.map { |source| source[:text].to_s.strip }.reject(&:empty?).uniq
          entry.delete(:source_contexts) if contexts.length <= 1
        end

        families.values
      end

      def merge_family_explorations(*lists)
        seen = {}

        lists.flatten.compact.each_with_object([]) do |item, out|
          next unless item.is_a?(Hash)

          word = item[:word].to_s.strip
          next if word.empty?

          key = normalize(word)
          next if seen[key]

          seen[key] = true
          out << item
        end
      end

      def buildable_explorations(entry)
        valid_explorations(entry)
          .reject { |item| matches?(item[:word], [entry[:base_word]]) }
          .select { |item| buildable_from_base_word?(entry, item) }
          .shuffle
      end

      def buildable_from_base_word?(entry, exploration)
        return true if matches?(exploration[:word], [entry[:word]])

        formation = exploration[:formation].to_s.strip
        return true if formation.empty?

        normalize(formation).start_with?(normalize(entry[:base_word]))
      end

      def applicable_applications(entry)
        Array(entry[:applications])
          .select { |item| !application_answer_word(item).empty? }
          .shuffle
      end

      def application_answer_word(application)
        answer = application[:answer] || {}
        answer[:word].to_s.strip
      end

      def application_base_word(entry, application)
        application[:base_word].to_s.strip.empty? ? entry[:base_word] : application[:base_word]
      end

      def application_choices(entry, application)
        choices = Array(application[:choices]).map(&:to_s).reject(&:empty?)
        choices = valid_explorations(entry).map { |item| item[:word].to_s.strip } if choices.empty?
        choice_list(application_answer_word(application), choices)
      end

      def application_answer_exploration(entry, application)
        exploration_for(entry, application_answer_word(application))
      end

      def application_why_it_fits(application)
        explanation = application[:explanation]
        if explanation.is_a?(Hash)
          explanation[:why_it_fits].to_s.strip
        else
          explanation.to_s.strip
        end
      end

      def application_distractor_for(application, word)
        Array(application[:distractors]).find { |item| matches?(word, [item[:word]]) }
      end

      def display_application_wrong_answer(entry, application, answer)
        selected = answer.to_s.strip
        return if selected.empty?

        distractor = application_distractor_for(application, selected)
        exploration = exploration_for(entry, selected)

        output.puts "Your answer:"
        output.puts selected
        output.puts

        meaning = distractor && distractor[:meaning].to_s.strip
        meaning = exploration[:target].to_s.strip if meaning.to_s.empty? && exploration
        unless meaning.to_s.empty?
          output.puts "Meaning:"
          output.puts meaning
          output.puts
        end

        grammar_source =
          if distractor && !distractor[:grammar].empty?
            { morphology: distractor[:grammar] }
          else
            exploration
          end
        display_grammar_summary(grammar_source, description: false) if grammar_source

        why_not = distractor && distractor[:why_not].to_s.strip
        unless why_not.to_s.empty?
          output.puts "Why it does not fit:"
          output.puts why_not
          output.puts
        end
      end

      def exploration_missed_payload(entry, exploration)
        {
          mode: mode,
          word: exploration[:word],
          base_word: entry[:base_word],
          target: exploration[:target]
        }
      end

      def application_missed_payload(entry, application, answer_exploration)
        {
          mode: mode,
          word: application_answer_word(application),
          base_word: application_base_word(entry, application),
          target: application.dig(:prompt, :meaning).to_s.strip.empty? ? answer_exploration&.dig(:target) : application.dig(:prompt, :meaning)
        }
      end

      def explain_typed_miss(answer, expected, entry)
        display_expected_answer(expected, entry)
      end

      def display_expected_answer(expected, entry)
        output.puts "The expected answer was:"
        output.puts expected
        output.puts

        return unless entry && (expected_exploration = exploration_for(entry, expected))

        target = expected_exploration[:target].to_s.strip
        unless target.empty?
          output.puts "Meaning:"
          output.puts target
          output.puts
        end

        formation = expected_exploration[:formation].to_s.strip
        unless formation.empty?
          output.puts "Formation:"
          output.puts formation
          output.puts
        end

        explanation = expected_exploration[:explanation].to_s.strip
        unless explanation.empty?
          output.puts "Why:"
          output.puts explanation
          output.puts
        end
      end

      def choice_list(correct, distractors)
        ([correct] + Array(distractors)).map(&:to_s).reject(&:empty?).uniq.shuffle
      end

      def selected_choice(answer, choices)
        answer.to_s.strip
      end

      def terminal_blue(value)
        return value.to_s unless output.respond_to?(:tty?) && output.tty?

        "\e[34m#{value}\e[0m"
      end

      def terminal_cyan(value)
        return value.to_s unless output.respond_to?(:tty?) && output.tty?

        "\e[36m#{value}\e[0m"
      end

      def terminal_green(value)
        return value.to_s unless output.respond_to?(:tty?) && output.tty?

        "\e[32m#{value}\e[0m"
      end

      def terminal_red(value)
        return value.to_s unless output.respond_to?(:tty?) && output.tty?

        "\e[31m#{value}\e[0m"
      end

      def display_source_translations(entry)
        source = entry[:source] || {}
        literal = source[:literal].to_s.strip
        natural = source[:target].to_s.strip

        unless literal.empty?
          output.puts "Literal:"
          output.puts literal
          output.puts
        end

        return if natural.empty?

        output.puts "Natural language translation:"
        output.puts natural
        output.puts
      end

      def exploration_for(entry, word)
        entry[:explorations].find { |item| matches?(word, [item[:word]]) }
      end
    end
  end
end
