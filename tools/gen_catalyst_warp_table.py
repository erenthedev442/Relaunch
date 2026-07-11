#!/usr/bin/env python3
"""Generate modules/custom/lua/catalyst_warp_table.lua for the !augwarp command
AND the website's augment drop locations (tools/docgen/generators/augments.py
reads the generated table, so !augwarp, the site, and the actual drop hook all
describe the SAME mob at the SAME rate).

Source of truth: modules/custom/lua/augment_catalyst_mobs.lua -- the 1:1
mob -> catalyst assignment that augment_catalyst_drops.lua actually rolls at
DROP_RATE (parsed live from that file so the % can't drift). The pre-2026-07-10
generator resolved mobs from mob_droplist (live DB / SQL) instead -- i.e. the
BASE game droplists, which are NOT where the custom 60% drops come from --
so !augwarp warped players to mobs that only shed the item silently through
vanilla treasure pools. Base droplists are no longer consulted at all.

Spawn coordinates come from mob_spawn_points.sql looked up by MOBNAME (what
mob:getName() returns, i.e. what the drop hook matches). NM groups are
excluded (the drop hook skips NMs). NOTE: names/polutils names may contain
escaped apostrophes ('Aern\\'s Elemental') -- the row regexes must stay
escape-aware or those rows silently vanish (the old generator had exactly
that bug and lost every spawn row with an apostrophed polutils name).

Candidate order per catalyst: land over boats/airships (never strand the
player mid-ocean), real coords over placeholder (0,0,0 / 1,1,1), lowest
minLevel (accessibility), Abyssea zones breaking ties (denser spawns).
A catalyst with TWO mapped mobs keeps the runner-up as altMob/altZone so the
website can list both; !augwarp ignores the alt fields.

Run:  python tools/gen_catalyst_warp_table.py     (cwd = repo root)
Regenerate whenever augment_catalyst_mobs.lua, augment_catalog.lua, or
mob spawn data changes, then re-run tools/docgen and commit BOTH outputs.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL  = ROOT / "sql"
LUA  = ROOT / "modules" / "custom" / "lua"
OUT  = LUA / "catalyst_warp_table.lua"

# Lua single-quoted string body, escape-aware ('Aern\'s Elemental').
_QSTR = r"'((?:[^'\\]|\\.)*)'"


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def lua_unescape(s: str) -> str:
    return s.replace("\\'", "'").replace("\\\\", "\\")


# ---------------------------------------------------------------------------
# Custom-module parsers (the actual drop system)
# ---------------------------------------------------------------------------

def parse_catalysts() -> dict[int, dict]:
    """augment_catalog.lua: itemId -> {cat, tier, label}."""
    text = read(LUA / "augment_catalog.lua")
    out: dict[int, dict] = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", text):
        iid  = int(m.group(1))
        body = m.group(2)
        cat   = re.search(r"\bcat\s*=\s*(\d+)", body)
        tier  = re.search(r"\btier\s*=\s*(\d+)", body)
        label = re.search(r"\blabel\s*=\s*" + _QSTR, body)
        out[iid] = {
            "cat":   int(cat.group(1))   if cat   else 0,
            "tier":  int(tier.group(1))  if tier  else 0,
            "label": lua_unescape(label.group(1)) if label else "?",
        }
    return out


def parse_mob_map() -> dict[int, list[str]]:
    """augment_catalyst_mobs.lua: itemId -> [mob internal name, ...]."""
    text = read(LUA / "augment_catalyst_mobs.lua")
    out: dict[int, list[str]] = {}
    for m in re.finditer(r"\[" + _QSTR + r"\]\s*=\s*(\d+)\s*,", text):
        out.setdefault(int(m.group(2)), []).append(lua_unescape(m.group(1)))
    return out


def parse_drop_rate() -> int:
    """DROP_RATE (%) from augment_catalyst_drops.lua -- the mapped-mob roll.
    Parsed live so a balance retune can't leave the warp table / site stale."""
    text = read(LUA / "augment_catalyst_drops.lua")
    m = re.search(r"^local\s+DROP_RATE\s*=\s*(\d+)", text, re.MULTILINE)
    if not m:
        raise RuntimeError("DROP_RATE not found in augment_catalyst_drops.lua")
    return int(m.group(1))


