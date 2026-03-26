#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "optparse"

options = {
  in_place: false,
  output: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby flip_pack.rb <pack.yaml> [--in-place] [--output out.yaml]"

  opts.on("--in-place", "Overwrite the input file") do
    options[:in_place] = true
  end

  opts.on("--output PATH", "Write flipped pack to PATH") do |path|
    options[:output] = path
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

parser.parse!(ARGV)

in_path = ARGV[0] or abort(parser.to_s)

if options[:in_place] && options[:output]
  abort("Use either --in-place or --output PATH, not both")
end

out_path =
  if options[:in_place]
    in_path
  elsif options[:output] && !options[:output].strip.empty?
    options[:output]
  else
    base = File.basename(in_path, File.extname(in_path))
    File.join(File.dirname(in_path), "#{base}_flipped.yaml")
  end

data = YAML.safe_load(File.read(in_path), permitted_classes: [], permitted_symbols: [], aliases: false)
abort("Expected YAML Hash") unless data.is_a?(Hash)

metadata = data["metadata"]
entries = data["entries"]

abort("metadata must be a Hash") unless metadata.is_a?(Hash)
abort("No entries found") unless entries.is_a?(Array)

if %w[transform conjugate].include?(metadata["drill_type"])
  abort("flip_pack.rb only supports standard word packs (not #{metadata['drill_type']} packs)")
end

def normalized_prompt_array(prompt)
  case prompt
  when Array
    prompt
  when String
    [prompt]
  else
    abort("Prompt must be a String or Array. Got: #{prompt.class}")
  end
end

def normalized_answer_array(answer)
  case answer
  when Array
    answer
  when String
    [answer]
  else
    abort("Answer must be a String or Array. Got: #{answer.class}")
  end
end

def next_flipped_id(entry, answer_idx, total_answers)
  raw_id = entry["id"]
  return nil if raw_id.nil?

  base = raw_id.to_s
  return base if total_answers == 1

  "#{base}_#{answer_idx + 1}"
end

flipped_entries = entries.each_with_index.flat_map do |entry, idx|
  unless entry.is_a?(Hash)
    abort("Entry at index #{idx + 1} must be a Hash. Got: #{entry.class}")
  end

  prompt = entry["prompt"]
  answer = entry["answer"]

  abort("Entry missing prompt/answer at entries[#{idx + 1}]: #{entry.inspect}") if prompt.nil? || answer.nil?

  prompts = normalized_prompt_array(prompt)
  answers = normalized_answer_array(answer)

  answers.each_with_index.map do |answer_value, answer_idx|
    new_entry = entry.dup

    new_entry.delete("phonetic")
    new_entry.delete("spoken")
    new_entry.delete("alternate_prompts")

    new_entry["id"] = next_flipped_id(entry, answer_idx, answers.length) if entry.key?("id")
    new_entry["prompt"] = answer_value
    new_entry["answer"] = prompts

    new_entry
  end
end

output = {}
output["metadata"] = metadata.dup
output["entries"] = flipped_entries

File.write(out_path, YAML.dump(output))
puts "Written: #{out_path}"