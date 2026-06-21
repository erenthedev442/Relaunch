"""Sync docs/progression/prime-trials.md with the Prime Weapon Trials.

The five trials that gate the Prime Armory forge are
defined in PrimeArmory_NPC.lua as a `TRIALS` table of `{ var, label, desc }`
rows, plus the Trial-1 collectible set `T1_SETS` (five "elements", each in four
types) and the per-item requirement `T1_REQUIRED`. We surface each trial's
player-facing requirement and the full Trial-1 collectible breakdown, so
reworking a trial -- or the collectible count -- updates the page automatically.

Markers written:
  prime-trials-gate          -- the N-trial gate overview
  prime-trials-table         -- one row per trial (its requirement)
  prime-trials-collectibles  -- Trial 1's "N of every collectible" breakdown
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


def _parse(text: str) -> dict:
    c: dict = {"trials": [], "t1_required": 12, "t1_elements": [], "t1_types": []}

    # The four trials: { var = '...', label = 'Trial N', desc = '...' }.
    trial_block = section(text, "TRIALS") or text
    for m in re.finditer(r"label\s*=\s*'([^']+)'\s*,\s*desc\s*=\s*'([^']+)'", trial_block):
        c["trials"].append({"label": m.group(1), "desc": m.group(2)})

    # Trial 1: collect N (T1_REQUIRED) of every collectible.
    m = re.search(r"T1_REQUIRED\s*=\s*(\d+)", text)
    if m:
        c["t1_required"] = int(m.group(1))

    # T1_SETS: five elements, each with the same four types (Stone/Coin/Jewel/Card).
    t1_block = section(text, "T1_SETS") or ""
    c["t1_elements"] = re.findall(r"name\s*=\s*'([^']+)'\s*,\s*types\s*=", t1_block)
    for t in re.findall(r"\bt\s*=\s*'([^']+)'", t1_block):
        if t not in c["t1_types"]:
            c["t1_types"].append(t)
    return c


# ---------------------------------------------------------------------------

def _render_gate(c: dict) -> str:
    n = len(c["trials"]) or 4
    return (
        f"The Prime Armory forge is locked behind the **{n} Prime Weapon Trials**. "
        f"They are tracked independently, so you can chip away at them **in any "
        f"order** -- clear all **{n}** and the Prime Armory will forge the Prime "
        f"weapon of your choice.\n\n"
        f"Talk to the **Prime Armory** NPC in **GM Home** at any time to see which "
        f"trials you've cleared and to hand in the collection trials."
    )


def _render_table(c: dict) -> str:
    lines = [
        "| Trial | What it takes |",
        "|---|---|",
    ]
    for t in c["trials"]:
        lines.append(f"| **{t['label']}** | {t['desc']} |")
    return "\n".join(lines)


def _render_collectibles(c: dict) -> str:
    req = c["t1_required"]
    elements = c["t1_elements"]
    types = c["t1_types"]
    n_items = len(elements) * len(types)
    total = req * n_items
    type_str = " &middot; ".join(types)
    lines = [
        f"Trial 1 wants **{req} of every one** of the **{n_items} Abyssea "
        f'collectibles** -- the full "five elements" set. Each element drops in '
        f"**{len(types)} types** ({type_str}), and you need **{req} of all "
        f"{n_items}**:",
        "",
        f"| Element | Types (&times;{req} each) |",
        "|---|---|",
    ]
    for el in elements:
        lines.append(f"| **{el}** | {type_str} |")
    lines += [
        "",
        f"That's **{req} &times; {n_items} = {total}** collectibles in total. They "
        f"drop from [Abyssea NMs](../endgame/abyssea-nms.md) -- bring the complete "
        f"set to the Prime Armory and it consumes the lot when you turn Trial 1 in.",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/PrimeArmory_NPC.lua")
    if src is None:
        print("[prime_trials] skip: PrimeArmory_NPC.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "prime-trials.md"
    blocks = [
        ("prime-trials-gate", _render_gate(c)),
        ("prime-trials-table", _render_table(c)),
        ("prime-trials-collectibles", _render_collectibles(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[prime_trials] {written}/{len(blocks)} marker block(s) written "
          f"(trials={len(c['trials'])}, "
          f"collectibles={len(c['t1_elements']) * len(c['t1_types'])})")