# ---------------------------------------------------------------------------
# Static SQL parsers
# ---------------------------------------------------------------------------

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


def parse_nm_pools() -> set[int]:
    """poolids with mobType & 2 (NM). mobType is the 10th numeric field after
    the 0x... modelid blob."""
    text = read(SQL / "mob_pools.sql")
    out: set[int] = set()
    for m in re.finditer(
        r"VALUES \((\d+),(?:" + _QSTR + r"|NULL),(?:" + _QSTR + r"|NULL),"
        r"\d+,0x[0-9A-Fa-f]+,(?:\d+,){9}(\d+),", text
    ):
        if int(m.group(4)) & 2:
            out.add(int(m.group(1)))
    return out


def parse_group_pools() -> dict[tuple[int, int], int]:
    """(zoneid, groupid) -> poolid, from mob_groups.sql."""
    text = read(SQL / "mob_groups.sql")
    out: dict[tuple[int, int], int] = {}
    rx = re.compile(r"VALUES \((\d+),(\d+),(\d+),(?:" + _QSTR + r"|NULL),")
    for m in rx.finditer(text):
        out[(int(m.group(3)), int(m.group(1)))] = int(m.group(2))
    return out


def parse_spawns_by_name() -> dict[str, list[dict]]:
    """mobname -> [{zone, groupid, lvl, x, y, z}].  zone = (mobid>>12)&0xFFF.
    Keyed by the mobname column = mob:getName() = what the drop hook matches."""
    text = read(SQL / "mob_spawn_points.sql")
    out: dict[str, list[dict]] = {}
    rx = re.compile(
        r"VALUES \((\d+),\d+,(?:" + _QSTR + r"|NULL),(?:" + _QSTR + r"|NULL),"
        r"(\d+),(\d+),(\d+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),"
    )
    for m in rx.finditer(text):
        mobid = int(m.group(1))
        name  = lua_unescape(m.group(2) or "?")
        out.setdefault(name, []).append({
            "zone":    (mobid >> 12) & 0xFFF,
            "groupid": int(m.group(4)),
            "lvl":     int(m.group(5)),
            "x": float(m.group(7)), "y": float(m.group(8)), "z": float(m.group(9)),
        })
    return out


def _placeholder(x: float, y: float, z: float) -> bool:
    return (abs(x) < 0.01 and abs(y) < 0.01 and abs(z) < 0.01) or \
           (abs(x - 1) < 0.01 and abs(y - 1) < 0.01 and abs(z - 1) < 0.01)


# Abyssea zones win ties (denser spawns = better farming) but never beat
# accessibility (a lower-level spawn of the same mob wins).
ABYSSEA_ZONES: frozenset[int] = frozenset({15, 45, 132, 215, 216, 217, 218, 253, 254, 255})

# Boats, barges and airships (zone_settings ids). Warping a player onto a
# moving transport strands them until it docks — only pick one of these when
# no land-based spawn of the mob exists.
TRANSPORT_ZONES: frozenset[int] = frozenset({1, 3, 46, 47, 58, 59, 220, 221, 223, 224, 225, 226, 227, 228})

# Manual warp-destination overrides, keyed by itemId: {zone, zoneName, x, y, z}.
# Replaces ONLY the destination coords of the auto-resolved entry (mob/rate
# stay authoritative). Currently empty -- the pre-2026-07-10 override for 861
# targeted the OLD droplist mob's zone and would now warp away from the mob
# that actually drops the catalyst.
WARP_OVERRIDES: dict[int, dict] = {}


