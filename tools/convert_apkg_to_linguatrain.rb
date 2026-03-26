#!/usr/bin/env ruby
# frozen_string_literal: true
# convert_apkg_to_linguatrain.rb

require "csv"
require "json"
require "yaml"
require "sqlite3"
require "tmpdir"
require "fileutils"
require "zip"

FIELD_SEPARATOR = "\u001F"

def parse_media_tag(str)
  match = (str || "").match(/\[sound:(.+?)\]/)
  match ? match[1] : ""
end

def parse_img_tag(str)
  match = (str || "").match(/<img\s+src="([^"]+)"/i)
  match ? match[1] : ""
end

def strip_html(text)
  return "" if text.nil?

  text
    .gsub(%r{<br\s*/?>}i, "\n")
    .gsub(%r{</p>}i, "\n")
    .gsub(%r{</div>}i, "\n")
    .gsub(%r{<div[^>]*>}i, "")
    .gsub(%r{<[^>]+>}, "")
    .gsub("&nbsp;", " ")
    .strip
end

def normalize_answers(text)
  cleaned = strip_html(text)

  cleaned
    .split(/\n+/)
    .map { |s| s.strip }
    .reject(&:empty?)
    .uniq
end


def map_note_fields(parts)
  parts = Array(parts).map { |p| p.to_s }

  if parts.length >= 6
    answer_text, prompt_text, img_html, audio_tag, category, _color = parts[0, 6]

    {
      "answer_text" => answer_text,
      "prompt_text" => prompt_text,
      "image" => img_html,
      "audio" => audio_tag,
      "category" => category,
      "sample_answer" => "",
      "sample_prompt" => ""
    }
  elsif parts.length == 4
    answer_text, prompt_text, sample_answer, sample_prompt = parts[0, 4]

    {
      "answer_text" => answer_text,
      "prompt_text" => prompt_text,
      "image" => "",
      "audio" => "",
      "category" => "",
      "sample_answer" => sample_answer,
      "sample_prompt" => sample_prompt
    }
  elsif parts.length == 3
    prompt_text, answer_text, audio_tag = parts[0, 3]

    {
      "answer_text" => answer_text,
      "prompt_text" => prompt_text,
      "image" => "",
      "audio" => audio_tag,
      "category" => "",
      "sample_answer" => "",
      "sample_prompt" => ""
    }
  elsif parts.length == 2
    answer_text, prompt_text = parts[0, 2]

    {
      "answer_text" => answer_text,
      "prompt_text" => prompt_text,
      "image" => "",
      "audio" => "",
      "category" => "",
      "sample_answer" => "",
      "sample_prompt" => ""
    }
  else
    nil
  end
end

def find_collection_db(tmp)
  candidates = %w[collection.anki21 collection.anki2]

  candidates.each do |name|
    path = File.join(tmp, name)
    next unless File.exist?(path)

    begin
      db = SQLite3::Database.new(path)
      note_count = db.get_first_value("select count(*) from notes")
      db.close
      return path if note_count.to_i.positive?
    rescue SQLite3::Exception
      db.close if db
    end
  end

  nil
end

