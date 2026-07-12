"""Generate docs/endgame/geas-fete.md from Geas_Fete.lua.

Escha Geas Fete: two Warding Circle NPCs (Escha Zi'Tah + Ru'Aun) pop tiered NMs
that drop Escha Beads + Aeonic materials (Beitetsu / Riftcinder / Riftborn
Boulder / Attestations). Reads the NM roster + the material exchange from the Lua
so the tables can't drift.

Marker IDs: geas-overview, geas-roster, geas-exchange
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

_TIER_NAME = {1: "Tier 1", 2: "Tier 2", 3: "Tier 3", 4: "Boss"}


def _parse(text: str) -> dict:
    nms = []
    for m in re.finditer(r"name\s*=\s*'([^']+)'[^}\n]*?tier\s*=\s*(\d)[^}\n]*?currency\s*=\s*(\d+)", text):
        nms.append({"name": m.group(1), "tier": int(m.group(2)), "cur": int(m.group(3))})
    ex = []
    for m in re.finditer(r"label\s*=\s*'([^']+)'[^}\n]*?cost\s*=\s*(\d+)", text):
        ex.append({"label": m.group(1), "cost": int(m.group(2))})

    # Reisenjima-crafted armor drops (GEAR_NQ/GEAR_HQ pools + tier chances).
    gear = {"nq": 0, "hq": 0, "nq_pct": {}, "hq_pct": {}}
    for kind in ("NQ", "HQ"):
        m = re.search(r"local GEAR_" + kind + r"\s*=\s*\{(.*?)\n\}", text, re.DOTALL)
        if m:
            gear[kind.lower()] = len(re.findall(r"\b2\d{4}\b", m.group(1)))
    for var, key in (("nqChance", "nq_pct"), ("hqChance", "hq_pct")):
        m = re.search(var + r"\s*=\s*\(\{([^}]*)\}\)", text)
        if m:
            gear[key] = {int(t): float(v) for t, v in
                         re.findall(r"\[(\d)\]\s*=\s*([\d.]+)", m.group(1))}
    return {"nms": nms, "exchange": ex, "gear": gear}


def _overview(c: dict) -> str:
    return (
        "Two **Warding Circle** NPCs — one in Escha - Zi'Tah and one in "
        "Escha - Ru'Aun — let you pop retail-faithful **Geas Fete NMs** "
        "on demand: walk up, pick a tier, pick an NM. **No pop items needed**, but each NM has a "
        "per-player cooldown.\n\n"
        "Every Escha kill pays **Escha Beads** (a real currency — see the Currencies II tab). That one "
        "pool funds the Warding Circle material exchange **and** the **Aeonic weapon** path "
        "([Temprix in Reisenjima](../progression/aeonic-weapons.md)). NMs also drop the Aeonic crafting "
        "materials directly — **Beitetsu**, **Riftcinder**, **Riftborn Boulder**, and (from bosses) "
        "**Attestations**, the weapon-type tokens the Aeonic forge needs."
        + _gear_para(c)
    )


def _gear_para(c: dict) -> str:
    g = c.get("gear") or {}
    if not g.get("nq"):
        return ""
    nq, hq = g["nq_pct"], g["hq_pct"]
    def pct(d, t):
        return f"{round(d.get(t, 0) * 100)}%"
    return (
        "\n\nTier 2 and up also drop the **Reisenjima-crafted armor** families "
        "as direct drops — **Adhemar, Argosy, Carmine, Rao, Ryuo, Souveran and "
        f"Naga** ({g['nq']} base pieces, {g['hq']} +1 pieces) — and the fete NMs "
        "are their **only source**. Base pieces drop at "
        f"**{pct(nq, 2)}** from Tier 2, **{pct(nq, 3)}** from Tier 3 and "
        f"**{pct(nq, 4)}** from bosses; **+1** pieces at **{pct(hq, 3)}** from "
        f"Tier 3 and **{pct(hq, 4)}** from bosses. Drops are a random piece "
        "from the whole pool — the hunt is the gate, not a job lock."
    )


def _roster(c: dict) -> str:
    from collections import defaultdict
    by = defaultdict(list)
    for n in c["nms"]:
        by[n["tier"]].append(n)
    lines = ["| Tier | NM | Escha Beads / kill |", "|---|---|---:|"]
    for t in sorted(by):
        for n in by[t]:
            lines.append(f"| {_TIER_NAME.get(t, t)} | {n['name']} | {n['cur']:,} |")
    return "\n".join(lines)


def _exchange(c: dict) -> str:
    if not c["exchange"]:
        return "_Exchange list unavailable._"
    lines = ["Spend Escha Beads at the Warding Circle for Aeonic materials — pick a "
             "material, then a quantity (x1 / x10 / full stack / Max):", "",
             "| Material | Cost each (Escha Beads) |", "|---|---:|"]
    for e in c["exchange"]:
        lines.append(f"| {e['label']} | {e['cost']:,} |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/Geas_Fete.lua")
    if src is None:
        print("[geas_fete] skip: Geas_Fete.lua not found")
        return
    c = _parse(src.read_text(encoding="utf-8", errors="replace"))
    page = docs_dir / "endgame" / "geas-fete.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    blocks = [("geas-overview", _overview(c)), ("geas-roster", _roster(c)), ("geas-exchange", _exchange(c))]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[geas_fete] {written}/{len(blocks)} blocks ({len(c['nms'])} NMs, {len(c['exchange'])} exchange rows)")
