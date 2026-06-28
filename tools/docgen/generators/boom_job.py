"""Sync docs/progression/boom-job.md with boom_job_catalog.lua.

Boom repurposes the Summoner slot (job 15) into a pet-less staff melee/hybrid
DD whose elemental spells DETONATE. Its passive traits, the per-spell
detonation odds/multipliers, and the Ignite window all come from the catalog,
so re-tuning the Lua updates the published tables (they can't drift).

The catalog stores traits as `{ xi.mod.NAME, value }` pairs, so we translate
each mod constant to plain English (no `xi.mod.*` names reach the page).

Markers written:
  boom-overview  — what the job is + how detonations / Ignite work (prose)
  boom-traits    — passive traits/mods with values
  boom-spells    — detonation spells: chance / damage multiplier / AoE radius
  boom-ignite    — the Ignite window: enspells, duration, boosted chance
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# xi.mod.NAME -> player-facing label. Each entry is rendered "<label> <+value>".
# Kept explicit (not a value lookup) so a tuned number never mislabels a row.
_MOD_LABELS = {
    "HP":            "Maximum HP",
    "MP":            "Maximum MP",
    "STR":           "STR",
    "DEX":           "DEX",
    "VIT":           "VIT",
    "AGI":           "AGI",
    "INT":           "INT",
    "MND":           "MND",
    "CHR":           "CHR",
    "ATTP":          "Attack",
    "ATT":           "Attack",
    "ACC":           "Accuracy",
    "DOUBLE_ATTACK": "Double Attack",
    "CRITHITRATE":   "Critical Hit Rate",
    "STORETP":       "Store TP",
    "STAFF":         "Staff skill",
    "ELEM":          "Elemental Magic skill",
    "MATT":          "Magic Attack",
    "MACC":          "Magic Accuracy",
    "FASTCAST":      "Fast Cast",
}

# Mods whose value is a percentage (rendered "+N%" instead of "+N").
_PERCENT_MODS = {"ATTP", "DOUBLE_ATTACK", "CRITHITRATE", "FASTCAST", "STORETP"}


def _parse(text: str) -> dict:
    c: dict = {}

    # ── Traits: list of { xi.mod.NAME, value } ──────────────────────────────
    traits_block = section(text, "catalog.traits")
    traits = []
    for name, val in re.findall(r"xi\.mod\.(\w+)\s*,\s*(-?\d+)", traits_block):
        traits.append((name, int(val)))
    c["traits"] = traits

    # ── Spells: each { id=, name='', chance=, mult=, aoe= } ──────────────────
    spells_block = section(text, "catalog.spells")
    spells = []
    for entry in re.findall(r"\{[^{}]*\}", spells_block):
        nm = re.search(r"name\s*=\s*'([^']+)'", entry)
        if not nm:
            continue
        ch = re.search(r"chance\s*=\s*(\d+)", entry)
        ml = re.search(r"mult\s*=\s*(\d+)", entry)
        ao = re.search(r"aoe\s*=\s*(\d+)", entry)
        spells.append({
            "name":   nm.group(1),
            "chance": int(ch.group(1)) if ch else 0,
            "mult":   int(ml.group(1)) if ml else 1,
            "aoe":    int(ao.group(1)) if ao else 0,
        })
    c["spells"] = spells

    # ── Enspells: list of ids; we surface the human names ───────────────────
    m = re.search(r"catalog\.enspells\s*=\s*\{([^}]*)\}", text)
    c["enspell_count"] = len(re.findall(r"\d+", m.group(1))) if m else 0
    # The names live in the trailing comment on that line.
    cm = re.search(r"catalog\.enspells\s*=\s*\{[^}]*\}\s*--\s*(.+)", text)
    if cm:
        names = [n.strip() for n in re.split(r"[/,]", cm.group(1)) if n.strip()]
        c["enspell_names"] = names
    else:
        c["enspell_names"] = []

    # ── Ignite window ───────────────────────────────────────────────────────
    ig = section(text, "catalog.ignite")
    c["ignite_duration"] = int(_first(r"duration\s*=\s*(\d+)", ig, "0"))
    c["ignite_boost"]    = int(_first(r"boostChance\s*=\s*(\d+)", ig, "0"))

    # ── Detonation damage formula (for prose only) ──────────────────────────
    bm = section(text, "catalog.boom")
    c["boom_cap"] = int(_first(r"cap\s*=\s*(\d+)", bm, "0"))

    return c


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _trait_value(name: str, val: int) -> str:
    sign = "+" if val >= 0 else ""
    if name in _PERCENT_MODS:
        return f"{sign}{val}%"
    return f"{sign}{commafy(val)}" if abs(val) >= 1000 else f"{sign}{val}"


# ---------------------------------------------------------------------------

def _render_overview(c: dict) -> str:
    # Base (un-Ignited) detonation odds across the two spell families.
    base_chances = sorted({s["chance"] for s in c["spells"] if s["mult"] <= 1})
    big = [s for s in c["spells"] if s["mult"] > 1]
    big_chance = big[0]["chance"] if big else 0
    big_mult = big[0]["mult"] if big else 1

    low = base_chances[0] if base_chances else 0
    lines = [
        "Boom plays like a melee damage-dealer that weaves elemental magic "
        "between weapon swings. **Every spell you cast has a chance to "
        "detonate** — the explosion lands as a separate elemental hit on the "
        "target (and, for the biggest spells, the enemies around it).",
        "",
        f"The bigger the spell, the bigger the boom: your standard nukes "
        f"detonate around **{low}%** of the time, while the heavy Ancient "
        f"Magic detonates far more often (**{big_chance}%**) and hits for "
        f"about **{big_mult}× as hard** with a splash radius.",
        "",
        "There are no commands to trigger any of this. **Cast spells. They "
        "boom.** Casting an enspell opens an **Ignite** window that pushes "
        "every detonation chance up while it lasts.",
    ]
    return "\n".join(lines)


def _render_traits(c: dict) -> str:
    rows = [
        "While Boom is your **main job**, you passively gain:",
        "",
        "| Trait | Bonus |",
        "|---|---|",
    ]
    for name, val in c["traits"]:
        label = _MOD_LABELS.get(name, name.title())
        rows.append(f"| {label} | {_trait_value(name, val)} |")
    return "\n".join(rows)


def _render_spells(c: dict) -> str:
    rows = [
        "| Spell | Detonation chance | Blast damage | Splash radius |",
        "|---|---|---|---|",
    ]
    for s in c["spells"]:
        radius = f"{s['aoe']}" if s["aoe"] > 0 else "—"
        mult = f"{s['mult']}×"
        rows.append(
            f"| **{s['name']}** | {s['chance']}% | {mult} | {radius} |"
        )
    return "\n".join(rows)


def _render_ignite(c: dict) -> str:
    names = c["enspell_names"]
    if names:
        ens = ", ".join(f"**{n}**" for n in names)
    else:
        ens = f"any of your **{c['enspell_count']}** enspells"
    lines = [
        f"Casting any enspell ({ens}) triggers **Ignite** for "
        f"**{c['ignite_duration']} seconds**.",
        "",
        "While Ignite is active:",
        "",
        f"- Every nuke's detonation chance is **floored at "
        f"{c['ignite_boost']}%** — your standard spells boom far more reliably.",
        "- The enspell's own melee enchant keeps your weapon lit between casts, "
        "supporting the hybrid melee rhythm.",
        "",
        "The core loop is **enspell → nuke → nuke → re-enspell** to keep the "
        "window open.",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/boom_job_catalog.lua")
    if src is None:
        print("[boom_job] skip: boom_job_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "boom-job.md"
    blocks = [
        ("boom-overview", _render_overview(c)),
        ("boom-traits", _render_traits(c)),
        ("boom-spells", _render_spells(c)),
        ("boom-ignite", _render_ignite(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[boom_job] {written}/{len(blocks)} marker block(s) written "
          f"(traits={len(c['traits'])}, spells={len(c['spells'])}, "
          f"enspells={c['enspell_count']})")
