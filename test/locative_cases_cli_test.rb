# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"

class LocativeCasesCliTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "linguatrain.rb")
  EXAMPLE = File.join(
    ROOT,
    "lib",
    "linguatrain",
    "locative_cases",
    "examples",
    "suomen_mestari_1_kappale_6_locative_cases.yaml"
  )

  def test_runs_the_example_through_the_real_cli
    stdout, stderr, status = run_cli(
      EXAMPLE,
      "all",
      "--locative-cases",
      stdin_data: "Juna menee Lehtelään.\nJuna on Lehtelässä.\nJuna lähtee Lehtelästä.\n"
    )

    assert status.success?, stderr
    assert_empty stderr
    assert_includes stdout, "Locative Cases — 3 question(s)"
    assert_includes stdout, "Results from suomen_mestari_1_kappale_6_locative_cases"
    assert_includes stdout, "Correct 1st: 3 (100.0%)"
    assert_includes stdout, "Revealed: 0 (0.0%)"
  end

  def test_requires_the_mode_flag_for_a_locative_cases_pack
    _stdout, stderr, status = run_cli(EXAMPLE)

    refute status.success?
    assert_includes stderr, "This pack is a Locative Cases pack. Use --locative-cases."
  end

  def test_rejects_lenient_diacritics_with_an_explanation
    _stdout, stderr, status = run_cli(EXAMPLE, "--locative-cases", "--lenient-umlauts")

    refute status.success?
    assert_includes stderr, "--lenient-umlauts is not supported with --locative-cases"
    assert_includes stderr, "diacritics can change meaning and grammatical form"
  end

  def test_count_limits_the_number_of_productions
    stdout, stderr, status = run_cli(
      EXAMPLE,
      "1",
      "--locative-cases",
      stdin_data: "Juna menee Lehtelään.\n"
    )

    assert status.success?, stderr
    assert_includes stdout, "Locative Cases — 1 question(s)"
    assert_includes stdout, "Total: 1"
  end

  def test_filters_by_question
    stdout, stderr, status = run_cli(
      EXAMPLE,
      "all",
      "--locative-cases",
      "--locative-question",
      "mistä",
      stdin_data: "Juna lähtee Lehtelästä.\n"
    )

    assert status.success?, stderr
    assert_includes stdout, "Locative Cases — 1 question(s)"
    assert_includes stdout, "A train leaves from Lehtelä."
    refute_includes stdout, "A train goes to Lehtelä."
  end

  def test_combines_case_and_family_filters
    stdout, stderr, status = run_cli(
      EXAMPLE,
      "all",
      "--locative-cases",
      "--locative-case",
      "inessive",
      "--locative-family",
      "S",
      stdin_data: "Juna on Lehtelässä.\n"
    )

    assert status.success?, stderr
    assert_includes stdout, "A train is in Lehtelä."
    assert_includes stdout, "Correct 1st: 1 (100.0%)"
  end

  def test_reports_when_filters_match_nothing
    _stdout, stderr, status = run_cli(
      EXAMPLE,
      "--locative-cases",
      "--locative-family",
      "L"
    )

    refute status.success?
    assert_includes stderr, "No locative-case productions match the requested filters"
    assert_includes stderr, "family=L"
  end

  def test_filter_options_require_locative_cases_mode
    _stdout, stderr, status = run_cli(EXAMPLE, "--locative-case", "illative")

    refute status.success?
    assert_includes stderr, "require --locative-cases"
  end

  private

  def run_cli(*arguments, stdin_data: "")
    Open3.capture3(
      RbConfig.ruby,
      CLI,
      *arguments,
      "--config",
      File::NULL,
      stdin_data: stdin_data,
      chdir: ROOT
    )
  end
end
