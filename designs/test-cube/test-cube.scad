size = 20;
$fn = 48;
difference() {
  cube(size, center = false);
  translate([size/2, size/2, -1]) cylinder(d = 8, h = size + 2);
}
