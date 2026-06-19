#!/usr/bin/env python3
"""
Clean BANNED and MALFORMED augments from every character inventory, KEEPING the
item and all other (valid) augments.

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
  A) BANNED   -- augId in BANNED_AUGS (retired augments that still sit on gear
                 augmented before their removal) -> ZERO the slot.
  B) MALFORMED-- augId has NO row in the `augments` table (orphaned / garbage id)
                 -> ZERO the slot. A boost is, by construction, already 0..31
                 (it is a 5-bit field), so there is nothing to clamp; a slot
                 with a VALID augId and a real table row is left BYTE-FOR-BYTE
                 untouched. => part B is a no-op on clean blobs.

Everything else in the blob is preserved exactly: AugmentKind, the kept slots,
and the signature. If an item ends up with NO augments AND an empty signature,
its blob is NULLed so it becomes a clean stock item.

The DRY-RUN report names every flagged augment (augId + its real stat from the
`augments` table) and prints a per-augment summary, so you can confirm by eye
exactly what will be removed BEFORE writing.

SAFETY:
  * OFFLINE characters only. A DB edit to an ONLINE char's inventory is
    overwritten when they log out (the server saves RAM -> DB), so online chars
    are REPORTED but never written -- re-run once they are offline.
  * Every affected row is backed up to a .tsv + a restore .sql before any write.
  * DRY-RUN by default. Set env DRY=0 to actually write.
  * No server restart needed -- offline inventories load fresh from
    char_inventory on next login.

ENV OVERRIDES:
  DRY        '1' (default) = dry-run; '0' = write.
  AUG_MYSQL  base mysql command (default 'sudo mysql' for the Azure box). For a
             local dry-run set e.g.:
               AUG_MYSQL='"C:/Program Files/MariaDB 10.6/bin/mysql.exe" -uroot -pwarrior3'
  AUG_BKDIR  backup directory (default /home/azureuser/augment_clean_backups).

KEEP-IN-SYNC: BANNED_AUGS below mirrors EXCLUDED_AUGS in
tools/gen_augment_catalog.py. If you retire another augment there, add its augId
here so it gets stripped from existing gear.
"""
import os
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

# --- A) BANNED augment IDs ---------------------------------------------------
# Mirror of EXCLUDED_AUGS in tools/gen_augment_catalog.py: augments retired from
# the catalog that may still sit on gear augmented before removal.
BANNED_AUGS = {
    380,                            # Physical Damage Limit
    550, 551, 552, 557, 558, 559,   # STR + DEX / VIT / AGI / CHR / INT / MND
    553, 555,                       # DEX+AGI, MND+CHR
    743, 744, 745, 749, 750, 751,   # flat melee / ranged Dmg
}

# Short names for the modIds that appear in banned/flagged augments (+ a few
# common ones). Anything else prints as mod<id>. Display only -- no logic uses it.
MOD_NAMES = {
    1: "DEF", 2: "HP", 5: "MP",
    8: "STR", 9: "DEX", 10: "VIT", 11: "AGI", 12: "INT", 13: "MND", 14: "CHR",
    287: "DMG", 376: "Rng.DMG", 1081: "Phys.Dmg.Limit%",
}


