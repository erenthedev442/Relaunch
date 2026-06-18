"""Generate the custom-spells reference page from live source.

Three spells on Legendary do not exist on retail FFXI. Their player-facing
numbers live in two places, and this generator keeps the doc page in sync
with both so the hand-written page can't drift:

  (a) Hunt-Mark PRICE + job/level string per spell come from the Hunting
      League catalog's "Spells" reward category in
      `modules/custom/lua/hunting_league_catalog.lua` (each entry has a
      display `name`, a `cost`, and a `stats` list whose first line is the
      job/level requirement, e.g. 'PLD 50' or 'WHM 40 / RDM 50 / SCH 50').

  (b) FORMULA CONSTANTS (power cap, multipliers, AoE radius, durations,
      element/enfeeble pairs) come straight from the spell scripts:
        scripts/actions/spells/white/divine_aegis.lua
        scripts/actions/spells/white/convergence.lua
        scripts/actions/spells/white/silencega.lua  (no custom constants)

Output marker IDs in docs/reference/custom-spells.md:
  - custom-spell-divine-aegis             (price / job / level line)
  - custom-spell-divine-aegis-shield      (power formula + PDT + duration)
  - custom-spell-divine-aegis-detonation  (AoE damage formula + radius + type)
  - custom-spell-convergence              (price / job / level line)
  - custom-spell-convergence-pairs        (element/enfeeble/duration table)
  - custom-spell-convergence-formula      (INT/MND damage formula)
  - custom-spell-silencega                (price / job / level line)

The catalog (modules/custom/) is gitignored, so this generator usually runs
against `$LEGENDARY_LIVE_ROOT`. Without it (CI), the catalog won't resolve
and price blocks skip cleanly; the spell scripts ARE committed, so formula
blocks still regenerate from the repo. Each block also has a sanity guard:
if the source clearly contains the constant but the parser extracts nothing,
the block is left untouched (keeps the published value) rather than blanked.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# Reuse the catalog-parsing primitives from the Hunting League generator so
# both stay consistent (balanced-brace scanner + Lua string-literal capture).
from tools.docgen.generators.hunting_league import (
    _balanced_blocks,
    _QUOTED,
    _quoted_value,
)

CATALOG = "modules/custom/lua/hunting_league_catalog.lua"
AEGIS_SRC = "scripts/actions/spells/white/divine_aegis.lua"
CONVERGENCE_SRC = "scripts/actions/spells/white/convergence.lua"
SILENCEGA_SRC = "scripts/actions/spells/white/silencega.lua"

# Catalog display names of the three custom spell scrolls.
SPELL_SCROLLS = {
    "divine_aegis": "Scroll of Divine Aegis",
    "convergence": "Scroll of Convergence",
    "silencega": "Scroll of Silencega",
}

# Static per-spell prose attributes that aren't numbers in any source
# (magic skill / school labels). Kept here so the rendered price line reads
# the same as the hand-written original.
SPELL_META = {
    "divine_aegis": "White Magic · {job} · {level} · Divine / Enhancing",
    "convergence": "Enfeebling Magic · {job} · {level}",
    "silencega": "Enfeebling Magic · {jobline}",
}

# Map xi.effect.* identifiers used in convergence's PAIRS table to the
# player-facing status name shown in the doc table.
EFFECT_LABELS = {
    "SLOW": "Slow",
    "BLINDNESS": "Blind",
    "PARALYSIS": "Paralysis",
    "SILENCE": "Silence",
    "WEIGHT": "Gravity",
    "BIND": "Bind",
}

# Element id -> (column label, damage-type label). Element and damage type
# share a name in the doc table.
ELEMENT_LABELS = {
    "FIRE": "Fire",
    "LIGHT": "Light",
    "WATER": "Water",
    "EARTH": "Earth",
    "WIND": "Wind",
    "THUNDER": "Thunder",
}


# ----------------------------------------------------------------------------
# Catalog: price + job/level per spell
# ----------------------------------------------------------------------------

def _inner_block(text: str, field: str) -> str | None:
    """Return the contents of `field = { ... }` (braces stripped), or None.

    Locates the field, then uses the balanced-brace scanner to find its
    table body — same approach hunting_league uses for `tiers`/`rewards`."""
    m = re.search(r"\b" + re.escape(field) + r"\s*=\s*", text)
    if not m:
        return None
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return None
    return remaining[outer[0] + 1: outer[1] - 1]


def _extract_spell_prices(text: str) -> dict[str, dict]:
    """Pull {cost, req} for each custom spell scroll from the catalog.

    Drills `rewardCategories = { ... }` -> each category's `items = { ... }`
    -> each item entry, matching our scroll display names and reading the
    `cost` plus the first `stats` string (the job/level requirement line)."""
    name_re = re.compile(r"\bname\s*=\s*" + _QUOTED)
    cost_re = re.compile(r"\bcost\s*=\s*(\d+)")

    out: dict[str, dict] = {}

    categories = _inner_block(text, "rewardCategories")
    if categories is None:
        return out

    for cstart, cend in _balanced_blocks(categories):
        category = categories[cstart + 1: cend - 1]
        items_body = _inner_block(category, "items")
        if items_body is None:
            continue
        for istart, iend in _balanced_blocks(items_body):
            item = items_body[istart + 1: iend - 1]
            nm = name_re.search(item)
            if not nm:
                continue
            display = _quoted_value(nm)
            key = next((k for k, v in SPELL_SCROLLS.items() if v == display), None)
            if key is None:
                continue
            cost_m = cost_re.search(item)
            stats0 = _first_stats_line(item)
            if cost_m is None or stats0 is None:
                continue
            out[key] = {"cost": int(cost_m.group(1)), "req": stats0}
    return out


def _first_stats_line(item_body: str) -> str | None:
    """Return the first quoted string inside the item's `stats = { ... }`."""
    m = re.search(r"\bstats\s*=\s*", item_body)
    if not m:
        return None
    remaining = item_body[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return None
    stats_block = remaining[outer[0] + 1: outer[1] - 1]
    first = re.search(_QUOTED, stats_block)
    return _quoted_value(first) if first else None


# A requirement line is one or more "JOB LEVEL" clauses separated by '/'.
_REQ_CLAUSE = re.compile(r"^[A-Z]{3}\s+\d{1,3}$")


def _parse_req(req: str) -> dict:
    """Split a 'PLD 50' or 'WHM 40 / RDM 50 / SCH 50' line into parts.

    Returns {single: bool, job, level, jobline}. For a single-job spell,
    `job`/`level` are filled; `jobline` is always the normalized full string."""
    clauses = [c.strip() for c in req.split("/")]
    valid = [c for c in clauses if _REQ_CLAUSE.match(c)]
    jobline = " / ".join(valid) if valid else req.strip()
    if len(valid) == 1:
        job, level = valid[0].split()
        return {"single": True, "job": job, "level": f"Level {level}", "jobline": jobline}
    return {"single": False, "job": None, "level": None, "jobline": jobline}


def _render_price_line(key: str, info: dict) -> str:
    req = _parse_req(info["req"])
    tail = SPELL_META[key].format(
        job=(req["job"] + " only") if req["job"] else "",
        level=req["level"] or "",
        jobline=req["jobline"],
    )
    return f"**{info['cost']} Hunt Marks** · {tail}"


# ----------------------------------------------------------------------------
# Divine Aegis script constants
# ----------------------------------------------------------------------------

def _parse_divine_aegis(text: str) -> dict | None:
    # power = math.min(150 + vit * 6 + math.floor(maxhp * 0.12), 3000)
    pwr = re.search(
        r"math\.min\(\s*(\d+)\s*\+\s*\w+\s*\*\s*(\d+)\s*\+\s*"
        r"math\.floor\(\s*\w+\s*\*\s*([0-9.]+)\s*\)\s*,\s*(\d+)\s*\)",
        text,
    )
    delay = re.search(r"\bDETONATE_DELAY\s*=\s*(\d+)", text)
    aoe = re.search(r"\bAoE_RANGE\s*=\s*(\d+)", text)
    pdt = re.search(r"\bPDT_BONUS\s*=\s*(-?\d+)", text)
    absorb = re.search(r"math\.floor\(\s*absorbed\s*\*\s*([0-9.]+)\s*\)", text)
    if not (pwr and delay and aoe and pdt and absorb):
        return None
    return {
        "base": int(pwr.group(1)),
        "vit_mult": int(pwr.group(2)),
        "hp_mult": pwr.group(3),
        "cap": int(pwr.group(4)),
        "duration_s": int(delay.group(1)) // 1000,
        "aoe": int(aoe.group(1)),
        # addMod units: -2000 = -20% physical damage taken.
        "pdt_pct": abs(int(pdt.group(1))) // 100,
        "absorb_mult": absorb.group(1),
    }


def _render_aegis_shield(d: dict) -> str:
    return (
        "```\n"
        f"power      = min( {d['base']} + VIT×{d['vit_mult']} + maxHP×{d['hp_mult']} , {d['cap']} )\n"
        f"PDT buff   = −{d['pdt_pct']}% physical damage taken\n"
        f"duration   = {d['duration_s']} seconds\n"
        "```"
    )


def _render_aegis_detonation(d: dict) -> str:
    return (
        "```\n"
        f"AoE damage = floor( damage_absorbed × {d['absorb_mult']} )\n"
        f"Radius     = {d['aoe']} yalms  (centered on the caster)\n"
        "Damage type = Light (Holy)\n"
        "```"
    )


# ----------------------------------------------------------------------------
# Convergence script constants
# ----------------------------------------------------------------------------

def _parse_convergence(text: str) -> dict | None:
    # baseDmg = math.floor(int * 2.5 + mnd * 2.0 + 80)
    dmg = re.search(
        r"math\.floor\(\s*\w+\s*\*\s*([0-9.]+)\s*\+\s*\w+\s*\*\s*([0-9.]+)\s*\+\s*(\d+)\s*\)",
        text,
    )
    pairs = _parse_convergence_pairs(text)
    if not dmg or not pairs:
        return None
    return {
        "int_mult": dmg.group(1),
        "mnd_mult": dmg.group(2),
        "flat": int(dmg.group(3)),
        "pairs": pairs,
    }


def _parse_convergence_pairs(text: str) -> list[dict]:
    """Read the PAIRS = { ... } table: effect, element, duration per row."""
    m = re.search(r"\bPAIRS\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    table = remaining[outer[0] + 1: outer[1] - 1]

    rows = []
    eff_re = re.compile(r"\beffect\s*=\s*xi\.effect\.(\w+)")
    elem_re = re.compile(r"\belement\s*=\s*xi\.element\.(\w+)")
    dur_re = re.compile(r"\bduration\s*=\s*(\d+)")
    for rs, re_ in _balanced_blocks(table):
        body = table[rs + 1: re_ - 1]
        eff = eff_re.search(body)
        elem = elem_re.search(body)
        dur = dur_re.search(body)
        if eff and elem and dur:
            rows.append({
                "effect": eff.group(1),
                "element": elem.group(1),
                "duration": int(dur.group(1)),
            })
    return rows


def _render_convergence_pairs(pairs: list[dict]) -> str:
    lines = [
        "| Roll | Element | Damage type | Status effect | Duration |",
        "|---:|---|---|---|---|",
    ]
    for i, p in enumerate(pairs, start=1):
        elem = ELEMENT_LABELS.get(p["element"], p["element"].capitalize())
        status = EFFECT_LABELS.get(p["effect"], p["effect"].capitalize())
        lines.append(f"| {i} | {elem} | {elem} | **{status}** | {p['duration']} s |")
    return "\n".join(lines)


def _render_convergence_formula(d: dict) -> str:
    return (
        "```\n"
        f"base    = floor( INT×{d['int_mult']} + MND×{d['mnd_mult']} + {d['flat']} )\n"
        "damage  = max(1, floor( base × resistRate ))\n"
        "```"
    )


# ----------------------------------------------------------------------------
# Orchestration
# ----------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "reference" / "custom-spells.md"
    if not page.exists():
        print(f"[custom_spells] skip: {page} not found")
        return

    # --- Prices / job-level lines (from catalog) ---------------------------
    cat_src = resolve_source(repo_root, CATALOG)
    prices: dict[str, dict] = {}
    if cat_src is None:
        print(f"[custom_spells] price blocks skipped: {CATALOG} not found "
              f"(no LEGENDARY_LIVE_ROOT?)")
    else:
        cat_text = cat_src.read_text(encoding="utf-8", errors="replace")
        prices = _extract_spell_prices(cat_text)
        # Sanity guard: the catalog clearly lists our scrolls, but we parsed
        # none. A field rename would otherwise blank the price lines.
        present = sum(1 for v in SPELL_SCROLLS.values() if v in cat_text)
        if present > 0 and not prices:
            print(f"[custom_spells] price blocks: PARSER REGRESSION -- "
                  f"{present} scroll names in catalog but 0 parsed; keeping "
                  f"existing published content")

    def _write_price(key: str, marker: str):
        info = prices.get(key)
        if info is None:
            return  # leave the published line untouched
        content = _render_price_line(key, info)
        if not write_between_markers(page, marker, content):
            print(f"[custom_spells] {marker}: markers not found in {page.name}")

    _write_price("divine_aegis", "custom-spell-divine-aegis")
    _write_price("convergence", "custom-spell-convergence")
    _write_price("silencega", "custom-spell-silencega")

    # --- Formula constants (from spell scripts) ----------------------------
    _write_block(
        repo_root, page, AEGIS_SRC,
        _parse_divine_aegis,
        [
            ("custom-spell-divine-aegis-shield", _render_aegis_shield),
            ("custom-spell-divine-aegis-detonation", _render_aegis_detonation),
        ],
        signal=r"math\.min\(",  # the power formula anchor
    )

    _write_block(
        repo_root, page, CONVERGENCE_SRC,
        _parse_convergence,
        [
            ("custom-spell-convergence-pairs",
             lambda d: _render_convergence_pairs(d["pairs"])),
            ("custom-spell-convergence-formula", _render_convergence_formula),
        ],
        signal=r"\bPAIRS\s*=",
    )

    # Silencega has no custom constants (vanilla enfeebling), so only its
    # price line is generated above — nothing to do from its script.

    n_price = len(prices)
    print(f"[custom_spells] wrote {n_price} price line(s) + formula blocks "
          f"into {page.name}")


def _write_block(repo_root: Path, page: Path, sub_path: str, parser, blocks,
                 signal: str) -> None:
    """Parse one spell script and fill its marker blocks.

    `parser(text) -> dict | None`. `blocks` is a list of
    (marker_id, render(parsed)->str). `signal` is a regex whose presence in
    the source means "this constant exists"; if it matches but the parser
    returns None, we keep the published content instead of blanking."""
    src = resolve_source(repo_root, sub_path)
    if src is None:
        print(f"[custom_spells] {sub_path}: source not found, skipping its blocks")
        return
    text = src.read_text(encoding="utf-8", errors="replace")
    parsed = parser(text)
    if parsed is None:
        if re.search(signal, text):
            name = Path(sub_path).name
            print(f"[custom_spells] {name}: PARSER REGRESSION -- source has "
                  f"constants but parse failed; keeping existing content")
        return
    for marker, render in blocks:
        content = render(parsed)
        if not write_between_markers(page, marker, content):
            print(f"[custom_spells] {marker}: markers not found in {page.name}")
