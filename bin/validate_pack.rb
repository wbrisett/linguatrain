#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "optparse"

class PackValidator
  ISO_639_1 = /\A[a-z]{2}\z/

def initialize(path:, strict: false, warn_integer_ids: true)
  @path = path
  @strict = strict
  @warn_integer_ids = warn_integer_ids
  @errors = []
  @warnings = []
end




  def run
    data = load_yaml(@path)
    return report unless data

    validate_top_level(data)
    validate_metadata(data["metadata"]) if data.is_a?(Hash)
    validate_entries(data["entries"]) if data.is_a?(Hash)

    report
  end

  private

  def load_yaml(path)
    unless File.file?(path)
      error("File not found: #{path}")
      return nil
    end

    begin
      YAML.safe_load(File.read(path), permitted_classes: [], permitted_symbols: [], aliases: false)
    rescue Psych::SyntaxError => e
      error("YAML syntax error: #{e.message}")
      nil
    rescue StandardError => e
      error("Failed to read YAML: #{e.class}: #{e.message}")
      nil
    end
  end

  def validate_top_level(data)
    unless data.is_a?(Hash)
      if data.is_a?(Array)
        error(
          "This looks like a legacy pack format.\n" \
            "Expected the YAML file to start with `metadata:` and `entries:`, but it starts with a list.\n" \
            "To convert:\n" \
            "  1) Add a `metadata:` block at the top\n" \
            "  2) Move your list under `entries:`\n" \
            "\n" \
            "Minimal example:\n" \
            "  metadata:\n" \
            "    pack_name: \"My Pack\"\n" \
            "    version: 1\n" \
            "    source_lang: \"en\"\n" \
            "    target_lang: \"fi\"\n" \
            "  entries:\n" \
            "    - id: \"001\"\n" \
            "      prompt: \"It is cold.\"\n" \
            "      answer:\n" \
            "        - \"On kylmä.\"\n"
        )
      else
        error(
          "Invalid YAML format.\n" \
            "Expected the YAML file to start with `metadata:` and `entries:`."
        )
      end
      return
    end

    %w[metadata entries].each do |key|
      error("Missing required top-level key: #{key}. Expected `metadata:` and `entries:` at the top of the file.") unless data.key?(key)
    end

    allowed = %w[metadata entries]
    unknown = data.keys - allowed
    unknown.each { |k| warn("Unknown top-level key: #{k}") } unless unknown.empty?
  end

  def validate_metadata(meta)
    unless meta.is_a?(Hash)
      error("metadata must be a mapping (Hash). Got: #{meta.class}")
      return
    end

    required = %w[pack_name version source_lang target_lang]
    required.each do |k|
      error("metadata missing required field: #{k}") unless meta.key?(k)
    end

    # pack_name
    if meta.key?("pack_name")
      if meta["pack_name"].is_a?(String)
        warn("metadata.pack_name is empty") if meta["pack_name"].strip.empty?
      else
        error("metadata.pack_name must be a String. Got: #{meta['pack_name'].class}")
      end
    end

    # version
    if meta.key?("version")
      v = meta["version"]
      if v.is_a?(Integer)
        error("metadata.version must be >= 1") if v < 1
      else
        error("metadata.version must be an Integer. Got: #{v.class}")
      end
    end

    # source_lang / target_lang
    %w[source_lang target_lang].each do |k|
      next unless meta.key?(k)

      val = meta[k]
      if val.is_a?(String)
        if val.match?(ISO_639_1)
          # ok
        else
          error("metadata.#{k} should look like ISO 639-1 (two lowercase letters), for example 'en', 'fi'. Got: #{val.inspect}")
        end
      else
        error("metadata.#{k} must be a String. Got: #{val.class}")
      end
    end

    # optional metadata fields sanity (author, description)
    %w[author description].each do |k|
      next unless meta.key?(k)
      val = meta[k]
      if val.nil?
        warn("metadata.#{k} is nil (remove it or set a string)")
      elsif !val.is_a?(String)
        error("metadata.#{k} must be a String if present. Got: #{val.class}")
      elsif val.strip.empty?
        warn("metadata.#{k} is empty")
      end
    end
  end

  def validate_entries(entries)
    unless entries.is_a?(Array)
      error("entries must be a list (Array). Got: #{entries.class}")
      return
    end

    if entries.empty?
      warn("entries list is empty")
      return
    end

    ids = {}
    entries.each_with_index do |entry, idx|
      validate_entry(entry, idx, ids)
    end
  end

  def validate_entry(entry, idx, ids)
    unless entry.is_a?(Hash)
      error("entries[#{idx}] must be a mapping (Hash). Got: #{entry.class}")
      return
    end

    # Required fields
    %w[id prompt answer].each do |k|
      error("entries[#{idx}] missing required field: #{k}") unless entry.key?(k)
    end

    # id
    if entry.key?("id")
      id = entry["id"]
      if id.is_a?(String)
        warn("entries[#{idx}].id is empty") if id.strip.empty?
        if ids.key?(id)
          error("Duplicate id #{id.inspect} at entries[#{idx}] (already used at entries[#{ids[id]}])")
        else
          ids[id] = idx
        end
      elsif id.is_a?(Integer)
        # Allow integer ids, but normalize warning (string is nicer in YAML)
        #warn("entries[#{idx}].id is an Integer; consider quoting it as a String") if @warn_integer_ids && !@strict
        id_key = id.to_s
        if ids.key?(id_key)
          error("Duplicate id #{id.inspect} at entries[#{idx}] (already used at entries[#{ids[id_key]}])")
        else
          ids[id_key] = idx
        end
      else
        error("entries[#{idx}].id must be a String (preferred) or Integer. Got: #{id.class}")
      end
    end

    # prompt
    if entry.key?("prompt")
      p = entry["prompt"]
      if p.is_a?(String)
        warn("entries[#{idx}].prompt is empty") if p.strip.empty?
      else
        error("entries[#{idx}].prompt must be a String. Got: #{p.class}")
      end
    end

    # answer
    if entry.key?("answer")
      ans = entry["answer"]
      unless ans.is_a?(Array)
        error("entries[#{idx}].answer must be a list (Array) of Strings. Got: #{ans.class}")
        return
      end

      if ans.empty?
        error("entries[#{idx}].answer must contain at least one accepted answer")
      else
        ans.each_with_index do |a, j|
          if a.is_a?(String)
            if a.strip.empty?
              error("entries[#{idx}].answer[#{j}] is empty")
            end
          else
            error("entries[#{idx}].answer[#{j}] must be a String. Got: #{a.class}")
          end
        end
      end
    end

    # Optional fields
    validate_optional_string(entry, idx, "phonetic")
    validate_optional_string(entry, idx, "notes")

    # tags
    if entry.key?("tags")
      tags = entry["tags"]
      if tags.nil?
        warn("entries[#{idx}].tags is nil (remove it or use [] )")
      elsif tags.is_a?(Array)
        tags.each_with_index do |t, j|
          if t.is_a?(String)
            warn("entries[#{idx}].tags[#{j}] is empty") if t.strip.empty?
          else
            error("entries[#{idx}].tags[#{j}] must be a String. Got: #{t.class}")
          end
        end
      else
        error("entries[#{idx}].tags must be a list (Array) of Strings. Got: #{tags.class}")
      end
    end

    # audio
    if entry.key?("audio")
      audio = entry["audio"]
      if audio.nil?
        warn("entries[#{idx}].audio is nil (remove it)")
      elsif audio.is_a?(Hash)
        if audio.key?("tts")
          tts = audio["tts"]
          unless tts == true || tts == false
            error("entries[#{idx}].audio.tts must be true/false. Got: #{tts.inspect}")
          end
        else
          warn("entries[#{idx}].audio has no recognized keys (expected: tts)")
        end
      else
        error("entries[#{idx}].audio must be a mapping (Hash). Got: #{audio.class}")
      end
    end

    # srs
    if entry.key?("srs")
      srs = entry["srs"]
      if srs.nil?
        warn("entries[#{idx}].srs is nil (remove it)")
      elsif srs.is_a?(Hash)
        if srs.key?("difficulty")
          d = srs["difficulty"]
          if d.is_a?(Integer)
            warn("entries[#{idx}].srs.difficulty is out of typical range 1..5: #{d}") if d < 1 || d > 5
          else
            error("entries[#{idx}].srs.difficulty must be an Integer. Got: #{d.class}")
          end
        else
          warn("entries[#{idx}].srs has no recognized keys (expected: difficulty)")
        end
      else
        error("entries[#{idx}].srs must be a mapping (Hash). Got: #{srs.class}")
      end
    end

    # Strict mode: flag empty optional strings as warnings->errors
    if @strict
      %w[phonetic notes].each do |k|
        next unless entry.key?(k)
        v = entry[k]
        next unless v.is_a?(String) && v.strip.empty?
        error("entries[#{idx}].#{k} is present but empty (strict mode)")
      end
    end
  end

  def validate_optional_string(entry, idx, key)
    return unless entry.key?(key)

    v = entry[key]
    if v.nil?
      warn("entries[#{idx}].#{key} is nil (remove it or set a string)")
    elsif v.is_a?(String)
      warn("entries[#{idx}].#{key} is empty") if v.strip.empty?
    else
      error("entries[#{idx}].#{key} must be a String if present. Got: #{v.class}")
    end
  end

  def error(msg) = @errors << msg
  def warn(msg) = @warnings << msg

  def report
    puts "Linguatrain pack validation: #{@path}"
    puts

    print_messages("Warnings", @warnings) if @warnings.any?
    print_messages("Errors", @errors) if @errors.any?

    errors_count = @errors.size
    warnings_count = @warnings.size

    if errors_count.positive?
      puts "Result: FAIL (#{errors_count} errors, #{warnings_count} warnings)"
      1
    else
      puts "Result: PASS (#{errors_count} errors, #{warnings_count} warnings)"
      0
    end
  end

  def print_messages(label, messages)
    puts "#{label} (#{messages.size}):"

    messages.each do |msg|
      lines = msg.to_s.split("\n")
      first = lines.shift
      puts "  - #{first}"
      lines.each { |line| puts "    #{line}" }
      puts
    end
  end
