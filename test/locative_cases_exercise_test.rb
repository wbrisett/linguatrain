# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "yaml"
require_relative "../lib/linguatrain/locative_cases/pack"
require_relative "../lib/linguatrain/locative_cases/exercise"

class LocativeCasesExerciseTest < Minitest::Test
  EXAMPLE = File.expand_path(
    "../lib/linguatrain/locative_cases/examples/suomen_mestari_1_kappale_6_locative_cases.yaml",
    __dir__
  )

  def setup
    data = YAML.safe_load_file(EXAMPLE, aliases: false)
    items = Linguatrain::LocativeCases::Pack.normalize(entries: data.fetch("entries"))
    @item = items.find { |item| item[:id] == "train_lehtela_to_lehtela" }
  end

  def test_accepts_a_complete_sentence_on_the_first_attempt
    output = StringIO.new

    stats, missed = Linguatrain::LocativeCases::Exercise.run(
      [@item],
      input: StringIO.new("Pedro ja Hanna menevät Lehtelään katsomaan asuntoa.\n"),
      output: output
    )

    assert_equal 1, stats[:total]
    assert_equal 1, stats[:correct_first]
    assert_equal 0, stats[:correct_retry]
    assert_equal 0, stats[:revealed]
    assert_empty missed
    assert_includes output.string, "Location: Lehtelä"
    assert_includes output.string, "Pedro and Hanna go to Lehtelä to view the apartment."
    assert_includes output.string, "Lehtelään — mihin / illative / S"
  end

  def test_records_a_correct_answer_after_retry
    output = StringIO.new

    stats, missed = Linguatrain::LocativeCases::Exercise.run(
      [@item],
      input: StringIO.new("Lehtelään\nPedro ja Hanna menevät Lehtelään katsomaan asuntoa.\n"),
      output: output
    )

    assert_equal 0, stats[:correct_first]
    assert_equal 1, stats[:correct_retry]
    assert_empty missed
    assert_includes output.string, "Try again. Produce the complete Finnish sentence."
  end

  def test_progressive_hints_then_reveals_the_complete_answer
    output = StringIO.new

    stats, missed = Linguatrain::LocativeCases::Exercise.run(
      [@item],
      input: StringIO.new("h\nh\nh\nr\n"),
      output: output
    )

    text = output.string
    assert_equal 1, stats[:revealed]
    assert_equal [@item], missed

    question_hint = text.index("Hint: Ask yourself: mihin?")
    family_hint = text.index("Hint: Use the internal family (S), illative.")
    form_hint = text.index("Hint: The target form is Lehtelään.")
    answer = text.index("Answer: Pedro ja Hanna menevät Lehtelään katsomaan asuntoa.")

    refute_nil question_hint
    assert_operator question_hint, :<, family_hint
    assert_operator family_hint, :<, form_hint
    assert_operator form_hint, :<, answer
  end

  def test_quit_stops_before_the_next_item
    output = StringIO.new

    stats, = Linguatrain::LocativeCases::Exercise.run(
      [@item, @item],
      input: StringIO.new("q\n"),
      output: output
    )

    assert_equal 1, stats[:total]
    assert_equal 1, output.string.scan("Location: Lehtelä").length
  end

end
