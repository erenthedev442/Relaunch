#!/usr/bin/env python3
"""
gen_windower_catalog.py
Generates addon data files for Windower and Ashita augment addons:

    tools/windower/augment_browser/data/{catalog,categories,sources}.lua
    tools/ashita/augment_browser/data/{catalog,categories,sources}.lua
    tools/windower/augment_trade/data/{catalog,categories}.lua
    tools/ashita/augment_trade/data/{catalog,categories}.lua

Sources:
    modules/custom/lua/augment_catalog.lua           (catalyst -> augment rows)
    modules/custom/lua/augment_affinity_catalog.lua  (category labels + affinity NMs)
    modules/custom/lua/catalyst_warp_table.lua       (item name + farm mob/zone)

This script is the single owner of those files -- never edit them manually.

Run from repo root: python tools/gen_windower_catalog.py
Re-run any time the catalog, affinity, or warp table changes.
"""
import re
import os

CATALOG_SRC  = 'modules/custom/lua/augment_catalog.lua'
AFFINITY_SRC = 'modules/custom/lua/augment_affinity_catalog.lua'
WARP_SRC     = 'modules/custom/lua/catalyst_warp_table.lua'
ADDON_DIRS = [
    'tools/windower/augment_browser/data',
    'tools/windower/augment_trade/data',
    'tools/ashita/augment_browser/data',
    'tools/ashita/augment_trade/data',
]
BROWSER_DIRS = [
    'tools/windower/augment_browser/data',
    'tools/ashita/augment_browser/data',
]

# ---- catalog rows ------------------------------------------------------------
with open(CATALOG_SRC, encoding='utf-8') as f:
    content = f.read()

# Match each entry:  [item_id] = { ... }   (fields in any order, no nested braces)
entry_re = re.compile(r'\[(\d+)\]\s*=\s*\{([^}]+)\}', re.DOTALL)

entries = []
for m in entry_re.finditer(content):
    body = m.group(2)
    cat   = re.search(r'\bcat\s*=\s*(\d+)',     body)
    tier  = re.search(r'\btier\s*=\s*(\d+)',    body)
    label = re.search(r"label\s*=\s*'([^']+)'", body)
    if not (cat and tier and label):
        continue
    base = re.search(r'\bbase\s*=\s*([0-9.]+)', body)
    mult = re.search(r'\bmult\s*=\s*([0-9.]+)', body)
    disp = re.search(r'\bdisp\s*=\s*([0-9.]+)', body)
    maxb = re.search(r'\bmaxBoost\s*=\s*(\d+)', body)
    flat = re.search(r'\bflatValue\s*=\s*(\d+)', body)
    tval = re.search(r'\btierValue\s*=\s*(\d+)', body)
    entries.append({
        'id':    int(m.group(1)),
        'cat':   int(cat.group(1)),
        'tier':  int(tier.group(1)),
        'label': label.group(1),
        'base':  float(base.group(1)) if base else 1,
        'mult':  float(mult.group(1)) if mult else 1,
        'disp':  float(disp.group(1)) if disp else 1,
        'maxBoost': int(maxb.group(1)) if maxb else None,
        'flatValue': int(flat.group(1)) if flat else None,
        'tierValue': int(tval.group(1)) if tval else None,
    })

entries.sort(key=lambda e: (e['tier'], e['cat'], e['label']))

# ---- category metadata (labels + affinity NM per cat) -------------------------
with open(AFFINITY_SRC, encoding='utf-8') as f:
    aff = f.read()

cat_rows = []
aff_re = re.compile(
    r"\{\s*cat\s*=\s*(\d+)\s*,\s*bit\s*=\s*\d+\s*,\s*label\s*=\s*'([^']*)'\s*,\s*nm\s*=\s*'([^']*)'")
for m in aff_re.finditer(aff):
    cat_rows.append({
        'cat':   int(m.group(1)),
        'label': m.group(2),
        'nm':    m.group(3).replace('_', ' '),
    })
cat_rows.sort(key=lambda r: r['cat'])

if not entries or not cat_rows:
    raise SystemExit('parse failure: no catalog entries or no categories -- aborting, files unchanged')

bad_cats = sorted({e['cat'] for e in entries} - {r['cat'] for r in cat_rows})
if bad_cats:
    raise SystemExit(f'catalog rows reference unknown categories {bad_cats} -- fix the sources first')

# ---- farm sources (item name + mapped mobs / zones) --------------------------
def lua_unescape(s):
    return s.replace("\\'", "'").replace("\\\\", "\\")

