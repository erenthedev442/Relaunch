"""Gap-fill item_mods for the +4 reforge line so the SERVER applies every stat
the client TOOLTIP shows.

The +4 items' mods were built from a parser that only captured plain "Stat+N"
formats and dropped the fancy ones (Magic Accuracy, "quoted" stats, "Ability:
effect", percent specials). This re-parses each item's authoritative stat
string from tools/bgwiki_stats_cache.json (keyed by server itemid, matches the
in-game tooltip) and emits INSERT IGNORE rows for every stat that maps to a
real engine mod.

INSERT IGNORE + a late-loading filename => only genuinely-missing mods are
added; existing (e.g. tier-scaled) values are kept untouched. Stats with no
engine mod (Wyvern HP, pet/luopan specials, most job-ability durations) and the
"Set:" bonuses are intentionally skipped and reported.

Run:  python tools/gen_plus4_displayed_mods.py
Reads: tools/bgwiki_stats_cache.json, plus4ids.txt (one itemid per line)
Writes: sql/zz_reforge_plus4_displayed_stats.sql
"""
from __future__ import annotations
import json, re
from pathlib import Path
from collections import Counter

REPO = Path(r'D:\server')

# stat name (normalized: quotes stripped, whitespace collapsed) -> (modId, scale)
# scale: stored value = displayed number * scale (sign preserved). Verified vs
# scripts/enum/mod.lua AND existing item_mods values (Haste 384 ×100; damage
# taken 160-164 ×100 negative; everything else stored as the raw number).
STAT_TO_MOD = {
    # attributes
    'DEF': (1, 1), 'HP': (2, 1), 'MP': (5, 1), 'STR': (8, 1), 'DEX': (9, 1),
    'VIT': (10, 1), 'AGI': (11, 1), 'INT': (12, 1), 'MND': (13, 1), 'CHR': (14, 1),
    # core offense / defense stats
    'Attack': (23, 1), 'Ranged Attack': (24, 1), 'Accuracy': (25, 1),
    'Ranged Accuracy': (26, 1), 'Enmity': (27, 1), 'Magic Atk. Bonus': (28, 1),
    'Magic Def. Bonus': (29, 1), 'Magic Accuracy': (30, 1), 'Magic Evasion': (31, 1),
    'Evasion': (68, 1), 'Store TP': (73, 1), 'Magic Damage': (311, 1),
    # multi-attack / crit / weaponskill
    'Double Attack': (288, 1), 'Triple Attack': (302, 1), 'Critical hit rate': (165, 1),
    'Critical hit damage': (421, 1), 'Weapon skill damage': (840, 1),
    'Skillchain Bonus': (174, 1), 'Dual Wield': (259, 1), 'Subtle Blow': (289, 1),
    'Zanshin': (306, 1), 'Daken': (911, 1), 'Fast Cast': (170, 1),
    'Conserve MP': (296, 1), 'Magic burst damage': (487, 1),
    # ranged
    'Snapshot': (365, 1), 'Rapid Shot': (359, 1),
    # recovery
    'Refresh': (369, 1), 'Regen': (370, 1), 'Cure potency': (374, 1),
    # haste (stored x100)
    'Haste': (384, 100),
    # damage taken (stored x100, value already carries the minus sign)
    'Damage taken': (160, 100), 'Physical damage taken': (161, 100),
    'Magic damage taken': (163, 100),
    # dragoon / dancer specials that DO have a mod
    'High Jump: Enmity reduction': (363, 1),
    'Waltz potency': (491, 1), 'Step accuracy': (403, 1),
    # combat skills
    'Throwing skill': (106, 1), 'Guarding skill': (107, 1), 'Shield skill': (109, 1),
    'Parrying skill': (110, 1),
    # magic skills
    'Divine magic skill': (111, 1), 'Healing magic skill': (112, 1),
    'Enhancing magic skill': (113, 1), 'Enfeebling magic skill': (114, 1),
    'Elemental magic skill': (115, 1), 'Dark magic skill': (116, 1),
    'Summoning magic skill': (117, 1), 'Ninjutsu skill': (118, 1),
    'Singing skill': (119, 1), 'String Instrument skill': (120, 1),
    'Wind Instrument skill': (121, 1), 'Blue magic skill': (122, 1),
    'Geomancy skill': (123, 1),
}


