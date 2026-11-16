// =====================================================================
//  HueForge Floating Frame  -  Customizer / MakerWorld edition
//  Design: Michael Bernasconi (v3.2: flat bottom, open back, glue-in panel,
//  slide-in stand on two dovetails printed in the frame's lower bay with
//  breakaway tabs).  Single self-contained file, no includes, no fonts.
//
//  Enter your HueForge print's width and height (mm).  Pick a part, render,
//  export STL/3MF.  Print exactly as exported: frame back face down, stand
//  lying flat.  NO supports, NO brim (a brim would weld the stand in).
//  Snap the stand out of its bay, slide it into the two dovetails on the
//  back of the spine from the right (seen from the back) -> 10 deg lean.
//  Slide it out to hang the frame on the keyhole.
// =====================================================================

/* [Your HueForge print] */
// Width of your HueForge print (mm) - the size set in HueForge
panel_w = 133.33; // [30:0.01:300]
// Height of your HueForge print (mm)
panel_h = 200; // [30:0.01:300]
// Thickness of your print (mm). Only for the read-out: the glue pocket is always pocket_depth deep
panel_t = 2.4; // [0.6:0.1:4]
// What to make
part = "frame_with_stand"; // [frame_with_stand:Frame + stand in its bay (one print), frame_only:Frame only, stand_only:Stand only]

/* [Advanced - frame] */
// Visible frame edge seen from the front (mm)
border = 4; // [3:0.5:15]
// Gap around the print, PER SIDE (mm). Pocket = print + 2 x clearance
clearance = 0.2; // [0:0.05:1]
// Glue pocket depth, frame front down to the glue ledge (mm)
pocket_depth = 4; // [2:0.5:8]
// Glue ledge width the print rests on (mm)
ledge_w = 3.5; // [2:0.5:6]
// Rounded fillet on the outer front edge (mm, 0 = sharp)
outer_fillet = 1.5; // [0:0.25:3]
// Rounding of the 4 outer corners (mm, 0 = square)
corner_r = 2; // [0:0.5:6]
// Crossbar across the back (stiffness)
crossbar = true;
// Crossbar height as a fraction of the frame height (keep it above the stand slots)
crossbar_frac = 0.55; // [0.45:0.01:0.8]
// Size of the triangular corner gussets on the back (mm, 0 = none)
gusset = 14; // [0:1:25]
// Keyhole for hanging on a screw (#6-#8 pan head)
keyhole = true;

/* [Advanced - stand] */
// Lean back angle with the stand in (degrees)
stand_lean = 10; // [5:0.5:20]
// Dovetail sliding clearance PER SIDE (mm). 0.1 = snug on a Bambu H2C; raise to 0.12-0.15 if too tight
stand_cl = 0.1; // [0.05:0.01:0.3]
// Height of the lower dovetail slot, fraction of the frame height
slot_lo_frac = 0.2; // [0.12:0.01:0.3]
// Height of the upper dovetail slot, fraction of the frame height
slot_hi_frac = 0.35; // [0.25:0.01:0.45]
// Stand thickness = its print height (mm); must stay below the frame depth to print in the bay
stand_t = 10; // [6:0.5:11]
// Foot distance behind the frame (mm, 0 = automatic: 20% of the frame height, min 30)
stand_reach = 0; // [0:1:80]

/* [Advanced - stand in bay / tabs] */
// Print the stand inside the frame's lower bay (falls back to beside the frame if it doesn't fit)
stand_in_bay = true;
// Air gap between the stand and the frame in the bay (mm)
bay_gap = 0.5; // [0.3:0.05:1]
// Breakaway tab thickness = height above the bed (mm)
tab_t = 0.6; // [0.4:0.1:1.2]
// Breakaway tab width (mm)
tab_w = 2.5; // [1.5:0.1:4]
// Width of the V-neck where the tab breaks (mm). Bigger = stronger, harder to snap
tab_neck = 0.8; // [0.4:0.1:1.6]

