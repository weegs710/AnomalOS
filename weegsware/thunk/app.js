const $ = s => document.querySelector(s);
const KEEPS = ["pose", "face", "body", "background", "palette", "lettering", "overall"];
const S = { name: null, proj: null, round: null, sel: null, b: null, mode: "grid", marking: false, tool: null,
  starts: [], autoStarts: new Set(), viewBg: "checker", iconset: null, queue: [], ready: false, rewriter: false, devices: {}, root: "", cmpMode: "side", flip: false,
  doneSeen: new Set(), fonts: [], text: null, swap: null, ssim: {}, lastProof: null };

async function api(method, path, body) {
  const r = await fetch(path, { method, headers: { "content-type": "application/json" }, body: body ? JSON.stringify(body) : undefined });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(j.error || `${r.status}`);
  return j;
}
const P = () => `/api/p/${encodeURIComponent(S.name)}`;
function toast(msg) { const t = $("#toast"); t.textContent = msg; t.hidden = false; clearTimeout(toast.t); toast.t = setTimeout(() => t.hidden = true, 3200); }
const fileUrl = rel => `/files/${encodeURIComponent(S.name)}/${rel}`;
const printById = id => S.proj?.prints.find(p => p.id === id);
const roundPrints = n => (S.proj?.prints || []).filter(p => p.round === n && p.kind === "gen").sort((a, b) => a.index - b.index);
const liveTasks = n => S.queue.filter(t => t.project === S.name && t.round === n && (t.kind === "gen" || t.kind === "fit") && (t.status === "queued" || t.status === "running"));
const roundOf = n => S.proj?.rounds.find(r => r.n === n);
function el(tag, attrs = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v; else if (k.startsWith("on")) e.addEventListener(k.slice(2), v);
    else if (v !== null && v !== undefined && v !== false) e.setAttribute(k, v === true ? "" : v);
  }
  for (const k of kids.flat()) if (k !== null && k !== undefined && k !== false) e.append(k.nodeType ? k : document.createTextNode(k));
  return e;
}
function label(p) {
  if (!p) return "";
  if (p.kind === "gen") return `R${p.round} print ${p.index}`;
  return `${p.tool || "edit"} (print ${p.id})`;
}

/* ---------- projects ---------- */
async function loadProjects() {
  const names = await api("GET", "/api/projects");
  $("#proj").replaceChildren(...names.map(n => el("option", { value: n }, n)));
  const want = localStorage.getItem("thunk.project");
  if (names.length) await openProject(names.includes(want) ? want : names[0]); else render();
}
async function openProject(name) {
  S.name = name; localStorage.setItem("thunk.project", name); $("#proj").value = name;
  S.proj = await api("GET", P());
  const last = S.proj.rounds.filter(r => (r.kind || "round") === "round").at(-1);
  const any = S.proj.rounds.at(-1);
  S.round = any ? any.n : null; S.sel = null; S.b = null; S.mode = "grid"; S.tool = null; S.marking = false;
  if (last) { $("#said").value = last.said || ""; $("#gets").value = last.prompt || ""; }
  S.starts = []; S.autoStarts.clear(); S.dropped = new Set();
  render(); syncAutoStarts();
}
async function reloadProject() { if (S.name) { S.proj = await api("GET", P()); render(); } }
$("#proj").addEventListener("change", e => openProject(e.target.value));
$("#newproj").addEventListener("click", () => { S.name = null; S.proj = null; render(true); });

/* ---------- render ---------- */
function render(asking = false) {
  renderRefs(); renderRounds(); renderStage(asking); renderInspect(); renderStart();
  $("#run").disabled = !S.name;
  $("#t-grid").setAttribute("aria-pressed", String(S.mode === "grid" && !S.tool));
  $("#t-view").setAttribute("aria-pressed", String(S.mode === "view" && !S.tool && !S.marking));
  $("#t-cmp").setAttribute("aria-pressed", String(S.mode === "cmp" && !S.tool));
  $("#t-mark").setAttribute("aria-pressed", String(S.marking && !S.tool));
  document.querySelectorAll(".tool").forEach(b => { b.setAttribute("aria-pressed", String(S.tool === b.dataset.tool)); b.disabled = !S.sel; });
  ["t-mark", "t-view", "t-cmp"].forEach(id => $(`#${id}`).disabled = !S.sel);
  $("#hint").textContent = hintText();
  const bgs = { checker: "", black: "#000000", white: "#ffffff", grey: "#808080" };
  $("#behind").replaceChildren("Behind:", ...Object.entries(bgs).map(([k, v]) => el("button", { type: "button", title: k, "aria-pressed": String(S.viewBg === k),
    style: v ? `background:${v}` : "", class: v ? "" : "checker", onclick: () => { S.viewBg = k; render(); } })));
  document.querySelectorAll(".single, .pic.checker").forEach(e => { if (bgs[S.viewBg]) { e.style.background = bgs[S.viewBg]; } else e.style.background = ""; });
}
function hintText() {
  if (S.tool === "text") return "Click the picture to place the text";
  if (S.tool === "swap") return "Drag a circle on the left, click where it goes on the right";
  if (S.tool === "fix" || S.marking) return "Drag a circle over each spot";
  if (S.mode === "view") return "Scroll zooms, drag pans, 0 is 1:1, Esc goes back";
  if (S.mode === "cmp") return "Shift-click sets B, F flips";
  return "1 to 9 picks a print, Enter looks closer, shift-click compares";
}

function renderRefs() {
  const box = $("#refs"); box.replaceChildren();
  for (const r of S.proj?.refs || []) {
    const src = `ref:${r}`;
    box.append(el("button", { type: "button", class: S.starts.includes(src) ? "sel" : "", title: `${r}: click to start from it`,
      onclick: () => toggleStart(src) }, el("img", { src: fileUrl(`refs/${encodeURIComponent(r)}`), alt: r })));
  }
}

