"""Builds a Lua-ready table of all +4 reforge sets grouped by job + slot,
sourced from bgwiki_stats_cache.json. Each piece gets a short 2-line stat
summary suitable for the Infamy Vendor preview menu (which has limited
width per line in customMenu)."""
from __future__ import annotations

import json
import re
from pathlib import Path
from collections import defaultdict

REPO = Path(r'D:\server')

# Reforge set name → primary job (the most commonly-cited owner of that set).
# Most sets are tied to one job; the few exceptions (Atrophy=RDM/SMN, Foire=PUP)
# I've assigned to the job most likely to play in modern endgame.
SET_TO_JOB = {
    # Modern Empyrean +4 sets (one per job is canonical)
    'Academics':    'SCH',
    'Agoge':        'WAR',
    'Anchorites':   'MNK',
    'Ankusa':       'BST',
    'Arcadian':     'RNG',
    'Archmages':    'BLM',
    'Assimilators': 'BLU',
    'Atrophy':      'RDM',
    'Bagua':        'GEO',
    'Bihu':         'BRD',
    'Brioso':       'BRD',
    'Caballarius':  'PLD',
    'Convokers':    'SMN',
    'Fallens':      'DRK',
    'Foire':        'PUP',
    'Futhark':      'RUN',
    'Geomancy':     'GEO',
    'Hachiya':      'NIN',
    'Hashishin':    'BLU',
    'Hizamaru':     'MNK',
    'Iuitl':        'RNG',
    'Jhakri':       'BLM',
    'Kendatsuba':   'NIN',
    'Lanun':        'COR',
    'Laksamana':    'COR',
    'Laksamanas':   'COR',
    'Maxixi':       'DNC',
    'maxixi':       'DNC',
    'Maculele':     'DNC',
    'Meghanada':    'THF',
    'Mummu':        'THF',
    'Mpaca':        'MNK',
    'Onca':         'BLU',
    'Pummeler':     'WAR',
    'Pummelers':    'WAR',
    'Pillager':     'THF',
    'Pillagers':    'THF',
    'Plunderers':   'THF',
    'Piety':        'WHM',
    'Peltast':      'DRG',
    'Peltasts':     'DRG',
    'Rawhide':      'RNG',
    'Runeist':      'RUN',
    'Runeists':     'RUN',
    'Sakpata':      'WAR',
    'Sakpatas':     'WAR',
    'Sakonji':      'SAM',
    'Sukenobu':     'SAM',
    'Tali':         'PUP',
    'Taliah':       'PUP',
    'Theophany':    'WHM',
    'theophany':    'WHM',
    'Theo':         'WHM',
    'Vishap':       'DRG',
    'Vrikodara':    'MNK',
    'Wakido':       'SAM',
    'Wicce':        'SCH',
    'Yorium':       'PLD',
    # Older / Magian / alternate AF+3-style sets (also use +4)
    'Glyphic':      'SMN',  # SMN AF3+4
    'Hesychasts':   'MNK',  # MNK relic +4
    'Horos':        'DNC',  # DNC relic +4
    'Ignominy':     'DRK',  # DRK relic +4
    'Luhlaza':      'BLU',  # BLU AF3+4
    'luhlaza':      'BLU',
    'Mochizuki':    'NIN',  # NIN relic +4
    'Orion':        'RNG',  # RNG AF3+4
    'Pedagogy':     'SCH',  # SCH AF3+4
    'Pitre':        'PUP',  # PUP AF3+4
    'Pteroslaver':  'DRG',  # DRG AF3+4
    'Reverence':    'PLD',  # PLD relic +4
    'Spaekonas':    'BLM',  # BLM AF3+4
    'Totemic':      'BST',  # BST AF3+4
    'Vitiation':    'RDM',  # RDM AF3+4
    # "Finger Gauntlets" oddballs — Empyrean +4 reforge of relic hands
    'Fallens Finger':     'DRK',
    'Ignominy Finger':    'DRK',
    'Pteroslaver Finger': 'DRG',
    'Vishap Finger':      'DRG',
}