/* [Hidden] */
pocket_fillet = 0; ledge_t = 1.2; reveal = 0; corner_relief = 0; fillet_steps = 10; back_depth = 7.4;
spine_w = 0; crossbar_w = 8;
key_head_d = 9.0; key_slot_w = 4.5; key_slot_len = 10; key_lip_t = 2.0; key_head_room = 3.2; key_roof = 1.0;
key_from_top = 12; key_double_over = 220;
slot_fracs = [slot_lo_frac, slot_hi_frac];
dt_neck = 6; dt_wide = 9; dt_depth = 4; recv_wall = 3.5; mouth_chamfer = 0.4;
stand_top_pad = 8; stand_top_d = 10; stand_lift = 1.0; foot_len = 8; foot_h = 6; stand_web = 6; tongue_chamfer = 0.4;
frame_g_est = 0; panel_fill = 1.0;
tab_taper = 1.2;
stand_slide = 0; show_panel = false; section = ""; section_at = 0;

bed_x = 325;  bed_y = 320;

$fn = 48;
part_ = part == "frame_with_stand" ? "print" : part == "frame_only" ? "frame" : part == "stand_only" ? "stand" : part;
eps = 0.01;

// ---------------------------------------------------------------- derived
gap = clearance + reveal;
pw = panel_w + 2*gap;
ph = panel_h + 2*gap;
OW = pw + 2*border;
OH = ph + 2*border;
x_in = pw/2 - ledge_w;
y_in0 = border + ledge_w;
y_in1 = border + ph - ledge_w;

z_need_key  = keyhole ? key_lip_t + 1 + key_head_room + key_roof : 0;
z_need_slot = dt_depth + 2;
z_seat = back_depth > 0 ? back_depth : max(z_need_key, z_need_slot, ledge_t + 2);
D = z_seat + pocket_depth;
panel_recess = pocket_depth - panel_t;

SWk = key_head_d + 9;
SWr = stand_t + 2*stand_cl + 2*recv_wall;
SW  = spine_w > 0 ? spine_w : max(SWk, SWr);
two_keys = OW > key_double_over;
key_xs   = two_keys ? [-OW*0.3, OW*0.3] : [0];

y_lo_  = max(slot_lo_frac * OH, border + ledge_w + 2 + dt_wide/2);   // keep clear of the bottom rail
yss    = [y_lo_, max(slot_hi_frac * OH, y_lo_ + dt_wide + 6)];          // slot centres, >= dt_wide + 6 mm apart (small frames)
ys     = max(yss);                               // top slot (sets the stand height)
ys_lo  = min(yss);
x_stop = stand_t/2 + stand_cl;                    // stop wall face (slot is open toward -x)
yc     = crossbar_frac * OH;
F      = stand_reach > 0 ? stand_reach : max(30, 0.2*OH);
y_top  = ys + dt_wide/2 + stand_top_pad;
L      = stand_lean;

// stand 2D profile, points are [z, y] in frame coordinates (z<0 = behind the frame)
function tab(z) = [z, -z*tan(L)];                 // point on the table line through the frame's back-bottom edge
upv  = [sin(L), cos(L)];                          // world "up" in [z, y]
B1 = tab(-(F - foot_len));
B2 = tab(-F);
B3 = B2 + foot_h*upv;
stand_pts = [[0, stand_lift], B1, B2, B3, [-stand_top_d, y_top], [0, y_top]];

function r1(v) = round(v*10)/10;
function hw(z) = dt_neck/2 + (dt_wide - dt_neck)/2 * z/dt_depth;
function slot_pts_at(y) = [[-1, y - hw(-1)], [dt_depth, y - dt_wide/2], [dt_depth, y + dt_wide/2], [-1, y + hw(-1)]];

// balance (frame + panel), table contacts: frame back-bottom edge (0,0) and foot (B2..B1)
frame_g = frame_g_est > 0 ? frame_g_est : 55*(OW + OH)/350.13;
panel_g = panel_w*panel_h*panel_t/1000*1.24*panel_fill;
zc      = (frame_g*D*0.4 + panel_g*(z_seat + panel_t/2)) / (frame_g + panel_g);
function back_of(p) = p[1]*sin(L) - p[0]*cos(L);    // horizontal distance behind the frame's edge contact
function up_of(p)   = p[1]*cos(L) + p[0]*sin(L);
cm      = [zc, OH/2];
x_cm    = back_of(cm);
x_foot  = back_of(B2);
x_foot1 = back_of(B1);
z_flat  = D - min(outer_fillet, border - 1);         // flat part of the bottom face (front fillet excluded)
tip_fwd = L + atan((z_flat - zc)/(OH/2));            // nudge (deg) at the top to tip it onto its face
tip_back= atan((x_foot - x_cm)/up_of(cm));

