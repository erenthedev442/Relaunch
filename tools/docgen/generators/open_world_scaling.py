"""Server-features sections for the two always-on combat frameworks added by
the 2026-07 collaborator drop (Sion Roberts):

  1. Open World Scaling  — modules/custom/lua/OpenWorldScaling.lua (engine) +
     modules/custom/lua/open_world_scaling_catalog.lua (zones, level profiles).
     Renders the eligible-zone count, activation floor, and the level-profile
     floor table into the `server-features-open-world-scaling` marker.

  2. Universal HP damage cap — settings/default/map.lua GLOBAL_HP_DAMAGE_CAP
     (enforced by modules/custom/cpp/fjb_combat.cpp). Renders into the
     `server-features-damage-cap` marker. The per-hit ceiling reshaped the
     REMA/Prime WS tiers and Gauntlet/Hunt tuning, so the section names those
     consumers.

Both blocks live on docs/progression/server-features.md. Every number is
parsed from the live sources (lua_const rule: no hardcoded literals here).
Fails closed per-section: a section whose source can't be parsed is skipped,
keeping the last good block live.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

_PAGE = ("progression", "server-features.md")

# xi.mod.* ids we show as columns, in display order.
_MOD_COLS = [("ATT", "Atk"), ("DEF", "Def"), ("ACC", "Acc"), ("EVA", "Eva")]


def _fmt(n: int) -> str:
    return f"{n:,}"


def _parse_scaling(text: str) -> dict | None:
    enabled = re.search(r"catalog\.enabled\s*=\s*(\w+)", text)
    min_level = re.search(r"catalog\.minLevel\s*=\s*(\d+)", text)
    if not enabled or enabled.group(1) != "true" or not min_level:
        return None

    zones_block = text.split("catalog.eligibleZones", 1)[-1].split("catalog.levelProfiles", 1)[0]
    zone_count = len(re.findall(r"\[xi\.zone\.\w+\]\s*=\s*true", zones_block))

    profiles = []
    prof_block = text.split("catalog.levelProfiles", 1)[-1].split("catalog.exclusions", 1)[0]
    for m in re.finditer(
        r"minLevel\s*=\s*(\d+),\s*maxLevel\s*=\s*(\d+),\s*name\s*=\s*'([^']+)',\s*hpFloor\s*=\s*(\d+),\s*modFloors\s*=\s*\{(.*?)\n\s{8}\}",
        prof_block, re.DOTALL,
    ):
        mods = dict(re.findall(r"\[xi\.mod\.(\w+)\]\s*=\s*(\d+)", m.group(5)))
        profiles.append({
            "lo": int(m.group(1)), "hi": int(m.group(2)),
            "name": m.group(3), "hp": int(m.group(4)),
            "mods": {k: int(v) for k, v in mods.items()},
        })
    if not profiles or zone_count == 0:
        return None
    return {"min_level": int(min_level.group(1)), "zones": zone_count, "profiles": profiles}


def _scaling_md(d: dict) -> str:
    head = " | ".join(label for _, label in _MOD_COLS)
    rows = []
    for p in d["profiles"]:
        hi = f'{p["lo"]}+' if p["hi"] >= 255 else f'{p["lo"]}–{p["hi"]}'
        mods = " | ".join(_fmt(p["mods"].get(key, 0)) for key, _ in _MOD_COLS)
        rows.append(f'| {hi} | {p["name"]} | {_fmt(p["hp"])} | {mods} |')
    table = "\n".join(rows)
    return f"""Every ordinary mob of **level {d['min_level']}+** in **{d['zones']} open-world progression zones** (Apex/Locus camps, Adoulin field zones, Escha and Reisenjima trash) is raised to relaunch-curve *minimum floors* the moment it spawns. Floors, not multipliers — a mob that already beats the floor keeps its stronger stats, while under-tuned database mobs get lifted into the intended band. NMs and dynamic pops are filtered out at runtime.

| Mob level | Band | HP floor | {head} |
|---|---|---|{'---|' * len(_MOD_COLS)}
{table}

Mob magic accuracy is deliberately left to the engine's own above-99 scaling. Zone, species, pool, and single-mob overrides can patch any floor individually."""


def _parse_cap(text: str) -> int | None:
    m = re.search(r"GLOBAL_HP_DAMAGE_CAP\s*=\s*(\d+)", text)
    return int(m.group(1)) if m else None


def _cap_md(cap: int) -> str:
    return f"""No single action — melee hit, weapon skill, magic burst, pet ability, anything — can remove more than **{_fmt(cap)} HP** from one target. The ceiling applies to every entity in combat, players and monsters alike.

This is the tuning anchor for the endgame damage systems built on top of it: **REMA / Prime weapon-skill enhancement** tiers are budgeted against the cap, and **Gauntlet / Hunt NM** health pools and self-healing are sized assuming capped per-hit damage."""


def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / _PAGE[0] / _PAGE[1]
    if not page.exists():
        print("[open_world_scaling] skip: server-features.md not found")
        return

    wrote = []

    src = resolve_source(repo_root, "modules/custom/lua/open_world_scaling_catalog.lua", required=False)
    if src is not None:
        parsed = _parse_scaling(src.read_text(encoding="utf-8", errors="replace"))
        if parsed and write_between_markers(page, "server-features-open-world-scaling", _scaling_md(parsed)):
            wrote.append(f"scaling({parsed['zones']} zones, {len(parsed['profiles'])} bands)")
        elif not parsed:
            print("[open_world_scaling] WARN: catalog parse failed or disabled — scaling block not rewritten")

    settings = resolve_source(repo_root, "settings/default/map.lua", required=False)
    if settings is not None:
        cap = _parse_cap(settings.read_text(encoding="utf-8", errors="replace"))
        if cap and write_between_markers(page, "server-features-damage-cap", _cap_md(cap)):
            wrote.append(f"damage-cap({cap:,})")
        elif not cap:
            print("[open_world_scaling] WARN: GLOBAL_HP_DAMAGE_CAP not found — cap block not rewritten")

    if wrote:
        print(f"[open_world_scaling] wrote: {', '.join(wrote)}")
    else:
        print("[open_world_scaling] nothing written (markers missing?)")
