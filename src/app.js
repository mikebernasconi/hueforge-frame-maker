import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { createOpenSCAD } from "../build/openscad.js";
import SCAD from "./frame.scad";
import { parseCustomizer, buildArgs, cleanStl, toBinaryStl, to3mf, meshBounds, parseEcho } from "./core.js";

const $ = s => document.querySelector(s);
const tabs = parseCustomizer(SCAD);
const types = {}, defaults = {};
tabs.forEach(t => t.params.forEach(p => { types[p.name] = p.type; defaults[p.name] = p.value; }));

// ---------- form
function buildForm() {
  const host = $("#params");
  tabs.forEach((t, ti) => {
    const sec = document.createElement("details"); if (ti === 0) sec.open = true;
    sec.innerHTML = `<summary>${t.name}</summary>`;
    t.params.forEach(p => {
      const row = document.createElement("div"); row.className = "row";
      const NICE = { panel_w: "Print width (mm)", panel_h: "Print height (mm)", panel_t: "Print thickness (mm)", part: "What to make",
        stand_cl: "Stand clearance per side (mm)", stand_lean: "Stand lean (deg)", bay_gap: "Bay gap (mm)", tab_t: "Tab thickness (mm)", tab_w: "Tab width (mm)", tab_neck: "Tab neck width (mm)" };
      const label = NICE[p.name] || p.name.replace(/_/g, " ");
      let ctl = "";
      if (p.type === "bool") ctl = `<input type="checkbox" id="p_${p.name}" ${p.value ? "checked" : ""}>`;
      else if (p.control === "select") ctl = `<select id="p_${p.name}">${p.options.map(o => `<option value="${o.value}" ${String(o.value) === String(p.value) ? "selected" : ""}>${o.label}</option>`).join("")}</select>`;
      else if (p.control === "slider") ctl = `<input type="range" id="r_${p.name}" min="${p.min}" max="${p.max}" step="${p.step}" value="${p.value}"><input type="number" id="p_${p.name}" min="${p.min}" max="${p.max}" step="${p.step}" value="${p.value}">`;
      else ctl = `<input type="${p.type === "number" ? "number" : "text"}" id="p_${p.name}" value="${p.value}">`;
      row.innerHTML = `<label for="p_${p.name}" title="${p.name}">${label}</label><div class="ctl">${ctl}</div>${p.desc ? `<div class="desc">${p.desc}</div>` : ""}`;
      sec.appendChild(row);
    });
    host.appendChild(sec);
  });
  tabs.forEach(t => t.params.forEach(p => {
    const r = $(`#r_${p.name}`), n = $(`#p_${p.name}`);
    if (r) { r.oninput = () => n.value = r.value; n.oninput = () => r.value = n.value; }
  }));
  // main size inputs at the top get precise typing; also mirror width/height into the headline boxes
}
function values() {
  const v = {};
  tabs.forEach(t => t.params.forEach(p => {
    const el = $(`#p_${p.name}`);
    v[p.name] = p.type === "bool" ? el.checked : p.type === "number" ? Number(el.value) : el.value;
  }));
  return v;
}
function resetForm() { tabs.forEach(t => t.params.forEach(p => {
  const el = $(`#p_${p.name}`), r = $(`#r_${p.name}`);
  if (p.type === "bool") el.checked = p.value; else el.value = p.value; if (r) r.value = p.value; })); }

// ---------- viewer
let renderer, scene, camera, controls, meshObj;
function initViewer() {
  const box = $("#view");
  renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
  renderer.setPixelRatio(window.devicePixelRatio); box.appendChild(renderer.domElement);
  scene = new THREE.Scene(); scene.background = new THREE.Color(0xf4f1ec);
  camera = new THREE.PerspectiveCamera(35, 1, 1, 5000); camera.up.set(0, 0, 1);
  controls = new OrbitControls(camera, renderer.domElement);
  scene.add(new THREE.HemisphereLight(0xffffff, 0x8a7a66, 1.6));
  const d = new THREE.DirectionalLight(0xffffff, 1.6); d.position.set(150, -200, 300); scene.add(d);
  const d2 = new THREE.DirectionalLight(0xffffff, 0.6); d2.position.set(-200, 150, -200); scene.add(d2);
  const grid = new THREE.GridHelper(320, 32, 0xb9ad9c, 0xd9d0c3); grid.rotation.x = Math.PI / 2; scene.add(grid);
  const resize = () => { const w = box.clientWidth, h = box.clientHeight; renderer.setSize(w, h); camera.aspect = w / h; camera.updateProjectionMatrix(); };
  window.addEventListener("resize", resize); resize();
  (function loop() { requestAnimationFrame(loop); controls.update(); renderer.render(scene, camera); })();
}
function showMesh(m, viewFrom) {
  if (meshObj) { scene.remove(meshObj); meshObj.geometry.dispose(); }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.BufferAttribute(m.verts, 3)); g.setIndex(new THREE.BufferAttribute(m.idx, 1));
  const ng = g.toNonIndexed(); ng.computeVertexNormals();
  const b = meshBounds(m), c = b.lo.map((l, i) => (l + b.hi[i]) / 2);
  ng.translate(-c[0], -c[1], -b.lo[2]);
  meshObj = new THREE.Mesh(ng, new THREE.MeshStandardMaterial({ color: 0xd2a56c, roughness: 0.75, metalness: 0.0, side: THREE.DoubleSide }));
  scene.add(meshObj);
  const r = Math.max(...b.size);
  const dir = viewFrom === "back" ? new THREE.Vector3(0.35, -0.9, -1.1) : new THREE.Vector3(0.45, -1.0, 1.25);
  camera.position.copy(dir.normalize().multiplyScalar(r * 2.1)); controls.target.set(0, 0, b.size[2] / 2); controls.update();
}