def convert(apkg_path, outdir)
  FileUtils.mkdir_p(outdir)
  media_out = File.join(outdir, "media")
  exported_images = []
  exported_audio = []

  unique = {}

  Dir.mktmpdir("apkg_convert") do |tmp|
    Zip::File.open(apkg_path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name_is_directory?

        safe_name = File.basename(entry.name)
        dest = File.expand_path(File.join(tmp, safe_name))

        entry.get_input_stream do |input|
          File.binwrite(dest, input.read)
        end
      end
    end

    db_path = find_collection_db(tmp)
    raise "Missing usable Anki collection database inside APKG" unless db_path

    media_json_path = File.join(tmp, "media")
    raise "Missing media map inside APKG" unless File.exist?(media_json_path)

    media_map = JSON.parse(File.read(media_json_path, encoding: "UTF-8"))
    db = SQLite3::Database.new(db_path)
    db.results_as_hash = false

    rows = db.execute("select flds from notes")
    rows.each do |row|
      flds = row[0]
      parts = (flds || "").split(FIELD_SEPARATOR)

      mapped = map_note_fields(parts)
      next unless mapped

      answers = normalize_answers(mapped["answer_text"])
      next if answers.empty?

      prompt = strip_html(mapped["prompt_text"]).strip
      next if prompt.empty?

      key = [prompt, answers.join(" | ")]
      rec = unique[key] || {
        "prompt" => prompt,
        "answers" => [],
        "category" => mapped["category"].to_s.strip,
        "image" => "",
        "audio" => "",
        "sample_answer" => strip_html(mapped["sample_answer"]),
        "sample_prompt" => strip_html(mapped["sample_prompt"])
      }

      rec["answers"] |= answers

      img = parse_img_tag(mapped["image"])
      aud = parse_media_tag(mapped["audio"])

      rec["image"] = img if !img.empty? && rec["image"].empty?
      rec["audio"] = aud if !aud.empty? && rec["audio"].empty?
      clean_sample_answer = strip_html(mapped["sample_answer"])
      clean_sample_prompt = strip_html(mapped["sample_prompt"])

      rec["sample_answer"] = clean_sample_answer if rec["sample_answer"].to_s.empty? && !clean_sample_answer.empty?
      rec["sample_prompt"] = clean_sample_prompt if rec["sample_prompt"].to_s.empty? && !clean_sample_prompt.empty?
      unique[key] = rec

    end

    db.close

    inverse_media_map = media_map.each_with_object({}) do |(idx, filename), memo|
      memo[filename] = idx
    end

    media_filenames = {
      "images" => unique.values.map { |rec| rec["image"] }.reject { |filename| filename.nil? || filename.empty? }.uniq,
      "audio" => unique.values.map { |rec| rec["audio"] }.reject { |filename| filename.nil? || filename.empty? }.uniq
    }

    if media_filenames.values.any? { |filenames| !filenames.empty? }
      FileUtils.mkdir_p(media_out)

      media_filenames["images"].each do |filename|
        idx = inverse_media_map[filename]
        next unless idx

        src = File.join(tmp, idx.to_s)
        next unless File.exist?(src)

        FileUtils.cp(src, File.join(media_out, filename))
        exported_images << filename
      end

      media_filenames["audio"].each do |filename|
        idx = inverse_media_map[filename]
        next unless idx

        src = File.join(tmp, idx.to_s)
        next unless File.exist?(src)

        FileUtils.cp(src, File.join(media_out, filename))
        exported_audio << filename
      end
    end
  end

  source_name = File.basename(apkg_path)

  readme_lines = [
    "# Conversion notes",
    "",
    "This pack was converted from the Anki file: #{source_name}.",
    ""
  ]

  unless exported_images.empty? && exported_audio.empty?
    readme_lines << "Extracted rich media files are available in media/."
    readme_lines << ""
    readme_lines << "Exported rich media summary:"
    readme_lines << ""
    readme_lines << "- Images: #{exported_images.length}"
    readme_lines << "- Audio: #{exported_audio.length}"
  end

  notes_path = File.join(outdir, "conversion_notes.md")
  File.write(notes_path, readme_lines.join("\n") + "\n")

  entries = unique.values.each_with_index.map do |rec, i|
    entry = {
      "id" => format("%03d", i + 1),
      "prompt" => rec["prompt"],
      "answer" => rec["answers"]
    }

    entry["notes"] = {
      "sample_answer" => rec["sample_answer"],
      "sample_prompt" => rec["sample_prompt"]
    } if !rec["sample_answer"].to_s.empty? || !rec["sample_prompt"].to_s.empty?

    entry
  end

  deck_id = File.basename(outdir)
                .downcase
                .gsub(/\s+/, "_")
                .gsub(/[^a-z0-9_]/, "")

  pack = {
    "metadata" => {
      "id" => deck_id,
      "version" => 1,
      "schema_version" => 1,
      "author" => "APKG conversion",
      "description" => "Converted from Anki APKG"
    },
    "entries" => entries
  }

  deck_name = File.basename(outdir)
  yaml_path = File.join(outdir, "#{deck_name}.yaml")
  File.write(yaml_path, YAML.dump(pack))

  has_extracted_media = !exported_images.empty? || !exported_audio.empty?

  csv_path = File.join(outdir, "manifest.csv")
  CSV.open(csv_path, "w", write_headers: true,
           headers: ["id", "prompt", "answers", "category", "image", "audio"]) do |csv|
    unique.values.each_with_index do |rec, i|
      csv << [
        format("%03d", i + 1),
        rec["prompt"],
        rec["answers"].join(" | "),
        rec["category"],
        rec["image"],
        rec["audio"]
      ]
    end
  end
  has_extracted_media
end

if ARGV.length < 1 || ARGV.length > 2
  warn "Usage: ruby convert_apkg_to_linguatrain.rb INPUT.apkg [OUTPUT_DIR]"
  exit 1
end

apkg_path = ARGV[0]

if ARGV[1]
  outdir = ARGV[1]
else
  base_name = File.basename(apkg_path, ".apkg")
  parent_dir = File.dirname(apkg_path)
  outdir = File.join(parent_dir, base_name)
end

has_extracted_media = convert(apkg_path, outdir)
puts "Conversion complete: #{outdir}"
if has_extracted_media
  puts "Review conversion_notes.md for details about extracted media and conversion behavior."
else
  puts "Review conversion_notes.md for details on the conversion."
end
