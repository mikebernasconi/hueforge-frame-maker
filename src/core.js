// Pure helpers (no DOM) - shared by the web app and the node test.
export function parseCustomizer(src) {
  const lines = src.split(/\r?\n/);
  const tabs = []; let tab = null, desc = [];
  for (const raw of lines) {
    const line = raw.trim();
    if (/^(module|function)\s/.test(line)) break;
    const t = line.match(/^\/\*\s*\[([^\]]+)\]\s*\*\/$/);
    if (t) { if (t[1].trim() === "Hidden") break; tab = { name: t[1].trim(), params: [] }; tabs.push(tab); desc = []; continue; }
    if (line.startsWith("//")) { desc.push(line.replace(/^\/\/\s?/, "")); continue; }
    const m = line.match(/^([A-Za-z_]\w*)\s*=\s*([^;]+);\s*(?:\/\/\s*(.*))?$/);
    if (m && tab) {
      const [, name, valRaw, specRaw] = m; const v = valRaw.trim();
      const p = { name, desc: desc.join(" "), tab: tab.name };
      if (v === "true" || v === "false") { p.type = "bool"; p.value = v === "true"; }
      else if (/^".*"$/.test(v)) { p.type = "string"; p.value = v.slice(1, -1); }
      else if (!isNaN(Number(v))) { p.type = "number"; p.value = Number(v); }
      else { desc = []; continue; }
      const spec = specRaw && specRaw.match(/^\[(.*)\]$/);
      if (spec) {
        const parts = spec[1].split(",").map(s => s.trim());
        if (parts.length === 1 && /^-?[\d.]+(:-?[\d.]+){1,2}$/.test(parts[0])) {
          const n = parts[0].split(":").map(Number);
          p.min = n[0]; p.max = n[n.length - 1]; p.step = n.length === 3 ? n[1] : 1; p.control = "slider";
        } else {
          p.control = "select";
          p.options = parts.map(s => { const i = s.indexOf(":"); return i < 0 ? { value: s, label: s } : { value: s.slice(0, i), label: s.slice(i + 1) }; });
        }
      }
      tab.params.push(p); desc = [];
    } else if (line === "") desc = [];
  }
  return tabs;
}

export function buildArgs(values, types, input = "/in.scad", output = "/out.stl") {
  const args = [input, "-o", output, "--backend=Manifold", "--export-format=binstl"];
  for (const [k, v] of Object.entries(values)) {
    const t = types[k];
    const lit = t === "string" ? JSON.stringify(String(v)) : t === "bool" ? (v ? "true" : "false") : String(Number(v));
    args.push("-D", `${k}=${lit}`);
  }
  return args;
}

// binary STL -> cleaned triangle soup (drops zero-area slivers) + indexed mesh
export function cleanStl(buf) {
  const dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  const n = dv.getUint32(80, true);
  const tris = []; let dropped = 0;
  for (let i = 0; i < n; i++) {
    const o = 84 + i * 50 + 12; const p = [];
    for (let k = 0; k < 9; k++) p.push(dv.getFloat32(o + 4 * k, true));
    const ux = p[3] - p[0], uy = p[4] - p[1], uz = p[5] - p[2], vx = p[6] - p[0], vy = p[7] - p[1], vz = p[8] - p[2];
    const cx = uy * vz - uz * vy, cy = uz * vx - ux * vz, cz = ux * vy - uy * vx;
    const a2 = Math.hypot(cx, cy, cz);
    if (a2 < 2e-9) { dropped++; continue; }
    tris.push(p);
  }
  const map = new Map(), verts = [], idx = [];
  for (const p of tris) for (let k = 0; k < 3; k++) {
    const key = `${p[3*k].toFixed(4)},${p[3*k+1].toFixed(4)},${p[3*k+2].toFixed(4)}`;
    let id = map.get(key); if (id === undefined) { id = verts.length / 3; map.set(key, id); verts.push(p[3*k], p[3*k+1], p[3*k+2]); }
    idx.push(id);
  }
  const fidx = [];      // drop triangles that collapsed after welding
  for (let i = 0; i < idx.length; i += 3) if (idx[i] !== idx[i+1] && idx[i+1] !== idx[i+2] && idx[i] !== idx[i+2]) fidx.push(idx[i], idx[i+1], idx[i+2]); else dropped++;
  return { verts: new Float32Array(verts), idx: new Uint32Array(fidx), dropped };
}

export function meshBounds(m) {
  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < m.verts.length; i++) { const a = i % 3; lo[a] = Math.min(lo[a], m.verts[i]); hi[a] = Math.max(hi[a], m.verts[i]); }
  return { lo, hi, size: hi.map((h, i) => h - lo[i]) };
}

