"""gear_source_audit.py

Emit a CSV of EVERY equippable item in the DB with its level / item level,
slot, jobs, and WHERE it comes from -- split into:

  * retail_source   -- the stock (retail-accurate) LSB acquisition: mob drops
                       (which mob) / crafting / guild-shop sale from SQL, PLUS
                       battlefield-BCNM loot, quest rewards, and mission rewards
                       scraped from the Lua scripts (which reference items by
                       the xi.item.* enum).
  * relaunch_source -- the CUSTOM relaunch overlay that references the item id:
                       the medal / Infamy vendors, HTBF, Omen, Ambuscade,
                       Invasion, Voidwatch, Domain, the forges, etc.

Everything is read straight from the repo working tree (sql/*.sql +
modules/custom/**), so the output reflects the CURRENT source -- including
uncommitted / pending changes -- with NO server restart or DB required.

    python tools/gear_source_audit.py                 # -> exports/gear_source_audit.csv
    python tools/gear_source_audit.py path/to/out.csv

Notes / limitations:
  * "retail" here means "stock LSB content." LSB mirrors retail, so drops /
    synth / guild shops / BCNM / quests / missions are retail-accurate, but a
    custom drop added to mob_droplist (or a custom battlefield) would also show
    up under retail_source.
  * Quest/mission scraping matches GRANT contexts (npcUtil.giveItem, a reward
    table's item(s)=, :addItem) -- not trade-in requirements -- and resolves
    xi.item.* enum names to ids. A giveItem argument built from a variable
    (e.g. { reward.item, ... }) can't be resolved statically and is skipped.
  * relaunch_source is derived from item ids referenced in the custom lua
    catalogs/loot pools. A file's label is inferred from its name (see LABELS).
  * An item with neither column populated is currently UNOBTAINABLE in the repo.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL  = ROOT / "sql"
CUSTOM = ROOT / "modules" / "custom"

# ---------------------------------------------------------------------------
# SQL row helpers (quote-aware field split, shared with gen_vendor_exclusions)

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

def _unq(s: str) -> str:
    return s[1:-1] if len(s) >= 2 and s[0] == "'" and s[-1] == "'" else s

def _pretty(token: str) -> str:
    return token.replace("_", " ").strip().title()

# ---------------------------------------------------------------------------
# Job + slot decoding (job bit order verified against item_equipment)

JOB_ORDER = ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
             'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
             'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN']
JOB_BIT = {1 << i: n for i, n in enumerate(JOB_ORDER)}
ALL_JOBS_MASK = sum(1 << i for i in range(len(JOB_ORDER)))

def decode_jobs(mask: int) -> str:
    if mask == 0:
        return ""
    if mask & ALL_JOBS_MASK == ALL_JOBS_MASK:
        return "All Jobs"
    return "/".join(JOB_BIT[b] for b in sorted(JOB_BIT) if mask & b)

SLOT_NAMES = [
    (0x0001, "Main"), (0x0002, "Sub"),  (0x0004, "Range"), (0x0008, "Ammo"),
    (0x0010, "Head"), (0x0020, "Body"), (0x0040, "Hands"), (0x0080, "Legs"),
    (0x0100, "Feet"), (0x0200, "Neck"), (0x0400, "Waist"), (0x0800, "L.Ear"),
    (0x1000, "R.Ear"), (0x2000, "L.Ring"), (0x4000, "R.Ring"), (0x8000, "Back"),
]
_EAR_BITS  = 0x0800 | 0x1000
_RING_BITS = 0x2000 | 0x4000

def decode_slot(mask: int) -> str:
    if mask & _EAR_BITS == _EAR_BITS and mask & ~_EAR_BITS == 0:
        return "Ear"
    if mask & _RING_BITS == _RING_BITS and mask & ~_RING_BITS == 0:
        return "Ring"
    return "/".join(n for b, n in SLOT_NAMES if mask & b) or "-"

# ---------------------------------------------------------------------------
# 1. item_basic -> display name
names: dict[int, str] = {}
for blob in _rows(SQL / "item_basic.sql", "item_basic"):
    f = _fields(blob)
    if len(f) > 2 and f[0].isdigit():
        names[int(f[0])] = _pretty(_unq(f[2]))

# 2. item_equipment -> level / ilevel / jobs / slot  (the gear universe)
gear: dict[int, dict] = {}
for blob in _rows(SQL / "item_equipment.sql", "item_equipment"):
    f = _fields(blob)
    if len(f) > 8 and f[0].isdigit():
        iid = int(f[0])
        gear[iid] = {
            "level":  int(f[2]) if f[2].isdigit() else 0,
            "ilvl":   int(f[3]) if f[3].isdigit() else 0,
            "jobs":   decode_jobs(int(f[4])) if f[4].isdigit() else "",
            "slot":   decode_slot(int(f[8])) if f[8].isdigit() else "-",
        }

# ---------------------------------------------------------------------------
# RETAIL sources (stock LSB data)

# dropid -> mob name(s)
drop_mobs: dict[int, set] = {}
for blob in _rows(SQL / "mob_groups.sql", "mob_groups"):
    f = _fields(blob)
    if len(f) > 6 and f[6].isdigit():
        did = int(f[6])
        if did != 0:
            drop_mobs.setdefault(did, set()).add(_unq(f[3]).replace("_", " "))

# item -> mob name(s) via mob_droplist (dropId=f0, itemId=f4)
item_drop_mobs: dict[int, set] = {}
for blob in _rows(SQL / "mob_droplist.sql", "mob_droplist"):
    f = _fields(blob)
    if len(f) > 4 and f[0].isdigit() and f[4].isdigit():
        iid = int(f[4])
        if iid == 0:
            continue
        for mob in drop_mobs.get(int(f[0]), ()):  # empty if dropid unmapped
            item_drop_mobs.setdefault(iid, set()).add(mob)

# crafting results (4 result cols sit before 4 qty cols + name + expansion)
craftable: set = set()
for blob in _rows(SQL / "synth_recipes.sql", "synth_recipes"):
    f = _fields(blob)
    for v in f[-10:-6]:
        if v.isdigit() and int(v) > 0:
            craftable.add(int(v))

# guild-shop sales (itemId = field 1)
guild_sold: set = set()
gpath = SQL / "guild_shops.sql"
if gpath.exists():
    for blob in _rows(gpath, "guild_shops"):
        f = _fields(blob)
        if len(f) > 1 and f[1].isdigit():
            guild_sold.add(int(f[1]))

# --- Battlefield / BCNM loot + quest + mission rewards (Lua-scripted) --------
# These acquisition methods live in Lua, not SQL. They reference items by the
# xi.item.CONSTANT enum, so first build NAME -> id, then scrape each script set.
SCRIPTS = ROOT / "scripts"

ITEM_ENUM: dict[str, int] = {}
_enum_path = SCRIPTS / "enum" / "item.lua"
if _enum_path.exists():
    for m in re.finditer(r"^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(\d+)\s*,",
                         _enum_path.read_text(encoding="utf-8", errors="replace"), re.M):
        ITEM_ENUM[m.group(1)] = int(m.group(2))

_XI_ITEM = re.compile(r"xi\.item\.([A-Z_][A-Z0-9_]*)")

def _enum_ids(blob: str):
    """Every xi.item.NAME in `blob` that resolves to an equippable gear id."""
    for m in _XI_ITEM.finditer(blob):
        iid = ITEM_ENUM.get(m.group(1))
        if iid is not None and iid in gear:
            yield iid

# item -> set of source names, per script family
item_bcnm: dict[int, set] = {}
item_quest: dict[int, set] = {}
item_mission: dict[int, set] = {}

def _harvest(target: dict[int, set], iid: int, name: str):
    target.setdefault(iid, set()).add(name)

# Battlefields: the `content.loot = { ... }` armoury-crate table.
_LOOT_BLOCK = re.compile(r"content\.loot\s*=\s*\{.*?\n\}", re.S)
for p in SCRIPTS.glob("battlefields/**/*.lua"):
    text = p.read_text(encoding="utf-8", errors="replace")
    name = _pretty(p.stem)
    for block in _LOOT_BLOCK.findall(text):
        for iid in _enum_ids(block):
            _harvest(item_bcnm, iid, name)

# Quests + missions: grant contexts only -- npcUtil.giveItem(...), a reward
# table's `item(s) = ...`, and :addItem(...). Filtering to gear ids drops the
# non-gear grants (currency, KIs, food). Trade/haveItem checks are not matched.
_GIVE   = re.compile(r"npcUtil\.giveItem\(\s*\w+\s*,\s*(\{(?:[^{}]|\{[^{}]*\})*\}|xi\.item\.\w+[^)]*)\)")
_REWARD = re.compile(r"\bitems?\s*=\s*(\{[^{}]*\}|xi\.item\.\w+)")
_ADD    = re.compile(r":addItem\(\s*(xi\.item\.\w+[^)]*)\)")

def _scan_rewards(root_glob: str, target: dict[int, set]):
    for p in SCRIPTS.glob(root_glob):
        text = p.read_text(encoding="utf-8", errors="replace")
        name = _pretty(p.stem)
        for rx in (_GIVE, _REWARD, _ADD):
            for m in rx.finditer(text):
                for iid in _enum_ids(m.group(1)):
                    _harvest(target, iid, name)

_scan_rewards("quests/**/*.lua",   item_quest)
_scan_rewards("missions/**/*.lua", item_mission)

def _capped(names: set, n: int = 3) -> str:
    shown = sorted(names)
    return ", ".join(shown[:n]) + (f" +{len(shown) - n} more" if len(shown) > n else "")

def retail_source(iid: int) -> str:
    parts = []
    mobs = item_drop_mobs.get(iid)
    if mobs:
        parts.append(f"Drop: {_capped(mobs, 4)}")
    if iid in craftable:
        parts.append("Craft")
    if iid in guild_sold:
        parts.append("Guild Shop")
    if iid in item_bcnm:
        parts.append(f"BCNM: {_capped(item_bcnm[iid])}")
    if iid in item_quest:
        parts.append(f"Quest: {_capped(item_quest[iid])}")
    if iid in item_mission:
        parts.append(f"Mission: {_capped(item_mission[iid])}")
    return " | ".join(parts)

# ---------------------------------------------------------------------------
# RELAUNCH (custom) sources -- item ids referenced in the custom overlay.

# filename keyword -> friendly source label (first match wins, order matters)
LABELS = [
    ("armor_catalog",          "Medal Vendor (Armor)"),
    ("accessory_catalog",      "Medal Vendor (Accessory)"),
    ("gear_progression",       "Medal Vendor (Gear Progression)"),
    ("infamy",                 "Infamy Vendor"),
    ("htbf",                   "HTBF"),
    ("omen",                   "Omen"),
    ("ambuscade",              "Ambuscade"),
    ("invasion",               "Invasion"),
    ("voidwatch",              "Voidwatch"),
    ("voidspire",              "Voidspire"),
    ("domain",                 "Domain"),
    ("weapon_forge",           "Weapon Forge"),
    ("relic_forge",            "Relic Forge"),
    ("prime",                  "Prime Armory"),
    ("reforge",                "Reforge"),
    ("hunting_league",         "Hunting League"),
    ("hunters_guild",          "Hunter's Guild"),
    ("augment_affinity",       "Affinity NM"),
    ("augment",                "Augment"),
    ("gauntlet",               "Gauntlet"),
    ("unity",                  "Unity"),
    ("colosseum",              "Colosseum"),
    ("raid",                   "Raid"),
    ("gauntlet",               "Gauntlet"),
    ("daily_board",            "Daily Board"),
    ("weekly_hunts",           "Weekly Hunts"),
    ("treasure",               "Treasure Hunt"),
    ("provisioners",           "Provisioners' League"),
    ("cosmetic",               "Cosmetic Boutique"),
    ("casino",                 "Casino"),
    ("chocobo",                "Chocobo Derby"),
    ("prestige",               "Prestige"),
    ("login_rewards",          "Login Rewards"),
    ("gil_",                   "Gil Shop"),
]

def _label_for(fname: str) -> str:
    low = fname.lower()
    for key, label in LABELS:
        if key in low:
            return label
    return _pretty(fname.replace(".lua", "").replace("_catalog", "").replace("_", " "))

# structured `id = N` / `itemId = N` (avoids costs/weights that aren't ids)
_ID_RE   = re.compile(r"(?:\bid|\bitemId)\s*=\s*(\d{3,5})\b")
# invasion_loot_pool.lua is a flat list of bare 5-digit item ids
_BARE_RE = re.compile(r"\b(\d{5})\b")

item_custom: dict[int, set] = {}
invasion_pool: set = set()   # the catch-all "everything drops" pool, tracked separately

def _add_custom(iid: int, label: str):
    if iid in gear:  # only care about equippable gear
        item_custom.setdefault(iid, set()).add(label)

for p in sorted(CUSTOM.glob("lua/*.lua")):
    text = p.read_text(encoding="utf-8", errors="replace")
    # invasion_loot_pool.lua is AUTO-GENERATED from the whole item table (every
    # piece of gear), so folding it into relaunch_source would stamp "Invasion"
    # on ~everything and bury the meaningful sources. Track it as its own flag.
    if "invasion_loot_pool" in p.name:
        for m in _BARE_RE.finditer(text):
            iid = int(m.group(1))
            if iid in gear:
                invasion_pool.add(iid)
        continue
    label = _label_for(p.name)
    for m in _ID_RE.finditer(text):
        _add_custom(int(m.group(1)), label)

def relaunch_source(iid: int) -> str:
    return " | ".join(sorted(item_custom.get(iid, ())))

# ---------------------------------------------------------------------------
# Emit CSV

out_path = Path(sys.argv[1]) if len(sys.argv) > 1 else (ROOT / "exports" / "gear_source_audit.csv")
out_path.parent.mkdir(parents=True, exist_ok=True)

rows = 0
with out_path.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["item_id", "name", "level", "ilvl", "slot", "jobs",
                "retail_source", "relaunch_source", "invasion_pool", "obtainable"])
    for iid in sorted(gear):
        g = gear[iid]
        rt = retail_source(iid)
        rl = relaunch_source(iid)
        inv = iid in invasion_pool
        w.writerow([
            iid, names.get(iid, f"item_{iid}"), g["level"], g["ilvl"],
            g["slot"], g["jobs"], rt, rl,
            "yes" if inv else "",
            "yes" if (rt or rl or inv) else "NO",
        ])
        rows += 1

n_retail   = sum(1 for iid in gear if retail_source(iid))
n_relaunch = sum(1 for iid in gear if item_custom.get(iid))
n_inv      = sum(1 for iid in gear if iid in invasion_pool)
n_orphan   = sum(1 for iid in gear
                 if not retail_source(iid) and not item_custom.get(iid) and iid not in invasion_pool)
print(f"wrote {rows} gear rows -> {out_path}")
print(f"  with a retail source:              {n_retail}")
print(f"  with a curated relaunch source:    {n_relaunch}")
print(f"  in the Invasion catch-all pool:    {n_inv}")
print(f"  UNOBTAINABLE (none of the above):  {n_orphan}")
