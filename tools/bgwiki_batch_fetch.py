"""Batch-fetch BG-Wiki pages for all iLvl 100+ items currently empty in
item_mods. Outputs results into two files:

  tools/bgwiki_batch_results.json      — successful fetches (name → stats text)
  tools/bgwiki_batch_failed.json       — failed fetches (404s, no stats, etc.)

Strategy per item:
  1. Try the obvious URL: bg-wiki.com/ffxi/Title_Cased_Name
  2. If 404 / no stats found, try a few common variants:
       - With Mythic/REMA suffixes: "(Level_119)", "(Level_119_II)", "(Level_119_III)"
       - With apostrophe: "Name's_Suffix" instead of "Name_Suffix"
  3. If still nothing, mark as failed.

This runs in the user's terminal (probably 8-12 min for ~1100 items at
0.5s/request). The results files are then consumed by the regenerator
to populate bgwiki_stats_cache.json + gear_stat_audit.json.
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.parse
from pathlib import Path

REPO = Path(r'D:\server')
NAKED_LIST = REPO / 'tools' / 'naked_ilvl_items.json'
RESULTS = REPO / 'tools' / 'bgwiki_batch_results.json'
FAILED = REPO / 'tools' / 'bgwiki_batch_failed.json'
CACHE = REPO / 'tools' / 'bgwiki_stats_cache.json'

UA = 'Mozilla/5.0 (compatible; LSB-DataSync; +https://github.com/LandSandBoat/server)'

# Extract the stat text from a BG-Wiki page. The item-info-body cell
# holds the canonical stat string we want.
STATS_RE = re.compile(
    r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)'
)


def slugify(name: str) -> str:
    """LSB short-name -> BG-Wiki URL slug.
    'caliburnus' -> 'Caliburnus'
    'agoge_mufflers_+4' -> 'Agoge_Mufflers_%2B4'
    """
    # Title-case each underscore-separated token, then keep underscores.
    parts = name.split('_')
    titled = '_'.join(p.capitalize() if p and not p.startswith('+') else p
                      for p in parts)
    return urllib.parse.quote(titled, safe='_')


def url_variants(name: str) -> list[str]:
    """All URLs to try, in priority order."""
    base = slugify(name)
    out = [f'https://www.bg-wiki.com/ffxi/{base}']

    # Mythic/REMA upgrade tiers — try these BEFORE the base, because if
    # the base name is generic ("caliburnus"), the +0 / +1 / +2 / +3 share
    # the same LSB name and we need to disambiguate.
    for suffix in ['_(Level_119)', '_(Level_119_II)', '_(Level_119_III)']:
        out.append(f'https://www.bg-wiki.com/ffxi/{base}{suffix}')

    # Apostrophe handling: "amin_turban" -> "Amin%27s_Turban"
    if '_' in name and "'" not in base:
        first, _, rest = name.partition('_')
        apos_slug = f'{first.capitalize()}%27s_{rest.replace("_", "_").title()}'
        out.append(f'https://www.bg-wiki.com/ffxi/{apos_slug}')

    return out


def fetch_stats(url: str) -> str | None:
    """Returns the stat text or None on failure."""
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
    # Sanity: stat strings always have DEF/HP/MP/stats. If none of those
    # are present, the regex hit something unrelated.
    if not re.search(r'(DEF|HP|MP|STR|DEX|DMG):', stats):
        return None
    return stats


def main() -> int:
    data = json.loads(NAKED_LIST.read_text(encoding='utf-8'))
    cache = json.loads(CACHE.read_text(encoding='utf-8'))
    cached_ids = {int(k) for k in cache.keys()}

    items = [it for it in data['items'] if it['itemId'] not in cached_ids]
    total = len(items)
    print(f'Batch fetch: {total} items (skipping {len(data["items"]) - total} already cached)')

    results: dict[int, dict] = {}
    failed: list[dict] = []

    for i, item in enumerate(items, 1):
        iid = item['itemId']
        name = item['name']
        if i % 50 == 0:
            print(f'  [{i}/{total}] {iid} {name}  '
                  f'(ok={len(results)} fail={len(failed)})')

        stats = None
        winning_url = None
        for url in url_variants(name):
            stats = fetch_stats(url)
            if stats:
                winning_url = url
                break
            time.sleep(0.3)

        if stats:
            results[iid] = {
                'name':  name.replace('_', ' ').title(),
                'url':   winning_url,
                'stats': stats,
            }
        else:
            failed.append({
                'itemId':    iid,
                'shortName': name,
                'kind':      item['kind'],
                'ilevel':    item['ilevel'],
                'tried':     url_variants(name),
            })

        # Save incrementally every 100 items so we don't lose work on crash.
        if i % 100 == 0:
            RESULTS.write_text(json.dumps(results, indent=2), encoding='utf-8')
            FAILED.write_text(json.dumps(failed, indent=2), encoding='utf-8')

    RESULTS.write_text(json.dumps(results, indent=2), encoding='utf-8')
    FAILED.write_text(json.dumps(failed, indent=2), encoding='utf-8')
    print(f'\nDONE: {len(results)} resolved, {len(failed)} failed')
    print(f'  results: {RESULTS}')
    print(f'  failed:  {FAILED}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
