# frozen_string_literal: true

module Linguatrain
  module LocativeCases
    class Pack
      def self.normalize(entries:)
        new(entries: entries).normalize
      end

      def self.filter(items, questions: [], cases: [], families: [])
        requested_questions = normalize_filter_values(questions)
        requested_cases = normalize_filter_values(cases)
        requested_families = normalize_filter_values(families)

        Array(items).select do |item|
          question_matches = requested_questions.empty? || requested_questions.include?(normalize_filter_value(item[:question]))
          case_matches = requested_cases.empty? || requested_cases.include?(normalize_filter_value(item[:case]))
          family_values = [item[:family], item[:family_code]].map { |value| normalize_filter_value(value) }
          family_matches = requested_families.empty? || requested_families.any? { |value| family_values.include?(value) }

          question_matches && case_matches && family_matches
        end
      end

      def self.normalize_filter_values(values)
        Array(values).map { |value| normalize_filter_value(value) }.reject(&:empty?).uniq
      end

      def self.normalize_filter_value(value)
        value.to_s.unicode_normalize(:nfc).strip.downcase
      end

      private_class_method :normalize_filter_values, :normalize_filter_value

      def initialize(entries:)
        @entries = entries
      end

      def normalize
        unless entries.is_a?(Array)
          raise "Invalid locative cases pack: entries must be a list"
        end

        entries.flat_map.with_index do |entry, entry_index|
          normalize_entry(entry, entry_index)
        end
      end

      private

      attr_reader :entries

      def normalize_entry(entry, entry_index)
        invalid_entry!(entry_index, "must be a mapping") unless entry.is_a?(Hash)

        entry_id = required_string(entry, "id", entry_index)
        lemma = required_string(entry, "lemma", entry_index)
        family = required_string(entry, "family", entry_index)
        family_code = required_string(entry, "family_code", entry_index)
        productions = value(entry, "productions")

        unless productions.is_a?(Array) && !productions.empty?
          invalid_entry!(entry_index, "productions must be a non-empty list")
        end

        source = normalize_source(value(entry, "source"), entry_index)

        productions.map.with_index do |production, production_index|
          normalize_production(
            production,
            entry_index: entry_index,
            production_index: production_index,
            entry_id: entry_id,
            lemma: lemma,
            family: family,
            family_code: family_code,
            source: source
          )
        end
      end

      def normalize_production(production, entry_index:, production_index:, entry_id:, lemma:, family:, family_code:, source:)
        label = "entry #{entry_id.inspect}, production #{production_index + 1}"
        raise "Invalid locative cases #{label}: must be a mapping" unless production.is_a?(Hash)

        production_id = required_production_string(production, "id", label)
        question = required_production_string(production, "question", label)
        grammatical_case = required_production_string(production, "case", label)
        prompt = required_production_string(production, "prompt", label)
        target_form = required_production_string(production, "target_form", label)
        answers = normalize_answers(value(production, "answer"), label)

        {
          id: "#{entry_id}_#{production_id}",
          group_id: entry_id,
          production_id: production_id,
          lemma: lemma,
          family: family,
          family_code: family_code,
          question: question,
          case: grammatical_case,
          prompt: prompt,
          answers: answers,
          target_form: target_form,
          explanation: optional_string(production, "explanation"),
          source: source,
          position: {
            entry: entry_index,
            production: production_index
          }
        }
      end

      def normalize_answers(raw, label)
        unless raw.is_a?(Array)
          raise "Invalid locative cases #{label}: answer must be a list"
        end

        answers = raw.map { |answer| answer.to_s.strip }.reject(&:empty?)
        raise "Invalid locative cases #{label}: answer must contain at least one sentence" if answers.empty?

        answers
      end

      def normalize_source(raw, entry_index)
        return {} if raw.nil?
        invalid_entry!(entry_index, "source must be a mapping") unless raw.is_a?(Hash)

        {
          text: optional_string(raw, "text"),
          reference: optional_string(raw, "reference")
        }
      end

      def required_string(hash, key, entry_index)
        text = optional_string(hash, key)
        invalid_entry!(entry_index, "#{key} must be a non-empty string") if text.empty?
        text
      end

      def required_production_string(hash, key, label)
        text = optional_string(hash, key)
        raise "Invalid locative cases #{label}: #{key} must be a non-empty string" if text.empty?
        text
      end

      def optional_string(hash, key)
        raw = value(hash, key)
        raw.nil? ? "" : raw.to_s.strip
      end

      def value(hash, key)
        hash[key] || hash[key.to_sym]
      end

      def invalid_entry!(entry_index, message)
        raise "Invalid locative cases entry #{entry_index + 1}: #{message}"
      end
    end
  end
end