# Slot mapping for sorting (head=1, body=2, hands=3, legs=4, feet=5).
SLOT_WORDS = {
    'head':  ['hat','cap','helm','crown','beret','headband','jinpachi','headgear','headpiece',
              'mask','keffiyeh','chapeau','coronet','coronal','mortarboard','petasos',
              'galero','roundlet','horn','burgeonet','bandeau','taj','kabuto','hatsuburi',
              'armet','tricorne','tiara','barbut','bonnet'],
    'body':  ['jerkin','doublet','briault','tunic','coat','khazagand','vest','mail','plate',
              'suit','robe','cyclas','frock','jupon','manteel','jubbah','justaucorps','jackcoat',
              'tabard','tobe','gown','cuirass','surcoat','lorica','korazin','bliaut','domaru',
              'chainmail','frac','casaque','breastplate','haubert','dalmatica'],
    'hands': ['gloves','cuffs','gages','mittens','gauntlets','bracers','grips',
              'gants','dastanas','mitons','mitaines','mufflers','bazubands',
              'mitts','kote','tekko','ocreae','vambraces','bangles','armlets'],
    'legs':  ['hose','trews','tights','slops','tonban','pantaloons','culottes','brais','trousers',
              'breeches','cuisses','flanchard','shalwar','churidars','cannions','spats',
              'pants','seraweels','bracca','hakama','brayettes','quijotes',
              'braccae','haidate'],
    'feet':  ['boots','clogs','greaves','crackows','gaiters','sune-ate','sollerets','pigaches',
              'sabots','babouches','sandals','slippers','calligae','loafers','charuqs',
              'socks','gambadoes','duckbills','kyahan','bottes','leggings','poulaines','shoes'],
}
SLOT_ORDER = {'head': 1, 'body': 2, 'hands': 3, 'legs': 4, 'feet': 5}


def detect_slot(name: str) -> str | None:
    n = name.lower().replace('+4', '').strip()
    last = n.split()[-1].strip()
    for slot, words in SLOT_WORDS.items():
        for w in words:
            if last == w or last.endswith('-' + w):
                return slot
    return None


def detect_set(name: str) -> str:
    parts = name.replace('_+4', ' +4').split()
    # Strip trailing +4
    if parts[-1] == '+4':
        parts = parts[:-1]
    # The set is the first 1-2 tokens; everything after is slot+plurals
    base = parts[0]
    # If first token is a possessive-suggesting word + slot word at end, base is single
    if len(parts) >= 3 and parts[1] in {'Wing', 'Finger'}:
        base = ' '.join(parts[:2])
    # Normalize case: BG-Wiki cache has a few oddly lowercased entries
    # like "theophany pantaloons +4" — collapse to canonical capitalisation
    base = base[0].upper() + base[1:] if base else base
    return base


def shorten_stats(stats: str, maxlen: int = 90) -> list[str]:
    """Return up to two ≤90-char lines summarizing the stats."""
    s = stats.strip()
    # Tokenize on commas / semicolons / double-spaces
    parts = [p.strip() for p in re.split(r'[,;]\s*|  +', s) if p.strip()]
    # Heuristic: pick the most "valuable" stats first
    priority = ['DMG:', 'DEF:', 'HP', 'MP', 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR',
                'Accuracy', 'Attack', '"Magic Atk', 'Magic Acc', '"Refresh"', '"Regen"',
                '"Store TP"', '"Dbl. Atk', '"Triple Atk', 'Haste', '"Conserve MP', 'Fast Cast']
    def rank(p: str) -> int:
        for i, k in enumerate(priority):
            if k.lower() in p.lower():
                return i
        return 999
    parts.sort(key=rank)
    # Build lines under maxlen
    lines: list[str] = []
    cur = ''
    for p in parts:
        candidate = (cur + ', ' + p) if cur else p
        if len(candidate) > maxlen:
            if cur:
                lines.append(cur)
            cur = p
            if len(lines) >= 1:
                # We've hit two lines worth — stop
                break
        else:
            cur = candidate
    if cur and len(lines) < 2:
        lines.append(cur)
    # Truncate any over-long single token
    return [l[:maxlen] for l in lines][:2]


