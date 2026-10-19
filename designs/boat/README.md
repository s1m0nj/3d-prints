# Boat

Two-colour toy boat, the first test of the OpenSCAD to Bambu Studio process.

- **Purpose:** test model for multi-colour printing.
- **Source:** my own design (`boat.scad`).
- **Size:** 50 mm long, 19 mm wide, 22.2 mm tall.
- **Parts:** `part="hull"` (black), `part="top"` (white cabin and mast), `part="all"` (colour preview).
- **Print:** A1, 0.4 mm nozzle, 0.20 mm Standard, PLA. Import both STLs as one object with multiple parts, then set the top to the white filament.
- **Notes:** the 2 mm mast is thin and may snap.

Build: `~/3d-prints/bin/build.sh boat.scad` (see the skill for the per-part commands).
