# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/linguatrain/image_lesson_viewer"

class ImageLessonViewerTest < Minitest::Test
  def test_builds_points_with_their_linked_translation_entries
    payload = Linguatrain::ImageLessonViewer.build_payload(
      image: image_fixture("/tmp/scene.jpg"),
      metadata: { title: "Summer lesson" },
      entries: [
        {
          id: "scene_1",
          focus_ref: "point_1",
          source: "What are they doing?",
          target: ["He puhuvat."],
          hint: "Use the he-form.",
          chunks: [
            {
              id: "talk",
              source: "They talk.",
              targets: ["He puhuvat."],
              guidance: {
                hints: ["They talk.", "Base verb: puhua."],
                components: [
                  { role: "subject", form: "He", meaning: "they" },
                  {
                    role: "verb", lemma: "puhua", verb_type: 1, form: "puhuvat", person: "third", number: "plural",
                    conjugation: {
                      forms: { "minä" => "puhun", "he" => "puhuvat" },
                      coaching: {
                        questions: [
                          { prompt: "Which grade?", answers: ["strong"], explanation: "Use the strong grade." }
                        ]
                      }
                    }
                  }
                ]
              }
            }
          ]
        }
      ]
    )

    point = payload.fetch(:points).first
    entry = point.fetch(:entries).first
    assert_equal "Summer lesson", payload[:title]
    assert_match(/\Alinguatrain:image-lesson:v1:[0-9a-f]{40}\z/, payload[:progress_key])
    assert_equal "1", point[:marker]
    assert_equal "What are they doing?", entry[:source]
    assert_equal ["He puhuvat."], entry[:targets]
    assert_includes entry[:accepted_answers], "He puhuvat."
    assert_equal ["Base verb: puhua."], entry.dig(:chunks, 0, :guidance_hints)
    assert_equal "puhua", entry.dig(:chunks, 0, :verb_coach, :lemma)
    assert_equal "1", entry.dig(:chunks, 0, :verb_coach, :verb_type)
    assert_equal "He", entry.dig(:chunks, 0, :verb_coach, :subject, :form)
    assert_equal({ "minä" => "puhun", "he" => "puhuvat" }, entry.dig(:chunks, 0, :verb_coach, :forms))
    assert_equal "Which grade?", entry.dig(:chunks, 0, :verb_coach, :questions, 0, :prompt)
  end

  def test_accepts_individual_chunks_and_complete_multi_chunk_answers
    entry = {
      target: ["He juovat kahvia. He puhuvat."],
      chunks: [
        { targets: ["He juovat kahvia.", "Naiset juovat kahvia."] },
        { targets: ["He puhuvat.", "Naiset puhuvat."] }
      ]
    }

    accepted = Linguatrain::ImageLessonViewer.accepted_answers_for(entry)

    assert_includes accepted, "He juovat kahvia."
    assert_includes accepted, "He puhuvat."
    assert_includes accepted, "He juovat kahvia. He puhuvat."
    assert_includes accepted, "Naiset juovat kahvia. Naiset puhuvat."
  end

  def test_writes_safe_interactive_html_and_uses_the_clean_interactive_image
    Dir.mktmpdir do |dir|
      marked_path = File.join(dir, "marked image.png")
      clean_path = File.join(dir, "clean image.jpg")
      output_path = File.join(dir, "lesson.html")
      File.write(marked_path, "marked")
      File.write(clean_path, "clean")
      image = image_fixture(marked_path).merge(interactive_path: clean_path)
      entries = [{ focus_ref: "point_1", source: "Choose </script> safely", target: ["Answer"] }]

      Linguatrain::ImageLessonViewer.write(
        output_path,
        image: image,
        entries: entries,
        metadata: { id: "lesson" }
      )

      html = File.read(output_path)
      assert_includes html, "file://#{clean_path.gsub(' ', '%20')}"
      assert_includes html, 'class="markers"'
      assert_includes html, "Check answer"
      assert_includes html, "Check answers"
      assert_includes html, "Action ${index + 1} of ${groups.length}"
      assert_includes html, "hint-group-title"
      assert_includes html, "Overall"
      assert_includes html, "Your answer in Finnish"
      assert_includes html, "Reveal answer"
      assert_includes html, "Reset progress"
      assert_includes html, "localStorage.setItem(data.progress_key"
      assert_includes html, "of ${linkedPoints.length} completed"
      assert_includes html, "marker.complete"
      assert_includes html, "Practice ${chunk.verb_coach.lemma}"
      assert_includes html, "likelyVerbError"
      assert_includes html, "What type of verb is"
      refute_includes html, "Choose </script> safely"
      assert_includes html, "Choose \\u003c/script\\u003e safely"
    end
  end

  def test_rejects_a_lesson_without_linked_focus_entries
    Dir.mktmpdir do |dir|
      image_path = File.join(dir, "scene.jpg")
      File.write(image_path, "image")

      error = assert_raises(Linguatrain::ImageLessonViewer::ViewerError) do
        Linguatrain::ImageLessonViewer.write(
          File.join(dir, "lesson.html"),
          image: image_fixture(image_path),
          entries: [{ focus_ref: "elsewhere", source: "Question", target: ["Answer"] }]
        )
      end

      assert_includes error.message, "no entries linked by focus_ref"
    end
  end

  def test_open_accepts_an_injected_launcher
    opened = []

    Linguatrain::ImageLessonViewer.open("/tmp/lesson.html", launcher: ->(path) { opened << path })

    assert_equal ["/tmp/lesson.html"], opened
  end

  private

  def image_fixture(path)
    {
      path: path,
      title: "Summer scene",
      instruction: "Choose a marker.",
      coordinate_space: { width: 1000, height: 800 },
      focus_points: {
        "point_1" => {
          id: "point_1",
          marker: "1",
          label: "Café",
          description: "They talk",
          x: 200,
          y: 300
        }
      }
    }
  end
end
