// Cabin Wi-Fi QR + IR remote holder. See SPEC.md.
// x across (0 centre), y up the wall (0 bottom edge), z out from the wall (0 = back face).
// part: "all" (assembled preview) | "A" | "B" (B+C, panel face up on bed) | "C" | "D"
part = "all";

include <qr_matrix.scad>   // qr_n, qr_runs = [[col,row_from_top,len],...]

$fn = 64;

// plate
plate_w = 50;  plate_h = 95;  plate_t = 3.0;  corner_r = 7;
// pocket
rem_w = 43; rem_t = 5; rem_l = 90;
pocket_w = 46.4;
pocket_gap = 8.5;
side_wall = 1.8; floor_t = 2.4;
pocket_top_y = 60;
wall_top_z = plate_t + pocket_gap;   // 9.5
// front panel
panel_t = 2.0; panel_h = 60;
edge_fillet = 1.0;
top_corner_r = 1.0;
// raised black
raise = 1.0;
// screws
screw_x = 18; screw_y = 88;
hole_d = 2.9; csk_d = 4.9;
recess_d = 8.0; recess_t = 1.2;
cover_d = 7.6; cover_t = 1.2; cover_ribs = 4; rib_w = 0.8; rib_out = 0.1;
pry_notch_w = 3; pry_notch_depth = 1.0;
// QR + text
mod = 1.3; qr_top_margin = 4.5;
text_str = "Si_Cabin"; text_size = 4.3; text_font = "Helvetica Neue:style=Bold";
text_baseline = 6.0;
glyph_dot_r = 0.9; glyph_stroke = 1.0; glyph_radii = [1.8, 3.6, 5.4];
glyph_gap = 2.2; glyph_dot_y = 6.9;

e = 0.01;
c_top = wall_top_z + panel_t;       // 11.5
panel_top_y = panel_h;

// ---------- outlines ----------
module outline_full() {
  hull() for (sx = [-1, 1], y = [corner_r, plate_h - corner_r])
    translate([sx * (plate_w / 2 - corner_r), y]) circle(r = corner_r);
}
module outline_low() {
  hull() {
    for (sx = [-1, 1]) {
      translate([sx * (plate_w / 2 - corner_r), corner_r]) circle(r = corner_r);
      translate([sx * (plate_w / 2 - top_corner_r), panel_h - top_corner_r]) circle(r = top_corner_r);
    }
  }
}

// convex slab with a quarter-round fillet on the top outer edge
module rounded_slab(t, f, n = 6) {
  linear_extrude(t - f) children();
  for (i = [0 : n - 1]) {
    zm = (i + 0.5) * f / n;
    d = f - sqrt(f * f - zm * zm);
    translate([0, 0, t - f + i * f / n - e]) linear_extrude(f / n + e) offset(r = -d) children();
  }
}

// ---------- part A ----------
module body_A() {
  difference() {
    union() {
      rounded_slab(plate_t, edge_fillet) outline_full();
      linear_extrude(wall_top_z) outline_low();
    }
    // pocket follows the outer corner radius so the wall keeps its thickness there
    translate([0, 0, plate_t]) linear_extrude(wall_top_z) intersection() {
      translate([-pocket_w / 2, floor_t]) square([pocket_w, pocket_top_y - floor_t + 1]);
      offset(delta = -side_wall) outline_low();
    }
    for (sx = [-1, 1]) translate([sx * screw_x, screw_y, 0]) screw_cut();
  }
}
module screw_cut() {
  translate([0, 0, -1]) cylinder(d = hole_d, h = 3);
  translate([0, 0, 0.8]) cylinder(d1 = hole_d, d2 = csk_d, h = (csk_d - hole_d) / 2);   // 90 degree cone
  translate([0, 0, 0.8 + (csk_d - hole_d) / 2 - e]) cylinder(d = csk_d, h = 1);
  translate([0, 0, plate_t - recess_t]) cylinder(d = recess_d, h = recess_t + 1);
  // pry notch on the low-y side
  translate([-pry_notch_w / 2, -recess_d / 2 - pry_notch_depth, plate_t - recess_t])
    cube([pry_notch_w, pry_notch_depth + 1, recess_t + 1]);
}

// ---------- part B (panel, at true z) ----------
module panel_B() {
  translate([0, 0, wall_top_z]) rounded_slab(panel_t, edge_fillet) outline_low();
}

// ---------- part C (black) ----------
function qr_x0() = -qr_n * mod / 2;
function qr_ytop() = panel_top_y - qr_top_margin;

module qr_2d() {
  // tiny growth fuses diagonally touching modules so the mesh stays manifold
  offset(delta = 0.01) for (r = qr_runs)
    translate([qr_x0() + r[0] * mod, qr_ytop() - (r[1] + 1) * mod])
      square([r[2] * mod, mod]);
}
module arc2d(r, w, a0, a1) {
  intersection() {
    difference() { circle(r = r + w / 2); circle(r = r - w / 2); }
    polygon(concat([[0, 0]], [for (a = [a0 : 5 : a1]) 20 * [cos(a), sin(a)]]));
  }
}
module glyph_2d() {
  circle(r = glyph_dot_r);
  for (r = glyph_radii) arc2d(r, glyph_stroke, 45, 135);
}
glyph_w = 2 * (glyph_radii[2] + glyph_stroke / 2) * sin(45);
// measured ink width and left bearing of "Si_Cabin" at text_size (mm)
text_w = 24.02; text_x_ink = 0.14;
module text_2d() {
  text(text_str, size = text_size, font = text_font, halign = "left", valign = "baseline");
}
module label_2d() {
  total = glyph_w + glyph_gap + text_w;
  x0 = -total / 2;
  translate([x0 + glyph_w / 2, glyph_dot_y]) glyph_2d();
  translate([x0 + glyph_w + glyph_gap - text_x_ink, text_baseline]) text_2d();
}
module black_C() {
  translate([0, 0, c_top]) linear_extrude(raise) { qr_2d(); label_2d(); }
}

// ---------- part D ----------
module cover() {
  cylinder(d = cover_d, h = cover_t);
  for (i = [0 : cover_ribs - 1]) rotate(i * 360 / cover_ribs + 45)
    intersection() {
      translate([cover_d / 2 - 0.5, -rib_w / 2, 0]) cube([0.5 + rib_out, rib_w, cover_t]);
      cylinder(r = cover_d / 2 + rib_out, h = cover_t);
    }
}
module covers_D() {
  for (i = [0 : 1], j = [0 : 1]) translate([i * 10, j * 10, 0]) cover();
}

// ---------- dispatch ----------
if (part == "all") {
  color("white") body_A();
  color("white") panel_B();
  color("black") black_C();
  for (sx = [-1, 1]) color("white") translate([sx * screw_x, screw_y, plate_t - cover_t]) cover();
} else if (part == "A") body_A();
else if (part == "B") translate([0, 0, -wall_top_z]) { panel_B(); }
else if (part == "BC") translate([0, 0, -wall_top_z]) { panel_B(); black_C(); }
else if (part == "C") translate([0, 0, -wall_top_z]) black_C();
else if (part == "D") covers_D();
