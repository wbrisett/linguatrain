# frozen_string_literal: true

module Linguatrain
  module WordExplorer
    class Pack
      ORIGINS = %w[source generated].freeze
      STATUSES = %w[valid limited unsuitable].freeze

      def self.normalize(entries:, grammar:)
        new(entries: entries, grammar: grammar).normalize
      end

      def initialize(entries:, grammar:)
        @entries = entries
        @grammar = grammar
      end

      def normalize
        {
          grammar: normalize_grammar,
          entries: normalize_entries
        }
      end

      private

      attr_reader :entries, :grammar

      def normalize_grammar
        Array(grammar).filter_map do |item|
          next unless item.is_a?(Hash)

          key = string_value(item, "key")
          next if key.empty?

          {
            key: key,
            name: string_value(item, "name"),
            plain_english: string_value(item, "plain_english"),
            description: string_value(item, "description")
          }
        end
      end

      def normalize_entries
        Array(entries).map.with_index do |entry, idx|
          raise "Invalid word explorer entry: #{entry.inspect}" unless entry.is_a?(Hash)

          word = string_value(entry, "word")
          base_word = string_value(entry, "base_word")
          target = string_value(entry, "target")
          morphology = hash_value(entry, "morphology")

          if word.empty? || base_word.empty? || target.empty? || morphology.empty?
            raise "Invalid word explorer entry: #{entry.inspect}"
          end

          {
            id: string_value(entry, "id", fallback: format("m%03d", idx + 1)),
            source: normalize_source(hash_value(entry, "source")),
            word: word,
            base_word: base_word,
            type: string_value(entry, "type"),
            target: target,
            morphology: stringify_hash(morphology),
            hint: string_value(entry, "hint"),
            formation: string_value(entry, "formation"),
            explanation: string_value(entry, "explanation"),
            role: string_value(entry, "role"),
            explorations: normalize_explorations(entry["explorations"] || entry[:explorations]),
            applications: normalize_applications(entry["applications"] || entry[:applications]),
            vocabulary_ref: string_value(entry, "vocabulary_ref"),
            grammar_refs: string_list(entry["grammar_refs"] || entry[:grammar_refs])
          }
        end
      end

      def normalize_source(source)
        return {} if source.empty?

        {
          entry_id: string_value(source, "entry_id"),
          chunk_id: string_value(source, "chunk_id"),
          text: string_value(source, "text"),
          literal: string_value(source, "literal"),
          target: string_value(source, "target")
        }
      end

      def normalize_explorations(raw)
        Array(raw).filter_map do |item|
          next unless item.is_a?(Hash)

          word = string_value(item, "word")
          target = string_value(item, "target")
          morphology = hash_value(item, "morphology")
          next if word.empty? || target.empty?

          origin = string_value(item, "origin", fallback: "generated")
          status = string_value(item, "status", fallback: "valid")

          origin = "generated" unless ORIGINS.include?(origin)
          status = "valid" unless STATUSES.include?(status)

          {
            word: word,
            target: target,
            morphology: stringify_hash(morphology),
            formation: string_value(item, "formation"),
            explanation: string_value(item, "explanation"),
            origin: origin,
            status: status,
            usage_note: string_value(item, "usage_note"),
            priority: string_value(item, "priority")
          }
        end
      end

      def normalize_applications(raw)
        Array(raw).filter_map do |item|
          next unless item.is_a?(Hash)

          answer = normalize_application_answer(hash_value(item, "answer"))
          next if answer[:word].empty?

          {
            id: string_value(item, "id"),
            type: string_value(item, "type", fallback: "contextual_choice"),
            reasoning: stringify_hash(hash_value(item, "reasoning")),
            source: normalize_source(hash_value(item, "source")),
            prompt: normalize_application_prompt(hash_value(item, "prompt")),
            base_word: string_value(item, "base_word"),
            answer: answer,
            choices: string_list(item["choices"] || item[:choices]),
            grammar_refs: string_list(item["grammar_refs"] || item[:grammar_refs]),
            explanation: normalize_application_explanation(item["explanation"] || item[:explanation]),
            distractors: normalize_application_distractors(item["distractors"] || item[:distractors])
          }
        end
      end

      def normalize_application_explanation(raw)
        if raw.is_a?(Hash)
          {
            why_it_fits: string_value(raw, "why_it_fits")
          }
        else
          {
            why_it_fits: raw.to_s.strip
          }
        end
      end

      def normalize_application_distractors(raw)
        Array(raw).filter_map do |item|
          next unless item.is_a?(Hash)

          word = string_value(item, "word")
          next if word.empty?

          {
            word: word,
            grammar: stringify_hash(hash_value(item, "grammar")),
            meaning: string_value(item, "meaning"),
            why_not: string_value(item, "why_not")
          }
        end
      end

      def normalize_application_prompt(prompt)
        return {} if prompt.empty?

        {
          text: string_value(prompt, "text"),
          meaning: string_value(prompt, "meaning")
        }
      end

      def normalize_application_answer(answer)
        {
          word: string_value(answer, "word")
        }
      end

      def hash_value(hash, key)
        value = hash[key] || hash[key.to_sym]
        value.is_a?(Hash) ? value : {}
      end

      def string_value(hash, key, fallback: "")
        value = hash[key] || hash[key.to_sym]
        value = fallback if value.nil?
        value.to_s.strip
      end

      def string_list(value)
        Array(value).map { |item| item.to_s.strip }.reject(&:empty?)
      end

      def stringify_hash(hash)
        hash.each_with_object({}) do |(key, value), out|
          out[key.to_s] =
            if value.is_a?(Hash)
              stringify_hash(value)
            elsif value.is_a?(Array)
              value.map { |item| item.is_a?(Hash) ? stringify_hash(item) : item.to_s.strip }
            elsif value.nil?
              ""
            else
              value.to_s.strip
            end
        end
      end
    end
  end
end
