"""Sync docs/economy/sparks-exchange.md with SparksExchange.lua.

The Eminence Broker buys Sparks of Eminence for gil. Unlike the catalog-style
systems, this NPC keeps its config inline in a `local cfg = { ... }` table, so
we slice that block out (section) and pull the per-spark `rate`, the preset
`tiers`, and the display `name` from it. The gil value of each tier is *computed*
(tier * rate), so re-pricing the rate updates the published payouts.

Markers written:
  sparks-exchange-access  — NPC + zone line
  sparks-exchange-rate    — gil-per-spark rate
  sparks-exchange-tiers   — preset convert amounts -> gil + "convert all"
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _parse(text: str) -> dict:
    c: dict = {"name": "Sparks Cash", "rate": 10, "tiers": []}

    cfg = section(text, "cfg")

    m = re.search(r"rate\s*=\s*(\d+)", cfg)
    if m:
        c["rate"] = int(m.group(1))

    m = re.search(r"tiers\s*=\s*\{([^}]*)\}", cfg)
    if m:
        c["tiers"] = ints(m.group(1))

    m = re.search(r"name\s*=\s*'([^']+)'", cfg)
    if m:
        c["name"] = m.group(1)

    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (
        f"The **Eminence Broker** — shown as **\"{c['name']}\"** — stands in the "
        f"economy corner of **GM Home**, in the row of gil-service NPCs. Talk to "
        f"him and the menu opens with your current spark balance up top."
    )


def _render_rate(c: dict) -> str:
    return (
        f"Every Spark of Eminence is worth **{commafy(c['rate'])} gil**. Sparks cap "
        f"out fast through Records of Eminence, so a full balance cashes out to a "
        f"tidy lump of gil — a reliable way to keep your purse topped up once "
        f"there's nothing left to spend sparks on."
    )


def _render_tiers(c: dict) -> str:
    rate = c["rate"]
    rows = [
        "| Sparks | You receive |",
        "|---|---|",
    ]
    for amt in c["tiers"]:
        rows.append(f"| {commafy(amt)} | {commafy(amt * rate)} gil |")
    rows.append("| **All your sparks** | balance × " + commafy(rate) + " gil |")
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/SparksExchange.lua")
    if src is None:
        print("[sparks_exchange] skip: SparksExchange.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "sparks-exchange.md"
    blocks = [
        ("sparks-exchange-access", _render_access(c)),
        ("sparks-exchange-rate", _render_rate(c)),
        ("sparks-exchange-tiers", _render_tiers(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[sparks_exchange] {written}/{len(blocks)} marker block(s) written "
          f"(rate={c['rate']}, tiers={len(c['tiers'])})")
