#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "optparse"
require "fileutils"

def die(msg, code = 1)
  warn msg
  exit code
end

options = {
  pack_name: nil,
  source_lang: "en",
  target_lang: "fi",
  author: nil,
  description: nil,
  version: 1,
  out: nil,
  in_place: false,
  batch: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: convert_legacy_pack.rb [options] path/to/legacy_pack.yaml"

  opts.on("--pack-name=NAME", "Name of the pack") do |v|
    options[:pack_name] = v
  end

  opts.on("--source-lang=CODE", "Source language (ISO 639-1), default: en") do |v|
    options[:source_lang] = v
  end

  opts.on("--target-lang=CODE", "Target language (ISO 639-1), default: fi") do |v|
    options[:target_lang] = v
  end

  opts.on("--author=NAME", "Author name") do |v|
    options[:author] = v
  end

  opts.on("--description=TEXT", "Description") do |v|
    options[:description] = v
  end

  opts.on("--version=NUM", Integer, "Version number (integer), default: 1") do |v|
    options[:version] = v
  end

  opts.on("-oFILE", "--out=FILE", "Output file path") do |v|
    options[:out] = v
  end

  opts.on("--in-place", "Overwrite input file (creates .bak backup)") do
    options[:in_place] = true
  end

  opts.on("--batch=DIR", "Convert all legacy YAML files under DIR (recursively)") do |v|
    options[:batch] = v
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

def yaml_files_under(dir)
  Dir.glob(File.join(dir, "**", "*.{yaml,yml}"), File::FNM_EXTGLOB).sort
end

def compute_out_path(in_path, batch_root, out_opt)
  return nil if out_opt.nil?

  if batch_root
    # Treat --out as an output directory in batch mode.
    out_dir = out_opt
    rel = in_path.sub(/^#{Regexp.escape(batch_root)}\/?/, "")
    File.join(out_dir, rel)
  else
    out_opt
  end
end

def normalize_legacy_entry(entry)
  entry = entry.transform_keys(&:to_s)

  # Legacy key mapping
  prompt = entry["prompt"] || entry["english"] || entry["en"]

  answer = entry["answer"] || entry["finnish"] || entry["fi"]

  phonetic = entry["phonetic"] || entry["phon"]

  acceptable = entry["alternate_prompts"] || entry["acceptable_answers"]

  [prompt, answer, phonetic, acceptable, entry]
end

def convert_one_file(in_path, options, batch_root: nil)
  die("Input file not found: #{in_path}", 2) unless File.file?(in_path)

  begin
    legacy_data = YAML.safe_load(File.read(in_path), permitted_classes: [], permitted_symbols: [], aliases: false)
  rescue Psych::SyntaxError => e
    die("YAML syntax error in #{in_path}: #{e.message}", 2)
  end

  unless legacy_data.is_a?(Array)
    die("Legacy pack file must start with a YAML list. File: #{in_path}", 2)
  end

  entries = legacy_data.map.with_index do |raw_entry, idx|
    unless raw_entry.is_a?(Hash)
      die("Entry at index #{idx} is not an object/map. File: #{in_path}", 2)
    end

    prompt, answer, phonetic, acceptable, entry = normalize_legacy_entry(raw_entry)

    die("Entry at index #{idx} is missing an English prompt (expected: prompt, english, or en). File: #{in_path}", 2) unless prompt.is_a?(String) && !prompt.strip.empty?
    die("Entry at index #{idx} is missing a target answer (expected: answer, finnish, or fi). File: #{in_path}", 2) if answer.nil? || answer.to_s.strip.empty?

    # Ensure id is present, or generate one
    id = entry["id"]
    id = format("%03d", idx + 1) if id.nil?
    id = id.to_s if id.is_a?(Integer)
    die("Entry id at index #{idx} must be a String or Integer. File: #{in_path}", 2) unless id.is_a?(String)

    # Normalize answer to Array<String>
    if answer.is_a?(String)
      answer = [answer]
    elsif answer.is_a?(Array)
      answer.each do |a|
        die("Entry answer elements at index #{idx} must be Strings. File: #{in_path}", 2) unless a.is_a?(String)
      end
    else
      die("Entry answer at index #{idx} must be a String or list of Strings. File: #{in_path}", 2)
    end

    new_entry = {
      "id" => id,
      "prompt" => prompt,
      "answer" => answer
    }

    # acceptable_answers -> alternate_prompts (source-language variants)
    if acceptable
      unless acceptable.is_a?(Array)
        die("acceptable_answers at index #{idx} must be a list of Strings. File: #{in_path}", 2)
      end

      alts = acceptable.map { |s| s.to_s.strip }.reject(&:empty?).uniq
      alts.reject! { |s| s == prompt.strip }
      new_entry["alternate_prompts"] = alts unless alts.empty?
    end

    new_entry["phonetic"] = phonetic if phonetic.is_a?(String) && !phonetic.strip.empty?

    # Pass through known optional fields if they exist already in legacy form
    %w[notes tags audio srs].each do |key|
      new_entry[key] = entry[key] if entry.key?(key)
    end

    new_entry
  end

  out = {
    "metadata" => {
      "pack_name" => options[:pack_name],
      "version" => options[:version],
      "source_lang" => options[:source_lang],
      "target_lang" => options[:target_lang]
    },
    "entries" => entries
  }

  out["metadata"]["author"] = options[:author] if options[:author] && !options[:author].to_s.strip.empty?
  out["metadata"]["description"] = options[:description] if options[:description] && !options[:description].to_s.strip.empty?

  yaml_text = YAML.dump(out)

  if options[:in_place]
    backup_path = "#{in_path}.bak"
    FileUtils.cp(in_path, backup_path)
    File.write(in_path, yaml_text)
    puts "Converted in place: #{in_path}"
    puts "Backup created:      #{backup_path}"
    puts "Entries:             #{entries.size}"
    return 0
  end

  computed_out = compute_out_path(in_path, batch_root, options[:out])
  out_path = computed_out || in_path.sub(/(\.ya?ml)\z/i, "_converted\\1")
  out_path = "#{in_path}_converted.yaml" if out_path == in_path

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(out_path)) unless File.dirname(out_path) == "."

  File.write(out_path, yaml_text)

  puts "Converted: #{in_path}"
  puts "Wrote:     #{out_path}"
  puts "Entries:   #{entries.size}"

  0
end

die("Missing required option: --pack-name", 2) if options[:pack_name].nil? || options[:pack_name].strip.empty?

if options[:in_place] && options[:out]
  die("Cannot use --out and --in-place together", 2)
end

if options[:batch]
  batch_root = options[:batch]
  die("Batch directory not found: #{batch_root}", 2) unless Dir.exist?(batch_root)

  files = yaml_files_under(batch_root)
  die("No .yaml/.yml files found under: #{batch_root}", 2) if files.empty?

  total = files.size
  failed = 0

  files.each_with_index do |file, i|
    puts "=== [#{i + 1}/#{total}] #{file} ==="
    begin
      code = convert_one_file(file, options, batch_root: batch_root)
      failed += 1 if code != 0
    rescue SystemExit => e
      failed += 1
      warn e.message
    end
    puts
  end

  if failed.positive?
    puts "Overall: FAIL (#{failed}/#{total} files failed)"
    exit 1
  else
    puts "Overall: PASS (#{total} files converted)"
    exit 0
  end
else
  in_path = ARGV[0]
  die("Missing input file", 2) if in_path.nil? || in_path.strip.empty?

  convert_one_file(in_path, options)
end