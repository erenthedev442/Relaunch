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


def mysql(query):
    r = subprocess.run(MYSQL_BASE + ["-N", "-B", "-e", query],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write("MYSQL ERROR:\n" + r.stderr + "\n")
        sys.exit(1)
    return r.stdout


# --- B) Valid augment IDs (every id defined in the augments table) -----------
# An augId with a row here -- even an inert modId=0 one -- is a real, defined
# augment and is left alone. An augId with NO row is orphaned -> zeroed.
valid_augids = set()
for ln in mysql(f"SELECT DISTINCT augmentId FROM {DB}.augments;").splitlines():
    ln = ln.strip()
    if ln:
        valid_augids.add(int(ln))

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
    banned_slots, orphan_slots, kept = [], [], []
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        aug = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if aug == 0:
            continue            # empty slot
        if aug in BANNED_AUGS:
            banned_slots.append(s)          # A) banned
        elif aug not in valid_augids:
            orphan_slots.append(s)          # B) orphaned / malformed
        else:
            kept.append((s, aug, boost))    # valid -> keep byte-for-byte
    if banned_slots or orphan_slots:
        sig = b[12:24].hex().upper()
        aff.append((charid, charname, loc, slot, itemId, name, b,
                    banned_slots, orphan_slots, kept, sig))

n_banned = sum(len(a[7]) for a in aff)
n_orphan = sum(len(a[8]) for a in aff)
print(f"banned augIds (A): {sorted(BANNED_AUGS)}")
print(f"valid augIds defined in table: {len(valid_augids)}")
print(f"online charids right now: {len(online)}")
print(f"items to clean: {len(aff)}  (banned slots={n_banned}, orphan slots={n_orphan})\n")

if not aff:
    print("Nothing to do.")
    sys.exit(0)

# --- backup (always, even in DRY) -------------------------------------------
os.makedirs(BKDIR, exist_ok=True)
with open(BACKUP, "w", encoding="utf-8") as bf, open(RESTORE, "w", encoding="utf-8") as rf:
    bf.write("charid\tlocation\tslot\titemId\torig_extra_hex\n")
    for charid, charname, loc, slot, itemId, name, b, banned_slots, orphan_slots, kept, sig in aff:
        bf.write(f"{charid}\t{loc}\t{slot}\t{itemId}\t{b.hex().upper()}\n")
        rf.write(f"UPDATE {DB}.char_inventory SET extra=UNHEX('{b.hex().upper()}') "
                 f"WHERE charid={charid} AND location={loc} AND slot={slot};\n")
print(f"backup : {BACKUP}")
print(f"restore: {RESTORE}\n")

done = on_skip = off_cnt = 0
for charid, charname, loc, slot, itemId, name, b, banned_slots, orphan_slots, kept, sig in aff:
    nb = bytearray(b)
    for s in banned_slots + orphan_slots:
        off = 2 + s * 2
        nb[off] = 0
        nb[off + 1] = 0
    # No augments left AND empty signature -> NULL the blob (clean stock item).
    # Otherwise keep the modified blob byte-for-byte (preserves kind + kept slots + sig).
    remaining = any((nb[2 + 2 * s] | nb[2 + 2 * s + 1]) for s in range(5))
    sig_zero = (sig == "000000000000000000000000")
    newval = "NULL" if (not remaining and sig_zero) else f"UNHEX('{nb.hex().upper()}')"

    is_on = charid in online
    keptd = ("keep " + ",".join(f"aug{a}@s{s}" for s, a, _ in kept)) if kept \
        else ("-> NULL" if newval == "NULL" else "-> blank")
    acts = []
    if banned_slots:
        acts.append(f"ban{banned_slots}")
    if orphan_slots:
        acts.append(f"orphan{orphan_slots}")

    if is_on:
        on_skip += 1
        print(f"  [SKIP/online] {charname:14.14s} {name[:20]:20.20s} {' '.join(acts)}  (re-run when offline)")
        continue

    off_cnt += 1
    tag = "DRY" if DRY else "CLEAN"
    print(f"  [{tag}/offline] {charname:14.14s} {name[:20]:20.20s} zero {' '.join(acts)} {keptd}")
    if not DRY:
        mysql(f"UPDATE {DB}.char_inventory SET extra={newval} "
              f"WHERE charid={charid} AND location={loc} AND slot={slot};")
        done += 1

print(f"\n{'DRY-RUN — NOTHING WRITTEN' if DRY else 'EXECUTED'}: "
      f"offline updated={0 if DRY else done}, "
      f"online skipped(re-run when offline)={on_skip}, "
      f"offline total={off_cnt}, items={len(aff)}")
