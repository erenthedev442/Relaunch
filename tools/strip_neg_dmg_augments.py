#!/usr/bin/env python3
"""
Strip negative-DMG augments from items while KEEPING the item (and any other augments).

For each item the scan flags (net DMG_RATING 287 / RANGED_DMG_RATING 376 < 0), zero
ONLY the augment slots whose augId is a negative-base DMG augment (modId 287/376,
value < 0). Everything else in the 24-byte exdata blob is preserved byte-for-byte:
AugmentKind, AugmentSubKind, the OTHER augment slots (good augments), and the signature.

OFFLINE characters only: a DB edit to an online char reverts on logout, so online chars
are skipped + reported (re-run once they're offline). No server restart needed — offline
inventories are loaded fresh from char_inventory on next login.

Backs up every affected row (+ a restore .sql) before touching anything.
DRY by default; set env DRY=0 to actually write.
"""
import os
import subprocess
import sys
import time

DB = "xidb"
DRY = os.environ.get("DRY", "1") != "0"
TS = int(time.time())
BKDIR = "/home/azureuser/neg_dmg_backups"
BACKUP = f"{BKDIR}/strip_{TS}.tsv"
RESTORE = f"{BKDIR}/strip_{TS}_restore.sql"


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


# DMG augment definitions; bad = negative-base (the ones that net negative)
dmg, bad = {}, set()
for ln in mysql(f"SELECT augmentId,modId,value,multiplier FROM {DB}.augments "
                f"WHERE modId IN (287,376);").splitlines():
    if not ln.strip():
        continue
    a, m, v, mul = (int(x) for x in ln.split("\t"))
    dmg[a] = (m, v, mul)
    if v < 0:
        bad.add(a)

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
    tot = {287: 0, 376: 0}
    badslots, kept = [], []
    for s in range(5):
        off = 2 + s * 2
        u16 = b[off] | (b[off + 1] << 8)
        aug = u16 & 0x7FF
        boost = (u16 >> 11) & 0x1F
        if aug in dmg:
            m, base, mult = dmg[aug]
            tot[m] += applied(base, boost, mult)
        if aug in bad:
            badslots.append(s)
        elif aug != 0:
            kept.append((s, aug, boost))
    if (tot[287] < 0 or tot[376] < 0) and badslots:
        sig = b[12:24].hex().upper()
        aff.append((charid, charname, loc, slot, itemId, name, b, badslots, kept, sig))

print(f"bad augIds (negative-base DMG): {sorted(bad)}")
print(f"online charids right now: {len(online)}")
print(f"net-negative items to strip: {len(aff)}\n")

# --- backup (always, even in DRY) ---
os.makedirs(BKDIR, exist_ok=True)
with open(BACKUP, "w") as bf, open(RESTORE, "w") as rf:
    bf.write("charid\tlocation\tslot\titemId\torig_extra_hex\n")
    for charid, charname, loc, slot, itemId, name, b, badslots, kept, sig in aff:
        bf.write(f"{charid}\t{loc}\t{slot}\t{itemId}\t{b.hex().upper()}\n")
        rf.write(f"UPDATE {DB}.char_inventory SET extra=UNHEX('{b.hex().upper()}') "
                 f"WHERE charid={charid} AND location={loc} AND slot={slot};\n")
print(f"backup : {BACKUP}")
print(f"restore: {RESTORE}\n")

done = on_cnt = off_cnt = 0
for charid, charname, loc, slot, itemId, name, b, badslots, kept, sig in aff:
    nb = bytearray(b)
    for s in badslots:
        off = 2 + s * 2
        nb[off] = 0
        nb[off + 1] = 0
    # If NO augments remain AND the signature is empty, NULL the blob so the item
    # is a clean stock item (not "blank-augmented"). Otherwise keep the modified
    # blob byte-for-byte (preserves AugmentKind + any good augments + signature).
    remaining = any((nb[2 + 2 * s] | nb[2 + 2 * s + 1]) for s in range(5))
    sig_zero = (sig == "000000000000000000000000")
    newval = "NULL" if (not remaining and sig_zero) else f"UNHEX('{nb.hex().upper()}')"

    is_on = charid in online
    if is_on:
        on_cnt += 1
    else:
        off_cnt += 1
    when = "relog" if is_on else "login"
    keptd = ("keep " + ",".join(f"aug{a}@s{s}" for s, a, _ in kept)) if kept else ("-> NULL" if newval == "NULL" else "-> blank")
    tag = "DRY" if DRY else "STRIP"
    print(f"  [{tag}/{when:5s}] {charname:14.14s} {name[:20]:20.20s} zero{badslots} {keptd}")
    if not DRY:
        mysql(f"UPDATE {DB}.char_inventory SET extra={newval} "
              f"WHERE charid={charid} AND location={loc} AND slot={slot};")
        done += 1

print(f"\n{'DRY-RUN — NOTHING WRITTEN' if DRY else 'EXECUTED'}: "
      f"updated={0 if DRY else done}, online(apply on relog)={on_cnt}, "
      f"offline(apply next login)={off_cnt}, total={len(aff)}")
