#!/usr/bin/env python3
"""Generate modules/custom/lua/catalyst_warp_table.lua for the !augwarp command.

For every augment catalyst (keys of augment_catalog.lua) find an open-world mob
that drops it and that mob's spawn point, so !augwarp can warp the player to a
zone where the catalyst drops.

Drop rates come from the LIVE DB first (sees custom drop tables), falling back
to SQL-file parsing when the DB is unavailable (laptop / CI).
Spawn coordinates always come from the committed mob_spawn_points.sql.

Primary sort key: non-NM mobs first (a 100% drop from a lottery NM is worse
for farming than a 10-24% drop from a repeatable mob), then highest itemRate
(% chance). Tiebreak: Abyssea zones (denser spawns), then real coords over
placeholder (0,0,0 / 1,1,1), then lowest minLevel for accessibility.

Run:  python tools/gen_catalyst_warp_table.py     (cwd = repo root / D:\\server_relaunch)
Regenerate whenever the catalog or mob droplist/spawn data changes, then commit
the resulting catalyst_warp_table.lua.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL  = ROOT / "sql"
OUT  = ROOT / "modules" / "custom" / "lua" / "catalyst_warp_table.lua"

# Allow importing tools.docgen._db when run as a script from the repo root.
sys.path.insert(0, str(ROOT))
try:
    from tools.docgen._db import connect as _db_connect
except ImportError:
    _db_connect = None  # type: ignore


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Catalog + static SQL parsers
# ---------------------------------------------------------------------------

def parse_catalysts() -> dict[int, dict]:
    text = read(ROOT / "modules" / "custom" / "lua" / "augment_catalog.lua")
    out: dict[int, dict] = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", text):
        iid  = int(m.group(1))
        body = m.group(2)
        cat   = re.search(r"\bcat\s*=\s*(\d+)", body)
        tier  = re.search(r"\btier\s*=\s*(\d+)", body)
        label = re.search(r"\blabel\s*=\s*'([^']*)'", body)
        out[iid] = {
            "cat":   int(cat.group(1))   if cat   else 0,
            "tier":  int(tier.group(1))  if tier  else 0,
            "label": label.group(1)      if label else "?",
        }
    return out


def parse_item_names() -> dict[int, str]:
    text = read(SQL / "item_basic.sql")
    out: dict[int, str] = {}
    for m in re.finditer(r"VALUES \((\d+),\d+,'([^']+)'", text):
        iid = int(m.group(1))
        if iid not in out:
            out[iid] = m.group(2).replace("_", " ").title()
    return out


def parse_zone_names() -> dict[int, str]:
    text = read(SQL / "zone_settings.sql")
    out: dict[int, str] = {}
    for m in re.finditer(r"VALUES \((\d+),\d+,'[^']*',\d+,'([^']+)'", text):
        out[int(m.group(1))] = m.group(2).replace("_", " ")
    return out


def parse_spawns() -> dict[tuple[int, int], list[tuple[int, float, float, float]]]:
    """(zone, groupid) -> [(minLevel, x, y, z)].  zone = (mobid>>12)&0xFFF."""
    text = read(SQL / "mob_spawn_points.sql")
    out: dict[tuple[int, int], list[tuple[int, float, float, float]]] = {}
    rx = re.compile(
        r"VALUES \((\d+),\d+,(?:'[^']*'|NULL),(?:'[^']*'|NULL),"
        r"(\d+),(\d+),(\d+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),"
    )
    for m in rx.finditer(text):
        mobid   = int(m.group(1))
        groupid = int(m.group(2))
        minlvl  = int(m.group(3))
        x, y, z = float(m.group(5)), float(m.group(6)), float(m.group(7))
        zone = (mobid >> 12) & 0xFFF
        out.setdefault((zone, groupid), []).append((minlvl, x, y, z))
    return out


# ---------------------------------------------------------------------------
# Drop data: live DB (preferred) or SQL fallback
# ---------------------------------------------------------------------------

# itemId -> {(groupid, zoneid, mob_name): (itemRate, isNM)}
_DropMap = dict[int, dict[tuple[int, int, str], tuple[int, bool]]]


def _drops_from_db() -> _DropMap | None:
    """Query the live DB for drop sources including custom drops."""
    if _db_connect is None:
        return None
    conn = _db_connect(ROOT)
    if conn is None:
        return None
    sql = """
        SELECT d.itemid, g.groupid, g.zoneid, g.name AS mob,
               MAX(d.itemRate) AS rate, MAX(p.mobType & 2) AS nm
        FROM mob_droplist d
        JOIN mob_groups g ON g.dropid = d.dropid
        JOIN mob_pools p ON p.poolid = g.poolid
        WHERE d.dropType IN (0, 1)
        GROUP BY d.itemid, g.groupid, g.zoneid, g.name
    """
    out: _DropMap = {}
    try:
        cur = conn.cursor()
        cur.execute(sql)
        for itemid, groupid, zoneid, mob, rate, nm in cur.fetchall():
            key = (int(groupid), int(zoneid), (mob or "?").replace("_", " "))
            iid = int(itemid)
            cur_rate = out.setdefault(iid, {}).get(key, (-1, False))[0]
            if int(rate) > cur_rate:
                out[iid][key] = (int(rate), bool(nm))
        cur.close()
    finally:
        conn.close()
    return out


def _drops_from_sql() -> _DropMap:
    """Fallback: parse drop sources from committed SQL files."""
    # Resolve @MACRO variables (e.g. @COMMON -> 150)
    dl_text = read(SQL / "mob_droplist.sql")
    macros: dict[str, int] = {}
    for m in re.finditer(r"SET\s+(@\w+)\s*=\s*(\d+)", dl_text):
        macros[m.group(1)] = int(m.group(2))

    # itemId -> {dropId: itemRate}
    item_to_drops: dict[int, dict[int, int]] = {}
    for m in re.finditer(r"VALUES \((\d+),(\d+),\d+,\d+,(\d+),(@\w+|\d+)", dl_text):
        drop_id   = int(m.group(1))
        drop_type = int(m.group(2))
        if drop_type not in (0, 1):   # skip Steal(2) and Despoil(4)
            continue
        item_id  = int(m.group(3))
        rate_tok = m.group(4)
        rate = macros.get(rate_tok, 0) if rate_tok.startswith("@") else int(rate_tok)
        d = item_to_drops.setdefault(item_id, {})
        if rate > d.get(drop_id, -1):
            d[drop_id] = rate

    # poolid -> mobType&2 (NM flag). mobType is the 10th numeric field after
    # the 0x... modelid blob (mJob..links are the 9 before it).
    pool_text = read(SQL / "mob_pools.sql")
    nm_pools: set[int] = set()
    for m in re.finditer(
        r"VALUES \((\d+),(?:'[^']*'|NULL),(?:'[^']*'|NULL),\d+,0x[0-9A-Fa-f]+,"
        r"(?:\d+,){9}(\d+),", pool_text
    ):
        if int(m.group(2)) & 2:
            nm_pools.add(int(m.group(1)))

    # dropId -> [(groupid, zoneid, mobname, isNM)]
    grp_text = read(SQL / "mob_groups.sql")
    drop_to_groups: dict[int, list[tuple[int, int, str, bool]]] = {}
    rx = re.compile(r"VALUES \((\d+),(\d+),(\d+),(?:'([^']*)'|NULL),(\d+),(\d+),(\d+),")
    for m in rx.finditer(grp_text):
        groupid = int(m.group(1))
        poolid  = int(m.group(2))
        zoneid  = int(m.group(3))
        name    = m.group(4) or "?"
        dropid  = int(m.group(7))
        if dropid:
            drop_to_groups.setdefault(dropid, []).append(
                (groupid, zoneid, name, poolid in nm_pools))

    out: _DropMap = {}
    for item_id, drop_rates in item_to_drops.items():
        for drop_id, rate in drop_rates.items():
            for groupid, zoneid, mob, is_nm in drop_to_groups.get(drop_id, ()):
                key = (groupid, zoneid, mob.replace("_", " "))
                cur = out.setdefault(item_id, {}).get(key, (-1, False))[0]
                if rate > cur:
                    out[item_id][key] = (rate, is_nm)
    return out


def _placeholder(x: float, y: float, z: float) -> bool:
    return (abs(x) < 0.01 and abs(y) < 0.01 and abs(z) < 0.01) or \
           (abs(x - 1) < 0.01 and abs(y - 1) < 0.01 and abs(z - 1) < 0.01)


# ---------------------------------------------------------------------------
# Manual warp-destination overrides
# ---------------------------------------------------------------------------
# Keyed by itemId. Overrides the auto-resolved zone+coordinates with a
# hand-chosen spawn point (e.g. a more accessible location in the same zone,
# or a different zone with a better drop mob). Mob/rate come from the auto-
# resolution; only the warp destination coordinates are replaced.
#
# Format: itemId -> {zone, zoneName, x, y, z}
# Abyssea zones win ties in candidate sorting — denser mob spawns make them
# better farming destinations when the drop rate is equal — but never beat a
# higher drop rate elsewhere (a 5% Abyssea mob must not outrank a 15% one).
ABYSSEA_ZONES: frozenset[int] = frozenset({15, 45, 132, 215, 216, 217, 218, 253, 254, 255})

# Boats, barges and airships (zone_settings ids). Warping a player onto a
# moving transport strands them until it docks — only pick one of these when
# no land-based source exists.
TRANSPORT_ZONES: frozenset[int] = frozenset({1, 3, 46, 47, 58, 59, 220, 221, 223, 224, 225, 226, 227, 228})

WARP_OVERRIDES: dict[int, dict] = {
    # Attack catalyst: warp to Abyssea-La Theine (132) at -681 / 0 / 242 instead of
    # Beaucedine Glacier (better accessible spawn for farming).
    861: {"zone": 132, "zoneName": "Abyssea-La Theine", "x": -681.5822, "y": 0.0, "z": 242.5282},
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    catalysts  = parse_catalysts()
    item_names = parse_item_names()
    zone_names = parse_zone_names()
    spawns     = parse_spawns()

    drop_map = _drops_from_db()
    if drop_map is not None:
        print("[catalyst_warp] using LIVE DB for drop rates (custom drops included)")
    else:
        drop_map = _drops_from_sql()
        print("[catalyst_warp] DB unavailable — falling back to SQL files (custom drops may be missing)")

    rows: dict[int, dict] = {}
    no_coords:  list[int] = []
    unresolved: list[int] = []

    for iid, meta in catalysts.items():
        cands:     list[dict] = []
        info_only: dict | None = None

        for (groupid, zoneid, mobname), (item_rate, is_nm) in drop_map.get(iid, {}).items():
            pts = spawns.get((zoneid, groupid), [])
            if not pts and (info_only is None or (info_only["nm"] and not is_nm)):
                info_only = {"zone": zoneid, "mob": mobname, "rate": item_rate, "nm": is_nm}
            for minlvl, x, y, z in pts:
                cands.append({
                    "zone": zoneid, "mob": mobname,
                    "lvl": minlvl, "x": x, "y": y, "z": z,
                    "ph": _placeholder(x, y, z),
                    "rate": item_rate, "nm": is_nm,
                })

        if not cands:
            if info_only:
                no_coords.append(iid)
                rows[iid] = {
                    "item": item_names.get(iid, f"item {iid}"),
                    "label": meta["label"], "cat": meta["cat"], "tier": meta["tier"],
                    "zone": info_only["zone"],
                    "zoneName": zone_names.get(info_only["zone"], f"Zone {info_only['zone']}"),
                    "mob": info_only["mob"],
                    "rate": info_only["rate"],
                    "noWarp": True,
                }
            else:
                unresolved.append(iid)
            continue

        # Primary sort: repeatable (non-NM) mobs first, land over boats/airships,
        # then highest drop rate. Tiebreak: Abyssea zones (denser spawns), then
        # real coords over placeholder (0,0,0), then lowest level.
        cands.sort(key=lambda c: (
            c["nm"],
            1 if c["zone"] in TRANSPORT_ZONES else 0,
            -c["rate"],
            0 if c["zone"] in ABYSSEA_ZONES else 1,
            c["ph"],
            c["lvl"],
        ))
        best = cands[0]
        ov = WARP_OVERRIDES.get(iid, {})
        rows[iid] = {
            "item": item_names.get(iid, f"item {iid}"),
            "label": meta["label"], "cat": meta["cat"], "tier": meta["tier"],
            "zone":     ov.get("zone",     best["zone"]),
            "zoneName": ov.get("zoneName", zone_names.get(best["zone"], f"Zone {best['zone']}")),
            "x": ov.get("x", best["x"]), "y": ov.get("y", best["y"]), "z": ov.get("z", best["z"]),
            "mob": best["mob"], "lvl": best["lvl"],
            "rate": best["rate"],
        }

    # Emit Lua.
    lines = [
        "-----------------------------------",
        "-- catalyst_warp_table.lua",
        "-- AUTO-GENERATED by tools/gen_catalyst_warp_table.py -- do not hand-edit.",
        "-- Maps each augment catalyst itemId -> the highest-drop-rate mob + its",
        "-- spawn point, for the !augwarp command.",
        "-- rate field is itemRate out of 1000 (divide by 10 for %).",
        "-----------------------------------",
        "return {",
    ]
    for iid in sorted(rows):
        r    = rows[iid]
        item  = r["item"].replace("'", "\\'")
        label = r["label"].replace("'", "\\'")
        mob   = r["mob"].replace("'", "\\'")
        zn    = r["zoneName"].replace("'", "\\'")
        rate  = r.get("rate", 0)
        if r.get("noWarp"):
            lines.append(
                f"    [{iid}] = {{ item='{item}', label='{label}', cat={r['cat']}, "
                f"tier={r['tier']}, zone={r['zone']}, zoneName='{zn}', "
                f"mob='{mob}', rate={rate}, noWarp=true }},"
            )
        else:
            lines.append(
                f"    [{iid}] = {{ item='{item}', label='{label}', cat={r['cat']}, "
                f"tier={r['tier']}, zone={r['zone']}, zoneName='{zn}', "
                f"x={r['x']:.3f}, y={r['y']:.3f}, z={r['z']:.3f}, "
                f"mob='{mob}', lvl={r['lvl']}, rate={rate} }},"
            )
    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[catalyst_warp] catalysts={len(catalysts)} resolved={len(rows)} "
          f"no_spawn_coords={len(no_coords)} unresolved={len(unresolved)}")
    if unresolved:
        print(f"[catalyst_warp] unresolved (no droplist source): {sorted(unresolved)[:20]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
