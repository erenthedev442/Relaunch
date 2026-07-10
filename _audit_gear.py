import os, re, io, sys
from pathlib import Path
ROOT = Path(r"C:\server")
os.environ["LEGENDARY_LIVE_ROOT"] = str(ROOT); sys.path.insert(0, str(ROOT))
from tools.docgen import _item_sources as S

def read(rel):
    p = ROOT / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

# --- equippable gear ids (only audit real gear, not mats/currency/consumables) ---
equip = set()
for ln in read("sql/item_equipment.sql").splitlines():
    m = re.match(r"^INSERT INTO `item_equipment` VALUES \((\d+),", ln)
    if m: equip.add(int(m.group(1)))
# names for output
names = {}
for ln in read("sql/item_basic.sql").splitlines():
    m = re.match(r"^INSERT INTO `item_basic` VALUES \((\d+),\d+,'([^']*)'", ln)
    if m: names[int(m.group(1))] = m.group(2)

sources = {}  # item id -> set of source labels
def add(iid, label):
    if iid in equip:
        sources.setdefault(iid, set()).add(label)

# --- VENDORS (parse each catalog for equippable item ids) ---
def vendor_ids(rel, label, scope_re=None):
    t = read(rel)
    if scope_re:
        m = re.search(scope_re, t, re.DOTALL)
        t = m.group(0) if m else ""
    for m in re.finditer(r"\{\s*[^{}]*\bid\s*=\s*(\d+)[^{}]*\bcost\s*=", t):
        add(int(m.group(1)), label)

vendor_ids("modules/custom/lua/infamy_vendor_catalog.lua", "Infamy Vendor")
# accessory/armor catalogs carry a `catalog.infamy` STAGING tier ("Not sold by the NPC --
# promoted to the Infamy Vendor"). Only bronze/silver/gold are actually sold, so cut the
# staging section off before parsing so it isn't double-counted as a Medal-NPC sale.
def sold_only(rel):
    t = read(rel); i = t.find("catalog.infamy")
    return t[:i] if i >= 0 else t
def vendor_ids_text(t, label):
    for m in re.finditer(r"\{\s*[^{}]*id\s*=\s*(\d+)[^{}]*cost\s*=", t):
        add(int(m.group(1)), label)
vendor_ids_text(sold_only("modules/custom/lua/accessory_catalog.lua"), "Medal Accessory NPC")
vendor_ids_text(sold_only("modules/custom/lua/armor_catalog.lua"),     "Medal Armor NPC")
# gear_progression: only bronze/silver/gold weapon tiers (skip the inert catalog.infamy export)
gp = read("modules/custom/lua/gear_progression_catalog.lua")
gp_tiers = gp[:gp.find("catalog.infamy")] if "catalog.infamy" in gp else gp
for m in re.finditer(r"\{\s*id\s*=\s*(\d+)[^{}]*\bcost\s*=", gp_tiers):
    add(int(m.group(1)), "Gear Progression Weapons")
# HL sortie earrings (Hunt Marks reward shop)
for m in re.finditer(r"\{\s*[^{}]*\bid\s*=\s*(\d+)[^{}]*\bcost\s*=", read("modules/custom/lua/hunting_league_catalog.lua")):
    add(int(m.group(1)), "HL Sortie Earrings")
# reuse gear_finder helpers for reforge / prime armory / !shop / su5
from tools.docgen.generators import gear_finder as GF
for iid in GF._reforge_ids(ROOT):       add(iid, "Reforge")
for iid in GF._prime_armory_ids(ROOT):  add(iid, "Prime Armory")
for iid in GF._shop_ids(ROOT):          add(iid, "!shop")

# --- CUSTOM SCRIPTED DROP TABLES (each is its own system) ---
for iid in S._htbf_drops(ROOT):            add(iid, "HTBF")
for iid in S._voidwatch_drops(ROOT):       add(iid, "Voidwatch")
for iid in S._abyssea_su5_drops(ROOT):     add(iid, "Abyssea Su5")
for iid in S._catalyst_mob_drops(ROOT):    add(iid, "Catalyst mobs")
for iid in S._dungeon_augment_drops(ROOT): add(iid, "Augment Dungeon")
for iid in S._HL_TROPHY_DROPS:             add(iid, "HL Trophy")
for iid in S._SEAL_DROPS:                  add(iid, "GM Home seal")
# --- mob_droplist (live DB) — one bucket ---
db = S._drops(ROOT) or {}
db_available = S._drops(ROOT) is not None
for iid in db: add(iid, "mob_droplist")

# --- FLAG: equippable custom gear with >=2 distinct sources ---
CUSTOM = {"Infamy Vendor","Medal Accessory NPC","Medal Armor NPC","Gear Progression Weapons",
          "HL Sortie Earrings","Reforge","Prime Armory","!shop","HTBF","Voidwatch","Abyssea Su5",
          "Catalyst mobs","Augment Dungeon","HL Trophy","GM Home seal"}
dups = []
for iid, srcs in sources.items():
    has_custom = bool(srcs & CUSTOM)
    if has_custom and len(srcs) >= 2:
        dups.append((iid, srcs))

print(f"equippable ids: {len(equip)} | items with >=1 source: {len(sources)} | mob_droplist loaded: {db_available}")
print(f"=== VIOLATIONS: custom gear acquirable >=2 ways: {len(dups)} ===")
for iid, srcs in sorted(dups, key=lambda x: -len(x[1])):
    print(f"  [{names.get(iid, '?')}] ({iid}): {' + '.join(sorted(srcs))}")

print()
VEND = {"Infamy Vendor","Medal Accessory NPC","Medal Armor NPC","Gear Progression Weapons","HL Sortie Earrings","Reforge","Prime Armory","!shop"}
DROPSYS = {"HTBF","Voidwatch","Abyssea Su5","Catalyst mobs","Augment Dungeon","HL Trophy","GM Home seal"}
catA=catB=catC=catD=0
for iid, srcs in dups:
    nv = len(srcs & VEND); nd = len(srcs & DROPSYS); inl = "mob_droplist" in srcs
    if nv >= 2: catA += 1
    elif nv >= 1 and nd >= 1: catB += 1
    elif nv >= 1 and inl: catC += 1
    elif nd >= 2 or (nd>=1 and inl): catD += 1
print(f"CATEGORY COUNTS (of {len(dups)}):")
print(f"  A) same item in 2+ CUSTOM VENDORS:        {catA}")
print(f"  B) custom vendor + custom DROP table:     {catB}")
print(f"  C) custom vendor + mob_droplist (a drop): {catC}")
print(f"  D) 2+ drop tables / drop+droplist:        {catD}")