function renderRounds() {
  const ol = $("#rounds"); ol.replaceChildren();
  for (const r of [...(S.proj?.rounds || [])].reverse()) {
    const ps = roundPrints(r.n), live = liveTasks(r.n).length;
    const kind = r.kind && r.kind !== "round" ? `${r.kind}, ` : "";
    const sub = live ? `${kind}running, ${ps.length} of ${ps.length + live} done` :
      `${kind}${ps.length} print${ps.length === 1 ? "" : "s"}` + (r.start && !r.kind?.startsWith("fit") ? `, from ${startLabel(r.start)}` : "");
    ol.append(el("li", {}, el("button", { type: "button", class: r.n === S.round ? "cur" : "",
      onclick: () => { S.round = r.n; S.sel = null; S.b = null; S.mode = "grid"; S.tool = null; S.marking = false; S.iconset = null; render(); syncAutoStarts(); } },
      el("span", { class: "rn" }, `R${r.n}`),
      el("span", {}, el("span", { class: "th" }, ps.slice(0, 5).map(p => el("img", { src: fileUrl(p.file), alt: "" }))),
        el("span", { class: "sub" }, sub)))));
  }
}
function startLabel(src) {
  if (!src) return ""; const [k, v] = src.split(/:(.*)/);
  if (k === "ref") return `reference ${v}`;
  return label(printById(+v)) || `print ${v}`;
}
function startUrl(src) { const [k, v] = src.split(/:(.*)/); return k === "ref" ? fileUrl(`refs/${encodeURIComponent(v)}`) : fileUrl(printById(+v)?.file || ""); }

function tileOf(item, i) {
  const isPrint = !!item.file;
  const pic = el("div", { class: "pic" + (isPrint && item.id === S.sel ? " sel" : "") + (isPrint && item.id === S.b ? " bsel" : "") });
  const fit = el("div", { class: "fit" }, el("span", { class: "num" }, String(i + 1)));
  if (isPrint) pic.append(el("img", { src: fileUrl(item.file), alt: `Print ${i + 1}`, onload: fitAll }), fit);
  else if (item.preview) pic.append(el("img", { class: "developing", src: `data:image/png;base64,${item.preview}`, alt: "", onload: fitAll }), fit,
    el("div", { class: "prog" }, el("i", { style: `width:${item.total ? 100 * item.step / item.total : 0}%` })));
  else pic.append(el("div", { class: "waiting" }, item.kind === "fit" ? "building the starting image" : item.status === "running" ? "starting" : "waiting"), fit);
  const cap = el("figcaption");
  if (isPrint) {
    if (item.strength) cap.append(el("span", { class: "tag" }, `strength ${item.strength}`));
    if (S.ssim[item.id] !== undefined) cap.append(el("span", { class: "tag" }, `${S.ssim[item.id]} like the original`));
    for (const k of item.keeps || []) cap.append(el("span", { class: "tag" }, k));
    if (item.marks?.length) cap.append(el("span", { class: "tag bad" }, `${item.marks.length} spot${item.marks.length > 1 ? "s" : ""} marked`));
    if (item.note) cap.append(el("span", { class: "tag" }, "note"));
    const kids = S.proj.prints.filter(q => q.from === item.id && q.kind !== "guide").length;
    if (kids) cap.append(el("span", { class: "tag" }, `${kids} made from it`));
  }
  return el("figure", { class: "tile", onclick: e => isPrint && pick(item.id, e.shiftKey),
    ondblclick: () => isPrint && (S.sel = item.id, S.mode = "view", render()) }, pic, cap);
}

function renderStage(asking) {
  const c = $("#canvas");
  if (!S.name) {
    const inp = el("input", { placeholder: "fox sticker, phone wallpaper, ...", "aria-label": "Project name" });
    c.replaceChildren(el("div", { class: "empty" }, el("div", {},
      el("h3", {}, asking || !$("#proj").options.length ? "Name a new project" : "Pick a project"),
      el("div", {}, "Every print lands in ~/Pictures/thunk/<name>/ with its prompt and seed next to it."),
      el("form", { onsubmit: async e => { e.preventDefault(); try { const n = inp.value.trim(); await api("POST", "/api/projects", { name: n });
        await loadProjects(); await openProject(n); } catch (er) { toast(er.message); } } },
        inp, el("button", { class: "btn primary", type: "submit" }, "Make project")))));
    setTimeout(() => inp.focus());
    return;
  }
  if (S.iconset) return renderIconset(c);
  if (S.tool === "swap" && printById(S.sel)) return renderSwap(c);
  if ((S.mode === "view" || S.tool) && printById(S.sel)) return renderSingle(c);
  if (S.mode === "cmp" && printById(S.sel)) return renderCompare(c);
  S.mode = "grid";
  if (S.round == null) {
    c.replaceChildren(el("div", { class: "empty" }, el("div", {}, el("h3", {}, "No rounds yet"),
      el("div", {}, "Write what you want on the right and run a round. Prints show up here, numbered, as they finish."))));
    return;
  }
  const items = [...roundPrints(S.round), ...liveTasks(S.round)].sort((a, b) => (a.index || 0) - (b.index || 0));
  const n = items.length || 1, cols = n <= 1 ? 1 : n <= 4 ? 2 : n <= 6 ? 3 : 4, rows = Math.ceil(n / cols);
  if (!items.length) { c.replaceChildren(el("div", { class: "empty" }, el("div", {}, el("h3", {}, "Nothing in this round"), el("div", {}, "It was stopped before any print finished.")))); return; }
  c.replaceChildren(el("div", { class: "grid", style: `grid-template-columns:repeat(${cols},minmax(0,1fr));grid-template-rows:repeat(${rows},minmax(0,1fr))` },
    items.map((it, i) => tileOf(it, i))));
  requestAnimationFrame(fitAll);
  const r = roundOf(S.round);
  if (r?.kind?.startsWith("fit") && r.from) loadFitScores(r);
}
async function loadFitScores(r) {
  for (const p of roundPrints(r.n)) if (S.ssim[p.id] === undefined) {
    S.ssim[p.id] = null;
    try { S.ssim[p.id] = (await api("POST", `${P()}/similar`, { a: r.from, b: p.id })).ssim; renderStage(); } catch { }
  }
}

