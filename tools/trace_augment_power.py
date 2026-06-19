#!/usr/bin/env python3
"""
READ-ONLY trace: for every augment on every character item, show its actual
applied value vs the catalog's max, so you can see whether anything is really
"too strong vs current".

For each augment slot it computes:
  applied = (tableValue + storedBoost) * tableMult        <- what the ENGINE gives now
  cap     = (catalogBase  + 31)        * catalogMult       <- the system's max (boost caps at 31)
and flags any slot where applied > cap (genuinely over the current ceiling).

Also prints, per augment actually found on gear: the boost spread, the max
applied value, and the cap -- plus a list of augments on gear that are NOT in
the Moogle catalog (retail / casket / removed), which `!refundcatalysts` covers.

Writes NOTHING. ENV: AUG_MYSQL (default 'sudo mysql'); on a laptop set e.g.
  AUG_MYSQL='"C:/Program Files/MariaDB 10.6/bin/mysql.exe" -uroot -pwarrior3'
"""
import os
import re
import shlex
import subprocess
import sys
from collections import defaultdict

DB = "xidb"
MYSQL_BASE = shlex.split(os.environ.get("AUG_MYSQL", "sudo mysql"))
MAX_BOOST = 31
CATALOG = os.environ.get("AUG_CATALOG", "modules/custom/lua/augment_catalog.lua")

MOD_NAMES = {
    1: "DEF", 2: "HP", 5: "MP", 8: "STR", 9: "DEX", 10: "VIT", 11: "AGI",
    12: "INT", 13: "MND", 14: "CHR", 25: "ATT", 65: "ATT", 287: "DMG",
    376: "Rng.DMG", 1081: "Phys.Dmg.Limit%",
}


def mysql(query):
    r = subprocess.run(MYSQL_BASE + ["-N", "-B", "-e", query], capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("MYSQL ERROR:\n" + r.stderr + "\n")
        sys.exit(1)
    return r.stdout


# catalog: augId -> (base, mult, label, maxBoost)  -- the system's INTENT.
# maxBoost is the per-augment boost ceiling the Moogle enforces (default 31 =
# the engine's hard cap). An item whose stored boost exceeds it was augmented
# before the cap was lowered and is "too strong vs current".
catalog = {}
for line in open(CATALOG, encoding="utf-8"):
    m = re.search(r'augId\s*=\s*(\d+)\s*,\s*base\s*=\s*(-?\d+)\s*,\s*mult\s*=\s*(\d+)', line)
    if not m:
        continue
    lm = re.search(r"""label\s*=\s*(['"])(.*?)\1""", line)
    mb = re.search(r'maxBoost\s*=\s*(\d+)', line)
    catalog[int(m.group(1))] = (int(m.group(2)), int(m.group(3)),
                                lm.group(2) if lm else "?",
                                int(mb.group(1)) if mb else MAX_BOOST)

# augments table: augId -> representative (modId, value, mult) the ENGINE applies
tbl = {}
for ln in mysql(f"SELECT augmentId,modId,value,multiplier FROM {DB}.augments;").splitlines():
    if not ln.strip():
        continue
    a, mid, v, mul = (int(x) for x in ln.split("\t"))
    if a not in tbl or abs(v) > abs(tbl[a][1]):
        tbl[a] = (mid, v, mul)

q = (f"SELECT HEX(ci.extra) FROM {DB}.char_inventory ci "
     f"WHERE ci.extra IS NOT NULL AND SUBSTRING(ci.extra,1,1)=0x02;")

over = []                               # genuinely over the cap
seen_boost = defaultdict(list)          # augId -> [boost,...]
noncatalog = defaultdict(int)           # augId (in table, not catalog) -> count
items = 0
for ln in mysql(q).splitlines():
    if not ln.strip():
        continue
    b = bytearray.fromhex(ln.strip())
    if len(b) < 12:
        continue
    items += 1
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        aug = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if aug == 0:
            continue
        seen_boost[aug].append(boost)
        if aug not in tbl:
            continue                    # orphan -- handled by the cleaner
        if aug not in catalog:
            noncatalog[aug] += 1
            continue
        cbase, cmult, _lbl, cmax = catalog[aug]
        _mid, tval, tmul = tbl[aug]
        tmul = tmul if tmul > 1 else 1
        cmult = cmult if cmult > 1 else 1
        applied = (tval + boost if tval > 0 else tval - boost) * tmul
        cap = (abs(cbase) + cmax) * cmult
        if boost > cmax:                 # stored boost over the augment's ceiling
            over.append((aug, boost, cmax, applied, cap))

print(f"scanned {items} augmented items\n")

print("=== Slots OVER the augment's boost ceiling (boost > maxBoost) ===")
if not over:
    print("  NONE — every augment on every item is within its maxBoost.\n")
else:
    by_aug = defaultdict(lambda: [0, None, None])  # aug -> [count, maxBoost, label]
    for aug, boost, cmax, applied, cap in over:
        by_aug[aug][0] += 1
        by_aug[aug][1] = cmax
        by_aug[aug][2] = catalog[aug][2]
    for aug, (cnt, cmax, lbl) in sorted(by_aug.items(), key=lambda kv: -kv[1][0]):
        seen = sorted(set(boost for a, boost, *_ in over if a == aug))
        print(f"  #{aug} {lbl}: maxBoost={cmax}, but {cnt} slot(s) carry boost {seen}  -> would cap to {cmax}")
    print()

print("=== Boost spread per cataloged augment on gear (cap = its maxBoost) ===")
for aug in sorted(seen_boost):
    if aug not in catalog:
        continue
    boosts = seen_boost[aug]
    cbase, cmult, lbl, cmax = catalog[aug]
    cmult = cmult if cmult > 1 else 1
    cap = (abs(cbase) + cmax) * cmult
    uniq = sorted(set(boosts))
    flag = "  <-- maxBoost < 31" if cmax < MAX_BOOST else ""
    print(f"  #{aug:<4} {lbl[:24]:24s} boosts {uniq}  on {len(boosts):>3} slot(s)   maxBoost={cmax} cap={cap}{flag}")

if noncatalog:
    print("\n=== Augments on gear NOT in the Moogle catalog (retail/casket/removed) ===")
    print("   (not from your augment system; !refundcatalysts removes these)")
    for aug, cnt in sorted(noncatalog.items(), key=lambda kv: -kv[1]):
        mid, v, mul = tbl[aug]
        nm = MOD_NAMES.get(mid, f"mod{mid}")
        print(f"   #{aug:<4} {nm}{'+' if v >= 0 else ''}{v}{('x'+str(mul)) if mul > 1 else ''}  on {cnt} slot(s)")
