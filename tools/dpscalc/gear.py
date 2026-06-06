"""Gear + augment loading and mod aggregation.

Everything here reads the LIVE xidb database (authoritative -- it already
includes the locally-imported custom "naked" stats that exist only in
sql/zz_custom_naked_item_mods.sql before import).

Augment decoding is validated against real char_inventory blobs:
  char_inventory.extra is a 24-byte Exdata::AugmentStandard struct --
    byte 0      : AugmentKind  flags
    byte 1      : AugmentSubKind flags
    bytes 2..11 : 5 x uint16 LE augments  (Id = bits 0..10, Value = bits 11..15)
    bytes 12..23: signature
Each decoded augment {Id, Value(0..31)} maps through the `augments` table
(one Id may yield several mod rows). Final magnitude per row, mirroring
src/map/items/item_equipment.cpp SetAugmentMod():
    v = (tableValue > 0 ? tableValue + Value : tableValue - Value)
        * (multiplier > 1 ? multiplier : 1)
"""
from __future__ import annotations

from dataclasses import dataclass, field
from functools import lru_cache

# Equipment slot ids as stored in char_equip.slotid (0..15).
SLOT_NAMES = {
    0: "main", 1: "sub", 2: "range", 3: "ammo",
    4: "head", 5: "body", 6: "hands", 7: "legs", 8: "feet",
    9: "neck", 10: "waist", 11: "ear1", 12: "ear2",
    13: "ring1", 14: "ring2", 15: "back",
}
SLOT_IDS = {v: k for k, v in SLOT_NAMES.items()}

# item_weapon.skill -> weapon category label (subset; matches score_weapons.py).
WEAPON_SKILL = {
    0: "(none)", 1: "Hand-to-Hand", 2: "Dagger", 3: "Sword", 4: "Great Sword",
    5: "Axe", 6: "Great Axe", 7: "Scythe", 8: "Polearm", 9: "Katana",
    10: "Great Katana", 11: "Club", 12: "Staff", 25: "Archery", 26: "Marksmanship",
}

# Two-handed weapon skill types (drive STR->Att ratio = 1.0 and TWOHAND_* mods).
TWOHAND_SKILLS = {4, 6, 7, 8, 10, 12}  # GSword, GAxe, Scythe, Polearm, GKatana, Staff
H2H_SKILL = 1


@dataclass
class ItemInfo:
    item_id: int
    name: str
    slot_mask: int          # item_equipment.slot bitmask
    jobs: int               # job bitmask
    level: int
    ilevel: int
    is_weapon: bool = False
    skill: int = 0          # weapon skill type
    dmg: int = 0            # base weapon DMG
    delay: int = 0          # base weapon delay
    hit: int = 0            # weapon hits (kraken club etc.)


# ----------------------------------------------------------------------------
# Augment table (loaded once)
# ----------------------------------------------------------------------------
_aug_cache: dict[int, list[dict]] | None = None


def _augment_table(conn) -> dict[int, list[dict]]:
    global _aug_cache
    if _aug_cache is None:
        cur = conn.cursor()
        cur.execute(
            "SELECT augmentId, multiplier, modId, value, isPet, petType FROM augments"
        )
        table: dict[int, list[dict]] = {}
        for r in cur.fetchall():
            table.setdefault(r["augmentId"], []).append(r)
        _aug_cache = table
    return _aug_cache


def decode_augments(extra: bytes | None) -> list[tuple[int, int]]:
    """Return [(augmentId, value0_31), ...] for the populated augment slots."""
    if not extra or len(extra) < 12:
        return []
    out = []
    for i in range(5):
        lo = extra[2 + i * 2]
        hi = extra[3 + i * 2]
        raw = lo | (hi << 8)
        if raw == 0:
            continue
        out.append((raw & 0x7FF, (raw >> 11) & 0x1F))
    return out


def augment_mods(conn, extra: bytes | None) -> dict[int, int]:
    """modId -> summed value contributed by this item's standard augments
    (player mods only; pet-augment rows are skipped)."""
    mods: dict[int, int] = {}
    table = _augment_table(conn)
    for aug_id, value in decode_augments(extra):
        for row in table.get(aug_id, []):
            if row["isPet"]:
                continue
            mod_id = row["modId"]
            if mod_id == 0:  # Mod::NONE -> unimplemented, skipped by engine
                continue
            base = row["value"]
            mult = row["multiplier"]
            mag = (base + value if base > 0 else base - value) * (mult if mult > 1 else 1)
            mods[mod_id] = mods.get(mod_id, 0) + mag
    return mods


# ----------------------------------------------------------------------------
# Item base mods + item info
# ----------------------------------------------------------------------------
@lru_cache(maxsize=None)
def _item_base_mods_cached(conn_id: int, item_id: int) -> tuple[tuple[int, int], ...]:
    # conn_id only participates in the cache key; the real conn comes via _conn.
    conn = _conn_registry[conn_id]
    cur = conn.cursor()
    cur.execute("SELECT modId, value FROM item_mods WHERE itemId=%s", (item_id,))
    mods: dict[int, int] = {}
    for r in cur.fetchall():
        if r["modId"] == 0:
            continue
        mods[r["modId"]] = mods.get(r["modId"], 0) + r["value"]
    return tuple(sorted(mods.items()))