function fitAll() {
  document.querySelectorAll(".pic").forEach(pic => {
    const img = pic.querySelector("img"), box = pic.querySelector(".fit");
    if (!box) return;
    if (!img || !img.naturalWidth) { Object.assign(box.style, { left: 0, top: 0, width: "100%", height: "100%" }); return; }
    const W = pic.clientWidth, H = pic.clientHeight, s = Math.min(W / img.naturalWidth, H / img.naturalHeight);
    const w = img.naturalWidth * s, h = img.naturalHeight * s;
    Object.assign(box.style, { left: (W - w) / 2 + "px", top: (H - h) / 2 + "px", width: w + "px", height: h + "px" });
  });
}
new ResizeObserver(() => { fitAll(); document.querySelectorAll(".single").forEach(v => v.refit?.()); }).observe(document.body);

function pick(id, asB = false) {
  if (asB && S.sel && id !== S.sel) { S.b = id; if (S.tool !== "swap") S.mode = "cmp"; }
  else { S.sel = id; if (S.b === id) S.b = null; }
  render();
}

/* ---------- a zoomable view of one print, with overlays ---------- */
function viewer(p, opts = {}) {
  const V = { z: 1, x: 0, y: 0, fitZ: 1 };
  const img = el("img", { src: fileUrl(p.file), alt: "", draggable: "false" });
  const layer = el("div", { class: "layer" }, img);
  const box = el("div", { class: "single" + (opts.crosshair ? " marking" : "") }, layer);
  const toImg = e => { const r = box.getBoundingClientRect(); return { px: (e.clientX - r.left - V.x) / V.z, py: (e.clientY - r.top - V.y) / V.z }; };
  const apply = () => { layer.style.transform = `translate(${V.x}px,${V.y}px) scale(${V.z})`; overlay(); };
  const overlay = () => { box.querySelectorAll(".ov").forEach(m => m.remove()); opts.overlay?.(box, V, img);
    const l = opts.live; if (l && img.naturalWidth) circleAt(box, V, img, { x: l.px / img.naturalWidth, y: l.py / img.naturalHeight, r: l.r / img.naturalWidth }); };
  box.refit = (reset) => { if (!img.naturalWidth) return; const W = box.clientWidth, H = box.clientHeight;
    V.fitZ = Math.min(W / img.naturalWidth, H / img.naturalHeight);
    if (reset || !box.didFit) { V.z = V.fitZ; V.x = (W - img.naturalWidth * V.z) / 2; V.y = (H - img.naturalHeight * V.z) / 2; box.didFit = true; }
    apply(); };
  box.oneToOne = () => { V.z = 1; V.x = (box.clientWidth - img.naturalWidth) / 2; V.y = (box.clientHeight - img.naturalHeight) / 2; apply(); };
  box.redraw = overlay;
  img.onload = () => box.refit(true);
  box.addEventListener("wheel", e => { e.preventDefault(); const r = box.getBoundingClientRect();
    const mx = e.clientX - r.left, my = e.clientY - r.top, f = e.deltaY < 0 ? 1.2 : 1 / 1.2, nz = Math.max(V.fitZ / 2, Math.min(8, V.z * f));
    V.x = mx - (mx - V.x) * nz / V.z; V.y = my - (my - V.y) * nz / V.z; V.z = nz; apply(); }, { passive: false });
  let drag = null;
  box.addEventListener("pointerdown", e => {
    if (e.target.closest("button")) return;
    box.setPointerCapture(e.pointerId);
    const q = toImg(e);
    if (opts.circle) drag = { circle: true, px: q.px, py: q.py, r: 0, moved: false };
    else drag = { sx: e.clientX, sy: e.clientY, x: V.x, y: V.y, moved: false, q };
  });
  box.addEventListener("pointermove", e => {
    if (!drag) return;
    if (drag.circle) { const q = toImg(e); drag.r = Math.hypot(q.px - drag.px, q.py - drag.py); drag.moved = true; opts.live = drag; overlay(); }
    else { if (Math.abs(e.clientX - drag.sx) + Math.abs(e.clientY - drag.sy) > 4) drag.moved = true;
      if (drag.moved) { V.x = drag.x + e.clientX - drag.sx; V.y = drag.y + e.clientY - drag.sy; apply(); } }
  });
  box.addEventListener("pointerup", () => {
    const d = drag; drag = null; opts.live = null;
    if (!d) return;
    const iw = img.naturalWidth, ih = img.naturalHeight;
    if (d.circle) opts.circle({ x: d.px / iw, y: d.py / ih, r: Math.max(d.r, 10 / V.z) / iw });
    else if (!d.moved && opts.click) opts.click({ x: d.q.px / iw, y: d.q.py / ih });
    overlay();
  });
  box.V = V; box.img = img;
  return box;
}
function circleAt(box, V, img, m, cls = "markc") {
  const iw = img.naturalWidth || 1, ih = img.naturalHeight || 1;
  const cx = V.x + m.x * iw * V.z, cy = V.y + m.y * ih * V.z, rr = Math.max(5, m.r * iw * V.z);
  box.append(el("span", { class: `ov ${cls}`, style: `left:${cx - rr}px;top:${cy - rr}px;width:${2 * rr}px;height:${2 * rr}px` }));
  return { cx, cy, rr };
}

function renderSingle(c) {
  const p = printById(S.sel);
  const marking = S.marking || S.tool === "fix";
  const box = viewer(p, {
    crosshair: marking || S.tool === "text",
    circle: marking ? async m => {
      const note = S.tool === "fix" ? "" : (prompt("What's wrong here?", "") ?? null);
      if (note === null) return;
      await savePrint(p.id, { marks: [...(p.marks || []), { ...m, note }] }); render();
    } : null,
    click: S.tool === "text" ? q => { S.text.x = q.x; S.text.y = q.y; box.redraw(); } : null,
    overlay: (b, V, img) => {
      const iw = img.naturalWidth || 1, ih = img.naturalHeight || 1;
      (p.marks || []).forEach((m, i) => {
        const { cx, cy, rr } = circleAt(b, V, img, m);
        b.append(el("span", { class: "ov markn", style: `left:${cx + rr + 6}px;top:${cy - 12}px` }, m.note || `spot ${i + 1}`,
          el("button", { type: "button", title: "Remove this mark", onclick: async () => {
            await savePrint(p.id, { marks: p.marks.filter((_, j) => j !== i) }); render(); } }, "x")));
      });
      if (S.tool === "text" && S.text && S.text.text) {
        const t = S.text, fs = t.size * ih * V.z;
        b.append(el("div", { class: "ov textprev", style: `left:${V.x + t.x * iw * V.z}px;top:${V.y + t.y * ih * V.z}px;` +
          `font-family:"${t.family}";font-size:${fs}px;color:${t.color};` +
          `-webkit-text-stroke:${t.outline_w * fs * 2}px ${t.outline};paint-order:stroke fill;` +
          (t.glow > 0 ? `text-shadow:0 0 ${t.glow * fs}px ${t.glow_color},0 0 ${t.glow * fs * 2}px ${t.glow_color};` : "") }, t.text));
      }
    },
  });
  c.replaceChildren(box);
  requestAnimationFrame(() => box.refit(true));
}

