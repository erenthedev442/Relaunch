"""Sync docs/progression/title-vendor.md with gil_title_vendor_catalog.lua.

The Title Broker in the Celennia Memorial Library sells cosmetic character titles for gil across four
price tiers. The NPC name, the four tier labels + gil costs, and the title
labels in each tier all come from the catalog, so re-pricing a tier or swapping
a title updates the published page.

Markers written:
  title-vendor-access  — NPC + zone line
  title-vendor-tiers   — the four price tiers with their titles
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy

# A Lua string literal in either quote style: group 1 is the quote, group 2 the
# value. The `\1` backreference closes on the SAME quote that opened, so an
# apostrophe inside a double-quoted string survives (e.g. "Behemoth's Bane").
_QSTR = r"(['\"])(.*?)\1"


def _top_level_blocks(block: str) -> list[str]:
    """Each top-level `{ ... }` entry inside `block`'s outermost braces."""
    body = block[block.find("{") + 1: block.rfind("}")]
    out: list[str] = []
    depth, start = 0, None
    for i, ch in enumerate(body):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                out.append(body[start:i + 1])
    return out


def _parse(text: str) -> dict:
    c: dict = {}

    m = re.search(r"catalog\.npcName\s*=\s*['\"]([^'\"]+)['\"]", text)
    c["npc"] = m.group(1) if m else "Title Broker"

    tiers_block = section(text, "catalog.tiers")
    c["tiers"] = []
    for entry in _top_level_blocks(tiers_block):
        label_m = re.search(r"label\s*=\s*" + _QSTR, entry)
        cost_m = re.search(r"cost\s*=\s*(\d+)", entry)
        # Every `label = '...'` in the entry: the first is the tier label, the
        # rest are the individual title labels.
        labels = [g2 for _, g2 in re.findall(r"label\s*=\s*" + _QSTR, entry)]
        c["tiers"].append({
            "label": label_m.group(2) if label_m else "",
            "cost": int(cost_m.group(1)) if cost_m else 0,
            "titles": labels[1:],
        })
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (f"The **{c['npc']}** is set up in **the Celennia Memorial Library** (reach it with `!lib`). "
            f"Talk to them, pick a price tier, then the title you want — pay the "
            f"gil and it's yours to wear.")


def _tier_name(label: str) -> str:
    """'Cheap (10k)' -> 'Cheap'. The price is shown separately."""
    return re.sub(r"\s*\(.*?\)\s*$", "", label).strip()


def _render_tiers(c: dict) -> str:
    out: list[str] = []
    for t in c["tiers"]:
        name = _tier_name(t["label"])
        titles = ", ".join(t["titles"]) if t["titles"] else "—"
        out.append(
            f"### {name} — {commafy(t['cost'])} gil\n\n"
            f"{len(t['titles'])} titles: {titles}"
        )
    return "\n\n".join(out)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gil_title_vendor_catalog.lua")
    if src is None:
        print("[title-vendor] skip: gil_title_vendor_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "title-vendor.md"
    blocks = [
        ("title-vendor-access", _render_access(c)),
        ("title-vendor-tiers", _render_tiers(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    total_titles = sum(len(t["titles"]) for t in c["tiers"])
    print(f"[title-vendor] {written}/{len(blocks)} marker block(s) written "
          f"(tiers={len(c['tiers'])}, titles={total_titles})")
