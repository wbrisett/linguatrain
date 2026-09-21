# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tempfile"
require "yaml"

class LocativeCasesValidatorTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  VALIDATOR = File.join(ROOT, "bin", "validate_pack.rb")
  EXAMPLE = File.join(
    ROOT,
    "lib",
    "linguatrain",
    "locative_cases",
    "examples",
    "suomen_mestari_1_kappale_6_locative_cases.yaml"
  )

  def test_accepts_the_example_pack
    stdout, stderr, status = run_validator("--locative-cases", EXAMPLE)

    assert status.success?, "#{stdout}\n#{stderr}"
    assert_empty stderr
    assert_includes stdout, "Result: PASS (0 errors, 0 warnings)"
  end

  def test_detects_a_case_that_does_not_match_family_and_question
    data = YAML.safe_load_file(EXAMPLE, aliases: false)
    data.fetch("entries").first.fetch("productions").first["case"] = "allative"

    Tempfile.create(["invalid_locative_cases", ".yaml"]) do |file|
      file.write(YAML.dump(data))
      file.flush

      stdout, _stderr, status = run_validator("--locative-cases", file.path)

      refute status.success?
      assert_includes stdout, 'case must be "illative" for S/mihin'
    end
  end

  def test_detects_an_inconsistent_family_code
    data = YAML.safe_load_file(EXAMPLE, aliases: false)
    data.fetch("entries").first["family_code"] = "L"

    Tempfile.create(["invalid_locative_family", ".yaml"]) do |file|
      file.write(YAML.dump(data))
      file.flush

      stdout, _stderr, status = run_validator(file.path)

      refute status.success?
      assert_includes stdout, 'family_code must be "S" for family "internal"'
    end
  end

  private

  def run_validator(*arguments)
    Open3.capture3(RbConfig.ruby, VALIDATOR, *arguments, chdir: ROOT)
  end
end