/* ---------- swap: donor on the left, base on the right ---------- */
function renderSwap(c) {
  const a = printById(S.sel), b = printById(S.b);
  if (!b) {
    c.replaceChildren(el("div", { class: "empty" }, el("div", {}, el("h3", {}, "Pick the print to take from"),
      el("div", {}, `The one you're fixing is ${label(a)}. Go back to the round (Esc), shift-click the print that has the part you want, then press Swap element again.`))));
    return;
  }
  S.swap ||= { src: null, dst: null };
  const donor = viewer(b, { crosshair: true, circle: m => { S.swap.src = m; donor.redraw(); base.redraw(); renderInspect(); },
    overlay: (bx, V, img) => { if (S.swap.src) circleAt(bx, V, img, S.swap.src, "markc"); } });
  const base = viewer(a, { crosshair: true, click: q => { S.swap.dst = q; base.redraw(); renderInspect(); },
    overlay: (bx, V, img) => { if (S.swap.src && S.swap.dst) circleAt(bx, V, img, { ...S.swap.dst, r: S.swap.src.r * (b.width / a.width) }, "markc ghost"); } });
  const col = (t, v) => el("div", { class: "cmp-side" }, el("div", { class: "lbl" }, t), v);
  c.replaceChildren(el("div", { class: "swapgrid" },
    col(el("span", {}, "Take from ", el("b", {}, label(b)), ": drag a circle over the part"), donor),
    col(el("span", {}, "Put on ", el("b", {}, label(a)), ": click where it goes"), base)));
  requestAnimationFrame(() => { donor.refit(true); base.refit(true); });
}

/* ---------- icon set ---------- */
function renderIconset(c) {
  const set = S.iconset, pngs = set.files.filter(f => f.endsWith(".png"));
  const row = bg => el("div", { class: "iconrow" + (bg ? "" : " checker"), style: bg ? `background:${bg}` : "" },
    pngs.map(f => { const n = +f.match(/icon-(\d+)/)[1]; return el("figure", {}, el("img", { src: fileUrl(f), width: Math.min(n, 256), height: Math.min(n, 256), alt: "" }),
      el("figcaption", { style: `color:${({ "#000000": "#cccccc", "#808080": "#111111", "#ffffff": "#333333" })[bg] || "var(--muted)"}` }, n > 256 ? `${n} (shown at 256)` : `${n}`)); }));
  c.replaceChildren(el("div", { class: "iconset" },
    el("div", { class: "cmp-head" }, el("span", {}, "Icon set in ", el("b", {}, set.dir), `: ${set.files.length} files plus ${set.zip.split("/").pop()}. Each size at its real pixels, on black, grey, white and see-through.`),
      el("button", { class: "btn", type: "button", onclick: () => { navigator.clipboard?.writeText(set.dir); toast("Folder path copied"); } }, "Copy folder path"),
      el("button", { class: "link", type: "button", onclick: () => { S.iconset = null; render(); } }, "Close")),
    !set.transparent ? el("div", { class: "err" }, "This print has no see-through background, so the icons have its background baked in. Use Cut out first, then make the set from the cut-out print.") : null,
    row("#000000"), row("#808080"), row("#ffffff"), row("")));
}

/* ---------- compare ---------- */
function renderCompare(c) {
  const a = printById(S.sel), b = printById(S.b);
  const key = b ? `${a.id}-${b.id}` : null;
  if (key && S.ssim[key] === undefined) { S.ssim[key] = null; api("POST", `${P()}/similar`, { a: a.id, b: b.id }).then(r => { S.ssim[key] = r.ssim; renderStage(); }).catch(() => { }); }
  const head = el("div", { class: "cmp-head" },
    el("div", { class: "seg", role: "group" }, ["side", "flip", "slider"].map(m => el("button", { type: "button", "aria-pressed": String(S.cmpMode === m),
      onclick: () => { S.cmpMode = m; render(); } }, { side: "Side by side", flip: "Flip", slider: "Slider" }[m]))),
    b ? el("span", {}, `A is ${label(a)}, B is ${label(b)}. How alike: `, el("b", {}, S.ssim[key] ?? "measuring"),
      " (1 is identical; a redraw of the same picture scores about 0.9, an unrelated picture about 0.2)") : "Shift-click another print, in any round, to set B.");
  let body;
  const side = (tag, p) => el("div", { class: "cmp-side" }, el("div", { class: "lbl" }, `${tag} `, el("b", {}, p ? label(p) : "none yet")),
    el("div", { class: "pic checker" }, p ? el("img", { src: fileUrl(p.file), alt: "" }) : el("div", { class: "waiting" }, "shift-click a print")));
  if (S.cmpMode === "side" || !b) body = el("div", { class: "cmp-body", style: "grid-template-columns:1fr 1fr" }, side("A", a), side("B", b));
  else if (S.cmpMode === "flip") body = el("div", { class: "cmp-body" }, side(S.flip ? "B" : "A", S.flip ? b : a));
  else {
    const top = el("img", { src: fileUrl(b.file), alt: "", style: "clip-path:inset(0 0 0 50%)" });
    const bar = el("span", { class: "bar", style: "left:50%" });
    const wrap = el("div", { class: "slider-wrap" }, el("img", { src: fileUrl(a.file), alt: "" }), top, bar);
    const move = e => { const r = wrap.getBoundingClientRect(); const f = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width));
      top.style.clipPath = `inset(0 0 0 ${f * 100}%)`; bar.style.left = `${f * 100}%`; };
    wrap.addEventListener("pointermove", e => e.buttons && move(e)); wrap.addEventListener("pointerdown", move);
    body = el("div", { class: "cmp-body" }, el("div", { class: "cmp-side" }, el("div", { class: "lbl" }, "A left of the line, B right of it. Drag."), wrap));
  }
  c.replaceChildren(el("div", { class: "compare" }, head, body));
}