def mysql(query):
    r = subprocess.run(MYSQL_BASE + ["-N", "-B", "-e", query],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("MYSQL ERROR:\n" + r.stderr + "\n")
        sys.exit(1)
    return r.stdout


# --- Augment definitions (augId -> [(modId, value, mult), ...]) --------------
# An augId with NO entry here is orphaned/garbage -> part B zeroes it. An augId
# WITH an entry (even an inert modId=0 one) is a real, defined augment, left alone.
augdefs = {}
for ln in mysql(f"SELECT augmentId,modId,value,multiplier FROM {DB}.augments;").splitlines():
    ln = ln.strip()
    if not ln:
        continue
    a, mid, val, mul = (int(x) for x in ln.split("\t"))
    augdefs.setdefault(a, []).append((mid, val, mul))
valid_augids = set(augdefs)


def aug_desc(aug_id):
    """Human-readable 'what stat is this augment' -- e.g. '#550 STR+1 DEX+1'."""
    rows = augdefs.get(aug_id)
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


def fmt_hits(hits):
    """hits = [(slot, augId), ...] -> 'slot[0,1,2] #743 DMG+1x4; slot[4] #550 STR+1 DEX+1'."""
    by_aug = {}
    for s, a in hits:
        by_aug.setdefault(a, []).append(s)
    return " ; ".join(f"slot{sorted(ss)} {aug_desc(a)}" for a, ss in sorted(by_aug.items()))


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
    banned_hits, orphan_hits, kept = [], [], []   # (slot, augId) / (slot, augId, boost)
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        aug = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if aug == 0:
            continue                            # empty slot
        if aug in BANNED_AUGS:
            banned_hits.append((s, aug))        # A) banned
        elif aug not in valid_augids:
            orphan_hits.append((s, aug))        # B) orphaned / malformed
        else:
            kept.append((s, aug, boost))        # valid -> keep byte-for-byte
    if banned_hits or orphan_hits:
        sig = b[12:24].hex().upper()
        aff.append((charid, charname, loc, slot, itemId, name, b,
                    banned_hits, orphan_hits, kept, sig))

# --- Summary: what augments are being removed, across every item -------------
slot_counter = Counter()
for a in aff:
    for _, augid in a[7] + a[8]:
        slot_counter[augid] += 1

print(f"online charids right now: {len(online)}")
print(f"items to clean: {len(aff)}  "
      f"(banned slots={sum(len(a[7]) for a in aff)}, orphan slots={sum(len(a[8]) for a in aff)})")
print("\nAugments being removed (slot count across ALL items) -- confirm by eye:")
for augid, cnt in slot_counter.most_common():
    kind = "BANNED" if augid in BANNED_AUGS else "orphan"
    print(f"   {kind:6s}  {aug_desc(augid):34s} x {cnt} slot(s)")
print()

if not aff:
    print("Nothing to do.")
    sys.exit(0)

# --- backup (always, even in DRY) -------------------------------------------
os.makedirs(BKDIR, exist_ok=True)
with open(BACKUP, "w", encoding="utf-8") as bf, open(RESTORE, "w", encoding="utf-8") as rf:
    bf.write("charid\tlocation\tslot\titemId\torig_extra_hex\n")
    for charid, charname, loc, slot, itemId, name, b, banned_hits, orphan_hits, kept, sig in aff:
        bf.write(f"{charid}\t{loc}\t{slot}\t{itemId}\t{b.hex().upper()}\n")
        rf.write(f"UPDATE {DB}.char_inventory SET extra=UNHEX('{b.hex().upper()}') "
                 f"WHERE charid={charid} AND location={loc} AND slot={slot};\n")
print(f"backup : {BACKUP}")
print(f"restore: {RESTORE}\n")

done = on_skip = off_cnt = 0
for charid, charname, loc, slot, itemId, name, b, banned_hits, orphan_hits, kept, sig in aff:
    nb = bytearray(b)
    for s, _a in banned_hits + orphan_hits:
        off = 2 + s * 2
        nb[off] = 0
        nb[off + 1] = 0
    # No augments left AND empty signature -> NULL the blob (clean stock item).
    # Otherwise keep the modified blob byte-for-byte (preserves kind + kept slots + sig).
    remaining = any((nb[2 + 2 * s] | nb[2 + 2 * s + 1]) for s in range(5))
    sig_zero = (sig == "000000000000000000000000")
    newval = "NULL" if (not remaining and sig_zero) else f"UNHEX('{nb.hex().upper()}')"

    desc = fmt_hits(banned_hits + orphan_hits)
    keptd = ("| keep " + ",".join(f"#{a}" for _, a, _ in kept)) if kept \
        else ("-> NULL" if newval == "NULL" else "-> blank")

    is_on = charid in online
    if is_on:
        on_skip += 1
        print(f"  [SKIP/online] {charname:13.13s} {name[:18]:18.18s} {desc}  (re-run when offline)")
        continue

    off_cnt += 1
    tag = "DRY" if DRY else "CLEAN"
    print(f"  [{tag}/offline] {charname:13.13s} {name[:18]:18.18s} zero {desc} {keptd}")
    if not DRY:
        mysql(f"UPDATE {DB}.char_inventory SET extra={newval} "
              f"WHERE charid={charid} AND location={loc} AND slot={slot};")
        done += 1

print(f"\n{'DRY-RUN — NOTHING WRITTEN' if DRY else 'EXECUTED'}: "
      f"offline updated={0 if DRY else done}, "
      f"online skipped(re-run when offline)={on_skip}, "
      f"offline total={off_cnt}, items={len(aff)}")
