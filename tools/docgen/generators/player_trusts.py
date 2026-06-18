"""Sync docs/community/player-trusts.md with player_trusts_catalog.lua.

Every number on that page (gil costs, durations, stat bonuses, base mods,
trustMult, slot→spell mapping, NPC coordinates, unlock minutes) lives in
the catalog. This generator parses the catalog and writes each piece into
its own DOCGEN marker block on the page so a balance edit in one place
propagates to the published docs on the next refresh.

Marker IDs written:
  pt-unlock-minutes   — the unlock threshold inline
  pt-npc-location     — Companion Master coords
  pt-slots-table      — slot → hijacked spell
  pt-cost-ladder      — gil per upgrade + cumulative
  pt-quick-buff       — per-stat per-tier Quick Buff ledger
  pt-mob-scaling      — per-mod per-tier real-Trust scaling
  pt-power-budget     — at-a-glance summary

Skips silently if the catalog or markers can't be found.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# ---------------------------------------------------------------------------
# Catalog parsing
# ---------------------------------------------------------------------------

_UNLOCK_RE = re.compile(r"\bcatalog\.unlockMinutes\s*=\s*(\d+)")

_NPC_RE = re.compile(
    r"catalog\.npcPos\s*=\s*\{[^}]*?"
    r"x\s*=\s*(-?[0-9.]+)[^}]*?"
    r"y\s*=\s*(-?[0-9.]+)[^}]*?"
    r"z\s*=\s*(-?[0-9.]+)[^}]*?"
    r"rotation\s*=\s*(\d+)",
    re.DOTALL,
)

# tier rows are one-line key=value chunks inside [N] = { ... }
_TIER_RE = re.compile(
    r"\[(\d+)\]\s*=\s*\{\s*"
    r"label\s*=\s*'([^']+)'\s*,\s*"
    r"buffDurationMin\s*=\s*(\d+)\s*,\s*"
    r"statBonus\s*=\s*(\d+)\s*,\s*"
    r"hpBonus\s*=\s*(\d+)\s*,\s*"
    r"mpBonus\s*=\s*(\d+)\s*,\s*"
    r"gilCost\s*=\s*(\d+)\s*,\s*"
    r"trustMult\s*=\s*([0-9.]+)"
)

# trustBaseMods entries: { xi.mod.X, N }   — N may be negative
_BASE_MOD_RE = re.compile(r"\{\s*xi\.mod\.([A-Z_]+)\s*,\s*(-?\d+)\s*\}")

# trustSlots entries: { slot = N, spellId = N, name = '...' }
_SLOT_RE = re.compile(
    r"\{\s*slot\s*=\s*(\d+)\s*,\s*"
    r"spellId\s*=\s*(\d+)\s*,\s*"
    r"name\s*=\s*'([^']+)'\s*\}"
)


def _section(text: str, name: str) -> str:
    """Slice out the catalog.<name> = { ... } block so per-row regexes
    don't accidentally match across unrelated sections of the file.

    Skips Lua line comments (`-- ...`) and respects both single- and
    double-quoted strings with backslash escapes. Without comment skipping,
    apostrophes inside comments (`friend's`, `don't`) trip the walker into
    a fake "string mode" it never escapes."""
    m = re.search(rf"\bcatalog\.{re.escape(name)}\s*=\s*\{{", text)
    if not m:
        return ""
    depth = 0
    start = m.end() - 1   # position of the opening brace
    i = start
    n = len(text)
    while i < n:
        c = text[i]
        # Lua line comment: jump past end-of-line. (Doesn't handle block
        # comments `--[[ ... ]]` — none in the catalogs.)
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                return ""
            i = nl + 1
            continue
        # Quoted string: skip past matching close quote with escape handling.
        if c == "'" or c == '"':
            quote = c
            i += 1
            while i < n:
                cc = text[i]
                if cc == "\\" and i + 1 < n:
                    i += 2
                    continue
                if cc == quote:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[start: i + 1]
        i += 1
    return ""


def _parse_catalog(text: str) -> dict:
    out: dict = {}

    um = _UNLOCK_RE.search(text)
    out["unlockMinutes"] = int(um.group(1)) if um else None

    npc = _NPC_RE.search(text)
    if npc:
        out["npc"] = {
            "x": float(npc.group(1)),
            "y": float(npc.group(2)),
            "z": float(npc.group(3)),
            "rot": int(npc.group(4)),
        }

    tiers_block = _section(text, "tiers")
    tiers: dict[int, dict] = {}
    for m in _TIER_RE.finditer(tiers_block):
        idx = int(m.group(1))
        tiers[idx] = {
            "label":           m.group(2),
            "buffDurationMin": int(m.group(3)),
            "statBonus":       int(m.group(4)),
            "hpBonus":         int(m.group(5)),
            "mpBonus":         int(m.group(6)),
            "gilCost":         int(m.group(7)),
            "trustMult":       float(m.group(8)),
        }
    out["tiers"] = [tiers[i] for i in sorted(tiers)]

    base_block = _section(text, "trustBaseMods")
    out["baseMods"] = [
        {"mod": m.group(1), "value": int(m.group(2))}
        for m in _BASE_MOD_RE.finditer(base_block)
    ]

    slots_block = _section(text, "trustSlots")
    out["slots"] = [
        {"slot": int(m.group(1)), "spellId": int(m.group(2)), "name": m.group(3)}
        for m in _SLOT_RE.finditer(slots_block)
    ]

    return out


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

# Friendly labels for the mods that appear in trustBaseMods. Anything
# missing falls through to the raw enum name (a clear signal the catalog
# added something the renderer hasn't decided how to display).
_MOD_DISPLAY = {
    "HPP":        ("HPP", "% extra HP on the mob", "%"),
    "DEF":        ("DEF", None, ""),
    "MEVA":       ("MEVA", "magic evasion", ""),
    "ATT":        ("ATT", None, ""),
    "ACC":        ("ACC", None, ""),
    "MATT":       ("MATT", "magic attack", ""),
    "MACC":       ("MACC", "magic accuracy", ""),
    "HASTE_GEAR": ("HASTE_GEAR", "1/1024ths", ""),
    "STR":        ("STR", "aura — buffs you too", ""),
    "DEX":        ("DEX", "aura", ""),
    "VIT":        ("VIT", "aura", ""),
}


def _display_mod(name: str) -> str:
    info = _MOD_DISPLAY.get(name)
    if not info:
        return f"`{name}`"
    short, note, _ = info
    if note:
        return f"**{short}** ({note})"
    return f"**{short}**"


def _fmt_mod_value(name: str, value: float) -> str:
    """Display a mod value with the right unit. HPP is %; HASTE_GEAR also
    shows its computed %."""
    suffix = _MOD_DISPLAY.get(name, (None, None, ""))[2]
    if name == "HASTE_GEAR":
        pct = (value / 1024.0) * 100
        return f"{int(round(value))} (~{pct:.1f}%)"
    if value == int(value):
        return f"+{int(value)}{suffix}"
    return f"+{value:g}{suffix}"


def _render_unlock(c: dict) -> str:
    n = c.get("unlockMinutes")
    if n is None:
        return "_(unlock threshold not parsed)_"
    return f"**{n} minutes** of shared party-in-zone time"


def _render_npc(c: dict) -> str:
    n = c.get("npc")
    if not n:
        return "_(NPC location not parsed)_"
    return (
        f"At GM Home, position **(x = {n['x']:.3f}, y = {n['y']:.3f}, "
        f"z = {n['z']:.3f}, rot = {n['rot']})**."
    )


def _render_slots(c: dict) -> str:
    slots = c.get("slots") or []
    if not slots:
        return "_(slot table not parsed)_"
    # Pretty-print the hijacked-trust name from the internal handle
    # ('kuyin_hathdenna' -> 'Kuyin Hathdenna').
    def _pretty(name: str) -> str:
        return " ".join(w.capitalize() for w in name.split("_"))
    lines = [
        "| Slot | Cast this spell to summon your assigned friend |",
        "|---:|---|",
    ]
    for s in slots:
        lines.append(f"| {s['slot']} | Trust: {_pretty(s['name'])} |")
    return "\n".join(lines)


def _render_cost_ladder(c: dict) -> str:
    tiers = c.get("tiers") or []
    if not tiers:
        return "_(tier ladder not parsed)_"
    lines = [
        "| Tier | Duration (Quick Buff) | Gil from previous tier | Cumulative |",
        "|---|---:|---:|---:|",
    ]
    cum = 0
    for t in tiers:
        cum += t["gilCost"]
        if t["gilCost"] == 0:
            cost_cell = "(free on unlock)"
        else:
            cost_cell = f"{t['gilCost']:,}"
        lines.append(
            f"| {t['label']} | {t['buffDurationMin']} min | {cost_cell} | {cum:,} |"
        )
    return "\n".join(lines)


_QUICK_BUFF_STAT_ROWS = [
    ("STR", "**STR**"), ("DEX", "**DEX**"), ("VIT", "**VIT**"),
    ("AGI", "**AGI**"), ("INT", "**INT**"), ("MND", "**MND**"),
    ("CHR", "**CHR**"),
]


def _render_quick_buff(c: dict) -> str:
    tiers = c.get("tiers") or []
    if not tiers:
        return "_(tier values not parsed)_"
    header = "| Mod on caster |" + "".join(f" {t['label']} |" for t in tiers)
    sep = "|---|" + "---:|" * len(tiers)
    rows = [header, sep]
    # 7 stat rows — each takes statBonus from the tier
    for _key, label in _QUICK_BUFF_STAT_ROWS:
        cells = " | ".join(f"+{t['statBonus']}" for t in tiers)
        rows.append(f"| {label} | {cells} |")
    # HP / MP rows
    rows.append("| **HP** (flat) | " + " | ".join(f"+{t['hpBonus']}" for t in tiers) + " |")
    rows.append("| **MP** (flat) | " + " | ".join(f"+{t['mpBonus']}" for t in tiers) + " |")
    return "\n".join(rows)


def _render_mob_scaling(c: dict) -> str:
    tiers = c.get("tiers") or []
    base = c.get("baseMods") or []
    if not tiers or not base:
        return "_(mob scaling not parsed)_"
    # Header: Mod | Bronze (1.0×) | Silver (1.25×) | ...
    header_cells = [
        f"{t['label']} ({t['trustMult']:g}×)" for t in tiers
    ]
    header = "| Mod on the Trust mob | " + " | ".join(header_cells) + " |"
    sep    = "|---|" + "---:|" * len(tiers)
    rows = [header, sep]
    for b in base:
        scaled = [b["value"] * t["trustMult"] for t in tiers]
        cells = " | ".join(_fmt_mod_value(b["mod"], v) for v in scaled)
        rows.append(f"| {_display_mod(b['mod'])} | {cells} |")
    return "\n".join(rows)


def _render_power_budget(c: dict) -> str:
    tiers = c.get("tiers") or []
    if not tiers:
        return "_(budget not parsed)_"
    base_mult = tiers[0]["trustMult"]   # Bronze baseline
    lines = [
        "| Tier | Quick Buff sum (7 stats / HP / MP) | Real Trust combined power |",
        "|---|---:|---:|",
    ]
    for t in tiers:
        stat_sum = t["statBonus"] * 7
        # "Combined power" is the trustMult^2 — both HP-scaling and ATT-scaling
        # compound, so the felt strength jumps quadratically with the
        # multiplier. Calling out exactly this is what makes the page
        # not just a numbers dump.
        ratio = (t["trustMult"] ** 2) / (base_mult ** 2)
        if ratio == 1.0:
            power = "baseline"
        else:
            power = f"~{ratio:.1f}× Bronze"
        lines.append(
            f"| {t['label']} | +{stat_sum} / +{t['hpBonus']} / +{t['mpBonus']} | {power} |"
        )
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/player_trusts_catalog.lua")
    if src is None:
        print("[player_trusts] skip: player_trusts_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    catalog = _parse_catalog(text)

    page = docs_dir / "community" / "player-trusts.md"
    blocks = [
        ("pt-unlock-minutes", _render_unlock(catalog)),
        ("pt-npc-location",   _render_npc(catalog)),
        ("pt-slots-table",    _render_slots(catalog)),
        ("pt-cost-ladder",    _render_cost_ladder(catalog)),
        ("pt-quick-buff",     _render_quick_buff(catalog)),
        ("pt-mob-scaling",    _render_mob_scaling(catalog)),
        ("pt-power-budget",   _render_power_budget(catalog)),
    ]

    written = 0
    for marker, content in blocks:
        if write_between_markers(page, marker, content):
            written += 1
        else:
            print(f"[player_trusts] {marker}: marker missing in {page.name}")
    print(f"[player_trusts] {written}/{len(blocks)} marker block(s) written "
          f"(tiers={len(catalog.get('tiers') or [])}, "
          f"base mods={len(catalog.get('baseMods') or [])}, "
          f"slots={len(catalog.get('slots') or [])})")
