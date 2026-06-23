/* Milestone-grid: wraps H2/H3/H4 + following content into .milestone-card
 * divs inside any .milestone-grid container, so generators can emit flat
 * markdown sections and CSS grid handles the horizontal layout.
 *
 * Used on: achievements, hunters-guild (hunt targets), prestige (AP table).
 */
(function () {
    "use strict";

    function wrapCards() {
        document.querySelectorAll(".md-typeset .milestone-grid").forEach(function (grid) {
            var children = Array.from(grid.children);
            var groups   = [];
            var cur      = null;

            children.forEach(function (node) {
                var tag = node.tagName;
                if (tag === "H2" || tag === "H3" || tag === "H4") {
                    if (cur) groups.push(cur);
                    cur = [node];
                    return;
                }
                if (tag === "HR") return; // hrules act as separators — discard
                if (cur) cur.push(node);
            });
            if (cur && cur.length) groups.push(cur);
            if (!groups.length) return;

            // Detach all children from grid (nodes stay live in JS memory)
            while (grid.firstChild) grid.removeChild(grid.firstChild);

            // Re-attach inside .milestone-card wrappers
            groups.forEach(function (nodeList) {
                var card = document.createElement("div");
                card.className = "milestone-card";
                nodeList.forEach(function (n) { card.appendChild(n); });
                grid.appendChild(card);
            });
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", wrapCards);
    } else {
        wrapCards();
    }
}());
