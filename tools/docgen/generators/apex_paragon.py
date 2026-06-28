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

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy

# Friendly names for the perk modKeys (auto-falls back to the raw key).
_MOD_LABEL = {
    "HP": "Max HP",
    "ATT": "Attack",
    "RATT": "Ranged Attack",
    "ACC": "Accuracy",
    "RACC": "Ranged Accuracy",
    "DEF": "Defense",
}


def _num(text: str, name: str, default, cast=int):
    m = re.search(rf"C\.{re.escape(name)}\s*=\s*([\d.]+)", text)
    return cast(m.group(1)) if m else default


def _parse_apex(text: str) -> dict:
    a = {
        "base_level": _num(text, "BASE_LEVEL", 165),
        "level_step": _num(text, "LEVEL_STEP", 4),
        "level_cap":  _num(text, "LEVEL_CAP", 230),
        "base_hp":    _num(text, "BASE_HP", 9000000),
        "hp_growth":  _num(text, "HP_GROWTH", 1.13, float),
        "att":        _num(text, "ATT_PER_TIER", 450),
        "deff":       _num(text, "DEF_PER_TIER", 380),
        "acc":        _num(text, "ACC_PER_TIER", 70),
        "eva":        _num(text, "EVA_PER_TIER", 50),
        "pp_base":    _num(text, "PP_BASE", 10),
        "pp_step":    _num(text, "PP_PER_TIER", 5),
    }
    a["bosses"] = re.findall(r"'([^']+)'", section(text, "C.BOSS_NAMES"))
    a["affixes"] = re.findall(r"key\s*=\s*'([^']+)'", section(text, "C.AFFIX_DEFS"))
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
        "with no summit. Talk to the **Apex Arbiter** in **Leafallia** (`!leaf`, endgame row, beside the "
        "Prime Armory) or type `!apex` to begin.\n\n"
        "Each **tier** pits you against a single scaled Apex boss "
        f"({names}). Clear it and you **bank Paragon Points** and raise your **record**, then the "
        "next tier spawns automatically — a little tougher. Keep climbing until you die or leave; "
        "**the run ends, but every Paragon Point you banked on the way up is kept.** Your next run "
        "resumes one tier above your record.\n\n"
        f"The first boss is around **level {a['base_level']}** — a step above the toughest Hunting "
        "League NMs — and it only goes up from there. Walk of Echoes rules apply: **solo (no "
        "Trusts), but your pets work.**"
    )


def _render_apex_scaling(a: dict) -> str:
    def lvl(t):  return min(a["level_cap"], a["base_level"] + (t - 1) * a["level_step"])
    def hp(t):   return int(a["base_hp"] * (a["hp_growth"] ** (t - 1)))
    def pp(t):   return a["pp_base"] + (t - 1) * a["pp_step"]

    lines = [
        "A taste of the curve (difficulty climbs forever — level is capped at "
        f"**{a['level_cap']}**, after which HP and stats carry it):",
        "",
        "| Tier | Boss level | Boss HP | Paragon Points (first clear) |",
        "|---:|---:|---:|---:|",
    ]
    for t in (1, 5, 10, 20, 30, 50):
        lines.append(f"| {t} | {lvl(t)} | {commafy(hp(t))} | {commafy(pp(t))} |")
    lines += [
        "",
        f"HP multiplies by **×{a['hp_growth']}** per tier, and the boss also gains roughly "
        f"**+{a['att']} Attack / +{a['deff']} Defense / +{a['acc']} Accuracy / +{a['eva']} Evasion** "
        "per tier on top.",
    ]
    return "\n".join(lines)


def _render_apex_affixes(a: dict) -> str:
    affix_str = ", ".join(f"**{x}**" for x in a["affixes"])
    return (
        f"From tier 5 on, each boss rolls an extra **affix** every 5 tiers (up to "
        f"**{len(a['affixes'])}** stacked at once), drawn from: {affix_str}. Affixes also "
        "intensify the deeper you go.\n\n"
        f"**Paragon Points** banked for a new tier = **{a['pp_base']} + {a['pp_step']} × (tier − 1)** "
        "— and each tier only ever pays out once (your record only goes up), so it's pure "
        "push-your-record, never a farm."
    )


def _render_paragon_overview(p: dict) -> str:
    return (
        "**Paragon** is the meta-progression Apex Trials feeds. Spend the Paragon Points you bank "
        "at the **Paragon Sage** in **Leafallia** (`!leaf`, next to the Apex Arbiter) on three things: an infinite "
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