echo(str("FRAME_OUTER_MM=", OW, " x ", OH, " x ", D));
echo(str("POCKET_MM=", pw, " x ", ph, " x ", pocket_depth, " deep, ledge ", ledge_w, " wide at z=", z_seat));
echo(str("PANEL_BOX=", -panel_w/2, ",", border + gap, ",", z_seat, ",", panel_w, ",", panel_h, ",", panel_t));
echo(str("V3SECT=", OW, ",", OH, ",", D, ",", ys, ",", L, ",", x_stop, ",", SW));
echo(str("SLOTS_Y=", yss));
echo(str("PANEL: face sits ", panel_recess, " mm below the frame front (", panel_t, " mm panel)"));
echo(str("SPINE: ", SW, " mm wide, unbroken y=0..", OH, "; crossbar at y=", yc));
echo(str("SLOT: dovetail ", dt_neck, "->", dt_wide, " mm x ", dt_depth, " deep, ", len(yss), " slots at y=", yss,
         ", open toward -x (right side seen from the back), stop wall at x=", x_stop,
         ", roof under panel ", z_seat - dt_depth, " mm"));
echo(str("STAND: ", stand_t, " thick, ", y_top - stand_lift, " tall x ", F, " reach, clearance ", stand_cl,
         "/side, lean ", L, " deg"));
echo(str("BALANCE: frame ~", round(frame_g), " g + panel ~", round(panel_g), " g, CoM ", r1(x_cm),
         " mm behind the edge contact, foot pad at ", r1(x_foot1), "..", r1(x_foot), " mm (stable=", x_cm > 0 && x_cm < x_foot1,
         "), tip forward needs ", r1(tip_fwd), " deg, tip back ", r1(tip_back), " deg"));
if (keyhole && z_seat - key_roof - key_lip_t - 1 < 2.5) echo("WARNING: keyhole head room < 2.5 mm, raise back_depth");
if (z_seat - dt_depth < 2) echo("WARNING: < 2 mm roof between the stand slot and the panel");
if (SW < SWr) echo("WARNING: spine_w too narrow for the stand slot + stop wall");
for (y = yss) if (abs(yc - y) < crossbar_w/2 + dt_wide/2 + 3) echo(str("WARNING: crossbar too close to the stand slot at y=", y, " - it would block the slide-in"));
for (i = [0:len(yss)-1], j = [0:len(yss)-1]) if (i < j && abs(yss[i] - yss[j]) < dt_wide + 6) echo("WARNING: dovetail slots closer than dt_wide + 6 mm");
if (ys_lo - dt_wide/2 < border + ledge_w + 2) echo("WARNING: lowest slot runs into the bottom rail");
if (keyhole && border + ph - key_from_top - key_slot_len - key_head_d < y_top) echo("WARNING: stand reaches the keyhole");
if (!((OW <= bed_x && OH <= bed_y) || (OH <= bed_x && OW <= bed_y)))
  echo(str("WARNING: frame ", OW, " x ", OH, " exceeds H2C bed ", bed_x, " x ", bed_y));

