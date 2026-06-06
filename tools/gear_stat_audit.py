#!/usr/bin/env python3
"""Audit gear used in Reforge + Hunting League systems for missing stat
implementation (items that exist in item_basic.sql but have no rows in
item_mods.sql, so they equip with zero stats).

Outputs JSON to tools/gear_stat_audit.json and a short console summary.
Investigation-only — does NOT modify catalogs or SQL.
"""

from __future__ import annotations

import datetime as _dt
import json
import os
import re
import sys
from collections import defaultdict
from typing import Dict, Iterable, List, Optional, Set, Tuple

REPO = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))

SQL_DIR = os.path.join(REPO, "sql")
LUA_DIR = os.path.join(REPO, "modules", "custom", "lua")
ITEM_ENUM = os.path.join(REPO, "scripts", "enum", "item.lua")

REFORGE_LUA       = os.path.join(LUA_DIR, "reforge_catalog.lua")
HUNTING_LUA       = os.path.join(LUA_DIR, "hunting_league_catalog.lua")
ARMOR_CATALOG_LUA = os.path.join(LUA_DIR, "armor_catalog.lua")
GEAR_PROG_LUA     = os.path.join(LUA_DIR, "gear_progression_catalog.lua")

OUTPUT_JSON       = os.path.join(REPO, "tools", "gear_stat_audit.json")


# ----------------------------------------------------------------------
# 1. Build xi.item -> ID map from scripts/enum/item.lua
# ----------------------------------------------------------------------
def load_item_enum(path: str) -> Dict[str, int]:
    """Return { CONSTANT_NAME (without xi.item. prefix) -> id }.

    The enum file is a Lua table of the shape:
        xi.item = {
            NONE                       = 0,
            ICE_BRAND                  = 16519,
            ...
        }
    Some lines are comments; some use computed expressions which we skip.
    """
    enum_map: Dict[str, int] = {}
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    # Match  NAME = <int>,
    pattern = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,?\s*(?:--.*)?$",
                         re.MULTILINE)
    for m in pattern.finditer(text):
        name = m.group(1)
        val  = int(m.group(2))
        enum_map[name] = val
    return enum_map


# ----------------------------------------------------------------------
# 2. Extract reforge IDs from reforge_catalog.lua
#    Pattern:  head|body|hands|legs|feet = { N, N, N, N }
#    inside catalog.pieces[xi.job.X] = { af = {...}, relic = {...}, empy = {...} }
# ----------------------------------------------------------------------
ITEM_ID_RE = re.compile(r"(\d+)")
SLOT_LINE_RE = re.compile(
    r"^\s*(head|body|hands|legs|feet)\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}",
    re.MULTILINE,
)
JOB_BLOCK_RE = re.compile(
    r"catalog\.pieces\[xi\.job\.([A-Z]+)\]\s*=\s*\{",
)
SET_HEADER_RE = re.compile(r"^\s*(af|relic|empy)\s*=\s*(?:--[^\n]*)?\s*$", re.MULTILINE)


def extract_reforge_items(path: str) -> List[Tuple[int, str]]:
    """Return list of (itemId, context_string) for every reforge piece.
    Context is "<JOB> <set> <slot> <tier>" e.g. "WAR empy head base".
    """
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # Find all job-block start positions
    job_starts: List[Tuple[int, str]] = [
        (m.start(), m.group(1)) for m in JOB_BLOCK_RE.finditer(text)
    ]
    if not job_starts:
        return []
    # Sort + sentinel end
    job_starts.sort()
    job_ends = [job_starts[i + 1][0] for i in range(len(job_starts) - 1)] + [len(text)]

    tier_names = ["base", "plus1", "plus2", "plus3"]
    out: List[Tuple[int, str]] = []

    for (start, job), end in zip(job_starts, job_ends):
        block = text[start:end]
        # Find set headers (af = / relic = / empy =) within this block; their
        # positions partition the block into set sections.
        sets = [(m.start(), m.group(1)) for m in SET_HEADER_RE.finditer(block)]
        sets.sort()
        set_ends = [sets[i + 1][0] for i in range(len(sets) - 1)] + [len(block)]

        for (sstart, setKey), send in zip(sets, set_ends):
            sub = block[sstart:send]
            for m in SLOT_LINE_RE.finditer(sub):
                slot = m.group(1)
                ids  = [int(m.group(i)) for i in range(2, 6)]
                for tier_idx, item_id in enumerate(ids):
                    if item_id and item_id > 0:
                        ctx = f"{job} {setKey} {slot} {tier_names[tier_idx]}"
                        out.append((item_id, ctx))
    return out