/* ---------- inspector and tool panels ---------- */
async function savePrint(id, patch) {
  const rec = await api("POST", `${P()}/print/${id}`, patch);
  const i = S.proj.prints.findIndex(p => p.id === id); if (i >= 0) S.proj.prints[i] = rec; syncAutoStarts(); return rec;
}
async function useResult(r, msg) {
  await reloadProject();
  if (r.print) { S.sel = r.print.id; S.mode = "view"; S.tool = null; S.marking = false; }
  render(); if (msg) toast(msg);
}
function facts(p) {
  return el("div", { class: "facts" },
    "Print", el("b", {}, label(p)), "Seed", el("b", {}, String(p.seed ?? "")),
    "Size", el("b", {}, `${p.width} x ${p.height}`), "Start", el("b", {}, p.start ? `${startLabel(p.start)} at ${p.strength}` : p.from ? `from print ${p.from}` : "words only"),
    "Took", el("b", {}, p.seconds ? `${p.seconds} s` : ""));
}
function renderInspect() {
  const box = $("#inspect"), p = printById(S.sel);
  if (!p) { box.replaceChildren(el("div", { class: "dim", style: "grid-column:1/-1" },
    S.name ? "Pick a print (click or 1 to 9) to keep parts of it, leave a note, start the next round from it, or edit it with the tools above." : "")); return; }
  if (S.tool) return box.replaceChildren(facts(p), toolPanel(p), el("div", { class: "acts" },
    el("button", { class: "btn", type: "button", onclick: () => { S.tool = null; S.marking = false; S.mode = "view"; render(); } }, "Done with this tool")));
  const chips = el("div", { class: "keeps", role: "group", "aria-label": "Keep from this print" },
    KEEPS.map(k => el("button", { class: "chip", type: "button", "aria-pressed": String((p.keeps || []).includes(k)),
      onclick: async () => { const ks = new Set(p.keeps || []); ks.has(k) ? ks.delete(k) : ks.add(k); await savePrint(p.id, { keeps: [...ks] }); render(); } },
      k === "overall" ? "Best overall" : `Keep the ${k}`)));
  const note = el("textarea", { class: "note", rows: "1", placeholder: "Note on this print", "aria-label": "Note on this print",
    onchange: async e => { await savePrint(p.id, { note: e.target.value }); renderRounds(); } });
  note.value = p.note || "";
  const kids = S.proj.prints.filter(q => q.from === p.id && q.kind !== "guide");
  const made = kids.length ? el("div", { class: "row", style: "justify-content:flex-start;margin-top:6px;font-size:13px;flex-wrap:wrap" }, "Made from it:",
    kids.map(q => el("button", { class: "link", type: "button", onclick: () => { S.sel = q.id; S.mode = "view"; render(); } }, q.tool || `print ${q.id}`))) : null;
  const back = p.from ? el("div", { class: "row", style: "justify-content:flex-start;margin-top:6px;font-size:13px" }, `${p.tool || "made"} from`,
    el("button", { class: "link", type: "button", onclick: () => { S.sel = p.from; render(); } }, label(printById(p.from)))) : null;
  const proof = p.proof ? el("div", { class: "say", style: "margin-top:6px;font-size:13px;color:var(--muted)" },
    `Changed ${p.proof.changed_px.toLocaleString()} px (${p.proof.percent}%) in ${p.proof.regions} region${p.proof.regions === 1 ? "" : "s"}, ${p.proof.outside_px} px outside the circle.`) : null;
  const finishFor = p.device ? el("button", { class: "btn primary", type: "button", onclick: async () => {
    await api("POST", `${P()}/tool`, { tool: "finish", print: p.id, device: p.device }); toast(`Finishing for ${p.device}, it lands in finals`); } }, `Finish for ${p.device}`) : null;
  const acts = el("div", { class: "acts" },
    finishFor,
    el("button", { class: "btn", type: "button", onclick: () => toggleStart(`print:${p.id}`) }, S.starts.includes(`print:${p.id}`) ? "Don't start from this" : "Start from this"),
    el("button", { class: "btn", type: "button", onclick: () => { $("#gets").value = p.prompt || ""; toast("Its prompt is in the box"); } }, "Use its prompt"),
    el("button", { class: "btn", type: "button", onclick: () => { $("#seed").value = p.seed; $("#count").value = 1; toast(`Seed ${p.seed} set, 1 print`); } }, "Same seed"),
    el("button", { class: "btn", type: "button", onclick: async () => { await api("POST", `${P()}/tool`, { tool: "upscale", print: p.id }); toast("Upscale queued, 4x"); } }, "Upscale 4x"),
    el("button", { class: "btn", type: "button", onclick: async () => { const r = await api("POST", `${P()}/final`, { print: p.id }); toast(`Copied to ${r.final}`); } }, "This is the one"),
    el("button", { class: "btn", type: "button", onclick: () => { navigator.clipboard?.writeText(`${S.root}/${S.name}/${p.file}`); toast(`${S.root}/${S.name}/${p.file} copied`); } }, "Copy file path"));
  box.replaceChildren(facts(p), el("div", {}, chips, note, made, back, proof, el("div", { class: "ptxt", title: p.prompt }, p.prompt || "")), acts);
}

