#!/usr/bin/env python3
"""
Scan the live xidb for ALL items whose APPLIED weapon-DMG augment nets negative.

Mirrors !delnegdmg, but DB-wide (offline chars included). Decodes the bit-packed
augments out of char_inventory.extra (24-byte AugmentStandard blob) and replicates
the engine apply formula (item_equipment.cpp:479):

    applied = (base>0 ? base+boost : base-boost) * (mult>1 ? mult : 1)

per DMG augment (modId 287 melee / 376 ranged), sums per mod across the 5 slots,
and flags items whose total for either mod is < 0.

Read-only: SELECTs only. Run on the box (uses `sudo mysql` socket auth).
"""
import subprocess
import sys
from collections import Counter

DB = "xidb"

LOC = {0: "Inventory", 1: "Mog Safe", 2: "Storage", 3: "Temp Items", 4: "Mog Locker",
       5: "Mog Satchel", 6: "Mog Sack", 7: "Mog Case", 8: "Wardrobe", 9: "Mog Safe 2",
       10: "Wardrobe 2", 11: "Wardrobe 3", 12: "Wardrobe 4", 13: "Wardrobe 5",
       14: "Wardrobe 6", 15: "Wardrobe 7", 16: "Wardrobe 8", 17: "Recycle Bin"}


def mysql(query):
    r = subprocess.run(["sudo", "mysql", "-N", "-B", "-e", query],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("MYSQL ERROR:\n" + r.stderr + "\n")
        sys.exit(1)
    return r.stdout


def applied(base, boost, mult):
    core = (base + boost) if base > 0 else (base - boost)
    return core * (mult if mult > 1 else 1)


# --- 1. live DMG augment definitions (modId 287 melee, 376 ranged) ---
dmg = {}  # augId -> (modId, base_value, multiplier)
for line in mysql(f"SELECT augmentId, modId, value, multiplier FROM {DB}.augments "
                  f"WHERE modId IN (287,376);").splitlines():
    if not line.strip():
        continue
    a, m, v, mul = (int(x) for x in line.split("\t"))
    dmg[a] = (m, v, mul)

print("=== Live DMG augment definitions (engine apply range over boost 0..31) ===")
for aid in sorted(dmg):
    modId, base, mult = dmg[aid]
    eff = mult if mult > 1 else 1
    lo = applied(base, 0, mult)
    hi = applied(base, 31, mult)
    rng = sorted((lo, hi))
    kind = "melee " if modId == 287 else "ranged"
    canneg = "  <-- can apply NEGATIVE" if min(rng) < 0 else ""
    print(f"  aug {aid:4d} {kind}  base {base:+4d}  x{eff}  ->  applied {rng[0]:+5d}..{rng[1]:+5d}{canneg}")
print()

# --- 2. every standard-augmented inventory item (byte0 == 0x02) ---
q = (f"SELECT c.charname, ci.location, ci.slot, ci.itemId, "
     f"COALESCE(ib.sortname, ib.name, '?'), HEX(ci.extra) "
     f"FROM {DB}.char_inventory ci "
     f"JOIN {DB}.chars c ON c.charid = ci.charid "
     f"LEFT JOIN {DB}.item_basic ib ON ib.itemid = ci.itemId "
     f"WHERE ci.extra IS NOT NULL AND SUBSTRING(ci.extra,1,1) = 0x02;")

scanned = 0
hits = []
cause = Counter()
overflow_cases = 0

for line in mysql(q).splitlines():
    if not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) < 6:
        continue
    charname, loc, slot, itemId, name, hexextra = parts[:6]
    loc, slot, itemId = int(loc), int(slot), int(itemId)
    if itemId in (0, 65535):
        continue
    try:
        b = bytes.fromhex(hexextra)
    except ValueError:
        continue
    if len(b) < 12:
        continue

    scanned += 1
    tot = {287: 0, 376: 0}
    found = []  # (augId, base, boost, mult, modId, applied)
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        augId = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if augId in dmg:
            modId, base, mult = dmg[augId]
            ap = applied(base, boost, mult)
            tot[modId] += ap
            found.append((augId, base, boost, mult, modId, ap))

    if tot[287] < 0 or tot[376] < 0:
        hits.append((charname, loc, slot, itemId, name, tot, found))
        for augId, base, boost, mult, modId, ap in found:
            if ap < 0:
                cause[augId] += 1
                if base > 0:          # a "+DMG" augment that applied negative = real overflow
                    overflow_cases += 1

# --- 3. report ---
print(f"=== Scanned {scanned} standard-augmented items DB-wide ===")
print(f"=== {len(hits)} item(s) have a NEGATIVE applied DMG augment ===\n")

hits.sort(key=lambda h: (h[0].lower(), h[1], h[2]))
print("| Character | Item | Augment | Net DMG |")
print("|---|---|---|---|")
for charname, loc, slot, itemId, name, tot, found in hits:
    disp = name.replace("_", " ").title()
    agg, order = {}, []
    for augId, base, boost, mult, modId, ap in found:
        if augId not in agg:
            agg[augId] = [0, base, modId]
            order.append(augId)
        agg[augId][0] += 1
    augparts = []
    for augId in order:
        cnt, base, modId = agg[augId]
        kind = " ranged" if modId == 376 else ""
        augparts.append(f"{cnt}x Dmg:{base:+d}{kind} (aug {augId})")
    netparts = []
    if tot[287] < 0:
        netparts.append(f"DMG {tot[287]}")
    if tot[376] < 0:
        netparts.append(f"R.DMG {tot[376]}")
    print(f"| {charname} | {disp} (id {itemId}, {LOC.get(loc, loc)} #{slot}) | {'; '.join(augparts)} | {', '.join(netparts)} |")

print()
print("=== cause tally (augId -> # of items it pushed negative) ===")
for augId, n in cause.most_common():
    modId, base, mult = dmg[augId]
    tag = "POSITIVE-base (OVERFLOW!)" if base > 0 else "negative-base (nominal)"
    print(f"  aug {augId}: {n} item(s)  [{tag}]")
print()
if overflow_cases:
    print(f"*** {overflow_cases} case(s) of a POSITIVE-base DMG augment applying NEGATIVE — real overflow bug. ***")
else:
    print("No positive-base DMG augment applied negative — every hit is a nominal -DMG augment.")
