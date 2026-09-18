# Image-backed packs

Linguatrain can open one local image beside the terminal when a pack starts. The image supplies visual context; ordinary authored entries still define what the learner is asked and which answers are accepted.

```yaml
metadata:
  id: summer_scene
  type: translation
  media:
    image:
      file: scans/summer_scene.jpg
      # Optional clean source for the interactive browser overlay. `file` may
      # remain a companion PNG with permanently drawn markers for normal viewers.
      interactive_file: scans/summer_scene_original.jpg
      title: Summer activity scene
      instruction: Keep the image visible and answer each location cue in Finnish.
      auto_open: true
      coordinate_space:
        unit: pixel
        origin: top_left
        width: 3024
        height: 4032
      focus_points_file: scans/coordinates.csv
      focus_points:
        cafe_women:
          x: 547
          y: 880
          label: Women at the café
```

An exercise entry connects to the intended visual subject with `focus_ref`:

```yaml
entries:
- id: scene_01_cafe
  focus_ref: cafe_women
  source: "At the café terrace: What are they doing?"
```

Coordinates use native image pixels and are measured from the declared origin. Declaring the native dimensions lets Linguatrain reject out-of-bounds points and gives future renderers enough information to scale, crop, or highlight the focus reliably.

Focus points can be maintained in a CSV instead of YAML:

```csv
id,marker,label,x,y,description
point_1,1,point 1,553,930,"They drink coffee
They talk"
point_2,2,point 2,1129,942,They wait
```

The optional columns are `id`, `marker`, `label`, and `description`; `x` and `y` are required. When `id` is omitted, Linguatrain turns the label into a stable reference (`point 1` becomes `point_1`). When `marker` is omitted, a label such as `point 1` supplies marker `1`; otherwise Linguatrain assigns the next available number. Markers may also be letters. Multiline quoted descriptions are supported. Inline `focus_points` and CSV points may be used together; an inline point with the same ID overrides the CSV row.

Use `tools/image_coordinate_picker.html` to author these files without changing the source scan:

1. Open the picker in a browser and choose the source image.
2. To resume existing work, load its coordinate CSV with the **Coordinates** file control.
3. Select numbered or lettered markers.
4. Click each person or group and add a short description.
5. Export the coordinate CSV.
6. Export the marked image as a companion PNG.

Imported coordinates retain their authored IDs, markers, labels, and descriptions. The picker checks for malformed coordinates, duplicate markers, and points outside the loaded image. The marked image contains a small target dot connected to an offset badge, so the badge does not cover the subject. Keep the original scan as the authoring source and set `metadata.media.image.file` to the marked companion when the lesson is ready to use.

The image path is resolved relative to the YAML file. This keeps a personal pack portable as long as the pack and image retain the same relative layout. The image is opened with the normal macOS, Linux, or Windows launcher. A learner can override that launcher with `runtime.image_viewer` in the user config, or use `--no-open-media` when the image is already open or the program is running without a desktop.

## Interactive browser view

Open an image-backed translation pack as a clickable browser lesson:

```sh
ruby linguatrain.rb path/to/lesson.yaml --image-view
```

Linguatrain parses the pack and its coordinate CSV, validates every `focus_ref`, generates a local HTML page, and opens it in the default browser. Clicking a numbered or lettered marker displays the linked YAML question and Finnish answer fields. Each authored chunk represents one required action, so an entry with three chunks displays three fields and an entry with one chunk displays one. Submit all fields with **Check answers** or press Enter. Each field accepts that chunk’s canonical target and authored alternatives, and partial feedback reports how many actions are correct. For multi-action entries, hints are separated into an optional **Overall** group followed by **Action 1**, **Action 2**, and so on. Guidance repeated identically for every action is automatically promoted into **Overall**, leaving only action-specific guidance in each numbered group. Hints and answers remain hidden until requested.

The browser saves submitted answers locally for this lesson. A completed marker, including all of its required actions, turns green and gains a check badge; the header shows overall completion. Returning to a marker restores its answers and feedback, and refreshing or closing the page does not discard that progress. Use **Reset progress** to clear the saved answers for the current lesson.

To create a reusable HTML page without opening it automatically:

```sh
ruby linguatrain.rb path/to/lesson.yaml --export-image-view path/to/lesson.html
```

