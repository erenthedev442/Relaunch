"""Generate the Item Database / Drop Finder dataset (docs/assets/item-search-data.json).

Powers the interactive Item Database page (docs/progression/item-database.md +
docs/assets/item-search.js): search any item and see WHERE IT DROPS (mob + zone
+ %) and WHAT IT'S USED FOR (e.g. an Augment Sage catalyst).

Drop data is read from the LIVE DB (mob_droplist -> mob_groups -> zone_settings,
joined to item_basic) via tools/docgen/_db.py -- the only source that reflects
the server's CUSTOM drop tables (e.g. the 100% King Behemoth horn). Like the
leaderboard/player generators, it SKIPS CLEANLY when the DB is unreachable
(CI / a laptop without the live DB) so the previously published JSON survives.
It therefore (re)populates whenever docgen runs on the box (the Azure refresh
cron) -- exactly like the leaderboards.

"Used for" is parsed from the (gitignored, live-only) Lua catalogs, which works
without the DB. Today that's the Augment Sage catalysts; add more sources here.
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._db import connect
from tools.docgen.generators.gear_finder import display_name


# ---------------------------------------------------------------------------
# Item display names  (item_basic.sql short name -> "Proper Name +1")
# ---------------------------------------------------------------------------

# INSERT INTO `item_basic` VALUES (883,0,'behemoth_horn','behemoth_horn',...)
_BASIC_RE = re.compile(r"^INSERT INTO `item_basic` VALUES \((\d+),\d+,'([^']*)'")


def _item_names(repo_root: Path) -> dict[int, str]:
    out: dict[int, str] = {}
    p = resolve_source(repo_root, "sql/item_basic.sql")
    if p is None:
        return out
    for ln in p.read_text(encoding="utf-8", errors="replace").splitlines():
        m = _BASIC_RE.match(ln)
        if m:
            out[int(m.group(1))] = m.group(2)
    return out


# ---------------------------------------------------------------------------
# "Used for" reverse-index from the Lua catalogs (no DB needed)
# ---------------------------------------------------------------------------

# augment_catalog.lua:  [2848] = { augId = 291, ..., label = 'Enfb.mag. skill' },
_AUG_CAT_RE = re.compile(r"\[(\d+)\]\s*=\s*\{[^}]*?\blabel\s*=\s*'([^']+)'")


def _used_for(repo_root: Path) -> dict[int, list[str]]:
    """itemId -> list of human 'used for' tags."""
    uses: dict[int, list[str]] = {}
    p = resolve_source(repo_root, "modules/custom/lua/augment_catalog.lua")
    if p:
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in _AUG_CAT_RE.finditer(text):
            uses.setdefault(int(m.group(1)), []).append(
                f"Augment Sage catalyst — {m.group(2)}")
    return uses


# ---------------------------------------------------------------------------
# Drop sources from the live DB
# ---------------------------------------------------------------------------

_DROP_SQL = """
SELECT d.itemid, g.name AS mob, g.zoneid, z.name AS zone, MAX(d.itemRate) AS rate
FROM mob_droplist d
JOIN mob_groups g       ON g.dropid  = d.dropid
LEFT JOIN zone_settings z ON z.zoneid = g.zoneid
GROUP BY d.itemid, g.name, g.zoneid, z.name
"""


def _drops(repo_root: Path) -> dict[int, list[dict]] | None:
    """itemId -> [{mob, zone, pct}], or None if the DB is unreachable."""
    conn = connect(repo_root)
    if conn is None:
        return None
    raw: dict[int, list[dict]] = {}
    try:
        cur = conn.cursor()
        cur.execute(_DROP_SQL)
        for itemid, mob, zoneid, zone, rate in cur.fetchall():
            raw.setdefault(int(itemid), []).append({
                "mob":  (mob or "").replace("_", " "),
                "zone": (zone.replace("_", " ") if zone else f"Zone {zoneid}"),
                "pct":  round(int(rate) / 10, 1),   # itemRate is out of 1000
            })
        cur.close()
    finally:
        conn.close()
    # Collapse duplicate (mob, zone) rows to their best rate; sort by % desc.
    out: dict[int, list[dict]] = {}
    for iid, drops in raw.items():
        best: dict[tuple, float] = {}
        for d in drops:
            k = (d["mob"], d["zone"])
            if d["pct"] > best.get(k, -1.0):
                best[k] = d["pct"]
        out[iid] = sorted(
            [{"mob": m, "zone": z, "pct": p} for (m, z), p in best.items()],
            key=lambda d: -d["pct"],
        )
    return out


# ---------------------------------------------------------------------------
# Hunting League trophy drops (catalog-scripted; NOT in mob_droplists)
# All 13 Augment Sage affinity catalysts + Khimaira Horn from Pandemonium Warden.
# ---------------------------------------------------------------------------

_HL_ZONE = "Escha Zi'Tah"

# mob label -> base mob name (without suffix) used for dedup against mob_droplists.
# The DB zone name for Escha Zi'Tah varies (e.g. "Escha ZiTah" without apostrophe),
# so we match on mob name + "escha" in zone rather than an exact zone-string compare.
_HL_TROPHY_DROPS: dict[int, dict] = {
    8983: {"mob": "Valkurm Emperor (Hunting League)",    "zone": _HL_ZONE, "pct": 100.0},  # Emperor Arthro's Shell
    843:  {"mob": "Roc (Hunting League)",                "zone": _HL_ZONE, "pct": 100.0},  # Giant Bird Plume
    908:  {"mob": "Aquarius (Hunting League)",           "zone": _HL_ZONE, "pct": 100.0},  # Adamantoise Shell
    1015: {"mob": "Serket (Hunting League)",             "zone": _HL_ZONE, "pct": 100.0},  # Sand Bat Fang
    909:  {"mob": "Vrtra (Hunting League)",              "zone": _HL_ZONE, "pct": 100.0},  # Guivre's Skull
    844:  {"mob": "Simurgh (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},  # Phoenix Feather
    1122: {"mob": "Nidhogg (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},  # Wyvern Skin
    10037: {"mob": "Nidhogg (Hunting League)",           "zone": _HL_ZONE, "pct": 100.0},  # Fafnir's Scale (Augment Sage rank 4)
    893:  {"mob": "King Behemoth (Hunting League)",      "zone": _HL_ZONE, "pct": 100.0},  # Giant Femur
    2893: {"mob": "Kirin (Hunting League)",              "zone": _HL_ZONE, "pct": 100.0},  # Gargantuan Black Tiger Fang
    1473: {"mob": "Absolute Virtue (Hunting League)",    "zone": _HL_ZONE, "pct": 100.0},  # HQ Scorpion Shell
    2371: {"mob": "Pandemonium Warden (Hunting League)", "zone": _HL_ZONE, "pct": 100.0},  # Khimaira Horn
    2372: {"mob": "Pandemonium Warden (Hunting League)", "zone": _HL_ZONE, "pct": 100.0},  # Khimaira Mane
    1133: {"mob": "Shinryu (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},  # Vial of Dragon Blood
}

_HL_SUFFIX = " (Hunting League)"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    drops = _drops(repo_root)
    if drops is None:
        print("[drop_finder] skip: no DB connection (LEGENDARY_LIVE_ROOT unset / "
              "DB unreachable) — leaving item-search-data.json as-is")
        return

    # Merge Hunting League trophy drops (scripted, absent from mob_droplists).
    # Remove any mob_droplists entry for the same mob in Escha Zi'Tah (zone name
    # may differ between our static string and the DB value, so match on mob name
    # + "escha" substring rather than an exact zone compare).
    for iid, entry in _HL_TROPHY_DROPS.items():
        base_mob = entry["mob"].replace(_HL_SUFFIX, "")
        existing = drops.setdefault(iid, [])
        drops[iid] = [
            d for d in existing
            if not (d["mob"] == base_mob and "escha" in d["zone"].lower())
        ]
        drops[iid].insert(0, entry)

    names = _item_names(repo_root)
    uses = _used_for(repo_root)

    # Every item that drops from a mob OR is used for something.
    ids = set(drops) | set(uses)
    items = []
    for iid in sorted(ids):
        short = names.get(iid)
        if not short:
            continue  # no item_basic name -> skip (NPC/internal id)
        items.append({
            "i": iid,
            "n": display_name(short),
            "d": drops.get(iid, []),
            "u": uses.get(iid, []),
        })

    payload = {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "items": items,
    }
    out = docs_dir / "assets" / "item-search-data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")

    n_drop = sum(1 for it in items if it["d"])
    n_use = sum(1 for it in items if it["u"])
    print(f"[drop_finder] wrote {out.name}: {len(items)} items "
          f"({n_drop} with drops, {n_use} with uses, {out.stat().st_size // 1024} KB)")
