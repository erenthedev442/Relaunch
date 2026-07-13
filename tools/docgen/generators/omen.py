"""Sync docs/endgame/omen.md with omen_catalog.lua.

Everything player-facing derives from the live catalog so the page tracks
tuning changes automatically: entry economy (canteen cooldown/banking),
time rules, floor compositions, objective lists, boss/mid-boss drop tables
(item-linked so the Gear Finder source scan sees them), card economics and
the boss roster and drops.

Marker IDs: omen-intro, omen-entry, omen-floors, omen-objectives,
            omen-midbosses, omen-bosses, omen-ou
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section
from tools.docgen._bgwiki import item_anchor


# ---------------------------------------------------------------------------
# Parsing helpers

def _int_val(block: str, field: str) -> int:
    m = re.search(rf"{re.escape(field)}\s*=\s*(\d+)", block)
    return int(m.group(1)) if m else 0


def _num_val(block: str, field: str) -> float:
    m = re.search(rf"{re.escape(field)}\s*=\s*([\d.]+)", block)
    return float(m.group(1)) if m else 0.0


def _time_expr(block: str, field: str) -> int:
    """Read `field = N * 60` (or a plain integer) as seconds."""
    m = re.search(rf"{re.escape(field)}\s*=\s*(\d+)\s*\*\s*60", block)
    if m:
        return int(m.group(1)) * 60
    return _int_val(block, field)


def _items(block: str) -> list[dict]:
    """All `{ id = N, name = '...' }` entries inside a block."""
    out = []
    for m in re.finditer(r"\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*'((?:[^'\\]|\\.)+)'\s*\}", block):
        out.append({"id": int(m.group(1)), "name": m.group(2).replace("\\'", "'")})
    return out


def _quoted_list(block: str) -> list[str]:
    return re.findall(r"'([^']+)'", block)


def _link(item: dict) -> str:
    # Shared builder: emits data-img, which item-tooltip.js requires -- a
    # hand-rolled anchor without it leaves taps dead on touch devices.
    return item_anchor(item["name"], item_id=item["id"])


def _pct(fraction: float) -> str:
    value = fraction * 100
    return f"{value:g}%"


def _parse(text: str) -> dict:
    c: dict = {}

    time_block = section(text, "catalog.time")
    c["t_start"] = _time_expr(time_block, "start") // 60
    c["t_floor"] = _time_expr(time_block, "perFloor") // 60
    c["t_small"] = _time_expr(time_block, "smallerLight") // 60
    c["t_cap"]   = _time_expr(time_block, "cap") // 60

    canteen_block = section(text, "catalog.canteen")
    m = re.search(r"cooldown\s*=\s*(\d+)\s*\*\s*60\s*\*\s*60", canteen_block)
    c["canteen_hours"]  = int(m.group(1)) if m else 20
    c["canteen_banked"] = _int_val(canteen_block, "maxBanked")

    c["max_members"] = _int_val(text, "catalog.maxMembers")
    c["obj_per_card"] = _int_val(text, "catalog.objectivesPerCard")
    c["conversion"]   = _int_val(text, "catalog.cardConversionRate")

    rates_block = section(text, "catalog.rates")
    c["r_acc"]   = _num_val(rates_block, "bossAccessory")
    c["r_body"]  = _num_val(rates_block, "bossBody")
    c["r_scale2"] = _num_val(rates_block, "bossExtraScale")
    c["r_ou_acc"] = _num_val(rates_block, "ouAccessory")
    c["r_ou_hand"] = _num_val(rates_block, "ouHands")
    c["r_ou_scale"] = _num_val(rates_block, "ouScale")
    c["r_bonus"]  = _num_val(rates_block, "bonusFloor")

    # Floors
    floors_block = section(text, "catalog.floors")
    floors = []
    for m in re.finditer(r"\[(\d)\]\s*=\s*\{(.*?)\n    \},", floors_block, re.DOTALL):
        num, body = int(m.group(1)), m.group(2)
        fams_m = re.search(r"families\s*=\s*\{([^}]*)\}", body)
        floors.append({
            "num":         num,
            "label":       (re.search(r"label\s*=\s*'([^']+)'", body) or [None, "?"])[1],
            "families":    _quoted_list(fams_m.group(1)) if fams_m else [],
            "sweetwater":  _int_val(body, "sweetwater"),
            "transcended": _int_val(body, "transcended"),
            "bonusCount":  _int_val(body, "bonusCount"),
            "bonusWindow": _int_val(body, "bonusWindow"),
            "midboss":     "midboss" in body,
            "boss":        re.search(r"\bboss\s*=\s*true", body) is not None,
            "lightChoice": "lightChoice" in body,
        })
    c["floors"] = floors

    # Floor-4 route families
    f4_block = section(floors_block, "familiesByRoute")
    c["route_families"] = {
        key: _quoted_list(m)
        for key, m in re.findall(r"(\w+)\s*=\s*\{([^}]*)\}", f4_block)
    }

    bonus_block = section(text, "catalog.bonusRoute")
    fams_m = re.search(r"families\s*=\s*\{([^}]*)\}", bonus_block)
    c["bonus_route"] = {
        "label":       (re.search(r"label\s*=\s*'([^']+)'", bonus_block) or [None, "?"])[1],
        "families":    _quoted_list(fams_m.group(1)) if fams_m else [],
        "total":       _int_val(bonus_block, "total"),
        "bonusCount":  _int_val(bonus_block, "bonusCount"),
        "bonusWindow": _int_val(bonus_block, "bonusWindow"),
    }

    # Objectives
    main_block = section(text, "catalog.mainObjectives")
    c["main_objectives"] = re.findall(r"text\s*=\s*'([^']+)'", main_block)

    bonus_obj_block = section(text, "catalog.bonusObjectives")
    c["bonus_objectives"] = []
    for m in re.finditer(r"\{\s*id\s*=\s*'\w+',\s*mult\s*=\s*(\d+),(?:[^}]*?)text\s*=\s*'([^']+)'", bonus_obj_block):
        c["bonus_objectives"].append({"mult": int(m.group(1)), "text": m.group(2)})

    # Mid-bosses
    mid_block = section(text, "catalog.midbosses")
    c["midbosses"] = []
    for m in re.finditer(r"key\s*=\s*'(\w+)'(.*?)(?=key\s*=\s*'|\Z)", mid_block, re.DOTALL):
        body = m.group(2)
        crystal_m = re.search(r"crystal\s*=\s*(\{[^}]*\})", body)
        gear_m    = re.search(r"gear\s*=\s*\n?\s*\{(.*?)\n        \}", body, re.DOTALL)
        c["midbosses"].append({
            "name":    (re.search(r"name\s*=\s*'([^']+)'", body) or [None, "?"])[1],
            "crystal": _items(crystal_m.group(1))[0] if crystal_m else None,
            "gear":    _items(gear_m.group(1)) if gear_m else [],
        })

    # Caturae
    bosses_block = section(text, "catalog.bosses")
    c["bosses"] = []
    for m in re.finditer(r"key\s*=\s*'(\w+)'(.*?)(?=key\s*=\s*'|\Z)", bosses_block, re.DOTALL):
        body = m.group(2)
        scale_m = re.search(r"scale\s*=\s*(\{[^}]*\})", body)
        moon_m  = re.search(r"moonbow\s*=\s*(\{[^}]*\})", body)
        acc_m   = re.search(r"accessories\s*=\s*\n?\s*\{(.*?)\n        \}", body, re.DOTALL)
        body_m  = re.search(r"body\s*=\s*(\{[^}]*\})", body)
        c["bosses"].append({
            "name":      (re.search(r"name\s*=\s*'([^']+)'", body) or [None, "?"])[1],
            "job":       (re.search(r"job\s*=\s*'([^']+)'", body) or [None, ""])[1],
            "signature": (re.search(r"signature\s*=\s*'((?:[^'\\]|\\.)+)'", body) or [None, ""])[1].replace("\\'", "'"),
            "scale":     _items(scale_m.group(1))[0] if scale_m else None,
            "moonbow":   _items(moon_m.group(1))[0] if moon_m else None,
            "accessories": _items(acc_m.group(1)) if acc_m else [],
            "body":      _items(body_m.group(1))[0] if body_m else None,
        })

    # Ou
    ou_block = section(text, "catalog.ou")
    ou_moon_m = re.search(r"moonbow\s*=\s*\n?\s*\{(.*?)\n    \},", ou_block, re.DOTALL)
    ou_acc_m  = re.search(r"accessories\s*=\s*\n?\s*\{(.*?)\n    \},", ou_block, re.DOTALL)
    ou_hand_m = re.search(r"hands\s*=\s*\n?\s*\{(.*?)\n    \},", ou_block, re.DOTALL)
    c["ou"] = {
        "job":       (re.search(r"job\s*=\s*'([^']+)'", ou_block) or [None, ""])[1],
        "signature": (re.search(r"signature\s*=\s*'((?:[^'\\]|\\.)+)'", ou_block) or [None, ""])[1].replace("\\'", "'"),
        "moonbow":   _items(ou_moon_m.group(1)) if ou_moon_m else [],
        "accessories": _items(ou_acc_m.group(1)) if ou_acc_m else [],
        "hands":     _items(ou_hand_m.group(1)) if ou_hand_m else [],
    }

    return c


# ---------------------------------------------------------------------------
# Renderers

def _fam(name: str) -> str:
    return name.capitalize()


def _render_intro(c: dict) -> str:
    return (
        f"The chessboard awaits. **Omen** is the Reisenjima Henge gauntlet from the "
        f"November 2016 era of retail: five gates of trials, three Glassy sentinels, and "
        f"the **Caturae** — Kin, Gin, Fu, Kyou and Kei — with the hidden Prime, **Ou**, "
        f"beyond them. It is the home of **paragon job cards**, **Caturae scales** and the "
        f"**Regal** treasures, and the road to **Artifact armor +2 and +3**.\n\n"
        f"!!! tip \"Quick start\"\n"
        f"    Get **Phoenix's blessing** and a **mystical canteen** from **Incantrix** at "
        f"    Ethereal Ingress #10 in Reisenjima, gather your group (up to {c['max_members']}), "
        f"    and choose *Enter Omen*. You start with **{c['t_start']} minutes**; each gate "
        f"    cleared grants **+{c['t_floor']}** (cap **{c['t_cap']}**)."
    )


def _render_entry(c: dict) -> str:
    return (
        f"**Incantrix** and **Coelestrox** stand at **Ethereal Ingress #10** in Reisenjima "
        f"(reachable through the Ethereal Ingress network).\n\n"
        f"- **Phoenix's blessing** — permanent key item; Incantrix bestows it on any "
        f"level-99 adventurer.\n"
        f"- **Mystical canteen** — one per entrant, consumed on entry. Incantrix fills one "
        f"every **{c['canteen_hours']} hours** and banks up to **{c['canteen_banked']}** "
        f"for you while you're away.\n"
        f"- **An ultimate weapon** — every entrant must have **forged one of the server's "
        f"ultimate weapons**: any final (iLvl 119&nbsp;III) **Relic, Empyrean, Mythic,** or "
        f"**Aeonic**, or a claimed **Prime**. Owning one is enough — equipped or stored, and "
        f"it is **not** consumed. Anyone in the group without one blocks entry.\n"
        f"- **Group size** — solo up to a full alliance of **{c['max_members']}**. Only the "
        f"leader initiates; everyone needs their own canteen and must be standing nearby.\n"
        f"- **Time** — **{c['t_start']} minutes** on entry, **+{c['t_floor']}** per ethereal "
        f"ingress used, **+{c['t_small']}** for the smaller light, hard cap "
        f"**{c['t_cap']} minutes**."
    )


def _render_floors(c: dict) -> str:
    lines = [
        "| Gate | What awaits | Bonus objectives |",
        "|---|---|---|",
    ]

    route_desc = ", ".join(
        f"{key.capitalize()}: {', '.join(_fam(f) for f in fams)}"
        for key, fams in c["route_families"].items()
    )

    for f in c["floors"]:
        if f["midboss"]:
            what = "One of the three **Glassy sentinels**, at random"
            bonus = "—"
        elif f["boss"]:
            what = "The **Caturae of your choice** (picked at the fourth gate's ingress)"
            bonus = "—"
        else:
            fams = ", ".join(_fam(x) for x in f["families"]) if f["families"] else f"By mid-boss route ({route_desc})"
            what = (f"{fams} — {f['sweetwater']} Sweetwater + "
                    f"{f['transcended']} Transcended, plus a random floor objective")
            bonus = f"{f['bonusCount']} in {f['bonusWindow'] // 60} min"

        light = " ← *larger/smaller light choice*" if f["lightChoice"] else ""
        lines.append(f"| **{f['num']} — {f['label']}** | {what}{light} | {bonus} |")

    br = c["bonus_route"]
    fams = ", ".join(_fam(x) for x in br["families"])
    lines.extend([
        "",
        f"**The smaller light — {br['label']}.** Choosing the *smaller* light at the second "
        f"gate grants **+{c['t_small']} minutes** and replaces the remaining gates with one "
        f"sprawling trial: **{br['total']} creatures** ({fams}) in successive waves, with "
        f"**{br['bonusCount']} bonus objectives** over {br['bonusWindow'] // 60} minutes. "
        f"Fell every last one — with the run's opener alive at the final blow — and the exit "
        f"ingress offers something else entirely (see **Ou** below).",
        "",
        f"**Hidden vault.** Leaving the third or final gate has a **{_pct(c['r_bonus'])}** "
        f"chance to detour through a chamber of treasure caskets: gil, paragon cards, "
        f"moonbow materials, scales, a spare canteen — and sometimes "
        f"{_link({'id': 28273, 'name': 'Regal Pumps'})}.",
    ])
    return "\n".join(lines)


def _render_objectives(c: dict) -> str:
    lines = [
        "Each trash gate rolls **one main objective** at random:",
        "",
    ]
    for text in c["main_objectives"]:
        lines.append(f"- {text.replace('%d', 'N')}")

    lines.extend([
        "",
        "Alongside it, timed **bonus objectives** begin the moment battle is joined "
        "(N scales with group size, capped at 6):",
        "",
    ])
    for obj in c["bonus_objectives"]:
        lines.append(f"- {obj['text'].replace('%d', 'a number of') if obj['mult'] else obj['text']}")

    lines.extend([
        "",
        f"Every **{c['obj_per_card']} objectives** completed (main objectives, bonus "
        f"objectives and boss kills all count — progress carries between runs) pays every "
        f"member **one paragon card for their current main job**. Coelestrox converts "
        f"**{c['conversion']} cards of one job into 1 of another**.",
    ])
    return "\n".join(lines)


def _render_midbosses(c: dict) -> str:
    lines = [
        "The third gate holds one of three Empty sentinels, chosen at random. Each "
        "drops its crystal **every time**, plus one of its three treasures:",
        "",
        "| Sentinel | Guaranteed | One of |",
        "|---|---|---|",
    ]
    for mb in c["midbosses"]:
        gear = ", ".join(_link(g) for g in mb["gear"])
        crystal = _link(mb["crystal"]) if mb["crystal"] else "—"
        lines.append(f"| **{mb['name']}** | {crystal} | {gear} |")
    return "\n".join(lines)


def _render_bosses(c: dict) -> str:
    lines = [
        f"The fourth gate's ingress lets you **choose your Caturae**. Every kill pays its "
        f"**scale** and **moonbow material** (plus a {_pct(c['r_scale2'])} chance of a second "
        f"scale) and awards its **bead** key item to every member; each accessory drops at "
        f"{_pct(c['r_acc'])} and the coveted body piece at {_pct(c['r_body'])}.",
        "",
        "| Caturae | Job | Watch for | Always | Accessories | Rare body |",
        "|---|---|---|---|---|---|",
    ]
    for b in c["bosses"]:
        always = ", ".join(_link(x) for x in (b["scale"], b["moonbow"]) if x)
        accs   = ", ".join(_link(x) for x in b["accessories"])
        body   = _link(b["body"]) if b["body"] else "—"
        lines.append(f"| **{b['name']}** | {b['job']} | {b['signature']} | {always} | {accs} | {body} |")
    return "\n".join(lines)


def _render_ou(c: dict) -> str:
    ou = c["ou"]
    moon = ", ".join(_link(x) for x in ou["moonbow"])
    accs = ", ".join(_link(x) for x in ou["accessories"])
    hands = ", ".join(_link(x) for x in ou["hands"])
    return (
        f"Collect **all five beads** (one per Caturae felled), take the **smaller light**, "
        f"and slay every creature on the rampart with the run's opener alive at the final "
        f"blow. The exit ingress will then offer a sixth choice. Accepting it consumes "
        f"**every member's beads**.\n\n"
        f"**Ou** ({ou['job']}) — {ou['signature']}.\n\n"
        f"| Drop | Chance |\n"
        f"|---|---|\n"
        f"| {moon} | Guaranteed (one of each) |\n"
        f"| {accs} | {_pct(c['r_ou_acc'])} each |\n"
        f"| {hands} | {_pct(c['r_ou_hand'])} (one of the four) |\n"
        f"| The five Caturae scales | {_pct(c['r_ou_scale'])} each |"
    )


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/omen_catalog.lua")
    if src is None:
        print("[omen] skip: omen_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "omen.md"
    blocks = [
        ("omen-intro",      _render_intro(c)),
        ("omen-entry",      _render_entry(c)),
        ("omen-floors",     _render_floors(c)),
        ("omen-objectives", _render_objectives(c)),
        ("omen-midbosses",  _render_midbosses(c)),
        ("omen-bosses",     _render_bosses(c)),
        ("omen-ou",         _render_ou(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[omen] {written}/{len(blocks)} marker block(s) written "
          f"({len(c['bosses'])} Caturae, {len(c['midbosses'])} mid-bosses)")