// ---------- engine
let lastMesh = null, lastName = "HueForge_Frame";
async function generate() {
  const btn = $("#gen"); btn.disabled = true; setStatus("Generating…", "busy");
  await new Promise(r => setTimeout(r, 30));
  const v = values(), log = [];
  try {
    const t0 = performance.now();
    const o = await createOpenSCAD({ print: s => log.push(s), printErr: s => log.push(s) });
    const inst = o.getInstance();
    inst.FS.writeFile("/in.scad", SCAD);
    let rc; try { rc = inst.callMain(buildArgs(v, types)); } catch (e) { rc = e; }
    let stl = null; try { stl = inst.FS.readFile("/out.stl"); } catch (e) {}
    const info = parseEcho(log);
    if (!stl || rc !== 0 || info.errors.length) throw new Error((info.errors.join("\n") || "OpenSCAD failed") + "\n" + log.slice(-8).join("\n"));
    const m = cleanStl(stl); lastMesh = m;
    const b = meshBounds(m);
    lastName = `HueForge_Frame_${v.panel_w}x${v.panel_h}_${v.part}`;
    showMesh(m, $("#viewback").checked ? "back" : "front");
    const inBay = info.bay && info.bay.includes("=true");
    const sepNote = v.part === "frame_with_stand" ? (inBay ? "Stand printed <b>in the lower bay</b> with breakaway tabs (one piece)." :
      "<b>Stand did not fit in the bay at this size</b> - it is placed <b>beside</b> the frame instead (two pieces on one plate).") : "";
    $("#info").innerHTML = `<div><b>Size:</b> ${b.size.map(x => x.toFixed(1)).join(" × ")} mm</div>` +
      (info.pocket ? `<div><b>Pocket:</b> ${info.pocket.replace("POCKET_MM=", "")}</div>` : "") +
      (sepNote ? `<div>${sepNote}</div>` : "") +
      (info.warnings.length ? `<div class="warn">${info.warnings.join("<br>")}</div>` : "") +
      `<div class="small">${m.idx.length / 3} triangles, rendered in ${((performance.now() - t0) / 1000).toFixed(1)} s</div>`;
    setStatus("Done - download below.", "ok");
    $("#dl_stl").disabled = $("#dl_3mf").disabled = false;
    window.__lastResult = { ok: true, triangles: m.idx.length / 3, size: b.size, inBay, warnings: info.warnings };
  } catch (e) {
    setStatus("Error: " + e.message, "err"); window.__lastResult = { ok: false, error: String(e.message) };
  } finally { btn.disabled = false; }
}
function setStatus(t, cls) { const s = $("#status"); s.textContent = t; s.className = cls || ""; }
function download(bytes, name, mime) {
  const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob([bytes], { type: mime })); a.download = name;
  document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
}
window.__hf = { generate, values, get stl() { return lastMesh && toBinaryStl(lastMesh); }, get threemf() { return lastMesh && to3mf(lastMesh, lastName); } };

window.addEventListener("DOMContentLoaded", async () => {
  buildForm(); initViewer();
  $("#gen").onclick = generate;
  $("#reset").onclick = resetForm;
  $("#dl_stl").onclick = () => lastMesh && download(toBinaryStl(lastMesh), lastName + ".stl", "model/stl");
  $("#dl_3mf").onclick = () => lastMesh && download(to3mf(lastMesh, lastName), lastName + ".3mf", "model/3mf");
  $("#dl_scad").onclick = () => download(new TextEncoder().encode(SCAD), "HueForge_Floating_Frame_Customizer.scad", "text/plain");
  $("#viewback").onchange = () => lastMesh && showMesh(lastMesh, $("#viewback").checked ? "back" : "front");
  setStatus("Loading the OpenSCAD engine…", "busy");
  try { await createOpenSCAD({ print: () => {}, printErr: () => {} }); setStatus("Ready.", "ok"); await generate(); }
  catch (e) { setStatus("Could not start OpenSCAD: " + e.message, "err"); }
});
