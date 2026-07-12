/* BG-Wiki item hover/tap preview --------------------------------------
 *
 * Picks up any <a class="item-link" data-img="..."> emitted by the
 * docgen generators and shows the linked image as a floating tooltip.
 *
 * Behavior:
 *   - Desktop (hover capable): hover the item name -> image floats
 *     just below the link. Click still opens the BG-Wiki article in a
 *     new tab.
 *   - Touch (no hover): tap toggles the preview. Clicking again or
 *     tapping outside dismisses. Long-press / second tap or the link
 *     itself (after first tap dismisses preview) opens BG-Wiki.
 *
 * Fails silently if the image 404s — the tooltip just hides itself.
 */
(function () {
    "use strict";

    var tooltip = null;
    var hideTimer = null;
    var currentLink = null;
    var isTouch = matchMedia("(hover: none)").matches;

    function ensureTooltip() {
        if (!tooltip) {
            tooltip = document.createElement("div");
            tooltip.id = "item-tooltip";
            document.body.appendChild(tooltip);
        }
        return tooltip;
    }

    function positionTooltip(tip, anchor) {
        // Measure after rendering so we know its real size.
        tip.style.top = "0px";
        tip.style.left = "0px";
        tip.style.display = "block";

        var rect = anchor.getBoundingClientRect();
        var tipRect = tip.getBoundingClientRect();
        var scrollY = window.pageYOffset || document.documentElement.scrollTop;
        var scrollX = window.pageXOffset || document.documentElement.scrollLeft;
        var vpW = document.documentElement.clientWidth;
        var vpH = document.documentElement.clientHeight;

        var top = rect.bottom + scrollY + 6;
        var left = rect.left + scrollX;

        // Clamp horizontally
        if (left + tipRect.width > scrollX + vpW - 8) {
            left = scrollX + vpW - tipRect.width - 8;
        }
        if (left < scrollX + 4) left = scrollX + 4;

        // If it would overflow the bottom of the viewport, show above
        if (rect.bottom + tipRect.height + 12 > vpH) {
            top = rect.top + scrollY - tipRect.height - 6;
            if (top < scrollY + 4) {
                top = scrollY + 4;
            }
        }

        tip.style.top = top + "px";
        tip.style.left = left + "px";
    }

    function showFor(link) {
        var url = link.getAttribute("data-img");
        if (!url) return;
        clearTimeout(hideTimer);

        var tip = ensureTooltip();
        currentLink = link;

        // Build/refresh image
        tip.innerHTML = "";
        tip.classList.add("is-loading");

        var img = new Image();
        img.alt = link.textContent;
        img.onload = function () {
            if (currentLink !== link) return; // user moved on already
            tip.classList.remove("is-loading");
            tip.innerHTML = "";
            tip.appendChild(img);
            positionTooltip(tip, link);
        };
        img.onerror = function () {
            // Silent fail — hide the tooltip and forget.
            if (currentLink !== link) return;
            tip.classList.remove("is-loading");
            tip.style.display = "none";
            tip.innerHTML = "";
        };
        img.src = url;

        // Position the loading state immediately so it doesn't jump.
        positionTooltip(tip, link);
    }

    function hide() {
        if (!tooltip) return;
        tooltip.style.display = "none";
        tooltip.innerHTML = "";
        tooltip.classList.remove("is-loading");
        currentLink = null;
    }

    function scheduleHide() {
        clearTimeout(hideTimer);
        hideTimer = setTimeout(hide, 120);
    }

    // mouseover / mouseout bubble; mouseenter / mouseleave do not.
    document.addEventListener("mouseover", function (e) {
        var link = e.target && e.target.closest ? e.target.closest(".item-link") : null;
        if (!link) return;
        showFor(link);
    });

    document.addEventListener("mouseout", function (e) {
        var link = e.target && e.target.closest ? e.target.closest(".item-link") : null;
        if (!link) return;
        // Don't hide if we're moving into a child of the same link.
        if (e.relatedTarget && link.contains(e.relatedTarget)) return;
        scheduleHide();
    });

    // Touch: tap-toggle. On the first tap, show preview and suppress
    // navigation. Tap-outside or tap-tooltip dismisses.
    document.addEventListener(
        "click",
        function (e) {
            var link = e.target && e.target.closest ? e.target.closest(".item-link") : null;

            if (link && isTouch) {
                // No preview image -> nothing to toggle; swallowing the tap
                // would make the link permanently dead. Just navigate.
                if (!link.getAttribute("data-img")) {
                    return;
                }
                // First tap shows; second tap on same link opens the article.
                if (currentLink === link && tooltip && tooltip.style.display === "block") {
                    // Let the click navigate
                    return;
                }
                e.preventDefault();
                showFor(link);
                return;
            }

            // Tap outside -> dismiss
            if (
                tooltip &&
                tooltip.style.display === "block" &&
                !(e.target.closest && e.target.closest("#item-tooltip"))
            ) {
                hide();
            }
        },
        false
    );

    // Keep tooltip visible when the mouse moves over it (so a user can
    // scroll/inspect a large image on desktop). Touch already handles
    // this via pointer-events: auto in the CSS.
    document.addEventListener("mouseover", function (e) {
        if (e.target && e.target.closest && e.target.closest("#item-tooltip")) {
            clearTimeout(hideTimer);
        }
    });
    document.addEventListener("mouseout", function (e) {
        if (!e.target || !e.target.closest) return;
        if (e.target.closest("#item-tooltip")) {
            // Only hide if leaving the tooltip entirely
            if (e.relatedTarget && tooltip && tooltip.contains(e.relatedTarget)) return;
            scheduleHide();
        }
    });

    // Hide on scroll/resize to avoid weird positioning artifacts.
    window.addEventListener("scroll", hide, { passive: true });
    window.addEventListener("resize", hide);
})();