# ----------------------------------------------------------------------
# 3. Extract hunting league reward shop items
#    File is a return { ... } table — we look for `id = N` inside the
#    `rewardCategories` section, and also the `name = '...'` on the same row.
# ----------------------------------------------------------------------
HL_LABEL_RE = re.compile(r"label\s*=\s*['\"]([^'\"]+)['\"]")
HL_ITEM_LINE_RE = re.compile(
    r"name\s*=\s*['\"]([^'\"]+)['\"]\s*,\s*id\s*=\s*(\d+)\s*,\s*cost\s*=\s*\d+",
)


def extract_hunting_items(path: str) -> List[Tuple[int, str]]:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # rewardCategories starts at first `rewardCategories =`
    idx = text.find("rewardCategories")
    if idx < 0:
        return []
    sub = text[idx:]

    # Walk through and track current label
    out: List[Tuple[int, str]] = []
    current_label = "?"
    pos = 0
    # We'll iterate by re-finding labels and items in linear order
    events: List[Tuple[int, str, Tuple[str, ...]]] = []
    for m in HL_LABEL_RE.finditer(sub):
        events.append((m.start(), "label", (m.group(1),)))
    for m in HL_ITEM_LINE_RE.finditer(sub):
        events.append((m.start(), "item", (m.group(1), m.group(2))))
    events.sort()
    for off, kind, payload in events:
        if kind == "label":
            current_label = payload[0]
        else:
            name, sid = payload
            iid = int(sid)
            out.append((iid, f"HL shop [{current_label}] {name}"))
    return out


# ----------------------------------------------------------------------
# 4. Extract armor_catalog (Armor_NPC) entries
#    Lines look like:
#       table.insert(b.head, { id = 25616, name = "Amalric Coif +1", cost = 12,
#       table.insert(g.feet, { id = 23789, name = "Nyame Sollerets", ...
# ----------------------------------------------------------------------
ARMOR_ROW_RE = re.compile(
    r"table\.insert\((?P<bucket>[a-z])\.(?P<slot>head|body|hands|legs|feet)\s*,\s*\{\s*id\s*=\s*(?P<id>\d+)\s*,\s*name\s*=\s*['\"](?P<name>[^'\"]+)['\"]",
)

ARMOR_TIER_MAP = {"b": "bronze", "s": "silver", "g": "gold"}


def extract_armor_npc_items(path: str) -> List[Tuple[int, str]]:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    out: List[Tuple[int, str]] = []
    for m in ARMOR_ROW_RE.finditer(text):
        bucket = m.group("bucket")
        slot   = m.group("slot")
        iid    = int(m.group("id"))
        name   = m.group("name")
        tier   = ARMOR_TIER_MAP.get(bucket, bucket)
        out.append((iid, f"Armor NPC [{tier}] {slot}: {name}"))
    return out


# ----------------------------------------------------------------------
# 5. Extract gear_progression_catalog (weapons) entries
#    Mix of `id = xi.item.X` and `id = 21627` (raw IDs).
# ----------------------------------------------------------------------
WEAPON_XI_ROW_RE = re.compile(
    r"table\.insert\(\s*(\w+)\s*,\s*\{\s*id\s*=\s*xi\.item\.([A-Z0-9_]+)\s*,\s*name\s*=\s*['\"]([^'\"]+)['\"]",
)
WEAPON_RAW_ROW_RE = re.compile(
    r"table\.insert\(\s*(\w+)\s*,\s*\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*['\"]([^'\"]+)['\"]",
)

# Tier headers in gear_progression_catalog
TIER_HEADER_RE = re.compile(
    r"^-----------------------------------\s*\n--\s*(BRONZE|SILVER|GOLD)\s+TIER",
    re.MULTILINE,
)


def extract_gear_progression_items(
    path: str, enum_map: Dict[str, int]
) -> List[Tuple[int, str]]:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # Build tier ranges
    tier_starts = [(m.start(), m.group(1).lower()) for m in TIER_HEADER_RE.finditer(text)]
    tier_starts.sort()
    if not tier_starts:
        tier_starts = [(0, "bronze")]
    tier_ends = [tier_starts[i + 1][0] for i in range(len(tier_starts) - 1)] + [len(text)]

    def tier_of(off: int) -> str:
        for (s, name), e in zip(tier_starts, tier_ends):
            if s <= off < e:
                return name
        return "?"

    out: List[Tuple[int, str]] = []
    unresolved: List[str] = []

    for m in WEAPON_XI_ROW_RE.finditer(text):
        bucket, const, name = m.group(1), m.group(2), m.group(3)
        iid = enum_map.get(const)
        tier = tier_of(m.start())
        if iid is None:
            unresolved.append(f"{tier}/{bucket}: xi.item.{const} ({name})")
            continue
        out.append((iid, f"Weapons NPC [{tier}] {bucket}: {name}"))

    for m in WEAPON_RAW_ROW_RE.finditer(text):
        bucket, raw, name = m.group(1), m.group(2), m.group(3)
        iid = int(raw)
        tier = tier_of(m.start())
        out.append((iid, f"Weapons NPC [{tier}] {bucket}: {name}"))

    if unresolved:
        print(f"[warn] {len(unresolved)} xi.item.* constants couldn't be resolved "
              f"from gear_progression_catalog; first 5: {unresolved[:5]}",
              file=sys.stderr)
    return out


