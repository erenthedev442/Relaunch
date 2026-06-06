"""Generate SQL to populate item_mods for Reforge +3 items the BG-Wiki
generator (tools/gen_naked_item_stats.py) missed.

History: the gear_coverage.py matrix originally surfaced that Empyrean+3
was 0% populated and Relic+3 was 32% populated — players grinded currency,
spent it on the +3 upgrade, and got items with literally zero stats. The
first version of this script filled all 184 empty items by deriving from
+2 stats. THEN we discovered the user already had a BG-Wiki-sourced
generator covering 259 items — its values are more authoritative than our
+2 + step derivation.

So this script now covers ONLY the items BG-Wiki MISSES — currently 5
outliers (4 Relic items with token mods that confused BG-Wiki's
"is-naked" check, plus the agoge_mufflers_+3 token-overlay case). For
every other item, BG-Wiki wins.

Output: sql/zz_reforge_plus3_outliers.sql
  - Prefix 'zz_' makes it load AFTER /sql/item_mods.sql (DROP TABLE)
  - INSERT IGNORE preserves both existing tokens AND any future BG-Wiki
    additions; BG-Wiki wins on every (item, mod) collision.

Usage:
    python tools/balance/generate_plus3_mods.py
"""
from __future__ import annotations

import math
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.docgen._db import connect  # noqa: E402
from tools.docgen._paths import resolve_source  # noqa: E402


# +2 -> +3 step per mod, derived from the user's actual AF+3 designs (median
# delta across all 110 healthy AF +2/+3 pairs in the DB). Default for any
# mod not listed here is 0 (i.e. +3 value = +2 value verbatim) — safe
# fallback that never invents stats.
PLUS3_STEP: dict[int, int] = {
    1:    10,    # DEF
    2:    10,    # HP
    5:    10,    # MP
    8:     5,    # STR
    9:     5,    # DEX
    10:    5,    # VIT
    11:    5,    # AGI
    12:    5,    # INT
    13:    5,    # MND
    14:    5,    # CHR
    23:   10,    # ATT
    24:   10,    # ACC
    25:   10,    # SLASHRES
    26:   10,    # PIERCERES
    28:    5,    # MATT
    29:    1,    # RACC
    30:   10,    # MACC
    31:   10,    # MEVA
    68:   10,    # EVA
    73:    1,    # STORETP
    110:   2,    # (per-AF sample step)
    114:   2,    # (per-AF sample step)
    161: -100,   # DMGPHYS  (more negative = more damage reduction)
    164: -100,   # DMGRANGE
    170:   2,    # FASTCAST
    289:   1,    # SUBTLE_BLOW
    311:  10,    # MAGIC_DAMAGE
    369:   1,    # SHIELD_DEF_BONUS
    384:   0,    # HASTE_GEAR (engine-capped, +3 doesn't push further)
    421:   1,    # CRIT_DMG_INCREASE
    487:   5,    # BLUNT_DEF
    841:   5,    # ALL_WSDMG_FIRST_HIT
}
DEFAULT_STEP = 0


# Reforge catalog parsing — same regexes as gear_coverage.py.
_JOB_BLOCK_RE = re.compile(r"catalog\.pieces\[xi\.job\.(\w+)\]\s*=\s*\{(.*?)\n\}\s*\n", re.DOTALL)
_SET_RE       = re.compile(r"\b(af|relic|empy)\s*=\s*(?:--[^\n]*\n)?\s*\{(.*?)\n\s*\}", re.DOTALL)
_SLOT_RE      = re.compile(r"\b(head|body|hands|legs|feet)\s*=\s*\{\s*([\d,\s]+)\s*\}")
SET_LABELS = {'af': 'AF', 'relic': 'Relic', 'empy': 'Empyrean'}


def parse_catalog(repo_root: Path) -> list[tuple[str, str, str, int, int]]:
    """Return [(job, set_key, slot, plus2_id, plus3_id), ...] for every
    job/set/slot combination that has a 4-element array (base, +1, +2, +3)."""
    path = resolve_source(repo_root, 'modules/custom/lua/reforge_catalog.lua')
    if path is None:
        raise SystemExit('reforge_catalog.lua not found')
    text = path.read_text(encoding='utf-8', errors='replace')

    out: list[tuple[str, str, str, int, int]] = []
    for jm in _JOB_BLOCK_RE.finditer(text):
        job = jm.group(1)
        for sm in _SET_RE.finditer(jm.group(2)):
            set_key = sm.group(1)
            for slm in _SLOT_RE.finditer(sm.group(2)):
                slot = slm.group(1)
                ids = [int(x.strip()) for x in slm.group(2).split(',') if x.strip()]
                if len(ids) >= 4:
                    out.append((job, set_key, slot, ids[2], ids[3]))
    return out


