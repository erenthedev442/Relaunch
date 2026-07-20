"""Sync docs/endgame/apex-paragon.md with the Apex Trials + Paragon catalogs.

Everything player-facing is derived from the two source catalogs so the page
can never drift from the live tuning:
  * apex_catalog.lua    -> scaling math (level/HP/Paragon-Point curves), affixes
  * paragon_catalog.lua -> perks (+ their hard caps), level costs, titles, daily buff

Markers written:
  apex-overview     -- what Apex Trials is + the climb loop
  apex-scaling      -- a sample tier->level/HP/points table (computed)
  apex-affixes      -- affix pool + reward formula
  paragon-overview  -- the Paragon board
  paragon-perks     -- perk table with auto-computed caps (perRank * maxRank)
  paragon-levels    -- Paragon Level cost curve + title thresholds
  paragon-daily     -- the Daily Might buff
"""
from __future__ import annotations

import math
import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy

# The Apex Arbiter / Paragon Sage hubs are NEVER hardcoded here: they are placed
# by addOverrides in ApexTrials.lua / Paragon.lua, and custom NPCs get
# consolidated between hubs over time (the 2026-07-06 move to Purgonorgo Isle).
# Emit npc_location_inject's tokens instead; they read those SAME modules (see
# _NPC_FILES["apex"] / ["paragon"]) and expand to the NPCs' live zones on every
# build, so the overview prose can't drift the way literal "Leafallia" would.
_APEX_LOC = "{{npc:apex}}"
_PARAGON_LOC = "{{npc:paragon}}"

# Friendly names for the perk modKeys (auto-falls back to the raw key).
_MOD_LABEL = {
    "HP": "Max HP",
    "ATT": "Attack",
    "RATT": "Ranged Attack",
    "ACC": "Accuracy",
    "RACC": "Ranged Accuracy",
    "DEF": "Defense",
    "MATT": "Magic Attack",
    "MACC": "Magic Accuracy",
    "MAGIC_DAMAGE": "Magic Damage",
    "PET_ATK_DEF": "Pet ATK/RATK/DEF",
    "PET_ACC_EVA": "Pet ACC/RACC/EVA",
    "PET_MAB_MDB": "Pet Magic ATK/DEF",
    "PET_MACC_MEVA": "Pet Magic ACC/EVA",
    "PET_ATTR_BONUS": "Pet Attributes",
    "PET_TP_BONUS": "Pet TP Bonus",
}


def _num(text: str, name: str, default, cast=int):
    m = re.search(rf"C\.{re.escape(name)}\s*=\s*([\d.]+)", text)
    return cast(m.group(1)) if m else default


def _table_num(text: str, table: str, name: str, default, cast=int):
    block = section(text, f"C.{table}")
    m = re.search(rf"\b{re.escape(name)}\s*=\s*([\d.]+)", block)
    return cast(m.group(1)) if m else default


def _parse_apex(text: str) -> dict:
    a = {
        "level_t1":    _num(text, "LEVEL_T1", 135),
        "level_t50":   _num(text, "LEVEL_T50", 145),
        "level_t100":  _num(text, "LEVEL_T100", 150),
        "level_cap":   _num(text, "LEVEL_CAP", 150),
        "base_hp":     _num(text, "BASE_HP", 1500000),
        "hp_growth_1": _num(text, "HP_T1_GROWTH", 1.0335, float),
        "hp_growth_2": _num(text, "HP_T51_GROWTH", 1.02, float),
        "hp_tail":     _num(text, "POST_100_HP_GAIN", 2.315, float),
        "mod_t1": {
            "att": _table_num(text, "MOD_T1", "att", 4500),
            "def": _table_num(text, "MOD_T1", "def", 1500),
            "acc": _table_num(text, "MOD_T1", "acc", 2200),
            "eva": _table_num(text, "MOD_T1", "eva", 800),
        },
        "mod_t50": {
            "att": _table_num(text, "MOD_T50", "att", 10000),
            "def": _table_num(text, "MOD_T50", "def", 5000),
            "acc": _table_num(text, "MOD_T50", "acc", 5400),
            "eva": _table_num(text, "MOD_T50", "eva", 2500),
        },
        "mod_t100": {
            "att": _table_num(text, "MOD_T100", "att", 18000),
            "def": _table_num(text, "MOD_T100", "def", 8000),
            "acc": _table_num(text, "MOD_T100", "acc", 9000),
            "eva": _table_num(text, "MOD_T100", "eva", 4000),
        },
        "mod_t500": {
            "att": _table_num(text, "MOD_T500", "att", 24000),
            "def": _table_num(text, "MOD_T500", "def", 11200),
            "acc": _table_num(text, "MOD_T500", "acc", 12200),
            "eva": _table_num(text, "MOD_T500", "eva", 5600),
        },
        "mod_caps": {
            "att": _table_num(text, "MOD_CAPS", "att", 25000),
            "def": _table_num(text, "MOD_CAPS", "def", 14000),
            "acc": _table_num(text, "MOD_CAPS", "acc", 14000),
            "eva": _table_num(text, "MOD_CAPS", "eva", 8000),
        },
        "pp_base": _num(text, "PP_BASE", 10),
        "pp_step": _num(text, "PP_PER_TIER", 5),
    }
    a["bosses"] = re.findall(r"'([^']+)'", section(text, "C.BOSS_NAMES"))
    a["affixes"] = re.findall(r"key\s*=\s*'([^']+)'", section(text, "C.AFFIX_DEFS"))
    a["affix_milestones"] = [
        int(v) for v in re.findall(r"\d+", section(text, "C.AFFIX_MILESTONES"))
    ]
    return a