# ----------------------------------------------------------------------
# 6. SQL inspection helpers
#    We scan item_basic.sql, item_equipment.sql, item_mods.sql, item_latents.sql
#    and build per-item facts.
# ----------------------------------------------------------------------
BASIC_VALUES_RE = re.compile(
    r"\((\d+)\s*,\s*\d+\s*,\s*'([^']*)'",
)
EQUIP_VALUES_RE = re.compile(
    r"\((\d+)\s*,\s*'[^']*'\s*,\s*\d+",
)
MODS_VALUES_RE = re.compile(
    r"\((\d+)\s*,\s*\d+\s*,\s*-?\d+\s*\)",
)
LATENTS_VALUES_RE = re.compile(
    r"\((\d+)\s*,\s*\d+\s*,\s*-?\d+\s*,\s*\d+\s*,\s*-?\d+\s*\)",
)


def load_item_basic(path: str) -> Dict[int, str]:
    """ Map item_id -> short_name. """
    out: Dict[int, str] = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if "INSERT INTO `item_basic`" not in line and "INSERT INTO item_basic" not in line:
                # Some lines just have VALUES rows continuing -- but item_basic.sql in LSB
                # tends to do one VALUES (...) per insert line. We'll be defensive and use
                # the global regex pass instead.
                pass
        f.seek(0)
        text = f.read()
    # match the entire (itemid, subid, 'short_name', 'name'...)
    for m in BASIC_VALUES_RE.finditer(text):
        iid = int(m.group(1))
        out[iid] = m.group(2)
    return out


def load_item_equipment_ids(path: str) -> Set[int]:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    out: Set[int] = set()
    for m in EQUIP_VALUES_RE.finditer(text):
        out.add(int(m.group(1)))
    return out


def load_item_mod_counts(path: str) -> Dict[int, int]:
    """Return per-item mod row count from item_mods.sql."""
    counts: Dict[int, int] = defaultdict(int)
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    for m in MODS_VALUES_RE.finditer(text):
        counts[int(m.group(1))] += 1
    return counts


def load_item_latent_counts(path: str) -> Dict[int, int]:
    counts: Dict[int, int] = defaultdict(int)
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    for m in LATENTS_VALUES_RE.finditer(text):
        counts[int(m.group(1))] += 1
    return counts


# ----------------------------------------------------------------------
# 7. Classify
# ----------------------------------------------------------------------
def classify(
    iid: int,
    basic: Dict[int, str],
    equip: Set[int],
    mods: Dict[int, int],
    latents: Dict[int, int],
) -> str:
    if iid not in basic:
        return "MISSING"
    if iid not in equip:
        return "NOT-EQUIP"
    nm = mods.get(iid, 0)
    nl = latents.get(iid, 0)
    if nm == 0 and nl == 0:
        return "NAKED"
    if nm == 0 and nl > 0:
        return "LATENT-ONLY"
    return "OK"


