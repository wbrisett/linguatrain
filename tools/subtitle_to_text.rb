#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
VERSION = "0.2.0"

class SrtToText
  TIMESTAMP_RE = /\A\d{2}:\d{2}:\d{2}[,.]\d{3}\s+-->\s+\d{2}:\d{2}:\d{2}[,.]\d{3}/
  PURE_SOUND_CUE_RE = /\A[\(\[].+[\)\]]\z/
  CREDIT_RE = /\A(?:Tekstit|Textning|Subtitles|Undertexter)\s*:/i

  Cue = Struct.new(:index, :start_time, :end_time, :lines, keyword_init: true) do
    def text
      lines.join("\n")
    end

    def normalized_text
      text.gsub(/\s+/, " ").strip
    end

    def start_seconds
      timestamp_to_seconds(start_time)
    end

    def end_seconds
      timestamp_to_seconds(end_time)
    end

    private

    def timestamp_to_seconds(timestamp)
      hours, minutes, seconds = timestamp.tr(",", ".").split(":")
      (hours.to_i * 3600) + (minutes.to_i * 60) + seconds.to_f
    end


  end

  attr_reader :stats



  def initialize(remove_sound_cues: true, remove_credits: true, paragraph_mode: false,
                 scene_gap: nil, song_ranges: [])
    @remove_sound_cues = remove_sound_cues
    @remove_credits = remove_credits
    @paragraph_mode = paragraph_mode
    @scene_gap = scene_gap
    @song_ranges = song_ranges

    @stats = {
      input_cues: 0,
      duplicate_cues: 0,
      sound_cues: 0,
      credit_cues: 0,
      punctuation_only_cues: 0,
      output_lines: 0,
      scene_breaks: 0,
      song_cues: 0,
      words: 0,
      characters: 0
    }
  end

  def convert(input)
    cues = parse(input)
    @stats[:input_cues] = cues.length

    cues = remove_adjacent_duplicates(cues)
    lines = build_output_lines(cues)

    @stats[:output_lines] =
      lines.count { |line| !line.empty? && line != "[SCENE BREAK]" }

    output_text = if @paragraph_mode
                    lines.join(" ").gsub(/\s+/, " ").strip + "\n"
                  else
                    lines.join("\n") + "\n"
                  end

    @stats[:words] = output_text.scan(/\S+/).length
    @stats[:characters] = output_text.length

    output_text
  end

  private

  def parse(input)
    normalized = input
      .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      .sub(/\A\uFEFF/, "")
      .gsub("\r\n", "\n")
      .gsub("\r", "\n")

    normalized.split(/\n{2,}/).filter_map do |block|
      parse_block(block)
    end
  end

  def parse_block(block)
    lines = block.lines.map(&:strip)
    lines.reject!(&:empty?)
    return if lines.empty?

    index = lines.first.match?(/\A\d+\z/) ? lines.shift.to_i : nil
    timestamp = lines.shift
    return unless timestamp&.match?(TIMESTAMP_RE)

    start_time, end_time = timestamp.split(/\s+-->\s+/, 2)
    return if lines.empty?

    Cue.new(
      index: index,
      start_time: start_time,
      end_time: end_time,
      lines: lines
    )
  end

  def remove_adjacent_duplicates(cues)
    cues.each_with_object([]) do |cue, result|
      previous = result.last

      duplicate =
        previous &&
        previous.start_time == cue.start_time &&
        previous.end_time == cue.end_time &&
        previous.normalized_text == cue.normalized_text

      if duplicate
        @stats[:duplicate_cues] += 1
      else
        result << cue
      end
    end
  end

  def build_output_lines(cues)
    output = []
    previous_cue = nil
    inside_song = false

    cues.each do |cue|
      if scene_break?(previous_cue, cue)
        output << "[SCENE BREAK]"
        @stats[:scene_breaks] += 1
      end

      song = song_cue?(cue)

      if song && !inside_song
        output << "[SONG]"
        inside_song = true
      elsif !song && inside_song
        output << "[/SONG]"
        inside_song = false
      end

      text = clean_cue(cue)

      if text
        if output.last&.end_with?(" -") && !text.start_with?("-")
          output[-1] = output.last.delete_suffix(" -") + " " + text
        else
          output << text
        end

        @stats[:song_cues] += 1 if song
      end

      previous_cue = cue
    end

    output << "[/SONG]" if inside_song
    output
  end

  def scene_break?(previous_cue, cue)
    return false unless @scene_gap && previous_cue

    cue.start_seconds - previous_cue.end_seconds >= @scene_gap
  end

  def song_cue?(cue)
    @song_ranges.any? do |range|
      cue.start_seconds < range.end &&
        cue.end_seconds > range.begin
    end
  end


  def clean_cue(cue)
    lines = cue.lines.map { |line| clean_line(line) }
    lines.reject!(&:empty?)
    return if lines.empty?

    if @remove_credits && lines.any? { |line| line.match?(CREDIT_RE) }
      @stats[:credit_cues] += 1
      return
    end

    if @remove_sound_cues
      original_count = lines.length
      lines.reject! { |line| line.match?(PURE_SOUND_CUE_RE) }
      @stats[:sound_cues] += original_count - lines.length
      return if lines.empty?
    end

    text = join_wrapped_lines(lines)

    if text.match?(/\A[[:punct:]\s]+\z/)
      @stats[:punctuation_only_cues] += 1
      return
    end

    text
  end

  def clean_line(line)
    line
      .gsub(/<[^>]+>/, "")       # Remove simple subtitle markup.
      .gsub(/\{\\[^}]+\}/, "")   # Remove common SSA/ASS formatting tags.
      .gsub(/[ \t]+/, " ")
      .strip
  end

  def join_wrapped_lines(lines)
    output = +""

    lines.each_with_index do |line, index|
      if index.zero?
        output << line
        next
      end

      if output.end_with?(" -") && !line.start_with?("-")
        output.delete_suffix!(" -")
        output << " " << line
      elsif line.start_with?("-")
        output << "\n" << line
      else
        output << " " << line
      end
    end

    output.strip
  end
