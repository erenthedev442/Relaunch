#!/usr/bin/env python3
"""
Clean BANNED, MALFORMED, and OVER-CAP augments from every character inventory,
KEEPING the item and all other (valid) augments.

Augments live bit-packed in the 24-byte `char_inventory.extra` blob:
  byte 0      = 0x02  (AugmentKind: this is an augmented item)
  bytes 2..11 = five uint16 slots, little-endian:
                  augId = u16 & 0x7FF        (low 11 bits)
                  boost = (u16 >> 11) & 0x1F  (high 5 bits, 0..31)
  bytes 12..23 = 12-byte signature
The engine applies, per slot:  final = (value + boost) * multiplier
(value + multiplier come from the `augments` table at runtime; the blob only
stores augId + boost).

WHAT THIS DOES, per augment slot (augId != 0):
  A) BANNED   -- augId in BANNED_AUGS (retired augments still on pre-removal
                 gear) -> ZERO the slot.
  B) MALFORMED-- augId has NO row in the `augments` table (orphaned id)
                 -> ZERO the slot.
  C) OVER-CAP -- augId is valid but its stored boost exceeds the augment's
                 maxBoost in augment_catalog.lua (the Moogle enforces maxBoost
                 only at augment time, so gear augmented before a cap was
                 lowered keeps the old higher boost) -> REDUCE the boost to
                 maxBoost in place (augId + other slots untouched).

A slot with a valid augId whose boost is already <= its maxBoost is left
BYTE-FOR-BYTE. => B and C are no-ops on clean blobs. Everything else in the blob
is preserved: AugmentKind, kept slots, signature. An item left with NO augments
AND an empty signature is NULLed to a clean stock item.

The DRY-RUN report names every affected augment (augId + its stat) and, for
over-cap, shows boost X->maxBoost.

SAFETY:
  * OFFLINE characters only (online edits revert on logout -> reported, skipped).
  * Backs up every affected row + a restore .sql before any write.
  * DRY-RUN by default. DRY=0 to write.
  * No restart needed -- offline inventories load fresh on next login.

ENV OVERRIDES:
  DRY         '1' (default) dry-run; '0' write.
  AUG_MYSQL   base mysql cmd (default 'sudo mysql'). Local laptop example:
                AUG_MYSQL='"C:/Program Files/MariaDB 10.6/bin/mysql.exe" -uroot -pwarrior3'
  AUG_BKDIR   backup dir (default /home/azureuser/augment_clean_backups).
  AUG_CATALOG augment_catalog.lua path (default ~/server/modules/custom/lua/
              augment_catalog.lua) -- read for the maxBoost ceilings (part C).

KEEP-IN-SYNC: BANNED_AUGS mirrors EXCLUDED_AUGS in gen_augment_catalog.py.
"""
import os
import re
import shlex
import subprocess
import sys
import time
from collections import Counter

DB = "xidb"
DRY = os.environ.get("DRY", "1") != "0"
TS = int(time.time())
BKDIR = os.environ.get("AUG_BKDIR", "/home/azureuser/augment_clean_backups")
BACKUP = f"{BKDIR}/aug_clean_{TS}.tsv"
RESTORE = f"{BKDIR}/aug_clean_{TS}_restore.sql"
MYSQL_BASE = shlex.split(os.environ.get("AUG_MYSQL", "sudo mysql"))
CATALOG = os.environ.get("AUG_CATALOG",
                         os.path.expanduser("~/server/modules/custom/lua/augment_catalog.lua"))
HARD_MAX_BOOST = 31   # engine's 5-bit ceiling; the per-augment maxBoost can be lower

# --- A) BANNED augment IDs ---------------------------------------------------
BANNED_AUGS = {
    380,                            # Physical Damage Limit
    550, 551, 552, 557, 558, 559,   # STR + DEX / VIT / AGI / CHR / INT / MND
    553, 555,                       # DEX+AGI, MND+CHR
    743, 744, 745, 749, 750, 751,   # flat melee / ranged Dmg
}

MOD_NAMES = {
    1: "DEF", 2: "HP", 5: "MP", 8: "STR", 9: "DEX", 10: "VIT", 11: "AGI",
    12: "INT", 13: "MND", 14: "CHR", 25: "ATT", 287: "DMG", 376: "Rng.DMG",
    1081: "Phys.Dmg.Limit%",
}


