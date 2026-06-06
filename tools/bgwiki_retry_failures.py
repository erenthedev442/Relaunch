"""Retry the failed BG-Wiki fetches with:
  - Improved URL logic (possessives, apostrophes)
  - Conservative rate limiting (2s between requests)
  - 429 backoff (waits 60s and retries)

Reads tools/bgwiki_batch_failed.json (output of bgwiki_batch_fetch.py),
appends new successes into bgwiki_batch_results.json, rewrites the
failed list with the remaining-failures (so re-running shrinks the pile).
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.parse
from pathlib import Path

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync/2)'
DELAY = 2.0   # seconds between requests, polite rate
BACKOFF_429 = 60   # wait 60s on rate limit hit, then retry once

STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')


def fetch(url: str) -> tuple[int, str | None]:
    """Return (status_code, stat_text or None)."""
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='replace')
        m = STATS_RE.search(html)
        if not m:
            return 200, None
        stats = m.group(1).strip()
        if not re.search(r'(DEF|HP|MP|STR|DEX|DMG):', stats):
            return 200, None
        return 200, stats
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception:
        return 0, None


def url_variants_v2(name: str) -> list[str]:
    """Improved URL builder — handles possessives + plural-confused names."""
    parts = name.split('_')
    titled = [p.capitalize() if p and not p.startswith('+') else p for p in parts]

    out = []

    # Variant 1: plain title-case
    out.append('_'.join(titled))

    # Variant 2: possessive — if first word ends in 's' (likely possessive
    # form in the LSB schema like 'academics' -> "Academic's"), insert apostrophe
    if titled and len(titled[0]) >= 4 and titled[0].endswith('s'):
        possessive = titled[0][:-1] + '%27s'   # %27 = '
        out.append('_'.join([possessive] + titled[1:]))

    # Variant 3: if name ends with _+N, also try without spaces in suffix
    # (BG-Wiki sometimes has "Item_Name_+N" vs "Item_Name_%2BN")
    base = '_'.join(titled)
    if re.search(r'_%2B\d$', urllib.parse.quote(base, safe='_+')):
        pass   # already covered

    # Return as full URLs
    return [
        f'https://www.bg-wiki.com/ffxi/{urllib.parse.quote(v, safe="_()")}' for v in out
    ]


def main() -> int:
    failed_path = REPO / 'tools' / 'bgwiki_batch_failed.json'
    results_path = REPO / 'tools' / 'bgwiki_batch_results.json'
    failed = json.loads(failed_path.read_text(encoding='utf-8'))
    results = json.loads(results_path.read_text(encoding='utf-8'))

    print(f'Retrying {len(failed)} failed items with improved URL logic')

    new_results = 0
    still_failed = []
    backoff_count = 0

    for i, item in enumerate(failed, 1):
        iid = item['itemId']
        name = item['shortName']

        if i % 25 == 0:
            print(f'  [{i}/{len(failed)}] ok={new_results} fail={len(still_failed)} backoffs={backoff_count}')

        stats = None
        winning_url = None
        for url in url_variants_v2(name):
            status, stats = fetch(url)
            if status == 429:
                # Rate-limited: wait and try once more
                backoff_count += 1
                print(f'    429 on {url} - sleeping {BACKOFF_429}s')
                time.sleep(BACKOFF_429)
                status, stats = fetch(url)
            if stats:
                winning_url = url
                break
            time.sleep(0.3)

        if stats:
            results[str(iid)] = {
                'name': name.replace('_', ' ').title(),
                'url': winning_url,
                'stats': stats,
            }
            new_results += 1
        else:
            still_failed.append(item)

        time.sleep(DELAY)

        # Periodic save
        if i % 50 == 0:
            results_path.write_text(json.dumps(results, indent=2), encoding='utf-8')
            failed_path.write_text(json.dumps(still_failed + failed[i:], indent=2), encoding='utf-8')

    results_path.write_text(json.dumps(results, indent=2), encoding='utf-8')
    failed_path.write_text(json.dumps(still_failed, indent=2), encoding='utf-8')
    print(f'\nDONE: {new_results} newly resolved, {len(still_failed)} still failed')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