export function toBinaryStl(m) {
  const nt = m.idx.length / 3, out = new ArrayBuffer(84 + nt * 50), dv = new DataView(out);
  const hdr = "HueForge Floating Frame - binary STL"; for (let i = 0; i < hdr.length; i++) dv.setUint8(i, hdr.charCodeAt(i));
  dv.setUint32(80, nt, true);
  for (let t = 0; t < nt; t++) {
    const o = 84 + t * 50, V = k => m.idx[3 * t + k] * 3;
    const a = V(0), b = V(1), c = V(2), P = m.verts;
    const ux = P[b] - P[a], uy = P[b+1] - P[a+1], uz = P[b+2] - P[a+2], vx = P[c] - P[a], vy = P[c+1] - P[a+1], vz = P[c+2] - P[a+2];
    let nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx; const l = Math.hypot(nx, ny, nz) || 1;
    dv.setFloat32(o, nx / l, true); dv.setFloat32(o + 4, ny / l, true); dv.setFloat32(o + 8, nz / l, true);
    [a, b, c].forEach((v, k) => { for (let j = 0; j < 3; j++) dv.setFloat32(o + 12 + 12 * k + 4 * j, P[v + j], true); });
  }
  return new Uint8Array(out);
}

// --- minimal 3MF (zip, stored) ---
const CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
function crc32(u8) { let c = 0xFFFFFFFF; for (let i = 0; i < u8.length; i++) c = CRC[(c ^ u8[i]) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
function zipStore(files) {
  const enc = new TextEncoder(), chunks = [], central = []; let off = 0;
  for (const [name, data0] of files) {
    const data = typeof data0 === "string" ? enc.encode(data0) : data0, nm = enc.encode(name), crc = crc32(data);
    const h = new DataView(new ArrayBuffer(30));
    h.setUint32(0, 0x04034b50, true); h.setUint16(4, 20, true); h.setUint16(8, 0, true); h.setUint16(10, 0, true); h.setUint16(12, 0x21, true);
    h.setUint32(14, crc, true); h.setUint32(18, data.length, true); h.setUint32(22, data.length, true); h.setUint16(26, nm.length, true);
    chunks.push(new Uint8Array(h.buffer), nm, data);
    const c = new DataView(new ArrayBuffer(46));
    c.setUint32(0, 0x02014b50, true); c.setUint16(4, 20, true); c.setUint16(6, 20, true); c.setUint16(14, 0x21, true);
    c.setUint32(16, crc, true); c.setUint32(20, data.length, true); c.setUint32(24, data.length, true); c.setUint16(28, nm.length, true); c.setUint32(42, off, true);
    central.push(new Uint8Array(c.buffer), nm);
    off += 30 + nm.length + data.length;
  }
  const csize = central.reduce((s, a) => s + a.length, 0), e = new DataView(new ArrayBuffer(22));
  e.setUint32(0, 0x06054b50, true); e.setUint16(8, files.length, true); e.setUint16(10, files.length, true); e.setUint32(12, csize, true); e.setUint32(16, off, true);
  const all = [...chunks, ...central, new Uint8Array(e.buffer)], out = new Uint8Array(all.reduce((s, a) => s + a.length, 0));
  let p = 0; for (const a of all) { out.set(a, p); p += a.length; } return out;
}
export function to3mf(m, name = "HueForge_Frame", bed = [325, 320]) {
  const b = meshBounds(m), tx = bed[0] / 2 - (b.lo[0] + b.hi[0]) / 2, ty = bed[1] / 2 - (b.lo[1] + b.hi[1]) / 2, tz = -b.lo[2];
  const vs = []; for (let i = 0; i < m.verts.length; i += 3) vs.push(`<vertex x="${m.verts[i].toFixed(4)}" y="${m.verts[i+1].toFixed(4)}" z="${m.verts[i+2].toFixed(4)}"/>`);
  const ts = []; for (let i = 0; i < m.idx.length; i += 3) ts.push(`<triangle v1="${m.idx[i]}" v2="${m.idx[i+1]}" v3="${m.idx[i+2]}"/>`);
  const model = `<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">` +
    `<metadata name="Title">${name}</metadata><metadata name="Designer">Michael Bernasconi</metadata>` +
    `<resources><object id="1" name="${name}" type="model"><mesh><vertices>${vs.join("")}</vertices><triangles>${ts.join("")}</triangles></mesh></object></resources>` +
    `<build><item objectid="1" transform="1 0 0 0 1 0 0 0 1 ${tx.toFixed(3)} ${ty.toFixed(3)} ${tz.toFixed(3)}"/></build></model>`;
  return zipStore([
    ["[Content_Types].xml", `<?xml version="1.0" encoding="UTF-8"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/></Types>`],
    ["_rels/.rels", `<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>`],
    ["3D/3dmodel.model", model]]);
}

export function parseEcho(log) {
  const get = k => { const l = log.find(s => s.includes(k)); return l ? l.replace(/^ECHO:\s*"?/, "").replace(/"$/, "") : null; };
  return { outer: get("FRAME_OUTER_MM="), pocket: get("POCKET_MM="), bay: get("STAND_IN_BAY="), balance: get("BALANCE:"),
           stand: get("STAND: "), warnings: log.filter(s => /WARNING|NOTE:/.test(s)).map(s => s.replace(/^ECHO:\s*"?/, "").replace(/"$/, "")),
           errors: log.filter(s => /^ERROR|Parser error/.test(s)) };
}
