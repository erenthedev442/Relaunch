"""Shared item_mods loader for the gear scorers + obtainable-items workbook.

The server populates the item_mods table from MANY sql files (base + a stack of
zz_ overlays), not just item_mods.sql + zz_custom_naked. Reading only those two
under-reports reforge/relic/Tokko/Voluspa gear and the tier carry-forward fixes.

This merges every source the way the server's importer does:
  override=True  -> plain INSERT / ON DUPLICATE KEY UPDATE  (later value wins)
  override=False -> INSERT IGNORE                            (fills only if absent)

Order matches alphabetical sql load order; zzz_reforge_carryforward.sql sorts
last so it only fills genuine gaps.

Keep SOURCES in sync with the copy in
tools/docgen/generators/gear_finder.py.
"""
from __future__ import annotations

import re
from pathlib import Path

SOURCES = [
    ("item_mods.sql", True),
    ("zz_custom_naked_item_mods.sql", True),
    ("zz_derived_tier_mods.sql", False),
    ("zz_infamy_extra_mods.sql", True),
    ("zz_naked_dungeon_fix.sql", False),
    ("zz_obtainable_gap_fills.sql", False),
    ("zz_reforge_plus12_displayed_stats.sql", False),
    ("zz_reforge_plus3_displayed_stats.sql", False),
    ("zz_reforge_plus3_outliers.sql", False),
    ("zz_reforge_plus4_displayed_stats.sql", False),
    ("zz_relic_119iii_mods.sql", False),
    ("zz_tokko_voluspa_mods.sql", False),
    ("zz_zurim_gear_mods.sql", False),
    # reward-item stats authored for the 2026-07 Skirmish/Geas-Fete drops
    ("../modules/custom/sql/skirmish_fete_gear_stats.sql", True),
    ("zzz_reforge_carryforward.sql", False),
]
# Tolerate spaces after commas: some item_mods rows are written "(23756, 1, 152)"
# (e.g. the Gleti set) and the old no-space pattern silently skipped them -> the
# scorer saw "no DB mods" and dropped those items from every vendor/finder.
_TUPLE = re.compile(r"\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(-?\d+)\s*\)")


def load_item_mod_map(sqldir: Path) -> dict[tuple[int, int], int]:
    """Return {(itemId, modId): value} merged across every source."""
    out: dict[tuple[int, int], int] = {}
    for fn, override in SOURCES:
        p = sqldir / fn
        if not p.exists():
            continue
        for ln in p.read_text(encoding="utf-8", errors="replace").splitlines():
            if "item_mods`" not in ln:
                continue
            for m in _TUPLE.finditer(ln):
                key = (int(m.group(1)), int(m.group(2)))
                val = int(m.group(3))
                if override or key not in out:
                    out[key] = val
    return out
