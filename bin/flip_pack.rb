#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

in_path = ARGV[0] or abort("Usage: ruby flip_pack.rb <pack.yaml> [--in-place|out.yaml]")
out_arg = ARGV[1]

in_place = out_arg == "--in-place"

out_path =
  if in_place
    in_path
  elsif out_arg && !out_arg.strip.empty?
    out_arg
  else
    base = File.basename(in_path, File.extname(in_path))
    File.join(File.dirname(in_path), "#{base}_flipped.yaml")
  end

data = YAML.load_file(in_path)
abort("Expected YAML Hash") unless data.is_a?(Hash)

metadata = data["metadata"] || data[:metadata]
entries  = data["entries"]  || data[:entries]

abort("No entries found") unless entries.is_a?(Array)

flipped_entries = entries.map do |e|
  prompt = e["prompt"] || e[:prompt]
  answer = e["answer"] || e[:answer]

  abort("Entry missing prompt/answer: #{e.inspect}") if prompt.nil? || answer.nil?

  new_entry = e.dup

  new_entry["prompt"] = answer
  new_entry["answer"] =
    case prompt
    when Array
      prompt
    else
      [prompt]
    end

  new_entry
end

output = {}

# Preserve metadata exactly
output["metadata"] = metadata if metadata

# Replace only entries
output["entries"] = flipped_entries

File.write(out_path, YAML.dump(output))

puts "Written: #{out_path}"