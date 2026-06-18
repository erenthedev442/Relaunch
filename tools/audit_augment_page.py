#!/usr/bin/env python3
"""Audit the WEBSITE augment catalog vs the LIVE augments table.

The website augment page (docgen `augments.py`) renders
`modules/custom/lua/augment_catalog.lua` — the catalog `gen_augment_catalog.py`
builds from `sql/augments.sql` + `zz_augment_rebalance.sql`. The ENGINE, however,
applies whatever is in the `augments` DB table (augmentId -> modId, value,
multiplier, cached at boot). If the generator's reconciliation drifts from the
table, the page lies about what you actually get (the WS-DMG 800-vs-200 bug was
exactly this — a `WHERE augmentId BETWEEN` override the parser couldn't read).

This flags, per augId shown on the site:
  * VALUE/MULT MISMATCH  — catalog base/mult != DB value/multiplier
  * COSMETIC (modId=0)   — shown on the site but attaches NO mod in-game
  * MISSING FROM DB      — in the catalog but not in the augments table

Runs on the laptop (MariaDB root) or the box (mariadb xiuser). Read-only.
    python tools/audit_augment_page.py
"""
import os
import re
import subprocess
import sys

ROOT = os.environ.get("LEGENDARY_LIVE_ROOT", r"D:/server")
CATALOG = os.path.join(ROOT, "modules", "custom", "lua", "augment_catalog.lua")


def mysql(query):
    attempts = (
        [r"C:\Program Files\MariaDB 10.6\bin\mysql.exe", "-u", "root", "-pwarrior3"],
        ["mariadb", "-u", "xiuser", "-pwarrior3"],
        ["mysql", "-u", "xiuser", "-pwarrior3"],
    )
    err = ""
    for base in attempts:
        try:
            r = subprocess.run(base + ["-N", "-B", "-e", query, "xidb"],
                               capture_output=True, text=True)
        except FileNotFoundError:
            continue
        if r.returncode == 0:
            return r.stdout
        err = r.stderr
    sys.exit("DB query failed: " + (err or "no client found"))


# --- DB truth: augmentId -> (modId, value, multiplier).  Multi-row augIds keep
#     a row with a non-zero modId when one exists (so the modId=0 flag is real). ---
db = {}
for ln in mysql("SELECT augmentId,modId,value,multiplier FROM augments;").splitlines():
    if not ln.strip():
        continue
    a, m, v, mul = (int(x) for x in ln.split("\t"))
    if a not in db or (db[a][0] == 0 and m != 0):
        db[a] = (m, v, mul)

# --- Catalog (website source): augId -> (base, mult, label) ---
aug_re = re.compile(r"augId\s*=\s*(\d+)")
base_re = re.compile(r"\bbase\s*=\s*(-?\d+)")
mult_re = re.compile(r"\bmult\s*=\s*(-?\d+)")
label_re = re.compile(r"label\s*=\s*'((?:[^'\\]|\\.)*)'")

cat = {}
with open(CATALOG, encoding="utf-8", errors="replace") as f:
    for ln in f:
        am = aug_re.search(ln)
        bm = base_re.search(ln)
        mm = mult_re.search(ln)
        if am and bm and mm:
            lm = label_re.search(ln)
            cat[int(am.group(1))] = (int(bm.group(1)), int(mm.group(1)),
                                     lm.group(1) if lm else "?")

# --- Compare ---
mismatch, cosmetic, missing = [], [], []
for aid, (base, mult, label) in sorted(cat.items()):
    if aid not in db:
        missing.append((aid, label))
        continue
    mod, value, dmult = db[aid]
    if mod == 0:
        cosmetic.append((aid, label))
    # The engine treats multiplier 0 and 1 identically (mult>1 ? mult : 1), so
    # normalise before comparing — only a DIFFERENT effective ceiling is a real
    # mismatch. The catalog stores base as a magnitude, so compare abs(value).
    eff_cat = mult if mult > 1 else 1
    eff_db = dmult if dmult > 1 else 1
    if base != abs(value) or eff_cat != eff_db:
        mismatch.append((aid, label, base, mult, value, dmult))

print(f"=== Augment page audit: {len(cat)} catalog entries vs {len(db)} DB augments ===\n")
print(f"--- VALUE/MULT MISMATCH ({len(mismatch)}): site shows base/mult, engine uses value/mult ---")
for aid, label, base, mult, value, dmult in mismatch:
    site_cap = (base + 31) * (mult if mult > 1 else 1)
    eng_cap = (abs(value) + 31) * (dmult if dmult > 1 else 1)
    print(f"  {aid:5} {label:34} site base={base} mult={mult} (cap {site_cap})"
          f"  vs  engine value={value} mult={dmult} (cap {eng_cap})")
print(f"\n--- COSMETIC modId=0 ({len(cosmetic)}): shown on site, attaches NO mod ---")
for aid, label in cosmetic:
    print(f"  {aid:5} {label}")
print(f"\n--- IN CATALOG, MISSING FROM augments TABLE ({len(missing)}) ---")
for aid, label in missing:
    print(f"  {aid:5} {label}")
print(f"\nSUMMARY: {len(mismatch)} mismatch, {len(cosmetic)} cosmetic, {len(missing)} missing")
