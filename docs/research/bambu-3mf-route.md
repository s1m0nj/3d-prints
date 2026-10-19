# Producing a valid native Bambu Studio 3MF with per-part filament assignment

**Question:** given separate white-body STL(s) and a black QR/text STL that sits
non-overlapping on top, what is the most reliable way to produce a native
Bambu Studio 3MF for a Bambu Lab A1 (0.4 mm nozzle) that assigns white = filament
1, black = filament 2, without triggering Bambu Studio's "object has invalid
config, load geometry data only" warning?

**Answer, up front:** use the installed CLI's `--assemble` flag together with
`--load-filament-ids`. This merges the input STLs into **one printable object
made of two parts**, with per-part `extruder` metadata, which is exactly the
native "Objects and Parts" concept the GUI itself uses for multi-material single
objects. No hand-editing of the 3MF XML is required for this STL-per-filament
case, and the result round-trips through `--info` with zero warnings.

```bash
/Applications/BambuStudio.app/Contents/MacOS/BambuStudio \
  --export-3mf out.3mf --outputdir /path/to/out \
  --load-settings "Bambu Lab A1 0.4 nozzle.json;0.20mm Standard @BBL A1.json" \
  --load-filaments "white_pla.json;black_pla.json" \
  --load-filament-ids "1,2" \
  --assemble \
  body_white.stl top_black.stl
```

Tested with the installed `BambuStudio-02.08.02.61` macOS binary against a
scratch directory (`/tmp/bambu-3mf-test`, not under `~/3d-prints`); see §7 for
the exact commands/output.

Source commit referenced throughout: `bambulab/BambuStudio@79df7ae309be398ed30c9f397c13c9911c2edc57`
(master, fetched 2026-10-19).

---

## 1. 3MF package layout Bambu Studio writes

