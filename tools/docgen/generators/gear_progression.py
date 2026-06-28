"""Sync docs/progression/gear-progression.md with gear_progression_catalog.lua.

The Gear Progression vendor in Escha ZiTah sells weapons across three
medal tiers (Bronze / Silver / Gold). Each tier covers a spread of weapon
categories, every weapon has a flat medal price and a job list. The catalog is
large (3 tiers x 14 categories x many weapons), so this generator *summarises*
it — per tier: how many categories, a few example weapons, the medal currency,
and the per-weapon cost — rather than dumping every line.

Markers written:
  gear-progression-access    — vendor + zone line
  gear-progression-currency  — the three medal currencies
  gear-progression-tiers     — compact tier-overview table (categories + cost)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# Tier order in the catalog; `infamy` is an inert trailing tier (the vendor only
# sells bronze/silver/gold) but we use its marker as the gold slab's end-cap.
_TIER_KEYS = ["bronze", "silver", "gold", "infamy"]
_SOLD_TIERS = ["bronze", "silver", "gold"]

_QUOTED_NAME = re.compile(r"name\s*=\s*(['\"])(.*?)\1")
_CAT_HEADER = re.compile(r"local\s+\w+\s*=\s*cat\([^,]+,\s*'([^']+)'\)")


def _quoted(pattern: str, text: str, default: str = "") -> str:
    """First capture of `pattern` (which must wrap its value in group 1), or default."""
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _slab(text: str, tier: str) -> str:
    """The body between `catalog.<tier> = { weapons` and the next tier marker.

    The weapon rows live in a `do ... end` block *after* the table literal
    (they're appended with table.insert), so a brace-balanced `section()` of the
    literal misses them. Slicing tier-marker to tier-marker captures the rows.
    """
    start = re.search(r"catalog\." + tier + r"\s*=\s*\{\s*weapons", text)
    if not start:
        return ""
    ends = []
    for other in _TIER_KEYS:
        m = re.search(r"catalog\." + other + r"\s*=\s*\{\s*weapons", text)
        if m and m.start() > start.start():
            ends.append(m.start())
    end = min(ends) if ends else len(text)
    return text[start.end():end]


def _clean_name(name: str) -> str:
    """Tidy an auto-generated display name for a public page.

    The scorer emits names like 'Mandau 119 Iii' / 'Verethragna 119 Iii' — strip
    the trailing internal version suffix so examples read like weapon names.
    """
    name = re.sub(r"\s+119(\s+I+i*)?\s*$", "", name, flags=re.IGNORECASE)
    return name.strip()


def _parse(text: str) -> dict:
    c: dict = {}

    # Medal currencies (names only — IDs stay out of player docs).
    seals = section(text, "catalog.seals")
    c["medals"] = {}
    for key in ("bronze", "silver", "gold"):
        c["medals"][key] = _quoted(
            key + r"\s*=\s*\{[^}]*name\s*=\s*['\"]([^'\"]+)['\"]", seals,
            {"bronze": "Beastmens Medal",
             "silver": "Kindreds Medal",
             "gold": "Demons Medal"}[key])

    # Per-tier summary.
    c["tiers"] = []
    for tier in _SOLD_TIERS:
        slab = _slab(text, tier)
        cats = _CAT_HEADER.findall(slab)
        names = [_clean_name(n) for _, n in _QUOTED_NAME.findall(slab)]
        costs = [int(x) for x in re.findall(r"cost\s*=\s*(\d+)", slab)]
        c["tiers"].append({
            "key": tier,
            "label": tier.capitalize(),
            "medal": c["medals"][tier],
            "categories": len(cats),
            "weapons": len(names),
            "cost_lo": min(costs) if costs else 0,
            "cost_hi": max(costs) if costs else 0,
            "examples": names[:3],
        })
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("The **Gear Progression** vendor stands in **Escha ZiTah** — the "
            "hub all five hunting ranks lead back to. Bring the medals you earn "
            "from content, pick a tier, then a weapon category, and trade up.")


def _render_currency(c: dict) -> str:
    m = c["medals"]
    return (
        "Each tier is bought with its own medal — the rarer the medal, the "
        "stronger the weapons it unlocks:\n\n"
        f"- **Bronze** weapons cost **{m['bronze']}s**\n"
        f"- **Silver** weapons cost **{m['silver']}s**\n"
        f"- **Gold** weapons cost **{m['gold']}s**\n\n"
        "Medals are earned from hunting-league content — there's no gil price "
        "here, only the medals you've banked."
    )


def _cost_cell(t: dict) -> str:
    if t["cost_lo"] == t["cost_hi"]:
        return f"{commafy(t['cost_lo'])} {t['medal']}s each"
    return f"{commafy(t['cost_lo'])}–{commafy(t['cost_hi'])} {t['medal']}s each"


def _render_tiers(c: dict) -> str:
    rows = [
        "| Tier | Weapon categories | Cost (per weapon) | Example weapons |",
        "|---|---|---|---|",
    ]
    for t in c["tiers"]:
        ex = ", ".join(t["examples"]) if t["examples"] else "—"
        rows.append(
            f"| **{t['label']}** | {t['categories']} categories"
            f" ({t['weapons']} weapons) | {_cost_cell(t)} | {ex} |"
        )
    rows.append("")
    rows.append(
        "Each tier spreads its weapons across the major categories — swords, "
        "daggers, clubs, staves, great swords, axes, scythes, polearms, bows, "
        "guns, hand-to-hand and more — so almost every job has something to aim "
        "for. **Every weapon lists the jobs that can wield it**, and the menu only "
        "shows categories that actually have stock."
    )
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gear_progression_catalog.lua")
    if src is None:
        print("[gear-progression] skip: gear_progression_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "gear-progression.md"
    blocks = [
        ("gear-progression-access", _render_access(c)),
        ("gear-progression-currency", _render_currency(c)),
        ("gear-progression-tiers", _render_tiers(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    total_weapons = sum(t["weapons"] for t in c["tiers"])
    print(f"[gear-progression] {written}/{len(blocks)} marker block(s) written "
          f"(tiers={len(c['tiers'])}, weapons={total_weapons})")
