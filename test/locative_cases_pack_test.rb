# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require_relative "../lib/linguatrain/locative_cases/pack"

class LocativeCasesPackTest < Minitest::Test
  EXAMPLE = File.expand_path(
    "../lib/linguatrain/locative_cases/examples/suomen_mestari_1_kappale_6_locative_cases.yaml",
    __dir__
  )

  def setup
    data = YAML.safe_load_file(EXAMPLE, aliases: false)
    @items = Linguatrain::LocativeCases::Pack.normalize(entries: data.fetch("entries"))
  end

  def test_flattens_grouped_productions_into_practice_items
    assert_equal 3, @items.length
    assert_equal %w[illative inessive elative], @items.map { |item| item[:case] }
    assert_equal %w[mihin missä mistä], @items.map { |item| item[:question] }
    assert_equal %w[Lehtelään Lehtelässä Lehtelästä], @items.map { |item| item[:target_form] }
  end

  def test_carries_shared_entry_context_into_each_practice_item
    @items.each do |item|
      assert_equal "train_lehtela", item[:group_id]
      assert_equal "Lehtelä", item[:lemma]
      assert_equal "internal", item[:family]
      assert_equal "S", item[:family_code]
      assert_equal "Lehtelästä menee juna keskustaan.", item.dig(:source, :text)
    end
  end

  def test_builds_stable_ids_from_the_group_and_production_ids
    assert_equal(
      %w[train_lehtela_to_lehtela train_lehtela_in_lehtela train_lehtela_from_lehtela],
      @items.map { |item| item[:id] }
    )
  end

  def test_preserves_complete_sentence_prompts_and_answers
    first = @items.first

    assert_equal "A train goes to Lehtelä.", first[:prompt]
    assert_equal ["Juna menee Lehtelään."], first[:answers]
  end

  def test_filters_by_question_case_and_family
    assert_equal ["illative"], filter(questions: ["MIHIN"]).map { |item| item[:case] }
    assert_equal ["missä"], filter(cases: ["inessive"]).map { |item| item[:question] }
    assert_equal 3, filter(families: ["s"]).length
    assert_equal 3, filter(families: ["INTERNAL"]).length
  end

  def test_repeated_values_within_one_filter_are_alternatives
    selected = filter(questions: ["mihin", "mistä"])

    assert_equal %w[illative elative], selected.map { |item| item[:case] }
  end

  def test_different_filter_dimensions_are_combined
    assert_empty filter(questions: ["mihin"], cases: ["elative"])
  end

  def test_rejects_an_entry_without_productions
    error = assert_raises(RuntimeError) do
      Linguatrain::LocativeCases::Pack.normalize(
        entries: [
          {
            "id" => "broken",
            "lemma" => "talo",
            "family" => "internal",
            "family_code" => "S",
            "productions" => []
          }
        ]
      )
    end

    assert_includes error.message, "productions must be a non-empty list"
  end

  def test_rejects_a_scalar_answer
    error = assert_raises(RuntimeError) do
      Linguatrain::LocativeCases::Pack.normalize(
        entries: [
          {
            "id" => "house",
            "lemma" => "talo",
            "family" => "internal",
            "family_code" => "S",
            "productions" => [
              {
                "id" => "into_house",
                "question" => "mihin",
                "case" => "illative",
                "prompt" => "I go into the house.",
                "answer" => "Menen taloon.",
                "target_form" => "taloon"
              }
            ]
          }
        ]
      )
    end

    assert_includes error.message, "answer must be a list"
  end

  private

  def filter(**criteria)
    Linguatrain::LocativeCases::Pack.filter(@items, **criteria)
  end
end
