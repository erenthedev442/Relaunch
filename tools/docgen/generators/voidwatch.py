"""Sync docs/endgame/voidwatch.md with voidwatch_catalog.lua.

The Voidwatch page is hand-written prose around five data tables that drift as
the catalog is re-tuned. This generator owns those five tables (and only those),
rendering them straight from the catalog so a balance change re-publishes the
docs without a hand edit.

Markers written:
  voidwatch-economy  — Voidstone caps/regen/cost/cruor price + battle/claim timers
  voidwatch-scaling  — tier-scaling formulas (level, HP, cruor/EXP rewards)
  voidwatch-lights   — the 5 Lights (colour, name, reward boon, per-light weight)
  voidwatch-strata   — the 7 abyssite strata (name, base tier, # zones, the 3 NMs)
  voidwatch-atmacite — the 6 Atmacite perks (name + effect + cost)

Player-facing language only — no .lua names, catalog vars, or charVar names in
the rendered output.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _int(pattern: str, text: str, default: int) -> int:
    return int(_first(pattern, text, str(default)))


def _float(pattern: str, text: str, default: float) -> float:
    return float(_first(pattern, text, str(default)))


def _g(v: float) -> str:
    return f"{v:g}"


def _pretty_nm(name: str) -> str:
    return name.replace("_", " ")


# ---------------------------------------------------------------------------
# Parsing

def _parse(text: str) -> dict:
    c: dict = {}

    # ── Economy ──
    c["max_stones"]   = _int(r"C\.MAX_STONES\s*=\s*(\d+)", text, 10)
    c["regen_sec"]    = _int(r"C\.REGEN_SECONDS\s*=\s*(\d+)", text, 3600)
    c["start_stones"] = _int(r"C\.START_STONES\s*=\s*(\d+)", text, 5)
    c["rift_cost"]    = _int(r"C\.RIFT_COST\s*=\s*(\d+)", text, 1)
    c["stone_cruor"]  = _int(r"C\.STONE_CRUOR\s*=\s*(\d+)", text, 400)
    c["battle_sec"]   = _int(r"C\.BATTLE_SECONDS\s*=\s*(\d+)", text, 1800)
    c["pyxis_sec"]    = _int(r"C\.PYXIS_SECONDS\s*=\s*(\d+)", text, 180)

    # ── Tier-scaling coefficients (parsed from the function bodies) ──
    c["lvl_base"], c["lvl_per"] = _affine(
        r"function\s+C\.nmLevel\s*\(\s*tier\s*\)\s*return\s+(\d+)\s*\+\s*tier\s*\*\s*(\d+)", text, 78, 4)
    c["hp_base"], c["hp_per"] = _affine(
        r"function\s+C\.nmHp\s*\(\s*tier\s*\)\s*return\s+(\d+)\s*\+\s*tier\s*\*\s*(\d+)", text, 180000, 110000)
    c["cruor_base"], c["cruor_per"] = _affine(
        r"function\s+C\.cruorReward\s*\(\s*tier\s*\)\s*return\s+(\d+)\s*\+\s*tier\s*\*\s*(\d+)", text, 800, 350)
    c["exp_base"], c["exp_per"] = _affine(
        r"function\s+C\.expReward\s*\(\s*tier\s*\)\s*return\s+(\d+)\s*\+\s*tier\s*\*\s*(\d+)", text, 1500, 600)

    # nmMods attack/accuracy bases + per-tier (for the prose row)
    mods = section(text, "C.nmMods")
    c["att_base"], c["att_per"] = _affine(
        r"\[xi\.mod\.ATT\]\s*=\s*(\d+)\s*\+\s*tier\s*\*\s*(\d+)", mods, 700, 200)
    c["acc_base"], c["acc_per"] = _affine(
        r"\[xi\.mod\.ACC\]\s*=\s*(\d+)\s*\+\s*tier\s*\*\s*(\d+)", mods, 550, 110)

    # ── Lights ──
    lights = section(text, "C.LIGHTS")
    order = re.search(r"order\s*=\s*\{([^}]*)\}", lights)
    c["light_order"] = re.findall(r"'([^']+)'", order.group(1)) if order else \
        ["RED", "BLUE", "GREEN", "YELLOW", "WHITE"]
    c["light_names"] = _kv_map(re.search(r"names\s*=\s*\{([^}]*)\}", lights))
    c["light_boon"]  = _kv_map(re.search(r"boon\s*=\s*\{([^}]*)\}", lights))

    c["quality_per_red"]  = _int(r"C\.QUALITY_PER_RED\s*=\s*(\d+)", text, 8)
    c["rolls_per_2_blue"] = _int(r"C\.ROLLS_PER_2_BLUE\s*=\s*(\d+)", text, 1)
    c["cruor_per_green"]  = _float(r"C\.CRUOR_PER_GREEN\s*=\s*([0-9.]+)", text, 0.25)
    c["exp_per_yellow"]   = _float(r"C\.EXP_PER_YELLOW\s*=\s*([0-9.]+)", text, 0.25)
    c["shard_per_white"]  = _int(r"C\.SHARD_PER_WHITE\s*=\s*(\d+)", text, 1)

    # ── Strata ──
    c["strata"] = _parse_strata(section(text, "C.STRATA"))

    # ── Atmacite ──
    c["atm_cost_mult"] = _int(
        r"function\s+C\.atmCost\s*\(\s*nextLevel\s*\)\s*return\s+nextLevel\s*\*\s*(\d+)", text, 3)
    c["atmacite"] = _parse_atmacite(section(text, "C.ATMACITE"))

    return c


def _affine(pattern: str, text: str, dbase: int, dper: int) -> tuple[int, int]:
    m = re.search(pattern, text)
    if m:
        return int(m.group(1)), int(m.group(2))
    return dbase, dper


def _kv_map(m) -> dict:
    """Parse a Lua `{ KEY = 'val', ... }` body into a dict."""
    if not m:
        return {}
    return dict(re.findall(r"(\w+)\s*=\s*'([^']*)'", m.group(1)))


def _parse_strata(block: str) -> list[dict]:
    """Each stratum entry: { key, name, base, zones=[...], roster=[names] }."""
    out: list[dict] = []
    # Split into per-stratum sub-blocks by the leading `{ key = '...'`.
    for m in re.finditer(r"\{\s*key\s*=\s*'([^']+)'\s*,\s*name\s*=\s*'([^']+)'\s*,\s*base\s*=\s*(\d+)", block):
        key, name, base = m.group(1), m.group(2), int(m.group(3))
        # The zones/roster for this stratum live between this match and the next
        # `key =` (or end of block).
        nxt = re.search(r"\{\s*key\s*=\s*'", block[m.end():])
        tail = block[m.end(): m.end() + nxt.start()] if nxt else block[m.end():]
        zm = re.search(r"zones\s*=\s*\{([^}]*)\}", tail)
        zones = re.findall(r"'([^']+)'", zm.group(1)) if zm else []
        rm = re.search(r"roster\s*=\s*\{(.*)\}", tail, re.DOTALL)
        names = re.findall(r"name\s*=\s*'([^']+)'", rm.group(1)) if rm else []
        out.append({"key": key, "name": name, "base": base, "zones": zones, "roster": names})
    return out


def _parse_atmacite(block: str) -> list[dict]:
    out: list[dict] = []
    for m in re.finditer(
        r"\{\s*key\s*=\s*'[^']+'\s*,\s*name\s*=\s*'([^']+)'\s*,\s*desc\s*=\s*'([^']+)'\s*,\s*max\s*=\s*(\d+)",
        block,
    ):
        out.append({"name": m.group(1), "desc": m.group(2), "max": int(m.group(3))})
    return out


# ---------------------------------------------------------------------------
# Rendering

def _fmt_minutes(seconds: int) -> str:
    if seconds % 60 == 0:
        return f"{seconds // 60} minutes"
    return f"{seconds} seconds"


def _render_economy(c: dict) -> str:
    regen = _fmt_minutes(c["regen_sec"]) if c["regen_sec"] < 3600 else \
        ("1 hour" if c["regen_sec"] == 3600 else f"{c['regen_sec'] // 3600} hours")
    rift = "1 Voidstone" if c["rift_cost"] == 1 else f"{c['rift_cost']} Voidstones"
    rows = [
        "| Voidstones | Detail |",
        "|---|---|",
        f"| Carry cap | {c['max_stones']} Voidstones |",
        f"| Regen | 1 Voidstone every {regen}, real time |",
        f"| Starting stock | {c['start_stones']} Voidstones, granted your first time |",
        f"| Rift cost | {rift} per opening |",
        f"| Buy price | {commafy(c['stone_cruor'])} cruor each |",
        f"| Battle timer | {_fmt_minutes(c['battle_sec'])} before the NM voids out |",
        f"| Pyxis claim window | {_fmt_minutes(c['pyxis_sec'])} to open the chest |",
    ]
    return "\n".join(rows)


def _render_scaling(c: dict) -> str:
    def sign(n):
        return f"+ tier × {commafy(n)}"

    rows = [
        "| What scales | Formula |",
        "|---|---|",
        f"| NM level | {c['lvl_base']} {sign(c['lvl_per'])} |",
        f"| NM HP | {commafy(c['hp_base'])} {sign(c['hp_per'])} |",
        f"| Attack | {commafy(c['att_base'])} {sign(c['att_per'])} |",
        f"| Accuracy | {commafy(c['acc_base'])} {sign(c['acc_per'])} |",
        f"| Cruor reward | {commafy(c['cruor_base'])} {sign(c['cruor_per'])} |",
        f"| EXP reward | {commafy(c['exp_base'])} {sign(c['exp_per'])} |",
    ]
    return "\n".join(rows)


def _render_lights(c: dict) -> str:
    # Per-light reward weight phrasing, keyed by colour.
    g = c["cruor_per_green"]
    y = c["exp_per_yellow"]
    rolls = c["rolls_per_2_blue"]
    blue = f"+{rolls} loot roll per 2 lights" if rolls != 1 else "+1 loot roll per 2 lights"
    weights = {
        "RED":    f"+{c['quality_per_red']} to the quality roll per light",
        "BLUE":   blue,
        "GREEN":  f"+{_g(g * 100)}% cruor per light",
        "YELLOW": f"+{_g(y * 100)}% EXP per light",
        "WHITE":  f"{c['shard_per_white']} atmacite shard per light",
    }

    colour_word = {"RED": "Red", "BLUE": "Blue", "GREEN": "Green", "YELLOW": "Yellow", "WHITE": "White"}
    rows = ["| Light | Colour | Reward boon | Per-light weight |", "|---|---|---|---|"]
    for key in c["light_order"]:
        name = c["light_names"].get(key, key.title())
        boon = c["light_boon"].get(key, "")
        rows.append(f"| **{name}** | {colour_word.get(key, key.title())} | {boon} | {weights.get(key, '')} |")
    return "\n".join(rows)


def _render_strata(c: dict) -> str:
    rows = ["| Stratum | Starting tier | Zones | Voidwalker NMs |", "|---|---|---|---|"]
    for s in c["strata"]:
        nms = ", ".join(_pretty_nm(n) for n in s["roster"])
        rows.append(f"| **{s['name']}** | {s['base'] + 1} | {len(s['zones'])} | {nms} |")
    return "\n".join(rows)


def _render_atmacite(c: dict) -> str:
    mult = c["atm_cost_mult"]
    rows = ["| Perk | Effect | Max level | Cost (shards) |", "|---|---|---|---|"]
    for p in c["atmacite"]:
        # cumulative cost to max = mult * (1+2+...+max)
        total = mult * (p["max"] * (p["max"] + 1) // 2)
        cost = f"{mult} × next level (to {commafy(total)} at max)"
        rows.append(f"| **{p['name']}** | {p['desc']} | {p['max']} | {cost} |")
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/voidwatch_catalog.lua")
    if src is None:
        print("[voidwatch] skip: voidwatch_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "voidwatch.md"
    blocks = [
        ("voidwatch-economy", _render_economy(c)),
        ("voidwatch-scaling", _render_scaling(c)),
        ("voidwatch-lights", _render_lights(c)),
        ("voidwatch-strata", _render_strata(c)),
        ("voidwatch-atmacite", _render_atmacite(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[voidwatch] {written}/{len(blocks)} marker block(s) written "
          f"(lights={len(c['light_order'])}, strata={len(c['strata'])}, "
          f"perks={len(c['atmacite'])})")
