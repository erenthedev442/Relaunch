/* Leaderboard page enhancements:
 *  1. wrapBoards — groups each h3+blurb+table inside .lb-grid into .lb-board cards
 *  2. applyMedals — adds gold/silver/bronze row classes from rank-column emoji
 */
(function () {
    "use strict";

    var MEDALS = { "🥇": "lb-gold", "🥈": "lb-silver", "🥉": "lb-bronze" };

    function wrapBoards() {
        document.querySelectorAll(".md-typeset .lb-grid").forEach(function (grid) {
            var nodes = Array.from(grid.childNodes);
            var boards = [];
            var cur = null;

            nodes.forEach(function (node) {
                if (node.nodeType === 1 && node.tagName === "H3") {
                    cur = document.createElement("div");
                    cur.className = "lb-board";
                    boards.push(cur);
                }
                if (cur) cur.appendChild(node);
            });

            boards.forEach(function (board) { grid.appendChild(board); });
        });
    }

    function applyMedals() {
        document.querySelectorAll(".md-typeset table tbody tr").forEach(function (row) {
            var cell = row.cells && row.cells[0];
            if (!cell) return;
            var cls = MEDALS[cell.textContent.trim()];
            if (cls) row.classList.add(cls);
        });
    }

    function init() {
        if (!document.querySelector("nav.lb-nav")) return;
        wrapBoards();
        applyMedals();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
}());
