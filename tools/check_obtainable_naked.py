#!/usr/bin/env python3
"""Guard against OBTAINABLE gear that equips for zero benefit.

Unlike tools/gear_stat_audit.py (which parses only upstream item_mods.sql and
feeds the BG-Wiki generator), this checks the LIVE DATABASE — the real state a
player sees — for the authoritative answer to one question:

    "Can a player obtain a piece of gear and equip it for NO stat benefit?"

A piece is flagged when ALL of these hold:
  * it is referenced by a reward catalog (modules/custom/lua/*.lua +
    tools/_plus4_catalog.lua) OR is on the auction house / a mob droplist /
    a guild shop  — i.e. a player can actually get it;
  * it is equippable (has a row in item_equipment);
  * it has ZERO rows in item_mods, item_latents AND item_mods_pet — so the
    only thing it grants is the base DEF/DMG already stored in item_equipment /
    item_weapon;
  * its item level is >= --min-ilevel (default 100). Low-level vanilla gear
    legitimately carries only base DEF, so flagging it is noise; endgame gear
    with no stat block is almost always a data bug.

Items that are statless BY DESIGN (Tokko/Voluspa/Onion novelty weapons, ammo,
unappraised Hexed gear) are excluded via an allowlist sourced from
sql/zz_rollback_fabricated_mods.sql plus a small hardcoded set.

Exit code: 0 if clean, 1 if any offenders — so it can gate refresh-site.bat /
deploys / CI:  `python tools/check_obtainable_naked.py || echo "FIX GEAR"`

Why this exists: the Reforge +4 dungeon-shop gear shipped naked because both
existing fixers were scoped to 4 catalogs and never looked at dungeon_catalog.
This check is catalog-agnostic, so the next batch of added gear can't slip
through the same gap.
"""
from __future__ import annotations

import argparse
import glob
import os
import re
import sys

try:
    import pymysql
except ImportError:
    sys.exit("pymysql is required: pip install pymysql")

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
NETWORK_LUA = os.path.join(REPO, "settings", "network.lua")
ITEM_ENUM = os.path.join(REPO, "scripts", "enum", "item.lua")
LUA_GLOBS = [
    os.path.join(REPO, "modules", "custom", "lua", "*.lua"),
    os.path.join(REPO, "tools", "_plus4_catalog.lua"),
]
ROLLBACK_SQL = os.path.join(REPO, "sql", "zz_rollback_fabricated_mods.sql")

# Statless on purpose — their value is DMG/Delay/skill in item_weapon, not a
# stat block. The Onion Sword line is the canonical example; the rest are read
# from the rollback file at runtime so this stays in sync.
EXTRA_BY_DESIGN = {16534, 21602, 21608, 21640}  # onion_sword line

NUM_RE = re.compile(r"\b(?:itemId|item|id)\s*=\s*(\d{3,6})\b", re.IGNORECASE)
XI_RE = re.compile(r"\b(?:itemId|item|id)\s*=\s*xi\.item\.([A-Z0-9_]+)", re.IGNORECASE)
TUPLE_RE = re.compile(
    r"(?:head|body|hands|legs|feet|main|sub|ranged|ammo|neck|waist|ears?|rings?|back)"
    r"\s*=\s*\{\s*((?:\d+\s*,\s*){1,7}\d+)\s*\}"
)


def load_db_settings():
    txt = open(NETWORK_LUA, "r", encoding="utf-8", errors="replace").read()

    def grab(key, default=None):
        m = re.search(rf"{key}\s*=\s*'([^']*)'", txt) or re.search(rf"{key}\s*=\s*(\d+)", txt)
        return m.group(1) if m else default

    return dict(
        host=grab("SQL_HOST", "127.0.0.1"),
        port=int(grab("SQL_PORT", "3306")),
        user=grab("SQL_LOGIN", "root"),
        password=grab("SQL_PASSWORD", ""),
        database=grab("SQL_DATABASE", "xidb"),
    )


