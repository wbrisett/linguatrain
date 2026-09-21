# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/linguatrain/locative_cases/scorer"

class LocativeCasesScorerTest < Minitest::Test
  ITEM = {
    answers: ["Juna menee Lehtelään."]
  }.freeze

  def test_accepts_a_complete_sentence_with_normalized_case_and_punctuation
    result = Linguatrain::LocativeCases::Scorer.new.score(
      "  JUNA menee Lehtelään!  ",
      ITEM
    )

    assert result[:correct]
    assert_equal "Juna menee Lehtelään.", result[:matched_answer]
  end

  def test_rejects_only_the_target_form
    result = Linguatrain::LocativeCases::Scorer.new.score("Lehtelään", ITEM)

    refute result[:correct]
  end

  def test_requires_diacritics_by_default
    result = Linguatrain::LocativeCases::Scorer.new.score("Juna menee Lehtelaan.", ITEM)

    refute result[:correct]
  end

  def test_does_not_offer_a_lenient_diacritic_mode
    assert_raises(ArgumentError) do
      Linguatrain::LocativeCases::Scorer.new(lenient: true)
    end
  end
end
