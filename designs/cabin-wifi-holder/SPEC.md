# Cabin Wi-Fi QR + LED remote holder: build spec

Hand-off for `/openscad-print`. Decided on the wayfinder map (s1m0nj/3d-prints#1). Everything here is locked; where a ticket was amended, this file has the final number. **Nothing in this repo has been printed or tested on a printer.**

Wi-Fi credentials live only in `tools/qr.js`. Never write them into any other file, README or issue, and never publish the finished files (the QR exposes the password).

## What it is

A wall-mounted holder for a small IR remote (43 W x 90 L x 5 T mm). A narrow plate with a pocket at the bottom; the remote drops into the pocket from above. The Wi-Fi QR is on the outside face of the pocket's front panel. White body, black raised QR/glyph/text. Apple/Japandi: minimal, soft rounded edges.

Printer: Bambu Lab A1 + AMS Lite, 0.4 mm nozzle, Bambu PLA Basic white (filament 1) and black (filament 2), profile `0.20mm Standard @BBL A1`, no supports. User is a beginner: keep default profiles.

## Coordinates and parameters

x = across (0 at centre), y = up the wall (0 at bottom edge), z = out from the wall (z = 0 is the back face on the bed).

```openscad
// plate
plate_w = 50;  plate_h = 95;  plate_t = 3.0;  corner_r = 7;
// pocket (inside A)
rem_w = 43; rem_t = 5; rem_l = 90;            // remote
pocket_w = 46.4;                              // remote + 1.7 each side
pocket_gap = 6.5;                             // remote 5 + 1.5 room; overrides the original ">= 7"
side_wall = 1.8; floor_t = 2.4;
pocket_top_y = 60;                            // panel / walls end here
wall_top_z = plate_t + pocket_gap;            // 9.5
// front panel B
panel_t = 2.0; panel_h = 60;                  // z 9.5 to 11.5, y 0 to 60, same outline as A
edge_fillet = 1.0;
// raised black C
raise = 1.0;                                  // z 11.5 to 12.5
// screws (countersunk, ~4.5 head, ~2.5 shank, ~20 long)
screw_x = 18; screw_y = 88;                   // 36 apart; 7 in from top and sides, concentric with corner_r
hole_d = 2.9; csk_d = 4.9;                    // 90 degree cone
recess_d = 8.0; recess_t = 1.2;               // front face
cover_d = 7.6; cover_t = 1.2; cover_ribs = 4; // push fit, tune ribs
pry_notch_w = 3; pry_notch_depth = 1.0;       // on the low-y side of each recess
```

Derived: pocket interior x +/-23.2, y 2.4 to 60, z 3 to 9.5. Remote rests on the floor, top at y = 92.4 (about 2.6 below the plate top), about 32 mm exposed above the panel. Overall depth 11.5 mm plus 1 mm raised QR.

Recess floor at z = 1.8. Countersink cone runs from dia 4.9 at z = 1.8 down to dia 2.9 at z = 0.8, leaving 0.8 mm of plate below it. Screws sit directly behind the inserted remote: lift the remote out to reach them. Covers are flush with the plate front face, so the sliding remote can never touch them.

## Parts

| Part | Content | Colour | Orientation |
|---|---|---|---|
| A | Backplate + side walls + floor, ONE solid. 2 countersunk holes + recesses + pry notches. Wall ends at y = 60 have R1 outer corners. | white (1) | back face down, walls rise, no supports |
| B | Front panel 50 x 60 x 2.0, same outline as A over y 0 to 60 (R7 bottom corners, R1 top corners). About 1.0 mm radius fillet on the top outer edge all round. Plain flat underside. No grooves or locating features. | white (1) | face up, underside on bed |
| C | Raised black QR, Wi-Fi glyph, `Si_Cabin`, 1.0 mm, sitting on B's top face at z = 11.5 (touching, NOT overlapping B) | black (2) | with B, on top |
| D x4 | Round screw cover, 7.6 x 1.2, 4 crush ribs. 2 for use, 2 spares. | white (1) | face down, ribs up |

Plate front edge above the pocket (y > 60): about 1.0 mm fillet on the top outer edge where printable, blended at the step with the panel; verify visually. Fillets only on top-surface edges, so no overhangs.

All of C is black. Black layers are the last 5 layers of B+C (white to z = 2.0 of the panel, black from there), so one colour swap.

## Front panel layout (variant E)

- QR: 29 x 29 modules, module 1.3 mm, 37.7 mm square, centred on x = 0, top margin 4.5 mm from panel top, so QR occupies y 17.8 to 55.5. Square modules only. Matrix and payload are generated and decode-verified by `tools/qr.js` (v3, ECC M, 217 dark runs in `qr_matrix.scad` / `qr_runs.json`). Do not regenerate with different settings.
- Text row below the QR: Wi-Fi glyph + `Si_Cabin`, centred as a group, glyph gap about 2.2 mm. Font Helvetica Neue Bold (`/System/Library/Fonts/HelveticaNeue.ttc`) or similar bold sans. Cap height about 4.3 mm (check OpenSCAD `size` against measured cap height), stems about 0.9 mm (must stay >= 0.8).
- Wi-Fi glyph: dot r 0.9 plus 3 arcs (90 degree sweep, radii 1.8 / 3.6 / 5.4, 1.0 mm stroke), about 5.4 mm tall, dot at the text baseline.
- **Spacing rule (overrides the prototype):** the top of the glyph must be at least 5 mm below the QR's bottom edge (about 4 modules of quiet zone). The prototype drew it about 3.3 mm below, so lower the text row (baseline about y = 6.5) and keep every element inside the panel's rounded corners.
- No "Scan to connect" text (dropped; it was marginal at 0.7 mm stems).
- Prototype for reference: branch `prototype/panel-layout`, `designs/cabin-wifi-holder/prototype-panel-layout.html`.

## Assembly

1. Print A, B+C, D. Check the remote drops into A's pocket (before gluing the panel, you can see inside).
2. Dry-fit B onto A. Stand both on a flat surface and line up the bottom and both side edges flush; tape.
3. Small beads of gel superglue on the **outer half** of the wall tops (1.8 mm wide) and floor top, never next to the pocket edge. Press and hold, wipe squeeze-out on the outside. Nothing goes in the pocket.
4. Screw A to the timber wall with two ~20 mm countersunk screws (lift the remote out first); push in covers D. Pry out with a fingernail or coin at the notch.
5. Test the finished print's QR with an iPhone before mounting.

## Verification checklist

Programmatic (OpenSCAD, scripts):
- [ ] SCAD builds with no WARNING/ERROR; every part exports a manifold STL; sizes match to 0.1 mm.
- [ ] Remote swept volume (43 x 5 box over the full drop path, z 3 to 8) intersects no part of A or D.
- [ ] Screw recesses/cover tops flush; both screw positions reachable once the remote is out.
- [ ] C does not overlap B; B and A outlines identical over y 0 to 60.
- [ ] Rendered black geometry matches the QR matrix (module-by-module sample) and the QR PNG re-decodes to the payload.
- [ ] Min feature check: QR modules 1.3, stems >= 0.8.

In Bambu Studio / by the user:
- [ ] Project opens without the "invalid config" notice; correct filament per part.
- [ ] Slice preview: no supports, one swap on the panel, sensible plate layout, no overlaps.
- [ ] Record estimated time and filament use from the slice.
- [ ] Physical fit of the real remote, glue, covers, iPhone scan (not done by the agent).

## Project file route (from the research ticket)

Use the Bambu Studio CLI so the app writes the project:

```bash
/Applications/BambuStudio.app/Contents/MacOS/BambuStudio \
  --export-3mf out.3mf --outputdir <dir> \
  --load-settings "Bambu Lab A1 0.4 nozzle.json;0.20mm Standard @BBL A1.json" \
  --load-filaments "white.json;black.json" --load-filament-ids "1,2" --assemble \
  panel_white.stl panel_black.stl
```

This produces one object with two parts and correct per-part filament, verified by the research agent (branch `research/bambu-3mf-route`). **Open risk:** `--assemble` merges all the STLs into one object, but the plate needs A and D as separate white objects and B+C as one two-part object. First try separate CLI runs and combining them, or the CLI's arrange/multi-object options; if that cannot be made to work, say so plainly, and fall back to the skill's STOP 2 / STOP 3 (user accepts "load as single object with multiple parts" and picks filaments). Never ship a hand-made generic 3MF as if it were native.

## Deliverables

Native `.3mf` (or clearly explained fallback), individual STLs, parametric `.scad`, `WiFi_QR_test.png`, short assembly + print-settings notes (only deltas from the default Bambu profile: none expected), a render, and `README.md` for the project folder. Fill in estimated time/filament from the slice. Do not claim physical testing.
