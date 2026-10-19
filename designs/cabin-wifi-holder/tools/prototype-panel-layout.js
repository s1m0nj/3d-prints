// PROTOTYPE (throwaway): renders front-panel layouts to scale (50 x 60 mm) as one HTML file.
const fs = require('fs'), path = require('path');
const { n, runs } = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'qr_runs.json')));
const W = 50, H = 60, S = 9, CAP = 0.72, INK = '#111';

const text = (t, size, x, baseline, anchor = 'middle') =>
  `<text x="${x}" y="${baseline}" font-size="${size}" font-weight="700" text-anchor="${anchor}" font-family="SF Pro Rounded, SF Pro Display, Helvetica Neue, Arial, sans-serif" fill="${INK}">${t}</text>`;

// Wi-Fi glyph: dot + 3 arcs (90 deg sweep), 1.0 mm strokes; (cx, cy) is the dot centre; height g measured to the outer arc top
function wifi(cx, cy, g) {
  const rs = [0.33, 0.66, 1].map(k => k * g), a = Math.PI / 4, out = [`<circle cx="${cx}" cy="${cy}" r="0.9" fill="${INK}"/>`];
  for (const r of rs) {
    const x1 = cx - r * Math.sin(a), y1 = cy - r * Math.cos(a), x2 = cx + r * Math.sin(a);
    out.push(`<path d="M${x1} ${y1} A${r} ${r} 0 0 1 ${x2} ${y1}" fill="none" stroke="${INK}" stroke-width="1" stroke-linecap="butt"/>`);
  }
  return out.join('');
}
function brackets(x, y, s, arm) { // four corner brackets around a square
  const w = 1, p = [];
  for (const [cx, cy, dx, dy] of [[x, y, 1, 1], [x + s, y, -1, 1], [x, y + s, 1, -1], [x + s, y + s, -1, -1]])
    p.push(`<path d="M${cx + dx * arm} ${cy} L${cx + dx * w * 0} ${cy} L${cx} ${cy + dy * arm}" fill="none" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round"/>`);
  return p.join('');
}
function qrAt(x0, y0, m) {
  return runs.map(([c, r, l]) => `<rect x="${x0 + c * m}" y="${y0 + r * m}" width="${l * m}" height="${m}" fill="${INK}"/>`).join('');
}

const variants = [
  { name: 'D  Viewfinder', notes: [], draw() {
    const m = 1.0, q = n * m, box = q + 8 * m, bx = (W - box) / 2, by = 4;
    const e = [brackets(bx, by, box, 6), qrAt((W - q) / 2, by + 4 * m, m)];
    // row: glyph + SSID, centred as a group
    const size = 6, cap = size * CAP, rowY = by + box + 3.2 + cap, tw = 8 * size * 0.56, gw = 8, gap = 2.2, start = (W - (gw + gap + tw)) / 2;
    e.push(wifi(start + gw / 2, rowY, 5.4), text('Si_Cabin', size, start + gw + gap + tw / 2, rowY));
    const sY = rowY + 2.6 + 3.3; e.push(text('Scan to connect', 4.6, W / 2, sY));
    this.notes = [`QR ${q} mm (module ${m}), viewfinder box ${box} mm, 4-module quiet zone inside it`, `bottom margin ${(H - sY).toFixed(1)} mm`, 'text stems: SSID ~0.9, "Scan to connect" ~0.7 mm (marginal)'];
    return e.join('');
  } },
  { name: 'E  Glyph minimal', notes: [], draw() {
    const m = 1.3, q = n * m, top = 4.5, e = [qrAt((W - q) / 2, top, m)];
    const size = 6, cap = size * CAP, rowY = top + q + 4.9 + cap, tw = 8 * size * 0.56, gw = 8, gap = 2.2, start = (W - (gw + gap + tw)) / 2;
    e.push(wifi(start + gw / 2, rowY, 5.4), text('Si_Cabin', size, start + gw + gap + tw / 2, rowY));
    this.notes = [`QR ${q.toFixed(1)} mm (module ${m}), side margin ${((W - q) / 2).toFixed(1)}`, `bottom margin ${(H - rowY).toFixed(1)} mm`, 'no "Scan to connect": the glyph says it'];
    return e.join('');
  } },
  { name: 'F  Glyph on top', notes: [], draw() {
    const m = 1.1, q = n * m, g = 5.4, gy = 4 + g, e = [wifi(W / 2, gy, g)];
    const qy = gy + 4.4; e.push(qrAt((W - q) / 2, qy, m));
    const size = 6, cap = size * CAP, rowY = qy + q + 4.4 + cap; e.push(text('Si_Cabin', size, W / 2, rowY));
    this.notes = [`QR ${q.toFixed(1)} mm (module ${m})`, `bottom margin ${(H - rowY).toFixed(1)} mm`, 'no "Scan to connect"'];
    return e.join('');
  } },
];

const card = v => { const body = v.draw(); return `<div class="v"><h3>${v.name}</h3><svg width="${W * S}" height="${H * S}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" rx="4" fill="#fafafa" stroke="#bbb" stroke-width=".2"/>${body}</svg><ul>${v.notes.map(x => `<li>${x}</li>`).join('')}</ul></div>`; };
const html = `<!doctype html><meta charset=utf-8><title>PROTOTYPE panel layouts</title>
<style>body{font:14px system-ui;margin:24px;background:#eee}.row{display:flex;gap:32px}.v{background:#fff;padding:16px;border-radius:8px}ul{font-size:12px;padding-left:16px;max-width:${W * S}px}</style>
<h2>PROTOTYPE (throwaway): front panel 50 x 60 mm, to scale</h2><p>Black = raised 1 mm. Stems under ~0.8 mm are marginal on a 0.4 mm nozzle.</p>
<div class=row>${variants.map(card).join('')}</div>`;
fs.writeFileSync(path.join(__dirname, '..', 'prototype-panel-layout.html'), html);
console.log('written');
