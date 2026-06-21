"""Sync docs/economy/sparks-exchange.md with SparksExchange.lua.

Reads the four exchange types from xi.sparks_exchange (sp_rate/sp_tiers,
ac_rate/ac_tiers, jp_rate/jp_tiers, hm_rate/hm_tiers) and renders a combined
tiers table with all four currencies plus a "convert all" row for each.

Markers written:
  sparks-exchange-access  — NPC + zone line
  sparks-exchange-tiers   — full conversion table (Sparks + Accolades + JP)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import commafy


def _ints(text: str) -> list[int]:
    return [int(x) for x in re.findall(r"\d+", text)]


def _parse(text: str) -> dict:
    c: dict = {
        "sp_rate": 10,   "sp_tiers": [],
        "ac_rate": 100,  "ac_tiers": [],
        "jp_rate": 4000, "jp_tiers": [],
        "hm_rate": 1000, "hm_tiers": [],
    }

    # Find the xi.sparks_exchange = { ... } block
    m = re.search(r"xi\.sparks_exchange\s*=\s*\{", text)
    if not m:
        return c
    # Grab everything up to the closing brace (simple scan)
    block_start = m.end()
    depth = 1
    i = block_start
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    block = text[block_start:i - 1]

    for key in ("sp_rate", "ac_rate", "jp_rate", "hm_rate"):
        m2 = re.search(rf"\b{key}\s*=\s*(\d+)", block)
        if m2:
            c[key] = int(m2.group(1))

    for key in ("sp_tiers", "ac_tiers", "jp_tiers", "hm_tiers"):
        m2 = re.search(rf"\b{key}\s*=\s*\{{([^}}]*)\}}", block)
        if m2:
            c[key] = _ints(m2.group(1))

    return c


def _render_access(c: dict) -> str:
    return (
        "The **Eminence Broker** stands in the economy corner of **GM Home**, in the "
        "row of gil-service NPCs. Talk to him to convert Sparks of Eminence, Unity "
        "Accolades, Job Points, or Hunting Marks into gil."
    )


def _render_tiers(c: dict) -> str:
    rows = [
        "### Sparks of Eminence",
        "",
        f"**{commafy(c['sp_rate'])} gil** per Spark.",
        "",
        "| Sparks | You receive |",
        "|---|---|",
    ]
    for amt in c["sp_tiers"]:
        rows.append(f"| {commafy(amt)} | {commafy(amt * c['sp_rate'])} gil |")
    rows.append(f"| **All your sparks** | balance × {commafy(c['sp_rate'])} gil |")

    rows += [
        "",
        "### Unity Accolades",
        "",
        f"**{commafy(c['ac_rate'])} gil** per Accolade.",
        "",
        "| Accolades | You receive |",
        "|---|---|",
    ]
    for amt in c["ac_tiers"]:
        rows.append(f"| {commafy(amt)} | {commafy(amt * c['ac_rate'])} gil |")
    rows.append(f"| **All your accolades** | balance × {commafy(c['ac_rate'])} gil |")

    rows += [
        "",
        "### Job Points",
        "",
        f"**{commafy(c['jp_rate'])} gil** per Job Point.",
        "",
        "| Job Points | You receive |",
        "|---|---|",
    ]
    for amt in c["jp_tiers"]:
        rows.append(f"| {commafy(amt)} | {commafy(amt * c['jp_rate'])} gil |")
    rows.append(f"| **All your JP** | balance × {commafy(c['jp_rate'])} gil |")

    rows += [
        "",
        "### Hunting Marks",
        "",
        f"**{commafy(c['hm_rate'])} gil** per Hunt Mark.",
        "",
        "| Hunt Marks | You receive |",
        "|---|---|",
    ]
    for amt in c["hm_tiers"]:
        rows.append(f"| {commafy(amt)} | {commafy(amt * c['hm_rate'])} gil |")
    rows.append(f"| **All your marks** | balance × {commafy(c['hm_rate'])} gil |")

    return "\n".join(rows)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/SparksExchange.lua")
    if src is None:
        print("[sparks_exchange] skip: SparksExchange.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "sparks-exchange.md"
    rate_summary = (
        f"Sparks: **{commafy(c['sp_rate'])} gil** each · "
        f"Accolades: **{commafy(c['ac_rate'])} gil** each · "
        f"Job Points: **{commafy(c['jp_rate'])} gil** each · "
        f"Hunt Marks: **{commafy(c['hm_rate'])} gil** each"
    )
    blocks = [
        ("sparks-exchange-access", _render_access(c)),
        ("sparks-exchange-rate", rate_summary),
        ("sparks-exchange-tiers", _render_tiers(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[sparks_exchange] {written}/{len(blocks)} marker block(s) written "  # noqa: E501
          f"(sp={c['sp_rate']}g/{len(c['sp_tiers'])} tiers, "
          f"ac={c['ac_rate']}g/{len(c['ac_tiers'])} tiers, "
          f"jp={c['jp_rate']}g/{len(c['jp_tiers'])} tiers, "
          f"hm={c['hm_rate']}g/{len(c['hm_tiers'])} tiers)")