function toolPanel(p) {
  const run = async (body, msg) => { try { const r = await api("POST", `${P()}/tool`, { print: p.id, ...body }); await useResult(r, msg); return r; } catch (e) { toast(e.message); } };
  if (S.tool === "cutout") {
    const tol = el("input", { type: "range", min: "4", max: "60", value: "18", class: "slider", style: "width:160px" });
    const tv = el("b", {}, "18"); tol.oninput = () => tv.textContent = tol.value;
    const clear = el("input", { type: "checkbox" });
    const glow = el("input", { type: "range", min: "0", max: "1", step: "0.05", value: "1", class: "slider", style: "width:160px" });
    const gv = el("b", {}, "1"); glow.oninput = () => gv.textContent = glow.value;
    return el("div", { class: "panel" },
      el("div", { class: "say" }, el("b", {}, "Dark background"), ": for glowing art on black or a dark gradient. The background goes and the glow stays as see-through light. Turn glow down for a hard solid edge, so it also looks right on light backgrounds. Check the result with Behind: above."),
      el("div", { class: "row" }, el("label", {}, "Glow", glow, gv),
        el("button", { class: "btn primary", type: "button", onclick: () => run({ tool: "cutout", method: "dark", glow: +glow.value }, "Cut out, saved as a new print") }, "Cut out the dark background")),
      el("div", { class: "say" }, el("b", {}, "Flat background"), ": for a subject on one plain colour. It removes what touches the corners."),
      el("div", { class: "row" }, el("label", {}, "Tolerance", tol, tv), el("label", {}, clear, `Also clear the ${p.marks?.length || 0} marked spot${p.marks?.length === 1 ? "" : "s"}`),
        el("button", { class: "btn", type: "button", onclick: () => run({ tool: "cutout", tolerance: +tol.value, clear_marks: clear.checked }, "Cut out, saved as a new print") }, "Cut out the flat background")));
  }
  if (S.tool === "icons") {
    const sizes = el("input", { type: "text", value: "16, 32, 48, 64, 128, 256, 512", style: "width:220px" });
    const pad = el("input", { type: "number", min: "0", max: "30", value: "4", style: "width:60px" });
    return el("div", { class: "panel" },
      el("div", { class: "say" }, "Trims to what's visible, squares it, and saves every size as a png, plus an .ico (16 to 256) and a zip, in this project's finals. Use a cut-out print so the background is see-through."),
      el("div", { class: "row" }, el("label", {}, "Sizes", sizes), el("label", {}, "Padding %", pad),
        el("button", { class: "btn primary", type: "button", onclick: async () => {
          try { const r = await api("POST", `${P()}/tool`, { tool: "icons", print: p.id, sizes: sizes.value.split(/[ ,]+/).filter(Boolean).map(Number), pad: +pad.value / 100 });
            S.iconset = r.icons; S.tool = null; render(); } catch (e) { toast(e.message); } } }, "Make the icon set")));
  }
  if (S.tool === "fix") {
    const st = el("input", { type: "number", min: "0.3", max: "1", step: "0.05", value: "0.9" });
    const n = el("input", { type: "number", min: "1", max: "6", value: "2" });
    return el("div", { class: "panel" },
      el("div", { class: "say" }, `Drag a circle over each spot on the picture. `, el("b", {}, `${p.marks?.length || 0} marked`), ". Fill uses only the pixels around it, so it never invents anything. Redraw lets the model repaint just those circles."),
      el("div", { class: "row" },
        el("button", { class: "btn primary", type: "button", disabled: !p.marks?.length, onclick: () => run({ tool: "fill" }, "Filled, saved as a new print") }, "Fill from around it"),
        el("label", {}, "or redraw with the model,", n, "tries at strength", st),
        el("button", { class: "btn", type: "button", disabled: !p.marks?.length, onclick: async () => {
          const r = await run({ tool: "redraw", strength: +st.value, count: +n.value }); if (r?.round) { S.round = r.round; S.mode = "grid"; S.tool = null; render(); toast("Redrawing the spots, they show up as a round"); } } }, "Redraw the spots"),
        el("button", { class: "link", type: "button", disabled: !p.marks?.length, onclick: async () => { await savePrint(p.id, { marks: [] }); render(); } }, "Clear marks")));
  }
  if (S.tool === "swap") {
    const sw = S.swap || {};
    const ready = sw.src && sw.dst && S.b;
    return el("div", { class: "panel" },
      el("div", { class: "say" }, S.b ? (sw.src ? (sw.dst ? "Ready. Only the circle changes on the base, the rest stays pixel for pixel." : "Now click where it goes on the right.") : "Drag a circle over the part you want on the left.") : "Shift-click a second print in the round first: that's the one you take from."),
      el("div", { class: "row" },
        el("button", { class: "btn primary", type: "button", disabled: !ready, onclick: async () => {
          const r = await run({ tool: "swap", donor: S.b, src: sw.src, dst: sw.dst });
          if (r?.proof) { S.swap = null; toast(`Swapped: ${r.proof.changed_px.toLocaleString()} px changed, ${r.proof.outside_px} outside the circle`); } } }, "Swap it in"),
        el("button", { class: "link", type: "button", onclick: () => { S.swap = null; render(); } }, "Start over")));
  }
  if (S.tool === "text") {
    S.text ||= { text: "", family: S.fonts[0]?.family || "", size: 0.08, color: "#ffffff", outline: "#000000", outline_w: 0.04, glow: 0, glow_color: "#ffffff", x: 0.5, y: 0.15 };
    const t = S.text, upd = () => document.querySelector(".single")?.redraw();
    const inp = (attrs, key, conv = v => v) => { const i = el("input", attrs); i.value = t[key]; i.oninput = () => { t[key] = conv(i.value); upd(); }; return i; };
    const txt = el("textarea", { rows: "2", placeholder: "The words, exactly" }); txt.value = t.text; txt.oninput = () => { t.text = txt.value; upd(); };
    const font = el("select", {}, S.fonts.map(f => el("option", { value: f.family }, f.family))); font.value = t.family; font.onchange = () => { t.family = font.value; upd(); };
    return el("div", { class: "panel" }, txt,
      el("div", { class: "row" }, el("label", {}, "Font", font), el("label", {}, "Size", inp({ type: "range", min: "0.02", max: "0.3", step: "0.005" }, "size", Number)),
        el("label", {}, "Colour", inp({ type: "color" }, "color")),
        el("label", {}, "Outline", inp({ type: "color" }, "outline"), inp({ type: "range", min: "0", max: "0.15", step: "0.005" }, "outline_w", Number)),
        el("label", {}, "Glow", inp({ type: "color" }, "glow_color"), inp({ type: "range", min: "0", max: "0.5", step: "0.01" }, "glow", Number)),
        el("button", { class: "btn primary", type: "button", onclick: () => {
          const f = S.fonts.find(x => x.family === t.family); if (!t.text.trim()) return toast("Type the words first");
          run({ tool: "text", ...t, font: f.file }, "Text burned in, saved as a new print"); } }, "Put it on")),
      el("div", { class: "say" }, "Click the picture to move it. The preview is the browser drawing the same font; the saved print is drawn by the server, so check it after."));
  }
  if (S.tool === "fit") {
    const devs = Object.keys(S.devices);
    const dev = el("select", {}, devs.map(d => el("option", { value: d }, `${d}, ${S.devices[d][0]} x ${S.devices[d][1]}`)));
    const st = el("input", { type: "text", value: "0.65, 0.75", style: "width:140px" });
    const edge = el("textarea", { rows: "2", placeholder: "What fills the new space above, below and beside it (the ceiling, the rest of the window, the floor...). Only the surroundings, not the subject, or the model draws the subject twice. Leave empty if it sits on a plain background." });
    return el("div", { class: "panel" },
      el("div", { class: "say" }, "Redraws the whole picture at the device's shape, one pass per strength, with this print's own words and seed, so it comes out one picture, not a patch job. Each result shows how alike it is to this print where they overlap (as a guide: a picture's own pixels after one model round trip score about 0.9, an unrelated picture about 0.2, and a good refit around 0.3 to 0.5). Pick one and press Finish for the exact size, no bars, nothing squashed."),
      edge,
      el("div", { class: "row" }, el("label", {}, "Device", dev), el("label", {}, "Strengths", st),
        el("button", { class: "btn primary", type: "button", onclick: async () => {
          const strengths = st.value.split(/[ ,]+/).filter(Boolean).map(Number);
          const r = await run({ tool: "fit", device: dev.value, strengths, edge_prompt: edge.value });
          if (r?.round) { S.round = r.round; S.sel = null; S.mode = "grid"; S.tool = null; render(); toast(`Fitting to ${dev.value}, ${strengths.length} tries`); } } }, "Fit it")));
  }
  return el("div");
}
document.querySelectorAll(".tool").forEach(b => b.addEventListener("click", () => {
  const t = b.dataset.tool;
  if (S.tool === t) { S.tool = null; S.mode = "view"; } else { S.tool = t; S.marking = false; S.mode = "view"; if (t === "swap") S.swap = null; }
  render();
}));

