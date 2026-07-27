# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../lib/linguatrain/translation/exercise"
require_relative "../lib/linguatrain/translation/scorer"

class TranslationGuidedTest < Minitest::Test
  def setup
    @entry = {
      "id" => "scene_01_cafe",
      "source" => "Top left: What are they doing?",
      "target" => "He juovat kahvia. He puhuvat.",
      "chunks" => [
        {
          "id" => "drink_coffee",
          "source" => "They drink coffee.",
          "targets" => ["He juovat kahvia."],
          "guidance" => {
            "components" => [
              { "role" => "subject", "form" => "He", "meaning" => "they" },
              { "role" => "verb", "lemma" => "juoda", "form" => "juovat", "person" => "third", "number" => "plural", "build" => "juo- + -vat → juovat", "hints" => ["Use the third-person plural ending -vat."] },
              { "role" => "object", "lemma" => "kahvi", "form" => "kahvia", "case" => "partitive", "hints" => ["Use the partitive singular ending -a."] }
            ],
            "hints" => [
              "They drink coffee.",
              "Base verb: juoda.",
              "Subject: he; use third-person plural.",
              "Use the third-person plural ending -vat."
            ]
          }
        },
        {
          "id" => "talk",
          "source" => "They talk.",
          "targets" => ["He puhuvat."],
          "guidance" => {
            "components" => [
              { "role" => "subject", "form" => "He", "meaning" => "they" },
              { "role" => "verb", "lemma" => "puhua", "form" => "puhuvat", "person" => "third", "number" => "plural", "build" => "puhu- + -vat → puhuvat", "hints" => ["Use the third-person plural ending -vat."] }
            ],
            "hints" => ["They talk.", "Base verb: puhua."]
          }
        }
      ]
    }
    @scorer = Linguatrain::Translation::Scorer.new
  end

  def test_scorer_distinguishes_near_match_from_missing_action
    result = @scorer.score("he jovat kahvia", @entry)

    assert_equal %i[near missing], result[:matches].map { |match| match[:status] }
    assert_equal "jovat", result[:matches].first.dig(:corrections, 0, :actual)
    assert_equal "juovat", result[:matches].first.dig(:corrections, 0, :expected)
    assert_equal 1, result[:matches].first.dig(:corrections, 0, :distance)
    assert_equal 0, result[:correct]
  end

  def test_scorer_recognizes_two_independent_one_letter_misspellings
    result = @scorer.score("he jovat kavia", @entry)
    coffee = result[:matches].first

    assert_equal :near, coffee[:status]
    assert_equal [%w[jovat juovat], %w[kavia kahvia]], coffee[:corrections].map { |correction| [correction[:actual], correction[:expected]] }
    assert_equal [1, 1], coffee[:corrections].map { |correction| correction[:distance] }
    assert_equal :missing, result[:matches].last[:status]
  end

  def test_completed_action_words_are_not_reused_as_a_fuzzy_match
    coffee_only = @scorer.score("he juovat kahvia", @entry)
    talk_only = @scorer.score("he puhuvat", @entry)

    assert_equal %i[correct missing], coffee_only[:matches].map { |match| match[:status] }
    assert_equal %i[missing correct], talk_only[:matches].map { |match| match[:status] }
  end

  def test_completed_first_action_moves_to_second_without_error_feedback
    input = StringIO.new("he juovat kahvia\nq\n")
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :quit, result
    assert_includes output.string, "✓ They drink coffee. : He juovat kahvia."
    assert_includes output.string, "○ They talk. — not answered yet"
    assert_includes output.string, "Let’s finish the remaining action."
    refute_includes output.string, "△ They talk. — almost correct"
    refute_includes output.string, "You wrote: juovat"
  end

  def test_separately_entered_correct_actions_both_count_as_independent
    input = StringIO.new("he puhuvat\nhe juovat kahvia\n")
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :complete, result
    assert_includes output.string, "Correct independently: 2"
    assert_includes output.string, "Correct after guidance: 0"
    assert_includes output.string, "Answers revealed: 0"
  end

  def test_corrected_word_completes_action_and_summary_lists_each_action
    input = StringIO.new(<<~ANSWERS)
      he puhuvat
      he juovat kavia
      kahvia
      he juovat kahvia
    ANSWERS
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :complete, result
    assert_includes output.string, "You wrote: kavia\n- Base noun: kahvi\n- Required case: partitive"
    assert_includes output.string, "Correct this word in Finnish:"
    assert_includes output.string, "✅ kahvia"
    assert_includes output.string, "Now write the complete sentence (action) in Finnish:"
    assert_includes output.string, "✅ He juovat kahvia."

    completed = <<~COMPLETED.chomp
      Completed:
      ✓ They drink coffee. : He juovat kahvia.
      ✓ They talk. : He puhuvat.
    COMPLETED
    assert_includes output.string, completed
  end

  def test_corrected_verb_word_completes_the_action
    input = StringIO.new(<<~ANSWERS)
      he juovat kahvia
      he puhavat
      puhuvat
      he puhuvat
    ANSWERS
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :complete, result
    assert_includes output.string, "You wrote: puhavat"
    assert_includes output.string, "Correct this word in Finnish:"
    assert_includes output.string, "✅ puhuvat"
    assert_includes output.string, "Now write the complete sentence (action) in Finnish:"
    assert_includes output.string, "✅ He puhuvat."
  end

  def test_known_verb_is_recognized_before_a_complete_action_has_been_found
    entry = {
      "source" => "What are they doing?",
      "target" => "He ostavat jäätelöä.",
      "chunks" => [
        {
          "id" => "buy_ice_cream",
          "source" => "They buy ice cream.",
          "targets" => ["He ostavat jäätelöä."],
          "guidance" => {
            "components" => [
              { "role" => "subject", "form" => "He" },
              { "role" => "verb", "lemma" => "ostaa", "form" => "ostavat", "person" => "third", "number" => "plural" },
              { "role" => "object", "lemma" => "jäätelö", "form" => "jäätelöä", "case" => "partitive" }
            ]
          }
        }
      ]
    }
    input = StringIO.new("he ostavat\nostaavat\nostavat\nhe ostavat jäätelöä\n")
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :complete, result
    assert_includes output.string, "✅ ostavat"
    assert_includes output.string, "✅ he ostavat"
    assert_includes output.string, "Now write the complete sentence (action) in Finnish:"
    assert_includes output.string, "✅ He ostavat jäätelöä."
  end

  def test_progressive_guidance_repairs_near_match_then_requests_missing_action
    input = StringIO.new(<<~ANSWERS)
      he jovat kahvia
      juovat
      he juovat kahvia
      h
      he puhuvat
    ANSWERS
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_equal :complete, result
    assert_includes output.string, "△ They drink coffee. — almost correct"
    assert_includes output.string, "○ They talk. — not answered yet"
    assert_includes output.string, "You wrote: jovat"
    assert_includes output.string, "Base verb: juoda"
    assert_includes output.string, "Required form: third-person plural"
    assert_includes output.string, "Hint: They talk."
    assert_includes output.string, "Correct independently: 0"
    assert_includes output.string, "Correct after guidance: 2"
  end

  def test_wrong_person_form_uses_authored_verb_guidance
    input = StringIO.new(<<~ANSWERS)
      he juo kahvia he puhuvat
      juovat
      he juovat kahvia
    ANSWERS
    output = StringIO.new

    Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_includes output.string, "You wrote: juo"
    assert_includes output.string, "Base verb: juoda"
    refute_includes output.string.split("Correct this word in Finnish:").first, "juovat"
    assert_includes output.string, "Correct independently: 1"
    assert_includes output.string, "Correct after guidance: 1"
  end

  def test_guidance_reports_each_misspelled_component
    input = StringIO.new(<<~ANSWERS)
      he talk
      he jovat kavia
      juovat
      kahvia
      he juovat kahvia
      he puhuvat
    ANSWERS
    output = StringIO.new

    Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_includes output.string, "You wrote: jovat"
    assert_includes output.string, "Base verb: juoda"
    assert_includes output.string, "You wrote: kavia"
    assert_includes output.string, "Base noun: kahvi"
    assert_includes output.string, "Required case: partitive"
    diagnostic = output.string.split("Correct this word in Finnish:").first
    refute_includes diagnostic, "juovat"
    refute_includes diagnostic, "kahvia"
    assert_includes output.string, "Correct independently: 1"
    assert_includes output.string, "Correct after guidance: 1"
  end

  def test_standard_translation_flow_is_unchanged_without_guidance
    input = StringIO.new("He juovat kahvia. He puhuvat.\nq\n")
    output = StringIO.new

    result = Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output
    )

    assert_equal :quit, result
    assert_includes output.string, "Results"
    refute_includes output.string, "Guided results"
  end

  def test_progressive_hints_do_not_reveal_corrected_surface_forms
    input = StringIO.new(<<~ANSWERS)
      he talk
      h
      h
      h
      h
      h
      q
    ANSWERS
    output = StringIO.new

    Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    refute_includes output.string, "juovat"
    refute_includes output.string, "kahvia"
    assert_includes output.string, "Base verb: juoda."
    assert_includes output.string, "Use the third-person plural ending -vat."
    assert_includes output.string, "No more hints are available. Type s to reveal the answer."
  end

  def test_retry_hints_follow_only_the_remaining_incorrect_component
    input = StringIO.new(<<~ANSWERS)
      he jovat kavia
      juovat
      h
      q
    ANSWERS
    output = StringIO.new

    Linguatrain::Translation::Exercise.run(
      [@entry],
      scorer: @scorer,
      input: input,
      output: output,
      guidance: "progressive"
    )

    assert_match(/✅ juovat\nAlmost correct:\n  You wrote: kavia/, output.string)
    assert_includes output.string, "Hint: Use the partitive singular ending -a."
    refute_includes output.string, "Hint: They drink coffee."
    refute_includes output.string, "Hint: Base verb: juoda."
  end
end
