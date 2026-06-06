"""Consolidates batch fetch results into the BG-Wiki cache + audit, then
re-runs gen_naked_item_stats.py to produce the updated SQL.

Run this AFTER bgwiki_batch_fetch.py finishes.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(r'D:\server')


def main() -> int:
    results = json.loads((REPO / 'tools' / 'bgwiki_batch_results.json').read_text(encoding='utf-8'))
    failed = json.loads((REPO / 'tools' / 'bgwiki_batch_failed.json').read_text(encoding='utf-8'))

    print(f'Loaded {len(results)} successful fetches, {len(failed)} failures')

    # Mythic-duplicate gotcha: if multiple itemIds share an LSB name, the
    # batch fetcher gave them all the SAME BG-Wiki page (the base item).
    # Identify those and flag them — they need a manual disambiguation pass.
    duplicates = json.loads(
        (REPO / 'tools' / 'naked_ilvl_duplicates.json').read_text(encoding='utf-8')
    )
    duplicate_ids: set[int] = set()
    for ids in duplicates.values():
        duplicate_ids.update(ids)
    print(f'Mythic/Empy/Aeonic upgrade-tier items (need manual disambiguation): {len(duplicate_ids)}')

    # Load existing cache + audit
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    audit = json.loads((REPO / 'tools' / 'gear_stat_audit.json').read_text(encoding='utf-8'))

    # Merge results into cache (but SKIP Mythic-duplicate items — those need
    # manual fixing so we don't overwrite the base item's stats on all 4 tiers)
    added_to_cache = 0
    skipped_duplicates = 0
    for iid_str, entry in results.items():
        iid = int(iid_str)
        if iid in duplicate_ids:
            skipped_duplicates += 1
            continue
        cache[iid_str] = {
            'name':  entry['name'],
            'url':   entry['url'],
            'stats': entry['stats'],
        }
        added_to_cache += 1

    # Add ALL successful items to audit (the gen processes whatever's in audit + cache)
    existing_audit_ids = {item['itemId'] for item in audit['naked_items']}
    added_to_audit = 0
    for iid_str, entry in results.items():
        iid = int(iid_str)
        if iid in existing_audit_ids:
            continue
        if iid in duplicate_ids:
            continue   # don't add Mythic-duplicates to audit (skip processing)
        audit['naked_items'].append({
            'itemId':    iid,
            'shortName': entry['name'].lower().replace(' ', '_'),
            'source':    'batch_fetch',
            'context':   f'BG-Wiki auto-fetched 2026-05-28',
            'modCount':  0,
            'latentCount': 0,
        })
        added_to_audit += 1

    print(f'Added {added_to_cache} entries to cache (+{added_to_audit} to audit)')
    print(f'Skipped {skipped_duplicates} Mythic-duplicate entries (will need manual fix)')

    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(
        json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(
        json.dumps(audit, indent=2), encoding='utf-8')

    # Re-run the gen
    print()
    print('Running gen_naked_item_stats.py...')
    result = subprocess.run(
        [sys.executable, str(REPO / 'tools' / 'gen_naked_item_stats.py')],
        cwd=str(REPO),
        capture_output=True,
        text=True,
    )
    print(result.stdout)
    if result.returncode != 0:
        print(f'GEN FAILED: {result.stderr}')
        return result.returncode

    print()
    print('Next: manually fix the Mythic-duplicate items (Caliburnus, Earp, etc.)')
    print(f'  See tools/naked_ilvl_duplicates.json for the full list.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
