import os, re, sys
from pathlib import Path
ROOT = Path(r"C:\server")
os.environ["LEGENDARY_LIVE_ROOT"] = str(ROOT); sys.path.insert(0, str(ROOT))
from tools.docgen import _item_sources as S
from tools.docgen.generators import gear_finder as GF

def read(rel):
    p = ROOT / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

# equippable gear ids + names
equip, names = set(), {}
for ln in read("sql/item_equipment.sql").splitlines():
    m = re.match(r"^INSERT INTO `item_equipment` VALUES \((\d+),", ln)
    if m: equip.add(int(m.group(1)))
for ln in read("sql/item_basic.sql").splitlines():
    m = re.match(r"^INSERT INTO `item_basic` VALUES \((\d+),\d+,'([^']*)'", ln)
    if m: names[int(m.group(1))] = m.group(2)

sources = {}
def add(iid, label):
    if iid in equip:
        sources.setdefault(iid, set()).add(label)

# an item entry: a brace opening with id=N ... cost= (stop at cost so a nested
# `stats = {...}` table in the same entry doesn't break the match).
ENTRY = re.compile(r"\{\s*[^{}]*\bid\s*=\s*(\d+)[^{}]*\bcost\s*=")
def vendor(rel, label, cut_marker=None):
    t = read(rel)
    if cut_marker:
        i = t.find(cut_marker)
        if i >= 0: t = t[:i]
    for m in ENTRY.finditer(t):
        add(int(m.group(1)), label)

vendor("modules/custom/lua/infamy_vendor_catalog.lua", "Infamy Vendor")
vendor("modules/custom/lua/accessory_catalog.lua",     "Medal Accessory NPC", cut_marker="-- INFAMY TIER")
vendor("modules/custom/lua/armor_catalog.lua",         "Medal Armor NPC",     cut_marker="-- INFAMY TIER")
vendor("modules/custom/lua/gear_progression_catalog.lua", "Gear Progression Weapons", cut_marker="catalog.infamy")
vendor("modules/custom/lua/hunting_league_catalog.lua", "HL Sortie Earrings")
for iid in GF._reforge_ids(ROOT):      add(iid, "Reforge")
for iid in GF._prime_armory_ids(ROOT): add(iid, "Prime Armory")
for iid in GF._shop_ids(ROOT):         add(iid, "!shop")

# custom scripted drop tables (each its own system)
for iid in S._htbf_drops(ROOT):            add(iid, "HTBF")
for iid in S._voidwatch_drops(ROOT):       add(iid, "Voidwatch")
for iid in S._abyssea_su5_drops(ROOT):     add(iid, "Abyssea Su5")
for iid in S._catalyst_mob_drops(ROOT):    add(iid, "Catalyst mobs")
for iid in S._dungeon_augment_drops(ROOT): add(iid, "Augment Dungeon")
for iid in S._HL_TROPHY_DROPS:             add(iid, "HL Trophy")
for iid in S._SEAL_DROPS:                  add(iid, "GM Home seal")
db = S._drops(ROOT)
for iid in (db or {}): add(iid, "mob_droplist")

VEND = {"Infamy Vendor","Medal Accessory NPC","Medal Armor NPC","Gear Progression Weapons",
        "HL Sortie Earrings","Reforge","Prime Armory","!shop"}
DROPSYS = {"HTBF","Voidwatch","Abyssea Su5","Catalyst mobs","Augment Dungeon","HL Trophy","GM Home seal"}
CUSTOM = VEND | DROPSYS

dups = [(i, s) for i, s in sources.items() if (s & CUSTOM) and len(s) >= 2]
cat = {"A":[], "B":[], "C":[], "D":[]}
for iid, s in dups:
    nv, nd, inl = len(s & VEND), len(s & DROPSYS), "mob_droplist" in s
    if nv >= 2: cat["A"].append((iid, s))
    elif nv >= 1 and nd >= 1: cat["B"].append((iid, s))
    elif nv >= 1 and inl: cat["C"].append((iid, s))
    else: cat["D"].append((iid, s))

print(f"equippable {len(equip)} | sourced items {len(sources)} | DB drops {'ok' if db is not None else 'MISSING'}")
print(f"TOTAL VIOLATIONS: {len(dups)}")
for k, title in [("A","2+ CUSTOM VENDORS"),("B","custom vendor + custom DROP table"),
                 ("C","custom vendor + also drops (mob_droplist)"),("D","2+ drop tables / drop+droplist")]:
    print(f"\n=== CAT {k}: {title} -- {len(cat[k])} ===")
    for iid, s in sorted(cat[k]):
        print(f"  [{names.get(iid,'?')}] ({iid}): {' + '.join(sorted(s))}")
