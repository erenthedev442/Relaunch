/* Gear Finder — interactive gear database + job set builder.
 *
 * Pure client-side. Fetches docs/assets/gear-data.json (emitted by
 * the site build tooling) and renders two views:
 *   1. Database  — filter/sort every equippable item; add any stat as a
 *                  sortable column with an optional "≥ min" filter.
 *   2. Set Builder — pick a job + priority (role or single stat) and get a
 *                    best-in-slot loadout from the same scored data.
 *
 * Item names render as the site's standard <a class="item-link" data-img>
 * markup, so the global item-tooltip.js shows BG-Wiki hover previews here too.
 */
(function () {
  "use strict";

  var THIS = document.currentScript; // captured synchronously at load

  function dataUrl() {
    var src = (THIS && THIS.src) || "assets/gear-finder.js";
    return src.replace(/gear-finder\.js.*$/, "gear-data.json");
  }

  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  // ---- tiny helpers -------------------------------------------------------
  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    if (attrs) for (var k in attrs) {
      if (k === "class") e.className = attrs[k];
      else if (k === "html") e.innerHTML = attrs[k];
      else if (k === "text") e.textContent = attrs[k];
      else e.setAttribute(k, attrs[k]);
    }
    if (kids) kids.forEach(function (c) { if (c) e.appendChild(c); });
    return e;
  }
  function opt(value, label) { var o = document.createElement("option"); o.value = value; o.textContent = label; return o; }
  function debounce(fn, ms) { var t; return function () { clearTimeout(t); var a = arguments, self = this; t = setTimeout(function () { fn.apply(self, a); }, ms); }; }

  // ---- MD5 (RFC 1321) for BG-Wiki image paths -----------------------------
  function md5(s) {
    s = unescape(encodeURIComponent(s)); // UTF-8 bytes, matching Python
    function rl(n, c) { return (n << c) | (n >>> (32 - c)); }
    function ad(x, y) { var l = (x & 0xFFFF) + (y & 0xFFFF); return (((x >> 16) + (y >> 16) + (l >> 16)) << 16) | (l & 0xFFFF); }
    function cm(q, a, b, x, t, s) { return ad(rl(ad(ad(a, q), ad(x, t)), s), b); }
    function ff(a, b, c, d, x, s, t) { return cm((b & c) | (~b & d), a, b, x, t, s); }
    function gg(a, b, c, d, x, s, t) { return cm((b & d) | (c & ~d), a, b, x, t, s); }
    function hh(a, b, c, d, x, s, t) { return cm(b ^ c ^ d, a, b, x, t, s); }
    function ii(a, b, c, d, x, s, t) { return cm(c ^ (b | ~d), a, b, x, t, s); }
    var n = s.length, blks = [], i;
    for (i = 0; i < (((n + 8) >> 6) + 1) * 16; i++) blks[i] = 0;
    for (i = 0; i < n; i++) blks[i >> 2] |= s.charCodeAt(i) << ((i % 4) * 8);
    blks[i >> 2] |= 0x80 << ((i % 4) * 8);
    blks[(((n + 8) >> 6) + 1) * 16 - 2] = n * 8;
    var a = 1732584193, b = -271733879, c = -1732584194, d = 271733878;
    for (i = 0; i < blks.length; i += 16) {
      var oa = a, ob = b, oc = c, od = d;
      a = ff(a, b, c, d, blks[i], 7, -680876936); d = ff(d, a, b, c, blks[i + 1], 12, -389564586); c = ff(c, d, a, b, blks[i + 2], 17, 606105819); b = ff(b, c, d, a, blks[i + 3], 22, -1044525330);
      a = ff(a, b, c, d, blks[i + 4], 7, -176418897); d = ff(d, a, b, c, blks[i + 5], 12, 1200080426); c = ff(c, d, a, b, blks[i + 6], 17, -1473231341); b = ff(b, c, d, a, blks[i + 7], 22, -45705983);
      a = ff(a, b, c, d, blks[i + 8], 7, 1770035416); d = ff(d, a, b, c, blks[i + 9], 12, -1958414417); c = ff(c, d, a, b, blks[i + 10], 17, -42063); b = ff(b, c, d, a, blks[i + 11], 22, -1990404162);
      a = ff(a, b, c, d, blks[i + 12], 7, 1804603682); d = ff(d, a, b, c, blks[i + 13], 12, -40341101); c = ff(c, d, a, b, blks[i + 14], 17, -1502002290); b = ff(b, c, d, a, blks[i + 15], 22, 1236535329);
      a = gg(a, b, c, d, blks[i + 1], 5, -165796510); d = gg(d, a, b, c, blks[i + 6], 9, -1069501632); c = gg(c, d, a, b, blks[i + 11], 14, 643717713); b = gg(b, c, d, a, blks[i], 20, -373897302);
      a = gg(a, b, c, d, blks[i + 5], 5, -701558691); d = gg(d, a, b, c, blks[i + 10], 9, 38016083); c = gg(c, d, a, b, blks[i + 15], 14, -660478335); b = gg(b, c, d, a, blks[i + 4], 20, -405537848);
      a = gg(a, b, c, d, blks[i + 9], 5, 568446438); d = gg(d, a, b, c, blks[i + 14], 9, -1019803690); c = gg(c, d, a, b, blks[i + 3], 14, -187363961); b = gg(b, c, d, a, blks[i + 8], 20, 1163531501);
      a = gg(a, b, c, d, blks[i + 13], 5, -1444681467); d = gg(d, a, b, c, blks[i + 2], 9, -51403784); c = gg(c, d, a, b, blks[i + 7], 14, 1735328473); b = gg(b, c, d, a, blks[i + 12], 20, -1926607734);
      a = hh(a, b, c, d, blks[i + 5], 4, -378558); d = hh(d, a, b, c, blks[i + 8], 11, -2022574463); c = hh(c, d, a, b, blks[i + 11], 16, 1839030562); b = hh(b, c, d, a, blks[i + 14], 23, -35309556);
      a = hh(a, b, c, d, blks[i + 1], 4, -1530992060); d = hh(d, a, b, c, blks[i + 4], 11, 1272893353); c = hh(c, d, a, b, blks[i + 7], 16, -155497632); b = hh(b, c, d, a, blks[i + 10], 23, -1094730640);
      a = hh(a, b, c, d, blks[i + 13], 4, 681279174); d = hh(d, a, b, c, blks[i], 11, -358537222); c = hh(c, d, a, b, blks[i + 3], 16, -722521979); b = hh(b, c, d, a, blks[i + 6], 23, 76029189);
      a = hh(a, b, c, d, blks[i + 9], 4, -640364487); d = hh(d, a, b, c, blks[i + 12], 11, -421815835); c = hh(c, d, a, b, blks[i + 15], 16, 530742520); b = hh(b, c, d, a, blks[i + 2], 23, -995338651);
      a = ii(a, b, c, d, blks[i], 6, -198630844); d = ii(d, a, b, c, blks[i + 7], 10, 1126891415); c = ii(c, d, a, b, blks[i + 14], 15, -1416354905); b = ii(b, c, d, a, blks[i + 5], 21, -57434055);
      a = ii(a, b, c, d, blks[i + 12], 6, 1700485571); d = ii(d, a, b, c, blks[i + 3], 10, -1894986606); c = ii(c, d, a, b, blks[i + 10], 15, -1051523); b = ii(b, c, d, a, blks[i + 1], 21, -2054922799);
      a = ii(a, b, c, d, blks[i + 8], 6, 1873313359); d = ii(d, a, b, c, blks[i + 15], 10, -30611744); c = ii(c, d, a, b, blks[i + 6], 15, -1560198380); b = ii(b, c, d, a, blks[i + 13], 21, 1309151649);
      a = ii(a, b, c, d, blks[i + 4], 6, -145523070); d = ii(d, a, b, c, blks[i + 11], 10, -1120210379); c = ii(c, d, a, b, blks[i + 2], 15, 718787259); b = ii(b, c, d, a, blks[i + 9], 21, -343485551);
      a = ad(a, oa); b = ad(b, ob); c = ad(c, oc); d = ad(d, od);
    }
    var hx = "0123456789abcdef", out = "";
    var arr = [a, b, c, d];
    for (i = 0; i < 4; i++) for (var j = 0; j < 4; j++) { var by = (arr[i] >> (j * 8)) & 0xFF; out += hx.charAt((by >> 4) & 0xF) + hx.charAt(by & 0xF); }
    return out;
  }

  // =========================================================================
  ready(function () {
    var root = document.getElementById("gear-finder");
    if (!root) return;
    root.innerHTML = '<div class="gf-loading">Loading gear data…</div>';
    fetch(dataUrl())
      .then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); })
      .then(function (data) { init(root, data); })
      .catch(function (e) { root.innerHTML = '<div class="gf-loading">Could not load gear data (' + e.message + ').</div>'; });
  });

  function init(root, data) {
    var META = data.meta, ITEMS = data.items;
    var JOBS = META.jobs;
    var JOB_BIT = {}; JOBS.forEach(function (j, i) { JOB_BIT[j] = 1 << i; });
    var ALL_JOBS = (1 << JOBS.length) - 1;
    var ROLES = META.roles;
    var SLOT_ORDER = META.slotOrder;
    var WSK = META.weaponSkills;

    function modLabel(id) { return META.modLabels[id] || ("mod " + id); }

    // Append stat options as labelled <optgroup>s (data-driven via
    // META.statGroups; falls back to one flat alphabetical group).
    function appendStatOptgroups(sel, valuePrefix) {
      var groups = META.statGroups || [["By stat",
        STAT_IDS.slice().sort(function (a, b) { return modLabel(a) < modLabel(b) ? -1 : 1; })]];
      groups.forEach(function (grp) {
        var og = el("optgroup", { label: grp[0] });
        grp[1].forEach(function (id) { og.appendChild(opt(valuePrefix + id, modLabel(id))); });
        sel.appendChild(og);
      });
    }

    // bit -> slot name (collapsed L/R) for decoding item.s masks
    var BIT_SLOT = {}; META.slotBits.forEach(function (p) { BIT_SLOT[p[0]] = p[1]; });
    function slotsOf(mask) {
      var out = [], seen = {};
      for (var b = 0; b < 16; b++) if (mask & (1 << b)) { var nm = BIT_SLOT[b]; if (nm && !seen[nm]) { seen[nm] = 1; out.push(nm); } }
      return out;
    }

    // Precompute per-item: search string, base-mod map, slot list, job list.
    var STAT_IDS = Object.keys(META.modLabels).map(Number);
    ITEMS.forEach(function (it) {
      it._s = it.n.toLowerCase();
      it._mv = {};
      if (it.m) it.m.forEach(function (p) { it._mv[p[0]] = p[1]; });
      it._slots = slotsOf(it.s);
      it._all = (it.j === ALL_JOBS);
      it._best = it.sc ? Math.max.apply(null, it.sc) : 0;
    });

    function jobStr(it) {
      if (it._all) return "All";
      var out = [];
      for (var i = 0; i < JOBS.length; i++) if (it.j & (1 << i)) out.push(JOBS[i]);
      return out.join(" ");
    }
    function bestRole(it) {
      if (!it.sc) return "";
      var bi = 0; for (var i = 1; i < it.sc.length; i++) if (it.sc[i] > it.sc[bi]) bi = i;
      return it.sc[bi] > 0 ? ROLES[bi] : "";
    }
    function hasStats(it) { return !!(it.m || it.w); }

    // ---- item-link markup (FFXIAH item page + icon, keyed on item id) ------
    // Reliable by construction: every gear-data item carries its id (it.i),
    // so we never guess BG-Wiki names/filenames. No-id items fall back to a
    // BG-Wiki search link with no hover image (item-tooltip.js skips empty).
    function itemAnchor(it) {
      var name = it.n, id = it.i;
      var attrs = { "class": "item-link", target: "_blank", rel: "noopener", text: name };
      if (id) {
        attrs.href = "https://www.ffxiah.com/item/" + id;
        // BG-Wiki stat box when resolved (it.img), else the FFXIAH icon.
        attrs["data-img"] = it.img || ("https://static.ffxiah.com/images/icon/" + id + ".png");
      } else {
        attrs.href = "https://www.bg-wiki.com/index.php?search=" +
          encodeURIComponent(name).replace(/%20/g, "+") + "&go=Go";
      }
      return el("a", attrs);
    }

    // ---- state ------------------------------------------------------------
    var tab = "db";
    var f = { q: "", slot: "All", job: "All", wtype: "All", source: "all", hasStats: true, hideEx: false, hideRare: false, maxLv: "" };
    var statCols = [];           // [{id, min}]
    var sort = { key: "ilvl", dir: -1 };
    var page = 0, PER = 100;
    var sb = { job: JOBS[0], priority: "role:DPS", obtOnly: false, wtype: "All" };

    // ---- shell ------------------------------------------------------------
    root.innerHTML = "";
    var tabs = el("div", { "class": "gf-tabs" }, [
      el("button", { "class": "gf-tab is-active", "data-tab": "db", text: "Database" }),
      el("button", { "class": "gf-tab", "data-tab": "set", text: "Set Builder" })
    ]);
    var panelDB = el("div", { "class": "gf-panel is-active", id: "gf-db" });
    var panelSet = el("div", { "class": "gf-panel", id: "gf-set" });
    root.appendChild(tabs);
    root.appendChild(panelDB);
    root.appendChild(panelSet);

    tabs.addEventListener("click", function (e) {
      var b = e.target.closest(".gf-tab"); if (!b) return;
      tab = b.getAttribute("data-tab");
      Array.prototype.forEach.call(tabs.children, function (c) { c.classList.toggle("is-active", c === b); });
      panelDB.classList.toggle("is-active", tab === "db");
      panelSet.classList.toggle("is-active", tab === "set");
      if (tab === "set") renderSet();
    });

    buildDBControls();
    renderDB();
    buildSetControls();

    // =======================================================================
    //  DATABASE
    // =======================================================================
    var dbCount, dbTableWrap, dbPager, statBar;

    function buildDBControls() {
      var c = el("div", { "class": "gf-controls" });

      var qIn = el("input", { type: "text", "class": "gf-search", placeholder: "Search item name…" });
      qIn.addEventListener("input", debounce(function () { f.q = qIn.value.trim().toLowerCase(); page = 0; renderDB(); }, 150));
      c.appendChild(field("Search", qIn));

      var slotSel = el("select"); slotSel.appendChild(opt("All", "All slots"));
      SLOT_ORDER.forEach(function (s) { slotSel.appendChild(opt(s, s)); });
      slotSel.addEventListener("change", function () { f.slot = slotSel.value; page = 0; renderDB(); });
      c.appendChild(field("Slot", slotSel));

      var jobSel = el("select"); jobSel.appendChild(opt("All", "All jobs"));
      JOBS.forEach(function (j) { jobSel.appendChild(opt(j, j)); });
      jobSel.addEventListener("change", function () { f.job = jobSel.value; page = 0; renderDB(); });
      c.appendChild(field("Usable by", jobSel));

      var wSel = el("select"); wSel.appendChild(opt("All", "Any type"));
      Object.keys(WSK).sort(function (a, b) { return WSK[a] < WSK[b] ? -1 : 1; }).forEach(function (k) { wSel.appendChild(opt(WSK[k], WSK[k])); });
      wSel.addEventListener("change", function () { f.wtype = wSel.value; page = 0; renderDB(); });
      c.appendChild(field("Weapon type", wSel));

      var srcSel = el("select");
      srcSel.appendChild(opt("all", "All items")); srcSel.appendChild(opt("obt", "Obtainable here"));
      srcSel.addEventListener("change", function () { f.source = srcSel.value; page = 0; renderDB(); });
      c.appendChild(field("Source", srcSel));

      var lvIn = el("input", { type: "number", min: "1", max: "99", placeholder: "any" });
      lvIn.addEventListener("input", debounce(function () { f.maxLv = lvIn.value; page = 0; renderDB(); }, 200));
      c.appendChild(field("Max Lv", lvIn));

      var checks = el("div", { "class": "gf-checks" });
      checks.appendChild(check("Has stats", true, function (v) { f.hasStats = v; page = 0; renderDB(); }));
      checks.appendChild(check("Hide Ex", false, function (v) { f.hideEx = v; page = 0; renderDB(); }));
      checks.appendChild(check("Hide Rare", false, function (v) { f.hideRare = v; page = 0; renderDB(); }));
      var cf = el("div", { "class": "gf-field" }, [el("label", { text: "Options" }), checks]);
      c.appendChild(cf);

      panelDB.appendChild(c);

      // stat columns bar
      statBar = el("div", { "class": "gf-statbar" });
      var addSel = el("select");
      addSel.appendChild(opt("", "+ Add stat column / filter…"));
      appendStatOptgroups(addSel, "");
      addSel.addEventListener("change", function () {
        var id = parseInt(addSel.value, 10);
        if (id && !statCols.some(function (s) { return s.id === id; })) { statCols.push({ id: id, min: "" }); sort = { key: "stat:" + id, dir: -1 }; page = 0; renderStatBar(); renderDB(); }
        addSel.value = "";
      });
      statBar.appendChild(el("span", { "class": "gf-hint", text: "Add a stat to show it as a sortable column (set a number to require ≥ that value):" }));
      statBar.appendChild(addSel);
      panelDB.appendChild(statBar);
      renderStatBar();

      dbCount = el("div", { "class": "gf-count" });
      var exportBtn = el("button", { "class": "gf-export", title: "Download the filtered list as CSV (opens in Excel / Google Sheets)", text: "⬇ Export CSV" });
      exportBtn.addEventListener("click", exportCSV);
      dbTableWrap = el("div", { "class": "gf-tablewrap" });
      dbPager = el("div", { "class": "gf-pager" });
      panelDB.appendChild(el("div", { "class": "gf-countrow" }, [dbCount, exportBtn]));
      panelDB.appendChild(dbTableWrap);
      panelDB.appendChild(dbPager);
    }

    function renderStatBar() {
      // remove existing chips (keep hint + select which are first two/last)
      Array.prototype.slice.call(statBar.querySelectorAll(".gf-statchip")).forEach(function (n) { n.remove(); });
      statCols.forEach(function (sc) {
        var minIn = el("input", { type: "number", placeholder: "≥", value: sc.min });
        minIn.addEventListener("input", debounce(function () { sc.min = minIn.value; page = 0; renderDB(); }, 200));
        var rm = el("button", { title: "Remove", text: "×" });
        rm.addEventListener("click", function () { statCols = statCols.filter(function (x) { return x !== sc; }); if (sort.key === "stat:" + sc.id) sort = { key: "score", dir: -1 }; renderStatBar(); renderDB(); });
        var chip = el("span", { "class": "gf-statchip" }, [el("span", { text: modLabel(sc.id) }), minIn, rm]);
        statBar.appendChild(chip);
      });
    }

    function field(label, ctrl) { return el("div", { "class": "gf-field" }, [el("label", { text: label }), ctrl]); }
    function check(label, def, cb) {
      var i = el("input", { type: "checkbox" }); i.checked = def;
      i.addEventListener("change", function () { cb(i.checked); });
      return el("label", {}, [i, document.createTextNode(label)]);
    }

    function filterDB() {
      var jb = f.job !== "All" ? JOB_BIT[f.job] : 0;
      var maxLv = f.maxLv ? parseInt(f.maxLv, 10) : 0;
      return ITEMS.filter(function (it) {
        if (f.hasStats && !hasStats(it)) return false;
        if (f.hideEx && (it.f & 1)) return false;
        if (f.hideRare && (it.f & 2)) return false;
        if (f.source === "obt" && !(it.f & 4)) return false;
        if (f.q && it._s.indexOf(f.q) === -1) return false;
        if (f.slot !== "All" && it._slots.indexOf(f.slot) === -1) return false;
        if (jb && !(it.j & jb) && !it._all) return false;
        if (f.wtype !== "All" && (!it.w || WSK[it.w[0]] !== f.wtype)) return false;
        if (maxLv && (it.l || 1) > maxLv) return false;
        for (var i = 0; i < statCols.length; i++) {
          var sc = statCols[i];
          if (sc.min !== "" && !((it._mv[sc.id] || 0) >= parseFloat(sc.min))) return false;
        }
        return true;
      });
    }

    function sortVal(it, key) {
      if (key === "name") return it._s;
      if (key === "slot") return SLOT_ORDER.indexOf(it._slots[0]);
      if (key === "jobs") return it._all ? 99 : (it.j ? popcount(it.j) : 0);
      if (key === "lv") return it.l || 0;
      if (key === "ilvl") return it.il || 0;
      if (key === "score") return it._best;
      if (key.indexOf("stat:") === 0) { var id = +key.slice(5); return (id in it._mv) ? it._mv[id] : -1e9; }
      if (key === "source") return (it.o || "").toLowerCase();
      return 0;
    }
    function popcount(n) { var c = 0; while (n) { n &= n - 1; c++; } return c; }

    function sortedList() {
      var list = filterDB();
      list.sort(function (a, b) {
        var va = sortVal(a, sort.key), vb = sortVal(b, sort.key);
        if (va < vb) return -1 * sort.dir; if (va > vb) return 1 * sort.dir;
        return a._s < b._s ? -1 : 1;
      });
      return list;
    }
    function csvCell(v) { v = String(v == null ? "" : v); return /[",\r\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; }
    function exportCSV() {
      var list = sortedList();
      var head = ["Item", "Slot", "Jobs", "Lv", "iLvl"];
      statCols.forEach(function (sc) { head.push(modLabel(sc.id)); });
      head.push("Score", "Role", "Source");
      var lines = [head.map(csvCell).join(",")];
      list.forEach(function (it) {
        var row = [it.n, it._slots.join("/"), jobStr(it), it.l || "", it.il || ""];
        statCols.forEach(function (sc) { var v = it._mv[sc.id]; row.push(v == null ? "" : fmt(v)); });
        row.push(it._best || "", bestRole(it) || "", it.o || "");
        lines.push(row.map(csvCell).join(","));
      });
      var csv = "\ufeff" + lines.join("\r\n"); // BOM so Excel reads UTF-8 correctly
      var url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
      var a = el("a", { href: url, download: "gear-finder.csv" });
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(function () { URL.revokeObjectURL(url); }, 1500);
    }
    function renderDB() {
      if (!dbTableWrap) return;
      var list = sortedList();
      dbCount.textContent = list.length.toLocaleString() + " item" + (list.length === 1 ? "" : "s");
      var pages = Math.max(1, Math.ceil(list.length / PER));
      if (page >= pages) page = pages - 1;
      var slice = list.slice(page * PER, page * PER + PER);

      var cols = [["name", "Item", false], ["slot", "Slot", false], ["jobs", "Jobs", false], ["lv", "Lv", true], ["ilvl", "iLvl", true]];
      statCols.forEach(function (sc) { cols.push(["stat:" + sc.id, modLabel(sc.id), true]); });
      cols.push(["score", "Score", true]);
      cols.push(["source", "Source", false]);

      var thead = el("thead"), htr = el("tr");
      cols.forEach(function (c) {
        var active = sort.key === c[0];
        var arrow = active
          ? el("span", { "class": "gf-arrow", text: sort.dir < 0 ? "▾" : "▴" })
          : el("span", { "class": "gf-arrow gf-arrow-idle", text: "⇅" });
        var th = el("th", { "class": "gf-sortable" + (c[2] ? " gf-num" : ""), "data-key": c[0], title: "Sort by " + c[1] },
          [document.createTextNode(c[1] + " "), arrow]);
        htr.appendChild(th);
      });
      thead.appendChild(htr);
      thead.addEventListener("click", function (e) {
        var th = e.target.closest("th[data-key]"); if (!th) return;
        var key = th.getAttribute("data-key");
        if (sort.key === key) sort.dir *= -1; else sort = { key: key, dir: (key === "name" || key === "slot" || key === "source") ? 1 : -1 };
        renderDB();
      });

      var tbody = el("tbody");
      if (!slice.length) {
        tbody.appendChild(el("tr", {}, [el("td", { "class": "gf-empty", colspan: String(cols.length), text: "No items match these filters." })]));
      }
      slice.forEach(function (it) {
        var tr = el("tr", { "class": "gf-row" });
        var nameTd = el("td"); nameTd.appendChild(itemAnchor(it));
        if (it.f & 1) nameTd.appendChild(el("span", { "class": "gf-badge ex", text: "Ex" }));
        if (it.f & 2) nameTd.appendChild(el("span", { "class": "gf-badge rare", text: "Rare" }));
        tr.appendChild(nameTd);
        tr.appendChild(el("td", { text: it._slots.join("/") || "—" }));
        tr.appendChild(el("td", { "class": "gf-jobs", text: jobStr(it) }));
        tr.appendChild(el("td", { "class": "gf-num", text: it.l ? String(it.l) : "—" }));
        tr.appendChild(el("td", { "class": "gf-num", text: it.il ? String(it.il) : "—" }));
        statCols.forEach(function (sc) { var v = it._mv[sc.id]; tr.appendChild(el("td", { "class": "gf-num", text: v == null ? "" : fmt(v) })); });
        var br = bestRole(it);
        tr.appendChild(el("td", { "class": "gf-num", text: it._best ? (it._best + (br ? " " + br : "")) : "" }));
        tr.appendChild(el("td", { text: it.o || "" }));
        tbody.appendChild(tr);

        tr.addEventListener("click", function (e) {
          if (e.target.closest("a")) return; // let item links work
          var nxt = tr.nextSibling;
          if (nxt && nxt.classList && nxt.classList.contains("gf-detail")) { nxt.remove(); return; }
          var det = el("tr", { "class": "gf-detail" });
          det.appendChild(el("td", { colspan: String(cols.length) }, [detailBody(it)]));
          tr.parentNode.insertBefore(det, tr.nextSibling);
        });
      });

      var table = el("table", { "class": "gf-table" }, [thead, tbody]);
      dbTableWrap.innerHTML = ""; dbTableWrap.appendChild(table);

      // pager
      dbPager.innerHTML = "";
      if (pages > 1) {
        var prev = el("button", { text: "‹ Prev" }); prev.disabled = page === 0;
        var next = el("button", { text: "Next ›" }); next.disabled = page >= pages - 1;
        prev.addEventListener("click", function () { if (page > 0) { page--; renderDB(); dbTableWrap.scrollIntoView({ block: "nearest" }); } });
        next.addEventListener("click", function () { if (page < pages - 1) { page++; renderDB(); dbTableWrap.scrollIntoView({ block: "nearest" }); } });
        dbPager.appendChild(prev);
        dbPager.appendChild(el("span", { text: "Page " + (page + 1) + " / " + pages }));
        dbPager.appendChild(next);
      }
    }

    function fmt(v) { return (v > 0 ? "+" : "") + v; }

    function detailBody(it) {
      var wrap = el("div");
      if (it.w) {
        var skill = WSK[it.w[0]] || ("skill " + it.w[0]);
        var dps = it.w[2] ? (it.w[1] * 60 / it.w[2]).toFixed(1) : "—";
        wrap.appendChild(el("div", { html: "<strong>" + skill + "</strong> — DMG " + it.w[1] + " · Delay " + it.w[2] + " · DPS " + dps }));
      }
      var mods = el("div", { "class": "gf-modlist" });
      (it.m || []).forEach(function (p) { mods.appendChild(el("span", { "class": "gf-mod", text: modLabel(p[0]) + " " + fmt(p[1]) })); });
      (it.lt || []).forEach(function (p) { mods.appendChild(el("span", { "class": "gf-mod gf-latent", text: "(latent) " + modLabel(p[0]) + " " + fmt(p[1]) })); });
      if (!(it.m || it.lt)) mods.appendChild(el("span", { "class": "gf-latent", text: "No stat bonuses." }));
      wrap.appendChild(mods);
      // Sources — the full "where to get it" list: system tags (Gear Vendor,
      // Reforge, !shop…) plus every mob/zone drop with its %, newest data each
      // docgen run. Generated by gear_finder.py from the shared source table.
      if (it.src && it.src.length) {
        var sw = el("div", { "class": "gf-sources" });
        sw.appendChild(el("span", { "class": "gf-src-h", text: "Sources" }));
        it.src.forEach(function (s) {
          if (s.s) {
            sw.appendChild(el("span", { "class": "gf-src gf-src-sys", text: s.s }));
          } else {
            var t = s.m + (s.z ? " · " + s.z : "") + (s.p != null ? " (" + s.p + "%)" : "");
            sw.appendChild(el("span", { "class": "gf-src gf-src-drop", text: t }));
          }
        });
        wrap.appendChild(sw);
      }
      var meta = [];
      if (it.su) meta.push("Superior Lv " + it.su);
      if (it.o && !(it.src && it.src.length)) meta.push("Obtainable: " + it.o);
      meta.push("Item ID " + it.i);
      wrap.appendChild(el("div", { "class": "gf-pickstats", text: meta.join(" · ") }));
      return wrap;
    }

    // =======================================================================
    //  SET BUILDER
    // =======================================================================
    var setBody;
    function buildSetControls() {
      var c = el("div", { "class": "gf-controls" });

      var jobSel = el("select"); JOBS.forEach(function (j) { jobSel.appendChild(opt(j, j)); });
      jobSel.value = sb.job;
      jobSel.addEventListener("change", function () { sb.job = jobSel.value; renderSet(); });
      c.appendChild(field("Job", jobSel));

      var prSel = el("select");
      ROLES.forEach(function (r) { prSel.appendChild(opt("role:" + r, "Best for " + r)); });
      appendStatOptgroups(prSel, "stat:");
      prSel.value = sb.priority;
      prSel.addEventListener("change", function () { sb.priority = prSel.value; renderSet(); });
      c.appendChild(field("Priority", prSel));

      var wSel = el("select"); wSel.appendChild(opt("All", "Any weapon"));
      Object.keys(WSK).sort(function (a, b) { return WSK[a] < WSK[b] ? -1 : 1; }).forEach(function (k) { wSel.appendChild(opt(WSK[k], WSK[k])); });
      wSel.addEventListener("change", function () { sb.wtype = wSel.value; renderSet(); });
      c.appendChild(field("Weapon type", wSel));

      var checks = el("div", { "class": "gf-checks" });
      checks.appendChild(check("Obtainable here only", false, function (v) { sb.obtOnly = v; renderSet(); }));
      c.appendChild(el("div", { "class": "gf-field" }, [el("label", { text: "Options" }), checks]));

      panelSet.appendChild(c);
      setBody = el("div"); panelSet.appendChild(setBody);
    }

    function priorityScore(it) {
      if (sb.priority.indexOf("role:") === 0) { var ri = ROLES.indexOf(sb.priority.slice(5)); return it.sc ? it.sc[ri] : 0; }
      var id = +sb.priority.slice(5);
      var v = it._mv[id] || 0;
      if (it.w && it.w[2]) v += (it.w[1] * 60 / it.w[2]) * 0.0001; // tie-break weapons by DPS
      return v;
    }

    function renderSet() {
      if (!setBody) return;
      var jb = JOB_BIT[sb.job];
      var bySlot = {};
      ITEMS.forEach(function (it) {
        if (!hasStats(it)) return;
        if (!(it.j & jb) && !it._all) return;
        if (sb.obtOnly && !(it.f & 4)) return;
        it._slots.forEach(function (s) { (bySlot[s] = bySlot[s] || []).push(it); });
      });

      var grid = el("div", { "class": "gf-set" });
      // visual slot order with paired ear/ring
      var layout = [];
      SLOT_ORDER.forEach(function (s) {
        if (s === "Ear" || s === "Ring") { layout.push([s, s + " 1"]); layout.push([s, s + " 2"]); }
        else layout.push([s, s]);
      });
      var usedInSlot = {};
      layout.forEach(function (pair) {
        var slot = pair[0], label = pair[1];
        var cand = (bySlot[slot] || []).slice();
        if (sb.wtype !== "All") {
          if (slot === "Main") {
            cand = cand.filter(function (it) { return it.w && WSK[it.w[0]] === sb.wtype; });
          } else if (slot === "Sub") {
            // Two-handed mains occupy both hands -> the Sub takes a GRIP (stored
            // as a skill-0 "weapon"). One-handed mains take a shield (no weapon
            // entry) or a same-type off-hand. Hand-to-Hand has no sub.
            var TWOH = { "Great Sword": 1, "Great Axe": 1, "Scythe": 1, "Polearm": 1, "Great Katana": 1, "Staff": 1 };
            if (TWOH[sb.wtype]) cand = cand.filter(function (it) { return it.w && it.w[0] === 0; });
            else if (sb.wtype === "Hand-to-Hand") cand = [];
            else cand = cand.filter(function (it) { return !it.w || (it.w && WSK[it.w[0]] === sb.wtype); });
          }
        }
        cand.sort(function (a, b) { return priorityScore(b) - priorityScore(a) || b._best - a._best; });
        // avoid picking the same ear/ring twice
        var skip = usedInSlot[slot] || {};
        var pick = null, alts = [];
        for (var i = 0; i < cand.length; i++) { if (skip[cand[i].i]) continue; if (!pick) { pick = cand[i]; } else if (alts.length < 3) { alts.push(cand[i]); } }
        if (pick) { usedInSlot[slot] = skip; skip[pick.i] = 1; }

        var card = el("div", { "class": "gf-slotcard" + (pick ? "" : " gf-none") });
        card.appendChild(el("h4", { text: label }));
        if (!pick) { card.appendChild(el("div", { "class": "gf-pick", text: "— none —" })); grid.appendChild(card); return; }
        var pdiv = el("div", { "class": "gf-pick" }); pdiv.appendChild(itemAnchor(pick)); card.appendChild(pdiv);
        card.appendChild(el("div", { "class": "gf-pickstats", text: pickStat(pick) }));
        if (alts.length) {
          var d = el("details", { "class": "gf-alts" });
          d.appendChild(el("summary", { text: "alternatives" }));
          alts.forEach(function (a) { var line = el("span", { "class": "gf-alt" }); line.appendChild(itemAnchor(a)); line.appendChild(document.createTextNode(" — " + pickStat(a))); d.appendChild(line); });
          card.appendChild(d);
        }
        grid.appendChild(card);
      });
      setBody.innerHTML = "";
      setBody.appendChild(el("p", { "class": "gf-hint", html: "Best gear per slot for <strong>" + sb.job + "</strong>, ranked by <strong>" + priorityLabel() + "</strong>. Click a slot's “alternatives” for runners-up. Tap an item for its BG-Wiki page." }));
      setBody.appendChild(grid);
    }

    function priorityLabel() {
      if (sb.priority.indexOf("role:") === 0) return "best for " + sb.priority.slice(5);
      return modLabel(+sb.priority.slice(5));
    }
    function pickStat(it) {
      var bits = [];
      if (sb.priority.indexOf("stat:") === 0) { var id = +sb.priority.slice(5); if (id in it._mv) bits.push(modLabel(id) + " " + fmt(it._mv[id])); }
      else { var s = priorityScore(it); if (s) bits.push("score " + Math.round(s)); }
      if (it.w) bits.push("DMG " + it.w[1] + "/" + it.w[2]);
      if (it.l) bits.push("Lv " + it.l);
      if (it.o) bits.push(it.o);
      return bits.join(" · ");
    }
  }
})();