def _parse_paragon(text: str) -> dict:
    p = {
        "level_base":  _num(text, "LEVEL_COST_BASE", 25),
        "level_step":  _num(text, "LEVEL_COST_STEP", 5),
        "daily_unlock": _num(text, "DAILY_MIGHT_UNLOCK", 80),
        "daily_dur":   _num(text, "DAILY_MIGHT_DURATION", 7200),
        "daily_hp":    _num(text, "DAILY_MIGHT_HP", 3000),
        "daily_regain": _num(text, "DAILY_MIGHT_REGAIN", 50),
        "perks": [],
        "titles": [],
    }
    block = section(text, "C.PERKS")
    for m in re.finditer(
        r"label\s*=\s*'([^']+)'.*?modKeys\s*=\s*\{([^}]*)\}.*?perRank\s*=\s*(\d+).*?maxRank\s*=\s*(\d+)",
        block,
    ):
        mods = re.findall(r"'([^']+)'", m.group(2))
        per, mx = int(m.group(3)), int(m.group(4))
        p["perks"].append({
            "label": m.group(1),
            "mods": [_MOD_LABEL.get(k, k) for k in mods],
            "per": per, "max": mx, "cap": per * mx,
        })
    for m in re.finditer(r"lvl\s*=\s*(\d+)\s*,\s*name\s*=\s*'([^']+)'", section(text, "C.TITLE_TIERS")):
        p["titles"].append({"lvl": int(m.group(1)), "name": m.group(2)})
    p["titles"].sort(key=lambda t: t["lvl"])
    return p


# --- renderers -------------------------------------------------------------

def _render_apex_overview(a: dict) -> str:
    names = ", ".join(a["bosses"][:3]) + ("…" if len(a["bosses"]) > 3 else "")
    return (
        "**Apex Trials** is an **infinite, scaling solo climb** — the one chase on the server "
        f"with no summit. Talk to the **Apex Arbiter** in {_APEX_LOC} (`!hub`, endgame row, beside the "
        "Prime Armory) to begin. The chat command only reports progress or ends an active climb.\n\n"
        "Each **tier** pits you against a single scaled Apex boss "
        f"({names}). Clear it and you **bank Paragon Points** and raise your **record**, then the "
        "next tier spawns automatically — a little tougher. Keep climbing until you die or leave; "
        "**the run ends, but every Paragon Point you banked on the way up is kept.** Your next run "
        "resumes one tier above your record.\n\n"
        f"The climb begins at **level {a['level_t1']}** and reaches its permanent **level "
        f"{a['level_cap']} cap** at tier 100. Difficulty after that comes from HP, safe stat "
        "growth, affixes, and mechanics rather than unviable mob levels. Walk of Echoes rules "
        "apply: **solo (no Trusts), but your pets work.**"
    )