/* ---------- composer ---------- */
function toggleStart(src, quiet = false) {
  S.autoStarts.delete(src);
  if (S.starts.includes(src)) S.starts = S.starts.filter(x => x !== src); else S.starts.push(src);
  renderStart(); renderRefs(); renderInspect(); if (!quiet) toast(S.starts.includes(src) ? `Starting from ${startLabel(src)} too` : `Not starting from ${startLabel(src)}`);
}
function hasFeedback(p) { return !!(p && ((p.keeps || []).length || (p.note || "").trim() || (p.marks || []).length)); }
// prints with keeps, notes or marks in the round on screen go into the next round, unless taken out by hand
function syncAutoStarts() {
  if (S.round == null) return;
  const want = roundPrints(S.round).filter(hasFeedback).map(p => `print:${p.id}`);
  for (const src of [...S.autoStarts]) if (!want.includes(src)) { S.autoStarts.delete(src); S.starts = S.starts.filter(x => x !== src); }
  for (const src of want) if (!S.starts.includes(src) && !S.dropped?.has(src)) { S.starts.push(src); S.autoStarts.add(src); }
  renderStart();
}
function renderStart() {
  $("#startbox").hidden = !S.starts.length;
  $("#starts").replaceChildren(...S.starts.map(src => el("div", { class: "st", title: startLabel(src) },
    el("img", { src: startUrl(src), alt: "" }), el("span", {}, startLabel(src)),
    el("button", { type: "button", title: "Don't start from this", onclick: () => { (S.dropped ||= new Set()).add(src); toggleStart(src, true); } }, "x"))));
  const total = Math.max(1, S.starts.length) * (+$("#count").value || 1) * (S.starts.length ? 1 + $("#also").value.split(/[ ,]+/).filter(Boolean).length : 1);
  $("#run").textContent = `Run round, ${total} print${total === 1 ? "" : "s"}`;
}
["#count", "#also"].forEach(id => $(id).addEventListener("input", renderStart));
$("#strength").addEventListener("input", e => $("#strengthv").textContent = (+e.target.value).toFixed(2));
$("#copydown").addEventListener("click", () => { $("#gets").value = $("#said").value; });
$("#size").addEventListener("change", e => { $("#customsize").hidden = e.target.value !== "custom"; });
$("#rewrite").addEventListener("click", async () => {
  const b = $("#rewrite"); b.disabled = true;
  try {
    const look = $("#look").checked, n = roundPrints(S.round).filter(hasFeedback).length;
    b.textContent = look && n ? `Looking at ${n} print${n === 1 ? "" : "s"}, up to ${2 * n + 2} min...` : "Writing, about a minute...";
    const r = await api("POST", `${P()}/rewrite`, { said: $("#said").value, prompt: $("#gets").value, round: S.round, look });
    $("#gets").value = r.prompt; toast("New prompt written. Edit it if it got you wrong.");
  } catch (e) { toast(e.message); }
  b.disabled = false; b.textContent = "Write the prompt";
});
$("#run").addEventListener("click", async () => {
  $("#runerr").textContent = "";
  const gets = $("#gets").value.trim() || $("#said").value.trim();
  if (!gets) { $("#runerr").textContent = "Write what you want first."; return; }
  if (!$("#gets").value.trim()) $("#gets").value = gets;
  const [w, h] = $("#size").value === "custom" ? [+$("#w").value, +$("#h").value] : $("#size").value.split("x").map(Number);
  const strengths = S.starts.length ? [+$("#strength").value, ...$("#also").value.split(/[ ,]+/).filter(Boolean).map(Number).filter(x => x > 0 && x <= 1)] : [];
  try {
    const r = await api("POST", `${P()}/round`, { said: $("#said").value, prompt: gets, count: +$("#count").value,
      width: w, height: h, seed: $("#seed").value.trim(), starts: S.starts, strengths });
    S.starts = []; S.autoStarts.clear(); S.dropped = new Set();
    await reloadProject(); S.round = r.round; S.sel = null; S.b = null; S.mode = "grid"; S.tool = null; render(); poll();
  } catch (e) { $("#runerr").textContent = e.message; }
});

