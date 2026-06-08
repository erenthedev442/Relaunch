"""Generic BG-Wiki re-scraper: fetch complete stat strings for a list of items.

Usage:  python tools/rescrape_tier.py <names_file> <out_json>
  names_file: lines of "itemId<TAB>db_name"
  out_json:   {itemId: {db, stats, url}}

Same robust extraction as rescrape_plus3.py (full DB name + apostrophe variants
+ multi-<td> stat-block match). Scrapes ALL names (no cache filter).
"""
from __future__ import annotations
import json, re, sys, time, urllib.request, urllib.parse
from pathlib import Path

UA = 'Mozilla/5.0 (compatible; LSB-DataSync; +https://github.com/LandSandBoat/server)'
TD = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)')


def variants(dbname: str):
    toks = dbname.split('_')
    cap = lambda t: t if t.startswith('+') else t.capitalize()
    out = ['_'.join(cap(t) for t in toks)]
    first = toks[0]
    if first.endswith('s') and len(first) > 3:
        out.append('_'.join([first[:-1].capitalize() + "'s"] + [cap(t) for t in toks[1:]]))
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
    names_file, out_json = sys.argv[1], sys.argv[2]
    names = {}
    for line in Path(names_file).read_text(encoding='utf-8').splitlines():
        if '\t' in line:
            iid, nm = line.split('\t', 1)
            names[iid.strip()] = nm.strip()
    print(f"scraping {len(names)} items...", flush=True)
    fresh, fail = {}, []
    for i, (iid, nm) in enumerate(names.items(), 1):
        url, s = fetch(nm)
        if s:
            fresh[iid] = {'db': nm, 'stats': s, 'url': url}
        else:
            fail.append((iid, nm))
        if i % 75 == 0:
            print(f"  [{i}/{len(names)}] ok={len(fresh)} fail={len(fail)}", flush=True)
        time.sleep(0.25)
    Path(out_json).write_text(json.dumps(fresh, ensure_ascii=False), encoding='utf-8')
    print(f"DONE: {len(fresh)} ok, {len(fail)} fail -> {out_json}", flush=True)
    if fail:
        print("sample fails:", fail[:15], flush=True)


if __name__ == '__main__':
    main()
