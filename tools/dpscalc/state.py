"""Anchored-delta reconstruction of a candidate gear set's FINAL combat stats.

The `!mystats` anchor (anchor.py) gives the engine's final numbers for the set
the player currently has equipped -- captured UNBUFFED and WITHOUT FOOD so the
ATT/ACC decomposition below stays linear. This module turns that anchor plus a
*candidate* gear set into the candidate's final combat stats, without re-running
the engine, by applying DB-sourced gear-mod deltas.

Decomposition (verified against src/map/entities/battleentity.cpp):

  ATT(slot)  = max(1, core + core*ATTP/100)          [integer ops]
      core   = 8 + mod[ATT] + floor(STR*strMult) + GetSkill + iLvlSkill
    -> core is recovered from the anchor by inverting the ATTP multiplier, then
       re-based by swapping in the candidate's mod[ATT] and floor(STR*strMult).

  ACC(0)     = GetAccFromSkill(skill) + floor(DEX*dexMult) + mod[ACC] + meritACC
    -> purely additive: candidate ACC = anchor ACC + Dmod[ACC] + D floor(DEX*dexMult).

  Wpn dmg    = weaponBaseDmg + weapon.DMG_RATING + entity.MAIN_DMG_RATING
  Wrank      = (weaponBaseDmg + entity.MAIN_DMG_RATING + weapon.MAIN_DMG_RANK
               [+3 H2H PC]) // 9         (weapon DMG_RATING cancels in rank)

Everything else `!mystats` shows (crit, multi-attack, haste, DW, Store TP, WS
dmg) is a pure getMod() total, so the candidate value is just the candidate
set's gear-mod total for that id.

Scope (v1): the weapon (main + sub) is FIXED across candidates -- only armor and
accessories are swapped -- which keeps strMult/skill/weapon-base constant. A
weapon swap needs a fresh `!mystats` anchor with that weapon equipped.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from . import gear
from .anchor import Anchor
from .gameconf import CONF
from .mods import name_to_id

# ---------------------------------------------------------------------------
# Mod ids (resolved once against scripts/enum/mod.lua)
# ---------------------------------------------------------------------------
_M = name_to_id()
MID = {
    n: _M[n]
    for n in (
        "ATT", "ATTP", "ACC",
        "STR", "DEX", "VIT", "AGI", "INT", "MND", "CHR",
        "CRITHITRATE", "CRIT_DMG_INCREASE",
        "DOUBLE_ATTACK", "TRIPLE_ATTACK", "QUAD_ATTACK",
        "HASTE_GEAR", "HASTE_MAGIC", "HASTE_ABILITY",
        "DUAL_WIELD", "STORETP", "TP_BONUS",
        "ALL_WSDMG_ALL_HITS", "ALL_WSDMG_FIRST_HIT",
        "ANY_FTP_BONUS", "WSACC",
        "MAIN_DMG_RATING", "SUB_DMG_RATING", "DMG_RATING",
        "MAIN_DMG_RANK", "SUB_DMG_RANK",
        "WEAPONSKILL_DAMAGE_BASE",
    )
}
# SMITE adds to ATTP for 2H/H2H but is weapon-fixed in v1; include it so the
# anchor inversion is exact when the equipped weapon happens to carry it.
_SMITE_ID = _M.get("SMITE")


# ---------------------------------------------------------------------------
# Fixed-weapon context
# ---------------------------------------------------------------------------
@dataclass
class WeaponCtx:
    main_skill: int
    main_base_dmg: int
    main_dmg_rank_mod: int
    main_delay: int
    main_hit: int
    is_2h: bool
    is_h2h: bool
    has_offhand: bool = False
    sub_skill: int = 0
    sub_base_dmg: int = 0
    sub_own_dmg_rating: int = 0
    sub_dmg_rank_mod: int = 0
    sub_delay: int = 0
    str_mult_main: float = 0.75
    str_mult_sub: float = 0.5
    dex_mult_main: float = 0.75
    dex_mult_sub: float = 0.75
    skill_main: int = 0
    skill_sub: int = 0

    @property
    def is_2h_or_h2h(self) -> bool:
        return self.is_2h or self.is_h2h


def _char_skills(conn, charid: int) -> dict[int, int]:
    cur = conn.cursor()
    cur.execute("SELECT skillid, value FROM char_skills WHERE charid=%s", (charid,))
    return {r["skillid"]: r["value"] for r in cur.fetchall()}


def resolve_weapon_ctx(conn, charid: int,
                       slots: dict[int, gear.EquippedSlot]) -> WeaponCtx:
    """Resolve the fixed main/sub weapon context from the equipped set."""
    main = slots.get(gear.SLOT_IDS["main"])
    if main is None:
        raise ValueError("no main weapon equipped; cannot build a melee anchor")
    minfo = gear.item_info(conn, main.item_id)
    if minfo is None or not minfo.is_weapon:
        raise ValueError("main-slot item is not a weapon")

    main_skill = minfo.skill
    is_2h = main_skill in gear.TWOHAND_SKILLS
    is_h2h = main_skill == gear.H2H_SKILL
    main_mods = gear.item_total_mods(conn, main.item_id, main.extra)
    skills = _char_skills(conn, charid)

    ctx = WeaponCtx(
        main_skill=main_skill,
        main_base_dmg=minfo.dmg,
        main_dmg_rank_mod=main_mods.get(MID["MAIN_DMG_RANK"], 0),
        main_delay=minfo.delay,
        main_hit=max(1, minfo.hit or 1),
        is_2h=is_2h, is_h2h=is_h2h,
        skill_main=skills.get(main_skill, 0),
    )

    if is_2h:
        ctx.str_mult_main, ctx.dex_mult_main = CONF.str_mult_2h, CONF.dex_mult_2h
    elif is_h2h:
        ctx.str_mult_main, ctx.dex_mult_main = CONF.str_mult_h2h, CONF.dex_mult_h2h
    else:
        ctx.str_mult_main = CONF.str_mult_1h_main
        ctx.dex_mult_main = CONF.dex_mult_1h_main

    if is_h2h:
        # H2H swings twice per round off the same fists -- mirror the main hand.
        ctx.has_offhand = True
        ctx.sub_skill = main_skill
        ctx.sub_base_dmg = minfo.dmg
        ctx.sub_dmg_rank_mod = ctx.main_dmg_rank_mod
        ctx.sub_delay = minfo.delay
        ctx.str_mult_sub, ctx.dex_mult_sub = ctx.str_mult_main, ctx.dex_mult_main
        ctx.skill_sub = ctx.skill_main
    else:
        sub = slots.get(gear.SLOT_IDS["sub"])
        sinfo = gear.item_info(conn, sub.item_id) if sub else None
        if sinfo and sinfo.is_weapon and sinfo.skill:
            sub_mods = gear.item_total_mods(conn, sub.item_id, sub.extra)
            ctx.has_offhand = True
            ctx.sub_skill = sinfo.skill
            ctx.sub_base_dmg = sinfo.dmg
            ctx.sub_own_dmg_rating = sub_mods.get(MID["DMG_RATING"], 0)
            ctx.sub_dmg_rank_mod = sub_mods.get(MID["MAIN_DMG_RANK"], 0)  # GetSubWeaponRank reads MAIN_DMG_RANK
            ctx.sub_delay = sinfo.delay
            ctx.str_mult_sub = CONF.str_mult_1h_sub
            ctx.dex_mult_sub = CONF.dex_mult_1h_sub
            ctx.skill_sub = skills.get(sinfo.skill, 0)
    return ctx


# ---------------------------------------------------------------------------
# Reconstructed combat stats for one candidate set
# ---------------------------------------------------------------------------
@dataclass
class CombatStats:
    stats: dict[str, int]
    att: int
    acc: int
    sub_att: int
    sub_acc: int
    main_dmg: int
    main_dmg_for_rank: int
    sub_dmg: int
    sub_dmg_for_rank: int
    crit_rate_mod: int
    crit_dmg: int
    da: int
    ta: int
    qa: int
    haste_gear: int
    haste_magic: int
    haste_ability: int
    dual_wield: int
    store_tp: int
    tp_bonus: int
    ws_dmg_all: int
    ws_dmg_first: int
    gear_ftp: float = 0.0   # ANY_FTP_BONUS/256: WS fTP bonus from gear (Fotia)
    ws_acc: int = 0         # WSACC: extra accuracy on every WS hit
    gear_mods: dict[int, int] = field(default_factory=dict)
    wctx: WeaponCtx | None = None

    def ws_dmg_for(self, ws_id: int) -> int:
        """Per-WS WEAPONSKILL_DAMAGE_BASE+id gear bonus (0 if none)."""
        return self.gear_mods.get(MID["WEAPONSKILL_DAMAGE_BASE"] + ws_id, 0)


def _floor_mul(stat: int, mult: float) -> int:
    return math.floor(stat * mult)


def _attp_of(set_mods: dict[int, int], is_2h_or_h2h: bool) -> int:
    attp = set_mods.get(MID["ATTP"], 0)
    if is_2h_or_h2h and _SMITE_ID is not None:
        attp += int(set_mods.get(_SMITE_ID, 0) / 256.0 * 100)
    return attp


def _core_from_final_att(final_att: int, attp: int) -> int:
    """Invert `final = core + core*attp//100` for the integer core (ATTP>=0)."""
    if attp <= 0:
        return final_att
    est = max(1, round(final_att / (1.0 + attp / 100.0)))
    for c in range(max(1, est - 4), est + 5):
        if c + (c * attp) // 100 == final_att:
            return c
    return est


def _final_att(core: int, attp: int) -> int:
    return max(1, core + (core * attp) // 100)


def build_combat_stats(anchor: Anchor, equipped_mods: dict[int, int],
                       cand_mods: dict[int, int], wctx: WeaponCtx) -> CombatStats:
    """Reconstruct a candidate set's final combat stats from the anchor.

    equipped_mods : gear-mod totals of the set the anchor was captured in.
    cand_mods     : gear-mod totals of the candidate set being evaluated.
    Passing equipped_mods as cand_mods reproduces the anchor exactly (self-test).
    """
    def delta(mod_id: int) -> int:
        return cand_mods.get(mod_id, 0) - equipped_mods.get(mod_id, 0)

    stats = {st: anchor.stats.get(st, 0) + delta(MID[st])
             for st in ("STR", "DEX", "VIT", "AGI", "INT", "MND", "CHR")}
    str_a, dex_a = anchor.stats.get("STR", 0), anchor.stats.get("DEX", 0)
    str_c, dex_c = stats["STR"], stats["DEX"]

    two = wctx.is_2h_or_h2h
    attp_a = _attp_of(equipped_mods, two)
    attp_c = _attp_of(cand_mods, two)
    core_a = _core_from_final_att(anchor.att, attp_a)

    # main hand
    core_c = (core_a + delta(MID["ATT"])
              + _floor_mul(str_c, wctx.str_mult_main)
              - _floor_mul(str_a, wctx.str_mult_main))
    att = _final_att(core_c, attp_c)
    acc = (anchor.acc + delta(MID["ACC"])
           + _floor_mul(dex_c, wctx.dex_mult_main)
           - _floor_mul(dex_a, wctx.dex_mult_main))

    # offhand (re-base the recovered core onto the sub strMult/skill)
    sub_att = sub_acc = 0
    if wctx.has_offhand:
        core_sub_a = (core_a
                      - _floor_mul(str_a, wctx.str_mult_main) - wctx.skill_main
                      + _floor_mul(str_a, wctx.str_mult_sub) + wctx.skill_sub)
        core_sub_c = (core_sub_a + delta(MID["ATT"])
                      + _floor_mul(str_c, wctx.str_mult_sub)
                      - _floor_mul(str_a, wctx.str_mult_sub))
        sub_att = _final_att(core_sub_c, attp_c)
        # ACC differs only by dexMult (skill-from-skill diff ~ 0 for like weapons)
        sub_acc = (acc
                   - _floor_mul(dex_c, wctx.dex_mult_main)
                   + _floor_mul(dex_c, wctx.dex_mult_sub))

    # weapon damage / rank
    main_dmg = anchor.wpn_dmg + delta(MID["MAIN_DMG_RATING"])
    main_dmg_for_rank = (wctx.main_base_dmg
                         + cand_mods.get(MID["MAIN_DMG_RATING"], 0)
                         + wctx.main_dmg_rank_mod)
    sub_dmg = sub_dmg_for_rank = 0
    if wctx.has_offhand:
        if wctx.is_h2h:
            sub_dmg, sub_dmg_for_rank = main_dmg, main_dmg_for_rank
        else:
            sub_dmg = (wctx.sub_base_dmg + wctx.sub_own_dmg_rating
                       + cand_mods.get(MID["SUB_DMG_RATING"], 0))
            sub_dmg_for_rank = (wctx.sub_base_dmg
                                + cand_mods.get(MID["SUB_DMG_RATING"], 0)
                                + wctx.sub_dmg_rank_mod)

    # Pure getMod() totals: the anchor captured each as gear + traits + merits +
    # JP (unbuffed), so the candidate value is anchor + gear-delta -- NOT the raw
    # candidate gear total, which would drop every non-gear contribution (e.g. a
    # job's innate Double Attack trait, merit crit rate, JP Store TP).
    return CombatStats(
        stats=stats, att=att, acc=acc, sub_att=sub_att, sub_acc=sub_acc,
        main_dmg=main_dmg, main_dmg_for_rank=main_dmg_for_rank,
        sub_dmg=sub_dmg, sub_dmg_for_rank=sub_dmg_for_rank,
        crit_rate_mod=anchor.crit_rate + delta(MID["CRITHITRATE"]),
        crit_dmg=anchor.crit_dmg + delta(MID["CRIT_DMG_INCREASE"]),
        da=anchor.da + delta(MID["DOUBLE_ATTACK"]),
        ta=anchor.ta + delta(MID["TRIPLE_ATTACK"]),
        qa=anchor.qa + delta(MID["QUAD_ATTACK"]),
        haste_gear=anchor.haste_gear + delta(MID["HASTE_GEAR"]),
        haste_magic=anchor.haste_magic + delta(MID["HASTE_MAGIC"]),
        haste_ability=anchor.haste_ability + delta(MID["HASTE_ABILITY"]),
        dual_wield=anchor.dual_wield + delta(MID["DUAL_WIELD"]),
        store_tp=anchor.store_tp + delta(MID["STORETP"]),
        tp_bonus=anchor.tp_bonus + delta(MID["TP_BONUS"]),
        ws_dmg_all=anchor.ws_dmg_all + delta(MID["ALL_WSDMG_ALL_HITS"]),
        ws_dmg_first=anchor.ws_dmg_first + delta(MID["ALL_WSDMG_FIRST_HIT"]),
        # fTP-bonus / WSACC are gear-only (calculateFTPBonus early-returns for
        # non-PC; no trait/merit/JP source), so the raw candidate gear total is
        # correct -- and the anchor never reports them, so no delta applies.
        gear_ftp=cand_mods.get(MID["ANY_FTP_BONUS"], 0) / 256.0,
        ws_acc=cand_mods.get(MID["WSACC"], 0),
        gear_mods=cand_mods, wctx=wctx,
    )