// ---------------------------------------------------------------- frame body (v2 unchanged)
module rbox(x0, y0, x1, y1, z0, z1) translate([x0, y0, z0]) cube([x1-x0, y1-y0, z1-z0]);
module outer_2d(inset=0) {
  r = max(corner_r - inset, 0.01);
  translate([0, OH/2]) offset(r=r) square([OW - 2*inset - 2*r, OH - 2*inset - 2*r], center=true);
}
module outer_shape() {
  rf = min(outer_fillet, border - pocket_fillet - 1, D - 1);
  n  = fillet_steps;
  hull() {
    linear_extrude(D - rf + eps) outer_2d(0);
    for (i=[1:n]) let(a = 90*i/n)
      translate([0, 0, D - rf + rf*sin(a) - eps]) linear_extrude(eps) outer_2d(rf*(1 - cos(a)));
  }
}
module pocket_2d(grow=0) { translate([0, border + ph/2]) offset(r=max(grow, 0.001)) square([pw, ph], center=true); }
module pocket_cut() {
  rbox(-pw/2, border, pw/2, border + ph, z_seat, D + 1);
  if (corner_relief > 0) for (sx=[-1,1], sy=[0,1]) translate([sx*pw/2, border + sy*ph, z_seat]) cylinder(r=corner_relief, h=D);
  rp = pocket_fillet; n = fillet_steps;
  if (rp > 0) for (i=[0:n-1]) hull() {
    a0 = 90*i/n; a1 = 90*(i+1)/n;
    translate([0, 0, D - rp + rp*sin(a0)]) linear_extrude(eps) pocket_2d(rp*(1 - cos(a0)));
    translate([0, 0, D - rp + rp*sin(a1)]) linear_extrude(i == n-1 ? 1 : eps) pocket_2d(rp*(1 - cos(a1)) + (i == n-1 ? eps : 0));
  }
}
module back_window_cut() {
  zt = z_seat - ledge_t;
  zb = zt - ledge_w;
  rbox(-x_in, y_in0, x_in, y_in1, zt - eps, z_seat + eps);
  hull() {
    rbox(-x_in, y_in0, x_in, y_in1, zt, zt + eps);
    rbox(-pw/2, border, pw/2, border + ph, zb, zb + eps);
  }
  rbox(-pw/2, border, pw/2, border + ph, -1, zb + eps);
}
module back_structure() {   // unbroken spine, crossbar, gussets - bed up to the ledge top
  intersection() {
    rbox(-pw/2 - eps, border - eps, pw/2 + eps, border + ph + eps, 0, z_seat);
    union() {
      rbox(-SW/2, 0, SW/2, OH, 0, z_seat);                                         // full-height spine
      if (keyhole && two_keys) for (kx = key_xs)
        rbox(kx - SWk/2, border + ph - key_from_top - key_slot_len - key_head_d/2 - 4, kx + SWk/2, OH, 0, z_seat);
      if (crossbar) rbox(-OW/2, yc - crossbar_w/2, OW/2, yc + crossbar_w/2, 0, z_seat);
      if (gusset > 0) for (sx=[-1,1], sy=[0,1])
        translate([sx*pw/2, border + sy*ph, 0]) scale([-sx, 1 - 2*sy, 1])
          linear_extrude(z_seat) polygon([[0,0],[gusset + ledge_w, 0],[0, gusset + ledge_w]]);
    }
  }
}
module nubs() {
  if (reveal > 0) for (f=[0.25, 0.75]) {
    for (sx=[-1,1]) translate([sx*pw/2, border + f*ph, z_seat]) cylinder(r=reveal, h=pocket_depth - 0.6);
    for (sy=[0,1])  translate([(f - 0.5)*pw, border + sy*ph, z_seat]) cylinder(r=reveal, h=pocket_depth - 0.6);
  }
}
module keyhole_cut(x) {
  yt = border + ph - key_from_top;
  yb = yt - key_slot_len;
  z1 = key_lip_t + 1;
  translate([x, 0, 0]) {
    translate([0, yb, -1]) cylinder(d=key_head_d, h=z1 + 1 + eps);
    translate([-key_slot_w/2, yb, -1]) cube([key_slot_w, key_slot_len, z1 + 1 + eps]);
    translate([0, 0, z1]) hull() {
      translate([0, yb, 0]) cylinder(d=key_head_d + 0.4, h=z_seat - key_roof - z1);
      translate([0, yt, 0]) cylinder(d=key_head_d + 0.4, h=z_seat - key_roof - z1);
    }
  }
}

// [z, y] profile -> frame coordinates, extruded along x from x0 to x1
module zy_extrude(x0, x1) {
  multmatrix([[0,0,1,x0],[0,1,0,0],[1,0,0,0],[0,0,0,1]]) linear_extrude(x1 - x0) children();
}
module slot_cut() {   // dovetails along x, blind at x_stop, open past the spine's -x side
  x_open = -SW/2 - 1;
  for (y = yss) {
    zy_extrude(x_open, x_stop) polygon(slot_pts_at(y));
    zy_extrude(x_open, x_stop) hull() {                  // 45 deg mouth flare at the back face
      polygon([[-1, y - dt_neck/2 - mouth_chamfer - 1], [-1, y + dt_neck/2 + mouth_chamfer + 1],
               [mouth_chamfer, y + dt_neck/2 - eps], [mouth_chamfer, y - dt_neck/2 + eps]]);
    }
  }
}

