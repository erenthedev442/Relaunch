"""Sync docs/progression/fellow-companion.md with fellow_companion.lua.

The Adventuring Fellow is a player-built pet companion (!fellow). Its whole
progression — level cap, point grants, XP scaling, the stat tracks and what
each point grants, the role presets, and the name/appearance/outfit pickers —
all live in the module's CONFIG table. This generator translates that CONFIG
into player-facing prose so re-tuning the module updates the published page.

Markers written:
  fellow-progression    — level cap, point grants, how XP is earned
  fellow-stats          — the stat tracks + what each point grants (plain English)
  fellow-roles          — the role presets (name + blurb)
  fellow-customization   — counts/lists of names, appearances, outfits
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# --- mod-constant -> player-facing label -------------------------------------
# Only the mods that actually appear in statMods/perLevel are needed.
_MOD_LABEL = {
    "STR": "STR",
    "DEX": "DEX",
    "VIT": "VIT",
    "AGI": "AGI",
    "INT": "INT",
    "MND": "MND",
    "ATT": "Attack",
    "ATTP": "Attack",          # ATTP is a percentage attack mod
    "ACC": "Accuracy",
    "DEF": "Defense",
    "EVA": "Evasion",
    "MATT": "Magic Attack",
    "MACC": "Magic Accuracy",
    "MDEF": "Magic Defense",
    "CRITHITRATE": "Critical Hit Rate",
    "DOUBLE_ATTACK": "Double Attack",
    "TRIPLE_ATTACK": "Triple Attack",
    "STORETP": "Store TP",
    "HASTE_GEAR": "Attack Speed (Haste)",
    "REGEN": "HP Regen",
    "REFRESH": "MP Refresh",
    "DMGPHYS": "Physical Damage Taken",
    "DMGMAGIC": "Magic Damage Taken",
}

# Mods expressed as a percentage in the engine (×1 per point reads as +1%).
_PCT_MODS = {
    "ATTP", "CRITHITRATE", "DOUBLE_ATTACK", "TRIPLE_ATTACK", "HASTE_GEAR",
}


def _grant_phrase(mod_name: str, val: int) -> str:
    label = _MOD_LABEL.get(mod_name, mod_name.replace("_", " ").title())
    if mod_name in ("DMGPHYS", "DMGMAGIC") and val < 0:
        # Negative damage-taken = a reduction.
        return f"-{abs(val)} {label}"
    sign = "+" if val >= 0 else ""
    if mod_name in _PCT_MODS:
        return f"{sign}{val}% {label}"
    return f"{sign}{val} {label}"


# --- parsing -----------------------------------------------------------------

def _num(pattern: str, text: str, default):
    m = re.search(pattern, text)
    return int(m.group(1)) if m else default


def _parse_stat_mods(cfg: str):
    """Return ordered list of (track, [(modName, val), ...]) from statMods.

    Order follows statOrder so the published table matches the in-game menu.
    """
    block = section(cfg, "statMods")
    tracks = {}
    # Each entry:  KEY = { { xi.mod.X, N }, { xi.mod.Y, M } },
    for key, body in re.findall(
        r"(\w+)\s*=\s*\{((?:\s*\{[^}]*\}\s*,?)+)\s*\}", block
    ):
        mods = [(mod, int(val))
                for mod, val in re.findall(r"xi\.mod\.(\w+)\s*,\s*(-?\d+)", body)]
        if mods:
            tracks[key] = mods

    order = _parse_order(cfg, "statOrder")
    ordered = [(k, tracks[k]) for k in order if k in tracks]
    # Fall back to dict order for anything statOrder missed.
    for k, v in tracks.items():
        if k not in dict(ordered):
            ordered.append((k, v))
    return ordered


def _parse_order(cfg: str, key: str):
    m = re.search(rf"{re.escape(key)}\s*=\s*\{{([^}}]*)\}}", cfg)
    if not m:
        return []
    return re.findall(r"'([^']+)'", m.group(1))


def _parse_roles(cfg: str):
    """Return ordered list of (display name, blurb) following roleOrder."""
    block = section(cfg, "roles")
    roles = {}
    for key, name, blurb in re.findall(
        r"(\w+)\s*=\s*\{\s*name\s*=\s*'([^']*)'\s*,\s*blurb\s*=\s*'([^']*)'",
        block,
    ):
        roles[key] = (name, blurb)
    order = _parse_order(cfg, "roleOrder")
    ordered = [roles[k] for k in order if k in roles]
    for k, v in roles.items():
        if v not in ordered:
            ordered.append(v)
    return ordered


def _parse_names(cfg: str):
    block = section(cfg, "names")
    return re.findall(r"'([^']+)'", block)


def _parse_models(cfg: str):
    """Return list of (formName, signatureMoveLabel)."""
    block = section(cfg, "models")
    out = []
    for entry in re.findall(r"\{([^}]*)\}", block):
        nm = re.search(r"name\s*=\s*'([^']+)'", entry)
        ws = re.search(r"ws\s*=\s*xi\.mobSkill\.(\w+)", entry)
        if nm:
            out.append((nm.group(1), _move_label(ws.group(1)) if ws else None))
    return out


def _parse_outfits(cfg: str):
    block = section(cfg, "outfits")
    return [m.group(1) for m in re.finditer(r"name\s*=\s*'([^']+)'", block)]


def _move_label(const: str) -> str:
    """xi.mobSkill.THOUSAND_NEEDLES_1 -> 'Thousand Needles'."""
    s = re.sub(r"_\d+$", "", const)            # drop trailing _1/_IV-as-suffix index
    parts = s.split("_")
    roman = {"II", "III", "IV", "V", "VI"}
    out = []
    for p in parts:
        out.append(p if p.upper() in roman else p.capitalize())
    return " ".join(out)


# --- rendering ---------------------------------------------------------------

def _render_progression(c: dict) -> str:
    lines = [
        f"Your Fellow earns XP from kills **while it is summoned**. "
        f"XP per kill scales with the slain foe's level "
        f"(a floor of {c['xpMin']}, capped at {c['xpMax']}).",
        "",
        f"It levels up to **{c['maxLevel']}**, and each level grants "
        f"**{c['pointsPerLevel']} stat points** to spend. You start with "
        f"**{c['startingPoints']} points** when your Fellow is first created.",
    ]
    if c.get("partyWideXp"):
        lines += [
            "",
            "If you are in a party, every party member who has their Fellow out "
            "earns XP from every kill in the same zone — so grinding in a zone "
            "levels everyone's companion at once.",
        ]
    return "\n".join(lines)


def _render_stats(c: dict) -> str:
    rows = [
        "| Stat track | Each point grants |",
        "|---|---|",
    ]
    for track, mods in c["statMods"]:
        grants = ", ".join(_grant_phrase(mod, val) for mod, val in mods)
        rows.append(f"| **{track}** | {grants} |")
    return "\n".join(rows)


def _render_roles(c: dict) -> str:
    rows = [
        "| Role | Behaviour |",
        "|---|---|",
    ]
    for name, blurb in c["roles"]:
        rows.append(f"| **{name}** | {blurb} |")
    return "\n".join(rows)


def _render_customization(c: dict) -> str:
    names = c["names"]
    models = c["models"]
    outfits = c["outfits"]

    lines = []
    lines.append(
        f"**Names** — choose from **{len(names)}** curated names: "
        f"{', '.join(names)}."
    )
    lines.append("")
    lines.append(
        f"**Appearances** — **{len(models)}** forms to pick from, each with its "
        f"own signature TP move:"
    )
    lines.append("")
    lines.append("| Appearance | Signature move |")
    lines.append("|---|---|")
    for name, move in models:
        lines.append(f"| {name} | {move or '—'} |")
    lines.append("")
    lines.append(
        f"**Outfits** — **{len(outfits)}** job-themed humanoid looks that override "
        f"the chosen appearance when set: {', '.join(outfits)}."
    )
    return "\n".join(lines)


# --- parse driver ------------------------------------------------------------

def _parse(text: str) -> dict:
    cfg = section(text, "local CONFIG")
    if not cfg:
        # CONFIG is declared `local CONFIG =\n{ ... }`; section() anchors on the
        # name + '='. Fall back to anchoring on 'CONFIG'.
        cfg = section(text, "CONFIG")
    c: dict = {}
    c["maxLevel"] = _num(r"maxLevel\s*=\s*(\d+)", cfg, 50)
    c["startingPoints"] = _num(r"startingPoints\s*=\s*(\d+)", cfg, 6)
    c["pointsPerLevel"] = _num(r"pointsPerLevel\s*=\s*(\d+)", cfg, 3)
    c["xpMin"] = _num(r"xpMin\s*=\s*(\d+)", cfg, 5)
    c["xpMax"] = _num(r"xpMax\s*=\s*(\d+)", cfg, 200)
    c["partyWideXp"] = bool(re.search(r"partyWideXp\s*=\s*true", cfg))
    c["statMods"] = _parse_stat_mods(cfg)
    c["roles"] = _parse_roles(cfg)
    c["names"] = _parse_names(cfg)
    c["models"] = _parse_models(cfg)
    c["outfits"] = _parse_outfits(cfg)
    return c


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/fellow_companion.lua")
    if src is None:
        print("[fellow] skip: fellow_companion.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "fellow-companion.md"
    blocks = [
        ("fellow-progression", _render_progression(c)),
        ("fellow-stats", _render_stats(c)),
        ("fellow-roles", _render_roles(c)),
        ("fellow-customization", _render_customization(c)),
    ]
    written = sum(1 for marker, content in blocks
                  if write_between_markers(page, marker, content))
    print(f"[fellow] {written}/{len(blocks)} marker block(s) written "
          f"(stats={len(c['statMods'])}, roles={len(c['roles'])}, "
          f"names={len(c['names'])}, models={len(c['models'])}, "
          f"outfits={len(c['outfits'])})")
