#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'yaml'
require 'fileutils'
require 'optparse'

# Interactive CLI utility for building hand-authored Linguatrain YAML packs.
#
# Supported public authoring modes:
# - Vocabulary packs
# - Conjugation packs

VERSION = 'dev_03'

class BuildYaml
  DEFAULT_VERSION = 1
  DEFAULT_SCHEMA_VERSION = 1
  DEFAULT_SUBJECTS = ['minä', 'sinä', 'hän', 'me', 'te', 'he'].freeze

  def initialize(argv)
    @options = {
      mode: :vocab,
      output: nil,
      positional_output: nil,
      overwrite: false,
      pad_width: 3,
      csv_input: nil
    }

    parse_options(argv)
  end

  def run
    puts banner
    puts

    output_path = resolve_output_path
    abort_if_output_exists!(output_path)

    pack =
      case @options[:mode]
      when :vocab
        build_vocab_pack(output_path)
      when :conjugate
        build_conjugate_pack(output_path)
      else
        raise ArgumentError, "Unsupported build mode: #{@options[:mode]}"
      end

    entries = pack.fetch('entries')

    if entries.empty?
      puts
      warn 'No entries were added. Aborting without writing a file.'
      return 1
    end

    write_yaml(output_path, pack)

    puts
    puts 'Pack created successfully.'
    puts "Mode: #{mode_label}"
    puts "Wrote: #{output_path}"
    puts "Entries: #{entries.length}"
    puts
    puts 'Next step:'
    puts "  ruby bin/validate_pack.rb #{validation_flag}#{shell_escape(output_path)}"

    0
  rescue Interrupt
    puts
    warn 'Interrupted. No file written.'
    130
  rescue ArgumentError, OptionParser::ParseError => e
    warn e.message
    1
  end

  private

  def parse_options(argv)
    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby build_yaml.rb [--vocab|--conjugate] [options] [output.yaml]'
      opts.separator ''
      opts.separator 'Examples:'
      opts.separator '  ruby build_yaml.rb --vocab packs/fi/my_vocabulary.yaml'
      opts.separator '  ruby build_yaml.rb --conjugate packs/fi/my_conjugation.yaml'
      opts.separator '  ruby build_yaml.rb --vocab --csv input.csv output.yaml'
      opts.separator '  ruby build_yaml.rb output.yaml'
      opts.separator ''

      opts.on('--vocab [FILE]', 'Build a Vocabulary pack (default)') do |value|
        select_mode(:vocab)
        @options[:output] = value unless blank?(value)
      end

      opts.on('--conjugate [FILE]', 'Build a Conjugation pack') do |value|
        select_mode(:conjugate)
        @options[:output] = value unless blank?(value)
      end

      opts.on('-o', '--output FILE', 'Output YAML filename or full path') do |value|
        @options[:output] = value
      end

      opts.on('--csv FILE', 'Read Vocabulary entries from CSV instead of interactive prompts') do |value|
        @options[:csv_input] = value
      end

      opts.on('--overwrite', 'Overwrite output file if it exists') do
        @options[:overwrite] = true
      end

      opts.on('--pad-width N', Integer, 'Zero-padding width for generated numeric entry ids (default: 3)') do |value|
        @options[:pad_width] = [value, 1].max
      end

      opts.on('-h', '--help', 'Show help') do
        puts opts
        exit 0
      end
    end.parse!(argv)

    @options[:positional_output] = argv.shift unless argv.empty?

    if @options[:mode] == :conjugate && csv_mode?
      raise OptionParser::InvalidOption, '--csv is only supported with --vocab'
    end

    if csv_mode? && blank?(@options[:csv_input])
      raise OptionParser::MissingArgument, '--csv requires an input CSV file'
    end

    return if argv.empty?

    raise OptionParser::InvalidArgument, "Unexpected arguments: #{argv.join(' ')}"
  end

  def select_mode(mode)
    if @explicit_mode && @explicit_mode != mode
      raise OptionParser::InvalidOption, '--vocab and --conjugate cannot be combined'
    end

    @explicit_mode = mode
    @options[:mode] = mode
  end

  def banner
    "Linguatrain YAML Builder (#{mode_label})"
  end

  def mode_label
    case @options[:mode]
    when :conjugate then 'conjugation'
    else 'vocabulary'
    end
  end

  def validation_flag
    @options[:mode] == :conjugate ? '--conjugate ' : ''
  end

  def resolve_output_path
    return normalize_output_path(@options[:output]) unless blank?(@options[:output])
    return normalize_output_path(@options[:positional_output]) unless blank?(@options[:positional_output])

    if csv_mode?
      return default_csv_output_path(@options[:csv_input])
    end

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

  def build_vocab_pack(output_path)
    metadata = csv_mode? ? build_csv_vocab_metadata(output_path) : collect_vocab_metadata(output_path)
    entries = csv_mode? ? collect_vocab_entries_from_csv : collect_vocab_entries

    {
      'metadata' => metadata,
      'entries' => entries
    }
  end

  def build_csv_vocab_metadata(output_path)
    default_id = File.basename(output_path, File.extname(output_path))

    {
      'id' => default_id,
      'title' => titleize_id(default_id),
      'type' => 'vocabulary',
      'format' => 'canonical',
      'version' => DEFAULT_VERSION,
      'schema_version' => DEFAULT_SCHEMA_VERSION,
      'description' => "Built from CSV: #{File.basename(@options[:csv_input])}",
      'tts_side' => 'prompt'
    }
  end

  def collect_vocab_metadata(output_path)
    metadata = collect_common_metadata(output_path, default_type: 'vocabulary')
    metadata['format'] = prompt_with_default('Format', 'canonical')
    metadata['tts_side'] = prompt_with_default('TTS side', 'prompt')

    source_pack = prompt_optional('Source pack id (optional)')
    metadata['source_pack'] = source_pack.strip unless blank?(source_pack)

    collect_optional_metadata(metadata)
    puts
    metadata
  end

  def collect_common_metadata(output_path, default_type:)
    puts 'Metadata'
    puts '--------'

    default_id = File.basename(output_path, File.extname(output_path))

    {
      'id' => prompt_with_default('Pack id', default_id),
      'title' => prompt_with_default('Title', titleize_id(default_id)),
      'type' => default_type,
      'version' => prompt_integer_with_default('Version', DEFAULT_VERSION),
      'schema_version' => prompt_integer_with_default('Schema version', DEFAULT_SCHEMA_VERSION)
    }
  end

  def collect_optional_metadata(metadata)
    author = prompt_optional('Author (optional)')
    description = prompt_optional('Description (optional)')
    tags = collect_tags

    metadata['author'] = author.strip unless blank?(author)
    metadata['description'] = description.strip unless blank?(description)
    metadata['tags'] = tags unless tags.empty?
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

  def collect_vocab_entries
    puts 'Vocabulary Entries'
    puts '------------------'
    puts 'Enter a prompt to create an entry.'
    puts 'Leave the prompt blank to finish, then confirm.'
    puts

    entries = []
    index = 1

    loop do
      display_id = format_id(index)
      puts "Entry #{display_id}"
      prompt_text = prompt('Prompt')

      if blank?(prompt_text)
        break if finish_entries?(entries)

        puts
        next
      end

      entry_id = prompt_with_default('Entry id', normalized_id(prompt_text, fallback: display_id))

      entry = {
        'id' => entry_id,
        'prompt' => prompt_text.strip,
        'answer' => collect_answers
      }

      type = prompt_optional('Type (optional; noun, verb, phrase, etc.)')
      alternate_prompts = collect_list('Alternate prompt (optional; blank to continue)')
      spoken = collect_list('Spoken form (optional; blank to continue)')
      phonetic = prompt_optional('Phonetic (optional)')
      notes = collect_list('Note (optional; blank to continue)')
      forms = collect_vocab_forms

      entry['type'] = type.strip unless blank?(type)
      entry['alternate_prompts'] = alternate_prompts unless alternate_prompts.empty?
      entry['spoken'] = spoken unless spoken.empty?
      entry['phonetic'] = phonetic.strip unless blank?(phonetic)
      entry['forms'] = forms unless forms.empty?
      entry['notes'] = notes unless notes.empty?

      entries << entry
      index += 1
      puts
    end

    entries
  end

  def collect_vocab_forms
    puts 'Forms (optional)'
    puts 'Enter a label and value, such as "partitive_singular: päivää". Leave label blank to continue.'

    forms = {}
    loop do
      label = prompt('Form label')
      break if blank?(label)

      value = prompt_required('Form value')
      forms[label.strip] = value.strip
    end
    forms
  end

  def collect_vocab_entries_from_csv
    input_path = @options[:csv_input]
    raise ArgumentError, "CSV file does not exist: #{input_path}" unless File.exist?(input_path)

    entries = []

    CSV.foreach(input_path, headers: true, encoding: 'bom|utf-8').with_index(2) do |row, line_number|
      normalized = normalize_csv_row(row)
      prompt_text = normalized['prompt'].to_s.strip
      next if prompt_text.empty?

      answers = split_csv_list(normalized['answer'])
      raise ArgumentError, "Missing answer for prompt #{prompt_text.inspect} on CSV line #{line_number}." if answers.empty?

      default_id = normalized_id(prompt_text, fallback: format_id(entries.length + 1))
      entry = {
        'id' => normalized['id'].to_s.strip.empty? ? default_id : normalized['id'].to_s.strip,
        'prompt' => prompt_text,
        'answer' => answers
      }

      type = normalized['type']
      alternate_prompts = split_csv_list(normalized['alternate_prompts'] || normalized['alternate_prompt'])
      spoken = split_csv_list(normalized['spoken'])
      notes = split_csv_list(normalized['notes'] || normalized['note'])
      phonetic = normalized['phonetic']

      entry['type'] = type.to_s.strip unless blank?(type)
      entry['alternate_prompts'] = alternate_prompts unless alternate_prompts.empty?
      entry['spoken'] = spoken unless spoken.empty?
      entry['phonetic'] = phonetic.to_s.strip unless blank?(phonetic)
      entry['notes'] = notes unless notes.empty?
      add_csv_forms(entry, normalized)

      entries << entry
    end

    raise ArgumentError, "CSV file has no data rows: #{input_path}" if entries.empty?

    entries
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "Malformed CSV: #{e.message}"
  end

  def add_csv_forms(entry, row)
    forms = {}
    row.each do |key, value|
      next unless key.start_with?('form_')
      next if blank?(value)

      forms[key.sub(/\Aform_/, '')] = value.to_s.strip
    end
    entry['forms'] = forms unless forms.empty?
  end

  def build_conjugate_pack(output_path)
    metadata = collect_conjugate_metadata(output_path)
    subjects = collect_subjects
    entries = collect_conjugate_entries(subjects)

    {
      'metadata' => metadata,
      'subjects' => subjects,
      'entries' => entries
    }
  end

  def collect_conjugate_metadata(output_path)
    metadata = collect_common_metadata(output_path, default_type: 'conjugation')
    metadata['format'] = prompt_with_default('Format', 'canonical')
    metadata['drill_type'] = 'conjugate'

    source_pack = prompt_optional('Source vocabulary pack id (optional)')
    metadata['source_pack'] = source_pack.strip unless blank?(source_pack)

    shuffle = prompt_with_default('Shuffle subjects? true/false', 'true')
    metadata['shuffle_subjects'] = boolean_text?(shuffle) if boolean_text?(shuffle)

    collect_optional_metadata(metadata)
    puts
    metadata
  end

  def collect_subjects
    puts 'Subjects'
    puts '--------'
    puts "Default: #{DEFAULT_SUBJECTS.join(', ')}"
    raw = prompt('Subjects, comma-separated (blank for default)')
    return DEFAULT_SUBJECTS.dup if blank?(raw)

    subjects = raw.split(',').map(&:strip).reject(&:empty?)
    raise ArgumentError, 'Conjugation packs require at least one subject.' if subjects.empty?

    subjects
  end

  def collect_conjugate_entries(subjects)
    puts
    puts 'Conjugation Entries'
    puts '-------------------'
    puts 'Enter a lemma to create an entry.'
    puts 'Leave the lemma blank to finish, then confirm.'
    puts

    entries = []
    index = 1

    loop do
      display_id = format_id(index)
      puts "Entry #{display_id}"
      lemma = prompt('Lemma')

      if blank?(lemma)
        break if finish_entries?(entries)

        puts
        next
      end

      entry = {
        'id' => prompt_with_default('Entry id', display_id),
        'lemma' => lemma.strip
      }

      gloss = prompt_optional('Gloss (optional)')
      entry['gloss'] = gloss.strip unless blank?(gloss)
      entry['forms'] = collect_conjugate_forms(lemma.strip, subjects)

      entries << entry
      index += 1
      puts
    end

    entries
  end

  def collect_conjugate_forms(lemma, subjects)
    puts "Forms for #{lemma}"

    subjects.each_with_object({}) do |subject, forms|
      puts subject
      positive = collect_list_required('  Positive form')
      negative = collect_list_required('  Negative form')
      forms[subject] = {
        'positive' => positive,
        'negative' => negative
      }
    end
  end

  def finish_entries?(entries)
    if entries.empty?
      puts 'No entry entered.'
      confirm?('Finish without adding any entries? [y/N]')
    else
      puts 'No entry entered.'
      confirm?("Finish and write #{entries.length} entr#{entries.length == 1 ? 'y' : 'ies'}? [y/N]")
    end
  end

  def normalize_csv_row(row)
    row.headers.each_with_object({}) do |header, memo|
      next if header.nil?

      key = header.to_s.strip.downcase.gsub(/[\s-]+/, '_')
      memo[key] = row[header]
    end
  end

  def split_csv_list(value)
    return [] if blank?(value)

    value.to_s
         .split(/\s*(?:;|\|)\s*|\r?\n+/)
         .map(&:strip)
         .reject(&:empty?)
         .uniq
  end

  def collect_answers
    puts 'At least one answer is required.'

    collect_list_required('Answer')
  end

  def collect_list_required(label)
    values = []
    first = prompt_required("#{label} 1")
    values << first.strip

    loop do
      value = prompt("#{label} #{values.length + 1} (optional; blank to continue)")
      break if blank?(value)

      values << value.strip
    end

    values
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

  def normalized_id(value, fallback:)
    id = value.to_s
              .strip
              .downcase
              .gsub(/[^\p{Alnum}]+/, '_')
              .gsub(/\A_+|_+\z/, '')
    id.empty? ? fallback : id
  end

  def titleize_id(value)
    value.to_s
         .tr('_-', ' ')
         .split
         .map { |part| part[0].to_s.upcase + part[1..].to_s }
         .join(' ')
  end

  def boolean_text?(value)
    text = value.to_s.strip.downcase
    return true if text == 'true'
    return false if text == 'false'

    nil
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end

  def csv_mode?
    !blank?(@options[:csv_input])
  end

  def default_csv_output_path(input_path)
    dirname = File.dirname(input_path)
    basename = File.basename(input_path, File.extname(input_path))
    normalize_output_path(File.join(dirname, "#{basename}.yaml"))
  end

  def shell_escape(value)
    return "''" if value.empty?
    return value if value.match?(/\A[\w.\/-]+\z/)

    "'#{value.gsub("'", %q('\\''))}'"
  end
end

exit BuildYaml.new(ARGV).run
