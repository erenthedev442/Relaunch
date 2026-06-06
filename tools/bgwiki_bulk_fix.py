"""Bulk fix for the 60 Bucket-4 items.

URL builder tries every pattern we've learned across the session:
  1. Plain title-case
  2. ALL-CAPS short tokens (for CSM/CSF/MG/WN/SV/EL abbreviations)
  3. Possessive (first word ends in 's' -> "X's")
  4. Hyphen-aware capitalization (Sune-Ate, Kusanagi-no-Tsurugi)
  5. Mythic Level_119 / Level_119_II / Level_119_III suffix variants
  6. Combinations of above

Assigns Mythic upgrade tiers by DMG order so we don't smear the highest-
tier stats onto the base item again.
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.parse
from pathlib import Path
from collections import defaultdict
import pymysql

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync/6)'
DELAY = 1.0
STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')

# Tokens that should stay ALL CAPS (not title-cased)
ALL_CAPS_TOKENS = {'csm', 'csf', 'mg', 'mgm', 'mgf', 'wn', 'sv', 'el',
                   'amm', 'iii', 'ii', 'iv', 'rdm', 'whm', 'blm'}

# Tokens that should stay lowercase when not first
LOWER_TOKENS = {'no', 'of', 'the', 'a', 'and'}


def fetch(url: str) -> str | None:
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='replace')
        m = STATS_RE.search(html)
        if not m: return None
        stats = m.group(1).strip()
        if not re.search(r'(DEF|HP|MP|STR|DEX|DMG):', stats): return None
        return stats
    except Exception:
        return None


def smart_token(token: str, is_first: bool) -> str:
    """Cap a token preserving:
      - All-caps short abbreviations
      - Hyphenated subwords (Sune-Ate, Kusanagi-no-Tsurugi)
      - Lowercase prepositions
    """
    if token.startswith('+'):
        return token
    if token.lower() in ALL_CAPS_TOKENS:
        return token.upper()
    if not is_first and token.lower() in LOWER_TOKENS:
        return token.lower()
    # Handle hyphenated tokens
    if '-' in token:
        return '-'.join(smart_token(p, i == 0) for i, p in enumerate(token.split('-')))
    return token.capitalize()


def url_variants(name: str, with_mythic_tiers: bool = False) -> list[str]:
    """Build every plausible URL for an LSB item name."""
    parts = name.split('_')
    titled = [smart_token(p, i == 0) for i, p in enumerate(parts)]
    out: list[str] = []

    # 1. Plain title
    out.append('_'.join(titled))

    # 2. Possessive on first word
    first = titled[0]
    if first.endswith('s') and len(first) >= 5 and "'" not in first and not first.isupper():
        out.append("_".join([first[:-1] + "'s"] + titled[1:]))

    # 3. Mythic upgrade tiers
    if with_mythic_tiers:
        base = '_'.join(titled)
        for sfx in ['_(Level_119)', '_(Level_119_II)', '_(Level_119_III)']:
            out.append(base + sfx)

    # Encode and return URLs
    def encode(slug):
        return slug.replace("'", '%27').replace('+', '%2B').replace(' ', '_')
    return [f'https://www.bg-wiki.com/ffxi/{encode(s)}' for s in out]


def main() -> int:
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    audit = json.loads((REPO / 'tools' / 'gear_stat_audit.json').read_text(encoding='utf-8'))
    unresolved = json.loads((REPO / 'tools' / 'naked_items_unresolved.json').read_text(encoding='utf-8'))
    unresolved_ids = {e['itemId'] for e in unresolved}
    existing_audit_ids = {item['itemId'] for item in audit['naked_items']}

    naked = json.loads((REPO / 'tools' / 'naked_ilvl_items.json').read_text(encoding='utf-8'))
    sql_text = (REPO / 'sql' / 'zz_custom_naked_item_mods.sql').read_text(encoding='utf-8')
    sql_ids = set(int(m.group(1)) for m in re.finditer(r'INSERT INTO `item_mods` VALUES \((\d+),', sql_text))
    naked_ids = set(naked['itemIds'])

    # The targets are items still uncovered AND not yet tagged as naked-by-design.
    # Exclude Mythic bases (we already correctly tagged those).
    duplicates = json.loads((REPO / 'tools' / 'naked_ilvl_duplicates.json').read_text(encoding='utf-8'))

    c = pymysql.connect(host='127.0.0.1', user='root', password='warrior3', database='xidb')
    cur = c.cursor()

    # Mythic-base detection
    mythic_bases = set()
    for nm, ids in duplicates.items():
        cur.execute(f'SELECT itemId, dmg FROM item_weapon WHERE itemId IN ({",".join(map(str, ids))}) ORDER BY dmg LIMIT 1')
        r = cur.fetchone()
        if r:
            mythic_bases.add(r[0])

    # Pull all uncovered items + their info
    uncovered = sorted(naked_ids - sql_ids - unresolved_ids - mythic_bases)
    name_by_id = {}
    items = {it['itemId']: it for it in naked['items']}
    for iid in uncovered:
        name_by_id[iid] = items[iid]['name']
    print(f'Bulk fix targeting {len(uncovered)} items')

    # Group duplicate-name items so we handle Mythic tiers correctly
    by_name = defaultdict(list)
    for iid in uncovered:
        name = name_by_id[iid]
        by_name[name].append(iid)

    recovered = 0
    failed = []

    for name, ids in sorted(by_name.items()):
        # Sort the IDs by DMG (for Mythic tier ordering)
        if len(ids) > 1:
            cur.execute(f'SELECT itemId, dmg FROM item_weapon WHERE itemId IN ({",".join(map(str, ids))}) ORDER BY dmg')
            ids = [r[0] for r in cur.fetchall()] or ids
            with_mythic = True
        else:
            with_mythic = True   # also try Mythic URLs for single-tier items (some items are just Mythic+3)

        urls = url_variants(name, with_mythic_tiers=with_mythic)

        # For Mythic groups: assign URLs by tier (lowest-DMG = base/plain, then Level_119s)
        if len(ids) > 1 and with_mythic:
            # Non-mythic URLs come first (plain, possessive), then mythic suffixes
            plain_urls = [u for u in urls if 'Level_119' not in u]
            mythic_urls = [u for u in urls if 'Level_119' in u]
            # Try plain URLs first for the lowest-DMG item
            stats = None
            winning = None
            for url in plain_urls:
                stats = fetch(url)
                if stats:
                    winning = url
                    cache[str(ids[0])] = {'name': name.replace('_', ' '), 'url': url, 'stats': stats}
                    if ids[0] not in existing_audit_ids:
                        audit['naked_items'].append({
                            'itemId': ids[0], 'shortName': name, 'source': 'bulk_fix',
                            'context': 'Bulk URL fix', 'modCount': 0, 'latentCount': 0,
                        })
                    recovered += 1
                    print(f'  OK  {ids[0]:>5} {name:<32} (base) {url}')
                    break
                time.sleep(0.3)
            if not stats:
                failed.append((ids[0], name, 'no base URL worked'))

            # Higher tiers get the mythic suffix URLs in order
            sorted_mythic = sorted(mythic_urls, key=lambda u: ('III' in u, 'II' in u and 'III' not in u, '119)' in u))
            # Reorder: Level_119 (single), Level_119_II, Level_119_III
            sorted_mythic = [u for u in mythic_urls if 'Level_119)' in u] + \
                            [u for u in mythic_urls if 'Level_119_II)' in u] + \
                            [u for u in mythic_urls if 'Level_119_III)' in u]
            for idx, iid in enumerate(ids[1:], start=0):
                if idx >= len(sorted_mythic): continue
                url = sorted_mythic[idx]
                stats = fetch(url)
                if stats:
                    cache[str(iid)] = {'name': name.replace('_', ' '), 'url': url, 'stats': stats}
                    if iid not in existing_audit_ids:
                        audit['naked_items'].append({
                            'itemId': iid, 'shortName': name, 'source': 'bulk_fix',
                            'context': f'Bulk URL fix tier {idx+1}', 'modCount': 0, 'latentCount': 0,
                        })
                    recovered += 1
                    print(f'  OK  {iid:>5} {name:<32} (tier {idx+1}) {url}')
                else:
                    failed.append((iid, name, url))
                time.sleep(DELAY)
        else:
            # Single item: try all variants in order
            stats = None
            winning = None
            for url in urls:
                stats = fetch(url)
                if stats:
                    winning = url
                    break
                time.sleep(0.3)
            iid = ids[0]
            if stats:
                cache[str(iid)] = {'name': name.replace('_', ' '), 'url': winning, 'stats': stats}
                if iid not in existing_audit_ids:
                    audit['naked_items'].append({
                        'itemId': iid, 'shortName': name, 'source': 'bulk_fix',
                        'context': 'Bulk URL fix', 'modCount': 0, 'latentCount': 0,
                    })
                recovered += 1
                print(f'  OK  {iid:>5} {name:<32} {winning}')
            else:
                failed.append((iid, name, 'no URL variant worked'))
                print(f'  -   {iid:>5} {name:<32} FAILED')
        time.sleep(DELAY)

    # Save
    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')

    # Tag remaining failures as "needs human triage"
    for iid, name, reason in failed:
        if iid in unresolved_ids: continue
        unresolved.append({
            'itemId': iid, 'shortName': name,
            'context': 'Bulk fix exhausted all URL variants',
            'reason': f'Last attempted: {reason}',
            'bgwiki': '',
        })
    (REPO / 'tools' / 'naked_items_unresolved.json').write_text(json.dumps(unresolved, indent=2), encoding='utf-8')

    print(f'\nBulk fix: {recovered} recovered, {len(failed)} truly stuck')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
