/* Live server-status badge ------------------------------------------------
 *
 * Polls a small JSON document published by the status-bridge
 * (see tools/status-bridge/) and updates the badge in the announcement
 * bar. The JSON shape is:
 *
 *     { "up": true, "online": 23, "updated": "2026-05-30T19:40:00Z" }
 *
 * States rendered:
 *   - up:true            -> green dot, "Online — N players"
 *   - up:false           -> red dot,   "Server offline"
 *   - stale / fetch fail  -> grey dot,  "Server status unavailable"
 *
 * Fails silently: any network/parse error leaves a neutral badge rather
 * than a broken one.
 */
(function () {
    "use strict";

    /* ===================================================================
     * CONFIG — after you create the gist, paste its RAW url here.
     * Example:
     *   https://gist.githubusercontent.com/richardknutzjr/<GIST_ID>/raw/status.json
     * (Setup steps: tools/status-bridge/README.md)
     * =================================================================== */
    var STATUS_URL = "__STATUS_JSON_URL__";

    var POLL_MS = 60000; // refresh cadence (matches the API's 60s cache)
    var STALE_MS = 5 * 60000; // if 'updated' is older than this, treat as unavailable
    /* =================================================================== */

    function badge() {
        return document.getElementById("server-status");
    }

    function setState(node, state, text) {
        if (!node) return;
        node.classList.remove(
            "server-status--loading",
            "server-status--up",
            "server-status--down",
            "server-status--unknown"
        );
        node.classList.add("server-status--" + state);
        var label = node.querySelector(".server-status__text");
        if (label) label.textContent = text;
    }

    function render(node, data) {
        // A stale file means the bridge stopped publishing — don't trust it.
        var updatedMs = data && data.updated ? Date.parse(data.updated) : NaN;
        if (!isNaN(updatedMs) && Date.now() - updatedMs > STALE_MS) {
            setState(node, "unknown", "Server status unavailable");
            return;
        }

        if (data && data.up) {
            var n = typeof data.online === "number" ? data.online : 0;
            setState(node, "up", "Online — " + n + " player" + (n === 1 ? "" : "s"));
        } else {
            setState(node, "down", "Server offline");
        }
    }

    function poll() {
        var node = badge();
        if (!node) return;

        // Not configured yet (placeholder URL still in place): hide just the
        // status badge rather than a permanent "unavailable" label. The banner
        // itself stays visible -- it also carries the "Join us on Discord" CTA
        // (overrides/main.html), which must show regardless of status wiring.
        if (!STATUS_URL || STATUS_URL.indexOf("__STATUS_JSON_URL__") !== -1) {
            node.style.display = "none";
            return;
        }

        // Cache-buster: gist raw is fronted by a CDN; a unique query param
        // bypasses any stale cached copy so the badge stays near-live.
        var url = STATUS_URL + (STATUS_URL.indexOf("?") === -1 ? "?" : "&") + "_=" + Date.now();

        fetch(url, { cache: "no-store" })
            .then(function (r) {
                if (!r.ok) throw new Error("HTTP " + r.status);
                return r.json();
            })
            .then(function (data) {
                render(badge(), data);
            })
            .catch(function () {
                setState(badge(), "unknown", "Server status unavailable");
            });
    }

    function start() {
        if (!badge()) return;
        poll();
        setInterval(poll, POLL_MS);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", start);
    } else {
        start();
    }
})();
