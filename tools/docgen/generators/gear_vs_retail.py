"""
Generates docs/reference/gear-vs-retail.md comparing server item stats
to their retail counterparts (sourced from FFXIAH.com via the cache at
tools/ffxiah_item_cache.json).

Dependencies:
  - tools/ffxiah_item_cache.json must exist (run tools/fetch_ffxiah_cache.py)
  - Live DB connection (reads item_mods + item_basic)

If the cache is missing the generator is a no-op (keeps old page content).
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from tools.docgen._db import connect
from tools.docgen._markers import write_between_markers

# ── stat mapping: FFXIAH display name → (LSB mod_id, db_scale, is_pct) ──────
# db_value = display_int * db_scale
#   db_scale=1:   stored as the raw integer (e.g. HP+45 → mod 2 = 45)
#   db_scale=100: stored × 100 (e.g. Haste+6% → mod 384 = 600)
# is_pct: whether to append "%" in the output table
STAT_MAP: dict[str, tuple[int, int, bool]] = {
    'DEF':                    (1,    1,    False),
    'HP':                     (2,    1,    False),
    'MP':                     (5,    1,    False),
    'STR':                    (8,    1,    False),
    'DEX':                    (9,    1,    False),
    'VIT':                    (10,   1,    False),
    'AGI':                    (11,   1,    False),
    'INT':                    (12,   1,    False),
    'MND':                    (13,   1,    False),
    'CHR':                    (14,   1,    False),
    'Attack':                 (23,   1,    False),
    'Ranged Attack':          (24,   1,    False),
    'Magic Attack Bonus':     (28,   1,    False),
    'Accuracy':               (25,   1,    False),
    'Ranged Accuracy':        (26,   1,    False),
    'Magic Accuracy':         (30,   1,    False),
    'Magic Def. Bonus':       (29,   1,    False),  # FFXIAH quoted format
    'Magic Defense Bonus':    (29,   1,    False),  # alternate spelling
    'Evasion':                (68,   1,    False),
    'Magic Evasion':          (31,   1,    False),
    'Enmity':                 (27,   1,    False),
    'Store TP':               (73,   1,    False),  # FFXIAH quoted format
    'Haste':                  (384,  100,  True),   # 6% → db 600
    'Damage taken':           (160,  100,  True),   # -6% → db -600
    'Physical damage limit':  (1081, 1,    True),   # 3% → db 3
    'Double Attack':          (288,  1,    True),
    'Triple Attack':          (302,  1,    True),
    'Subtle Blow':            (289,  1,    False),
    'Subtle Blow II':         (973,  1,    False),
    'Dual Wield':             (259,  1,    False),
    'Fast Cast':              (170,  1,    True),
    'Phalanx':                (301,  1,    False),
    'Snapshot':               (365,  1,    True),
    'Rapid Shot':             (359,  1,    True),
    'Regain':                 (368,  1,    False),
    'Refresh':                (369,  1,    False),
    'Conserve MP':            (296,  1,    False),
    'TP Bonus':               (345,  1,    False),
    'Critical hit rate':      (165,  1,    True),
}

# Canonical display name per mod_id (for showing server-only stats)
_MOD_DISPLAY: dict[int, tuple[str, int, bool]] = {}
for _name, (_mid, _scale, _pct) in STAT_MAP.items():
    if _mid not in _MOD_DISPLAY:
        _MOD_DISPLAY[_mid] = (_name, _scale, _pct)


def _fmt(val: float | int, is_pct: bool, sign: bool = True) -> str:
    n = int(val) if val == int(val) else val
    s = f'{n:+}' if sign else str(n)
    return s + '%' if is_pct else s


def _get_server_mods(conn, item_ids: list[int]) -> dict[int, dict[int, int]]:
    if not item_ids:
        return {}
    ph = ','.join(['%s'] * len(item_ids))
    cur = conn.cursor()
    cur.execute(
        f'SELECT itemId, modId, modVal FROM item_mods WHERE itemId IN ({ph})',
        item_ids,
    )
    out: dict[int, dict[int, int]] = {}
    for iid, mid, mval in cur.fetchall():
        out.setdefault(int(iid), {})[int(mid)] = int(mval)
    cur.close()
    return out


def _get_item_names(conn, item_ids: list[int]) -> dict[int, str]:
    if not item_ids:
        return {}
    ph = ','.join(['%s'] * len(item_ids))
    cur = conn.cursor()
    cur.execute(
        f'SELECT itemId, name FROM item_basic WHERE itemId IN ({ph})',
        item_ids,
    )
    out = {int(r[0]): str(r[1]) for r in cur.fetchall()}
    cur.close()
    return out


def _mk_table(headers: list[str], keys: list[str], rows: list[dict]) -> str:
    if not rows:
        return '*None found.*\n'
    sep = '| ' + ' | '.join('---' for _ in headers) + ' |'
    hdr = '| ' + ' | '.join(headers) + ' |'
    lines = [hdr, sep]
    for r in rows:
        lines.append('| ' + ' | '.join(str(r.get(k, '')) for k in keys) + ' |')
    return '\n'.join(lines) + '\n'


def generate(repo_root: Path, docs_dir: Path) -> None:
    cache_file = repo_root / 'tools' / 'ffxiah_item_cache.json'
    out_page   = docs_dir / 'reference' / 'gear-vs-retail.md'

    if not cache_file.exists():
        print('[gear_vs_retail] skip: ffxiah_item_cache.json not found — '
              'run tools/fetch_ffxiah_cache.py first')
        return

    if not out_page.exists():
        print(f'[gear_vs_retail] skip: {out_page} not found')
        return

    with open(cache_file, 'r', encoding='utf-8') as f:
        cache: dict = json.load(f)

    found = {
        int(iid): entry
        for iid, entry in cache.items()
        if entry.get('found') and entry.get('stats')
    }

    if not found:
        print('[gear_vs_retail] skip: cache has no valid entries')
        return

    conn = connect(repo_root)
    if conn is None:
        print('[gear_vs_retail] skip: no DB connection')
        return

    try:
        item_ids = list(found.keys())
        server_mods_map = _get_server_mods(conn, item_ids)
        server_names    = _get_item_names(conn, item_ids)
    finally:
        conn.close()

    rows_missing: list[dict] = []
    rows_differ:  list[dict] = []
    rows_custom:  list[dict] = []

    sorted_items = sorted(found.items(), key=lambda kv: found[kv[0]].get('name', ''))

    for item_id, entry in sorted_items:
        retail_stats: dict[str, int] = entry.get('stats', {})
        s_mods = server_mods_map.get(item_id, {})
        item_name = server_names.get(item_id, entry.get('name', f'#{item_id}'))

        # check each retail stat against server
        for stat_name, retail_val in retail_stats.items():
            if stat_name not in STAT_MAP:
                continue
            mod_id, scale, is_pct = STAT_MAP[stat_name]
            expected_db = retail_val * scale
            actual_db   = s_mods.get(mod_id)

            if actual_db is None:
                if retail_val != 0:
                    rows_missing.append({
                        'item':   item_name,
                        'stat':   stat_name,
                        'retail': _fmt(retail_val, is_pct),
                        'server': '—',
                        'id':     item_id,
                    })
            elif actual_db != expected_db:
                actual_disp = actual_db / scale
                diff = actual_disp - retail_val
                rows_differ.append({
                    'item':   item_name,
                    'stat':   stat_name,
                    'retail': _fmt(retail_val, is_pct),
                    'server': _fmt(actual_disp, is_pct),
                    'diff':   _fmt(diff, is_pct),
                    'id':     item_id,
                })

        # check server mods not present in retail
        retail_mod_ids = {
            STAT_MAP[sn][0]
            for sn in retail_stats
            if sn in STAT_MAP
        }
        for mod_id, mod_val in s_mods.items():
            if mod_id in retail_mod_ids:
                continue  # already compared above
            if mod_id not in _MOD_DISPLAY:
                continue
            disp_name, scale, is_pct = _MOD_DISPLAY[mod_id]
            actual_disp = mod_val / scale
            rows_custom.append({
                'item':   item_name,
                'stat':   disp_name,
                'retail': '—',
                'server': _fmt(actual_disp, is_pct),
                'id':     item_id,
            })

    # Compute cache freshness
    dates = [e.get('fetched_at', '')[:10] for e in cache.values() if e.get('fetched_at')]
    cache_date = max(dates) if dates else 'unknown'
    n_compared = len(found)

    missing_tbl = _mk_table(
        ['Item', 'Stat', 'Retail', 'Server'],
        ['item', 'stat', 'retail', 'server'],
        rows_missing,
    )
    differ_tbl = _mk_table(
        ['Item', 'Stat', 'Retail', 'Server', 'Diff'],
        ['item', 'stat', 'retail', 'server', 'diff'],
        rows_differ,
    )
    custom_tbl = _mk_table(
        ['Item', 'Stat', 'Server Value'],
        ['item', 'stat', 'server'],
        rows_custom,
    )

    content = f"""\
*{n_compared} items compared · retail data from [FFXIAH.com](https://www.ffxiah.com) · cache date {cache_date}*

## Stats Missing or Lower on Server

Retail has these stats, but the server doesn't — or the server value is lower.
These may be bugs, pending additions, or LSB implementation differences.

{missing_tbl}
## Stats with Different Values

Both retail and server have the stat, but the values differ.

{differ_tbl}
## Server-Only Stats (Custom Legendary Buffs)

Stats the server adds that don't exist on the retail item.

{custom_tbl}"""

    if write_between_markers(out_page, 'gear-vs-retail-data', content):
        print(
            f'[gear_vs_retail] {n_compared} items compared — '
            f'{len(rows_missing)} missing, {len(rows_differ)} differ, '
            f'{len(rows_custom)} custom'
        )
    else:
        print('[gear_vs_retail] marker not found in page — skipping write')
