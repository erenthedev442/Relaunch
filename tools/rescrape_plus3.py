"""Re-fetch COMPLETE stat strings for the reforged +3 items from BG-Wiki.

The old scrape truncated many +3 entries in bgwiki_stats_cache.json (e.g.
Peltast's Mezail +3 cut off at 'Haste+7%', missing 'Weapon skill damage' etc.).
This re-fetches them fresh using the full DB name (with apostrophe variants, so
'peltasts_mezail' -> 'Peltast's_Mezail') and a robust <td> extractor.

Scope: only ids already present in bgwiki_stats_cache.json (the known reforged
armor set) -> bounded + avoids mis-fetching unrelated +3 weapons.

Reads:  plus3_names.txt (id<TAB>db_name), tools/bgwiki_stats_cache.json
Writes: tools/plus3_fresh_stats.json  ({id: stats})
"""
from __future__ import annotations
import json, re, time, urllib.request, urllib.parse
from pathlib import Path

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync; +https://github.com/LandSandBoat/server)'
TD = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)')


def variants(dbname: str):
    toks = dbname.split('_')
    cap = lambda t: t if t.startswith('+') else t.capitalize()
    base = '_'.join(cap(t) for t in toks)
    out = [base]
    first = toks[0]
    if first.endswith('s') and len(first) > 3:                # peltasts -> Peltast's
        apos = first[:-1].capitalize() + "'s"
        out.append('_'.join([apos] + [cap(t) for t in toks[1:]]))
    return out


def fetch(dbname: str):
    for v in variants(dbname):
        url = 'https://www.bg-wiki.com/ffxi/' + urllib.parse.quote(v, safe='_')
        try:
            html = urllib.request.urlopen(
                urllib.request.Request(url, headers={'User-Agent': UA}), timeout=15
            ).read().decode('utf-8', 'replace')
        except Exception:
            continue
        for m in TD.finditer(html):
            s = m.group(1).strip()
            if re.search(r'(DEF|HP|MP|STR|DEX|DMG):', s):
                return url, s
    return None, None


def main():
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    names = {}
    for line in (REPO / 'plus3_names.txt').read_text(encoding='utf-8').splitlines():
        if '\t' in line:
            iid, nm = line.split('\t', 1)
            names[iid.strip()] = nm.strip()
    targets = [iid for iid in names if iid in cache]   # only known reforged +3
    print(f"re-scraping {len(targets)} cached +3 items...", flush=True)

    fresh, fail = {}, []
    for i, iid in enumerate(targets, 1):
        url, s = fetch(names[iid])
        if s:
            fresh[iid] = {'name': cache[iid].get('name', ''), 'db': names[iid], 'stats': s, 'url': url}
        else:
            fail.append((iid, names[iid]))
        if i % 40 == 0:
            print(f"  [{i}/{len(targets)}] ok={len(fresh)} fail={len(fail)}", flush=True)
        time.sleep(0.3)

    (REPO / 'tools' / 'plus3_fresh_stats.json').write_text(
        json.dumps(fresh, ensure_ascii=False, indent=0), encoding='utf-8')
    print(f"\nDONE: fetched {len(fresh)}, failed {len(fail)}", flush=True)
    if fail:
        print("failures:", fail[:20], flush=True)


if __name__ == '__main__':
    main()
