#!/usr/bin/env python3
"""
Fetch and cache item stats from FFXIAH.com for offline retail comparison.

Run from repo root; caches to tools/ffxiah_item_cache.json.

Usage:
  python3 tools/fetch_ffxiah_cache.py              # il119+ items from live DB
  python3 tools/fetch_ffxiah_cache.py --ilevel-min=99
  python3 tools/fetch_ffxiah_cache.py --item-ids=23732,23733,23734
  python3 tools/fetch_ffxiah_cache.py --refresh-days=0   # force refresh all
  python3 tools/fetch_ffxiah_cache.py --dry-run          # list what needs fetching
  python3 tools/fetch_ffxiah_cache.py --max-items=50     # cap total fetched
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

REPO_ROOT = Path(__file__).resolve().parents[1]
CACHE_FILE = Path(__file__).parent / 'ffxiah_item_cache.json'
BASE_URL = 'https://www.ffxiah.com/item/{}'
USER_AGENT = (
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
)
DELAY_SECONDS = 1.5   # between requests — be respectful
SAVE_EVERY = 50       # checkpoint save interval


def load_cache() -> dict:
    if CACHE_FILE.exists():
        with open(CACHE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def save_cache(cache: dict) -> None:
    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        json.dump(cache, f, indent=2, ensure_ascii=False)


def is_stale(entry: dict, max_age_days: int) -> bool:
    ts = entry.get('fetched_at')
    if not ts:
        return True
    try:
        dt = datetime.fromisoformat(ts)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        age = (datetime.now(timezone.utc) - dt).days
        return age >= max_age_days
    except Exception:
        return True


def fetch_html(item_id: int) -> str | None:
    url = BASE_URL.format(item_id)
    req = Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urlopen(req, timeout=15) as resp:
            return resp.read().decode('utf-8', errors='replace')
    except HTTPError as e:
        if e.code == 404:
            return None
        print(f'  HTTP {e.code} for item {item_id}', file=sys.stderr)
        return None
    except URLError as e:
        print(f'  Network error for item {item_id}: {e}', file=sys.stderr)
        return None


def parse_stats_text(text: str) -> dict[str, int]:
    """
    Parse FFXIAH stats text into {stat_name: int_value}.

    Handles:
      DEF:121                  -> {'DEF': 121}
      HP+45 MP+29              -> {'HP': 45, 'MP': 29}
      "Magic Def. Bonus"+5     -> {'Magic Def. Bonus': 5}
      Haste+6%                 -> {'Haste': 6}
      Damage taken-6%          -> {'Damage taken': -6}
      Physical damage limit+3% -> {'Physical damage limit': 3}
    """
    stats: dict[str, int] = {}
    text = ' '.join(text.split())  # normalise whitespace / newlines
    pos = 0

    while pos < len(text):
        # skip leading spaces
        while pos < len(text) and text[pos] == ' ':
            pos += 1
        if pos >= len(text):
            break

        # ── quoted name: "Store TP"+8 ────────────────────────────────────────
        if text[pos] == '"':
            end_q = text.find('"', pos + 1)
            if end_q == -1:
                break
            name = text[pos + 1:end_q]
            pos = end_q + 1
        else:
            # ── find where the value (+N / -N / :N) starts ──────────────────
            m = re.search(r'[+\-:]\d', text[pos:])
            if not m:
                break
            name = text[pos:pos + m.start()].strip()
            pos += m.start()

        # ── parse value (+N, -N, :N) followed by optional % ─────────────────
        m_val = re.match(r'[:\-+]\d+', text[pos:])
        if not m_val:
            continue
        raw = text[pos:pos + m_val.end()]
        pos += m_val.end()
        if pos < len(text) and text[pos] == '%':
            pos += 1   # discard — we track pct-ness via the stat name

        if not name:
            continue

        value = int(raw[1:]) if raw[0] == ':' else int(raw)
        stats[name] = value

    return stats


def parse_item_page(html: str) -> tuple[str, dict[str, int]]:
    """Return (item_name, stats_dict) from FFXIAH item page HTML."""
    m_name = re.search(r"<span class='ucwords'>([^<]+)</span>", html)
    name = m_name.group(1).strip() if m_name else ''

    m_stats = re.search(r"<span class='item-stats'>(.*?)</span>", html, re.S)
    if not m_stats:
        return name, {}

    content = m_stats.group(1)
    # Split on <br> — parts[0] = "[Slot] All Races", parts[-1] = "LV XX JOBS"
    parts = re.split(r'<br\s*/?>', content, flags=re.I)
    if len(parts) < 3:
        return name, {}

    stats_text = ' '.join(parts[1:-1])
    # Strip any stray HTML
    stats_text = re.sub(r'<[^>]+>', '', stats_text)
    stats_text = re.sub(r'&amp;', '&', stats_text)
    stats_text = re.sub(r'&quot;', '"', stats_text)

    return name, parse_stats_text(stats_text)


def get_items_from_db(ilevel_min: int) -> list[tuple[int, str]]:
    """Query local DB for equippable items >= ilevel_min."""
    sys.path.insert(0, str(REPO_ROOT))
    try:
        from tools.docgen import _db
        conn = _db.connect(REPO_ROOT)
    except Exception as e:
        print(f'DB import error: {e}', file=sys.stderr)
        return []
    if conn is None:
        print('DB not available — set LEGENDARY_LIVE_ROOT or ensure network.lua is present',
              file=sys.stderr)
        return []
    try:
        cur = conn.cursor()
        # retail item IDs are below ~32768; custom/server-only items above
        cur.execute("""
            SELECT DISTINCT ie.itemId, ib.name
            FROM item_equipment ie
            JOIN item_basic ib ON ib.itemId = ie.itemId
            WHERE ie.ilevel >= %s
              AND ie.itemId BETWEEN 1 AND 32767
            ORDER BY ib.name
        """, (ilevel_min,))
        rows = cur.fetchall()
        cur.close()
        return [(int(row[0]), str(row[1])) for row in rows]
    finally:
        conn.close()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--ilevel-min', type=int, default=109,
                    help='Minimum item level to include (default 109)')
    ap.add_argument('--item-ids',
                    help='Comma-separated explicit item IDs to fetch')
    ap.add_argument('--refresh-days', type=int, default=30,
                    help='Re-fetch entries older than N days (default 30)')
    ap.add_argument('--max-items', type=int, default=0,
                    help='Stop after fetching N new items (0 = unlimited)')
    ap.add_argument('--dry-run', action='store_true',
                    help='List what would be fetched, then exit')
    args = ap.parse_args()

    cache = load_cache()

    if args.item_ids:
        items: list[tuple[int, str]] = [
            (int(x.strip()), '') for x in args.item_ids.split(',')
        ]
    else:
        items = get_items_from_db(args.ilevel_min)

    if not items:
        print('No items found — exiting.')
        return

    to_fetch = [
        (iid, nm) for iid, nm in items
        if str(iid) not in cache or is_stale(cache[str(iid)], args.refresh_days)
    ]

    print(f'{len(items)} items in scope; {len(cache)} cached; '
          f'{len(to_fetch)} need fetching')

    if args.dry_run:
        for iid, nm in to_fetch[:30]:
            age = ''
            if str(iid) in cache:
                age = f' (stale: {cache[str(iid)].get("fetched_at","?")[:10]})'
            print(f'  {iid:>6}  {nm}{age}')
        if len(to_fetch) > 30:
            print(f'  ... and {len(to_fetch) - 30} more')
        return

    if args.max_items and len(to_fetch) > args.max_items:
        print(f'Capping at {args.max_items} items')
        to_fetch = to_fetch[:args.max_items]

    fetched = errors = not_found = 0

    for i, (item_id, known_name) in enumerate(to_fetch):
        label = f'[{i+1}/{len(to_fetch)}] {item_id} {known_name}'
        print(label + '...', end=' ', flush=True)

        html = fetch_html(item_id)

        ts = datetime.now(timezone.utc).isoformat()

        if html is None:
            print('not found')
            cache[str(item_id)] = {
                'fetched_at': ts, 'found': False,
                'name': known_name, 'stats': {},
            }
            not_found += 1
        else:
            name, stats = parse_item_page(html)
            display_name = name or known_name
            if not stats:
                print(f'PARSE ERROR (name={display_name!r})')
                errors += 1
                # still cache so we don't retry immediately
                cache[str(item_id)] = {
                    'fetched_at': ts, 'found': True,
                    'name': display_name, 'stats': {},
                }
            else:
                print(f'ok  ({len(stats)} stats)  {display_name}')
                cache[str(item_id)] = {
                    'fetched_at': ts, 'found': True,
                    'name': display_name, 'stats': stats,
                }
                fetched += 1

        if (i + 1) % SAVE_EVERY == 0:
            save_cache(cache)
            print(f'  [checkpoint: saved {i+1} processed]')

        if i < len(to_fetch) - 1:
            time.sleep(DELAY_SECONDS)

    save_cache(cache)
    print(f'\nDone: {fetched} fetched, {not_found} not on FFXIAH, {errors} parse errors')
    print(f'Cache: {CACHE_FILE}')


if __name__ == '__main__':
    main()
