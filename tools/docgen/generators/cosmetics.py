"""Sync docs/economy/cosmetic-boutique.md with cosmetic_shop_catalog.lua.

Reads the daily-rotating Boutique Moogle's cosmetic pool (id/name/price, grouped
by the catalog's ``-- === THEME ===`` comments) and renders a themed table of
every cosmetic with an FFXIAH item link + hover icon, so players can browse the
whole rotation and see what's coming.

Markers written:
  cosmetic-catalog  — themed table of every rotating cosmetic
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item


# `-- === Theme Name (optional notes) ===` group header in the catalog.
_THEME_RE = re.compile(r"^\s*--\s*=+\s*(.+?)\s*=+\s*$")
# `{ id = 11316, name = 'Otokogusa Yukata', price = 15000 }` -- name may be
# single- OR double-quoted (e.g. "Lord's Yukata"), so capture the quote char.
_ITEM_RE = re.compile(
    r"\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*(['\"])(.*?)\2\s*,\s*price\s*=\s*(\d+)"
)


def _parse(text: str) -> list[tuple[str, list[tuple[int, str, int]]]]:
    """Walk the catalog tracking the most recent `=== Theme ===` header.
    Returns [(theme, [(id, name, price), ...]), ...] in source order."""
    bucket: dict[str, list[tuple[int, str, int]]] = {}
    order: list[str] = []
    current = "Cosmetics"

    for line in text.splitlines():
        h = _THEME_RE.match(line)
        if h:
            current = h.group(1).strip()
            continue
        m = _ITEM_RE.search(line)
        if m:
            if current not in bucket:
                bucket[current] = []
                order.append(current)
            bucket[current].append((int(m.group(1)), m.group(3), int(m.group(4))))

    return [(theme, bucket[theme]) for theme in order]


def _item_link(name: str, item_id: int) -> str:
    page_url, image_url = urls_for_item(name, None, item_id)
    img = f' data-img="{image_url}"' if image_url else ""
    return (
        f'<a class="item-link" href="{page_url}"{img} '
        f'target="_blank" rel="noopener">{name}</a>'
    )


def _fmt_an(price: int) -> str:
    if price >= 1000 and price % 1000 == 0:
        return f"{price // 1000}k AN"
    return f"{price:,} AN"


def _render(groups) -> str:
    total = sum(len(items) for _, items in groups)
    lines: list[str] = [
        f"_The **Boutique Moogle** at GM Home features **one** of these {total} "
        f"cosmetics per day (rotating, resets 00:00 UTC). Pure appearance — "
        f"**no combat stats**. Paid in **Allied Notes**, earned in (S) zones. "
        f"Hover an item for its icon, or click through to FFXIAH for the full look._",
        "",
    ]
    for theme, items in groups:
        if not items:
            continue
        lines.append(f"### {theme}")
        lines.append("")
        lines.append("| Cosmetic | Price |")
        lines.append("|---|---:|")
        for iid, name, price in items:
            lines.append(f"| {_item_link(name, iid)} | {_fmt_an(price)} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/cosmetic_shop_catalog.lua")
    if src is None:
        print("[cosmetics] skip: cosmetic_shop_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    groups = _parse(text)
    total = sum(len(items) for _, items in groups)
    if total == 0:
        print("[cosmetics] skip: no items parsed (catalog format changed?)")
        return

    page = docs_dir / "economy" / "cosmetic-boutique.md"
    wrote = write_between_markers(page, "cosmetic-catalog", _render(groups))
    if wrote:
        print(f"[cosmetics] cosmetic-catalog: {total} cosmetics across {len(groups)} themes")
    else:
        print(f"[cosmetics] skipped (markers not found in {page.name})")
