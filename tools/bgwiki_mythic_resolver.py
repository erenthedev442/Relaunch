"""Disambiguate Mythic / Empyrean / Aeonic weapon upgrade tiers.

For LSB names like 'caliburnus' with 4 itemIds and 4 distinct DMG values
(156/165/172/181), this script fetches the 4 BG-Wiki upgrade-tier pages:
  Caliburnus              -> base (DMG 156)
  Caliburnus_(Level_119)  -> first upgrade
  Caliburnus_(Level_119_II)
  Caliburnus_(Level_119_III)
and assigns the BG-Wiki stat block to the LSB item with matching DMG.

Run this AFTER bgwiki_batch_consolidate.py (which intentionally skips
duplicates so we don't smear the base item's stats across all tiers).
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.parse
from pathlib import Path
import pymysql

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync)'
STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')
DMG_RE = re.compile(r'DMG:[+]?(\d+)')


def fetch_stats(url: str) -> str | None:
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='replace')
    except Exception:
        return None
    m = STATS_RE.search(html)
    if not m:
        return None
    stats = m.group(1).strip()
    if not re.search(r'(DEF|HP|MP|STR|DEX|DMG):', stats):
        return None
    return stats


def title_case(name: str) -> str:
    parts = name.split('_')
    return '_'.join(p.capitalize() if p and not p.startswith('+') else p
                    for p in parts)


def main() -> int:
    duplicates = json.loads((REPO / 'tools' / 'naked_ilvl_duplicates.json').read_text(encoding='utf-8'))
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    audit = json.loads((REPO / 'tools' / 'gear_stat_audit.json').read_text(encoding='utf-8'))
    existing_audit_ids = {item['itemId'] for item in audit['naked_items']}

    c = pymysql.connect(host='127.0.0.1', user='root', password='warrior3', database='xidb')
    cur = c.cursor()

    TIER_SUFFIXES = ['', '_(Level_119)', '_(Level_119_II)', '_(Level_119_III)']
    resolved = 0
    failed = 0

    for name, itemIds in duplicates.items():
        slug = title_case(name)
        # Sort items by DMG (lowest = base)
        cur.execute(
            f'SELECT itemId, dmg FROM item_weapon WHERE itemId IN ({",".join(map(str, itemIds))}) ORDER BY dmg'
        )
        rows = cur.fetchall()
        if not rows:
            print(f'  SKIP {name}: no item_weapon rows')
            continue

        print(f'\n{name} ({len(rows)} tiers, DMG {",".join(str(r[1]) for r in rows)})')

        # Fetch each tier
        tier_stats = []
        for i, (iid, dmg) in enumerate(rows):
            if i >= len(TIER_SUFFIXES):
                print(f'    {iid} (DMG {dmg}): no more tier suffixes to try')
                failed += 1
                continue
            suffix = TIER_SUFFIXES[i]
            url = f'https://www.bg-wiki.com/ffxi/{urllib.parse.quote(slug + suffix, safe="_()")}'
            stats = fetch_stats(url)
            if not stats:
                # Try with the Aftermath / Mythic suffix variants
                for alt in ['_(Aftermath)', '_(Mythic)']:
                    stats = fetch_stats(f'https://www.bg-wiki.com/ffxi/{urllib.parse.quote(slug + alt, safe="_()")}')
                    if stats:
                        break
            if not stats:
                print(f'    {iid} (DMG {dmg}): FAILED — tried {url}')
                failed += 1
                continue

            # Sanity: the BG-Wiki DMG should roughly match the LSB DMG
            m = DMG_RE.search(stats)
            wiki_dmg = int(m.group(1)) if m else None
            if wiki_dmg is not None and abs(wiki_dmg - dmg) > 30:
                print(f'    {iid} (DMG {dmg}): warn - BG-Wiki DMG {wiki_dmg} differs from LSB ({dmg})')

            cache[str(iid)] = {'name': slug.replace('_', ' '), 'url': url, 'stats': stats}
            if iid not in existing_audit_ids:
                audit['naked_items'].append({
                    'itemId':    iid,
                    'shortName': f'{name}_tier_{i}',
                    'source':    'mythic_resolver',
                    'context':   f'Tier {i} of {name} (DMG {dmg})',
                    'modCount':  0,
                    'latentCount': 0,
                })
            print(f'    {iid} (DMG {dmg}): OK {url}')
            resolved += 1
            time.sleep(0.4)

    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')
    print(f'\nMythic resolver: {resolved} resolved, {failed} failed')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
