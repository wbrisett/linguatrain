# frozen_string_literal: true

require "rbconfig"
require "csv"

module Linguatrain
  module Media
    class MediaError < StandardError; end

    module_function

    def image_from(metadata, pack_path:)
      media = hash_value(metadata, :media)
      raw_image = media[:image] || media["image"]
      return nil if raw_image.nil?

      image = raw_image.is_a?(Hash) ? raw_image : { file: raw_image }
      file = (image[:file] || image["file"] || image[:path] || image["path"]).to_s.strip
      raise MediaError, "metadata.media.image requires a file path" if file.empty?

      path = if absolute_path?(file)
               File.expand_path(file)
             else
               File.expand_path(file, File.dirname(File.expand_path(pack_path)))
             end

      interactive_file = (image[:interactive_file] || image["interactive_file"]).to_s.strip
      interactive_path = if interactive_file.empty?
                           path
                         elsif absolute_path?(interactive_file)
                           File.expand_path(interactive_file)
                         else
                           File.expand_path(interactive_file, File.dirname(File.expand_path(pack_path)))
                         end

      coordinate_space = hash_value(image, :coordinate_space)
      width = integer_value(coordinate_space, :width)
      height = integer_value(coordinate_space, :height)
      focus_points = normalize_focus_points(
        image,
        width: width,
        height: height,
        pack_path: pack_path
      )

      {
        path: path,
        interactive_path: interactive_path,
        title: (image[:title] || image["title"] || File.basename(path)).to_s.strip,
        instruction: (image[:instruction] || image["instruction"]).to_s.strip,
        auto_open: boolean_value(image, :auto_open, default: true),
        coordinate_space: {
          unit: (coordinate_space[:unit] || coordinate_space["unit"] || "pixel").to_s.strip,
          origin: (coordinate_space[:origin] || coordinate_space["origin"] || "top_left").to_s.strip,
          width: width,
          height: height
        },
        focus_points: focus_points
      }
    end

    def focus_for(image, reference)
      return nil unless image.is_a?(Hash)

      image.fetch(:focus_points, {})[reference.to_s]
    end

    def validate_focus_references!(image, entries)
      return unless image

      Array(entries).each do |entry|
        reference = (entry[:focus_ref] || entry["focus_ref"]).to_s.strip
        next if reference.empty?

        focus = focus_for(image, reference)
        if focus
          entry[:focus_marker] = focus[:marker]
          entry[:focus_label] = focus[:label]
          next
        end

        entry_id = (entry[:id] || entry["id"]).to_s.strip
        raise MediaError, "Entry '#{entry_id}' references unknown image focus '#{reference}'"
      end
    end

    def open_pack_image(metadata, pack_path:, enabled: true, output: $stdout, launcher: nil, image_viewer: nil)
      image = image_from(metadata, pack_path: pack_path)
      return nil unless enabled && image && image[:auto_open]

      raise MediaError, "Image source not found: #{image[:path]}" unless File.file?(image[:path])

      if launcher
        launcher.call(image[:path])
      else
        launch_image(image[:path], image_viewer: image_viewer)
      end

      output.puts
      output.puts "Image source: #{image[:title]}"
      output.puts image[:instruction] unless image[:instruction].empty?
      image
    end

    def launch_image(path, image_viewer: nil)
      command = launcher_command(path, image_viewer: image_viewer)
      pid = Process.spawn(*command, out: File::NULL, err: File::NULL)
      Process.detach(pid)
    rescue Errno::ENOENT
      raise MediaError, "Could not open image source: the system image viewer is unavailable"
    end

    def launcher_command(path, image_viewer: nil, host_os: RbConfig::CONFIG["host_os"].to_s)
      custom_command = custom_launcher_command(path, image_viewer)
      return custom_command if custom_command

      if host_os.match?(/darwin/i)
        ["open", path]
      elsif host_os.match?(/mswin|mingw|cygwin/i)
        ["cmd", "/c", "start", "", path]
      else
        ["xdg-open", path]
      end
    end

    def custom_launcher_command(path, image_viewer)
      parts =
        case image_viewer
        when Array
          image_viewer.map(&:to_s)
        else
          executable = image_viewer.to_s.strip
          executable.empty? ? [] : [executable]
        end
      return nil if parts.empty?

      if parts.any? { |part| part.include?("{path}") }
        parts.map { |part| part.gsub("{path}", path) }
      else
        parts + [path]
      end
    end

    def hash_value(hash, key)
      return {} unless hash.is_a?(Hash)

      value = hash[key] || hash[key.to_s]
      value.is_a?(Hash) ? value : {}
    end

    def boolean_value(hash, key, default:)
      return default unless hash.is_a?(Hash)
      return hash[key] != false if hash.key?(key)
      return hash[key.to_s] != false if hash.key?(key.to_s)

      default
    end

    def integer_value(hash, key)
      return nil unless hash.is_a?(Hash)

      raw = hash[key] || hash[key.to_s]
      return raw if raw.is_a?(Integer) && raw.positive?
      return raw.to_i if raw.to_s.match?(/\A[1-9]\d*\z/)

      nil
    end

    def normalize_focus_points(image, width:, height:, pack_path:)
      file_points = load_focus_points_file(image, pack_path: pack_path)
      raw_points = image[:focus_points] || image["focus_points"] || {}
      raise MediaError, "metadata.media.image.focus_points must be a mapping" unless raw_points.is_a?(Hash)

      inline_points = raw_points.each_with_object({}) do |(id, raw), points|
        raise MediaError, "Image focus '#{id}' must be a mapping" unless raw.is_a?(Hash)

        normalized_id = id.to_s.strip
        points[normalized_id] = normalize_focus_point(normalized_id, raw, width: width, height: height)
      end

      merged = file_points.merge(inline_points)
      assign_focus_markers!(merged)
      merged.each_value do |point|
        raise MediaError, "Image focus '#{point[:id]}' x=#{point[:x]} is outside image width #{width}" if width && point[:x] >= width
        raise MediaError, "Image focus '#{point[:id]}' y=#{point[:y]} is outside image height #{height}" if height && point[:y] >= height
      end
      merged
    end

    def load_focus_points_file(image, pack_path:)
      raw_file = image[:focus_points_file] || image["focus_points_file"]
      file = raw_file.to_s.strip
      return {} if file.empty?

      path = absolute_path?(file) ? File.expand_path(file) : File.expand_path(file, File.dirname(File.expand_path(pack_path)))
      raise MediaError, "Image focus-points CSV not found: #{path}" unless File.file?(path)

      points = {}
      CSV.foreach(path, headers: true).with_index(2) do |row, line_number|
        label = row["label"].to_s.strip
        explicit_id = row["id"].to_s.strip
        id = explicit_id.empty? ? focus_id_from_label(label) : explicit_id
        raise MediaError, "Image focus-points CSV line #{line_number} requires id or label" if id.empty?
        raise MediaError, "Duplicate image focus '#{id}' in #{path}" if points.key?(id)

        raw = {
          "x" => row["x"],
          "y" => row["y"],
          "marker" => row["marker"],
          "label" => label,
          "description" => row["description"]
        }
        points[id] = normalize_focus_point(id, raw, width: nil, height: nil)
      end

      points
    rescue CSV::MalformedCSVError => e
      raise MediaError, "Invalid image focus-points CSV '#{path}': #{e.message}"
    end

    def normalize_focus_point(id, raw, width:, height:)
      x = coordinate_value(raw, :x)
      y = coordinate_value(raw, :y)
      raise MediaError, "Image focus '#{id}' requires non-negative integer x and y coordinates" unless x && y
      raise MediaError, "Image focus '#{id}' x=#{x} is outside image width #{width}" if width && x >= width
      raise MediaError, "Image focus '#{id}' y=#{y} is outside image height #{height}" if height && y >= height

      {
        id: id,
        x: x,
        y: y,
        marker: (raw[:marker] || raw["marker"]).to_s.strip,
        label: (raw[:label] || raw["label"]).to_s.strip,
        description: (raw[:description] || raw["description"]).to_s.strip
      }
    end

    def assign_focus_markers!(points)
      used = {}

      points.each_value do |point|
        marker = point[:marker].to_s.strip
        marker = marker_from_label(point[:label]) if marker.empty?
        next if marker.empty?

        raise MediaError, "Duplicate image focus marker '#{marker}'" if used[marker]

        point[:marker] = marker
        used[marker] = true
      end

      next_number = 1
      points.each_value do |point|
        next unless point[:marker].to_s.empty?

        next_number += 1 while used[next_number.to_s]
        point[:marker] = next_number.to_s
        used[next_number.to_s] = true
        next_number += 1
      end
    end

    def marker_from_label(label)
      match = label.to_s.strip.match(/\Apoint\s+([[:alnum:]]+)\z/i)
      match ? match[1] : ""
    end

    def coordinate_value(hash, key)
      raw = hash[key] || hash[key.to_s]
      return raw if raw.is_a?(Integer) && raw >= 0
      return raw.to_i if raw.to_s.match?(/\A\d+\z/)

      nil
    end

    def focus_id_from_label(label)
      label.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    end

    def absolute_path?(path)
      path.start_with?(File::SEPARATOR) || path.match?(/\A[A-Za-z]:[\\\/]/)
    end
  end
end