sources = {}
if os.path.exists(WARP_SRC):
    with open(WARP_SRC, encoding='utf-8') as f:
        warp = f.read()
    for m in re.finditer(r'\[(\d+)\]\s*=\s*\{([^}]+)\}', warp):
        iid = int(m.group(1))
        body = m.group(2)
        item = re.search(r"\bitem\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        mob = re.search(r"\bmob\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        zone = re.search(r"\bzoneName\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        lvl = re.search(r'\blvl\s*=\s*(\d+)', body)
        rate = re.search(r'\brate\s*=\s*(\d+)', body)
        alt_mob = re.search(r"\baltMob\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        alt_zone = re.search(r"\baltZone\s*=\s*'((?:[^'\\]|\\.)*)'", body)
        mobs = []
        if mob:
            mobs.append({
                'name': lua_unescape(mob.group(1)),
                'zone': lua_unescape(zone.group(1)) if zone else '',
                'lvl': int(lvl.group(1)) if lvl else 0,
            })
        if alt_mob:
            mobs.append({
                'name': lua_unescape(alt_mob.group(1)),
                'zone': lua_unescape(alt_zone.group(1)) if alt_zone else '',
                'lvl': 0,
            })
        sources[iid] = {
            'item': lua_unescape(item.group(1)) if item else '',
            'rate': int(int(rate.group(1)) / 10) if rate else 10,
            'mobs': mobs,
        }

for e in entries:
    src = sources.get(e['id'])
    if src and src['item']:
        e['item'] = src['item']

# ---- write both addons ---------------------------------------------------------
def lua_str(s):
    return "'" + s.replace("'", "\\'") + "'"

catalog_lines = [
    '-- Auto-generated by tools/gen_windower_catalog.py -- do not edit manually.',
    '-- Source: modules/custom/lua/augment_catalog.lua',
    'return {',
]
def lua_num(n):
    if float(n) == int(n):
        return str(int(n))
    return f'{n:g}'

for e in entries:
    extra = f", base = {lua_num(e['base'])}, mult = {lua_num(e['mult'])}, disp = {lua_num(e['disp'])}"
    if e.get('item'):
        extra += f", item = {lua_str(e['item'])}"
    if e['maxBoost'] is not None:
        extra += f", maxBoost = {e['maxBoost']}"
    if e['flatValue'] is not None:
        extra += f", flatValue = {e['flatValue']}"
    if e['tierValue'] is not None:
        extra += f", tierValue = {e['tierValue']}"
    catalog_lines.append(
        f"    [{e['id']:5}] = {{ cat = {e['cat']:2}, tier = {e['tier']}, label = {lua_str(e['label'])}{extra} }},")
catalog_lines.append('}')
catalog_text = '\n'.join(catalog_lines) + '\n'

cat_lines = [
    '-- Auto-generated by tools/gen_windower_catalog.py -- do not edit manually.',
    '-- Source: modules/custom/lua/augment_affinity_catalog.lua',
    '-- One row per augment category: display name + the affinity NM that unlocks it.',
    'return {',
]
for r in cat_rows:
    cat_lines.append(
        f"    [{r['cat']:2}] = {{ name = {lua_str(r['label'])}, nm = {lua_str(r['nm'])} }},")
cat_lines.append('}')
cat_text = '\n'.join(cat_lines) + '\n'

src_lines = [
    '-- Auto-generated by tools/gen_windower_catalog.py -- do not edit manually.',
    '-- Source: modules/custom/lua/catalyst_warp_table.lua',
    '-- Farm list for Augment Browser. rate is percent on the mapped mob.',
    'return {',
]
for iid in sorted(sources):
    s = sources[iid]
    mob_bits = []
    for mob in s['mobs']:
        mob_bits.append(
            f"{{ name = {lua_str(mob['name'])}, zone = {lua_str(mob['zone'])}, lvl = {mob['lvl']} }}")
    mobs_lua = ', '.join(mob_bits)
    src_lines.append(
        f"    [{iid:5}] = {{ item = {lua_str(s['item'])}, rate = {s['rate']}, mobs = {{ {mobs_lua} }} }},")
src_lines.append('}')
src_text = '\n'.join(src_lines) + '\n'

for d in ADDON_DIRS:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'catalog.lua'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(catalog_text)
    with open(os.path.join(d, 'categories.lua'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(cat_text)
    print(f'{d}: {len(entries)} catalog entries, {len(cat_rows)} categories')

for d in BROWSER_DIRS:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'sources.lua'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(src_text)
    print(f'{d}: {len(sources)} farm sources')
