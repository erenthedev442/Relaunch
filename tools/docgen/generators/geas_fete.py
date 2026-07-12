"""Generate docs/endgame/geas-fete.md from Geas_Fete.lua.

Escha Geas Fete, retail-??? edition (2026-07-12): NMs pop at the stock retail
??? points across Escha Zi'Tah, Escha Ru'Aun, and Reisenjima (QM_POINTS in the
Lua); the Warding Circles are the material exchange. Reads the NM roster, the
??? camp map (positions joined from sql/npc_list.sql), and the exchange from
the Lua so the tables can't drift.

Marker IDs: geas-overview, geas-roster, geas-camps, geas-exchange
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import item_anchor

_TIER_NAME = {1: "Tier 1", 2: "Tier 2", 3: "Tier 3", 4: "Boss"}
_ZONES = ["Escha - Zi'Tah", "Escha - Ru'Aun", "Reisenjima"]


def _zone_of(text: str, pos: int) -> str:
    """Which NM_CATALOG zone block a text offset falls in (blocks are ordered)."""
    marks = [(text.find("[ZITAH] = {"), _ZONES[0]),
             (text.find("[RUAUN] = {"), _ZONES[1]),
             (text.find("[REISEN] = {"), _ZONES[2])]
    zone = _ZONES[0]
    for at, name in marks:
        if at != -1 and pos > at:
            zone = name
    return zone


def _parse(text: str) -> dict:
    nms = []
    for m in re.finditer(r"name\s*=\s*'((?:[^'\\]|\\.)+)'[^}\n]*?gid\s*=\s*(\d+)[^}\n]*?tier\s*=\s*(\d)[^}\n]*?currency\s*=\s*(\d+)(.*)", text):
        zone = _zone_of(text, m.start())
        drops = [{"id": int(i), "name": n.replace("\\'", "'")} for i, n in
                 re.findall(r"\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*'((?:[^'\\]|\\.)+)'\s*\}",
                            m.group(5))]
        nms.append({"name": m.group(1).replace("\\'", "'"), "gid": int(m.group(2)),
                    "tier": int(m.group(3)), "cur": int(m.group(4)),
                    "zone": zone, "drops": drops})
    ex = []
    for m in re.finditer(r"label\s*=\s*'([^']+)'[^}\n]*?cost\s*=\s*(\d+)", text):
        ex.append({"label": m.group(1), "cost": int(m.group(2))})

    # ??? camp map: QM_POINTS npcid -> gid list, per zone sub-block.
    camps = {z: [] for z in _ZONES}
    qm_block = re.search(r"local QM_POINTS = \{(.*?)\n\}", text, re.DOTALL)
    if qm_block:
        qtext = qm_block.group(1)
        marks = [(qtext.find("[ZITAH] = {"), _ZONES[0]),
                 (qtext.find("[RUAUN] = {"), _ZONES[1]),
                 (qtext.find("[REISEN] = {"), _ZONES[2])]
        for m in re.finditer(r"\[(17\d{6})\]\s*=\s*\{\s*([\d,\s]+)\}", qtext):
            zone = _ZONES[0]
            for at, name in marks:
                if at != -1 and m.start() > at:
                    zone = name
            camps[zone].append({"npcid": int(m.group(1)),
                                "gids": [int(g) for g in re.findall(r"\d+", m.group(2))]})

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
    rates = {}
    for var, key in (("FETE_DROP_RATE", "nm"), ("FETE_BOSS_DROP_RATE", "boss")):
        m = re.search(r"local " + var + r"\s*=\s*([\d.]+)", text)
        if m:
            rates[key] = float(m.group(1))
    return {"nms": nms, "exchange": ex, "gear": gear, "rates": rates, "camps": camps}


def _overview(c: dict) -> str:
    n_camps = {z: len(c["camps"].get(z, [])) for z in _ZONES}
    return (
        "Geas Fete NMs pop **retail-style, at the `???` points** scattered across "
        f"**Escha - Zi'Tah** ({n_camps[_ZONES[0]]} points), **Escha - Ru'Aun** "
        f"({n_camps[_ZONES[1]]} points), and **Reisenjima** ({n_camps[_ZONES[2]]} points). "
        "Inspect a `???` to pop one of the NMs camped there — **no pop items needed** "
        "(no trinkets or Tribulens), just a per-player cooldown per NM. "
        "The full camp map is [below](#camp-map). Fair warning: every fete NM is "
        "**tuned aggressive** — tier-scaled attack, accuracy, multi-hits, and TP "
        "pressure on top of its stock kit — so bring a real setup, especially for "
        "Tier 3 and the bosses.\n\n"
        "Every Escha kill pays **Escha Beads** (a real currency — see the Currencies II tab). That one "
        "pool funds the Warding Circle material exchange **and** the **Aeonic weapon** path "
        "([Temprix in Reisenjima](../progression/aeonic-weapons.md)). NMs also drop the Aeonic crafting "
        "materials directly — **Beitetsu**, **Riftcinder**, **Riftborn Boulder**, and (from bosses) "
        "**Attestations**, the weapon-type tokens the Aeonic forge needs."
        + _drops_para(c) + _gear_para(c)
    )


def _drops_para(c: dict) -> str:
    r = c.get("rates") or {}
    if not r.get("nm"):
        return ""
    n_drops = sum(len(n["drops"]) for n in c["nms"])
    return (
        f"\n\nEvery retail Geas Fete NM is implemented, each with its **retail "
        f"signature drops** ({n_drops} items across the roster — see the tables "
        f"below). Each listed item rolls independently at "
        f"**{round(r['nm'] * 100)}%** per kill (**{round(r.get('boss', r['nm']) * 100)}%** "
        "on the zone bosses)."
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


def _item_link(d: dict) -> str:
    # Shared builder: emits data-img, which item-tooltip.js requires -- a
    # hand-rolled anchor without it leaves taps dead on touch devices.
    return item_anchor(d["name"], item_id=d["id"])


def _camps(c: dict, qm_pos: dict) -> str:
    """Per-zone ??? camp tables: /pos + the NMs popped there."""
    name_by_zone_gid = {}
    for n in c["nms"]:
        name_by_zone_gid.setdefault(n["zone"], {})[n["gid"]] = n["name"]
    lines = ["Every `???` lists the NMs camped at it — inspect it in-game to pop "
             "one. Coordinates are `/pos` (x, z).", ""]
    for zone in _ZONES:
        rows = c["camps"].get(zone) or []
        if not rows:
            continue
        lines += [f"### {zone}", "", "| `???` at | NMs |", "|---|---|"]
        for r in sorted(rows, key=lambda r: r["npcid"]):
            pos = qm_pos.get(r["npcid"])
            where = f"({pos[0]:.0f}, {pos[2]:.0f})" if pos else "—"
            names = ", ".join(name_by_zone_gid.get(zone, {}).get(g, f"gid {g}")
                              for g in r["gids"])
            lines.append(f"| {where} | {names} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def _load_qm_positions(repo_root: Path) -> dict:
    """npcid -> (x, y, z) for the stock 'qm' ??? NPCs, from sql/npc_list.sql."""
    src = resolve_source(repo_root, "sql/npc_list.sql", required=False)
    out = {}
    if src is None:
        return out
    for m in re.finditer(
        r"VALUES \((17\d{6}),'qm[^']*','\?\?\?',\d+,(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)",
        src.read_text(encoding="utf-8", errors="replace"),
    ):
        out[int(m.group(1))] = (float(m.group(2)), float(m.group(3)), float(m.group(4)))
    return out


def _roster(c: dict) -> str:
    from collections import defaultdict
    lines = []
    for zone in _ZONES:
        by = defaultdict(list)
        for n in c["nms"]:
            if n["zone"] == zone:
                by[n["tier"]].append(n)
        if not by:
            continue
        lines += [f"### {zone}", "",
                  "| Tier | NM | Beads / kill | Signature drops (each rolled per kill) |",
                  "|---|---|---:|---|"]
        for t in sorted(by):
            for n in by[t]:
                drops = ", ".join(_item_link(d) for d in n["drops"]) or "—"
                lines.append(f"| {_TIER_NAME.get(t, t)} | {n['name']} | {n['cur']:,} | {drops} |")
        lines.append("")
    return "\n".join(lines).rstrip()


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
    qm_pos = _load_qm_positions(repo_root)
    page = docs_dir / "endgame" / "geas-fete.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    blocks = [("geas-overview", _overview(c)), ("geas-roster", _roster(c)),
              ("geas-camps", _camps(c, qm_pos)), ("geas-exchange", _exchange(c))]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    n_camps = sum(len(v) for v in c["camps"].values())
    print(f"[geas_fete] {written}/{len(blocks)} blocks ({len(c['nms'])} NMs, "
          f"{n_camps} ??? camps, {len(c['exchange'])} exchange rows)")