end

options = {
  remove_sound_cues: true,
  remove_credits: true,
  paragraph_mode: false,
  scene_gap: nil,
  song_ranges: [],
  output: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: subtitle_to_text.rb [options] INPUT.srt"

  opts.on("-o", "--output FILE", "Write output to FILE") do |file|
    options[:output] = file
  end

  opts.on("--keep-sound-cues", "Keep cues such as '(Puhelin.)' or '[Music]'") do
    options[:remove_sound_cues] = false
  end

  opts.on("--keep-credits", "Keep subtitle credit lines") do
    options[:remove_credits] = false
  end

  opts.on("--paragraph", "Write one continuous paragraph instead of one cue per line") do
    options[:paragraph_mode] = true
  end

  opts.on(
    "--scene-gap SECONDS",
    Float,
    "Insert [SCENE BREAK] after a subtitle gap of at least SECONDS"
  ) do |seconds|
    unless seconds.positive?
      raise OptionParser::InvalidArgument,
            "scene gap must be greater than zero"
    end

    options[:scene_gap] = seconds
  end

  opts.on(
    "--song-range START-END",
    "Mark a known song range; may be supplied more than once"
  ) do |value|
    start_text, end_text = value.split("-", 2)

    unless start_text && end_text
      raise OptionParser::InvalidArgument,
            "song range must use START-END"
    end

    parse_time = lambda do |text|
      parts = text.tr(",", ".").split(":")

      unless parts.length == 3
        raise OptionParser::InvalidArgument,
              "invalid timestamp: #{text}"
      end

      hours, minutes, seconds = parts

      (hours.to_i * 3600) +
        (minutes.to_i * 60) +
        seconds.to_f
    end

    start_seconds = parse_time.call(start_text)
    end_seconds = parse_time.call(end_text)

    unless end_seconds > start_seconds
      raise OptionParser::InvalidArgument,
            "song range end must be after start"
    end

    options[:song_ranges] << (start_seconds...end_seconds)
  end

  opts.on("--version", "Show version") do
    puts VERSION
    exit
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

begin
  parser.parse!
  input_path = ARGV.shift

  unless input_path
    warn parser
    exit 1
  end

  input = Pathname(input_path)
  unless input.file?
    warn "Input file not found: #{input}"
    exit 1
  end

  output = options[:output] ?
    Pathname(options[:output]) :
    input.sub_ext(".txt")

  converter = SrtToText.new(
    remove_sound_cues: options[:remove_sound_cues],
    remove_credits: options[:remove_credits],
    paragraph_mode: options[:paragraph_mode],
    scene_gap: options[:scene_gap],
    song_ranges: options[:song_ranges]
  )

  output.write(converter.convert(input.read), mode: "w", encoding: "UTF-8")
  stats = converter.stats

  puts "Read:                 #{stats[:input_cues]} subtitle cues"
  puts "Duplicates removed:   #{stats[:duplicate_cues]}"
  puts "Sound cues removed:   #{stats[:sound_cues]}"
  puts "Credits removed:      #{stats[:credit_cues]}"
  puts "Punctuation removed:  #{stats[:punctuation_only_cues]}"
  puts "Output lines:         #{stats[:output_lines]}"
  puts "Scene breaks:         #{stats[:scene_breaks]}"
  puts "Song cues marked:     #{stats[:song_cues]}"
  puts "Words:                #{stats[:words]}"
  puts "Characters:           #{stats[:characters]}"

  puts "Wrote #{output}"
rescue OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 1
rescue StandardError => e
  warn "Conversion failed: #{e.message}"
  exit 1
end
