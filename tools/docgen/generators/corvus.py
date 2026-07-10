"""Sync the custom-Trust doc pages with trust_skoll.lua.

The Void Keeper in Leafallia grants three custom Trusts — **Corvus, Meat, Gemma** —
configured in the `TRUSTS` table of trust_skoll.lua (NOT a `*_catalog` file).
For each one we parse the display name, the in-game Trust-menu name (clientName)
and the unlock gate (Hunting League rank + Hunt Marks) out of that table, then
fill the "At a glance" summary block on that Trust's page — so the documented
unlock can never drift from the in-game requirement again. Corvus additionally
has a generated how-to-unlock paragraph.

Unlock note: these Trusts are EARNED, not bought with gil. Each one is gated on
a Hunting League rank (`rankReq`) and a one-time Hunt Marks cost (`markCost`)
parsed live from the Lua. (The legacy gil price was removed in the relaunch.)

Markers written: corvus-summary, corvus-unlock, meat-summary, gemma-summary
(kept as `corvus.py` for import stability; it now covers all three trusts).
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy

# The Void Keeper's hub is NEVER hardcoded here: it is placed by an addOverride
# in trust_skoll.lua, and custom NPCs get consolidated between hubs over time
# (the 2026-07-06 move to Purgonorgo Isle). Emit npc_location_inject's token
# instead; it reads that SAME module (see _NPC_FILES["void_keeper"]) and expands
# this to the NPC's live zone on every build, so the "Where" line and unlock
# paragraph can't drift the way a literal "Leafallia" would.
_LOC = "{{npc:void_keeper}}"

# Per-trust doc config. name / clientName / rankReq / markCost are pulled LIVE from the Lua;
# the role line, sibling links, pronouns and "who answers" noun are stable prose
# authored here. `unlock` is the unlock-paragraph marker id, or None to skip it.
_TRUSTS = [
    {
        "spellId": 902, "page": "corvus.md",
        "summary": "corvus-summary", "unlock": "corvus-unlock",
        "siblings": "[Meat](meat.md) and [Gemma](skoll.md)",
        "role": "ranged damage dealer — he stands at the back line and shoots",
        "subj": "he", "obj": "him", "poss": "his", "noun": "archer",
    },
    {
        "spellId": 899, "page": "meat.md",
        "summary": "meat-summary", "unlock": None,
        "siblings": "[Corvus](corvus.md) and [Gemma](skoll.md)",
        "role": "pure tank — soaks the damage, minimal DPS",
        "subj": "it", "obj": "it", "poss": "its", "noun": "tiny Tarutaru",
    },
    {
        "spellId": 901, "page": "skoll.md",
        "summary": "gemma-summary", "unlock": None,
        "siblings": "[Corvus](corvus.md) and [Meat](meat.md)",
        "role": "primary support **+** secondary nuker; she never tanks",
        "subj": "she", "obj": "her", "poss": "her", "noun": "small woman",
    },
]


def _entry_for_spell(trusts: str, spell_id: int) -> str:
    """The brace-balanced `{ ... }` entry whose body contains spellId=<id>."""
    body = trusts[trusts.find("{") + 1: trusts.rfind("}")]
    depth, start = 0, None
    for i, ch in enumerate(body):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                entry = body[start:i + 1]
                if re.search(rf"spellId\s*=\s*{spell_id}\b", entry):
                    return entry
    return ""


def _parse(trusts: str, spell_id: int) -> dict:
    c = {"name": "?", "client": "?", "rank": 0, "marks": 0}
    entry = _entry_for_spell(trusts, spell_id)
    if entry:
        m = re.search(r"name\s*=\s*'([^']+)'", entry)
        if m:
            c["name"] = m.group(1)
        m = re.search(r"clientName\s*=\s*'([^']+)'", entry)
        if m:
            c["client"] = m.group(1)
        # Earned, not bought: gated on Hunting League rank + Hunt Marks.
        m = re.search(r"rankReq\s*=\s*(\d+)", entry)
        if m:
            c["rank"] = int(m.group(1))
        m = re.search(r"markCost\s*=\s*(\d+)", entry)
        if m:
            c["marks"] = int(m.group(1))
    return c


def _gate(c: dict) -> str:
    """Player-facing unlock requirement: 'Hunting League Rank N + X Hunt Marks'."""
    return f"Hunting League Rank {c['rank']} + {commafy(c['marks'])} Hunt Marks"


def _render_summary(t: dict, c: dict) -> str:
    return (
        f"- **Where:** the **Void Keeper** in {_LOC} (reach it with "
        f"`!hub`) — the same NPC that grants {t['siblings']}\n"
        f"- **Unlock:** **{_gate(c)}** — one-time, permanent, per character\n"
        f"- **Role:** {t['role']}\n"
        f"- **To summon:** cast **{c['client']}** from your Trust menu — that slot "
        f"*is* {c['name']} (the name **{c['name']}** appears over {t['poss']} head "
        f"and in your party list)"
    )


def _render_unlock(t: dict, c: dict) -> str:
    return (
        f"Reach **{_gate(c)}**, then travel to {_LOC} with `!hub`, find the "
        f"**Void Keeper**, and bind {c['name']}. The marks are spent once; the binding "
        f"is permanent and per character — earn {t['obj']} once and {t['subj']}'s yours "
        f"forever.\n\n"
        f"In your Trust menu {t['subj']} shows up as **\"{c['client']}\"** — that Trust "
        f"slot was re-used, so the menu label is just cosmetic. Cast **{c['client']}**, "
        f"and the {t['noun']} who answers — named **{c['name']}** over {t['poss']} head "
        f"— *is* {t['obj']}.\n\n"
        f"So: **cast {c['client']} → get {c['name']}.**"
    )


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/trust_skoll.lua")
    if src is None:
        print("[trusts] skip: trust_skoll.lua not found")
        return

    trusts = section(src.read_text(encoding="utf-8", errors="replace"), "TRUSTS")

    written = 0
    for t in _TRUSTS:
        c = _parse(trusts, t["spellId"])
        page = docs_dir / "progression" / t["page"]
        if write_between_markers(page, t["summary"], _render_summary(t, c)):
            written += 1
        if t["unlock"] and write_between_markers(page, t["unlock"], _render_unlock(t, c)):
            written += 1
        print(f"[trusts] {t['page']}: name={c['name']} client={c['client']} rank={c['rank']} marks={c['marks']}")
    print(f"[trusts] {written} marker block(s) written across {len(_TRUSTS)} custom-trust page(s)")
