#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "optparse"
require_relative "../tools/finnish_phonetics"

options = {
  in_place: false
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: bin/add_finnish_phonetics PACK.yaml [options]"

  opts.on("--in-place", "Modify the input file in place") do
    options[:in_place] = true
  end

  opts.on("-o", "--output FILE", "Write output to FILE") do |file|
    options[:output] = file
  end
end

parser.parse!

input_path = ARGV[0]
abort(parser.to_s) unless input_path

unless File.exist?(input_path)
  abort("File not found: #{input_path}")
end

data = YAML.load_file(input_path)
entries = data["entries"]

unless entries.is_a?(Array)
  abort("No entries array found in #{input_path}")
end

entries.each do |entry|
  next unless entry.is_a?(Hash)
  next if entry.key?("phonetic")

  answers = entry["answer"]
  next unless answers.is_a?(Array) && !answers.empty?

  first_answer = answers.first.to_s.strip
  next if first_answer.empty?

  entry["phonetic"] = FinnishPhonetics.render(first_answer)
end

output_path =
  if options[:in_place]
    input_path
  elsif options[:output]
    options[:output]
  else
    ext = File.extname(input_path)
    base = File.basename(input_path, ext)
    dir = File.dirname(input_path)
    File.join(dir, "#{base}_with_phonetics#{ext}")
  end

File.write(output_path, YAML.dump(data))
puts "Wrote #{output_path}"