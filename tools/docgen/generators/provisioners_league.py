"""Sync docs/endgame/provisioners-league.md with provisioners_catalog.lua.

The League Steward's location, the point-scoring multipliers (fishing skill
divisor, big/legendary/featured multipliers, the per-craft-turn-in divisor),
and the five-rank ladder (label + lifetime threshold + cumulative mark bonus)
all come from the catalog, so re-tuning any of them updates the published page.

Markers written:
  provisioners-league-access   — League Steward + zone line
  provisioners-league-scoring  — how fishing & crafting points are earned
  provisioners-league-ranks    — the five-rank ladder table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str) -> dict:
    c: dict = {}

    sc = section(text, "catalog.scoring")
    c["skillDivisor"]  = int(_first(r"skillDivisor\s*=\s*(\d+)", sc, "10"))
    c["bigMult"]       = int(_first(r"bigMult\s*=\s*(\d+)", sc, "2"))
    c["legendaryMult"] = int(_first(r"legendaryMult\s*=\s*(\d+)", sc, "10"))
    c["featuredMult"]  = int(_first(r"featuredMult\s*=\s*(\d+)", sc, "3"))
    c["craftDivisor"]  = int(_first(r"craftDivisor\s*=\s*(\d+)", sc, "10"))

    # Ranks: ordered list of { points, label, bonusMarks }.
    ranks_block = section(text, "catalog.ranks")
    ranks = []
    for entry in re.findall(r"\{[^{}]*\}", ranks_block):
        label_m = re.search(r"label\s*=\s*'([^']+)'", entry)
        if not label_m:
            continue
        nums = {k: int(v) for k, v in re.findall(r"(points|bonusMarks)\s*=\s*(\d+)", entry)}
        ranks.append({
            "label": label_m.group(1),
            "points": nums.get("points", 0),
            "bonusMarks": nums.get("bonusMarks", 0),
        })
    c["ranks"] = ranks
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("Seek out the **League Steward** at **Reisenjima Henge** — he keeps the "
            "books for both anglers and crafters. Talk to him to check your rank, "
            "your League Point total, and this week's featured fish.")


def _render_scoring(c: dict) -> str:
    lines = [
        "There are two ways to earn **League Points**:",
        "",
        "**Fishing weigh-ins** — every fish you catch is worth points that scale "
        "with the fish's skill: the tougher the catch, the more it pays. On top of that:",
        "",
        f"- A **big fish** (the ruler-measured monsters) is worth **{c['bigMult']}×** points.",
        f"- A **legendary** catch is league gold — worth **{c['legendaryMult']}×** points.",
        f"- This week's **featured fish** pays a **{c['featuredMult']}×** bonus — a rotating "
        "target that keeps the weekly race fresh and is always something a normal angler can land.",
        "",
        "**Crafting turn-ins** — every high-quality (HQ) item you hand in at the "
        "server's Crafting Exchange also credits League Points alongside its usual "
        "reward, so your crafting progress counts here too.",
    ]
    return "\n".join(lines)


def _render_ranks(c: dict) -> str:
    rows = [
        "| Rank | League Points | Mark bonus |",
        "|---|---:|---:|",
    ]
    for r in c["ranks"]:
        pts = "—" if r["points"] == 0 else commafy(r["points"])
        bonus = "—" if r["bonusMarks"] == 0 else f"+{commafy(r['bonusMarks'])}"
        rows.append(f"| **{r['label']}** | {pts} | {bonus} |")
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/provisioners_catalog.lua")
    if src is None:
        print("[provisioners_league] skip: provisioners_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "provisioners-league.md"
    blocks = [
        ("provisioners-league-access", _render_access(c)),
        ("provisioners-league-scoring", _render_scoring(c)),
        ("provisioners-league-ranks", _render_ranks(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[provisioners_league] {written}/{len(blocks)} marker block(s) written "
          f"(ranks={len(c['ranks'])})")
