#!/usr/bin/env python3
"""Generate modules/custom/lua/catalyst_warp_table.lua for the !augwarp command.

For every augment catalyst (keys of augment_catalog.lua) find an open-world mob
that drops it and that mob's spawn point, so !augwarp can warp the player to a
zone where the catalyst drops.

Join (all from committed sql/, no live DB needed):
  augment_catalog.lua   catalyst itemId -> { cat, tier, label }
  item_basic.sql        itemId -> display name
  zone_settings.sql     zoneid -> zone name
  mob_droplist.sql      dropId -> itemId            (dropId,dropType,groupId,groupRate,itemId,itemRate)
  mob_groups.sql        dropid -> (groupid,zoneid,name)
  mob_spawn_points.sql  (zone,groupid) -> (minLevel,x,y,z)   zone = (mobid>>12)&0xFFF

For each catalyst we pick the most accessible drop: a spawn point with real
coords (not 0,0,0 / 1,1,1 placeholders) and the lowest minLevel.

Run:  python tools/gen_catalyst_warp_table.py     (cwd = repo root / D:\\server_relaunch)
Regenerate whenever the catalog or mob droplist/spawn data changes, then commit
the resulting catalyst_warp_table.lua.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "sql"
OUT = ROOT / "modules" / "custom" / "lua" / "catalyst_warp_table.lua"


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def parse_catalysts() -> dict[int, dict]:
    text = read(ROOT / "modules" / "custom" / "lua" / "augment_catalog.lua")
    out: dict[int, dict] = {}
    # [itemid] = { ... cat = N ... tier = N ... label = '...' }
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", text):
        iid = int(m.group(1))
        body = m.group(2)
        cat = re.search(r"\bcat\s*=\s*(\d+)", body)
        tier = re.search(r"\btier\s*=\s*(\d+)", body)
        label = re.search(r"\blabel\s*=\s*'([^']*)'", body)
        out[iid] = {
            "cat": int(cat.group(1)) if cat else 0,
            "tier": int(tier.group(1)) if tier else 0,
            "label": label.group(1) if label else "?",
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
    # (zoneid,zonetype,'ip',port,'name',...)
    for m in re.finditer(r"VALUES \((\d+),\d+,'[^']*',\d+,'([^']+)'", text):
        out[int(m.group(1))] = m.group(2).replace("_", " ")
    return out


def parse_droplist() -> dict[int, set[int]]:
    """itemId -> set of dropId."""
    text = read(SQL / "mob_droplist.sql")
    out: dict[int, set[int]] = {}
    # (dropId,dropType,groupId,groupRate,itemId,...)
    for m in re.finditer(r"VALUES \((\d+),\d+,\d+,\d+,(\d+),", text):
        drop_id, item_id = int(m.group(1)), int(m.group(2))
        out.setdefault(item_id, set()).add(drop_id)
    return out


def parse_groups() -> dict[int, list[tuple[int, int, str]]]:
    """dropid -> [(groupid, zoneid, mobname)]."""
    text = read(SQL / "mob_groups.sql")
    out: dict[int, list[tuple[int, int, str]]] = {}
    # (groupid,poolid,zoneid,name|NULL,respawn,spawntype,dropid,...)
    rx = re.compile(
        r"VALUES \((\d+),(\d+),(\d+),(?:'([^']*)'|NULL),(\d+),(\d+),(\d+),"
    )
    for m in rx.finditer(text):
        groupid = int(m.group(1))
        zoneid = int(m.group(3))
        name = m.group(4) or "?"
        dropid = int(m.group(7))
        if dropid:
            out.setdefault(dropid, []).append((groupid, zoneid, name))
    return out


def parse_spawns() -> dict[tuple[int, int], list[tuple[int, float, float, float]]]:
    """(zone, groupid) -> [(minLevel, x, y, z)]. zone = (mobid>>12)&0xFFF."""
    text = read(SQL / "mob_spawn_points.sql")
    out: dict[tuple[int, int], list[tuple[int, float, float, float]]] = {}
    # (mobid,spawnslotid,'mobname'|NULL,'polutils'|NULL,groupid,minLevel,maxLevel,x,y,z,rot)
    rx = re.compile(
        r"VALUES \((\d+),\d+,(?:'[^']*'|NULL),(?:'[^']*'|NULL),"
        r"(\d+),(\d+),(\d+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),"
    )
    for m in rx.finditer(text):
        mobid = int(m.group(1))
        groupid = int(m.group(2))
        minlvl = int(m.group(3))
        x, y, z = float(m.group(5)), float(m.group(6)), float(m.group(7))
        zone = (mobid >> 12) & 0xFFF
        out.setdefault((zone, groupid), []).append((minlvl, x, y, z))
    return out


def _placeholder(x: float, y: float, z: float) -> bool:
    return (abs(x) < 0.01 and abs(y) < 0.01 and abs(z) < 0.01) or \
           (abs(x - 1) < 0.01 and abs(y - 1) < 0.01 and abs(z - 1) < 0.01)


def main() -> int:
    catalysts = parse_catalysts()
    item_names = parse_item_names()
    zone_names = parse_zone_names()
    item_drops = parse_droplist()
    drop_groups = parse_groups()
    spawns = parse_spawns()

    rows: dict[int, dict] = {}
    no_coords: list[int] = []
    unresolved: list[int] = []

    for iid, meta in catalysts.items():
        # Gather every (zone, mob, level, coords) this catalyst can drop from.
        cands: list[dict] = []
        info_only: dict | None = None  # zone+mob without spawn coords
        for drop_id in item_drops.get(iid, ()):
            for groupid, zoneid, mobname in drop_groups.get(drop_id, ()):
                pts = spawns.get((zoneid, groupid), [])
                if not pts and info_only is None:
                    info_only = {"zone": zoneid, "mob": mobname.replace("_", " ")}
                for minlvl, x, y, z in pts:
                    cands.append({
                        "zone": zoneid, "mob": mobname.replace("_", " "),
                        "lvl": minlvl, "x": x, "y": y, "z": z,
                        "ph": _placeholder(x, y, z),
                    })
        if not cands:
            if info_only:
                # Has a drop source but the mob is a pop NM with no fixed spawn
                # point. Record zone + mob so !augwarp can still report it.
                no_coords.append(iid)
                rows[iid] = {
                    "item": item_names.get(iid, f"item {iid}"),
                    "label": meta["label"], "cat": meta["cat"], "tier": meta["tier"],
                    "zone": info_only["zone"],
                    "zoneName": zone_names.get(info_only["zone"], f"Zone {info_only['zone']}"),
                    "mob": info_only["mob"], "noWarp": True,
                }
            else:
                unresolved.append(iid)
            continue
        # Prefer real coords over placeholders, then the lowest-level mob.
        cands.sort(key=lambda c: (c["ph"], c["lvl"]))
        best = cands[0]
        rows[iid] = {
            "item": item_names.get(iid, f"item {iid}"),
            "label": meta["label"], "cat": meta["cat"], "tier": meta["tier"],
            "zone": best["zone"], "zoneName": zone_names.get(best["zone"], f"Zone {best['zone']}"),
            "x": best["x"], "y": best["y"], "z": best["z"],
            "mob": best["mob"], "lvl": best["lvl"],
        }

    # Emit Lua.
    lines = [
        "-----------------------------------",
        "-- catalyst_warp_table.lua",
        "-- AUTO-GENERATED by tools/gen_catalyst_warp_table.py -- do not hand-edit.",
        "-- Maps each augment catalyst itemId -> an open-world drop mob + its spawn",
        "-- point, for the !augwarp command. Regenerate after catalog/mob changes.",
        "-----------------------------------",
        "return {",
    ]
    for iid in sorted(rows):
        r = rows[iid]
        item = r["item"].replace("'", "\\'")
        label = r["label"].replace("'", "\\'")
        mob = r["mob"].replace("'", "\\'")
        zn = r["zoneName"].replace("'", "\\'")
        if r.get("noWarp"):
            lines.append(
                f"    [{iid}] = {{ item='{item}', label='{label}', cat={r['cat']}, "
                f"tier={r['tier']}, zone={r['zone']}, zoneName='{zn}', "
                f"mob='{mob}', noWarp=true }},"
            )
        else:
            lines.append(
                f"    [{iid}] = {{ item='{item}', label='{label}', cat={r['cat']}, "
                f"tier={r['tier']}, zone={r['zone']}, zoneName='{zn}', "
                f"x={r['x']:.3f}, y={r['y']:.3f}, z={r['z']:.3f}, mob='{mob}', lvl={r['lvl']} }},"
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
