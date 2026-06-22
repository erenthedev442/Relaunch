/* Leaderboard page enhancements
 * Adds medal-row highlight classes after the DOM loads.
 * The rank column contains the literal emoji for positions 1-3;
 * we read that text and add the matching CSS class to the row.
 */
(function () {
    "use strict";

    var MEDALS = { "🥇": "lb-gold", "🥈": "lb-silver", "🥉": "lb-bronze" };

    function init() {
        if (!document.querySelector("nav.lb-nav")) return;   // not the leaderboards page

        document.querySelectorAll(".md-typeset table tbody tr").forEach(function (row) {
            var cell = row.cells && row.cells[0];
            if (!cell) return;
            var cls = MEDALS[cell.textContent.trim()];
            if (cls) row.classList.add(cls);
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
}());