def mysql(query):
    r = subprocess.run(MYSQL_BASE + ["-N", "-B", "-e", query], capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("MYSQL ERROR:\n" + r.stderr + "\n")
        sys.exit(1)
    return r.stdout


# --- augments table: augId -> [(modId, value, mult), ...] --------------------
augdefs = {}
for ln in mysql(f"SELECT augmentId,modId,value,multiplier FROM {DB}.augments;").splitlines():
    ln = ln.strip()
    if not ln:
        continue
    a, mid, val, mul = (int(x) for x in ln.split("\t"))
    augdefs.setdefault(a, []).append((mid, val, mul))
valid_augids = set(augdefs)


# --- C) per-augment boost ceilings from augment_catalog.lua ------------------
# augId -> maxBoost (default 31). Only augments the catalog caps below 31 matter.
maxboost = {}
catalog_label = {}
if os.path.exists(CATALOG):
    for line in open(CATALOG, encoding="utf-8"):
        m = re.search(r'augId\s*=\s*(\d+)', line)
        if not m:
            continue
        aug = int(m.group(1))
        mb = re.search(r'maxBoost\s*=\s*(\d+)', line)
        maxboost[aug] = int(mb.group(1)) if mb else HARD_MAX_BOOST
        lm = re.search(r"""label\s*=\s*(['"])(.*?)\1""", line)
        if lm:
            catalog_label[aug] = lm.group(2)
    capped = {a: mb for a, mb in maxboost.items() if mb < HARD_MAX_BOOST}
    print(f"catalog loaded: {len(maxboost)} augs, {len(capped)} with maxBoost<31 {capped}")
else:
    print(f"[warn] catalog not found at {CATALOG} -- part C (over-cap) SKIPPED. "
          f"Set AUG_CATALOG to enable it.")


def aug_desc(aug_id):
    lbl = catalog_label.get(aug_id)
    if lbl:                              # cataloged -> human label (e.g. 'All songs')
        return f"#{aug_id} {lbl}"
    rows = augdefs.get(aug_id)           # else (banned/orphan) -> raw stat
    if not rows:
        return f"#{aug_id} (orphan/undefined)"
    parts = []
    for mid, val, mul in rows:
        if mid == 0 and val == 0:
            continue
        nm = MOD_NAMES.get(mid, f"mod{mid}")
        s = f"{nm}{'+' if val >= 0 else ''}{val}"
        if mul and mul > 1:
            s += f"x{mul}"
        parts.append(s)
    return f"#{aug_id} " + (" ".join(parts) if parts else "(inert)")


online = set(int(x) for x in
             mysql(f"SELECT DISTINCT charid FROM {DB}.accounts_sessions;").split()
             if x.strip())

q = (f"SELECT ci.charid,c.charname,ci.location,ci.slot,ci.itemId,"
     f"COALESCE(ib.sortname,ib.name,'?'),HEX(ci.extra) "
     f"FROM {DB}.char_inventory ci JOIN {DB}.chars c ON c.charid=ci.charid "
     f"LEFT JOIN {DB}.item_basic ib ON ib.itemid=ci.itemId "
     f"WHERE ci.extra IS NOT NULL AND SUBSTRING(ci.extra,1,1)=0x02;")

aff = []
for ln in mysql(q).splitlines():
    if not ln.strip():
        continue
    p = ln.split("\t")
    if len(p) < 7:
        continue
    charid, charname, loc, slot, itemId, name, hexx = \
        int(p[0]), p[1], int(p[2]), int(p[3]), int(p[4]), p[5], p[6]
    b = bytearray.fromhex(hexx)
    if len(b) < 12:
        continue
    banned_hits, orphan_hits, cap_hits, kept = [], [], [], []
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        aug = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if aug == 0:
            continue
        if aug in BANNED_AUGS:
            banned_hits.append((s, aug))                       # A) zero
        elif aug not in valid_augids:
            orphan_hits.append((s, aug))                       # B) zero
        else:
            mx = maxboost.get(aug, HARD_MAX_BOOST)
            if boost > mx:
                cap_hits.append((s, aug, boost, mx))           # C) reduce boost
            else:
                kept.append((s, aug, boost))
    if banned_hits or orphan_hits or cap_hits:
        sig = b[12:24].hex().upper()
        aff.append((charid, charname, loc, slot, itemId, name, b,
                    banned_hits, orphan_hits, cap_hits, kept, sig))

# --- Summary -----------------------------------------------------------------
zero_counter = Counter()
cap_counter = Counter()
for a in aff:
    for _, augid in a[7] + a[8]:
        zero_counter[augid] += 1
    for _, augid, _, _ in a[9]:
        cap_counter[augid] += 1

print(f"\nonline charids right now: {len(online)}")
print(f"items to clean: {len(aff)}  (zero banned/orphan slots={sum(zero_counter.values())}, "
      f"cap-to-maxBoost slots={sum(cap_counter.values())})")
if zero_counter:
    print("\nAugments being REMOVED (zeroed) -- confirm by eye:")
    for augid, cnt in zero_counter.most_common():
        kind = "BANNED" if augid in BANNED_AUGS else "orphan"
        print(f"   {kind:6s}  {aug_desc(augid):34s} x {cnt} slot(s)")
if cap_counter:
    print("\nAugments being CAPPED to maxBoost (boost reduced, item kept):")
    for augid, cnt in cap_counter.most_common():
        mx = maxboost.get(augid, HARD_MAX_BOOST)
        print(f"   CAP     {aug_desc(augid):34s} -> boost<= {mx}   x {cnt} slot(s)")
print()

if not aff:
    print("Nothing to do.")
    sys.exit(0)

# --- backup (always) ---------------------------------------------------------
os.makedirs(BKDIR, exist_ok=True)
with open(BACKUP, "w", encoding="utf-8") as bf, open(RESTORE, "w", encoding="utf-8") as rf:
    bf.write("charid\tlocation\tslot\titemId\torig_extra_hex\n")
    for charid, charname, loc, slot, itemId, name, b, *_rest in aff:
        bf.write(f"{charid}\t{loc}\t{slot}\t{itemId}\t{b.hex().upper()}\n")
        rf.write(f"UPDATE {DB}.char_inventory SET extra=UNHEX('{b.hex().upper()}') "
                 f"WHERE charid={charid} AND location={loc} AND slot={slot};\n")
print(f"backup : {BACKUP}")
print(f"restore: {RESTORE}\n")

done = on_skip = off_cnt = 0
for charid, charname, loc, slot, itemId, name, b, banned_hits, orphan_hits, cap_hits, kept, sig in aff:
    nb = bytearray(b)
    for s, _a in banned_hits + orphan_hits:                    # zero
        off = 2 + s * 2
        nb[off] = 0
        nb[off + 1] = 0
    for s, aug, _old, mx in cap_hits:                          # reduce boost in place
        off = 2 + s * 2
        u16 = aug | (mx << 11)
        nb[off] = u16 & 0xFF
        nb[off + 1] = (u16 >> 8) & 0xFF

    remaining = any((nb[2 + 2 * s] | nb[2 + 2 * s + 1]) for s in range(5))
    sig_zero = (sig == "000000000000000000000000")
    newval = "NULL" if (not remaining and sig_zero) else f"UNHEX('{nb.hex().upper()}')"

    acts = []
    for _s, a in banned_hits:
        acts.append(f"zero {aug_desc(a)}")
    for _s, a in orphan_hits:
        acts.append(f"zero {aug_desc(a)}")
    for _s, a, old, mx in cap_hits:
        acts.append(f"cap {aug_desc(a)} boost {old}->{mx}")
    desc = " | ".join(acts)

    is_on = charid in online
    if is_on:
        on_skip += 1
        print(f"  [SKIP/online] {charname:13.13s} {name[:18]:18.18s} {desc}  (re-run when offline)")
        continue

    off_cnt += 1
    tag = "DRY" if DRY else "CLEAN"
    print(f"  [{tag}/offline] {charname:13.13s} {name[:18]:18.18s} {desc}")
    if not DRY:
        mysql(f"UPDATE {DB}.char_inventory SET extra={newval} "
              f"WHERE charid={charid} AND location={loc} AND slot={slot};")
        done += 1

print(f"\n{'DRY-RUN — NOTHING WRITTEN' if DRY else 'EXECUTED'}: "
      f"offline updated={0 if DRY else done}, "
      f"online skipped(re-run when offline)={on_skip}, "
      f"offline total={off_cnt}, items={len(aff)}")