def norm(name: str) -> str:
    name = name.replace('"', '').replace('”', '').replace('“', '')
    return re.sub(r'\s+', ' ', name).strip()


def tokenize(s: str):
    pairs, last = [], 0
    for m in re.finditer(r'([+-]\d+)%?|:\s*(\d+)', s):
        name = norm(s[last:m.start()])
        raw = m.group(1) if m.group(1) else '+' + m.group(2)
        last = m.end()
        n = int(re.sub(r'[^0-9]', '', raw))
        if raw.startswith('-'):
            n = -n
        pairs.append((name, n))
    return pairs


def main():
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    ids = [l.strip() for l in (REPO / 'plus4ids.txt').read_text().splitlines() if l.strip()]

    rows = []           # (itemid, modId, value)
    skipped = Counter()
    mapped_stats = Counter()
    not_in_cache = []
    vishap = []
    for iid in ids:
        if iid not in cache:
            not_in_cache.append(iid)
            continue
        seen = set()
        for name, val in tokenize(cache[iid]['stats']):
            if not name:
                continue
            hit = STAT_TO_MOD.get(name)
            if not hit:
                skipped[name] += 1
                continue
            modId, scale = hit
            if modId in seen:        # avoid dup modId within one item
                continue
            seen.add(modId)
            value = val * scale
            if value == 0:
                continue
            rows.append((int(iid), modId, value))
            mapped_stats[name] += 1
            if iid == '24043':
                vishap.append((modId, value, name))

    # ---- write SQL ----
    out = REPO / 'sql' / 'zz_reforge_plus4_displayed_stats.sql'
    lines = [
        '-- ---------------------------------------------------------------------------',
        '-- zz_reforge_plus4_displayed_stats.sql   (generated by',
        '-- tools/gen_plus4_displayed_mods.py)',
        '--',
        '-- Gap-fills item_mods for the +4 reforge line so the SERVER applies the stats',
        "-- the client TOOLTIP shows. Source of truth: tools/bgwiki_stats_cache.json",
        '-- (keyed by server itemid, matches in-game). INSERT IGNORE + late filename =>',
        '-- only genuinely-missing mods are added; existing tier-scaled values are kept.',
        '--',
        '-- Skipped (no engine mod / needs a different system): Wyvern/pet/luopan stats,',
        "-- most job-ability durations, and \"Set:\" bonuses (handled separately).",
        '-- Reapply: re-run the generator. Reverse: delete this file + re-import item_mods.',
        '-- ---------------------------------------------------------------------------',
        '',
    ]
    # chunk into multi-row INSERTs (one per item for readability)
    by_item = {}
    for iid, mid, val in rows:
        by_item.setdefault(iid, []).append((mid, val))
    for iid in sorted(by_item):
        vals = ','.join(f'({iid},{mid},{val})' for mid, val in sorted(by_item[iid]))
        lines.append(f'INSERT IGNORE INTO `item_mods` VALUES {vals};')
    out.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    # ---- report ----
    print(f"items in cache: {len(by_item)} | not in cache (skipped): {len(not_in_cache)} {not_in_cache}")
    print(f"total INSERT IGNORE rows: {len(rows)}")
    print(f"distinct stats MAPPED: {len(mapped_stats)}")
    print(f"\n=== Vishap Brais +4 (24043) generated rows ===")
    for mid, val, name in sorted(vishap):
        print(f"   mod {mid:>4} = {val:<6} ({name})")
    print(f"\n=== top SKIPPED stats (no mapping) — {len(skipped)} distinct, {sum(skipped.values())} instances ===")
    for n, c in skipped.most_common(40):
        print(f"   {c:3}  {n}")
    print(f"\nwrote {out}")


if __name__ == '__main__':
    main()