The exported page retains an absolute link to the local image and embeds the normalized lesson content. It is therefore intended for private, local study rather than distribution. Regenerate it after changing the YAML or coordinate CSV.

When the normal `file` already contains permanently drawn marker badges, add `interactive_file` pointing to the clean source image. The ordinary desktop image viewer continues to open `file`; the browser lesson uses `interactive_file` and draws its own clickable overlay.

When an entry has `focus_ref`, Linguatrain resolves that reference through the CSV or inline focus points and prints `Look at marker 1.` before the question. The prompt therefore stays synchronized if the author switches from numbers to letters and re-exports the CSV.

## Authoring guidance

Use a short location cue in every entry, such as “top left, café terrace” or “bottom right, in the water.” The cue should identify a single person or group without translating the expected Finnish answer. Keep the expected answer as short as the real lesson requires; an image exercise may only be testing forms such as `He juovat kahvia` and `He puhuvat`.

Image description is open-ended, while Linguatrain scoring is deterministic. Author a narrow question and list realistic accepted sentences. Do not treat the runtime as a computer-vision system and do not expect it to judge every semantically valid paraphrase.

Use separate chunks when the picture calls for multiple required actions. Every chunk must then be completed (`AND`):

```yaml
chunks:
- id: drink_coffee
  source: They drink coffee.
  target: He juovat kahvia.
- id: talk
  source: They talk.
  target: He puhuvat.
```

Use multiple `targets` in one chunk when the picture permits different interpretations. Any one target completes that single action (`OR`):

```yaml
chunks:
- id: walk
  source: They walk on the beach or into the water.
  targets:
  - He kävelevät rannalla.
  - He kävelevät veteen.
```

This distinction affects both guidance and scoring: the first example has two required actions, while the second has one action with two valid answers.

## Conjugation help after repeated verb errors

Progressive guidance can offer a focused conjugation detour after the learner misses the same verb form twice. Add a present-tense paradigm to the verb component:

```yaml
guidance:
  components:
  - role: verb
    lemma: puhua
    form: puhuvat
    person: third
    number: plural
    conjugation:
      forms:
        minä: puhun
        sinä: puhut
        hän: puhuu
        me: puhumme
        te: puhutte
        he: puhuvat
```

On the second recognized verb miss, Linguatrain asks whether the learner wants conjugation practice. If accepted, it drills the authored forms and then returns to the same image action. The learner must still correct the verb and re-enter the complete sentence. Declining the detour continues the ordinary hint flow, and the offer is not repeated for that action.

When a verb component declares `verb_type`, the terminal includes it in both guidance paths. A base-verb hint such as `Base verb: odottaa.` is displayed as `Hint: Base verb: odottaa. Type 1 verb.` An immediate near-error diagnosis includes a separate line such as `- Verb type: 1` between the base verb and required form. Authors should keep the base-verb hint itself concise and store the type structurally on the component rather than repeating it in hint text.

The interactive browser lesson uses the same component metadata for a smaller inline intervention. After two likely verb-form errors in one action, it offers **Practice _verb_**. The learner identifies the subject, person/number, and—when `verb_type` is authored—the verb type; then completes any authored rule-specific questions and supplies the required conjugated form before returning to the original sentence. Attempt counts and completed coaching are stored with the lesson's browser progress.

Subject, person/number, verb type, and the final conjugation question are generated from the component fields. Language-specific reasoning should be authored under `conjugation.coaching.questions`:

```yaml
conjugation:
  forms:
    minä: odotan
    he: odottavat
  coaching:
    questions:
    - prompt: Does the 1-1-2 pattern use the weak or strong grade here?
      answers: [strong]
      explanation: The he-form uses the strong grade, so odottavat keeps tt.
```

Place `verb_type` on the verb component as a number or string. The generated question accepts forms such as `1`, `type 1`, and `verb type 1`:

```yaml
- role: verb
  lemma: odottaa
  verb_type: 1
  form: odottavat
  person: third
  number: plural
```

This keeps the browser renderer language-neutral: it diagnoses a likely mistake using the authored components but does not invent Finnish-specific grammar rules.

Keep copyrighted scans in a private lesson-pack directory. Reference them from YAML; do not copy them into a public application or language-pack repository unless redistribution is permitted.
