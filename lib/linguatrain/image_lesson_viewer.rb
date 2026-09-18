# frozen_string_literal: true

require "cgi"
require "digest"
require "json"
require "tmpdir"
require_relative "media"

module Linguatrain
  module ImageLessonViewer
    class ViewerError < StandardError; end

    module_function

    def temporary_path(pack_path:, metadata: {})
      raw_id = value(metadata, :id).to_s.strip
      raw_id = File.basename(pack_path.to_s, File.extname(pack_path.to_s)) if raw_id.empty?
      safe_id = raw_id.gsub(/[^a-zA-Z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "")
      safe_id = "linguatrain_image_lesson" if safe_id.empty?
      fingerprint = Digest::SHA1.hexdigest(File.expand_path(pack_path.to_s))[0, 10]
      File.join(Dir.tmpdir, "#{safe_id}_#{fingerprint}.html")
    end

    def write(path, image:, entries:, metadata: {})
      raise ViewerError, "The image lesson has no image" unless image.is_a?(Hash)
      viewer_image_path = image[:interactive_path] || image[:path]
      raise ViewerError, "Image source not found: #{viewer_image_path}" unless File.file?(viewer_image_path.to_s)

      payload = build_payload(image: image, entries: entries, metadata: metadata)
      linked_count = payload.fetch(:points).sum { |point| point.fetch(:entries).length }
      raise ViewerError, "The image lesson has no entries linked by focus_ref" if linked_count.zero?

      destination = File.expand_path(path.to_s)
      parent = File.dirname(destination)
      raise ViewerError, "Output directory does not exist: #{parent}" unless Dir.exist?(parent)

      File.write(destination, render(payload))
      destination
    rescue SystemCallError => e
      raise ViewerError, "Could not write image lesson: #{e.message}"
    end

    def open(path, launcher: nil)
      if launcher
        launcher.call(path)
      else
        command = Media.launcher_command(File.expand_path(path.to_s))
        pid = Process.spawn(*command, out: File::NULL, err: File::NULL)
        Process.detach(pid)
      end
      path
    rescue SystemCallError => e
      raise ViewerError, "Could not open image lesson: #{e.message}"
    end

    def build_payload(image:, entries:, metadata: {})
      entries_by_focus = Array(entries).group_by { |entry| value(entry, :focus_ref).to_s.strip }
      pack_id = first_present(value(metadata, :id), value(metadata, :title), image[:title], image[:path])
      progress_key = "linguatrain:image-lesson:v1:#{Digest::SHA1.hexdigest(pack_id)}"
      points = image.fetch(:focus_points, {}).values.map do |point|
        reference = value(point, :id).to_s
        {
          id: reference,
          marker: value(point, :marker).to_s,
          label: value(point, :label).to_s,
          description: value(point, :description).to_s,
          x: value(point, :x),
          y: value(point, :y),
          entries: Array(entries_by_focus[reference]).map { |entry| viewer_entry(entry) }
        }
      end

      {
        title: first_present(value(metadata, :title), value(metadata, :id), image[:title], "Image lesson"),
        progress_key: progress_key,
        instruction: image[:instruction].to_s,
        image: {
          path: File.expand_path((image[:interactive_path] || image[:path]).to_s),
          title: image[:title].to_s,
          width: image.dig(:coordinate_space, :width),
          height: image.dig(:coordinate_space, :height)
        },
        points: points
      }
    end

    def viewer_entry(entry)
      {
        id: value(entry, :id).to_s,
        source: value(entry, :source).to_s,
        targets: string_list(value(entry, :target)),
        accepted_answers: accepted_answers_for(entry),
        literal: value(entry, :literal).to_s,
        phonetic: value(entry, :phonetic).to_s,
        hint: value(entry, :hint).to_s,
        chunks: Array(value(entry, :chunks)).map do |chunk|
          guidance = value(chunk, :guidance)
          chunk_source = value(chunk, :source).to_s
          guidance_hints = guidance.is_a?(Hash) ? string_list(value(guidance, :hints)) : []
          guidance_hints.reject! do |hint|
            comparable_text(hint) == comparable_text(chunk_source)
          end
          {
            id: value(chunk, :id).to_s,
            source: chunk_source,
            targets: string_list(value(chunk, :targets)),
            literal: value(chunk, :literal).to_s,
            hint: value(chunk, :hint).to_s,
            guidance_hints: guidance_hints,
            verb_coach: verb_coach_for(guidance)
          }
        end
      }
    end

    def verb_coach_for(guidance)
      return nil unless guidance.is_a?(Hash)

      components = Array(value(guidance, :components))
      subject = components.find { |component| value(component, :role).to_s.strip.downcase == "subject" }
      verb = components.find { |component| value(component, :role).to_s.strip.downcase == "verb" }
      return nil unless verb.is_a?(Hash)

      conjugation = value(verb, :conjugation)
      forms = conjugation.is_a?(Hash) ? value(conjugation, :forms) : nil
      coaching = conjugation.is_a?(Hash) ? value(conjugation, :coaching) : nil
      questions = coaching.is_a?(Hash) ? Array(value(coaching, :questions)) : []
      normalized_questions = questions.filter_map do |question|
        next unless question.is_a?(Hash)

        prompt = value(question, :prompt).to_s.strip
        answers = string_list(value(question, :answers))
        answers.concat(string_list(value(question, :answer)))
        next if prompt.empty? || answers.empty?

        {
          prompt: prompt,
          answers: answers.uniq,
          explanation: value(question, :explanation).to_s.strip
        }
      end

      {
        subject: subject.is_a?(Hash) ? {
          form: value(subject, :form).to_s.strip,
          meaning: value(subject, :meaning).to_s.strip
        } : nil,
        lemma: value(verb, :lemma).to_s.strip,
        verb_type: value(verb, :verb_type).to_s.strip,
        form: value(verb, :form).to_s.strip,
        person: value(verb, :person).to_s.strip,
        number: value(verb, :number).to_s.strip,
        build: value(verb, :build).to_s.strip,
        forms: forms.is_a?(Hash) ? forms.to_h { |key, form| [key.to_s, form.to_s] } : {},
        questions: normalized_questions
      }
    end

    def accepted_answers_for(entry)
      chunks = Array(value(entry, :chunks))
      answers = string_list(value(entry, :target))
      chunks.each { |chunk| answers.concat(string_list(value(chunk, :targets))) }

      if chunks.length > 1
        combinations = [""]
        chunks.each do |chunk|
          targets = string_list(value(chunk, :targets))
          combinations = combinations.product(targets).map { |prefix, target| "#{prefix} #{target}".strip }
          combinations = combinations.take(256)
        end
        answers.concat(combinations)
      end

      answers.map(&:strip).reject(&:empty?).uniq
    end

    def render(payload)
      json = JSON.generate(payload).gsub("<", "\\u003c").gsub(">", "\\u003e").gsub("&", "\\u0026")
      image_url = file_url(payload.dig(:image, :path))
      title = CGI.escapeHTML(payload.fetch(:title).to_s)

      <<~HTML
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{title} · Linguatrain</title>
          <style>
            :root {
              color-scheme: light;
              --paper: #f5f0e6;
              --panel: #fffdf8;
              --ink: #202620;
              --muted: #687067;
              --line: #d9d1c2;
              --accent: #d85a30;
              --accent-dark: #7a271a;
              --teal: #167c78;
              --complete: #167044;
              --shadow: 0 18px 48px rgba(44, 35, 24, .14);
            }
            * { box-sizing: border-box; }
            body {
              margin: 0;
              background: radial-gradient(circle at top left, #fffaf0 0, var(--paper) 46%, #ebe4d8 100%);
              color: var(--ink);
              font-family: ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              min-height: 100vh;
            }
            header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              gap: 22px;
              padding: 24px clamp(18px, 4vw, 54px) 18px;
              border-bottom: 1px solid var(--line);
              background: rgba(255, 253, 248, .88);
              backdrop-filter: blur(12px);
            }
            header h1 { margin: 0; font: 700 clamp(23px, 3vw, 36px)/1.15 Georgia, serif; }
            header p { margin: 8px 0 0; color: var(--muted); max-width: 75ch; }
            .progress-tools { display: flex; align-items: center; gap: 12px; flex: 0 0 auto; }
            .progress-summary { color: var(--complete); font-weight: 800; white-space: nowrap; }
            main {
              display: grid;
              grid-template-columns: minmax(0, 1.45fr) minmax(320px, .75fr);
              gap: clamp(18px, 3vw, 38px);
              padding: clamp(18px, 3vw, 42px);
              align-items: start;
            }
            .image-card, .lesson-panel {
              background: var(--panel);
              border: 1px solid var(--line);
              border-radius: 18px;
              box-shadow: var(--shadow);
            }
            .image-card { padding: 12px; }
            .image-stage { position: relative; line-height: 0; overflow: hidden; border-radius: 11px; background: #ded8cc; }
            .image-stage img { display: block; width: 100%; height: auto; }
            .marker-lines, .markers { position: absolute; inset: 0; width: 100%; height: 100%; }
            .marker-lines { pointer-events: none; }
            .marker-lines line { stroke: var(--accent-dark); stroke-width: 3; vector-effect: non-scaling-stroke; }
            .marker-lines circle { fill: var(--accent); }
            .marker-lines line.complete { stroke: var(--complete); }
            .marker-lines circle.complete { fill: var(--complete); }
            .marker {
              position: absolute;
              transform: translate(-50%, -50%);
              width: clamp(34px, 3.2vw, 48px);
              height: clamp(34px, 3.2vw, 48px);
              border-radius: 50%;
              border: 3px solid white;
              background: var(--accent);
              color: white;
              font-weight: 800;
              font-size: clamp(14px, 1.5vw, 20px);
              cursor: pointer;
              box-shadow: 0 3px 10px rgba(32, 25, 18, .35);
              transition: transform .15s ease, background .15s ease;
            }
            .marker:hover, .marker:focus-visible { transform: translate(-50%, -50%) scale(1.12); outline: 4px solid rgba(22, 124, 120, .36); }
            .marker.active { background: var(--teal); }
            .marker.complete { background: var(--complete); }
            .marker.complete::after {
              content: "✓";
              position: absolute;
              right: -7px;
              top: -7px;
              display: grid;
              place-items: center;
              width: 19px;
              height: 19px;
              border: 2px solid white;
              border-radius: 50%;
              background: var(--complete);
              color: white;
              font-size: 12px;
              line-height: 1;
            }
            .marker.unlinked { opacity: .48; }
            .lesson-panel { position: sticky; top: 22px; padding: clamp(20px, 3vw, 34px); min-height: 320px; }
            .eyebrow { color: var(--teal); text-transform: uppercase; letter-spacing: .1em; font-size: 12px; font-weight: 800; }
            .lesson-panel h2 { margin: 8px 0 6px; font: 700 clamp(22px, 2.2vw, 30px)/1.2 Georgia, serif; }
            .description { color: var(--muted); margin: 0 0 22px; white-space: pre-line; }
            .empty { display: grid; place-items: center; min-height: 240px; color: var(--muted); text-align: center; }
            .entry { border-top: 1px solid var(--line); padding-top: 20px; margin-top: 20px; }
            .entry:first-of-type { border-top: 0; padding-top: 0; margin-top: 0; }
            .question { font-size: 19px; line-height: 1.45; margin: 0 0 16px; }
            .answer-form { margin-bottom: 10px; }
            .answer-row { margin-bottom: 11px; }
            .answer-row label { display: block; margin-bottom: 6px; color: var(--muted); font-size: 13px; font-weight: 700; }
            .answer-input {
              display: block;
              width: 100%;
              min-width: 0;
              border: 1px solid #aaa397;
              border-radius: 10px;
              padding: 11px 13px;
              background: white;
              color: var(--ink);
              font: inherit;
            }
            .answer-input:focus { outline: 3px solid rgba(22, 124, 120, .25); border-color: var(--teal); }
            .answer-input.correct { border-color: #167044; background: #f0faf5; }
            .answer-input.incorrect { border-color: #a33b24; background: #fff5f2; }
            .answer-form button { margin-top: 1px; }
            .feedback { min-height: 24px; margin: 0 0 12px; font-weight: 700; }
            .feedback.correct { color: #167044; }
            .feedback.incorrect { color: #a33b24; }
            .practice-offers { margin: 0 0 14px; }
            .practice-offers > p { margin: 0 0 8px; color: var(--accent-dark); font-weight: 700; }
            .practice-card {
              margin: 4px 0 16px;
              padding: 16px;
              border: 1px solid rgba(22, 124, 120, .35);
              border-left: 4px solid var(--teal);
              border-radius: 5px 12px 12px 5px;
              background: #edf7f4;
            }
            .practice-card h3 { margin: 0 0 5px; font: 700 20px/1.25 Georgia, serif; }
            .practice-card p { margin: 6px 0 12px; }
            .practice-card .answer-input { margin: 8px 0 10px; }
            .practice-feedback { min-height: 22px; margin: 8px 0 0 !important; font-weight: 700; }
            .practice-progress { color: var(--teal); font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: .06em; }
            .actions { display: flex; flex-wrap: wrap; gap: 9px; margin-bottom: 14px; }
            button.action {
              border: 1px solid var(--teal);
              border-radius: 999px;
              padding: 9px 14px;
              background: transparent;
              color: var(--teal);
              font-weight: 700;
              cursor: pointer;
            }
            button.action.primary { color: white; background: var(--teal); }
            .reveal { border-left: 4px solid var(--teal); background: #edf7f4; padding: 13px 15px; border-radius: 4px 10px 10px 4px; margin-top: 12px; }
            .reveal strong { display: block; margin-bottom: 5px; }
            .reveal ul { padding-left: 20px; margin: 7px 0 0; }
            .hint-group + .hint-group { margin-top: 15px; padding-top: 15px; border-top: 1px solid rgba(22, 124, 120, .2); }
            .hint-group-title { color: var(--teal); font-size: 14px; }
            .chunk { margin-top: 12px; padding-top: 12px; border-top: 1px solid rgba(22, 124, 120, .2); }
            .chunk:first-child { border-top: 0; margin-top: 0; padding-top: 0; }
            .small { color: var(--muted); font-size: 14px; }
            [hidden] { display: none !important; }
            @media (max-width: 900px) {
              header { align-items: flex-start; flex-direction: column; }
              main { grid-template-columns: 1fr; }
              .lesson-panel { position: static; }
            }
          </style>
        </head>
        <body>
          <header>
            <div>
              <h1>#{title}</h1>
              <p id="instruction"></p>
            </div>
            <div class="progress-tools">
              <span class="progress-summary" id="progressSummary"></span>
              <button class="action" id="resetProgress" type="button">Reset progress</button>
            </div>
          </header>
          <main>
            <section class="image-card" aria-label="Interactive lesson image">
              <div class="image-stage" id="stage">
                <img id="lessonImage" src="#{CGI.escapeHTML(image_url)}" alt="#{CGI.escapeHTML(payload.dig(:image, :title).to_s)}">
                <svg class="marker-lines" id="markerLines" aria-hidden="true"></svg>
                <div class="markers" id="markers"></div>
              </div>
            </section>
            <aside class="lesson-panel" id="panel" aria-live="polite">
              <div class="empty">Choose a numbered marker to explore that part of the scene.</div>
            </aside>
          </main>
          <script id="lessonData" type="application/json">#{json}</script>
          <script>
            (() => {
              const data = JSON.parse(document.getElementById('lessonData').textContent);
              const image = document.getElementById('lessonImage');
              const markers = document.getElementById('markers');
              const lines = document.getElementById('markerLines');
              const panel = document.getElementById('panel');
              const progressSummary = document.getElementById('progressSummary');
              const resetProgress = document.getElementById('resetProgress');
              const markerVisuals = new Map();
              let selectedPoint = null;
              let selectedButton = null;
              document.getElementById('instruction').textContent = data.instruction || 'Choose a marker to view its lesson content.';

              function emptyProgress() {
                return { entries: {} };
              }

              function loadProgress() {
                try {
                  const saved = JSON.parse(localStorage.getItem(data.progress_key));
                  return saved && saved.entries && typeof saved.entries === 'object' ? saved : emptyProgress();
                } catch (_error) {
                  return emptyProgress();
                }
              }

              let progress = loadProgress();

              function saveProgress() {
                try {
                  localStorage.setItem(data.progress_key, JSON.stringify(progress));
                } catch (_error) {
                  // Progress still remains available for this open page if browser storage is unavailable.
                }
              }

              const text = (tag, value, className) => {
                const node = document.createElement(tag);
                node.textContent = value;
                if (className) node.className = className;
                return node;
              };

              function hintGroupsFor(entry) {
                if (entry.chunks.length > 1) {
                  const groups = [];
                  const chunkHints = entry.chunks.map(chunk =>
                    [...new Set([chunk.hint, ...chunk.guidance_hints].filter(Boolean))]
                  );
                  const sharedHints = chunkHints[0].filter(hint =>
                    chunkHints.every(hints => hints.includes(hint))
                  );
                  const overallHints = [...new Set([entry.hint, ...sharedHints].filter(Boolean))];
                  if (overallHints.length) groups.push({ label: 'Overall', hints: overallHints });
                  chunkHints.forEach((authoredHints, index) => {
                    const hints = authoredHints.filter(hint => !sharedHints.includes(hint));
                    if (hints.length) {
                      groups.push({ label: `Action ${index + 1}`, hints: [...new Set(hints)] });
                    }
                  });
                  return groups;
                }

                const hints = [];
                if (entry.hint) hints.push(entry.hint);
                entry.chunks.forEach(chunk => {
                  if (chunk.hint) hints.push(chunk.hint);
                  hints.push(...chunk.guidance_hints);
                });
                const unique = [...new Set(hints.filter(Boolean))];
                return unique.length ? [{ label: '', hints: unique }] : [];
              }

              function normalizeAnswer(value) {
                return String(value || '')
                  .normalize('NFC')
                  .toLocaleLowerCase('fi-FI')
                  .replace(/[^\\p{L}\\p{N}]+/gu, ' ')
                  .trim()
                  .replace(/\\s+/g, ' ');
              }

              function answerGroups(entry) {
                if (entry.chunks.length > 1) {
                  return entry.chunks.map(chunk =>
                    [...new Set(chunk.targets.map(normalizeAnswer).filter(Boolean))]
                  );
                }
                return [[...new Set(entry.accepted_answers.map(normalizeAnswer).filter(Boolean))]];
              }

              function scoresFor(entry, values) {
                return answerGroups(entry).map((answers, index) => {
                  const given = normalizeAnswer(values[index]);
                  return Boolean(given && answers.includes(given));
                });
              }

              function entryIsComplete(entry) {
                const saved = progress.entries[entry.id];
                if (!saved || !Array.isArray(saved.values)) return false;
                const scores = scoresFor(entry, saved.values);
                return scores.length > 0 && scores.every(Boolean);
              }

              function pointIsComplete(point) {
                return point.entries.length > 0 && point.entries.every(entryIsComplete);
              }

              function editDistance(left, right) {
                const previous = Array.from({ length: right.length + 1 }, (_item, index) => index);
                for (let row = 1; row <= left.length; row += 1) {
                  const current = [row];
                  for (let column = 1; column <= right.length; column += 1) {
                    const substitution = previous[column - 1] + (left[row - 1] === right[column - 1] ? 0 : 1);
                    const insertion = current[column - 1] + 1;
                    const deletion = previous[column] + 1;
                    current.push(Math.min(substitution, insertion, deletion));
                  }
                  previous.splice(0, previous.length, ...current);
                }
                return previous.at(-1);
              }

              function likelyVerbError(rawAnswer, chunk) {
                const coach = chunk.verb_coach;
                if (!coach || !coach.form || !coach.lemma) return false;
                const words = normalizeAnswer(rawAnswer).split(' ').filter(word => word.length >= 3);
                const expected = normalizeAnswer(coach.form);
                const lemma = normalizeAnswer(coach.lemma);
                if (!words.length || words.includes(expected)) return false;

                return words.some(word => [expected, lemma].some(candidate => {
                  if (!candidate || word[0] !== candidate[0]) return false;
                  const threshold = Math.max(2, Math.floor(candidate.length * .45));
                  return editDistance(word, candidate) <= threshold;
                }));
              }

              function coachingSteps(chunk) {
                const coach = chunk.verb_coach;
                if (!coach) return [];
                const steps = [];
                if (coach.subject && coach.subject.form) {
                  steps.push({
                    prompt: `What is the Finnish subject for “${coach.subject.meaning || coach.subject.form}”?`,
                    answers: [coach.subject.form],
                    explanation: `${coach.subject.form} is the subject required by this action.`
                  });
                }
                if (coach.person && coach.number) {
                  const label = `${coach.person}-person ${coach.number}`;
                  steps.push({
                    prompt: `Which person and number does “${coach.subject?.form || 'this subject'}” require?`,
                    answers: [label, `${coach.person} person ${coach.number}`, `${coach.person} ${coach.number}`],
                    explanation: `Use the ${label} form.`
                  });
                }
                if (coach.verb_type) {
                  steps.push({
                    prompt: `What type of verb is “${coach.lemma}”?`,
                    answers: [coach.verb_type, `type ${coach.verb_type}`, `verb type ${coach.verb_type}`],
                    explanation: `${coach.lemma} is a Type ${coach.verb_type} verb.`
                  });
                }
                steps.push(...coach.questions);
                steps.push({
                  prompt: `Conjugate “${coach.lemma}” for “${coach.subject?.form || coach.person}”.`,
                  answers: [coach.form],
                  explanation: coach.build || `The required form is ${coach.form}.`
                });
                return steps;
              }

              function startVerbPractice(entry, chunk, actionIndex, container, returnInput, onReturn) {
                const coach = chunk.verb_coach;
                const steps = coachingSteps(chunk);
                if (!coach || !steps.length) return;
                const card = document.createElement('div');
                card.className = 'practice-card';
                container.replaceChildren(card);
                let stepIndex = 0;

                const renderStep = () => {
                  card.replaceChildren();
                  card.append(text('div', `Step ${stepIndex + 1} of ${steps.length}`, 'practice-progress'));
                  card.append(text('h3', `Practice ${coach.lemma}`));
                  const step = steps[stepIndex];
                  card.append(text('p', step.prompt));
                  const form = document.createElement('form');
                  const input = document.createElement('input');
                  input.className = 'answer-input';
                  input.type = 'text';
                  input.autocomplete = 'off';
                  input.spellcheck = true;
                  input.placeholder = 'Kirjoita vastaus…';
                  const check = text('button', 'Check', 'action primary');
                  check.type = 'submit';
                  const feedback = text('p', '', 'practice-feedback');
                  form.append(input, check, feedback);
                  form.addEventListener('submit', event => {
                    event.preventDefault();
                    const accepted = step.answers.map(normalizeAnswer);
                    if (!accepted.includes(normalizeAnswer(input.value))) {
                      feedback.textContent = 'Not quite. Try again.';
                      feedback.style.color = '#a33b24';
                      return;
                    }

                    feedback.textContent = `✓ ${step.explanation || 'Correct!'}`;
                    feedback.style.color = '#167044';
                    input.disabled = true;
                    check.textContent = stepIndex + 1 === steps.length ? 'Finish practice' : 'Continue';
                    check.type = 'button';
                    check.addEventListener('click', () => {
                      stepIndex += 1;
                      if (stepIndex < steps.length) {
                        renderStep();
                        return;
                      }

                      const saved = progress.entries[entry.id] || { values: [] };
                      saved.coaching ||= {};
                      saved.coaching[actionIndex] = { completed: true };
                      progress.entries[entry.id] = saved;
                      saveProgress();
                      card.replaceChildren();
                      card.append(text('h3', 'Practice complete'));
                      card.append(text('p', `Now use ${coach.form} in the complete action.`));
                      const returnButton = text('button', 'Return to the action', 'action primary');
                      returnButton.type = 'button';
                      returnButton.addEventListener('click', () => {
                        onReturn();
                        returnInput.focus();
                      });
                      card.append(returnButton);
                    }, { once: true });
                  });
                  card.append(form);
                  input.focus();
                };

                renderStep();
              }

              function refreshProgressDisplay() {
                const linkedPoints = data.points.filter(point => point.entries.length > 0);
                const completed = linkedPoints.filter(pointIsComplete).length;
                progressSummary.textContent = `${completed} of ${linkedPoints.length} completed`;
                linkedPoints.forEach(point => {
                  const visuals = markerVisuals.get(point.id);
                  if (!visuals) return;
                  const complete = pointIsComplete(point);
                  visuals.button.classList.toggle('complete', complete);
                  visuals.line.classList.toggle('complete', complete);
                  visuals.dot.classList.toggle('complete', complete);
                  const baseLabel = `Marker ${point.marker}: ${point.label || point.description || 'image point'}`;
                  visuals.button.setAttribute('aria-label', complete ? `${baseLabel}, completed` : baseLabel);
                });
              }

              function answerForm(entry, onProgressChange) {
                const form = document.createElement('form');
                form.className = 'answer-form';
                const groups = answerGroups(entry);
                const inputs = groups.map((answers, index) => {
                  const row = document.createElement('div');
                  row.className = 'answer-row';
                  const inputId = `answer-${entry.id || 'entry'}-${index + 1}`;
                  const labelText = groups.length > 1 ? `Action ${index + 1} of ${groups.length}` : 'Your answer in Finnish';
                  const label = text('label', labelText);
                  label.htmlFor = inputId;
                  const input = document.createElement('input');
                  input.id = inputId;
                  input.className = 'answer-input';
                  input.type = 'text';
                  input.autocomplete = 'off';
                  input.spellcheck = true;
                  input.placeholder = 'Kirjoita vastaus…';
                  row.append(label, input);
                  form.append(row);
                  return { input, answers };
                });
                const checkButton = text('button', groups.length > 1 ? 'Check answers' : 'Check answer', 'action primary');
                checkButton.type = 'submit';
                const feedback = text('p', '', 'feedback');
                const practiceArea = document.createElement('div');
                practiceArea.className = 'practice-offers';
                form.append(checkButton);
                const evaluate = () => {
                  let correct = 0;
                  let answered = 0;
                  const scores = inputs.map(({ input, answers }) => {
                    const given = normalizeAnswer(input.value);
                    input.classList.remove('correct', 'incorrect');
                    if (given) answered += 1;
                    if (given && answers.includes(given)) {
                      correct += 1;
                      input.classList.add('correct');
                      return true;
                    } else {
                      input.classList.add('incorrect');
                      return false;
                    }
                  });
                  feedback.className = 'feedback';
                  if (answered === 0) {
                    feedback.textContent = groups.length > 1 ? 'Type an answer for each action.' : 'Type an answer first.';
                    feedback.classList.add('incorrect');
                  } else if (correct === groups.length) {
                    feedback.textContent = groups.length > 1 ? `✓ All ${groups.length} actions correct!` : '✓ Correct!';
                    feedback.classList.add('correct');
                  } else {
                    feedback.textContent = groups.length > 1
                      ? `${correct} of ${groups.length} actions correct. Try the highlighted fields again or show a hint.`
                      : 'Not quite. Try again or show a hint.';
                    feedback.classList.add('incorrect');
                  }
                  return { correct, answered, scores };
                };
                const renderPracticeOffers = () => {
                  practiceArea.replaceChildren();
                  const state = progress.entries[entry.id];
                  if (!state || !state.failures) return;
                  const offers = inputs.map(({ input }, index) => {
                    const chunk = entry.chunks.length > 1 ? entry.chunks[index] : entry.chunks[0];
                    const completedAction = answerGroups(entry)[index].includes(normalizeAnswer(input.value));
                    if (!chunk?.verb_coach || completedAction || Number(state.failures[index] || 0) < 2) return null;
                    return { chunk, index, input };
                  }).filter(Boolean);
                  if (!offers.length) return;

                  practiceArea.append(text('p', 'It looks like the verb form may be the difficult part.'));
                  const buttons = document.createElement('div');
                  buttons.className = 'actions';
                  offers.forEach(({ chunk, index, input }) => {
                    const completed = Boolean(state.coaching?.[index]?.completed);
                    const label = completed ? `Practice ${chunk.verb_coach.lemma} again` : `Practice ${chunk.verb_coach.lemma}`;
                    const button = text('button', label, 'action');
                    button.type = 'button';
                    button.addEventListener('click', () => {
                      startVerbPractice(entry, chunk, index, practiceArea, input, renderPracticeOffers);
                    });
                    buttons.append(button);
                  });
                  practiceArea.append(buttons);
                };
                const saved = progress.entries[entry.id];
                if (saved && Array.isArray(saved.values)) {
                  inputs.forEach(({ input }, index) => { input.value = saved.values[index] || ''; });
                  if (saved.values.some(value => normalizeAnswer(value))) evaluate();
                }
                renderPracticeOffers();
                form.addEventListener('submit', event => {
                  event.preventDefault();
                  const state = progress.entries[entry.id] || {};
                  state.values = inputs.map(({ input }) => input.value);
                  state.failures ||= {};
                  state.coaching ||= {};
                  const result = evaluate();
                  inputs.forEach(({ input }, index) => {
                    const chunk = entry.chunks.length > 1 ? entry.chunks[index] : entry.chunks[0];
                    if (!result.scores[index] && input.value.trim() && chunk && likelyVerbError(input.value, chunk)) {
                      state.failures[index] = Number(state.failures[index] || 0) + 1;
                    }
                  });
                  progress.entries[entry.id] = state;
                  saveProgress();
                  onProgressChange();
                  renderPracticeOffers();
                });
                return { form, feedback, practiceArea, firstInput: inputs[0].input };
              }

              function answerBox(entry) {
                const box = document.createElement('div');
                box.className = 'reveal';
                box.hidden = true;
                box.append(text('strong', 'Answer'));
                entry.targets.forEach(answer => box.append(text('div', answer)));
                if (entry.literal) box.append(text('div', `Literal: ${entry.literal}`, 'small'));
                if (entry.phonetic) box.append(text('div', `Pronunciation: ${entry.phonetic}`, 'small'));
                if (entry.chunks.length > 1) {
                  entry.chunks.forEach(chunk => {
                    const row = document.createElement('div');
                    row.className = 'chunk';
                    row.append(text('strong', chunk.source));
                    chunk.targets.forEach(answer => row.append(text('div', answer)));
                    box.append(row);
                  });
                } else if (entry.chunks.length === 1) {
                  const alternatives = entry.chunks[0].targets.filter(answer => !entry.targets.includes(answer));
                  if (alternatives.length) {
                    const row = document.createElement('div');
                    row.className = 'chunk';
                    row.append(text('strong', 'Also accepted'));
                    alternatives.forEach(answer => row.append(text('div', answer)));
                    box.append(row);
                  }
                }
                return box;
              }

              function renderPoint(point, button) {
                selectedPoint = point;
                selectedButton = button;
                document.querySelectorAll('.marker').forEach(node => node.classList.remove('active'));
                button.classList.add('active');
                panel.replaceChildren();
                panel.append(text('div', `Marker ${point.marker}`, 'eyebrow'));
                panel.append(text('h2', point.label || `Point ${point.marker}`));
                if (point.description) panel.append(text('p', point.description, 'description'));

                if (!point.entries.length) {
                  panel.append(text('p', 'No YAML entry currently references this marker.', 'small'));
                  return;
                }

                point.entries.forEach(entry => {
                  const section = document.createElement('section');
                  section.className = 'entry';
                  section.append(text('p', entry.source, 'question'));
                  const response = answerForm(entry, refreshProgressDisplay);
                  section.append(response.form, response.feedback, response.practiceArea);
                  const actions = document.createElement('div');
                  actions.className = 'actions';
                  const hintGroups = hintGroupsFor(entry);
                  if (hintGroups.length) {
                    const hintButton = text('button', 'Show hints', 'action');
                    hintButton.type = 'button';
                    const hintBox = document.createElement('div');
                    hintBox.className = 'reveal';
                    hintBox.hidden = true;
                    hintBox.append(text('strong', 'Hints'));
                    hintGroups.forEach(group => {
                      const groupBox = document.createElement('div');
                      groupBox.className = 'hint-group';
                      if (group.label) groupBox.append(text('strong', group.label, 'hint-group-title'));
                      const list = document.createElement('ul');
                      group.hints.forEach(hint => list.append(text('li', hint)));
                      groupBox.append(list);
                      hintBox.append(groupBox);
                    });
                    hintButton.addEventListener('click', () => {
                      hintBox.hidden = !hintBox.hidden;
                      hintButton.textContent = hintBox.hidden ? 'Show hints' : 'Hide hints';
                    });
                    actions.append(hintButton);
                    section.append(actions, hintBox);
                  } else {
                    section.append(actions);
                  }
                  const answer = answerBox(entry);
                  const answerButton = text('button', 'Reveal answer', 'action primary');
                  answerButton.type = 'button';
                  answerButton.addEventListener('click', () => {
                    answer.hidden = !answer.hidden;
                    answerButton.textContent = answer.hidden ? 'Reveal answer' : 'Hide answer';
                  });
                  actions.append(answerButton);
                  section.append(answer);
                  panel.append(section);
                  if (point.entries.length === 1) response.firstInput.focus();
                });
              }

              function placeMarkers() {
                markers.replaceChildren();
                lines.replaceChildren();
                markerVisuals.clear();
                const width = Number(data.image.width) || image.naturalWidth;
                const height = Number(data.image.height) || image.naturalHeight;
                lines.setAttribute('viewBox', `0 0 ${width} ${height}`);
                const scale = Math.max(1, width / 1600);
                const radius = 22 * scale;
                const offset = 42 * scale;
                data.points.forEach(point => {
                  const badgeX = Math.min(width - radius - 3, Math.max(radius + 3, point.x + offset));
                  const badgeY = Math.min(height - radius - 3, Math.max(radius + 3, point.y - offset));
                  const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
                  line.setAttribute('x1', point.x); line.setAttribute('y1', point.y);
                  line.setAttribute('x2', badgeX); line.setAttribute('y2', badgeY);
                  const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
                  dot.setAttribute('cx', point.x); dot.setAttribute('cy', point.y); dot.setAttribute('r', 6 * scale);
                  lines.append(line, dot);

                  const button = text('button', point.marker, `marker${point.entries.length ? '' : ' unlinked'}`);
                  button.type = 'button';
                  button.style.left = `${badgeX / width * 100}%`;
                  button.style.top = `${badgeY / height * 100}%`;
                  button.setAttribute('aria-label', `Marker ${point.marker}: ${point.label || point.description || 'image point'}`);
                  button.addEventListener('click', () => renderPoint(point, button));
                  markers.append(button);
                  markerVisuals.set(point.id, { button, line, dot });
                });
                refreshProgressDisplay();
              }

              resetProgress.addEventListener('click', () => {
                if (!window.confirm('Reset all saved progress for this image lesson?')) return;
                progress = emptyProgress();
                try { localStorage.removeItem(data.progress_key); } catch (_error) {}
                refreshProgressDisplay();
                if (selectedPoint && selectedButton) {
                  renderPoint(selectedPoint, selectedButton);
                } else {
                  panel.innerHTML = '<div class="empty">Choose a numbered marker to explore that part of the scene.</div>';
                }
              });

              if (image.complete) placeMarkers(); else image.addEventListener('load', placeMarkers);
            })();
          </script>
        </body>
        </html>
      HTML
    end

    def file_url(path)
      normalized = File.expand_path(path.to_s).tr("\\", "/")
      encoded = normalized.split("/").map { |segment| CGI.escape(segment).gsub("+", "%20") }.join("/")
      "file://#{encoded}"
    end

    def value(hash, key)
      return nil unless hash.is_a?(Hash)

      hash[key] || hash[key.to_s]
    end

    def string_list(raw)
      Array(raw).map { |item| item.to_s.strip }.reject(&:empty?).uniq
    end

    def comparable_text(raw)
      raw.to_s.downcase.gsub(/[^\p{L}\p{N}]+/, " ").strip.gsub(/\s+/, " ")
    end

    def first_present(*values)
      values.map { |item| item.to_s.strip }.find { |item| !item.empty? }.to_s
    end
  end
end