/* ---------- refs: drop, paste, pick ---------- */
async function addRefs(files) {
  if (!S.name) { toast("Make a project first"); return; }
  for (const f of files) {
    if (!f.type.startsWith("image/")) continue;
    const data = await new Promise(res => { const r = new FileReader(); r.onload = () => res(r.result); r.readAsDataURL(f); });
    const name = (f.name && f.name !== "image.png") ? f.name : `pasted-${Date.now()}.png`;
    await api("POST", `${P()}/ref`, { name, data });
  }
  await reloadProject();
}
const drop = $("#drop");
$("#pick").addEventListener("change", e => addRefs([...e.target.files]));
["dragover", "dragenter"].forEach(t => document.addEventListener(t, e => { e.preventDefault(); drop.classList.add("over"); }));
["dragleave", "drop"].forEach(t => document.addEventListener(t, e => { e.preventDefault(); drop.classList.remove("over"); }));
document.addEventListener("drop", e => addRefs([...e.dataTransfer.files]));
document.addEventListener("paste", e => { if (e.target.matches("textarea, input")) return; const fs = [...e.clipboardData.files]; if (fs.length) addRefs(fs); });

/* ---------- view buttons and keys ---------- */
$("#t-grid").addEventListener("click", () => { S.mode = "grid"; S.marking = false; S.tool = null; render(); });
$("#t-view").addEventListener("click", () => { S.mode = "view"; S.tool = null; S.marking = false; render(); });
$("#t-cmp").addEventListener("click", () => { S.mode = "cmp"; S.tool = null; S.marking = false; render(); });
$("#t-mark").addEventListener("click", () => { S.marking = !S.marking; S.tool = null; S.mode = "view"; render(); });
document.addEventListener("keydown", e => {
  if (e.target.matches("textarea, input, select")) return;
  const ps = roundPrints(S.round);
  if (/^[1-9]$/.test(e.key) && S.mode === "grid" && !S.tool) {
    const items = [...ps, ...liveTasks(S.round)].sort((a, b) => a.index - b.index), it = items[+e.key - 1];
    if (it?.file) pick(it.id, e.shiftKey);
  } else if (e.key === "Enter" && S.sel) { S.mode = "view"; render(); }
  else if (e.key === "Escape") { S.mode = "grid"; S.marking = false; S.tool = null; render(); }
  else if ((e.key === "f" || e.key === "F") && S.mode === "cmp") { S.cmpMode = "flip"; S.flip = !S.flip; render(); }
  else if (e.key === "0") document.querySelector(".single")?.oneToOne();
  else if ((e.key === "ArrowRight" || e.key === "ArrowLeft") && S.sel && !S.tool) {
    const i = ps.findIndex(p => p.id === S.sel), j = i + (e.key === "ArrowRight" ? 1 : -1);
    if (ps[j]) { S.sel = ps[j].id; render(); }
  }
});
$("#stop").addEventListener("click", async () => { const r = await api("POST", "/api/stop", { project: S.name }); toast(`Stopping ${r.stopped}`); });

/* ---------- live state ---------- */
async function poll() {
  clearTimeout(poll.t);
  try {
    const st = await api("GET", "/api/state");
    S.ready = st.ready; S.queue = st.queue; S.root = st.root; S.devices = st.devices; S.rewriter = st.rewriter;
    $("#loading").hidden = st.ready && !st.failed;
    $("#loading").textContent = st.failed ? `The image model didn't start. See ${st.root}/.sd-server.log` : "Loading the image model, about a minute";
    $("#rwhint").textContent = st.rewriter ? "Writes from your words plus the keeps, notes and marked spots on this round. Edit what it gives you." : "The rewriter is loading.";
    $("#rewrite").disabled = !st.rewriter || !S.name;
    $("#look").parentElement.hidden = !st.vision; if (!st.vision) $("#look").checked = false;
    const mine = st.queue.filter(t => t.project === S.name);
    const run = mine.find(t => t.status === "running"), waiting = mine.filter(t => t.status === "queued").length;
    $("#job").hidden = !run && !waiting;
    if (run) {
      $("#jobwhat").textContent = run.kind !== "gen" ? `${run.label || run.kind}, ${run.stage || "starting"}` :
        `Round ${run.round}, print ${run.index}` + (run.total ? `, step ${run.step} of ${run.total}` : `, ${run.stage || "starting"}`);
      $("#jobmeter").style.width = run.total ? `${100 * run.step / run.total}%` : "0";
    } else if (waiting) $("#jobwhat").textContent = st.ready ? "Starting" : "Waiting for the model";
    $("#jobnext").textContent = waiting ? `then ${waiting} more` : "";
    const finished = mine.filter(t => !["queued", "running"].includes(t.status) && !S.doneSeen.has(t.id));
    finished.forEach(t => { S.doneSeen.add(t.id);
      if (t.status === "failed") toast(`Failed: ${t.error || "unknown"}`);
      else if (t.status === "done" && t.kind !== "gen" && poll.started) toast(`${t.label} done`); });
    poll.started = true;
    if (finished.length) await reloadProject();
    else if (run && S.mode === "grid" && run.round === S.round && !S.tool) renderStage();
  } catch (e) { $("#loading").hidden = false; $("#loading").textContent = "Can't reach thunk"; }
  poll.t = setTimeout(poll, 700);
}
api("GET", "/api/fonts").then(f => { S.fonts = f; }).catch(() => { });
loadProjects().then(poll);