def load_item_enum():
    enum = {}
    for m in re.finditer(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,?", open(ITEM_ENUM, encoding="utf-8").read(), re.M):
        enum[m.group(1)] = int(m.group(2))
    return enum


def catalog_item_ids(enum):
    ids = set()
    files = []
    for g in LUA_GLOBS:
        files.extend(glob.glob(g))
    for f in files:
        t = open(f, encoding="utf-8", errors="replace").read()
        ids.update(int(x) for x in NUM_RE.findall(t))
        ids.update(enum[c] for c in XI_RE.findall(t) if c in enum)
        for grp in TUPLE_RE.findall(t):
            ids.update(int(x) for x in re.findall(r"\d+", grp))
    return ids


def by_design_allowlist():
    allow = set(EXTRA_BY_DESIGN)
    if os.path.exists(ROLLBACK_SQL):
        # Strip `-- ...` line comments first: the rollback file annotates every
        # ID with a comment that itself contains ')' (e.g. "(bronze daggers)"),
        # which would truncate a naive IN(...) capture. After stripping, the
        # only multi-digit tokens left are the itemIds being deleted.
        lines = []
        for line in open(ROLLBACK_SQL, encoding="utf-8"):
            lines.append(line.split("--", 1)[0])
        code = "\n".join(lines)
        m = re.search(r"item_mods.*?IN\s*\((.*)\)", code, re.DOTALL | re.IGNORECASE)
        if m:
            allow.update(int(x) for x in re.findall(r"\b(\d{3,6})\b", m.group(1)))
    return allow


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--min-ilevel", type=int, default=100,
                    help="only flag naked gear at this item level or higher (default 100)")
    ap.add_argument("--all", action="store_true", help="ignore the by-design allowlist")
    args = ap.parse_args()

    enum = load_item_enum()
    obtainable = catalog_item_ids(enum)
    allow = set() if args.all else by_design_allowlist()

    cfg = load_db_settings()
    con = pymysql.connect(**cfg)
    cur = con.cursor()

    def col(sql):
        cur.execute(sql)
        return {r[0] for r in cur.fetchall()}

    obtainable |= col("SELECT DISTINCT itemid FROM auction_house")
    obtainable |= col("SELECT DISTINCT itemId FROM mob_droplist")
    obtainable |= col("SELECT DISTINCT itemid FROM guild_shops")

    cur.execute("SELECT itemId, name, ilevel FROM item_equipment")
    equip = {r[0]: (r[1].decode() if isinstance(r[1], bytes) else r[1], r[2]) for r in cur.fetchall()}
    modded = col("SELECT DISTINCT itemId FROM item_mods")
    latent = col("SELECT DISTINCT itemId FROM item_latents")
    pet = col("SELECT DISTINCT itemId FROM item_mods_pet")
    con.close()

    offenders = []
    for iid in obtainable:
        if iid not in equip or iid in modded or iid in latent or iid in pet:
            continue
        if iid in allow:
            continue
        name, ilv = equip[iid]
        if ilv >= args.min_ilevel:
            offenders.append((iid, name, ilv))

    offenders.sort(key=lambda x: (-x[2], x[0]))
    if offenders:
        print(f"FAIL: {len(offenders)} obtainable item(s) at iLvl>={args.min_ilevel} "
              f"equip for ZERO stat benefit (no item_mods/latents/pet mods):\n")
        print(f"  {'itemId':>6}  {'iLvl':>4}  name")
        for iid, name, ilv in offenders:
            print(f"  {iid:>6}  {ilv:>4}  {name}")
        print("\nFix: add their mods (BG-Wiki cache via the gen pipeline, or a targeted")
        print("zz_ SQL file). If a flagged item is statless by design, add it to the")
        print("allowlist in sql/zz_rollback_fabricated_mods.sql or EXTRA_BY_DESIGN here.")
        return 1

    print(f"OK: no obtainable gear at iLvl>={args.min_ilevel} is naked "
          f"({len(allow)} by-design items allowlisted).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
