# Reference

## Tools on this Mac

- OpenSCAD 2021.01 at `~/Applications/OpenSCAD.app` (the Homebrew cask is disabled).
- `~/3d-prints/bin/build.sh <file.scad> [name=value ...]` writes STL, 3MF, four PNGs, and a size report to `out/`. Set `OUTNAME` to rename outputs, e.g. `OUTNAME=boat-hull build.sh boat.scad part=\"hull\"`.
- System Python 3.6 crashes here. Use awk or shell for scripting.
- OpenSCAD auto-reload and auto-preview are enabled, so saving the `.scad` refreshes an open window. Opening the same file twice can spawn a second window: close the extra one.
- OpenSCAD GUI: F5 previews (`key code 96` via System Events), Cmd+Shift+V fits the view.

## A1 design rules

- Build volume 256 x 256 x 256 mm. The build.sh report flags oversize parts.
- Overhangs steeper than 45 degrees need supports: prefer chamfers, or print flat-side down.
- Walls 1.2 mm minimum (3 lines at 0.4 mm). Features under 0.8 mm do not print reliably. Free-standing pins under 2 mm diameter break easily.
- Clearance: 0.1 mm snug, 0.2 mm sliding, 0.3 to 0.4 mm loose. Printed holes come out 0.1 to 0.2 mm small.
- `$fn` 64 or higher on visible curves. Overlap unions by 0.01 mm or more and extend cuts past surfaces so the mesh stays manifold.
- The user's setup: Bambu Lab A1, 0.4 mm nozzle, 0.20 mm Standard profile, black PLA and white PLA.

## Multi-colour

OpenSCAD 2021.01 does not write colours into 3MF. Export one STL per colour instead.

- Give the `.scad` a `part` switch (`"all"` for preview, one value per colour).
- Make parts non-overlapping: subtract the lower part from the upper (`difference() { top(); hull_body(); }`), so no volume is claimed twice.
- Build each part, then open all the STLs together in Bambu Studio and accept the multi-part prompt.
- Colour by height (a stripe at a layer) belongs in Bambu Studio, not the model.

## Multi-plate

- A part over 256 mm per axis, or a set too big for one plate: split it in OpenSCAD with a cut plane, add alignment pegs and matching sockets (0.2 mm clearance), then check every piece against the size report. The user approves any split before it is built.
- Several pieces or long prints: use Bambu Studio's plates, one piece per plate, slice all plates, queue each.

## Driving Bambu Studio from the Mac

Screenshots (`screencapture -x`) and System Events keystrokes work once the user grants permission.

- Screenshot pixels are larger than screen points. Divide screenshot coordinates by (screenshot width / screen width): on this Mac 2000 / 1680 = 1.1905. Read screen width with `osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.mainScreen.frame.size.width'`.
- `osascript -l JavaScript ~/3d-prints/bin/click.js <x> <y>` sends a real left click in screen points. System Events `click at` does nothing in Bambu Studio.
- Buttons, tabs, row selection, and right-click menus respond to real clicks. Native dropdowns (per-part filament) do not open: hand that step to the user.
- Bring the app forward before clicking: `osascript -e 'tell application "BambuStudio" to activate'`. A click lands in whichever window is on top.
- Resize with `tell process "BambuStudio" to set size of window 1 to {1700, 1000}` so the object list is visible.
- Print history, printer selection, and the queue live behind Print plate and the Device tab. Show the dialog to the user before confirming.