def _render_apex_scaling(a: dict) -> str:
    def lerp(start, finish, position, span):
        return int(math.floor(start + (finish - start) * position / span + 0.5))

    def progress(t):
        return math.log(1 + (t - 100) / 100) / math.log(5) if t > 100 else 0

    def lvl(t):
        if t <= 50:
            return lerp(a["level_t1"], a["level_t50"], t - 1, 49)
        if t <= 100:
            return lerp(a["level_t50"], a["level_t100"], t - 50, 50)
        return a["level_cap"]

    hp50 = a["base_hp"] * (a["hp_growth_1"] ** 49)
    hp100 = hp50 * (a["hp_growth_2"] ** 50)

    def hp(t):
        if t <= 50:
            return int(a["base_hp"] * (a["hp_growth_1"] ** (t - 1)))
        if t <= 100:
            return int(hp50 * (a["hp_growth_2"] ** (t - 50)))
        return int(hp100 * (1 + a["hp_tail"] * progress(t)))

    def mod(t, key):
        if t <= 50:
            return lerp(a["mod_t1"][key], a["mod_t50"][key], t - 1, 49)
        if t <= 100:
            return lerp(a["mod_t50"][key], a["mod_t100"][key], t - 50, 50)
        value = a["mod_t100"][key] + (
            a["mod_t500"][key] - a["mod_t100"][key]
        ) * progress(t)
        return min(a["mod_caps"][key], int(math.floor(value + 0.5)))

    def pp(t):
        return a["pp_base"] + (t - 1) * a["pp_step"]

    lines = [
        "The climb has three bands: **Relic + T5 augments through tier 50**, prepared "
        "**Prime/final REMA builds through tier 100**, then a diminishing elite curve. "
        f"Boss level never exceeds **{a['level_cap']}**:",
        "",
        "| Tier | Boss level | Base HP | Attack | Defense | Accuracy | Paragon Points |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for t in (1, 25, 50, 75, 100, 200, 300, 500):
        lines.append(
            f"| {t} | {lvl(t)} | {commafy(hp(t))} | {commafy(mod(t, 'att'))} | "
            f"{commafy(mod(t, 'def'))} | {commafy(mod(t, 'acc'))} | {commafy(pp(t))} |"
        )
    lines += [
        "",
        f"HP grows by **{(a['hp_growth_1'] - 1) * 100:.2f}% per tier** through 50, "
        f"**{(a['hp_growth_2'] - 1) * 100:.0f}% per tier** through 100, then logarithmically. "
        "Displayed combat stats are the guaranteed base modifiers before affixes and mechanics.",
    ]
    return "\n".join(lines)


def _render_apex_affixes(a: dict) -> str:
    affix_str = ", ".join(f"**{x}**" for x in a["affixes"])
    milestones = ", ".join(str(x) for x in a["affix_milestones"])
    return (
        f"Bosses gain an additional affix at tiers **{milestones}** (up to "
        f"**{len(a['affixes'])}** stacked), drawn from: {affix_str}. Affix strength is capped "
        "so combinations remain below engine modifier limits and never replace the tier curve.\n\n"
        f"**Paragon Points** banked for a new tier = **{a['pp_base']} + {a['pp_step']} × (tier − 1)** "
        "— and each tier only ever pays out once (your record only goes up), so it's pure "
        "push-your-record, never a farm."
    )


def _render_paragon_overview(p: dict) -> str:
    return (
        "**Paragon** is the meta-progression Apex Trials feeds. Spend the Paragon Points you bank "
        f"at the **Paragon Sage** in {_PARAGON_LOC} (`!hub`, next to the Apex Arbiter) on three things: an infinite "
        "**Paragon Level** prestige track, permanent **capped perks**, and the **Daily Might** buff. "
        "It's deliberately flex-and-flavour — the perk caps are modest next to maxed gear, so "
        "Paragon is a prestige climb, not a power treadmill."
    )


def _render_paragon_perks(p: dict) -> str:
    lines = [
        "Permanent stat boosts, applied automatically every time you log in or zone. Each has "
        "**10 ranks**; the cap is reached at max rank:",
        "",
        "| Perk | Boosts | Per rank | Cap (max rank) |",
        "|---|---|---:|---:|",
    ]
    for k in p["perks"]:
        mods = " & ".join(k["mods"])
        lines.append(f"| **{k['label']}** | {mods} | +{k['per']} | **+{commafy(k['cap'])}** |")
    return "\n".join(lines)


def _render_paragon_levels(p: dict) -> str:
    lines = [
        f"Ascending from Paragon Level *N* to *N+1* costs **{p['level_base']} + {p['level_step']} × N** "
        "Paragon Points — an endless prestige track that shows on `!reallevel` and the leaderboards. "
        "Your Paragon Level earns a scaling **title**:",
        "",
        "| Paragon Level | Title |",
        "|---:|---|",
        "| 0 | Aspirant |",
    ]
    for t in p["titles"]:
        lines.append(f"| {t['lvl']}+ | {t['name']} |")
    return "\n".join(lines)


def _render_paragon_daily(p: dict) -> str:
    hours = p["daily_dur"] // 3600
    return (
        f"Unlock **Daily Might** once for **{commafy(p['daily_unlock'])} Paragon Points**, then claim "
        f"it from the Paragon Sage **once per day**. It grants a **{hours}-hour surge**: "
        f"**+{commafy(p['daily_hp'])} max HP**, **Regain {p['daily_regain']} TP/tick**, plus **Refresh** "
        "and **Regen** scaled to your max MP/HP. A daily reason to log in, and a head start on your "
        "next climb."
    )


# --- entry -----------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    apex_src = resolve_source(repo_root, "modules/custom/lua/apex_catalog.lua")
    para_src = resolve_source(repo_root, "modules/custom/lua/paragon_catalog.lua")
    if apex_src is None or para_src is None:
        print("[apex_paragon] skip: catalog(s) not found")
        return

    a = _parse_apex(apex_src.read_text(encoding="utf-8", errors="replace"))
    p = _parse_paragon(para_src.read_text(encoding="utf-8", errors="replace"))

    page = docs_dir / "endgame" / "apex-paragon.md"
    blocks = [
        ("apex-overview",    _render_apex_overview(a)),
        ("apex-scaling",     _render_apex_scaling(a)),
        ("apex-affixes",     _render_apex_affixes(a)),
        ("paragon-overview", _render_paragon_overview(p)),
        ("paragon-perks",    _render_paragon_perks(p)),
        ("paragon-levels",   _render_paragon_levels(p)),
        ("paragon-daily",    _render_paragon_daily(p)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[apex_paragon] {written}/{len(blocks)} marker block(s) written "
          f"(perks={len(p['perks'])}, affixes={len(a['affixes'])}, titles={len(p['titles'])})")
