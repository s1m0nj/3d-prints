// Two-colour boat, 50 mm long. Flat bottom, no supports.
// part: "all" (preview), "hull" (black), "top" (white: cabin + mast)
part = "all";
length = 50;
width = 19;
height = 9;
wall = 1.2;
bottom_scale = 0.6;   // bottom footprint relative to deck
cabin_len = 12;
cabin_w = 9;
cabin_h = 7;          // above deck
cabin_x = -8;
mast_d = 2;
mast_h = 22;
mast_x = 8;
$fn = 64;

// Deck outline: rounded stern, pointed bow. Extremes land exactly at +-l/2.
module plan(l, w) {
  hull() {
    translate([-l/2 + w/2, 0]) circle(d = w);
    translate([l/2 - 1, 0]) circle(d = 2);
  }
}

module hull_shape(l, w, h) {
  hull() {
    translate([-(l - l*bottom_scale)/2 * 0.6, 0, 0]) linear_extrude(0.01) plan(l*bottom_scale, w*bottom_scale);
    translate([0, 0, h]) linear_extrude(0.01) plan(l, w);
  }
}

module outer() { hull_shape(length, width, height); }

module hull_body() {
  difference() {
    outer();
    translate([0, 0, wall]) hull_shape(length - 2*wall, width - 2*wall, height - wall + 1);
  }
}

// Cabin + mast, with the hull subtracted so the two colour parts never overlap.
module top_body() {
  difference() {
    union() {
      intersection() {
        translate([cabin_x, -cabin_w/2, wall - 1]) cube([cabin_len, cabin_w, height + cabin_h - wall + 1]);
        union() {
          outer();
          translate([0, 0, height - 0.01]) linear_extrude(cabin_h + 1) plan(length, width);
        }
      }
      translate([mast_x, 0, wall - 1]) cylinder(d = mast_d, h = mast_h);
    }
    hull_body();
  }
}

if (part == "hull") hull_body();
else if (part == "top") top_body();
else { color("#222") hull_body(); color("white") top_body(); }
