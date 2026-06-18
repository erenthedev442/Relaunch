"""Generate the "Rates at a glance" table inside docs/changes/index.md.

The narrative-style table at the top of the page summarizes server rate
multipliers with friendly labels and notes. The display labels and
notes are hand-curated here; the **numeric values** are pulled live
from `settings/main.lua` and `settings/map.lua` so they can't drift
out of sync.

When a row maps to multiple settings keys and they all share the same
value, the row shows that single value (e.g. "10×"). When the keys
diverge, the row shows them combined (e.g. "10× / 3×") so the
divergence is visible to readers.

Marker ID: "rates-at-a-glance"
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


# ---------------------------------------------------------------------
# Hand-curated row manifest.
#
# Each entry is:
#   (label, keys, notes)
#
# `keys` is a list of "<file>:<SETTING_NAME>" — "main" or "map".
# When the row has more than one key, values are deduplicated; if they
# all agree we show one number, otherwise we show them joined with " / ".
#
# Add a new row by appending to RATES. Add a new setting to an existing
# row by appending to its `keys` list. No other code needs to change.
# ---------------------------------------------------------------------

RATES: list[tuple[str, list[str], str]] = [
    ("**EXP** (scripted, FoV/GoV, ROE)",
        ["main:EXP_RATE", "main:BOOK_EXP_RATE", "main:ROE_EXP_RATE"],
        "All script-based EXP sources"),
    ("**EXP** (mob kills)",
        ["map:EXP_RATE"],
        "Base mob EXP"),
    ("**Capacity Points** (scripted)",
        ["main:CAPACITY_RATE"],
        "Records of Eminence, etc."),
    ("**Capacity Points** (mob kills)",
        ["map:CAPACITY_RATE"],
        ""),
    ("**Sparks**",
        ["main:SPARKS_RATE"],
        ""),
    ("**TABs** (FoV)",
        ["main:TABS_RATE"],
        ""),
    ("**Mob drop rate**",
        ["map:DROP_RATE_MULTIPLIER"],
        ""),
    ("**Gil from mobs**",
        ["map:MOB_GIL_MULTIPLIER"],
        "Plus the **+N gil/mob level** bonus shown below"),
    ("**Gil bonus per mob level**",
        ["map:ALL_MOBS_GIL_BONUS"],
        "Flat bonus added to every mob kill"),
    ("**Gil from quests**",
        ["main:GIL_RATE"],
        ""),
    ("**Bayld from quests**",
        ["main:BAYLD_RATE"],
        ""),
    ("**Fame gain**",
        ["map:FAME_MULTIPLIER"],
        ""),
    ("**Skill-up rate**",
        ["map:SKILLUP_CHANCE_MULTIPLIER"],
        "All combat & magic skills"),
    ("**Craft skill-up rate**",
        ["map:CRAFT_CHANCE_MULTIPLIER"],
        ""),
    ("**Craft HQ chance**",
        ["map:CRAFT_HQ_CHANCE_MULTIPLIER"],
        ""),
    ("**Player / Pet / Trust / Fellow TP gain**",
        ["map:PLAYER_TP_MULTIPLIER", "map:PET_TP_MULTIPLIER",
         "map:TRUST_TP_MULTIPLIER", "map:FELLOW_TP_MULTIPLIER"],
        ""),
    ("**NPC shop prices**",
        ["main:SHOP_PRICE"],
        "Things cost more at vendors"),
    ("**EXP loss on death**",
        ["map:EXP_LOSS_RATE"],
        "Death is costly — be careful"),
]


# Settings line format used throughout the LSB settings/*.lua files:
#   SETTING_NAME    = 10.000, -- optional comment
_SETTING_RE = re.compile(r"^\s*([A-Z][A-Z0-9_]+)\s*=\s*([^,\-\n]+?)\s*(?:,|--|$)")


def generate(repo_root: Path, docs_dir: Path) -> None:
    settings_root = resolve_source(repo_root, "settings")
    if settings_root is None:
        print("[rates_table] skip: settings/ not found")
        return

    files = {
        "main": settings_root / "main.lua",
        "map":  settings_root / "map.lua",
    }
    for label, p in files.items():
        if not p.exists():
            print(f"[rates_table] skip: settings/{p.name} not found")
            return

    values: dict[str, dict[str, str]] = {}
    for source_label, path in files.items():
        values[source_label] = _parse_settings(path.read_text(encoding="utf-8", errors="replace"))

    page = docs_dir / "changes" / "index.md"
    content = _render(values)

    wrote = write_between_markers(page, "rates-at-a-glance", content)
    if wrote:
        print(f"[rates_table] rates-at-a-glance: {len(RATES)} rows written into markers")
    else:
        print(f"[rates_table] rates-at-a-glance: skipped (markers not found in {page.name})")


def _parse_settings(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in text.splitlines():
        m = _SETTING_RE.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def _format_multiplier(raw: str) -> str:
    """Render a numeric setting as `Nx` (e.g. 10x), or pass through ints
    that aren't multipliers (e.g. ALL_MOBS_GIL_BONUS = 1000)."""
    try:
        num = float(raw.rstrip(",").strip())
    except ValueError:
        return f"`{raw}`"
    # Heuristic: values <= 200 are almost certainly multipliers in LSB.
    # Flat bonuses like ALL_MOBS_GIL_BONUS = 1000 should render as
    # `+1000` (with the unit explained in the row's notes).
    if num >= 1000:
        return f"+{int(num) if num.is_integer() else num:,}"
    if num.is_integer():
        return f"{int(num)}×"
    return f"{num:g}×"


def _format_values(values: dict[str, dict[str, str]], keys: list[str]) -> str:
    rendered: list[str] = []
    for key in keys:
        source, name = key.split(":", 1)
        raw = values.get(source, {}).get(name)
        if raw is None:
            rendered.append("?")
        else:
            rendered.append(_format_multiplier(raw))
    # Collapse duplicates while preserving order.
    seen: list[str] = []
    for r in rendered:
        if r not in seen:
            seen.append(r)
    if len(seen) == 1:
        return f"**{seen[0]}**"
    return " / ".join(f"**{v}**" for v in seen)


def _render(values: dict[str, dict[str, str]]) -> str:
    lines = [
        "| | Multiplier | Notes |",
        "|---|---:|---|",
    ]
    for label, keys, notes in RATES:
        lines.append(f"| {label} | {_format_values(values, keys)} | {notes} |")
    return "\n".join(lines)