end

options = { strict: false, all: nil }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: validate_pack.rb [options] path/to/pack.yaml"

  opts.on("--strict", "Treat some warnings as errors (stricter hygiene)") do
    options[:strict] = true
  end

  opts.on("-aDIR", "--all=DIR", "Validate all .yaml/.yml files under DIR (recursively)") do |dir|
    options[:all] = dir
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

begin
  parser.parse!
rescue OptionParser::InvalidOption => e
  warn e.message
  puts parser
  exit 2
end

if options[:all]
  root = options[:all]
  unless Dir.exist?(root)
    warn "Directory not found: #{root}"
    exit 2
  end

  files = Dir.glob(File.join(root, "**", "*.{yaml,yml}"), File::FNM_EXTGLOB).sort
  if files.empty?
    warn "No .yaml/.yml files found under: #{root}"
    exit 2
  end

  total_files = files.size
  failed_files = 0

  files.each_with_index do |file, i|
    puts "=== [#{i + 1}/#{total_files}] #{file} ==="
    code = PackValidator.new(path: file, strict: options[:strict]).run
    failed_files += 1 if code != 0
    puts
  end

  if failed_files.positive?
    puts "Overall: FAIL (#{failed_files}/#{total_files} files failed)"
    exit 1
  else
    puts "Overall: PASS (#{total_files} files checked)"
    exit 0
  end
else
  path = ARGV[0]
  if path.nil? || path.strip.empty?
    puts parser
    exit 2
  end

  exit_code = PackValidator.new(path: path, strict: options[:strict]).run
  exit exit_code
end