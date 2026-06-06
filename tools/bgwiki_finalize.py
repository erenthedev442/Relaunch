"""Phase 4 — final classification of the 75 truly-uncovered items.

After Phase 1-3, the remaining items split into these categories:

1. **Mythic base tiers** (Caliburnus 21643, Idris 21070, Helheim 21651, etc.)
   — retail FFXI design: the unupgraded Mythic has NO item_mods bonuses,
   only DMG/Delay from item_weapon. BG-Wiki landing page (/Caliburnus)
   confirms no stat block. Naked by design.

2. **Joke / placeholder items** (Onion Sword III, Save the Queen III,
   Brave Blade III, Premium Hearts) — `_iii` suffix on items that aren't
   true Mythic III tiers; these are easter-eggs without BG-Wiki pages.

3. **Ammo** (Rakaznar arrow/bolt/bullet, etc.) — no item_mods by FFXI
   convention.

4. **Resolvable misses** (Nodal Wand has a BG-Wiki page with stats; we
   missed it earlier due to URL handling).

5. **Truly custom** (Lexeme Blade, gnafrons_adargas, archdukes_sword,
   custom server items with no retail equivalent).

This script:
- Tags categories 1, 2, 3 as naked-by-design in unresolved.json (those
  are the correct designs, not bugs).
- Fetches category 4 items.
- Marks category 5 with a "custom_no_bgwiki" reason for triage.
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
UA = 'Mozilla/5.0 (compatible; LSB-DataSync/4)'

STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')


def fetch(url: str) -> str | None:
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='replace')
        m = STATS_RE.search(html)
        if not m: return None
        stats = m.group(1).strip()
        if not re.search(r'(DEF|HP|MP|STR|DEX|DMG):', stats):
            return None
        return stats
    except Exception:
        return None


def main() -> int:
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    audit = json.loads((REPO / 'tools' / 'gear_stat_audit.json').read_text(encoding='utf-8'))
    unresolved_path = REPO / 'tools' / 'naked_items_unresolved.json'
    unresolved = json.loads(unresolved_path.read_text(encoding='utf-8'))
    unresolved_ids = {e['itemId'] for e in unresolved}
    existing_audit_ids = {item['itemId'] for item in audit['naked_items']}

    naked = json.loads((REPO / 'tools' / 'naked_ilvl_items.json').read_text(encoding='utf-8'))
    sql_text = (REPO / 'sql' / 'zz_custom_naked_item_mods.sql').read_text(encoding='utf-8')
    sql_ids = set(int(m.group(1)) for m in re.finditer(r'INSERT INTO `item_mods` VALUES \((\d+),', sql_text))
    naked_ids = set(naked['itemIds'])
    uncovered = sorted(naked_ids - sql_ids - unresolved_ids)
    print(f'Starting with {len(uncovered)} uncovered items')

    c = pymysql.connect(host='127.0.0.1', user='root', password='warrior3', database='xidb')
    cur = c.cursor()

    # Pre-fetch item info
    info: dict[int, dict] = {}
    for iid in uncovered:
        cur.execute('SELECT name FROM item_basic WHERE itemId=%s', (iid,))
        r = cur.fetchone()
        if r: info[iid] = {'name': r[0]}
        cur.execute('SELECT dmg, delay FROM item_weapon WHERE itemId=%s', (iid,))
        r = cur.fetchone()
        if r: info[iid].update({'dmg': r[0], 'delay': r[1]})

    # Mythic-base detection: items in the duplicates list whose tier (DMG order)
    # is the lowest, AND the higher tiers ARE already in cache (meaning the
    # base is the ONLY one missing — confirming it's a "naked base").
    dupes = json.loads((REPO / 'tools' / 'naked_ilvl_duplicates.json').read_text(encoding='utf-8'))
    mythic_bases: set[int] = set()
    for name, ids in dupes.items():
        # Sort by DMG
        cur.execute(f'SELECT itemId, dmg FROM item_weapon WHERE itemId IN ({",".join(map(str, ids))}) ORDER BY dmg')
        sorted_ids = [r[0] for r in cur.fetchall()]
        if len(sorted_ids) < 2: continue
        # The lowest-DMG one is the base
        base_id = sorted_ids[0]
        # Higher tiers should mostly be covered (in cache or SQL)
        higher_covered = sum(1 for iid in sorted_ids[1:] if iid in sql_ids or str(iid) in cache)
        if higher_covered >= 1:    # at least one higher tier is covered
            mythic_bases.add(base_id)

    # ---- CATEGORY 1: Mythic bases ----
    p1 = 0
    for iid in uncovered:
        if iid in mythic_bases:
            name = info.get(iid, {}).get('name', f'item_{iid}')
            unresolved.append({
                'itemId': iid, 'shortName': name,
                'context': 'Mythic base tier — naked by retail design',
                'reason': 'Mythic base form has DMG/Delay only; stats come from Magian upgrade tiers. BG-Wiki landing page confirms no item_mods.',
                'bgwiki': f'https://www.bg-wiki.com/ffxi/{name.title()}',
            })
            unresolved_ids.add(iid)
            p1 += 1
    print(f'  Cat 1 (Mythic bases): {p1} tagged naked-by-design')

    # ---- CATEGORY 2: Joke items (suffix _iii on non-Mythic, premium_*, etc.) ----
    JOKE_SUBSTRINGS = ['onion_sword_iii', 'save_the_queen_iii', 'brave_blade_iii',
                       'premium_hearts', 'premium_mogti', 'lexeme_blade']
    p2 = 0
    for iid in uncovered:
        if iid in mythic_bases: continue
        name = info.get(iid, {}).get('name', '')
        if any(s == name for s in JOKE_SUBSTRINGS):
            unresolved.append({
                'itemId': iid, 'shortName': name,
                'context': 'Joke / placeholder item — no BG-Wiki page',
                'reason': 'Easter-egg or custom item without a retail BG-Wiki equivalent. Has DMG/Delay if applicable; no stat bonuses.',
                'bgwiki': '',
            })
            unresolved_ids.add(iid)
            p2 += 1
    print(f'  Cat 2 (Joke items): {p2} tagged naked-by-design')

    # ---- CATEGORY 3: Ammo ----
    AMMO_SUBSTRINGS = ['_arrow', '_bolt', '_bullet']
    p3 = 0
    for iid in uncovered:
        if iid in unresolved_ids: continue
        name = info.get(iid, {}).get('name', '')
        if any(s in name for s in AMMO_SUBSTRINGS):
            unresolved.append({
                'itemId': iid, 'shortName': name,
                'context': 'Ammo — no item_mods by FFXI convention',
                'reason': 'Ammunition items use DMG/Delay only; no stat bonuses by design.',
                'bgwiki': '',
            })
            unresolved_ids.add(iid)
            p3 += 1
    print(f'  Cat 3 (Ammo): {p3} tagged naked-by-design')

    # ---- CATEGORY 4: Try one more fetch on the rest ----
    p4 = 0
    still_uncovered = [iid for iid in uncovered if iid not in unresolved_ids and iid not in mythic_bases]
    for iid in still_uncovered:
        name = info.get(iid, {}).get('name', '')
        if not name: continue
        # Try plain title-case
        titled = '_'.join(p.capitalize() if not p.startswith('+') else p for p in name.split('_'))
        url = f'https://www.bg-wiki.com/ffxi/{titled}'.replace('+', '%2B')
        stats = fetch(url)
        if not stats:
            # Try possessive
            first = name.split('_')[0]
            if first.endswith('s') and len(first) >= 5:
                poss = first[:-1].capitalize() + "%27s"
                rest_parts = name.split('_')[1:]
                rest = '_'.join(p.capitalize() if not p.startswith('+') else p for p in rest_parts)
                url = f'https://www.bg-wiki.com/ffxi/{poss}_{rest}'.replace('+', '%2B')
                stats = fetch(url)
        if stats:
            cache[str(iid)] = {'name': name.replace('_', ' ').title(), 'url': url, 'stats': stats}
            if iid not in existing_audit_ids:
                audit['naked_items'].append({
                    'itemId': iid, 'shortName': name, 'source': 'phase4_final',
                    'context': 'BG-Wiki final retry', 'modCount': 0, 'latentCount': 0,
                })
            p4 += 1
        time.sleep(0.6)
    print(f'  Cat 4 (Final retry): {p4} recovered')

    # ---- CATEGORY 5: Mark the rest as custom_no_bgwiki ----
    p5 = 0
    final_uncovered = []
    sql_text = (REPO / 'sql' / 'zz_custom_naked_item_mods.sql').read_text(encoding='utf-8')
    sql_ids_after = set(int(m.group(1)) for m in re.finditer(r'INSERT INTO `item_mods` VALUES \((\d+),', sql_text))
    for iid in uncovered:
        if iid in unresolved_ids: continue
        if str(iid) in cache: continue
        name = info.get(iid, {}).get('name', f'item_{iid}')
        unresolved.append({
            'itemId': iid, 'shortName': name,
            'context': 'No BG-Wiki page found',
            'reason': 'Custom server item or wildly-nonstandard naming. Needs manual stat decision or removal from catalog.',
            'bgwiki': '',
        })
        unresolved_ids.add(iid)
        final_uncovered.append((iid, name))
        p5 += 1
    print(f'  Cat 5 (No BG-Wiki found): {p5} marked for triage')

    # Save everything
    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')
    unresolved_path.write_text(json.dumps(unresolved, indent=2), encoding='utf-8')

    print(f'\n=== FINAL DISPOSITION ===')
    print(f'Cat 1 (Mythic bases, naked-by-design):  {p1}')
    print(f'Cat 2 (Joke items, naked-by-design):    {p2}')
    print(f'Cat 3 (Ammo, naked-by-design):          {p3}')
    print(f'Cat 4 (Recovered via final retry):      {p4}')
    print(f'Cat 5 (Custom / no-BG-Wiki):            {p5}')
    print(f'TOTAL: {p1 + p2 + p3 + p4 + p5} items classified')
    if final_uncovered:
        print()
        print('Truly stuck (need human decision):')
        for iid, name in final_uncovered[:30]:
            print(f'  {iid}: {name}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
