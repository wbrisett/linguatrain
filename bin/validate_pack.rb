#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "optparse"
require "csv"
require "pathname"

class PackValidator
  ISO_639_1 = /\A[a-z]{2}\z/
  KNOWN_DRILL_TYPES = %w[transform conjugate].freeze

  def initialize(path:, strict: false, warn_integer_ids: true, forced_mode: nil, update: false)
    @path = path
    @strict = strict
    @warn_integer_ids = warn_integer_ids
    @forced_mode = forced_mode
    @update = update
    @errors = []
    @warnings = []
    @updated_output_path = nil
    @original_errors = []
    @original_warnings = []
    @updated_errors = []
    @updated_warnings = []
    @raw_yaml = nil
    @source_entry_scalars = {}
  end

  attr_reader :errors, :warnings, :updated_output_path, :original_errors, :original_warnings, :updated_errors, :updated_warnings

  def run
    data = load_yaml(@path)
    return report unless data
    @source_entry_scalars = extract_entry_scalar_map

    validate_loaded_data(data)
    @original_errors = @errors.dup
    @original_warnings = @warnings.dup

    if @update && data.is_a?(Hash)
      fixed_data = build_updated_data(data)
      @updated_output_path = write_updated_yaml(fixed_data)

      @errors = []
      @warnings = []
      validate_loaded_data(fixed_data)
      @updated_errors = @errors.dup
      @updated_warnings = @warnings.dup
    end

    report
  end

  def validate_loaded_data(data)
    validate_top_level(data)
    return unless data.is_a?(Hash)

    metadata = data["metadata"]
    drill_type = validate_metadata(metadata)
    mode = effective_mode(drill_type)

    case mode
    when "transform"
      validate_transform_pack(data)
    when "conjugate"
      validate_conjugate_pack(data)
    else
      validate_word_pack(data)
    end
  end

  def build_updated_data(data)
    updated = deep_copy(data)
    return updated unless updated.is_a?(Hash)

    metadata = updated["metadata"]
    metadata = {} unless metadata.is_a?(Hash)
    updated["metadata"] = metadata

    metadata["version"] = 1
    metadata["schema_version"] = 1

    entries = updated["entries"]
    if entries.is_a?(Array)
      entries.each_with_index do |entry, entry_idx|
        normalize_entry_scalars!(entry, entry_idx)
      end
      repair_duplicate_entry_ids!(entries)
    end

    updated
  end

  def repair_duplicate_entry_ids!(entries)
    used_ids = {}

    entries.each do |entry|
      next unless entry.is_a?(Hash)
      next unless entry.key?("id")

      raw_id = entry["id"]
      normalized_id = case raw_id
                      when String then raw_id.strip
                      when Integer then raw_id.to_s
                      else nil
                      end

      next if normalized_id.nil? || normalized_id.empty?

      if used_ids.key?(normalized_id)
        entry["id"] = next_duplicate_id(normalized_id, used_ids)
      else
        used_ids[normalized_id] = true
      end
    end
  end

  def next_duplicate_id(base_id, used_ids)
    candidate = "#{base_id}dup"
    suffix = 2

    while used_ids.key?(candidate)
      candidate = "#{base_id}dup#{suffix}"
      suffix += 1
    end

    used_ids[candidate] = true
    candidate
  end

  def deep_copy(obj)
    Marshal.load(Marshal.dump(obj))
  end

  def normalize_entry_scalars!(entry, entry_idx)
    return unless entry.is_a?(Hash)

    %w[prompt answer alternate_prompts spoken].each do |key|
      next unless entry.key?(key)
      entry[key] = normalize_stringish_value(entry[key], key, original_entry_scalar(entry_idx, key))
    end

    if entry["cues"].is_a?(Array)
      entry["cues"].each do |cue_entry|
        next unless cue_entry.is_a?(Hash)

        cue_entry["cue"] = normalize_stringish_value(cue_entry["cue"], "cue") if cue_entry.key?("cue")

        if cue_entry["steps"].is_a?(Array)
          cue_entry["steps"].each do |step|
            next unless step.is_a?(Hash)

            step["transform"] = normalize_stringish_value(step["transform"], "transform") if step.key?("transform")
            step["answer"] = normalize_stringish_value(step["answer"], "answer") if step.key?("answer")
          end
        end
      end
    end

    entry["lemma"] = normalize_stringish_value(entry["lemma"], "lemma") if entry.key?("lemma")
    entry["verb"] = normalize_stringish_value(entry["verb"], "verb") if entry.key?("verb")

    forms = entry["forms"]
    if forms.is_a?(Hash)
      forms.each do |person, form_value|
        case form_value
        when Hash
          form_value["positive"] = normalize_stringish_value(form_value["positive"], "positive") if form_value.key?("positive")
          form_value["negative"] = normalize_stringish_value(form_value["negative"], "negative") if form_value.key?("negative")
        when Array, String, Numeric
          forms[person] = normalize_stringish_value(form_value, person.to_s)
        end
      end
    end
  end

  def normalize_stringish_value(value, key, original_source = nil)
    case value
    when Array
      original_items = original_source.is_a?(Array) ? original_source : []
      value.each_with_index.map do |item, idx|
        normalize_stringish_scalar(item, key, original_items[idx])
      end
    else
      original_item = original_source.is_a?(String) ? original_source : nil
      normalize_stringish_scalar(value, key, original_item)
    end
  end

  def normalize_stringish_scalar(value, key, original_source = nil)
    case value
    when String
      value
    when Numeric
      if original_source.is_a?(String) && !original_source.strip.empty?
        strip_matching_quotes(original_source.strip)
      else
        suggested_quoted_scalar(value, key)
      end
    else
      value
    end
  end

  def write_updated_yaml(data)
    path = Pathname.new(@path)
    output_path = path.sub_ext(".updated#{path.extname}").to_s
    File.write(output_path, YAML.dump(data))
    output_path
  end

  def original_entry_scalar(entry_idx, key, item_idx = nil)
    entry_data = @source_entry_scalars[entry_idx]
    return nil unless entry_data.is_a?(Hash)

    value = entry_data[key]
    return value if item_idx.nil?
    return nil unless value.is_a?(Array)

    value[item_idx]
  end

  def strip_matching_quotes(text)
    return text unless text.length >= 2

    if (text.start_with?("\"") && text.end_with?("\"")) ||
       (text.start_with?("'") && text.end_with?("'"))
      text[1...-1]
    else
      text
    end
  end

  def extract_entry_scalar_map
    return {} unless @raw_yaml.is_a?(String) && !@raw_yaml.empty?

    tracked_keys = %w[prompt answer alternate_prompts spoken]
    result = {}
    current_entry_idx = nil
    current_key = nil

    @raw_yaml.each_line do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")

      if line.match?(/^\s*-\s+id:\s*/)
        current_entry_idx = current_entry_idx.nil? ? 0 : current_entry_idx + 1
        result[current_entry_idx] ||= {}
        current_key = nil
        next
      end

      next if current_entry_idx.nil?

      if (match = line.match(/^\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$/))
        key = match[1]
        raw_value = match[2].to_s.rstrip

        if tracked_keys.include?(key)
          if raw_value.empty?
            result[current_entry_idx][key] = []
            current_key = key
          else
            result[current_entry_idx][key] = strip_inline_comment(raw_value)
            current_key = nil
          end
        else
          current_key = nil
        end
        next
      end

      if current_key && (match = line.match(/^\s*-\s*(.*?)\s*$/))
        result[current_entry_idx][current_key] ||= []
        result[current_entry_idx][current_key] << strip_inline_comment(match[1])
      end
    end

    result
  end

  def strip_inline_comment(text)
    text.to_s.sub(/\s+#.*\z/, "").rstrip
  end

  private

  def load_yaml(path)
    unless File.file?(path)
      error("File not found: #{path}")
      return nil
    end

    begin
      @raw_yaml = File.read(path)
      YAML.safe_load(@raw_yaml, permitted_classes: [], permitted_symbols: [], aliases: false)
    rescue Psych::SyntaxError => e
      error("YAML syntax error: #{e.message}")
      nil
    rescue StandardError => e
      error("Failed to read YAML: #{e.class}: #{e.message}")
      nil
    end
  end

  def effective_mode(drill_type)
    mode = @forced_mode || drill_type
    return nil if mode.nil? || mode.to_s.strip.empty?

    mode.to_s.strip.downcase
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
            "    id: \"my_pack\"\n" \
            "    version: 1\n" \
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

    allowed = %w[metadata entries persons]
    unknown = data.keys - allowed
    unknown.each { |k| warn("Unknown top-level key: #{k}") } unless unknown.empty?
  end

  def validate_metadata(meta)
    unless meta.is_a?(Hash)
      error("metadata must be a mapping (Hash). Got: #{meta.class}")
      return nil
    end

    required = %w[id version schema_version]
    required.each do |k|
      error("metadata missing required field: #{k}") unless meta.key?(k)
    end

    drill_type = nil

    if meta.key?("id")
      val = meta["id"]
      if val.is_a?(String)
        warn("metadata.id is empty") if val.strip.empty?
      else
        error("metadata.id must be a String. Got: #{val.class}")
      end
    end

    if meta.key?("version")
      v = meta["version"]
      if v.is_a?(Integer)
        error("metadata.version must be >= 1") if v < 1
      else
        error("metadata.version must be an Integer. Got: #{v.class}")
      end
    end

    if meta.key?("schema_version")
      v = meta["schema_version"]
      if v.is_a?(Integer)
        error("metadata.schema_version must be >= 1") if v < 1
      else
        error("metadata.schema_version must be an Integer. Got: #{v.class}")
      end
    end

    %w[shuffle_persons shuffle_cues].each do |k|
      next unless meta.key?(k)

      val = meta[k]
      if val.nil?
        warn("metadata.#{k} is nil (remove it or set true/false)")
      elsif val != true && val != false
        error("metadata.#{k} must be a Boolean. Got: #{val.class}")
      end
    end

    if meta.key?("drill_type")
      val = meta["drill_type"]
      if val.is_a?(String)
        drill_type = val.to_s.strip.downcase
        if drill_type.empty?
          warn("metadata.drill_type is empty")
          drill_type = nil
        elsif !KNOWN_DRILL_TYPES.include?(drill_type)
          error("metadata.drill_type must be one of: #{KNOWN_DRILL_TYPES.join(', ')}. Got: #{val.inspect}")
        end
      else
        error("metadata.drill_type must be a String. Got: #{val.class}")
      end
    end

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

    if meta.key?("tags")
      tags = meta["tags"]
      if tags.nil?
        warn("metadata.tags is nil (remove it or use [] )")
      elsif tags.is_a?(Array)
        tags.each_with_index do |t, j|
          if t.is_a?(String)
            warn("metadata.tags[#{j}] is empty") if t.strip.empty?
          else
            error("metadata.tags[#{j}] must be a String. Got: #{t.class}")
          end
        end
      else
        error("metadata.tags must be a list (Array) of Strings. Got: #{tags.class}")
      end
    end

    if meta.key?("tts")
      tts = meta["tts"]
      if tts.nil?
        warn("metadata.tts is nil (remove it or use a mapping)")
      elsif tts.is_a?(Hash)
        known = %w[template]
        unknown = tts.keys - known
        unknown.each { |k| warn("Unknown metadata.tts key: #{k}") }

        if tts.key?("template")
          template = tts["template"]
          if template.nil?
            warn("metadata.tts.template is nil (remove it or set a string)")
          elsif template.is_a?(String)
            warn("metadata.tts.template is empty") if template.strip.empty?
          else
            error("metadata.tts.template must be a String. Got: #{template.class}")
          end
        end
      else
        error("metadata.tts must be a mapping (Hash). Got: #{tts.class}")
      end
    end

    deprecated = {
      "pack_name" => "Use metadata.id instead.",
      "source_lang" => "Move language codes into localisation, not the pack.",
      "target_lang" => "Move language codes into localisation, not the pack.",
      "languages" => "Move language codes/names into localisation.",
      "ui" => "Move UI strings into localisation."
    }

    deprecated.each do |key, msg|
      next unless meta.key?(key)

      warn("metadata.#{key} is deprecated. #{msg}")
    end

    %w[source_lang target_lang].each do |k|
      next unless meta.key?(k)

      val = meta[k]
      if val.is_a?(String)
        unless val.match?(ISO_639_1)
          warn("metadata.#{k} should usually look like ISO 639-1 (two lowercase letters), for example 'en', 'fi'. Got: #{val.inspect}")
        end
      else
        error("metadata.#{k} must be a String. Got: #{val.class}")
      end
    end

    if @forced_mode && drill_type && @forced_mode != drill_type
      error("Mode mismatch: CLI requested #{@forced_mode.inspect} but metadata.drill_type is #{drill_type.inspect}")
    end

    drill_type
  end

  def validate_word_pack(data)
    if data.key?("persons")
      warn("Top-level `persons` is ignored for standard word packs")
    end

    metadata = data["metadata"]
    if metadata.is_a?(Hash)
      warn("metadata.shuffle_persons is ignored for standard word packs") if metadata.key?("shuffle_persons")
      warn("metadata.shuffle_cues is ignored for standard word packs") if metadata.key?("shuffle_cues")
    end

    validate_word_entries(data["entries"])
  end

  def display_entry_id(entry, idx)
    raw_id = entry.is_a?(Hash) ? entry["id"] : nil
    raw_id = raw_id.to_s.strip unless raw_id.nil?
    raw_id && !raw_id.empty? ? raw_id : format("%03d", idx + 1)
  end

  def suggested_quoted_scalar(value, label)
    return value.to_s unless value.is_a?(Numeric)

    label_text = label.to_s
    prompt_like_label = label_text == "prompt" ||
      label_text == "cue" ||
      label_text.include?(".prompt") ||
      label_text.end_with?(".cue")

    if prompt_like_label && value.is_a?(Integer)
      if value >= 0
        if (value % 3600).zero?
          hours = value / 3600
          return format("%02d:00", hours) if hours.between?(0, 23)
        elsif (value % 60).zero?
          total_minutes = value / 60
          hours = total_minutes / 60
          minutes = total_minutes % 60
          return format("%02d:%02d", hours, minutes) if hours.between?(0, 23) && minutes.between?(0, 59)
        end
      end
    end

    value.to_s
  end

  def validate_entry_string_array(values, entry, idx, key, min: 1)
    label = "entries[#{idx + 1}].#{key}"

    if values.size < min
      if min == 1
        error("#{label} must contain at least one item")
      else
        error("#{label} must contain at least #{min} items")
      end
      return
    end

    values.each_with_index do |value, j|
      if value.is_a?(String)
        error("#{label}[#{j}] is empty") if value.strip.empty?
      elsif value.is_a?(Numeric)
        entry_id = display_entry_id(entry, idx)
        suggestion = original_entry_scalar(idx, key, j)
        suggestion = strip_matching_quotes(suggestion.to_s.strip) unless suggestion.nil?
        suggestion = suggested_quoted_scalar(value, label) if suggestion.nil? || suggestion.empty?
        error(%Q{Error: - id: '#{entry_id}' #{key}: - #{suggestion} must be a string. Use quotes to properly render this. "#{suggestion}"})
      else
        error("#{label}[#{j}] must be a String. Got: #{value.class}")
      end
    end
  end

  def validate_entry_scalar_string(value, entry, idx, key, label)
    if value.is_a?(String)
      warn("#{label} is empty") if value.strip.empty?
    elsif value.is_a?(Numeric)
      entry_id = display_entry_id(entry, idx)
      suggestion = original_entry_scalar(idx, key)
      suggestion = strip_matching_quotes(suggestion.to_s.strip) unless suggestion.nil?
      suggestion = suggested_quoted_scalar(value, key) if suggestion.nil? || suggestion.empty?
      error(%Q{Error: - id: '#{entry_id}' #{key}: #{suggestion} must be a string. Use quotes to properly render this. "#{suggestion}"})
    else
      error("#{label} must be a String. Got: #{value.class}")
    end
  end

  def validate_required_string_or_string_list(entry, idx_or_label, key, min: 1)
    label = idx_or_label.is_a?(Integer) ? "entries[#{idx_or_label + 1}].#{key}" : "#{idx_or_label}.#{key}"
    value = entry[key]

    case value
    when Array
      if idx_or_label.is_a?(Integer)
        validate_entry_string_array(value, entry, idx_or_label, key, min: min)
      else
        validate_string_array(value, label, min: min)
      end
    else
      if idx_or_label.is_a?(Integer)
        validate_entry_scalar_string(value, entry, idx_or_label, key, label)
      elsif value.is_a?(String)
        warn("#{label} is empty") if value.strip.empty?
      else
        error("#{label} must be a String or a list (Array) of Strings. Got: #{value.class}")
      end
    end
  end


  def validate_transform_pack(data)
    if data.key?("persons")
      warn("Top-level `persons` is ignored for transform packs")
    end

    metadata = data["metadata"]
    if metadata.is_a?(Hash) && metadata.key?("shuffle_persons")
      warn("metadata.shuffle_persons is ignored for transform packs")
    end

    validate_transform_entries(data["entries"])
  end

  def validate_conjugate_pack(data)
    metadata = data["metadata"]
    if metadata.is_a?(Hash) && metadata.key?("shuffle_cues")
      warn("metadata.shuffle_cues is ignored for conjugate packs")
    end

    persons = validate_persons(data["persons"])
    validate_conjugate_entries(data["entries"], persons)
  end

  def validate_persons(persons)
    unless persons.is_a?(Array)
      error("Conjugation packs require a top-level `persons` list (Array). Got: #{persons.class}")
      return []
    end

    if persons.empty?
      error("Conjugation packs require at least one person in the top-level `persons` list")
      return []
    end

    normalized = []
    seen = {}

    persons.each_with_index do |person, idx|
      if person.is_a?(String)
        text = person.strip
        if text.empty?
          error("persons[#{idx}] is empty")
          next
        end

        if seen.key?(text)
          error("Duplicate person #{text.inspect} at persons[#{idx}] (already used at persons[#{seen[text]}])")
        else
          seen[text] = idx
          normalized << text
        end
      else
        error("persons[#{idx}] must be a String. Got: #{person.class}")
      end
    end

    normalized
  end

  def validate_entries_array(entries, label: "entries")
    unless entries.is_a?(Array)
      error("#{label} must be a list (Array). Got: #{entries.class}")
      return false
    end

    if entries.empty?
      warn("#{label} list is empty")
      return false
    end

    true
  end

  def validate_word_entries(entries)
    return unless validate_entries_array(entries)

    ids = {}
    entries.each_with_index do |entry, idx|
      validate_word_entry(entry, idx, ids)
    end
  end

  def validate_transform_entries(entries)
    return unless validate_entries_array(entries)

    ids = {}
    entries.each_with_index do |entry, idx|
      validate_transform_entry(entry, idx, ids)
    end
  end

  def validate_conjugate_entries(entries, persons)
    return unless validate_entries_array(entries)

    ids = {}
    entries.each_with_index do |entry, idx|
      validate_conjugate_entry(entry, idx, ids, persons)
    end
  end

  def validate_optional_id(entry, idx, ids)
    return unless entry.key?("id")

    id = entry["id"]
    if id.is_a?(String)
      warn("entries[#{idx + 1}].id is empty") if id.strip.empty?
      register_id(id, idx, ids)
    elsif id.is_a?(Integer)
      warn("entries[#{idx + 1}].id is an Integer; consider quoting it as a String") if @warn_integer_ids && !@strict
      register_id(id.to_s, idx, ids)
    else
      error("entries[#{idx + 1}].id must be a String (preferred) or Integer if present. Got: #{id.class}")
    end
  end

  def register_id(id_key, idx, ids)
    if ids.key?(id_key)
      error("Duplicate id #{id_key.inspect} at entries[#{idx + 1}] (already used at entries[#{ids[id_key]}])")
    else
      ids[id_key] = idx
    end
  end

  def validate_word_entry(entry, idx, ids)
    unless entry.is_a?(Hash)
      error("entries[#{idx + 1}] must be a mapping (Hash). Got: #{entry.class}")
      return
    end

    validate_optional_id(entry, idx, ids)

    %w[prompt answer].each do |k|
      error("entries[#{idx + 1}] missing required field: #{k}") unless entry.key?(k)
    end

    validate_required_string_or_string_list(entry, idx, "prompt", min: 1)
    validate_required_string_list(entry, idx, "answer", min: 1)
    validate_optional_string_list(entry, idx, "alternate_prompts")
    validate_optional_string_list(entry, idx, "spoken")
    validate_optional_string(entry, idx, "phonetic")
    validate_optional_string(entry, idx, "speaker")

    # Canonical keys plus compatibility aliases accepted by the runtime loader.
    allowed = %w[
      id
      prompt
      answer
      alternate_prompts
      spoken
      phonetic
      speaker
      source
      target
      also_accepted
      phon
      english
      finnish
      en
      fi
      notes
    ]
    unknown = entry.keys - allowed
    unknown.each { |k| warn("entries[#{idx + 1}] unknown key: #{k}") } unless unknown.empty?

    if @strict
      %w[phonetic speaker].each do |k|
        next unless entry.key?(k)
        v = entry[k]
        next unless v.is_a?(String) && v.strip.empty?

        error("entries[#{idx + 1}].#{k} is present but empty (strict mode)")
      end
    end
  end

  def validate_transform_entry(entry, idx, ids)
    unless entry.is_a?(Hash)
      error("entries[#{idx + 1}] must be a mapping (Hash). Got: #{entry.class}")
      return
    end

    validate_optional_id(entry, idx, ids)

    error("entries[#{idx + 1}] missing required field: prompt") unless entry.key?("prompt")
    error("entries[#{idx + 1}] missing required field: cues") unless entry.key?("cues")

    validate_required_string(entry, idx, "prompt")

    cues = entry["cues"]
    unless cues.is_a?(Array)
      error("entries[#{idx + 1}].cues must be a list (Array). Got: #{cues.class}")
      return
    end

    if cues.empty?
      error("entries[#{idx + 1}].cues must contain at least one cue")
    else
      cues.each_with_index do |cue_entry, cue_idx|
        validate_transform_cue(cue_entry, idx, cue_idx)
      end
    end

    allowed = %w[id prompt cues]
    unknown = entry.keys - allowed
    unknown.each { |k| warn("entries[#{idx + 1}] unknown key: #{k}") } unless unknown.empty?
  end

  def validate_transform_cue(cue_entry, entry_idx, cue_idx)
    unless cue_entry.is_a?(Hash)
      error("entries[#{entry_idx + 1}].cues[#{cue_idx}] must be a mapping (Hash). Got: #{cue_entry.class}")
      return
    end

    error("entries[#{entry_idx + 1}].cues[#{cue_idx}] missing required field: cue") unless cue_entry.key?("cue")
    error("entries[#{entry_idx + 1}].cues[#{cue_idx}] missing required field: steps") unless cue_entry.key?("steps")

    validate_required_string(cue_entry, "entries[#{entry_idx + 1}].cues[#{cue_idx}]", "cue")

    steps = cue_entry["steps"]
    unless steps.is_a?(Array)
      error("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps must be a list (Array). Got: #{steps.class}")
      return
    end

    if steps.empty?
      error("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps must contain at least one step")
    else
      steps.each_with_index do |step, step_idx|
        validate_transform_step(step, entry_idx, cue_idx, step_idx)
      end
    end

    allowed = %w[cue steps]
    unknown = cue_entry.keys - allowed
    unknown.each { |k| warn("entries[#{entry_idx + 1}].cues[#{cue_idx}] unknown key: #{k}") } unless unknown.empty?
  end

  def validate_transform_step(step, entry_idx, cue_idx, step_idx)
    unless step.is_a?(Hash)
      error("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}] must be a mapping (Hash). Got: #{step.class}")
      return
    end

    error("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}] missing required field: transform") unless step.key?("transform")
    error("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}] missing required field: answer") unless step.key?("answer")

    validate_required_string(step, "entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}]", "transform")
    validate_required_string_list(step, "entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}]", "answer", min: 1)

    allowed = %w[transform answer]
    unknown = step.keys - allowed
    unknown.each { |k| warn("entries[#{entry_idx + 1}].cues[#{cue_idx}].steps[#{step_idx}] unknown key: #{k}") } unless unknown.empty?
  end

  def validate_conjugate_entry(entry, idx, ids, persons)
    unless entry.is_a?(Hash)
      error("entries[#{idx + 1}] must be a mapping (Hash). Got: #{entry.class}")
      return
    end

    validate_optional_id(entry, idx, ids)

    error("entries[#{idx + 1}] missing required field: lemma") unless entry.key?("lemma") || entry.key?("verb")
    error("entries[#{idx + 1}] missing required field: forms") unless entry.key?("forms")

    lemma_key = entry.key?("lemma") ? "lemma" : (entry.key?("verb") ? "verb" : nil)
    validate_required_string(entry, idx, lemma_key) if lemma_key
    validate_optional_string(entry, idx, "gloss")

    forms = entry["forms"]
    unless forms.is_a?(Hash)
      error("entries[#{idx + 1}].forms must be a mapping (Hash). Got: #{forms.class}")
      return
    end

    persons.each do |person|
      unless forms.key?(person)
        error("entries[#{idx + 1}].forms missing person: #{person}")
        next
      end

      validate_conjugate_form(forms[person], idx, person)
    end

    extra_people = forms.keys.reject { |k| persons.include?(k) }
    extra_people.each do |person|
      warn("entries[#{idx + 1}].forms has person not listed in top-level persons: #{person.inspect}")
      validate_conjugate_form(forms[person], idx, person)
    end

    if entry.key?("verb") && !entry.key?("lemma")
      warn("entries[#{idx + 1}].verb is a legacy alias; prefer `lemma`")
    end

    allowed = %w[id lemma verb gloss forms]
    unknown = entry.keys - allowed
    unknown.each { |k| warn("entries[#{idx + 1}] unknown key: #{k}") } unless unknown.empty?
  end

  def validate_conjugate_form(raw, entry_idx, person)
    label = "entries[#{entry_idx + 1}].forms[#{person.inspect}]"

    if raw.is_a?(Hash)
      error("#{label} missing required field: positive") unless raw.key?("positive")
      error("#{label} missing required field: negative") unless raw.key?("negative")

      validate_required_string_list(raw, label, "positive", min: 1)
      validate_required_string_list(raw, label, "negative", min: 0)

      allowed = %w[positive negative]
      unknown = raw.keys - allowed
      unknown.each { |k| warn("#{label} unknown key: #{k}") } unless unknown.empty?
    elsif raw.is_a?(Array)
      warn("#{label} uses legacy flat positive-only form; prefer { positive: [...], negative: [...] }")
      validate_string_array(raw, "#{label}", min: 1)
    elsif raw.is_a?(String)
      warn("#{label} uses legacy flat positive-only form; prefer { positive: [...], negative: [...] }")
      warn("#{label} is empty") if raw.strip.empty?
    else
      error("#{label} must be a mapping (preferred), Array, or String. Got: #{raw.class}")
    end
  end

  def validate_required_string(entry, idx_or_label, key)
    label = idx_or_label.is_a?(Integer) ? "entries[#{idx_or_label + 1}].#{key}" : "#{idx_or_label}.#{key}"
    value = entry[key]

    if value.is_a?(String)
      warn("#{label} is empty") if value.strip.empty?
    else
      error("#{label} must be a String. Got: #{value.class}")
    end
  end

  def validate_required_string_list(entry, idx_or_label, key, min: 1)
    label = idx_or_label.is_a?(Integer) ? "entries[#{idx_or_label + 1}].#{key}" : "#{idx_or_label}.#{key}"
    value = entry[key]

    unless value.is_a?(Array)
      error("#{label} must be a list (Array) of Strings. Got: #{value.class}")
      return
    end

    if idx_or_label.is_a?(Integer)
      validate_entry_string_array(value, entry, idx_or_label, key, min: min)
    else
      validate_string_array(value, label, min: min)
    end
  end

  def validate_optional_string(entry, idx, key)
    return unless entry.key?(key)

    v = entry[key]
    if v.nil?
      warn("entries[#{idx + 1}].#{key} is nil (remove it or set a string)")
    elsif v.is_a?(String)
      warn("entries[#{idx + 1}].#{key} is empty") if v.strip.empty?
    else
      error("entries[#{idx + 1}].#{key} must be a String if present. Got: #{v.class}")
    end
  end

  def validate_optional_string_list(entry, idx, key)
    return unless entry.key?(key)

    value = entry[key]
    if value.nil?
      warn("entries[#{idx + 1}].#{key} is nil (remove it or use [] )")
    elsif value.is_a?(Array)
      validate_string_array(value, "entries[#{idx + 1}].#{key}", min: 0)
    else
      error("entries[#{idx + 1}].#{key} must be a list (Array) of Strings if present. Got: #{value.class}")
    end
  end

  def validate_string_array(values, label, min: 1)
    if values.size < min
      if min == 1
        error("#{label} must contain at least one item")
      else
        error("#{label} must contain at least #{min} items")
      end
      return
    end

    values.each_with_index do |value, j|
      if value.is_a?(String)
        if value.strip.empty?
          error("#{label}[#{j}] is empty")
        end
      elsif value.is_a?(Numeric)
        error("#{label}[#{j}] must be a String, but YAML parsed it as #{value.class}. If this is meant to be text, quote it. For example: \"#{value}\"")
      else
        error("#{label}[#{j}] must be a String. Got: #{value.class}")
      end
    end
  end

  def error(msg) = @errors << msg
  def warn(msg) = @warnings << msg

  def report
    puts "Linguatrain pack validation: #{@path}"
    puts

    if @updated_output_path
      puts "Updated YAML written to: #{@updated_output_path}"
      puts

      puts "Original file results:"
      puts
      print_messages("Warnings", @original_warnings) if @original_warnings.any?
      print_messages("Errors", @original_errors) if @original_errors.any?
      puts "Result: #{section_result(@original_errors, @original_warnings)}"
      puts

      puts "Updated file results:"
      puts
      print_messages("Warnings", @updated_warnings) if @updated_warnings.any?
      print_messages("Errors", @updated_errors) if @updated_errors.any?
      puts "Result: #{section_result(@updated_errors, @updated_warnings)}"

      @errors = @updated_errors.dup
      @warnings = @updated_warnings.dup

      return @updated_errors.any? ? 1 : 0
    end

    print_messages("Warnings", @original_warnings) if @original_warnings.any?
    print_messages("Errors", @original_errors) if @original_errors.any?

    @errors = @original_errors.dup
    @warnings = @original_warnings.dup

    puts "Result: #{section_result(@original_errors, @original_warnings)}"
    @original_errors.any? ? 1 : 0
  end

  def section_result(errors, warnings)
    status = errors.any? ? "FAIL" : "PASS"
    "#{status} (#{errors.size} errors, #{warnings.size} warnings)"
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

def write_csv_report(csv_path, rows)
  CSV.open(csv_path, "w") do |csv|
    csv << %w[file severity message]
    rows.each do |row|
      csv << [row[:file], row[:severity], row[:message]]
    end
  end
end

options = { strict: false, all: nil, forced_mode: nil, csv: nil, update: false }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: validate_pack.rb [options] path/to/pack.yaml"

  opts.on("--strict", "Treat some warnings as errors (stricter hygiene)") do
    options[:strict] = true
  end

  opts.on("--update", "Write a fixed YAML file alongside the original using version: 1 and schema_version: 1") do
    options[:update] = true
  end

  opts.on("--transform", "Validate the pack as a transform pack") do
    if options[:forced_mode] && options[:forced_mode] != "transform"
      raise OptionParser::InvalidOption, "--transform cannot be combined with --conjugate"
    end
    options[:forced_mode] = "transform"
  end

  opts.on("--conjugate", "Validate the pack as a conjugate pack") do
    if options[:forced_mode] && options[:forced_mode] != "conjugate"
      raise OptionParser::InvalidOption, "--conjugate cannot be combined with --transform"
    end
    options[:forced_mode] = "conjugate"
  end

  opts.on("-aDIR", "--all=DIR", "Validate all .yaml/.yml files under DIR (recursively)") do |dir|
    options[:all] = dir
  end

  opts.on("--csv=FILE", "Write validation results to CSV (especially useful with --all)") do |file|
    options[:csv] = file
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
  csv_rows = []

  files.each_with_index do |file, i|
    puts "=== [#{i + 1}/#{total_files}] #{file} ==="
    validator = PackValidator.new(path: file, strict: options[:strict], forced_mode: options[:forced_mode], update: options[:update])
    code = validator.run
    failed_files += 1 if code != 0

    validator.warnings.each do |msg|
      csv_rows << { file: file, severity: "warning", message: msg }
    end

    validator.errors.each do |msg|
      csv_rows << { file: file, severity: "error", message: msg }
    end

    puts
  end

  if options[:csv]
    write_csv_report(options[:csv], csv_rows)
    puts "CSV report written to #{options[:csv]}"
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

  exit_code = PackValidator.new(path: path, strict: options[:strict], forced_mode: options[:forced_mode], update: options[:update]).run
  exit exit_code
end