module frame_body() {
  difference() {
    union() {
      difference() { outer_shape(); pocket_cut(); back_window_cut(); }
      back_structure();
      nubs();
    }
    if (keyhole) for (kx = key_xs) keyhole_cut(kx);
    slot_cut();
  }
}

// ---------------------------------------------------------------- stand
module stand_2d_body() {   // [z, y] profile, behind the frame (z <= 0), with a window cut-out
  difference() {
    polygon(stand_pts);
    offset(r=stand_web/2) offset(delta=-stand_web - stand_web/2) polygon(stand_pts);
  }
}
module tongue_2d(y, extra=0) {
  intersection() {
    offset(delta=-stand_cl - extra) polygon(slot_pts_at(y));
    translate([-0.5, 0]) square([dt_depth + 1, OH]);
  }
}
// stand in its own print coordinates: profile in XY ([z, y] -> [X, Y]), thickness along Z from 0
module stand_print_local() {
  linear_extrude(stand_t) stand_2d_body();
  for (y = yss) hull() {
    translate([0, 0, tongue_chamfer]) linear_extrude(stand_t - 2*tongue_chamfer) tongue_2d(y);
    linear_extrude(stand_t) tongue_2d(y, tongue_chamfer);
  }
}
// stand inserted, frame coordinates (local Z -> frame x, local X -> frame z)
module stand_inserted() {
  translate([-stand_t/2 - stand_slide, 0, 0]) multmatrix([[0,0,1,0],[0,1,0,0],[1,0,0,0],[0,0,0,1]]) stand_print_local();
}

// ---------------------------------------------------------------- outputs
module panel() { translate([-panel_w/2, border + gap, z_seat]) cube([panel_w, panel_h, panel_t]); }
module assembly() {
  color("BurlyWood") frame_body();
  color("SaddleBrown") stand_inserted();
  if (show_panel) color("SteelBlue") panel();
}
// print plate: frame back-down, stand flat beside it (the stand's [z,y] profile has X in [-F, dt_depth])
plate_dx = OW/2 + 8 + F;
plate_dy = (OH - y_top)/2;
echo(str("PLATE_STAND_AT=", plate_dx, ",", plate_dy));

// ---------------------------------------------------------------- v3.2: stand printed in a lower bay
// stand profile [pz, py] -> frame plan [x, y]: rotated 180 deg, tongues toward the spine, top end down
X0 = SW/2 + bay_gap + (dt_depth - stand_cl);             // frame x of the stand's front edge (pz = 0)
Yb = y_in0 + bay_gap;                                    // frame y of the stand's top end (py = y_top)
function to_bay(p) = [X0 - p[0], Yb + y_top - p[1]];
tip_pts  = [for (y = yss) for (d = [-1, 1]) [dt_depth - stand_cl, y + d*(dt_wide/2 - stand_cl)]];
bay_pts  = [for (p = concat(stand_pts, tip_pts)) to_bay(p)];
bay_x1   = x_in - bay_gap;                               // outer side of the bay (inside the ledge)
bay_y1   = (crossbar ? yc - crossbar_w/2 : y_in1) - bay_gap;
g_leg    = gusset > 0 ? gusset + ledge_w : 0;
fit_x    = max([for (p = bay_pts) p[0]]) <= bay_x1;
fit_y    = max([for (p = bay_pts) p[1]]) <= bay_y1;
fit_gus  = g_leg == 0 || min([for (p = bay_pts) (pw/2 - p[0]) + (p[1] - border)]) >= g_leg + bay_gap*sqrt(2);
fit_gus2 = g_leg == 0 || crossbar || min([for (p = bay_pts) (pw/2 - p[0]) + (border + ph - p[1])]) >= g_leg + bay_gap*sqrt(2);
fit_t    = stand_t <= D - 0.4;
fit_cb   = !crossbar || yc - crossbar_w/2 > y_in0 + 10;
in_bay   = stand_in_bay && fit_x && fit_y && fit_gus && fit_gus2 && fit_t && fit_cb;
echo(str("STAND_IN_BAY=", in_bay, "  (bay x ", SW/2, "..", r1(x_in), ", y ", y_in0, "..", r1(bay_y1 + bay_gap),
         "; stand needs x to ", r1(max([for (p = bay_pts) p[0]])), ", y to ", r1(max([for (p = bay_pts) p[1]])),
         "; fits: width ", fit_x, ", height ", fit_y, ", gusset ", fit_gus && fit_gus2, ", thickness ", fit_t, " (", stand_t, " <= ", D - 0.4, ")",
         ")"));