The exporter is `_BBS_3MF_Exporter` in `src/libslic3r/Format/bbs_3mf.cpp`
(path constants around [L153-L190](https://github.com/bambulab/BambuStudio/blob/79df7ae309be398ed30c9f397c13c9911c2edc57/src/libslic3r/Format/bbs_3mf.cpp#L153)):

- `3D/3dmodel.model`
- `[Content_Types].xml`, `_rels/.rels`
- `Metadata/project_settings.config`
- `Metadata/model_settings.config`
- `Metadata/slice_info.config`
- `Metadata/cut_information.xml` (note: `.xml`, not `.config`)

Verified locally by unzipping a CLI-produced 3MF, the real package also contains:

```
3D/Objects/object_1.model, object_2.model   (one per source STL/part, referenced as components)
3D/_rels/3dmodel.model.rels
Metadata/plate_1.png, plate_no_light_1.png, plate_1_small.png, pick_1.png, top_1.png
Metadata/filament_sequence.json
```

`model_settings.config` ground truth (two-object case, before assembling):

```xml
<config>
  <object id="2">
    <metadata key="name" value="cube1.stl"/>
    <metadata key="extruder" value="1"/>
    <metadata face_count="12"/>
    <part id="1" subtype="normal_part" uuid="...">
      <metadata key="name" value="cube1.stl"/>
      <metadata key="matrix" value="1 0 0 5 0 1 0 5 0 0 1 2.5 0 0 0 1"/>
      <metadata key="source_file" value="cube1.stl"/>
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <mesh_stat face_count="12" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>
    </part>
  </object>
  ...
  <plate>
    <metadata key="plater_id" value="1"/>
    <model_instance><metadata key="object_id" value="2"/><metadata key="instance_id" value="0"/><metadata key="identify_id" value="47"/></model_instance>
  </plate>
  <assemble></assemble>
</config>
```

`3D/3dmodel.model` wraps each top-level object as
`<object id=".." p:UUID=".." type="model"><components><component p:path="/3D/Objects/object_N.model" objectid=".." .../></components></object>`,
with a `<build>` section placing each via `<item objectid=".." transform=".." printable="1"/>`.
A `BambuStudio:3mfVersion` metadata entry is mandatory for the file to be
recognized as native Bambu Studio output (see §4).

## 2. Per-part filament (`extruder`) metadata

The `extruder` metadata key's XML position depends on whether the parts are
separate top-level **objects** or **parts of one assembled object**:

- **Multi-object** (each STL its own object, plain `--export-3mf`, no
  `--assemble`): `<metadata key="extruder" value="N"/>` is a direct child of
  `<object>`, before `<part>`.
- **Single-object, multi-part** (produced with `--assemble`): `<metadata key="extruder" value="N"/>`
  is a child of **each `<part>`** element, after the `source_offset_*` entries.
  **This is the schema needed for "one printable object, two parts, two
  filaments."**

`project_settings.config` carries the filament *list* (`filament_colour`,
`filament_type`, `filament_settings_id`, `filament_ids`, `nozzle_diameter`,
etc., each a JSON array indexed by filament/extruder number). The per-object
or per-part `extruder` value is a 1-based index into this array (extruder 1 →
filament array index 0, extruder 2 → index 1).

A separate, more complex mechanism also exists in the schema but is not needed
here: `MMU_SEGMENTATION_ATTR = "paint_color"` / `CUSTOM_SUPPORTS_ATTR = "paint_supports"`
(constants in the same `bbs_3mf.cpp`, used by the per-triangle MMU-painting
gizmo rather than simple per-part extruder assignment).

## 3. Multi-object vs. single-object-multi-part: which to author

Both representations exist in the schema; **single-object-multi-part
(produced via `--assemble`) is simpler and more robust** for the white-body +
black-top case:

- It is produced natively by the installed CLI with zero hand-editing (§7).
- It keeps object-id bookkeeping to **one** object (one `<object>` block in
  `model_settings.config`, one `<object type="model">` in `3D/3dmodel.model`),
  instead of two independent object ids / `<model_instance>` entries / `<item>`
  build entries that must stay in sync — a bigger surface for id-mismatch
  errors (see `bbs_3mf.cpp:2262`, `"invalid object, id: "`).
- Multi-object is only necessary if each part must be independently
  selectable/movable as its own print item on the plate. For "two parts
  rigidly fused into one object" (this case), single-object-multi-part is the
  native Bambu Studio concept — what the GUI calls "Objects and Parts"
  (right-click → Add part).

## 4. What actually triggers "invalid config, load geometry data only"

Exact string located in `src/slic3r/GUI/Plater.cpp` (too large for GitHub's
code-search index — confirmed via direct raw fetch of
`https://raw.githubusercontent.com/bambulab/BambuStudio/master/src/slic3r/GUI/Plater.cpp`
at the referenced commit):

```cpp
// Plater.cpp:300-321  (helper 1)
static bool is_bbl_vendor_config(const DynamicPrintConfig &config_loaded, PresetBundle *preset_bundle) {
    if (!preset_bundle) return false;
    auto *printer_model_opt = config_loaded.option<ConfigOptionString>("printer_model");
    if (!printer_model_opt || printer_model_opt->value.empty()) return false;
    for (const auto &vendor : preset_bundle->vendors)
        for (const auto &vendor_model : vendor.second.models)
            if (vendor_model.name == printer_model_opt->value) return vendor.first == "BBL";
    return false;
}

// Plater.cpp:328-345  (helper 2)
static bool check_project_config(const DynamicPrintConfig &config_loaded) {
    if (config_loaded.empty()) return true;
    auto *nd = config_loaded.option<ConfigOptionFloatsNullable>("nozzle_diameter");
    if (!nd) return true;
    const size_t extruder_count = nd->size();
    if (extruder_count <= 1) return true;
    const auto *opt = dynamic_cast<const ConfigOptionVectorBase *>(config_loaded.option("extruder_type"));
    const size_t sz = opt ? opt->size() : 0;
    if (sz != extruder_count) return false;
    return true;
}

// Plater.cpp:8679-8684  (the actual trigger)
if (!is_bbl_vendor_config(config_loaded, wxGetApp().preset_bundle) && !check_project_config(config_loaded)) {
    load_config = false;
    q->get_notification_manager()->push_notification(NotificationType::CustomNotification,
        NotificationManager::NotificationLevel::WarningNotificationLevel,
        into_u8(_L("The 3mf file has invalid config, load geometry data only")));
}
```

**For a single-nozzle A1**, `check_project_config` trivially returns `true`
whenever `nozzle_diameter` has ≤ 1 entry or `config_loaded` is empty — the
normal case for an A1. Since the warning fires only when *both* helpers
return `false`, and `check_project_config` can't fail for a 1-nozzle config,
**this exact "invalid config" message is primarily a dual/multi-nozzle
(H2D-class) failure mode** (mismatched `extruder_type` vs `nozzle_diameter`
array sizes). On an A1 it will essentially never fire as long as
`project_settings.config` parses into a non-crashing `DynamicPrintConfig` at
all, even with an unrecognized `printer_model`.

Two related but separately-worded messages are the more realistic risk for a
hand-built file (same file, ~L8694-8768):

- `"The 3mf is not from Bambu Lab, load geometry data only."` — 3MF detected
  as Prusa-format (`en_3mf_file_type == En3mfType::From_Prusa`).
- `"The 3mf is not from Bambu Lab, load geometry data and color data only."` /
  `"The 3mf is generated by old Bambu Studio, load geometry data only."` —
  fires when `load_config && config_loaded.empty()`, i.e.
  `project_settings.config` failed to parse into any usable config. Branches
  on `file_version == 0.0.0` (non-Bambu origin) vs non-zero (old Bambu
  Studio).
- `"Due to the lower version of Bambu Studio, this 3mf file cannot be fully
  loaded..."` — version-mismatch path (`file_version.maj() > app_version.maj()`).

**The "native" recognition flag, `m_is_bbl_3mf`,** is set only when the
importer finds `BambuStudio:3mfVersion` (or legacy `bamboo_slicer:Version3mf`)
metadata inside `3D/3dmodel.model`:

```cpp
// bbs_3mf.cpp:4316-4329 (import)
if ((m_curr_metadata_name == BBS_3MF_VERSION) || (m_curr_metadata_name == BBS_3MF_VERSION1)) {
    ...
    m_is_bbl_3mf = true;
}
// bbs_3mf.cpp:7393 (export)
metadata_item_map[BBS_3MF_VERSION] = std::to_string(VERSION_BBS_3MF);
```

where `BBS_3MF_VERSION = "BambuStudio:3mfVersion"`
([bbs_3mf.cpp#L111](https://github.com/bambulab/BambuStudio/blob/79df7ae309be398ed30c9f397c13c9911c2edc57/src/libslic3r/Format/bbs_3mf.cpp#L111)).
**If hand-authoring: `3D/3dmodel.model` must include
`<metadata name="BambuStudio:3mfVersion">1</metadata>`**, or the whole file is
treated as foreign ("not from Bambu Lab" warnings, not the "invalid config"
one).

Separately, raw parse-time integrity errors abort the load outright
(`add_error(...)`) rather than showing a dismissible warning, e.g.:

- `"invalid object, id: " + id` (`bbs_3mf.cpp:2262`) — object id referenced
  from `model_settings.config`/the plate instance list has no corresponding
  entry in `m_model->objects` (object-id mismatch between `3D/3dmodel.model`
  and `Metadata/model_settings.config`).
- `"Found component with invalid object id"` (`bbs_3mf.cpp:4242, 6102`) —
  mismatched `objectid` attribute on a `<component>` in `3D/3dmodel.model`.
- `"Found invalid object"` (`:3950, 4524`), `"Found invalid volumes count"`
  (`:5618`), `"Found invalid triangle id"` (`:5627`), `"Found invalid vertex
  id"` (`:5463, 5657`) — malformed/truncated mesh XML in the per-object
  `.model` files.

**Practical triggers to avoid when hand-authoring:** (a) missing
`BambuStudio:3mfVersion` metadata; (b) object/part/component id
cross-references between `3D/3dmodel.model`, `3D/Objects/object_N.model`, and
`Metadata/model_settings.config` that don't line up 1:1; (c) a
`project_settings.config` that fails to parse at all. (d), mismatched
`nozzle_diameter`/`extruder_type` array lengths, is a dual-nozzle-only concern
and irrelevant for the A1.

## 5. Relevant CLI flags (installed v02.08.02.61, macOS)

From `--help` plus `src/BambuStudio.cpp` at the same commit:

- `--load-filament-ids "1,2,3,1"` — one filament id per **input file**.
  Requires `--load-filaments` to be set, else:
  `"loaded_filament_ids should be used with load_filaments together"` → exit
  `CLI_INVALID_PARAMS` (confirmed by reproduction, §7 Run B).
  **Count must exactly equal the number of input files** — confirmed in
  source (`m_input_files.size()` check) and by testing. **This means
  filament-id assignment via CLI is strictly one id per input STL/object,
  never per-triangle or sub-mesh within a single STL** — a single mesh file
  cannot have its triangles auto-split across filaments by this flag.
- `--load-filaments "filament1.json;..."` — full filament preset(s), one per
  entry in `--load-filament-ids`.
- `--load-settings "machine.json;process.json"` — per the official wiki
  (`Command-Line-Usage.md`), **up to 1 machine setting and 1 process setting
  supported**, and both must be present together once any is loaded; loading
  only a machine profile without a matching process profile fails with
  `"process not compatible with printer."` / `"The selected printer is not
  compatible with the process preset in the 3mf."` (confirmed by
  reproduction).
- `--assemble` — "Arrange the supplied models in a plate and merge them in a
  single model in order to perform actions once." **Verified locally this is
  exactly what produces the single-object/multi-part + per-part-`extruder`
  schema needed** (§7 Run D).
- `--load-assemble-list assemble_list.json` — mutually exclusive with passing
  input model files on the command line
  (`"load_assemble_list should not be used with input model files to
  load..."`); it re-arranges/re-groups objects on an *existing* plate via a
  JSON descriptor. Not applicable to a from-scratch raw-STL workflow.
- `--export-3mf filename.3mf`, `--outputdir dir`, `--min-save`, `--info`,
  `--export-stl(s)`, `--metadata-name`/`--metadata-value` — as documented in
  `--help`; `--info` was used below as the round-trip validity check.

**Official wiki** (`https://github.com/bambulab/BambuStudio/wiki` →
`Command-Line-Usage.md`, cloned from the public wiki git repo):

> `--load-filaments "filament1.json;filament2.json;..."` — Load filament
> settings from the specified file list, the filament setting count should
> not exceed the filaments used in the 3mf. **the config file should be a
> full config** instead of the one used in `resources/profiles/BBL/filament`.
>
> `--load-settings "machine.json;process.json"` — Load machine/process
> settings from the specified file, **up to 1 machine setting and 1 process
> setting supported**. the config file should be a full config instead of the
> one used in `resources/profiles/BBL/machine` or `resources/profiles/BBL/process`.

In practice (§7), the bundled, non-"full" system preset JSONs under
`/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/...` (which use
`inherits` and are not flattened/"full") worked fine directly with
`--load-filaments`/`--load-settings` — Bambu Studio resolves `inherits` chains
against its own bundled preset tree. The wiki's "full config" caveat appears
to matter more for arbitrary externally-authored JSON not resolvable against
any installed vendor preset tree.

## 6. Wiki coverage gap

The wiki repo (`bambulab/BambuStudio.wiki.git`) contains: `Home.md`,
`BambuLab-Official-Wiki.md`, `Command-Line-Usage.md`, `Docker-Run-Guide.md`,
compile guides, `QA.md`. **There is no dedicated 3MF-format-schema page, and
no multi-material/multi-color-printing page** — only `Command-Line-Usage.md`
is relevant here. `Home.md` links out to `wiki.bambulab.com` (a consumer-docs
site, not primary source-level documentation; not fetched for this question).
All schema-level detail in §1-§4 came from source code + hands-on testing, not
the wiki.

## 7. Hands-on verification (ground truth)

Scratch dir: `/tmp/bambu-3mf-test` (not under `~/3d-prints`). Two hand-written
STL cubes: `cube1.stl` (20×20×5 mm "body", z = 0–5) and `cube2.stl` (10×10×2 mm
"top", z = 5–7, non-overlapping, sitting on the body's footprint).

**Run A — bare export, no filament assignment:**

```
BambuStudio --export-3mf out_basic.3mf --outputdir /tmp/bambu-3mf-test cube1.stl cube2.stl
→ result.json: {"error_string":"Success.","return_code":0,...}
```

Each STL becomes a separate top-level `<object>`, both defaulted to
`<metadata key="extruder" value="1"/>` as a direct child of `<object>`.

**Run B — `--load-filament-ids` alone (error reproduction):**

```
BambuStudio --export-3mf out_ids.3mf --outputdir /tmp/bambu-3mf-test --load-filament-ids "1,2" cube1.stl cube2.stl
→ stderr: "[error]   loaded_filament_ids should be used with load_filaments together"
→ stdout: "run found error, exit"
→ result.json: {"error_string":"Invalid parameters to the slicer.","return_code":-2,...}
```

**Run C — full per-object filament assignment (machine + process + two
filament profiles + filament-ids, no `--assemble`):**

```
F="/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/filament/Generic PLA @BBL A1.json"
M="/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/machine/Bambu Lab A1 0.4 nozzle.json"
P="/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/process/0.20mm Standard @BBL A1.json"
BambuStudio --export-3mf out_ids.3mf --outputdir /tmp/bambu-3mf-test \
  --load-settings "$M;$P" --load-filaments "$F;$F" --load-filament-ids "1,2" cube1.stl cube2.stl
→ result.json: {"error_string":"Success.","return_code":0,...}
```

(First attempt without `$P` failed: `"[error] run 3002: process not
compatible with printer."` / `"The selected printer is not compatible with
the process preset in the 3mf."` — confirms machine + process must be loaded
together.)

Result: two top-level `<object>` elements, `extruder` = 1 and 2 respectively,
as direct children of each `<object>`. `project_settings.config` got
`"filament_settings_id": ["Generic PLA @BBL A1", "Generic PLA @BBL A1"]` and a
2-element `filament_is_mixed`; oddly `filament_colour`/`nozzle_diameter`
stayed single-element — an observed CLI quirk, not explained in any source
comment found; likely cosmetic/display-only and shouldn't affect printability
since per-extruder filament identity is carried by `filament_settings_id`
and the per-object/part `extruder` index.

**Run D — `--assemble` (the schema this task needs):**

```
BambuStudio --export-3mf out_assemble.3mf --outputdir /tmp/bambu-3mf-test \
  --load-settings "$M;$P" --load-filaments "$F;$F" --load-filament-ids "1,2" --assemble cube1.stl cube2.stl
→ result.json: {"error_string":"Success.","return_code":0,...}
```

Resulting `model_settings.config` — **one object, two parts, per-part
`extruder`, produced natively, no hand-editing**:

```xml
<object id="3">
  <metadata key="name" value="Assembly"/>
  <metadata face_count="24"/>
  <part id="1" subtype="normal_part" uuid="9a9c0e51-...">
    <metadata key="name" value="cube1.stl"/>
    <metadata key="matrix" value="1 0 0 5 0 1 0 5 0 0 1 2.5 0 0 0 1"/>
    <metadata key="source_file" value="cube1.stl"/>
    ...
    <metadata key="extruder" value="1"/>
    <mesh_stat .../>
  </part>
  <part id="2" subtype="normal_part" uuid="d27b1a3a-...">
    <metadata key="name" value="cube2.stl"/>
    ...
    <metadata key="extruder" value="2"/>
    <mesh_stat .../>
  </part>
</object>
<plate>
  ...
  <model_instance><metadata key="object_id" value="3"/>...</model_instance>
</plate>
```

`3D/3dmodel.model` now has a **single** `<object id="3" type="model">` whose
`<components>` holds **two** `<component>` elements (`objectid="1"` and
`objectid="2"`), and **one** `<item objectid="3" .../>` in `<build>`.

Round-trip check:

```
BambuStudio --info out_assemble.3mf
→ size_x = 15.000000  size_y = 15.000000  size_z = 7.000000
  number_of_facets = 24  manifold = yes  number_of_parts = 2  volume = 700.000000
```

No warnings or errors on reload — a clean round trip straight from the CLI.

## Recommended route for the white-body + black-top-text case

```bash
/Applications/BambuStudio.app/Contents/MacOS/BambuStudio \
  --export-3mf out.3mf --outputdir /path/to/out \
  --load-settings "Bambu Lab A1 0.4 nozzle.json;0.20mm Standard @BBL A1.json" \
  --load-filaments "white_pla.json;black_pla.json" \
  --load-filament-ids "1,2" \
  --assemble \
  body_white.stl top_black.stl
```

Use two *distinct* color filament profile JSONs (not the same file twice, as
in the generic test above), and point `--load-settings` at the real
BBL-bundled A1 machine/process JSONs (under
`/Applications/BambuStudio.app/Contents/Resources/profiles/BBL/...`) or
equivalents, per the wiki's "full config" caveat. Open the resulting 3MF in
the GUI to confirm the plate, filament colors, and part tree before slicing —
but based on hands-on testing, no "invalid config" or "not from Bambu Lab"
warning should appear.

## Limits and unknowns

- `--assemble`+`--load-filament-ids` assigns one filament **per input STL
  file**. If the white/black split instead needs to be carved out of a
  *single* mesh (sub-mesh/triangle-level), that is outside CLI capability —
  you would need either Bambu Studio's MMU-painting mechanism
  (`paint_color` attribute, §2) or to pre-split the mesh into separate STLs
  before this pipeline. Since the question's starting inputs are already
  separate white/black STLs, this limit does not apply here.
  — ***Unverified beyond source constants***: the exact `paint_color` XML
  schema was not hands-on tested (not needed for this case).
  — **Unverified**: whether the CLI can orient/arrange the two parts
  automatically on first contact — here part *positions* came from each
  STL's own origin (`matrix` metadata placed `cube2` already offset); for
  the real white/black parts, the `--ensure-on-bed`, `--orient`, or
  pre-arranged STL origins should be checked explicitly so the black part
  lands correctly on the white part rather than needing manual placement.
- The "invalid config, load geometry data only" warning string, as found in
  `Plater.cpp`, is realistically a dual/multi-nozzle failure mode rather than
  something expected to occur on an A1; the more likely real-world risk for a
  hand-built or mis-exported file is one of the "not from Bambu Lab" messages
  gated by `BambuStudio:3mfVersion`/`m_is_bbl_3mf`, or an outright parse abort
  from id mismatches. The CLI route above sidesteps all of these because
  Bambu Studio itself is writing every file.
- GitHub's hosted code-search index does not cover the large files cited here
  (`Plater.cpp` ~1.28 MB, `bbs_3mf.cpp` ~350 KB); line numbers for those two
  files come from a direct fetch of the raw file at the commit above rather
  than the search UI — worth a quick diff-check against current `master` if
  revisiting this later, since line numbers can drift with upstream changes.
- No primary wiki or source-comment explanation was found for why
  `filament_colour`/`nozzle_diameter` stay single-element in CLI-exported
  `project_settings.config` despite 2 filaments being loaded (Run C) — flagged
  as an observed quirk, not confirmed to matter for printability.
- Not tested: slicing (`--slice`) and actual physical printing of the
  resulting 3MF on real A1 hardware — this research covers only the
  file-format/CLI-plumbing side of the question, as scoped.

## Source references

- `bambulab/BambuStudio` @ `79df7ae309be398ed30c9f397c13c9911c2edc57` (master,
  fetched 2026-10-19):
  - `src/libslic3r/Format/bbs_3mf.cpp` (3MF reader/writer, path/tag constants,
    import/export of `model_settings.config`, `BBS_3MF_VERSION`, id-mismatch
    error strings)
  - `src/slic3r/GUI/Plater.cpp` (the "invalid config"/"not from Bambu Lab"
    warning logic, `is_bbl_vendor_config`, `check_project_config`)
  - `src/BambuStudio.cpp` (CLI argument parsing/enforcement for
    `--load-filament-ids`, `--load-filaments`, `--load-settings`,
    `--load-assemble-list`, `--assemble`)
- `bambulab/BambuStudio.wiki.git` → `Command-Line-Usage.md`
- Local hands-on testing: `/Applications/BambuStudio.app/Contents/MacOS/BambuStudio`
  (`BambuStudio-02.08.02.61`) on macOS, scratch dir `/tmp/bambu-3mf-test`.
