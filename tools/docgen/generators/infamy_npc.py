"""Generate the Infamy Vendor section inside docs/progression/gear-vendors.md.

Reads ``modules/custom/lua/infamy_vendor_catalog.lua`` -- the catalog the live
Infamy Vendor NPC actually uses -- and fills the "infamy-vendor" marker block
with two tables:

  * Curated picks  -- catalog.vendorItems (hand-listed relic weapons, bard
                      instruments, and other special weapons).
  * Best-in-slot   -- catalog.vendorItemsAuto (top gear auto-promoted from the
                      scored catalogs by tools/build_infamy_top_picks.py, plus
                      the Sortie JSE +2 earrings).

The Infamy Vendor no longer sells +4 armor: the "+4 Reforge" menu was removed
(the +4 tier is now an earned upgrade at the Dynamis-Divergence Forge, not a
direct Infamy buy). The catalog's ``plus4Sets`` data is left in place for a
possible revert but is intentionally NOT documented as buyable here.

Reuses ``dungeons._extract_vendor_items_block`` so this can't drift from the
parser ``item_index`` uses on the same catalog. The catalog is normally
gitignored (live-only), so this runs against ``$LEGENDARY_LIVE_ROOT`` and skips
cleanly when no source resolves (or parses to zero rows).

Marker ID: "infamy-vendor"
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item
from tools.docgen.generators import dungeons

# infamy_vendor_catalog.lua names its currency CharVar `currencyCv = 'Infamy'`
# (not the `currencyName` the dungeon catalog uses), so parse that and fall back
# to "Infamy".
_CURRENCY_CV_RE = re.compile(r"\bcurrencyCv\s*=\s*['\"]([^'\"]+)['\"]")
# The auto block's first stats line is an internal balance score
# (e.g. "CASTER score 1060") -- not player-facing, so it's dropped from Notes.
_SCORE_RE = re.compile(r"\bscore\s+\d+\b")


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str) -> str:
    """BG-Wiki link with a data-img tooltip, matching the other vendor tables."""
    page_url, image_url = urls_for_item(name, None)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">'
        f'{_escape_md(name)}</a>'
    )


def _notes(stats: list[str]) -> str:
    keep = [s for s in stats if not _SCORE_RE.search(s)]
    return _escape_md(" · ".join(keep))


def _render_table(items: list[dict]) -> list[str]:
    lines = ["| Item | Cost | Notes |", "|---|---:|---|"]
    for it in items:
        lines.append(
            f"| {_item_link(it['name'])} | {it['cost']} | {_notes(it.get('stats') or [])} |"
        )
    return lines


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/infamy_vendor_catalog.lua")
    if src is None:
        print("[infamy_npc] skip: infamy_vendor_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    cm = _CURRENCY_CV_RE.search(text)
    currency = cm.group(1) if cm else "Infamy"

    curated = dungeons._extract_vendor_items_block(text, "catalog.vendorItems")
    auto = dungeons._extract_vendor_items_block(text, "catalog.vendorItemsAuto")

    if not (curated or auto):
        print("[infamy_npc] 0 items parsed; leaving page untouched (parser drift?)")
        return

    lines: list[str] = []
    lines.append(
        f"The **Infamy Vendor** stands at **Leafallia** (`!leaf`) and is paid in **{currency}**, "
        f"earned from endgame content -- Abyssea NM hunts, Invasions, and the weekly "
        f"Raid. It is a hand-curated **accessory shop** -- best-in-slot neck, ear, "
        f"ring, waist, and back pieces. Weapons and armor are no longer sold here; "
        f"they drop from the [Voidwatch](../endgame/voidwatch.md) NMs instead. All "
        f"costs below are in {currency}."
    )
    lines.append("")
    lines.append(
        "Looking for **+4 armor**? That's no longer bought here — the +4 tier is an "
        "earned upgrade at the [Dynamis-Divergence Forge](../endgame/dynamis-divergence.md) "
        "(trade a reforged +3 AF/Relic piece plus [D] materials). The Infamy Vendor "
        "sells accessories only."
    )
    lines.append("")

    if curated:
        lines.append("### Accessories")
        lines.append("")
        lines.append(
            f"_{len(curated)} hand-picked accessories -- neck, ear, ring, waist, and "
            f"back pieces._"
        )
        lines.append("")
        lines.extend(_render_table(curated))
        lines.append("")

    if auto:
        lines.append("### Best-in-slot (auto-promoted)")
        lines.append("")
        lines.append(
            f"_{len(auto)} top armor, weapons, and Sortie earrings, refreshed from "
            f"the live gear rankings._"
        )
        lines.append("")
        lines.extend(_render_table(auto))

    content = "\n".join(lines).rstrip()
    page = docs_dir / "progression" / "gear-vendors.md"
    if write_between_markers(page, "infamy-vendor", content):
        print(f"[infamy_npc] infamy-vendor: {len(curated)} curated + {len(auto)} auto items")
    else:
        print(f"[infamy_npc] infamy-vendor: markers not found in {page.name}")
