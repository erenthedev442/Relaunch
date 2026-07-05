"""gen_vendor_exclusions.py

Rebuild tools/vendor_obtainable_elsewhere.json -- the set of ilvl119+ gear that is
obtainable from a source OTHER than the medal vendor (Armor/Accessory/GearProgression
NPCs). score_armor/score_weapons/score_accessories drop these from bronze/silver/gold
so the medal vendor only sells gear EXCLUSIVE to it (owner rule 2026-07).

Sources counted as "obtainable elsewhere":
  * mob drops        -- sql/mob_droplist.sql
  * crafting         -- sql/synth_recipes.sql (all four result columns)
  * other custom content/vendors/forge -- item ids referenced in the reward/loot/
    vendor catalogs (everything except the three medal catalogs themselves)

Restricted to real ilvl>=119 equipment (sql/item_equipment.sql) since that's all the
vendor sells. Re-run after the DB or those catalogs change:  python tools/gen_vendor_exclusions.py
"""
from __future__ import annotations
import json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL  = ROOT / "sql"
LUA  = ROOT / "modules" / "custom" / "lua"

def _rows(path: Path, table: str):
    pat = re.compile(rf"INSERT INTO `{table}` VALUES \((.*)\);")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = pat.search(line)
        if m:
            yield m.group(1)

def _fields(blob: str):
    out, buf, q = [], [], False
    for ch in blob:
        if ch == "'":
            q = not q; buf.append(ch)
        elif ch == "," and not q:
            out.append("".join(buf).strip()); buf = []
        else:
            buf.append(ch)
    out.append("".join(buf).strip())
    return out

# 1. ilvl>=119 equipment ids  (itemId=field0, ilevel=field3)
gear = set()
for blob in _rows(SQL / "item_equipment.sql", "item_equipment"):
    f = _fields(blob)
    if len(f) > 3 and f[0].isdigit() and f[3].isdigit() and int(f[3]) >= 119:
        gear.add(int(f[0]))

# 2. mob drops  (itemId = field4)
drop = set()
for blob in _rows(SQL / "mob_droplist.sql", "mob_droplist"):
    f = _fields(blob)
    if len(f) > 4 and f[4].isdigit():
        drop.add(int(f[4]))

# 3. crafting results  (the 4 result columns sit before 4 qty cols + name + expansion)
synth = set()
for blob in _rows(SQL / "synth_recipes.sql", "synth_recipes"):
    f = _fields(blob)
    for v in f[-10:-6]:               # result, resultHQ1..3
        if v.isdigit() and int(v) > 0:
            synth.add(int(v))

# 4. ids referenced in other custom content/vendor/forge catalogs (not the medal 3)
MEDAL = {"armor_catalog.lua", "accessory_catalog.lua", "gear_progression_catalog.lua"}
catalog = set()
idpat = re.compile(r"\bid\s*=\s*(\d{4,5})")
for p in LUA.glob("*catalog*.lua"):
    if p.name in MEDAL:
        continue
    for m in idpat.finditer(p.read_text(encoding="utf-8", errors="replace")):
        catalog.add(int(m.group(1)))

elsewhere = sorted((drop | synth | catalog) & gear)
out = {
    "_note": ("Gear (ilvl119+) obtainable from a source OTHER than the medal vendor "
              "(mob drops, crafting, or another custom content/vendor/forge catalog). "
              "Excluded from Armor/Accessory/GearProgression bronze/silver/gold. "
              "Regenerate via tools/gen_vendor_exclusions.py."),
    "ids": elsewhere,
}
(ROOT / "tools" / "vendor_obtainable_elsewhere.json").write_text(json.dumps(out, indent=0), encoding="utf-8")
print(f"gear ilvl119+: {len(gear)} | drops: {len(drop&gear)} | craft: {len(synth&gear)} | "
      f"other content: {len(catalog&gear)} | -> obtainable-elsewhere gear: {len(elsewhere)}")
