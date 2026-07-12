"""Sync docs/economy/gil-exchange.md with gil_exchange_npc.lua.

The Gil Exchange converts spare gil into Hunt Marks at deliberately poor rates.
Its config lives inline in a `local config = { ... }` table; the bundle list is a
`bundles = { { gil = .., marks = .. }, ... }` array. We slice that block out and
read each bundle's `gil` cost and `marks` payout straight from the structured
fields (the inline `label` strings are an internal menu detail, not used here).

Markers written:
  gil-exchange-access   — NPC + zone line
  gil-exchange-bundles  — the gil -> marks bundle table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _parse(text: str) -> dict:
    c: dict = {"name": "Gil Exchange", "bundles": []}

    config = section(text, "config")

    m = re.search(r"npcName\s*=\s*'([^']+)'", config)
    if m:
        c["name"] = m.group(1)

    # Each bundle is `{ gil = N, marks = N, ... }`; pull the two numbers in order.
    bundles = section(config, "bundles")
    for entry in re.findall(r"\{[^}]*\}", bundles):
        g = re.search(r"gil\s*=\s*(\d+)", entry)
        mk = re.search(r"marks\s*=\s*(\d+)", entry)
        if g and mk:
            c["bundles"].append((int(g.group(1)), int(mk.group(1))))

    return c


def _short_gil(n: int) -> str:
    """1000000 -> '1M', 100000 -> '100k' (readable bundle sizes)."""
    if n >= 1_000_000 and n % 1_000_000 == 0:
        return f"{n // 1_000_000}M"
    if n >= 1_000 and n % 1_000 == 0:
        return f"{n // 1_000}k"
    return commafy(n)


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (
        f"The **{c['name']}** is in the economy row at **{{{{npc:gil_exchange}}}}** (`!hub`). Speak to "
        f"it to open the menu — your current gil shows at the top, and your Hunt "
        f"Mark total is confirmed after each trade."
    )


def _render_bundles(c: dict) -> str:
    rows = [
        "| You pay | You receive | Rate |",
        "|---|---|---|",
    ]
    for gil, marks in c["bundles"]:
        per = round(gil / marks) if marks else 0
        rows.append(
            f"| {_short_gil(gil)} gil | {commafy(marks)} Hunt Mark"
            f"{'s' if marks != 1 else ''} | {commafy(per)} gil each |"
        )
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gil_exchange_npc.lua")
    if src is None:
        print("[gil_exchange] skip: gil_exchange_npc.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "gil-exchange.md"
    blocks = [
        ("gil-exchange-access", _render_access(c)),
        ("gil-exchange-bundles", _render_bundles(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[gil_exchange] {written}/{len(blocks)} marker block(s) written "
          f"(bundles={len(c['bundles'])})")
