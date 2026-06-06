"""Final-final pass — handle BG-Wiki redirects (Theophany_Pantaloons_+4
redirects to Theo._Pantaloons_+4) by detecting redirect text and following
to the target page."""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.parse
from pathlib import Path
import pymysql

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync/7)'
STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')
REDIRECT_TARGET_RE = re.compile(r'Redirect to:\s*<a href="/ffxi/([^"]+)"', re.IGNORECASE)
REDIRECT_TARGET_RE2 = re.compile(r'<link rel="canonical" href="https://www\.bg-wiki\.com/ffxi/([^"]+)"')


def fetch_page(url: str, follow_redirect: bool = True) -> tuple[str | None, str | None]:
    """Returns (stat_text, final_url) — follows MediaWiki redirects."""
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='replace')
            final_url = resp.geturl()

        # First try direct stat extraction
        m = STATS_RE.search(html)
        if m and re.search(r'(DEF|HP|MP|STR|DEX|DMG):', m.group(1)):
            return m.group(1).strip(), final_url

        # Check for "Redirect to:" pattern (MediaWiki soft redirect)
        if follow_redirect:
            redirect_m = REDIRECT_TARGET_RE.search(html)
            if redirect_m:
                target = redirect_m.group(1)
                # Follow the redirect
                return fetch_page(f'https://www.bg-wiki.com/ffxi/{target}', follow_redirect=False)

            # Check canonical URL — if it differs from our URL, follow it
            canonical_m = REDIRECT_TARGET_RE2.search(html)
            if canonical_m:
                target = canonical_m.group(1)
                target_url = f'https://www.bg-wiki.com/ffxi/{target}'
                if target_url != url and target_url != final_url:
                    return fetch_page(target_url, follow_redirect=False)

        return None, final_url
    except Exception:
        return None, None


# Known item-specific URL overrides (where the BG-Wiki name differs significantly
# from the LSB name in ways we can't auto-derive).
MANUAL_OVERRIDES = {
    # Taliah +2 set — BG-Wiki uses abbreviated names
    25796: 'https://www.bg-wiki.com/ffxi/Tal._Manteel_%2B2',
    25834: 'https://www.bg-wiki.com/ffxi/Tal._Gages_%2B2',
    25885: 'https://www.bg-wiki.com/ffxi/Tal._Seraweels_%2B2',
    25952: 'https://www.bg-wiki.com/ffxi/Tal._Crackows_%2B2',
    # Talab — likely "Talab" exists with different name
    27322: 'https://www.bg-wiki.com/ffxi/Talab_Trousers',
    # Hairpins — try alternative names
    26696: 'https://www.bg-wiki.com/ffxi/Pixie_Hairpin_%2B1',
    26699: 'https://www.bg-wiki.com/ffxi/Theia%27s_Hairpin_%2B1',
    26709: 'https://www.bg-wiki.com/ffxi/Imp._Wing_Hairpin',
    # Regal Captain's (confirmed by probe)
    25825: 'https://www.bg-wiki.com/ffxi/Regal_Captain%27s_Gloves',
    # Mutsu-no-Kami Yoshiyuki — verified Level_119 page
    21953: 'https://www.bg-wiki.com/ffxi/Mutsu-no-Kami_Yoshiyuki_(Lv.119)',
}

# Items that legitimately don't exist on BG-Wiki — tag as custom/no-bgwiki
CONFIRMED_CUSTOM = {
    21541,  # premium_hearts (joke item)
    23861,  # suit_of_adamantite_armor (joke item)
    20752,  # extra lexeme_blade tier
    21303, 21317, 21332,  # rakaznar ammo (naked-by-design)
}


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
    uncovered = sorted(naked_ids - sql_ids)
    items_by_id = {it['itemId']: it for it in naked['items']}
    print(f'Targeting {len(uncovered)} uncovered items with redirect handling')

    recovered = 0
    failed = []

    for iid in uncovered:
        item = items_by_id.get(iid, {})
        name = item.get('name', f'item_{iid}')

        # Try manual override first
        if iid in MANUAL_OVERRIDES:
            url = MANUAL_OVERRIDES[iid]
            stats, final_url = fetch_page(url)
            if stats:
                cache[str(iid)] = {'name': name.replace('_', ' '), 'url': final_url or url, 'stats': stats}
                if iid not in existing_audit_ids:
                    audit['naked_items'].append({
                        'itemId': iid, 'shortName': name, 'source': 'redirect_fix',
                        'context': 'BG-Wiki redirect/override', 'modCount': 0, 'latentCount': 0,
                    })
                recovered += 1
                print(f'  OK   {iid:>5} {name:<30} -> {final_url or url}')
                time.sleep(1.0)
                continue

        # For everything else, derive URL and follow redirects
        parts = name.split('_')
        titled = []
        for i, p in enumerate(parts):
            if p.startswith('+'):
                titled.append(p)
            elif p.lower() in {'csm', 'csf', 'mg', 'mgm', 'mgf', 'wn', 'sv', 'el'}:
                titled.append(p.upper())
            elif '-' in p:
                titled.append('-'.join(s.capitalize() if s.lower() not in {'no', 'of', 'the'} else s.lower()
                                       for s in p.split('-')))
            else:
                titled.append(p.capitalize())

        slug = '_'.join(titled).replace("'", '%27').replace('+', '%2B')
        url = f'https://www.bg-wiki.com/ffxi/{slug}'
        stats, final_url = fetch_page(url)

        # Try possessive variant
        if not stats and titled[0].endswith('s') and len(titled[0]) >= 5:
            possessive_slug = '_'.join([titled[0][:-1] + "'s"] + titled[1:])
            possessive_slug = possessive_slug.replace("'", '%27').replace('+', '%2B')
            url2 = f'https://www.bg-wiki.com/ffxi/{possessive_slug}'
            stats, final_url = fetch_page(url2)

        if stats:
            cache[str(iid)] = {'name': name.replace('_', ' '), 'url': final_url or url, 'stats': stats}
            if iid not in existing_audit_ids:
                audit['naked_items'].append({
                    'itemId': iid, 'shortName': name, 'source': 'redirect_fix',
                    'context': 'Followed redirect', 'modCount': 0, 'latentCount': 0,
                })
            recovered += 1
            print(f'  OK   {iid:>5} {name:<30} -> {final_url or url}')
        else:
            failed.append((iid, name))
            print(f'  -    {iid:>5} {name:<30} (no resolution)')
        time.sleep(1.0)

    # Save
    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')

    # Tag CONFIRMED_CUSTOM as naked-by-design
    custom_tagged = 0
    for iid in CONFIRMED_CUSTOM:
        if iid in unresolved_ids: continue
        item = items_by_id.get(iid, {})
        unresolved.append({
            'itemId': iid, 'shortName': item.get('name', f'item_{iid}'),
            'context': 'Confirmed custom/joke item with no BG-Wiki equivalent',
            'reason': 'Joke or custom server item; no retail stats exist.',
            'bgwiki': '',
        })
        unresolved_ids.add(iid)
        custom_tagged += 1
    (REPO / 'tools' / 'naked_items_unresolved.json').write_text(json.dumps(unresolved, indent=2), encoding='utf-8')

    print(f'\nRedirect-fix: {recovered} recovered, {len(failed)} still failed, {custom_tagged} tagged as custom')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
