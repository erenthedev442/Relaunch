"""Sync the custom-Trust doc pages with trust_skoll.lua.

The Void Keeper in GM Home sells three custom Trusts — **Corvus, Meat, Gemma** —
configured in the `TRUSTS` table of trust_skoll.lua (NOT a `*_catalog` file).
For each one we parse the display name, the in-game Trust-menu name (clientName)
and the gil cost out of that table, then fill the "At a glance" summary block on
that Trust's page — so the documented price can never drift from the in-game
price again (which is exactly what happened to Meat/Gemma when they were
hand-written). Corvus additionally has a generated how-to-unlock paragraph.

Cost note: a trust without its own `cost` field uses the shared 50M default
(GIL_COST in the Lua). Gemma rides that default; Meat and Corvus carry their own
`cost`. The default below MUST track GIL_COST in trust_skoll.lua.

Markers written: corvus-summary, corvus-unlock, meat-summary, gemma-summary
(kept as `corvus.py` for import stability; it now covers all three trusts).
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy

# Shared fallback price — trusts without their own `cost` field use this.
# Mirrors GIL_COST in modules/custom/lua/trust_skoll.lua.
_DEFAULT_COST = 50000000

# Per-trust doc config. name / clientName / cost are pulled LIVE from the Lua;
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
    c = {"name": "?", "client": "?", "cost": _DEFAULT_COST}
    entry = _entry_for_spell(trusts, spell_id)
    if entry:
        m = re.search(r"name\s*=\s*'([^']+)'", entry)
        if m:
            c["name"] = m.group(1)
        m = re.search(r"clientName\s*=\s*'([^']+)'", entry)
        if m:
            c["client"] = m.group(1)
        # The trust's own `cost` overrides the shared default; fall back if absent.
        m = re.search(r"cost\s*=\s*(\d+)", entry)
        c["cost"] = int(m.group(1)) if m else _DEFAULT_COST
    return c


def _render_summary(t: dict, c: dict) -> str:
    return (
        f"- **Where:** the **Void Keeper** at [GM Home](gm-home.md) (reach it with "
        f"`!gmhome`) — the same NPC that sells {t['siblings']}\n"
        f"- **Cost:** **{commafy(c['cost'])} gil** — one-time, permanent, per character\n"
        f"- **Role:** {t['role']}\n"
        f"- **To summon:** cast **{c['client']}** from your Trust menu — that slot "
        f"*is* {c['name']} (the name **{c['name']}** appears over {t['poss']} head "
        f"and in your party list)"
    )


def _render_unlock(t: dict, c: dict) -> str:
    return (
        f"Travel to **GM Home** with `!gmhome`, find the **Void Keeper**, and bind "
        f"{c['name']} for **{commafy(c['cost'])} gil**. The binding is permanent and "
        f"per character — buy {t['obj']} once and {t['subj']}'s yours forever.\n\n"
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
        print(f"[trusts] {t['page']}: name={c['name']} client={c['client']} cost={c['cost']}")
    print(f"[trusts] {written} marker block(s) written across {len(_TRUSTS)} custom-trust page(s)")
