#!/usr/bin/env python3
"""Reconcile gear mods: find equippable items whose live item_mods are MISSING
mods that the item's reference stats (BG-Wiki) say it should have.

This catches the "partial gap" class -- an item that has SOME mods but not all
(e.g. the Reforge +3/+4 pieces that had base stats but were missing Weapon skill
damage). The naked guard (check_obtainable_naked.py) can't see these because it
only asks "has ANY mods?".

Method:  for every item that has a BG-Wiki reference, parse the reference stat
string into expected (modId -> value) using the SAME verified parser/map used to
fix the +3/+4 lines, then diff against the item's actual item_mods rows. A mod is
"missing" if the reference has it and item_mods has no row for that modId. We
compare PRESENCE, not value (server values may intentionally differ, e.g. +4
scaling). Pet/wyvern stats are not in the map (they live in item_mods_pet) so
they are never reported here.

Reference:  tools/bgwiki_stats_cache.json  +  tools/plus3_fresh_stats.json
            (fresh re-scrape wins, since the old cache truncated many +3 strings).
Output:     tools/gear_reconcile_report.json  + ranked console summary.

Run:  python tools/reconcile_gear_mods.py [--min-missing N] [--ilevel N]
Investigation-only -- never writes to the DB.
"""
from __future__ import annotations
import os, sys, json, re, argparse, datetime
from collections import defaultdict

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, REPO)
from tools.gen_plus4_displayed_mods import STAT_TO_MOD, tokenize, norm   # parser + base map
from tools.gen_plus3_displayed_mods import EXTRA                          # +3 aliases / extras
from tools.check_obtainable_naked import (load_db_settings,              # DB creds from network.lua
                                          load_item_enum, catalog_item_ids,
                                          by_design_allowlist)            # statless-on-purpose items

try:
    import pymysql
except ImportError:
    sys.exit("pymysql is required: pip install pymysql")

MAP = {**STAT_TO_MOD, **EXTRA}
ARMOR_SLOTS = {16, 32, 64, 128, 256}
WEAPON_SLOTS = {1, 2, 3, 4, 8}   # main / sub / main+sub / ranged / ammo (shuriken grant skill too)
# Combat skills a weapon grants intrinsically (from item_weapon / iLvl), so they
# are NOT item_mods rows on a weapon -> don't report them as "missing" there.
# (On ARMOR the same skill IS an item_mods bonus, so we keep it for armor.)
WEAPON_INTRINSIC = {80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91,
                    104, 105, 106, 107, 108, 110}


def mod_enum():
    txt = open(os.path.join(REPO, "scripts", "enum", "mod.lua"), encoding="utf-8", errors="replace").read()
    enum = {}
    for m in re.finditer(r"\b([A-Z][A-Z0-9_]+)\s*=\s*(\d+)", txt):
        enum.setdefault(int(m.group(2)), m.group(1))
    return enum


def expected_mods(stats: str) -> dict:
    out = {}
    for name, val in tokenize(stats):
        hit = MAP.get(norm(name))
        if not hit:
            continue
        mid, scale = hit
        v = val * scale
        if v != 0 and mid not in out:
            out[mid] = v
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-missing", type=int, default=1, help="only report items missing >= N mods")
    ap.add_argument("--ilevel", type=int, default=0, help="only report items at iLvl >= N")
    ap.add_argument("--top", type=int, default=35, help="how many to print")
    ap.add_argument("--obtainable", action="store_true",
                    help="only items players can actually get (custom catalogs + mob drops + "
                         "synth + guild shops) -- filters out unused/dormant retail item data")
    args = ap.parse_args()

    cache = json.load(open(os.path.join(REPO, "tools", "bgwiki_stats_cache.json"), encoding="utf-8"))
    fresh = {}
    for fn in ("plus3_fresh_stats.json", "plus12_fresh_stats.json"):
        fp = os.path.join(REPO, "tools", fn)
        if os.path.exists(fp):
            fresh.update(json.load(open(fp, encoding="utf-8")))
    ref = {**cache, **fresh}            # fresh re-scrapes override truncated cache entries

    enum = mod_enum()
    lbl = lambda m: f"{enum.get(m, 'mod')}({m})"

    s = load_db_settings()
    conn = pymysql.connect(host=s["host"], port=s["port"], user=s["user"],
                           password=s["password"], database=s["database"])
    cur = conn.cursor()
    cur.execute("SELECT itemId, ilevel, slot, name FROM item_equipment")
    equip = {r[0]: (r[1], r[2], r[3]) for r in cur.fetchall()}
    cur.execute("SELECT itemId, modId FROM item_mods")
    actual = defaultdict(set)
    for iid, mid in cur.fetchall():
        actual[iid].add(mid)
    # Obtainability: what a player can actually acquire on THIS server.
    obtainable = set(catalog_item_ids(load_item_enum()))   # custom progression systems
    cur.execute("SELECT DISTINCT itemId FROM mob_droplist")
    obtainable |= {r[0] for r in cur.fetchall()}
    cur.execute("SELECT DISTINCT Result FROM synth_recipes")
    obtainable |= {r[0] for r in cur.fetchall()}
    try:
        cur.execute("SELECT DISTINCT itemid FROM guild_shops")
        obtainable |= {r[0] for r in cur.fetchall()}
    except Exception:
        pass
    conn.close()
    bydesign = by_design_allowlist()

    rows = []
    for k, d in ref.items():
        try:
            iid = int(k)
        except (TypeError, ValueError):
            continue
        if iid not in equip:
            continue
        if iid in bydesign:                 # statless on purpose (Onion Sword line, etc.)
            continue
        if args.obtainable and iid not in obtainable:
            continue
        ilv, slot, name = equip[iid]
        if ilv < args.ilevel:
            continue
        exp = expected_mods(d.get("stats", ""))
        have = actual.get(iid, set())
        wpn = slot in WEAPON_SLOTS
        miss = {m: v for m, v in exp.items()
                if m not in have and not (wpn and m in WEAPON_INTRINSIC)}
        if len(miss) >= args.min_missing:
            rows.append({
                "itemId": iid, "name": name, "ilevel": ilv, "slot": slot,
                "n_missing": len(miss),
                "missing": {lbl(m): v for m, v in sorted(miss.items())},
            })
    rows.sort(key=lambda x: (-x["n_missing"], -x["ilevel"]))

    out = os.path.join(REPO, "tools", "gear_reconcile_report.json")
    json.dump({
        "generated": datetime.datetime.now().isoformat(timespec="seconds"),
        "referenced_items_checked": sum(1 for k in ref if int(k) in equip) if all(str(k).isdigit() for k in ref) else len(ref),
        "items_with_missing_mods": len(rows),
        "total_missing_mod_instances": sum(x["n_missing"] for x in rows),
        "items": rows,
    }, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print(f"checked {len(ref)} referenced items | items missing >=1 mod: {len(rows)} | "
          f"total missing-mod instances: {sum(x['n_missing'] for x in rows)}\n")
    print(f"Top {args.top} gaps (most-missing first):")
    for r in rows[:args.top]:
        print(f"  {r['itemId']:>6} {r['name']:<30} iLv{r['ilevel']:<3} miss {r['n_missing']:>2}: "
              f"{', '.join(r['missing'].keys())}")
    print(f"\nfull ranked report -> {out}")


if __name__ == "__main__":
    main()