def main() -> int:
    print('Parsing reforge_catalog.lua...')
    records = parse_catalog(REPO_ROOT)
    print(f'  {len(records)} (job, set, slot) entries')

    print('Connecting to DB...')
    conn = connect(REPO_ROOT)
    if conn is None:
        print('  DB connection failed')
        return 1
    cur = conn.cursor()

    # Bulk-fetch mods for every +2 and +3 we care about.
    all_ids = list({r[3] for r in records} | {r[4] for r in records})
    cur.execute(
        f"SELECT itemId, modId, value FROM item_mods "
        f"WHERE itemId IN ({','.join(['%s'] * len(all_ids))})",
        all_ids,
    )
    mods: dict[int, dict[int, int]] = defaultdict(dict)
    for item_id, mod_id, value in cur.fetchall():
        mods[item_id][mod_id] = value

    # Find the names of every +3 item we'll touch — for nice SQL comments.
    cur.execute(
        f"SELECT itemId, name FROM item_basic "
        f"WHERE itemId IN ({','.join(['%s'] * len(all_ids))})",
        all_ids,
    )
    name_by_id = {row[0]: row[1] for row in cur.fetchall()}

    # Identify which items the BG-Wiki gen (zz_custom_naked_item_mods.sql)
    # already covers. We ONLY want to emit rows for +3 items BG-Wiki misses
    # — its values are more authoritative than our +2-derivation formula,
    # so for overlap items, BG-Wiki should win.
    bgwiki_path = resolve_source(REPO_ROOT, 'sql/zz_custom_naked_item_mods.sql')
    bgwiki_items: set[int] = set()
    if bgwiki_path and bgwiki_path.exists():
        bgwiki_text = bgwiki_path.read_text(encoding='utf-8', errors='replace')
        bgwiki_items = {int(m.group(1))
                        for m in re.finditer(r"INSERT INTO `item_mods` VALUES \((\d+),", bgwiki_text)}
        print(f'  BG-Wiki covers {len(bgwiki_items)} items — skipping those')

    # Build the outlier list. An item needs filling if:
    #   - BG-Wiki doesn't cover it, AND
    #   - +2 has mods we can derive from
    # NOTE: deliberately NO state-dependent check (e.g. "+3 has < 4 mods").
    # The generator emits the same rows regardless of whether the SQL has
    # been applied yet — INSERT IGNORE handles the "already populated"
    # case at apply time. This keeps the generator's output reproducible
    # and decouples it from live DB state.
    to_fix: list[tuple[str, str, str, int, int]] = []
    for job, set_key, slot, p2_id, p3_id in records:
        if p3_id in bgwiki_items:
            continue
        if not mods.get(p2_id):
            continue
        to_fix.append((job, set_key, slot, p2_id, p3_id))

    print(f'  {len(to_fix)} outlier +3 items to populate')
    by_set = defaultdict(int)
    for _, s, _, _, _ in to_fix:
        by_set[s] += 1
    for s, n in sorted(by_set.items()):
        print(f'    {SET_LABELS[s]}+3: {n}')

    # Generate the SQL.
    out_lines: list[str] = []
    out_lines.append('-- ============================================================')
    out_lines.append('-- zz_reforge_plus3_outliers.sql')
    out_lines.append('--')
    out_lines.append('-- Auto-generated by tools/balance/generate_plus3_mods.py.')
    out_lines.append('--')
    out_lines.append('-- Reforge +3 items that the BG-Wiki generator')
    out_lines.append('-- (tools/gen_naked_item_stats.py) missed because they had pre-')
    out_lines.append('-- existing token mods (job-specific JA bonuses) which made its')
    out_lines.append("-- 'is naked' check treat them as already populated. Without")
    out_lines.append('-- this file these items ship with ONLY their tokens and no')
    out_lines.append('-- standard stat block.')
    out_lines.append('--')
    out_lines.append('-- Strategy: derive each +3 stats from its +2 sibling using the')
    out_lines.append("-- PLUS3_STEP table (median delta across the user's 110 healthy")
    out_lines.append('-- AF+3 vs AF+2 pairs).')
    out_lines.append('--')
    out_lines.append("-- Filename prefix 'zz_' ensures we load AFTER /sql/item_mods.sql")
    out_lines.append('-- (which does DROP TABLE on every full update); INSERT IGNORE')
    out_lines.append('-- preserves existing tokens AND any future BG-Wiki data — if')
    out_lines.append('-- BG-Wiki ever populates one of these items, its row wins.')
    out_lines.append('-- ============================================================')
    out_lines.append('')

    # INSERTs, grouped by (set, job, slot) so the SQL is grep-able.
    insert_count = 0
    for job, set_key, slot, p2_id, p3_id in to_fix:
        p2 = mods.get(p2_id, {})
        p3_name = name_by_id.get(p3_id, f'item {p3_id}')
        p2_name = name_by_id.get(p2_id, f'item {p2_id}')
        out_lines.append(f'-- {SET_LABELS[set_key]}+3  {job:>3}  {slot:>5}  '
                         f'{p3_name} (derived from {p2_name})')
        rows = []
        for mod_id, p2_value in sorted(p2.items()):
            step = PLUS3_STEP.get(mod_id, DEFAULT_STEP)
            new_value = p2_value + step
            if new_value == 0:
                continue
            rows.append((mod_id, new_value))
        for mod_id, value in rows:
            # INSERT IGNORE — preserves existing tokens AND any future
            # BG-Wiki data. BG-Wiki wins on every (item, mod) collision.
            out_lines.append(
                f'INSERT IGNORE INTO `item_mods` VALUES ({p3_id}, {mod_id}, {value});'
            )
            insert_count += 1
        out_lines.append('')

    # Emit into /sql/ with zz_ prefix so the file loads AFTER item_mods.sql
    # in dbtool's full update path. See the SQL header comment for the
    # full rationale.
    out_path = REPO_ROOT / 'sql' / 'zz_reforge_plus3_outliers.sql'
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text('\n'.join(out_lines), encoding='utf-8')
    print(f'Wrote {out_path}')
    print(f'  {len(to_fix)} items touched, {insert_count} INSERT rows')
    return 0


if __name__ == '__main__':
    sys.exit(main())
