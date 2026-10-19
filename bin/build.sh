#!/bin/bash
# Usage: build.sh model.scad [name=value ...]
# Outputs next to the .scad in out/: STL, 3MF, preview PNGs (iso/front/top/side) and a bbox report.
set -euo pipefail
SCAD_BIN="$HOME/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
src="$1"; shift
dir="$(cd "$(dirname "$src")" && pwd)"
name="$(basename "$src" .scad)"; oname="${OUTNAME:-$name}"
out="$dir/out"; mkdir -p "$out"
defs=(); for d in "$@"; do defs+=(-D "$d"); done

echo "== Export =="
"$SCAD_BIN" -o "$out/$oname.stl" ${defs[@]+"${defs[@]}"} "$dir/$name.scad" 2>&1 | grep -vE '^$' || true
"$SCAD_BIN" -o "$out/$oname.3mf" ${defs[@]+"${defs[@]}"} "$dir/$name.scad" 2>&1 | grep -E 'WARNING|ERROR' || true

echo "== Previews =="
render() { # label rx,ry,rz
  "$SCAD_BIN" -o "$out/$oname-$1.png" --imgsize=900,700 --viewall --autocenter \
    --camera=0,0,0,$2,500 --projection=p --colorscheme=Tomorrow \
    ${defs[@]+"${defs[@]}"} "$dir/$name.scad" 2>&1 | grep -E 'WARNING|ERROR' || true
}
render iso 55,0,25
render front 90,0,0
render top 0,0,0
render side 90,0,90
ls "$out"/$oname-*.png

echo "== Report =="
awk '
/^[ \t]*facet/ {t++}
/^[ \t]*vertex/ { x=$2;y=$3;z=$4
  if(!n++){x0=x1=x;y0=y1=y;z0=z1=z}
  if(x<x0)x0=x; if(x>x1)x1=x; if(y<y0)y0=y; if(y>y1)y1=y; if(z<z0)z0=z; if(z>z1)z1=z }
END { if(!n){print "EMPTY MODEL - nothing exported"; exit 1}
  dx=x1-x0;dy=y1-y0;dz=z1-z0
  printf "triangles: %d\nsize mm  X=%.2f Y=%.2f Z=%.2f\nmin corner: %.2f %.2f %.2f\n",t,dx,dy,dz,x0,y0,z0
  print "fits A1 (256^3):", (dx<=256&&dy<=256&&dz<=256)?"YES":"NO" }' "$out/$oname.stl"
