#!/usr/bin/env python3
"""List a character's augmented items with decoded augments.

Read-only (SELECTs only). Run ON THE BOX (uses `sudo mysql` socket auth):
    python3 tools/list_char_augments.py <CharName>

Decodes the bit-packed augments out of char_inventory.extra (byte0 == 0x02
AugmentStandard blob; 5 slots of 2 bytes each starting at offset 2; low 11
bits = augId, high 5 bits = boost), maps augId -> the live `augments` table
(modId, base value, multiplier), applies the engine formula
(item_equipment.cpp:479) and the modId -> name from scripts/enum/mod.lua.
Equipped items (char_equip container/slot) are listed first.
"""
import subprocess
import sys
import re
import os

DB = "xidb"
REPO = os.path.expanduser("~/server")
LOC = {0: "Inventory", 1: "Mog Safe", 2: "Storage", 3: "Temp", 4: "Mog Locker",
       5: "Mog Satchel", 6: "Mog Sack", 7: "Mog Case", 8: "Wardrobe 1", 9: "Mog Safe 2",
       10: "Wardrobe 2", 11: "Wardrobe 3", 12: "Wardrobe 4", 13: "Wardrobe 5",
       14: "Wardrobe 6", 15: "Wardrobe 7", 16: "Wardrobe 8", 17: "Recycle"}

charname = sys.argv[1] if len(sys.argv) > 1 else "Burtgang"


def mysql(q):
    err = ""
    for cmd in ("mariadb", "mysql"):           # mariadb client first; mysql is the compat symlink
        try:
            r = subprocess.run(["sudo", cmd, "-N", "-B", "-e", q], capture_output=True, text=True)
        except FileNotFoundError:
            continue
        if r.returncode == 0:
            return r.stdout
        err = r.stderr
    sys.stderr.write(err or "no mariadb/mysql client found\n")
    sys.exit(1)


def applied(base, boost, mult):
    core = (base + boost) if base > 0 else (base - boost)
    return core * (mult if mult > 1 else 1)


# augments table: augId -> (modId, base, mult)
augs = {}
for ln in mysql(f"SELECT augmentId,modId,value,multiplier FROM {DB}.augments;").splitlines():
    if not ln.strip():
        continue
    a, m, v, mul = (int(x) for x in ln.split("\t"))
    augs[a] = (m, v, mul)

# modId -> mod name (scripts/enum/mod.lua)
modname = {}
try:
    with open(f"{REPO}/scripts/enum/mod.lua", encoding="utf-8", errors="replace") as f:
        for ln in f:
            mm = re.match(r"\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*(\d+)\s*,", ln)
            if mm:
                modname.setdefault(int(mm.group(2)), mm.group(1))
except OSError:
    pass

# equipped (containerid, slotid)
equipped = set()
for ln in mysql(f"SELECT ce.containerid, ce.slotid FROM {DB}.char_equip ce "
                f"JOIN {DB}.chars c ON c.charid=ce.charid WHERE c.charname='{charname}';").splitlines():
    if not ln.strip():
        continue
    cid, sid = (int(x) for x in ln.split("\t"))
    equipped.add((cid, sid))

# augmented items
q = (f"SELECT ci.location, ci.slot, ci.itemId, COALESCE(ib.sortname,ib.name,'?'), HEX(ci.extra) "
     f"FROM {DB}.char_inventory ci JOIN {DB}.chars c ON c.charid=ci.charid "
     f"LEFT JOIN {DB}.item_basic ib ON ib.itemid=ci.itemId "
     f"WHERE c.charname='{charname}' AND ci.extra IS NOT NULL AND SUBSTRING(ci.extra,1,1)=0x02 "
     f"ORDER BY ci.location, ci.slot;")

eq_items, other_items = [], []
for ln in mysql(q).splitlines():
    if not ln.strip():
        continue
    p = ln.split("\t")
    if len(p) < 5:
        continue
    loc, slot, itemId, name, hexx = int(p[0]), int(p[1]), int(p[2]), p[3], p[4]
    if itemId in (0, 65535):
        continue
    try:
        b = bytes.fromhex(hexx)
    except ValueError:
        continue
    if len(b) < 12:
        continue
    decoded = []
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        augId = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if augId == 0:
            continue
        if augId in augs:
            modId, base, mult = augs[augId]
            decoded.append((modname.get(modId, f"mod{modId}"), applied(base, boost, mult)))
        else:
            decoded.append((f"aug{augId}?", None))
    if not decoded:
        continue
    rec = (loc, slot, itemId, name.replace("_", " ").title(), decoded)
    (eq_items if (loc, slot) in equipped else other_items).append(rec)


def show(items):
    for loc, slot, itemId, disp, decoded in items:
        augstr = ", ".join(f"{mn} {('%+d' % ap) if ap is not None else '?'}" for mn, ap in decoded)
        print(f"  {disp}  (id {itemId}, {LOC.get(loc, loc)})  ->  {augstr}")


total = len(eq_items) + len(other_items)
print(f"=== {charname}: {total} augmented items ({len(eq_items)} equipped) ===\n")
print(f"--- EQUIPPED ({len(eq_items)}) ---")
show(eq_items)
print(f"\n--- NOT EQUIPPED ({len(other_items)}) ---")
show(other_items)