if (stand_in_bay && !in_bay) echo("NOTE: stand does not fit in the bay at this size - placed SEPARATELY on the plate (v3.1 layout)");

// tabs, frame plan coordinates.  tab(a, b): a = point on the face where it should BREAK (V neck), b = other face
module tab(a, b) {
  d = b - a; Lt = norm(d); u = d / Lt; n = [-u[1], u[0]];
  ov = 0.3;                                              // overlap into each part
  pa = a - ov*u;  pb = b + ov*u;
  linear_extrude(tab_t) polygon([
    pa + n*tab_neck/2, a + n*tab_neck/2, a + u*tab_taper + n*tab_w/2, pb + n*tab_w/2,
    pb - n*tab_w/2, a + u*tab_taper - n*tab_w/2, a - n*tab_neck/2, pa - n*tab_neck/2]);
}
// front-edge tabs (to the spine): break at the STAND side, so the stand's bearing face stays clean
front_tab_py = [(stand_lift + ys_lo - dt_wide/2) / 2,
                for (i = [0:len(yss)-2]) (yss[i] + yss[i+1]) / 2];
// top-end tabs (to the bottom rail, under the ledge): break at the FRAME side, frame stays clean
top_tab_pz = [-stand_top_d*0.25, -stand_top_d*0.75];
module tabs() {
  for (py = front_tab_py) let(sy = Yb + y_top - py) tab([X0, sy], [SW/2, sy]);
  for (pz = top_tab_pz)   let(sx = X0 - pz) tab([sx, border], [sx, Yb]);
}
module stand_in_bay_m() translate([X0, Yb + y_top, 0]) rotate([0, 0, 180]) stand_print_local();
echo(str("TABS: ", len(front_tab_py) + len(top_tab_pz), " tabs, ", tab_t, " thick x ", tab_w, " wide, V-neck ", tab_neck,
         " mm; front-edge tabs to the spine at frame y=", [for (py = front_tab_py) r1(Yb + y_top - py)],
         ", top-end tabs to the bottom rail at frame x=", [for (pz = top_tab_pz) r1(X0 - pz)]));
echo(str("V32=", X0, ",", Yb, ",", y_top, ",", bay_gap, ",", tab_t));

if (section == "x") {
  intersection() { assembly(); translate([section_at - 0.2, -1, -F - 5]) cube([0.4, OH + 2, D + F + 10]); }
} else if (part_ == "print") {
  if (in_bay) {
    frame_body();
    stand_in_bay_m();
    tabs();
  } else {
    frame_body();
    translate([plate_dx, plate_dy, 0]) stand_print_local();
  }
} else if (part_ == "tabs") {
  tabs();
} else if (part_ == "stand_in_bay") {
  stand_in_bay_m();
} else if (part_ == "frame") {
  frame_body();
} else if (part_ == "stand") {
  stand_print_local();
} else if (part_ == "plate") {
  frame_body();
  translate([plate_dx, plate_dy, 0]) stand_print_local();
} else if (part_ == "stand_inserted") {
  stand_inserted();
} else if (part_ == "inserted") {
  assembly();
} else if (part_ == "joint") {         // close-up crop around the slot, for previews
  intersection() {
    union() { color("BurlyWood") frame_body(); if (stand_slide < 900) color("SaddleBrown") stand_inserted(); }
    translate([-SW/2 - 14, ys_lo - 16, -14]) cube([SW + 18, ys - ys_lo + 32, D + 15]);
  }
} else if (part_ == "standing") {
  rotate([-L, 0, 0]) rotate([90, 0, 0]) assembly();
  color("LightGray") translate([-OW*0.8, -OH*0.4, -1]) cube([1.6*OW, OH*0.8, 1]);
}