def main() -> int:
    catalysts   = parse_catalysts()
    mob_map     = parse_mob_map()
    drop_rate   = parse_drop_rate()          # percent
    rate_1000   = drop_rate * 10             # table stores rate out of 1000
    item_names  = parse_item_names()
    zone_names  = parse_zone_names()
    nm_pools    = parse_nm_pools()
    group_pools = parse_group_pools()
    spawns      = parse_spawns_by_name()

    print(f"[catalyst_warp] source: augment_catalyst_mobs.lua "
          f"({sum(len(v) for v in mob_map.values())} mob assignments, "
          f"DROP_RATE={drop_rate}%)")

    def spawn_key(pt: dict) -> tuple:
        return (
            1 if pt["zone"] in TRANSPORT_ZONES else 0,
            _placeholder(pt["x"], pt["y"], pt["z"]),
            pt["lvl"],
            0 if pt["zone"] in ABYSSEA_ZONES else 1,
        )

    def best_spawn(mob: str) -> dict | None:
        """Most accessible non-NM spawn point for a mob name."""
        cands = []
        for pt in spawns.get(mob, []):
            pool = group_pools.get((pt["zone"], pt["groupid"]))
            if pool is None or pool in nm_pools:
                continue
            cands.append(pt)
        if not cands:
            return None
        cands.sort(key=spawn_key)
        return cands[0]

    rows: dict[int, dict] = {}
    unresolved: list[int] = []
    ghost_mobs: list[str] = []

    for iid, meta in sorted(catalysts.items()):
        picks = []
        for mob in mob_map.get(iid, []):
            pt = best_spawn(mob)
            if pt is None:
                ghost_mobs.append(mob)
                continue
            picks.append((mob, pt))
        if not picks:
            unresolved.append(iid)
            continue
        # Primary = most accessible mapped mob; runner-up kept for the site.
        picks.sort(key=lambda p: spawn_key(p[1]))
        mob, pt = picks[0]
        ov = WARP_OVERRIDES.get(iid, {})
        row = {
            "item": item_names.get(iid, f"item {iid}"),
            "label": meta["label"], "cat": meta["cat"], "tier": meta["tier"],
            "zone":     ov.get("zone",     pt["zone"]),
            "zoneName": ov.get("zoneName", zone_names.get(pt["zone"], f"Zone {pt['zone']}")),
            "x": ov.get("x", pt["x"]), "y": ov.get("y", pt["y"]), "z": ov.get("z", pt["z"]),
            "mob": mob.replace("_", " "), "lvl": pt["lvl"],
            "rate": rate_1000,
        }
        if len(picks) > 1:
            alt_mob, alt_pt = picks[1]
            row["altMob"]  = alt_mob.replace("_", " ")
            row["altZone"] = zone_names.get(alt_pt["zone"], f"Zone {alt_pt['zone']}")
        rows[iid] = row

    # Emit Lua.
    lines = [
        "-----------------------------------",
        "-- catalyst_warp_table.lua",
        "-- AUTO-GENERATED by tools/gen_catalyst_warp_table.py -- do not hand-edit.",
        "-- Maps each augment catalyst itemId -> the mob ASSIGNED to drop it in",
        "-- augment_catalyst_mobs.lua (rolled at DROP_RATE by",
        "-- augment_catalyst_drops.lua) + that mob's most accessible spawn point.",
        "-- Consumed by the !augwarp command AND tools/docgen/generators/augments.py",
        "-- (the website's drop locations), so all player-facing surfaces agree.",
        "-- rate field is the drop chance out of 1000 (divide by 10 for %).",
        "-- altMob/altZone: second assigned mob when a catalyst has two sources.",
        "-----------------------------------",
        "return {",
    ]

    def q(s: str) -> str:
        return s.replace("\\", "\\\\").replace("'", "\\'")

    for iid in sorted(rows):
        r = rows[iid]
        alt = ""
        if "altMob" in r:
            alt = f", altMob='{q(r['altMob'])}', altZone='{q(r['altZone'])}'"
        lines.append(
            f"    [{iid}] = {{ item='{q(r['item'])}', label='{q(r['label'])}', "
            f"cat={r['cat']}, tier={r['tier']}, "
            f"zone={r['zone']}, zoneName='{q(r['zoneName'])}', "
            f"x={r['x']:.3f}, y={r['y']:.3f}, z={r['z']:.3f}, "
            f"mob='{q(r['mob'])}', lvl={r['lvl']}, rate={r['rate']}{alt} }},"
        )
    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[catalyst_warp] catalysts={len(catalysts)} resolved={len(rows)} "
          f"unresolved={len(unresolved)}")
    if ghost_mobs:
        print(f"[catalyst_warp] WARN mapped mobs with no usable spawn: {sorted(set(ghost_mobs))}")
    if unresolved:
        print(f"[catalyst_warp] WARN unresolved catalysts (no mapped mob with a "
              f"non-NM spawn -- fix augment_catalyst_mobs.lua): {unresolved}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