# ----------------------------------------------------------------------
# 8. Main
# ----------------------------------------------------------------------
def main() -> int:
    print("[*] Loading item enum...")
    enum_map = load_item_enum(ITEM_ENUM)
    print(f"    {len(enum_map):,} constants")

    print("[*] Extracting Reforge items...")
    reforge = extract_reforge_items(REFORGE_LUA)
    print(f"    {len(reforge):,} item references")

    print("[*] Extracting Hunting League shop items...")
    hl_shop = extract_hunting_items(HUNTING_LUA)
    print(f"    {len(hl_shop):,} shop items")

    print("[*] Extracting Armor NPC items...")
    armor = extract_armor_npc_items(ARMOR_CATALOG_LUA)
    print(f"    {len(armor):,} armor entries")

    print("[*] Extracting Gear Progression (weapons) items...")
    weapons = extract_gear_progression_items(GEAR_PROG_LUA, enum_map)
    print(f"    {len(weapons):,} weapon entries")

    print("[*] Loading item_basic.sql...")
    basic = load_item_basic(os.path.join(SQL_DIR, "item_basic.sql"))
    print(f"    {len(basic):,} items")

    print("[*] Loading item_equipment.sql...")
    equip = load_item_equipment_ids(os.path.join(SQL_DIR, "item_equipment.sql"))
    print(f"    {len(equip):,} equipment entries")

    print("[*] Loading item_mods.sql counts...")
    mods = load_item_mod_counts(os.path.join(SQL_DIR, "item_mods.sql"))
    print(f"    {len(mods):,} items with mods")

    print("[*] Loading item_latents.sql counts...")
    latents = load_item_latent_counts(os.path.join(SQL_DIR, "item_latents.sql"))
    print(f"    {len(latents):,} items with latents")

    # Tag every reference with source
    sources: Dict[str, List[Tuple[int, str]]] = {
        "reforge":        reforge,
        "hunting_league": hl_shop + armor + weapons,
    }

    summary: Dict[str, Dict[str, int]] = {}
    naked: List[dict] = []
    missing: List[dict] = []
    latent_only: List[dict] = []
    not_equip: List[dict] = []

    # Track per-source per-id to avoid double-counting duplicates across
    # different contexts (e.g., same item shows up twice in reforge if any
    # mistake) — keep first context only.
    for source_name, items in sources.items():
        seen: Dict[int, str] = {}
        for iid, ctx in items:
            if iid not in seen:
                seen[iid] = ctx
        s = {"total": 0, "ok": 0, "naked": 0, "latent_only": 0,
             "missing": 0, "not_equip": 0}
        for iid, ctx in seen.items():
            s["total"] += 1
            cls = classify(iid, basic, equip, mods, latents)
            short = basic.get(iid, "")
            mc = mods.get(iid, 0)
            lc = latents.get(iid, 0)
            entry = {
                "itemId": iid,
                "shortName": short,
                "source": source_name,
                "context": ctx,
                "modCount": mc,
                "latentCount": lc,
            }
            if cls == "OK":
                s["ok"] += 1
            elif cls == "NAKED":
                s["naked"] += 1
                naked.append(entry)
            elif cls == "LATENT-ONLY":
                s["latent_only"] += 1
                latent_only.append(entry)
            elif cls == "MISSING":
                s["missing"] += 1
                missing.append(entry)
            elif cls == "NOT-EQUIP":
                s["not_equip"] += 1
                not_equip.append(entry)
        summary[source_name] = s

    naked.sort(key=lambda e: (e["source"], e["itemId"]))
    missing.sort(key=lambda e: (e["source"], e["itemId"]))
    latent_only.sort(key=lambda e: (e["source"], e["itemId"]))
    not_equip.sort(key=lambda e: (e["source"], e["itemId"]))

    report = {
        "generated_at": _dt.datetime.now().isoformat(timespec="seconds"),
        "summary": summary,
        "naked_items":      naked,
        "missing_items":    missing,
        "latent_only_items": latent_only,
        "not_equip_items":  not_equip,
    }

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    # ---- Console output -------------------------------------------------
    print()
    print("=" * 70)
    print("GEAR STAT AUDIT")
    print("=" * 70)
    for src, s in summary.items():
        print(f"\n[{src}]  total={s['total']}   "
              f"ok={s['ok']}  naked={s['naked']}  "
              f"latent_only={s['latent_only']}  "
              f"missing={s['missing']}  not_equip={s['not_equip']}")

    print()
    print("FIRST 10 NAKED ITEMS (no stats at all when equipped):")
    print(f"{'itemId':>7}  {'short_name':<32}  {'source':<16}  context")
    print("-" * 110)
    for e in naked[:10]:
        print(f"{e['itemId']:>7}  {e['shortName'][:32]:<32}  "
              f"{e['source']:<16}  {e['context']}")
    if len(naked) > 10:
        print(f"... and {len(naked) - 10} more (see {OUTPUT_JSON})")

    if missing:
        print()
        print(f"MISSING (not in item_basic.sql at all) — {len(missing)}")
        for e in missing[:10]:
            print(f"  {e['itemId']:>7}  source={e['source']:<16}  {e['context']}")

    if not_equip:
        print()
        print(f"NOT-EQUIP (in item_basic but not item_equipment) — {len(not_equip)}")
        for e in not_equip[:10]:
            print(f"  {e['itemId']:>7}  short={e['shortName']:<24}  "
                  f"source={e['source']:<16}  {e['context']}")

    if latent_only:
        print()
        print(f"LATENT-ONLY (has latents, no static mods) — {len(latent_only)}")
        for e in latent_only[:10]:
            print(f"  {e['itemId']:>7}  short={e['shortName']:<24}  "
                  f"latents={e['latentCount']}  src={e['source']:<16}  {e['context']}")

    print()
    print(f"Full report: {OUTPUT_JSON}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
