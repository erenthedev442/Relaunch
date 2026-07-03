"""Sync docs/progression/weapon-forge.md with weapon_forge_catalog.lua.

Everything player-facing derives from the live catalog so the page
tracks tuning changes automatically:
  * catalog.chains      -> upgrade table (weapon type, jobs, 119I/II/III names)
  * catalog.costs       -> medal costs, HL rank gates, Reforge Mark cost
  * NPC position (hardcoded in WeaponForge_NPC.lua)

Markers written:
  weapon-forge-intro     -- what it is + NPC location
  weapon-forge-costs     -- cost table for both steps
  weapon-forge-chains    -- full 14-weapon upgrade table
  weapon-forge-tips      -- practical tips (dual-path note, GM bypass, etc.)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


# ---------------------------------------------------------------------------
# Parsing helpers

def _str(block: str, field: str) -> str:
    m = re.search(rf"{re.escape(field)}\s*=\s*'([^']*)'", block)
    if not m:
        m = re.search(rf'{re.escape(field)}\s*=\s*"([^"]*)"', block)
    return m.group(1) if m else ""


def _int(block: str, field: str) -> int:
    m = re.search(rf"{re.escape(field)}\s*=\s*(\d+)", block)
    return int(m.group(1)) if m else 0


def _parse(text: str) -> dict:
    # --- costs ---
    cost2_block = section(text, "toStage2")
    cost3_block = section(text, "toStage3")

    costs = {
        "to2": {
            "hl_rank":  _int(cost2_block, "hlRank"),
            "med_name": _str(cost2_block, "name"),
            "med_qty":  _int(cost2_block, "qty"),
        },
        "to3": {
            "hl_rank":       _int(cost3_block, "hlRank"),
            "med_name":      _str(cost3_block, "name"),
            "med_qty":       _int(cost3_block, "qty"),
            "reforge_marks": _int(cost3_block, "reforgeMarks"),
        },
    }

    # --- chains ---
    # Each chain block looks like:
    #   { type = '...', jobs = '...', s1 = { id = N, name = '...' }, ... }
    chains = []
    for m in re.finditer(
        r"\{\s*type\s*=\s*'([^']+)'\s*,\s*jobs\s*=\s*'([^']+)'[^}]*"
        r"s1\s*=\s*\{[^}]*name\s*=\s*'([^']+)'[^}]*\}"
        r"[^}]*s2\s*=\s*\{[^}]*name\s*=\s*'([^']+)'[^}]*\}"
        r"[^}]*s3\s*=\s*\{[^}]*name\s*=\s*'([^']+)'[^}]*\}",
        text, re.DOTALL,
    ):
        chains.append({
            "type": m.group(1),
            "jobs": m.group(2),
            "s1":   m.group(3),
            "s2":   m.group(4),
            "s3":   m.group(5),
        })

    return {"costs": costs, "chains": chains}


# ---------------------------------------------------------------------------
# Renderers

def _render_intro(c: dict) -> str:
    n = len(c["chains"])
    return (
        f"The **Weapon Forger** in **Leafallia** upgrades weapons through three "
        f"stages — 119I, 119II, and 119III — in the same style as retail FFXI's "
        f"Oboro reforging. Each step consumes your current weapon and the required "
        f"materials; nothing is lost until you confirm.\n\n"
        f"There are **{n} weapon-type chains**, one per weapon skill. "
        f"Start with a **119I weapon** from the Bronze vendor in Escha - Zi'Tah "
        f"and work your way up to a **Stage-5 Relic** (119III).\n\n"
        f"!!! tip \"How to find it\"\n"
        f"    The Weapon Forger stands next to the Relic Forge in "
        f"    **{{{{npc:weapon_forger}}}}** (`!leaf`). It auto-detects which "
        f"    upgradeable weapons you have — if you own a 119I or 119II "
        f"    weapon the menu entry appears automatically."
    )


def _render_costs(c: dict) -> str:
    co = c["costs"]
    t2, t3 = co["to2"], co["to3"]

    rank_labels = {
        1: "Rank I (Initiate)",
        2: "Rank II (Hunter)",
        3: "Rank III (Elite)",
        4: "Rank IV (Champion)",
        5: "Rank V (Legend)",
    }

    # Precompute the nested bits: f-strings can't contain backslash-escaped
    # quotes in their expression part (SyntaxError on the box's Python), so the
    # inner rank labels / marks clause are built as plain locals first.
    t2_rank = rank_labels.get(t2['hl_rank'], f"Rank {t2['hl_rank']}")
    t3_rank = rank_labels.get(t3['hl_rank'], f"Rank {t3['hl_rank']}")
    t3_marks = f" + {t3['reforge_marks']:,} Reforge Marks (any pool)" if t3.get('reforge_marks') else ""

    lines = [
        "| Step | Consume | Materials | Gate |",
        "|---|---|---|---|",
        f"| 119I → 119II | Your 119I weapon | "
        f"{t2['med_qty']}× {t2['med_name']} | "
        f"Hunting League {t2_rank} |",
        f"| 119II → 119III | Your 119II weapon | "
        f"{t3['med_qty']}× {t3['med_name']}"
        f"{t3_marks} | "
        f"Hunting League {t3_rank} |",
    ]
    lines += [
        "",
        "**Medals** come from the Hunt Seals NPC in Escha - Zi'Tah "
        "(same vendor as Hunt Marks). "
        "**Reforge Marks** are earned from Reforge NM kills in Gwora Corridor — "
        "your total across all three pools (AF, Relic, Empyrean) counts.",
    ]
    return "\n".join(lines)


def _render_chains(c: dict) -> str:
    lines = [
        f"All **{len(c['chains'])} weapon upgrade chains**. "
        "The 119I column names the Bronze-tier weapon you start with; "
        "the 119III column is the Stage-5 Relic at the end of the path.",
        "",
        "| Weapon type | Jobs | 119I (start) | 119II (forge) | 119III (Relic) |",
        "|---|---|---|---|---|",
    ]
    for ch in c["chains"]:
        lines.append(
            f"| {ch['type']} | {ch['jobs']} "
            f"| {ch['s1']} | {ch['s2']} | **{ch['s3']}** |"
        )
    return "\n".join(lines)


def _render_tips(c: dict) -> str:
    return (
        "**Dual path to 119III** — the Stage-5 Relics at the end of each "
        "chain are the same items sold by the **Relic Forge** NPC (Dynamis "
        "path). Both paths award the identical weapon; use whichever suits "
        "your play style.\n\n"
        "**Slot the 119II first** — the 119II weapons (e.g., Raetic Algol, "
        "Crepuscular Knife) are solid mid-endgame pieces on their own. "
        "You don't have to push to 119III immediately.\n\n"
        "**Silver vendor shortcut** — the 119II stage weapon is also "
        "sold directly at the Silver weapon vendor in Escha - Zi'Tah for "
        "25× Kindred's Medals, so you can skip the forge step and still "
        "have a 119II to trade in later.\n\n"
        "**Nothing is lost on cancel** — the NPC only takes items on "
        "the final confirm. Browsing the menu and reading the chain is "
        "always free."
    )


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/weapon_forge_catalog.lua")
    if src is None:
        print("[weapon_forge] skip: weapon_forge_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    if not c["chains"]:
        print("[weapon_forge] warning: no chains parsed — check catalog format")

    page = docs_dir / "progression" / "weapon-forge.md"
    blocks = [
        ("weapon-forge-intro",  _render_intro(c)),
        ("weapon-forge-costs",  _render_costs(c)),
        ("weapon-forge-chains", _render_chains(c)),
        ("weapon-forge-tips",   _render_tips(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[weapon_forge] {written}/{len(blocks)} marker block(s) written "
          f"({len(c['chains'])} chains)")
