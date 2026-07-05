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
from tools.docgen._markers import write_between_markers
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
# Augmentation Dungeon catalyst drops (Lua-scripted; NOT in mob_droplists)
# 7 dungeons × (12 trash mobs @ 30% each + boss pool @ ~100%/pool daily).
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

    # -- dungeon_catalog.lua: label + mob names per dungeon key --
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

    # -- augment_dungeon_drops_data.lua: item IDs per dungeon --
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

    # -- build drop entries --
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
# G1 = guaranteed common reward, G2 = rare gear (heavy 0-weight whiff slot).
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

    # Merge Augmentation Dungeon catalyst drops (scripted, absent from
    # mob_droplists).  These ADD to any existing entries for the same item
    # (catalysts are common crafting materials that also drop elsewhere).
    for iid, entries in _dungeon_augment_drops(repo_root).items():
        drops.setdefault(iid, []).extend(entries)

    # Merge remaining scripted drop sources.
    for src in (_htbf_drops, _abyssea_su5_drops, _catalyst_mob_drops,
                _voidwatch_drops):
        for iid, entries in src(repo_root).items():
            drops.setdefault(iid, []).extend(entries)
    for iid, entry in _SEAL_DROPS.items():
        drops.setdefault(iid, []).append(entry)

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

    # Stamp the live coverage counts into item-database.md. The page is otherwise
    # static widget HTML (the data lives in the JSON above), which froze its
    # "Last updated" stamp -- this marker bumps the content hash whenever the item
    # coverage changes AND tells readers the dataset is regenerated every deploy.
    page = docs_dir / "progression" / "item-database.md"
    if page.exists():
        meta = (
            f"**{len(items):,} items** indexed straight from the live server — "
            f"**{n_drop:,}** with drop sources, **{n_use:,}** with system uses. This "
            f"dataset is **rebuilt from the live database on every deploy**, so it always "
            f"reflects the current server (the \"Last updated\" date below tracks the "
            f"page layout, not the data)."
        )
        if write_between_markers(page, "item-database-meta", meta):
            print("[drop_finder] item-database-meta: written")
