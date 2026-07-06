"""Shared item-source computation for the docgen generators.

Both the Item Database (drop_finder.py) and the Gear Finder (gear_finder.py)
need the SAME "where does this item come from" data, so it lives here once and
they both call `collect_drop_sources()` -- they can never drift.

Sources merged (item_id -> [{mob, zone, pct}]):
  * live DB mob_droplist -> mob_groups -> zone_settings         (needs the DB)
  * Hunting League trophy drops       (scripted, catalog Lua)
  * Augmentation Dungeon catalyst drops
  * HTBF armoury-crate loot
  * Abyssea Su5 weapon pool
  * Open-world augment-catalyst mobs
  * Voidwatch Riftworn Pyxis loot
  * GM Home mob seal drops

`collect_drop_sources()` returns (drops, db_available). The scripted sources
are parsed from Lua and need no DB, so they populate even on a laptop/CI; only
the mob_droplist rows require a live connection. Callers that MUST have the DB
(the Item Database page) check the `db_available` flag and skip when False.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._db import connect


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
# ---------------------------------------------------------------------------

_HL_ZONE = "Escha Zi'Tah"

_HL_TROPHY_DROPS: dict[int, dict] = {
    8983: {"mob": "Valkurm Emperor (Hunting League)",    "zone": _HL_ZONE, "pct": 100.0},
    843:  {"mob": "Roc (Hunting League)",                "zone": _HL_ZONE, "pct": 100.0},
    908:  {"mob": "Aquarius (Hunting League)",           "zone": _HL_ZONE, "pct": 100.0},
    1015: {"mob": "Serket (Hunting League)",             "zone": _HL_ZONE, "pct": 100.0},
    909:  {"mob": "Vrtra (Hunting League)",              "zone": _HL_ZONE, "pct": 100.0},
    844:  {"mob": "Simurgh (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},
    1122: {"mob": "Nidhogg (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},
    10037: {"mob": "Nidhogg (Hunting League)",           "zone": _HL_ZONE, "pct": 100.0},
    893:  {"mob": "King Behemoth (Hunting League)",      "zone": _HL_ZONE, "pct": 100.0},
    2893: {"mob": "Kirin (Hunting League)",              "zone": _HL_ZONE, "pct": 100.0},
    1473: {"mob": "Absolute Virtue (Hunting League)",    "zone": _HL_ZONE, "pct": 100.0},
    2371: {"mob": "Pandemonium Warden (Hunting League)", "zone": _HL_ZONE, "pct": 100.0},
    2372: {"mob": "Pandemonium Warden (Hunting League)", "zone": _HL_ZONE, "pct": 100.0},
    1133: {"mob": "Shinryu (Hunting League)",            "zone": _HL_ZONE, "pct": 100.0},
}

_HL_SUFFIX = " (Hunting League)"


# ---------------------------------------------------------------------------
# Augmentation Dungeon catalyst drops (Lua-scripted; NOT in mob_droplists)
# ---------------------------------------------------------------------------

_DUNGEON_TRASH_PCT = 30.0
_LABEL_RE = re.compile(r'''label\s*=\s*(?:"([^"]*)"|'([^']*)')''')
_ROSTER_CLOSE_RE = re.compile(r"\}\s*,\s*(.+)\s*,\s*\d+\s*\)")
_DKEY_RE = re.compile(r"^    (\w+)\s*=\s*$")
_ID_RE = re.compile(r"\bid\s*=\s*(\d+)")
_SLOT_RE = re.compile(r"^\[(\d+)\]")


def _dungeon_augment_drops(repo_root: Path) -> dict[int, list[dict]]:
    """Augmentation Dungeon catalyst drops -> {item_id: [{mob, zone, pct}]}."""
    cat_p = resolve_source(repo_root, "modules/custom/lua/dungeon_catalog.lua")
    drop_p = resolve_source(repo_root, "modules/custom/lua/augment_dungeon_drops_data.lua")
    if not cat_p or not drop_p:
        return {}

    meta: dict[str, dict] = {}
    cur_key: str | None = None
    cur_label: str | None = None
    for line in cat_p.read_text(encoding="utf-8", errors="replace").splitlines():
        s = line.strip()
        km = re.match(r"^(\w+)\s*=$", s)
        if km:
            cur_key = km.group(1)
            cur_label = None
        lm = _LABEL_RE.search(s)
        if lm and cur_key:
            cur_label = lm.group(1) if lm.group(1) is not None else lm.group(2)
        rm = _ROSTER_CLOSE_RE.search(s)
        if rm and cur_key and cur_label:
            parts = [p.strip().strip("'\"") for p in rm.group(1).split(",")]
            if len(parts) == 3:
                meta[cur_key] = {
                    "label": cur_label,
                    "first": parts[0], "second": parts[1], "boss": parts[2],
                }
            cur_key = None

    parsed: dict[str, dict] = {}
    dkey: str | None = None
    section: str | None = None
    for line in drop_p.read_text(encoding="utf-8", errors="replace").splitlines():
        s = line.strip()
        dm = _DKEY_RE.match(line)
        if dm and dm.group(1) in meta:
            dkey = dm.group(1)
            parsed[dkey] = {"trash": [], "boss": []}
            section = None
            continue
        if dkey is None:
            continue
        if s.startswith("trash"):
            section = "trash"
            continue
        if s.startswith("boss"):
            section = "boss"
            continue
        id_m = _ID_RE.search(s)
        if not id_m or section is None:
            continue
        iid = int(id_m.group(1))
        if section == "trash":
            slot_m = _SLOT_RE.match(s)
            parsed[dkey]["trash"].append(
                (int(slot_m.group(1)) if slot_m else 0, iid))
        else:
            parsed[dkey]["boss"].append(iid)

    out: dict[int, list[dict]] = {}
    for key, data in parsed.items():
        info = meta.get(key)
        if not info:
            continue
        zone = info["label"]
        for slot, iid in data["trash"]:
            mob = info["first"] if slot <= 6 else info["second"]
            out.setdefault(iid, []).append({
                "mob": f"{mob} (Dungeon)",
                "zone": zone,
                "pct": _DUNGEON_TRASH_PCT,
            })
        pool = data["boss"]
        if pool:
            boss_pct = round(100.0 / len(pool), 1)
            for iid in pool:
                out.setdefault(iid, []).append({
                    "mob": f"{info['boss']} (Dungeon Boss)",
                    "zone": zone,
                    "pct": boss_pct,
                })
    return out


# ---------------------------------------------------------------------------
# xi.item enum lookup (resolves symbolic names used in HTBF loot tables)
# ---------------------------------------------------------------------------

_ENUM_RE = re.compile(r"^\s+(\w+)\s*=\s*(\d+)")


def _xi_item_enum(repo_root: Path) -> dict[str, int]:
    p = resolve_source(repo_root, "scripts/enum/item.lua")
    if not p:
        return {}
    out: dict[str, int] = {}
    for ln in p.read_text(encoding="utf-8", errors="replace").splitlines():
        m = _ENUM_RE.match(ln)
        if m:
            out[m.group(1)] = int(m.group(2))
    return out


# ---------------------------------------------------------------------------
# HTBF (High-Tier Battlefield) armoury-crate loot
# ---------------------------------------------------------------------------

def _htbf_drops(repo_root: Path) -> dict[int, list[dict]]:
    p = resolve_source(repo_root, "modules/custom/lua/htbf_loot.lua")
    if not p:
        return {}
    enum = _xi_item_enum(repo_root)
    text = p.read_text(encoding="utf-8", errors="replace")

    fights: dict[str, list[tuple[int, int]]] = {}
    fight: str | None = None
    for line in text.splitlines():
        fm = re.match(r"^fightLoot\.(\w+)\s*=", line)
        if fm:
            fight = fm.group(1)
            fights[fight] = []
            continue
        if fight is None:
            continue
        im = re.search(r"itemId\s*=\s*(?:xi\.item\.(\w+)|(\d+))", line)
        wm = re.search(r"weight\s*=\s*(\d+)", line)
        if im and wm:
            iid = enum.get(im.group(1), 0) if im.group(1) else int(im.group(2))
            fights[fight].append((iid, int(wm.group(1))))

    out: dict[int, list[dict]] = {}
    for key, items in fights.items():
        label = key.replace("_", " ").title()
        zero_idx = next(
            (i for i, (iid, _) in enumerate(items) if iid == 0), len(items))
        for group in (items[:zero_idx], items[zero_idx:]):
            total = sum(w for _, w in group)
            if total == 0:
                continue
            for iid, w in group:
                if iid == 0:
                    continue
                out.setdefault(iid, []).append({
                    "mob": f"HTBF: {label}",
                    "zone": "Battlefield",
                    "pct": round(w / total * 100, 1),
                })
    return out


# ---------------------------------------------------------------------------
# Abyssea Su5 weapon drops (5% per kill, 1 random of 22 weapons)
# ---------------------------------------------------------------------------

def _abyssea_su5_drops(repo_root: Path) -> dict[int, list[dict]]:
    p = resolve_source(repo_root, "modules/custom/lua/abyssea_su5_drops.lua")
    if not p:
        return {}
    m = re.search(r"SU5_WEAPONS\s*=\s*\{([^}]+)\}",
                  p.read_text(encoding="utf-8", errors="replace"))
    if not m:
        return {}
    ids = [int(x) for x in re.findall(r"(\d+)", m.group(1))]
    pct = round(5.0 / max(len(ids), 1), 1)
    return {iid: [{"mob": "Any mob (Abyssea)", "zone": "Abyssea",
                    "pct": pct}] for iid in ids}


# ---------------------------------------------------------------------------
# Open-world augment catalyst drops (1:1 mob -> catalyst, 50%)
# ---------------------------------------------------------------------------

_CAT_MOB_RE = re.compile(r"\['([^']+)'\]\s*=\s*(\d+)")


def _catalyst_mob_drops(repo_root: Path) -> dict[int, list[dict]]:
    p = resolve_source(repo_root, "modules/custom/lua/augment_catalyst_mobs.lua")
    if not p:
        return {}
    out: dict[int, list[dict]] = {}
    for m in _CAT_MOB_RE.finditer(
            p.read_text(encoding="utf-8", errors="replace")):
        out.setdefault(int(m.group(2)), []).append({
            "mob": m.group(1).replace("_", " "),
            "zone": "Open World",
            "pct": 50.0,
        })
    return out


# ---------------------------------------------------------------------------
# Voidwatch Riftworn Pyxis loot (quality-tiered: 60% common / 32% unc / 8% rare)
# ---------------------------------------------------------------------------

def _voidwatch_drops(repo_root: Path) -> dict[int, list[dict]]:
    p = resolve_source(repo_root, "modules/custom/lua/voidwatch_catalog.lua")
    if not p:
        return {}
    text = p.read_text(encoding="utf-8", errors="replace")

    def nums(s: str) -> list[int]:
        return [int(x) for x in re.findall(r"\b(\d{3,})\b", s)]

    TIER_PCT = {"common": 60.0, "uncommon": 32.0, "rare": 8.0}
    out: dict[int, list[dict]] = {}

    loot_start = text.find("C.LOOT")
    loot_end = text.find("\nC.", loot_start + 6) if loot_start >= 0 else -1
    if loot_start >= 0:
        block = text[loot_start:(loot_end if loot_end > loot_start else len(text))]
        for tier, base in TIER_PCT.items():
            tm = re.search(rf"{tier}.*?\{{([^}}]+)\}}", block, re.DOTALL)
            if not tm:
                continue
            ids = nums(tm.group(1))
            pct = round(base / max(len(ids), 1), 1)
            for iid in ids:
                out.setdefault(iid, []).append({
                    "mob": "Voidwalker NM", "zone": "Voidwatch",
                    "pct": max(pct, 0.1),
                })

    for m in re.finditer(
            r"(\w+)\s*=\s*\{\s*rare\s*=\s*\{([^}]*)\}", text):
        nm = m.group(1)
        if nm in TIER_PCT:
            continue
        ids = nums(m.group(2))
        if not ids:
            continue
        pct = round(8.0 / len(ids), 1)
        for iid in ids:
            out.setdefault(iid, []).append({
                "mob": f"{nm.replace('_', ' ')} (Voidwatch)",
                "zone": "Voidwatch",
                "pct": max(pct, 0.1),
            })
    return out


# ---------------------------------------------------------------------------
# GM Home mob seal drops (100% from mobs in zone 210)
# ---------------------------------------------------------------------------

_SEAL_DROPS: dict[int, dict] = {
    9539: {"mob": "Any mob",   "zone": "GM Home", "pct": 100.0},
    9541: {"mob": "Lv90+ mob", "zone": "GM Home", "pct": 100.0},
    9543: {"mob": "Lv90+ NM",  "zone": "GM Home", "pct": 100.0},
}


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def collect_drop_sources(repo_root: Path) -> tuple[dict[int, list[dict]], bool]:
    """Return (item_id -> [{mob, zone, pct}], db_available).

    Merges the live-DB mob_droplist rows with every scripted drop source. The
    merge order/dedup matches the historical drop_finder behaviour exactly, so
    the Item Database JSON is byte-for-byte unchanged. When the DB is
    unreachable, db_available is False and only the scripted (Lua-parsed)
    sources are present.
    """
    db = _drops(repo_root)                 # DB rows, or None if unreachable
    db_available = db is not None
    drops: dict[int, list[dict]] = db if db is not None else {}

    # Hunting League trophy drops (scripted, absent from mob_droplists). Remove
    # any mob_droplists entry for the same mob in Escha Zi'Tah first (the zone
    # name may differ between our static string and the DB value, so match on
    # mob name + "escha" substring rather than an exact zone compare).
    for iid, entry in _HL_TROPHY_DROPS.items():
        base_mob = entry["mob"].replace(_HL_SUFFIX, "")
        existing = drops.setdefault(iid, [])
        drops[iid] = [
            d for d in existing
            if not (d["mob"] == base_mob and "escha" in d["zone"].lower())
        ]
        drops[iid].insert(0, entry)

    # Augmentation Dungeon catalyst drops (ADD to any existing entries).
    for iid, entries in _dungeon_augment_drops(repo_root).items():
        drops.setdefault(iid, []).extend(entries)

    # Remaining scripted drop sources.
    for src in (_htbf_drops, _abyssea_su5_drops, _catalyst_mob_drops,
                _voidwatch_drops):
        for iid, entries in src(repo_root).items():
            drops.setdefault(iid, []).extend(entries)
    for iid, entry in _SEAL_DROPS.items():
        drops.setdefault(iid, []).append(entry)

    return drops, db_available