def main() -> int:
    cache = json.loads((REPO / 'tools' / 'bgwiki_stats_cache.json').read_text(encoding='utf-8'))
    plus4: dict[int, dict] = {}
    for iid, entry in cache.items():
        name = entry.get('name', '')
        if '+4' in name:
            plus4[int(iid)] = entry

    sets: dict[str, dict[str, tuple[int, str, list[str]]]] = defaultdict(dict)
    unknown_slot: list[tuple[int, str]] = []
    for iid, entry in plus4.items():
        name = entry['name']
        slot = detect_slot(name)
        if not slot:
            unknown_slot.append((iid, name))
            continue
        setname = detect_set(name)
        statlines = shorten_stats(entry.get('stats', ''))
        sets[setname][slot] = (iid, name, statlines)

    # Group sets by job
    by_job: dict[str, list[str]] = defaultdict(list)
    unknown_set: list[str] = []
    for setname in sorted(sets):
        job = SET_TO_JOB.get(setname)
        if job:
            by_job[job].append(setname)
        else:
            unknown_set.append(setname)

    # Print Lua-ready output
    out_lines = ['-- AUTO-GENERATED by tools/build_infamy_plus4_catalog.py',
                 '-- Source: tools/bgwiki_stats_cache.json',
                 '-- Edit the SET_TO_JOB map in the Python script, not this file.',
                 '',
                 'catalog.plus4Sets =',
                 '{']
    for job in sorted(by_job):
        out_lines.append(f'    -- {job}')
        out_lines.append(f'    [\'{job}\'] = {{')
        for setname in sorted(by_job[job]):
            slot_entries = sets[setname]
            out_lines.append(f'        {{ set = \'{setname}\', pieces = {{')
            for slot in ['head', 'body', 'hands', 'legs', 'feet']:
                if slot in slot_entries:
                    iid, name, statlines = slot_entries[slot]
                    stat_lua = ', '.join(f'\'{l.replace("\'", "\\\\\'")}\'' for l in statlines)
                    if not stat_lua:
                        stat_lua = '\'(retail stats from BG-Wiki)\''
                    out_lines.append(f'            [\'{slot}\'] = {{ id = {iid}, name = \'{name}\', stats = {{ {stat_lua} }} }},')
            out_lines.append('        } },')
        out_lines.append('    },')
    out_lines.append('}')
    out_lines.append('')

    out_path = REPO / 'tools' / '_plus4_catalog.lua'
    out_path.write_text('\n'.join(out_lines), encoding='utf-8')
    print(f'Wrote {out_path} ({len(out_lines)} lines)')
    print(f'Jobs covered: {sorted(by_job.keys())}')
    print(f'Sets per job:')
    for job in sorted(by_job):
        print(f'  {job}: {[s for s in by_job[job]]}')

    # =====================================================================
    # LEAK AUDIT: +4 items are an Infamy Vendor exclusive. Any +4 item ID
    # appearing in armor_catalog.lua, gear_progression_catalog.lua,
    # reforge_catalog.lua, or hunting_league_catalog.lua is a regression
    # of the "+4 lives only on the dungeon vendor" design rule (see the
    # comment block in tools/score_armor.py + tools/score_weapons.py near
    # the explicit `_+4` exclusion filter).
    # Print-only -- no auto-fix. If the warning fires, hand-edit the
    # offending catalog to remove the leaked entry, or investigate why the
    # scoring tools' +4 filter didn't catch it.
    # =====================================================================
    import re as _re
    plus4_ids = set()
    with (REPO / 'sql' / 'item_basic.sql').open(encoding='utf-8', errors='replace') as f:
        for line in f:
            m = _re.search(r"VALUES \((\d+),\d+,'([^']+)','([^']+)',", line)
            if m and m.group(2).endswith('_+4'):
                plus4_ids.add(int(m.group(1)))

    LEAK_CATALOGS = [
        'armor_catalog.lua',
        'gear_progression_catalog.lua',
        'reforge_catalog.lua',
        'hunting_league_catalog.lua',
    ]
    leaks = {}
    for cat_name in LEAK_CATALOGS:
        cat_path = REPO / 'modules' / 'custom' / 'lua' / cat_name
        if not cat_path.exists():
            continue
        cat_text = cat_path.read_text(encoding='utf-8', errors='replace')
        cat_leaks = []
        for m in _re.finditer(r'id\s*=\s*(\d+)', cat_text):
            iid = int(m.group(1))
            if iid in plus4_ids:
                line_no = cat_text[:m.start()].count('\n') + 1
                cat_leaks.append((line_no, iid))
        if cat_leaks:
            leaks[cat_name] = cat_leaks

    print()
    if leaks:
        total = sum(len(v) for v in leaks.values())
        print(f'LEAK WARNING: {total} +4 item(s) found in non-dungeon catalogs.')
        print('The "+4 only on Infamy Vendor" rule is being violated. Hand-edit')
        print('to remove these entries, or relax the filter intentionally:')
        for cat_name, cat_leaks in leaks.items():
            print(f'  {cat_name}:')
            for line_no, iid in cat_leaks:
                print(f'    line {line_no}: id {iid}')
    else:
        print(f'LEAK CHECK OK: zero +4 items in {len(LEAK_CATALOGS)} non-dungeon catalogs.')
    if unknown_set:
        print()
        print(f'WARNING: {len(unknown_set)} sets had no job mapping (add to SET_TO_JOB):')
        for s in unknown_set:
            print(f'  {s}: {[(iid, n) for iid, n, _ in sets[s].values()][:1]}')
    if unknown_slot:
        print()
        print(f'WARNING: {len(unknown_slot)} items had unrecognized slot:')
        for iid, name in unknown_slot[:20]:
            print(f'  {iid}: {name}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
