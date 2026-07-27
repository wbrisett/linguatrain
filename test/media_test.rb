# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "stringio"
require "tmpdir"
require_relative "../lib/linguatrain/media"

class MediaTest < Minitest::Test
  def test_resolves_image_relative_to_pack
    Dir.mktmpdir do |dir|
      pack_path = File.join(dir, "lesson.yaml")
      image_path = File.join(dir, "scans", "scene.jpg")
      FileUtils.mkdir_p(File.dirname(image_path))
      File.write(image_path, "image")

      image = Linguatrain::Media.image_from(
        { media: { image: { file: "scans/scene.jpg" } } },
        pack_path: pack_path
      )

      assert_equal image_path, image[:path]
      assert image[:auto_open]
    end
  end

  def test_opens_declared_image_with_injected_launcher
    Dir.mktmpdir do |dir|
      image_path = File.join(dir, "scene.jpg")
      File.write(image_path, "image")
      opened = []
      output = StringIO.new

      image = Linguatrain::Media.open_pack_image(
        {
          media: {
            image: {
              file: image_path,
              title: "Summer scene",
              instruction: "Keep the scene visible while answering."
            }
          }
        },
        pack_path: File.join(dir, "lesson.yaml"),
        output: output,
        launcher: ->(path) { opened << path }
      )

      assert_equal [image_path], opened
      assert_equal image_path, image[:path]
      assert_includes output.string, "Image source: Summer scene"
      assert_includes output.string, "Keep the scene visible while answering."
    end
  end

  def test_can_disable_media_opening
    opened = []

    result = Linguatrain::Media.open_pack_image(
      { media: { image: { file: "missing.jpg" } } },
      pack_path: "/tmp/lesson.yaml",
      enabled: false,
      launcher: ->(path) { opened << path }
    )

    assert_nil result
    assert_empty opened
  end

  def test_missing_enabled_image_has_clear_error
    error = assert_raises(Linguatrain::Media::MediaError) do
      Linguatrain::Media.open_pack_image(
        { media: { image: { file: "missing.jpg" } } },
        pack_path: "/tmp/lesson.yaml",
        launcher: ->(_path) {}
      )
    end

    assert_includes error.message, "Image source not found"
  end

  def test_normalizes_native_pixel_focus_points
    image = Linguatrain::Media.image_from(
      {
        media: {
          image: {
            file: "scene.jpg",
            coordinate_space: { unit: "pixel", origin: "top_left", width: 3024, height: 4032 },
            focus_points: {
              cafe_women: { x: 547, y: 880, label: "Women at the café" }
            }
          }
        }
      },
      pack_path: "/tmp/lesson.yaml"
    )

    focus = Linguatrain::Media.focus_for(image, "cafe_women")
    assert_equal({ id: "cafe_women", x: 547, y: 880, label: "Women at the café", description: "" }, focus)
    assert_equal 3024, image.dig(:coordinate_space, :width)
    assert_equal "top_left", image.dig(:coordinate_space, :origin)
  end

  def test_rejects_out_of_bounds_focus_point
    error = assert_raises(Linguatrain::Media::MediaError) do
      Linguatrain::Media.image_from(
        {
          media: {
            image: {
              file: "scene.jpg",
              coordinate_space: { width: 100, height: 100 },
              focus_points: { missing: { x: 101, y: 50 } }
            }
          }
        },
        pack_path: "/tmp/lesson.yaml"
      )
    end

    assert_includes error.message, "outside image width"
  end

  def test_rejects_unknown_entry_focus_reference
    image = {
      focus_points: {
        "known" => { id: "known", x: 10, y: 20, label: "Known" }
      }
    }

    error = assert_raises(Linguatrain::Media::MediaError) do
      Linguatrain::Media.validate_focus_references!(
        image,
        [{ id: "scene_1", focus_ref: "unknown" }]
      )
    end

    assert_includes error.message, "unknown image focus 'unknown'"
  end

  def test_loads_multiline_focus_descriptions_from_csv
    Dir.mktmpdir do |dir|
      csv_path = File.join(dir, "coordinates.csv")
      File.write(csv_path, <<~CSV)
        label,x,y,description
        point 1,553,930,"They drink coffee
        They talk"
        point 2,1129,942,They wait
      CSV

      image = Linguatrain::Media.image_from(
        {
          media: {
            image: {
              file: "scene.jpg",
              coordinate_space: { width: 3024, height: 4032 },
              focus_points_file: "coordinates.csv"
            }
          }
        },
        pack_path: File.join(dir, "lesson.yaml")
      )

      first = Linguatrain::Media.focus_for(image, "point_1")
      second = Linguatrain::Media.focus_for(image, "point_2")
      assert_equal [553, 930], [first[:x], first[:y]]
      assert_equal "They drink coffee\nThey talk", first[:description]
      assert_equal "They wait", second[:description]
    end
  end
end
