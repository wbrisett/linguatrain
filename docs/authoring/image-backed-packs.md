# Image-backed packs

Linguatrain can open one local image beside the terminal when a pack starts. The image supplies visual context; ordinary authored entries still define what the learner is asked and which answers are accepted.

```yaml
metadata:
  id: summer_scene
  type: translation
  media:
    image:
      file: scans/summer_scene.jpg
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
label,x,y,description
point 1,553,930,"They drink coffee
They talk"
point 2,1129,942,They wait
```

The optional columns are `id`, `label`, and `description`; `x` and `y` are required. When `id` is omitted, Linguatrain turns the label into a stable reference (`point 1` becomes `point_1`). Multiline quoted descriptions are supported. Inline `focus_points` and CSV points may be used together; an inline point with the same ID overrides the CSV row.

The image path is resolved relative to the YAML file. This keeps a personal pack portable as long as the pack and image retain the same relative layout. Use `--no-open-media` when the image is already open or when running without a desktop.

## Authoring guidance

Use a short location cue in every entry, such as “top left, café terrace” or “bottom right, in the water.” The cue should identify a single person or group without translating the expected Finnish answer. Keep the expected answer as short as the real lesson requires; an image exercise may only be testing forms such as `He juovat kahvia` and `He puhuvat`.

Image description is open-ended, while Linguatrain scoring is deterministic. Author a narrow question and list realistic accepted sentences. Do not treat the runtime as a computer-vision system and do not expect it to judge every semantically valid paraphrase.

Keep copyrighted scans in a private lesson-pack directory. Reference them from YAML; do not copy them into a public application or language-pack repository unless redistribution is permitted.