_conn_registry: dict[int, object] = {}


def _register(conn) -> int:
    cid = id(conn)
    _conn_registry[cid] = conn
    return cid


def item_base_mods(conn, item_id: int) -> dict[int, int]:
    """modId -> value from item_mods (base/innate item modifiers)."""
    return dict(_item_base_mods_cached(_register(conn), item_id))


def item_total_mods(conn, item_id: int, extra: bytes | None = None) -> dict[int, int]:
    """Base item mods + decoded augment mods, summed by modId."""
    mods = item_base_mods(conn, item_id)
    if extra:
        for mid_, v in augment_mods(conn, extra).items():
            mods[mid_] = mods.get(mid_, 0) + v
    return mods


@lru_cache(maxsize=None)
def _item_info_cached(conn_id: int, item_id: int) -> ItemInfo | None:
    conn = _conn_registry[conn_id]
    cur = conn.cursor()
    cur.execute(
        "SELECT itemId, name, level, ilevel, jobs, slot FROM item_equipment WHERE itemId=%s",
        (item_id,),
    )
    e = cur.fetchone()
    if not e:
        return None
    info = ItemInfo(
        item_id=item_id, name=e["name"], slot_mask=e["slot"], jobs=e["jobs"],
        level=e["level"], ilevel=e["ilevel"],
    )
    cur.execute(
        "SELECT skill, dmg, delay, hit FROM item_weapon WHERE itemId=%s", (item_id,)
    )
    w = cur.fetchone()
    if w:
        info.is_weapon = True
        info.skill = w["skill"]
        info.dmg = w["dmg"]
        info.delay = w["delay"]
        info.hit = w["hit"]
    return info


def item_info(conn, item_id: int) -> ItemInfo | None:
    return _item_info_cached(_register(conn), item_id)


# ----------------------------------------------------------------------------
# Character equipped gear
# ----------------------------------------------------------------------------
@dataclass
class EquippedSlot:
    slot_id: int
    item_id: int
    extra: bytes


def equipped_items(conn, charid: int) -> dict[int, EquippedSlot]:
    """slot_id (0..15, the EQUIPMENT slot) -> EquippedSlot for the char.

    char_equip.equipslotid is the equipment slot (0=main..15=back); the item
    itself lives in container `containerid` at inventory index `slotid`.
    """
    cur = conn.cursor()
    cur.execute(
        """
        SELECT ce.equipslotid AS slot_id, ci.itemId AS item_id, ci.extra AS extra
        FROM char_equip ce
        JOIN char_inventory ci
          ON ci.charid = ce.charid
         AND ci.location = ce.containerid
         AND ci.slot = ce.slotid
        WHERE ce.charid = %s
        ORDER BY ce.equipslotid
        """,
        (charid,),
    )
    out: dict[int, EquippedSlot] = {}
    for r in cur.fetchall():
        if not r["item_id"]:
            continue
        extra = bytes(r["extra"]) if r["extra"] else b""
        out[r["slot_id"]] = EquippedSlot(r["slot_id"], r["item_id"], extra)
    return out


def gear_set_mods(conn, slots: dict[int, EquippedSlot]) -> dict[int, int]:
    """Total mod contribution of a whole equipped set (base + augments)."""
    total: dict[int, int] = {}
    for slot in slots.values():
        for mid_, v in item_total_mods(conn, slot.item_id, slot.extra).items():
            total[mid_] = total.get(mid_, 0) + v
    return total


def inventory_candidates(conn, charid: int, job_id: int,
                         slot_ids: set[int] | None = None
                         ) -> dict[int, list[EquippedSlot]]:
    """For each equipment slot, the distinct owned items the char's main job can
    equip there (item_id + augment extra).

    Scans every container the char owns. Filtering mirrors the server's equip
    check (charutils.cpp:3454): usable by job J if jobs & (1<<(J-1)); equippable
    in slot S if slot_mask & (1<<S). Deduped by (item_id, extra) so identical
    copies collapse while differently-augmented copies stay separate.
    """
    cur = conn.cursor()
    cur.execute(
        "SELECT DISTINCT itemId, extra FROM char_inventory "
        "WHERE charid=%s AND itemId>0",
        (charid,),
    )
    rows = cur.fetchall()
    out: dict[int, list[EquippedSlot]] = {}
    for r in rows:
        info = item_info(conn, r["itemId"])
        if not info or not (info.jobs & (1 << (job_id - 1))):
            continue
        extra = bytes(r["extra"]) if r["extra"] else b""
        for slot_id in range(16):
            if slot_ids is not None and slot_id not in slot_ids:
                continue
            if info.slot_mask & (1 << slot_id):
                out.setdefault(slot_id, []).append(
                    EquippedSlot(slot_id, r["itemId"], extra))
    return out
