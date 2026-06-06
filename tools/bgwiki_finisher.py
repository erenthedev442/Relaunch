"""Final pass to recover the remaining 242 uncovered items.

Three phases:
  1. Smart URL retry with proper encoding (apostrophe, plus, hyphen)
     — fixes the +4 reforge bug where my earlier retry script double-encoded
     %27 -> %2527. Recovers possessive items like Academic's_Bracers_+4.
  2. Manual Mythic disambiguation overrides for the 15 stragglers.
  3. Tag Tokko/Voluspa/ammo as naked-by-design.

Run order:
  python tools/bgwiki_finisher.py
  python tools/gen_naked_item_stats.py
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
import urllib.error
from pathlib import Path

REPO = Path(r'D:\server')
UA = 'Mozilla/5.0 (compatible; LSB-DataSync/3)'
DELAY = 1.5

STATS_RE = re.compile(r'<td class="item-info-body"[^>]*>([^<]+)(?:<|</td>)')


def fetch(url: str) -> tuple[int, str | None]:
    """Return (status, stat_text or None). Status 0 on network error."""
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


def build_url(slug_parts: list[str]) -> str:
    """Build a BG-Wiki URL from already-cased slug parts.
    Encoding is done ONCE, manually — no urllib.parse.quote (which double-
    encodes anything already containing %27 or %2B)."""
    raw = '_'.join(slug_parts)
    # Manual encoding of special chars
    encoded = (raw
               .replace("'", '%27')
               .replace('+', '%2B')
               .replace(' ', '_'))
    return f'https://www.bg-wiki.com/ffxi/{encoded}'


def url_variants(name: str) -> list[str]:
    """Smart URL variants. Tries:
      1. Plain title-case
      2. Possessive (if first word ends in 's', insert apostrophe)
      3. All-caps middle word (for things like "no-kami")
      4. Hyphenated variants for compound words
    """
    parts = name.split('_')
    titled = [p.capitalize() if p and not p.startswith('+') else p for p in parts]
    out: list[list[str]] = []

    # 1. Plain title
    out.append(titled[:])

    # 2. Possessive on first word: "academics" -> "Academic's"
    if titled and len(titled[0]) >= 5 and titled[0].endswith('s'):
        out.append([titled[0][:-1] + "'s"] + titled[1:])

    # 3. Hyphenated compound (e.g., kusanagi-no-tsurugi already has hyphens
    #    in the LSB name — those need preserving in URL)
    # Already handled by underscore split, but check if name has hyphens
    # that should become _ in URL.
    if '-' in name:
        # Try the name with hyphens preserved instead of split
        out.append([name.replace('_', '_')])

    # 4. Try with "the_" prefix (some items like "Idris" might be "The_Idris" etc.)
    # Skip for now — rare case.

    return [build_url(parts) for parts in out]


# ---------------------------------------------------------------------------
# Phase 2: Manual Mythic disambiguation overrides
# These are hand-curated based on knowledge of BG-Wiki naming conventions.
# Each entry maps itemId -> direct URL.
# ---------------------------------------------------------------------------

MYTHIC_OVERRIDES = {
    # kusanagi-no-tsurugi: hyphenated Japanese name, capitalized differently
    21983: 'https://www.bg-wiki.com/ffxi/Kusanagi-no-Tsurugi',
    21984: 'https://www.bg-wiki.com/ffxi/Kusanagi-no-Tsurugi_(Level_119)',
    21985: 'https://www.bg-wiki.com/ffxi/Kusanagi-no-Tsurugi_(Level_119_II)',
    21986: 'https://www.bg-wiki.com/ffxi/Kusanagi-no-Tsurugi_(Level_119_III)',

    # mutsu-no-kami_yoshiyuki: hyphenated + space in LSB
    21953: 'https://www.bg-wiki.com/ffxi/Mutsu-no-Kami_Yoshiyuki',
    21981: 'https://www.bg-wiki.com/ffxi/Mutsu-no-Kami_Yoshiyuki_(Level_119)',

    # lexeme_blade: 3 itemIds, possibly Aftermath states
    # 20750/20751/20752 might be base/AM1/AM2 — try base only
    20750: 'https://www.bg-wiki.com/ffxi/Lexeme_Blade',

    # duban: 4 itemIds 26492-26495, possibly upgrade variants
    26492: 'https://www.bg-wiki.com/ffxi/Duban',
    26493: 'https://www.bg-wiki.com/ffxi/Duban_+1',
    26494: 'https://www.bg-wiki.com/ffxi/Duban_+2',
    26495: 'https://www.bg-wiki.com/ffxi/Duban_+3',

    # hebos_spear: 2 itemIds
    21885: 'https://www.bg-wiki.com/ffxi/Hebo%27s_Spear',
    21893: 'https://www.bg-wiki.com/ffxi/Hebo%27s_Spear_(Level_119)',

    # pandits_staff
    22101: 'https://www.bg-wiki.com/ffxi/Pandit%27s_Staff',
    22168: 'https://www.bg-wiki.com/ffxi/Pandit%27s_Staff_(Level_119)',

    # save_the_queen_iii / onion_sword_iii — these are joke/special items
    # already handled in audit's unresolved list. Skip.

    # brave_blade_iii / mutsu / etc. — try standard tier URLs
    21676: 'https://www.bg-wiki.com/ffxi/Brave_Blade',
    21677: 'https://www.bg-wiki.com/ffxi/Brave_Blade_(Level_119)',

    # artemiss_bow_+2
    22145: 'https://www.bg-wiki.com/ffxi/Artemis%27s_Bow_%2B2',
    22169: 'https://www.bg-wiki.com/ffxi/Artemis%27s_Bow_%2B2_(Level_119)',

    # maxixi +4 sets — these are female-only Reforge SCH/RUN(?) sets that don't have item_weapon rows (skipped by mythic resolver)
    # Try regular possessive URL
    23913: 'https://www.bg-wiki.com/ffxi/Maxixi_Tiara_%2B4',
    23914: 'https://www.bg-wiki.com/ffxi/Maxixi_Tiara_%2B4',  # dupe
    23958: 'https://www.bg-wiki.com/ffxi/Maxixi_Casaque_%2B4',
    23959: 'https://www.bg-wiki.com/ffxi/Maxixi_Casaque_%2B4',
    24003: 'https://www.bg-wiki.com/ffxi/Maxixi_Bangles_%2B4',
    24004: 'https://www.bg-wiki.com/ffxi/Maxixi_Bangles_%2B4',
    24048: 'https://www.bg-wiki.com/ffxi/Maxixi_Tights_%2B4',
    24049: 'https://www.bg-wiki.com/ffxi/Maxixi_Tights_%2B4',
    24093: 'https://www.bg-wiki.com/ffxi/Maxixi_Toe_Shoes_%2B4',
    24094: 'https://www.bg-wiki.com/ffxi/Maxixi_Toe_Shoes_%2B4',
}


# ---------------------------------------------------------------------------
# Phase 3: Naked-by-design tags. These items intentionally have no item_mods.
# Add to unresolved.json with the standard reason.
# ---------------------------------------------------------------------------

NAKED_BY_DESIGN_SUBSTRINGS = [
    'eminent_arrow', 'eminent_bolt', 'eminent_bullet',
    'rakaznar_arrow', 'rakaznar_bolt', 'rakaznar_bullet',
    'damascus_bolt', 'damascus_bullet',
    'midrium_bolt', 'midrium_bullet',
    'voluspa_arrow', 'voluspa_bolt', 'voluspa_bullet',
]


def main() -> int:
    naked = json.loads((REPO / 'tools' / 'naked_ilvl_items.json').read_text(encoding='utf-8'))
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    audit = json.loads((REPO / 'tools' / 'gear_stat_audit.json').read_text(encoding='utf-8'))
    existing_audit_ids = {item['itemId'] for item in audit['naked_items']}

    # What's currently uncovered?
    sql_text = (REPO / 'sql' / 'zz_custom_naked_item_mods.sql').read_text(encoding='utf-8')
    sql_ids = set(int(m.group(1)) for m in re.finditer(r'INSERT INTO `item_mods` VALUES \((\d+),', sql_text))
    naked_ids = set(naked['itemIds'])
    uncovered_ids = naked_ids - sql_ids
    print(f'Starting with {len(uncovered_ids)} uncovered items')

    # ---- PHASE 1: Smart retry ----
    print('\nPHASE 1: smart-URL retry')
    p1_recovered = 0
    p1_failed = 0
    items_by_id = {it['itemId']: it for it in naked['items']}
    for iid in sorted(uncovered_ids):
        item = items_by_id.get(iid)
        if not item:
            continue
        name = item['name']

        # Skip mythic overrides (handled in phase 2)
        if iid in MYTHIC_OVERRIDES:
            continue
        # Skip naked-by-design (phase 3)
        if any(s in name for s in NAKED_BY_DESIGN_SUBSTRINGS):
            continue

        stats = None
        winning_url = None
        for url in url_variants(name):
            status, stats = fetch(url)
            if stats:
                winning_url = url
                break
            time.sleep(0.3)

        if stats:
            cache[str(iid)] = {'name': name.replace('_', ' ').title(),
                               'url': winning_url, 'stats': stats}
            if iid not in existing_audit_ids:
                audit['naked_items'].append({
                    'itemId': iid, 'shortName': name,
                    'source': 'phase1_smart_retry',
                    'context': 'BG-Wiki recovered via smart URL', 'modCount': 0, 'latentCount': 0,
                })
                existing_audit_ids.add(iid)
            p1_recovered += 1
        else:
            p1_failed += 1
        time.sleep(DELAY)

    print(f'  Phase 1: {p1_recovered} recovered, {p1_failed} failed')

    # ---- PHASE 2: Mythic overrides ----
    print('\nPHASE 2: mythic overrides')
    p2_recovered = 0
    p2_failed = 0
    for iid, url in MYTHIC_OVERRIDES.items():
        if iid not in uncovered_ids:
            continue
        status, stats = fetch(url)
        if stats:
            item = items_by_id.get(iid, {})
            name = item.get('name', f'item_{iid}')
            cache[str(iid)] = {'name': name.replace('_', ' ').title(), 'url': url, 'stats': stats}
            if iid not in existing_audit_ids:
                audit['naked_items'].append({
                    'itemId': iid, 'shortName': name,
                    'source': 'phase2_mythic_override',
                    'context': f'Override URL {url}', 'modCount': 0, 'latentCount': 0,
                })
                existing_audit_ids.add(iid)
            p2_recovered += 1
        else:
            p2_failed += 1
            print(f'    {iid} {url} - FAILED')
        time.sleep(DELAY)
    print(f'  Phase 2: {p2_recovered} recovered, {p2_failed} failed')

    # ---- PHASE 3: Tag naked-by-design ----
    print('\nPHASE 3: tag naked-by-design')
    unresolved_path = REPO / 'tools' / 'naked_items_unresolved.json'
    unresolved = json.loads(unresolved_path.read_text(encoding='utf-8'))
    unresolved_ids = {e['itemId'] for e in unresolved}
    p3_tagged = 0
    for iid in uncovered_ids:
        item = items_by_id.get(iid)
        if not item:
            continue
        if any(s in item['name'] for s in NAKED_BY_DESIGN_SUBSTRINGS):
            if iid not in unresolved_ids:
                unresolved.append({
                    'itemId': iid, 'shortName': item['name'],
                    'context': f'Ammo / consumable - naked by design',
                    'reason': 'Ammo items have no item_mods by FFXI convention',
                    'bgwiki': '',
                })
                unresolved_ids.add(iid)
                p3_tagged += 1
    print(f'  Phase 3: {p3_tagged} tagged naked-by-design')

    # Save everything
    (REPO / 'tools' / 'bgwiki_stats_cache.json').write_text(json.dumps(cache, indent=2), encoding='utf-8')
    (REPO / 'tools' / 'gear_stat_audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')
    unresolved_path.write_text(json.dumps(unresolved, indent=2), encoding='utf-8')

    print(f'\nDONE: {p1_recovered + p2_recovered} new BG-Wiki entries, {p3_tagged} naked-by-design tagged')
    print('Run: python tools/gen_naked_item_stats.py')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
