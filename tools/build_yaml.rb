#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'optparse'

# Development utility for interactively building a standard Linguatrain YAML pack.
#
# Scope for this version:
# - Standard packs only
# - Interactive prompts
# - Auto-generated entry IDs
# - Blank prompt in the entry loop asks for confirmation to finish
# - Blank extra-answer exits that sub-loop
# - Optional phonetic and alternate prompts
#
# Intended as a starting point for later refinement.

VERSION = 'dev_01'

class BuildYaml
  DEFAULT_VERSION = 1
  DEFAULT_SCHEMA_VERSION = 1

  def initialize(argv)
    @options = {
      output: nil,
      positional_output: nil,
      overwrite: false,
      pad_width: 3,
      dev: false
    }

    parse_options(argv)
  end

  def run
    puts banner
    puts

    output_path = resolve_output_path
    abort_if_output_exists!(output_path)

    metadata = collect_metadata(output_path)
    entries = collect_entries

    if entries.empty?
      puts
      warn 'No entries were added. Aborting without writing a file.'
      return 1
    end

    pack = {
      'metadata' => metadata,
      'entries' => entries
    }

    write_yaml(output_path, pack)

    puts
    puts 'Pack created successfully.'
    puts "Wrote: #{output_path}"
    puts "Entries: #{entries.length}"
    puts
    puts 'Next step:'
    puts "  ruby bin/validate_pack.rb #{shell_escape(output_path)}"

    0
  rescue Interrupt
    puts
    warn 'Interrupted. No file written.'
    130
  rescue ArgumentError => e
    warn e.message
    1
  end

  private

  def parse_options(argv)
    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby build_yaml.rb [options] [output.yaml]'

      opts.on('-o', '--output FILE', 'Output YAML filename or full path') do |value|
        @options[:output] = value
      end

      opts.on('--overwrite', 'Overwrite output file if it exists') do
        @options[:overwrite] = true
      end

      opts.on('--pad-width N', Integer, 'Zero-padding width for entry ids (default: 3)') do |value|
        @options[:pad_width] = [value, 1].max
      end

      opts.on('--dev', 'Development mode flag for future behavior toggles') do
        @options[:dev] = true
      end

      opts.on('-h', '--help', 'Show help') do
        puts opts
        exit 0
      end
    end.parse!(argv)

    @options[:positional_output] = argv.shift unless argv.empty?

    return if argv.empty?

    raise OptionParser::InvalidArgument, "Unexpected arguments: #{argv.join(' ')}"
  end

  def banner
    'Linguatrain YAML Builder (development version)'
  end

  def resolve_output_path
    return normalize_output_path(@options[:output]) unless blank?(@options[:output])
    return normalize_output_path(@options[:positional_output]) unless blank?(@options[:positional_output])

    puts 'What YAML filename should be created?'
    puts 'Enter a filename or full path ending in .yaml or .yml.'

    loop do
      value = prompt_required('Output filename')
      return normalize_output_path(value)
    rescue ArgumentError => e
      puts e.message
    end
  end

  def abort_if_output_exists!(path)
    return unless File.exist?(path)
    return if @options[:overwrite]

    raise ArgumentError, "Output file already exists: #{path}\nUse --overwrite to replace it."
  end

  def normalize_output_path(path)
    value = path.to_s.strip

    raise ArgumentError, 'Output filename is required.' if value.empty?

    if File.directory?(value)
      raise ArgumentError, 'Please provide a filename ending in .yaml or .yml, not just a directory path.'
    end

    ext = File.extname(value).downcase
    unless ['.yaml', '.yml'].include?(ext)
      raise ArgumentError, 'Output filename must end in .yaml or .yml.'
    end

    value
  end

  def collect_metadata(output_path)
    puts 'Metadata'
    puts '--------'

    default_id = File.basename(output_path, File.extname(output_path))

    metadata = {
      'id' => prompt_with_default('Pack id', default_id),
      'version' => prompt_integer_with_default('Version', DEFAULT_VERSION),
      'schema_version' => prompt_integer_with_default('Schema version', DEFAULT_SCHEMA_VERSION)
    }

    author = prompt_optional('Author (optional)')
    description = prompt_optional('Description (optional)')
    tags = collect_tags

    metadata['author'] = author unless blank?(author)
    metadata['description'] = description unless blank?(description)
    metadata['tags'] = tags unless tags.empty?

    puts
    metadata
  end

  def collect_tags
    puts 'Tags (optional)'
    puts 'Enter one tag per line. Leave blank to continue.'

    tags = []
    loop do
      tag = prompt('Tag')
      break if blank?(tag)

      tags << tag.strip
    end
    tags
  end

  def collect_entries
    puts 'Entries'
    puts '-------'
    puts 'Enter a prompt to create an entry.'
    puts 'Leave the prompt blank to finish, then confirm.'
    puts

    entries = []
    index = 1

    loop do
      puts "Entry #{format_id(index)}"
      prompt_text = prompt('Prompt')

      if blank?(prompt_text)
        if entries.empty?
          puts 'No prompt entered.'
          break if confirm?('Finish without adding any entries? [y/N]')
        else
          puts 'No prompt entered.'
          break if confirm?("Finish and write #{entries.length} entr#{entries.length == 1 ? 'y' : 'ies'}? [y/N]")
        end

        puts
        next
      end

      entry = {
        'id' => format_id(index),
        'prompt' => prompt_text.strip,
        'answer' => collect_answers
      }

      alternate_prompts = collect_list('Alternate prompt (optional; blank to continue)')
      spoken = collect_list('Spoken form (optional; blank to continue)')
      phonetic = prompt_optional('Phonetic (optional)')

      entry['alternate_prompts'] = alternate_prompts unless alternate_prompts.empty?
      entry['spoken'] = spoken unless spoken.empty?
      entry['phonetic'] = phonetic.strip unless blank?(phonetic)

      entries << entry
      index += 1
      puts
    end

    entries
  end

  def collect_answers
    puts 'At least one answer is required.'

    answers = []
    first = prompt_required('Answer 1')
    answers << first.strip

    loop do
      label = "Answer #{answers.length + 1} (optional; blank to continue)"
      value = prompt(label)
      break if blank?(value)

      answers << value.strip
    end

    answers
  end

  def collect_list(label)
    values = []
    loop do
      value = prompt(label)
      break if blank?(value)

      values << value.strip
    end
    values
  end

  def write_yaml(path, data)
    dirname = File.dirname(path)
    FileUtils.mkdir_p(dirname) unless dirname == '.'

    yaml_content = YAML.dump(data)
    header = "# created with build_yaml version: #{VERSION}\n"

    File.write(path, header + yaml_content)
  end

  def prompt(label)
    print "#{label}: "
    input = $stdin.gets
    raise Interrupt if input.nil?

    input.chomp
  end

  def prompt_required(label)
    loop do
      value = prompt(label)
      return value unless blank?(value)

      puts 'A value is required.'
    end
  end

  def prompt_optional(label)
    prompt(label)
  end

  def prompt_with_default(label, default)
    value = prompt("#{label} [#{default}]")
    blank?(value) ? default : value.strip
  end

  def prompt_integer_with_default(label, default)
    loop do
      raw = prompt("#{label} [#{default}]")
      return default if blank?(raw)
      return raw.to_i if raw.match?(/\A\d+\z/)

      puts 'Please enter a whole number.'
    end
  end

  def confirm?(label)
    value = prompt(label)
    value.strip.downcase == 'y'
  end

  def format_id(index)
    index.to_s.rjust(@options[:pad_width], '0')
  end

  def blank?(value)
    value.nil? || value.strip.empty?
  end

  def shell_escape(value)
    return "''" if value.empty?
    return value if value.match?(/\A[\w.\/-]+\z/)

    "'#{value.gsub("'", %q('\\''))}'"
  end
end

exit BuildYaml.new(ARGV).run
