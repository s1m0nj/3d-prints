---
name: openscad-print
description: Model 3D-printable parts in OpenSCAD and queue them in Bambu Studio for the user's Bambu Lab A1. Use when the user wants to design, change, colour, or print a 3D model (bracket, holder, enclosure, toy, boat).
---

Turn a request into a printed part: OpenSCAD source, a visually approved model, then a Bambu Studio plate. The user is the gate at four **human stops**, marked STOP. Everything between stops is yours.

Work in the `~/3d-prints` repo: own models in `designs/<model>/<model>.scad`, downloaded favourites in `favourites/<model>/`. Every project folder gets a `README.md` (purpose, source and licence, print settings). Check `favourites/` before designing from scratch. Read [reference.md](reference.md) for A1 design rules, multi-colour, multi-plate, and Bambu Studio automation limits.

## Steps

1. **Pin the dimensions.** Ask one question at a time until every size that matters is a number (length, width, wall, clearances, colours). Done when each dimension is in the `.scad` as a named parameter at the top.

2. **Write the `.scad`.** Parameters first, flat face on Z=0, `$fn` set. For N colours, add a `part` switch so each colour exports as its own non-overlapping solid (reference.md, Multi-colour). Done when the file builds without WARNING or ERROR.

3. **Build and inspect.** Run `~/3d-prints/bin/build.sh <file> [name=value]`, once per part with `OUTNAME=<model>-<part>` and `part=\"<part>\"`. View every PNG (iso, top, front, side). Check requested dimensions against the size report, then wall thickness, overhangs, and anything poking through. Fix and rebuild until the report matches the request to 0.1 mm and the previews show a valid model. Done when you would show this to the user without caveats.

4. **STOP 1: visual approval.** Open the file in the OpenSCAD GUI (`open -a ~/Applications/OpenSCAD.app <file.scad>`), press F5, fit the view. Summarise dimensions and choices. Wait for explicit approval. Apply requested changes and return to step 3.

5. **Load into Bambu Studio.** `open -a BambuStudio <stl files>`. A single 3MF shows an "invalid config" notice: press OK. Multiple STLs raise "load as a single object with multiple parts?": **STOP 2**, ask the user to click Yes. Done when a screenshot shows the object at the expected size on the A1 plate.

6. **Assign filaments.** Per-part filament is set in the object list's Fila. column. Synthetic clicks cannot open that dropdown: **STOP 3**, ask the user to pick each part's filament. Done when a screenshot shows every part on its intended filament number.

7. **Slice, then confirm before printing.** Click Slice plate, read the estimated time and filament use. **STOP 4**: show the Print dialog and wait for explicit confirmation before anything reaches the printer. Done when the job is queued and the user has seen the Printer and filament it will use.

## Hand-offs

When a step needs the user, say exactly what to click and where, then wait. After they reply, verify with a screenshot rather than assuming it happened.
