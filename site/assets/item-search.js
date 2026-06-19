/* Item Database — drop & use finder.
 *
 * Pure client-side. Fetches docs/assets/item-search-data.json (emitted by
 * tools/docgen/generators/drop_finder.py) and renders a searchable list: each
 * item shows WHERE IT DROPS (mob / zone / %) and WHAT IT'S USED FOR.
 *
 * Mounts into #item-search on the Item Database page; no-ops elsewhere. Skips
 * gracefully when the JSON is absent/empty (the drop data is DB-backed and only
 * (re)generates on the box's live-server docs refresh).
 */
(function () {
  "use strict";

  var THIS = document.currentScript;

  function dataUrl() {
    var src = (THIS && THIS.src) || "assets/item-search.js";
    return src.replace(/item-search\.js.*$/, "item-search-data.json");
  }
  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }
  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
  }
  function pctClass(p) { return p >= 50 ? "is-hi" : (p >= 10 ? "is-mid" : "is-lo"); }

  ready(function () {
    var mount = document.getElementById("item-search");
    if (!mount) return;
    fetch(dataUrl(), { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (payload) {
        if (!payload || !payload.items || !payload.items.length) {
          mount.innerHTML = '<div class="is-loading">Item data hasn\'t been ' +
            'generated yet — it fills in on the next live-server docs refresh.</div>';
          return;
        }
        build(mount, payload.items);
      })
      .catch(function () {
        mount.innerHTML = '<div class="is-loading">Couldn\'t load item data.</div>';
      });
  });

  function build(mount, items) {
    mount.innerHTML =
      '<div class="is-bar">' +
        '<div class="is-search"><input id="is-q" type="text" ' +
          'placeholder="Search items… try \'behemoth\'" aria-label="Search items"></div>' +
        '<div class="is-filters">' +
          '<button class="is-btn is-active" data-f="all">All</button>' +
          '<button class="is-btn" data-f="drops">Drops from a mob</button>' +
          '<button class="is-btn" data-f="uses">Augment catalysts</button>' +
          '<span class="is-count" id="is-count"></span>' +
        '</div>' +
      '</div>' +
      '<div id="is-results" class="is-results"></div>';

    var q = mount.querySelector("#is-q");
    var results = mount.querySelector("#is-results");
    var count = mount.querySelector("#is-count");
    var filter = "all";
    var CAP = 300;

    function card(it) {
      var name = it.i
        ? '<a class="is-name" href="https://www.ffxiah.com/item/' + it.i +
          '" target="_blank" rel="noopener">' + esc(it.n) + "</a>"
        : '<span class="is-name">' + esc(it.n) + "</span>";
      var h = '<div class="is-card">' + name;
      if (it.d && it.d.length) {
        h += '<div class="is-lbl">Drops from</div>';
        h += it.d.map(function (d) {
          return '<div class="is-row"><span class="is-mob">' + esc(d.mob) +
            '</span><span class="is-sep">·</span><span class="is-zone">' +
            esc(d.zone) + '</span><span class="is-pct ' + pctClass(d.pct) + '">' +
            Math.round(d.pct) + "%</span></div>";
        }).join("");
      } else {
        h += '<div class="is-row is-muted">Not a mob drop (vendor / craft / quest)</div>';
      }
      if (it.u && it.u.length) {
        h += '<div class="is-lbl">Used for</div><div class="is-chips">' +
          it.u.map(function (u) { return '<span class="is-chip">' + esc(u) + "</span>"; }).join("") +
          "</div>";
      }
      return h + "</div>";
    }

    function render() {
      var t = q.value.trim().toLowerCase();
      var rows = items.filter(function (it) { return it.n.toLowerCase().indexOf(t) !== -1; });
      if (filter === "drops") rows = rows.filter(function (it) { return it.d && it.d.length; });
      if (filter === "uses") rows = rows.filter(function (it) { return it.u && it.u.length; });
      count.textContent = rows.length + " of " + items.length;
      if (!rows.length) { results.innerHTML = '<div class="is-none">No items match.</div>'; return; }
      var shown = rows.slice(0, CAP);
      results.innerHTML = shown.map(card).join("") +
        (rows.length > shown.length
          ? '<div class="is-none">Showing the first ' + CAP + " of " + rows.length +
            " — refine your search to see more.</div>"
          : "");
    }

    q.addEventListener("input", render);
    Array.prototype.forEach.call(mount.querySelectorAll(".is-btn"), function (b) {
      b.addEventListener("click", function () {
        filter = b.getAttribute("data-f");
        Array.prototype.forEach.call(mount.querySelectorAll(".is-btn"), function (x) {
          x.classList.toggle("is-active", x === b);
        });
        render();
      });
    });
    render();
  }
})();
