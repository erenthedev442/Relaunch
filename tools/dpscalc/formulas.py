"""Pure combat-math ports from the server's custom Lua/C++ engine.

Every function here is a faithful port of a specific server routine, cited in
its docstring. NOTHING in this module touches the DB or the player/target
objects -- it takes plain numbers so it can be unit-checked in isolation.

Where the server rolls RNG (pDIF, crit, multi-attack, hit/miss), we compute the
*expected value* instead of sampling, because the tool ranks gear by average
damage, not a single swing. Each EV function documents the distribution it is
collapsing.

Unit conventions (matching the server):
  * Haste mods (HASTE_GEAR/MAGIC/ABILITY) are in 1/10000 (2500 = 25%).
  * Percent mods (ATTP, *_WSDMG, DUAL_WIELD, STORETP, CRITHITRATE...) are whole
    percents (25 = 25%).
  * Weapon `delay` is the raw item stat (e.g. 240, 480); CBattleEntity converts
    it to a millisecond swing interval as delay*1000/60.
"""
from __future__ import annotations

import math


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


# ---------------------------------------------------------------------------
# Weapon rank + fSTR
#   src/map/entities/battleentity.cpp GetMainWeaponRank (dmg // 9)
#   scripts/globals/combat/physical_utilities.lua calculateMeleeStatFactor
# ---------------------------------------------------------------------------
def weapon_rank(weapon_dmg_for_rank: int, is_h2h_pc: bool = False) -> int:
    """GetMainWeaponRank: (effective wDamage [+3 H2H PC]) // 9.

    The server sums everything THEN integer-divides by 9, so the caller must pass
    the already-assembled rank input:
        weaponBaseDmg + MAIN_DMG_RATING(entity) + MAIN_DMG_RANK(weapon)
    Note DMG_RATING is deliberately excluded -- it boosts weapon *damage* but is
    added-then-subtracted in GetMainWeaponRank, so it never affects rank
    (battleentity.cpp:792-793, "Company sword/Maneater don't boost weapon rank").
    """
    w = weapon_dmg_for_rank + (3 if is_h2h_pc else 0)
    return max(w, 0) // 9


def fstr(player_str: int, target_vit: int, wrank: int) -> float:
    """calculateMeleeStatFactor (PC/Trust branch). Returns fSTR (a float, the
    /4-scaled and rank-clamped stat factor added to base weapon damage)."""
    stat_diff = player_str - target_vit
    stat_diff = clamp(stat_diff, (7 + wrank2(wrank)) * -2, (14 + wrank2(wrank)) * 2)

    if stat_diff >= 12:
        f = stat_diff + 4
    elif stat_diff >= 6:
        f = stat_diff + 6
    elif stat_diff >= 1:
        f = stat_diff + 7
    elif stat_diff >= -2:
        f = stat_diff + 8
    elif stat_diff >= -7:
        f = stat_diff + 9
    elif stat_diff >= -15:
        f = stat_diff + 10
    elif stat_diff >= -21:
        f = stat_diff + 12
    else:
        f = stat_diff + 13

    upper = wrank + 8
    lower = -1 if wrank == 0 else -wrank
    return clamp(f / 4, lower, upper)


def wrank2(wrank: int) -> int:
    # statDiff clamp uses weaponRank*2 in both bounds; small helper for clarity.
    return wrank * 2


# ---------------------------------------------------------------------------
# WSC + fTP
#   physical_utilities.lua calculateWSC
#   weaponskills.lua xi.weaponskills.fTP
# ---------------------------------------------------------------------------
WSC_STATS = ("STR", "DEX", "VIT", "AGI", "INT", "MND", "CHR")


def wsc(stats: dict[str, int], mults: dict[str, float],
        ws_stat_bonus: dict[str, int] | None = None) -> int:
    """calculateWSC: sum over stats of floor(stat * (wsMult + WS_x_BONUS/100))."""
    ws_stat_bonus = ws_stat_bonus or {}
    total = 0
    for st in WSC_STATS:
        m = mults.get(st, 0.0)
        b = ws_stat_bonus.get(st, 0) / 100.0
        if m or b:
            total += math.floor(stats.get(st, 0) * (m + b))
    return total


def ftp(tp: int, table: list[float] | None) -> float:
    """xi.weaponskills.fTP. Returns 1 if no table or tp<1000; else linear interp
    over table[1..3] anchored at TP 1000/2000/3000."""
    if not table or tp < 1000:
        return 1.0
    if tp >= 2000:
        return table[1] + (tp - 2000) * (table[2] - table[1]) / 1000
    return table[0] + (tp - 1000) * (table[1] - table[0]) / 1000


# ---------------------------------------------------------------------------
# Hit rate
#   physical_hit_rate.lua accuracyAndEvasionToHitRate + caps
# Level correction is OFF for the Hunting League zone, so no dlvl term.
# ---------------------------------------------------------------------------
def hit_rate(acc: int, eva: int, cap: float) -> float:
    return clamp((75 + (acc - eva) / 2) / 100.0, 0.20, cap)


# ---------------------------------------------------------------------------
# Critical hit rate
#   physical_utilities.lua criticalRateFromStatDiff + calculateSwingCriticalRate
# ---------------------------------------------------------------------------
def crit_stat_bonus(d_dex: int) -> float:
    if d_dex > 50:
        return 0.15
    if d_dex >= 40:
        return (d_dex - 35) / 100.0
    if d_dex >= 30:
        return 0.04
    if d_dex >= 20:
        return 0.03
    if d_dex >= 14:
        return 0.02
    if d_dex >= 7:
        return 0.01
    return 0.0


def swing_crit_rate(player_dex: int, target_agi: int, crithitrate_mod: int,
                    merit_crit: float = 0.0, tp_factor: float = 0.0,
                    target_crit_eva: int = 0) -> float:
    r = (0.05
         + crit_stat_bonus(player_dex - target_agi)
         + crithitrate_mod / 100.0
         + merit_crit
         + tp_factor
         - target_crit_eva / 100.0)
    return clamp(r, 0.05, 1.0)


# ---------------------------------------------------------------------------
# Melee pDIF (expected value)
#   physical_utilities.lua calculateMeleePDIF + wRatioCapPC + getSpikeRatio
#
# pDifWeaponCapTable (PC caps) -- keyed by weapon SKILL type id.
# ---------------------------------------------------------------------------
PDIF_WEAPON_CAP = {
    1: 3.5,    # Hand-to-Hand
    2: 3.25,   # Dagger
    3: 3.25,   # Sword
    4: 3.75,   # Great Sword
    5: 3.25,   # Axe
    6: 3.75,   # Great Axe
    7: 4.0,    # Scythe
    8: 3.75,   # Polearm
    9: 3.25,   # Katana
    10: 3.5,   # Great Katana
    11: 3.25,  # Club
    12: 3.75,  # Staff
    25: 3.5,   # Archery
    26: 3.5,   # Marksmanship
}


def _pc_pdif_caps(w_ratio: float, final_cap: float) -> tuple[float, float]:
    """wRatioCapPC -> (lowerCap, upperCap)."""
    if w_ratio < 0.5:
        up = w_ratio + 0.5
    elif w_ratio < 0.7:
        up = 1.0
    elif w_ratio < 1.2:
        up = w_ratio + 0.3
    elif w_ratio < 1.5:
        up = w_ratio + w_ratio * 0.25
    else:
        up = min(w_ratio + 0.375, final_cap)

    if w_ratio < 0.38:
        lo = 0.0
    elif w_ratio < 1.25:
        lo = w_ratio * 1176 / 1024 - 448 / 1024
    elif w_ratio < 1.51:
        lo = 1.0
    elif w_ratio < 2.44:
        lo = w_ratio * 1176 / 1024 - 775 / 1024
    else:
        lo = min(w_ratio - 0.375, final_cap)
    return lo, up


def _pc_spike_ratio(w_ratio: float) -> float:
    """getSpikeRatio(isPC=true): chance the hit collapses to pDIF=1.0."""
    if 0.5 < w_ratio < 1.5:
        return clamp((0.5 - abs(w_ratio - 1)) * 1.2, 0.0, 1 / 3)
    return 0.0


# meleeRandom = 1 + rand(0,5)*0.01 -> mean of {1.00..1.05}
_MELEE_RANDOM_EV = 1.0 + (0 + 1 + 2 + 3 + 4 + 5) / 6 * 0.01  # = 1.025


def _pdif_one_branch(base_ratio: float, crit: bool, final_cap_base: float,
                     crit_dmg_mult: float) -> float:
    """Expected pDIF for a single hit given a fixed crit outcome, collapsing the
    spike chance, the uniform(lower,upper) roll and the meleeRandom factor."""
    w_ratio = base_ratio + (1.0 if crit else 0.0)
    final_cap = final_cap_base + (1.0 if crit else 0.0)
    spike = _pc_spike_ratio(w_ratio)
    lo, up = _pc_pdif_caps(w_ratio, final_cap)
    # Server clamps the lower bound at 0 (calculateMeleePDIF Step 3); the upper
    # 50/50 {0.5 vs 0} roll never binds for PCs because pDifUpperCap >= 0.5.
    lo = max(lo, 0.0)
    ev = (lo + up) / 2 * _MELEE_RANDOM_EV
    if crit:
        ev *= crit_dmg_mult
    return spike * 1.0 + (1 - spike) * ev


def melee_pdif_ev(attack: int, defense: int, weapon_skill: int, crit_rate: float,
                  crit_dmg_increase: int = 0, target_crit_def: int = 0,
                  atk_mult: float = 1.0, damage_limit: int = 0,
                  damage_limitp: int = 0, ignore_def_factor: float = 0.0) -> float:
    """Expected melee pDIF over crit+non-crit outcomes.

    attack            : actor ATT for the relevant weapon slot (already includes ATTP).
    defense           : target DEF.
    weapon_skill      : weapon skill-type id (selects the PC pDIF cap).
    crit_rate         : probability this hit crits.
    atk_mult          : wsAttackMod (atkVaries fTP for WS; 1.0 for auto-attacks).
    ignore_def_factor : fraction of target DEF ignored (ignoredDefense fTP for WS).
    """
    actor_attack = max(1, math.floor(attack * atk_mult))
    if ignore_def_factor:
        defense = math.floor(defense * (1.0 - ignore_def_factor))
    target_def = max(1, defense)
    base_ratio = actor_attack / target_def

    cap = PDIF_WEAPON_CAP.get(weapon_skill, 3.25)
    final_cap_base = (cap + damage_limit / 100.0) * (1 + damage_limitp / 100.0)
    crit_dmg_mult = (100 + clamp(crit_dmg_increase - target_crit_def, 0, 100)) / 100.0

    non = _pdif_one_branch(base_ratio, False, final_cap_base, crit_dmg_mult)
    cri = _pdif_one_branch(base_ratio, True, final_cap_base, crit_dmg_mult)
    return (1 - crit_rate) * non + crit_rate * cri


# ---------------------------------------------------------------------------
# Multi-attack expected hit count
#   weaponskills.lua getMultiAttacks (priority QA > TA > DA, mutually exclusive)
# Rates are whole-percent mods. Returns expected number of hits from one swing.
# ---------------------------------------------------------------------------
def expected_hits_per_swing(qa: int, ta: int, da: int,
                            oa_twice: int = 0, oa_thrice: int = 0) -> float:
    qa = clamp(qa, 0, 100) / 100.0
    ta = clamp(ta, 0, 100) / 100.0
    da = clamp(da, 0, 100) / 100.0
    # Priority chain: first proc wins. Occult Acumen "one a twice/thrice" sit
    # above QA in the chain but are rare on melee gear; included for fidelity.
    p_thrice = clamp(oa_thrice, 0, 100) / 100.0
    p_twice = clamp(oa_twice, 0, 100) / 100.0
    rem = 1.0
    hits = 1.0
    # OA Thrice (+2)
    hits += rem * p_thrice * 2
    rem *= (1 - p_thrice)
    # OA Twice (+1)
    hits += rem * p_twice * 1
    rem *= (1 - p_twice)
    # Quad (+3)
    hits += rem * qa * 3
    rem *= (1 - qa)
    # Triple (+2)
    hits += rem * ta * 2
    rem *= (1 - ta)
    # Double (+1)
    hits += rem * da * 1
    return hits


# ---------------------------------------------------------------------------
# TP return per hit
#   scripts/globals/combat/tp.lua calculateTPReturn (PC branch) + modified delay
# ---------------------------------------------------------------------------
def tp_return_pc(delay: int) -> float:
    """calculateTPReturn PC branch: base TP gained from one hit at `delay`
    (already the modified/halved delay for DW where applicable)."""
    if delay > 900:
        return 173 + (delay - 900) * 28 / 360
    if delay > 720:
        return 161 + (delay - 720) * 24 / 360
    if delay > 630:
        return 154 + (delay - 630) * 28 / 360
    if delay > 540:
        return 149 + (delay - 540) * 20 / 360
    if delay > 180:
        return 61 + (delay - 180) * 88 / 360
    return 61 + (delay - 180) * 63 / 360


def modified_delay_dw(delay: int, dual_wield: int) -> float:
    """getModifiedDelayAndCanZanshin DW branch: (delay*(100-DW)/100)/2."""
    return (delay * (100 - dual_wield) / 100) / 2


def tp_per_hit(base_delay: int, store_tp: int, dual_wield: int = 0,
               is_dual_wield: bool = False) -> float:
    """Single-hit TP including STORETP. base_delay is the raw weapon delay stat."""
    d = modified_delay_dw(base_delay, dual_wield) if is_dual_wield else base_delay
    return tp_return_pc(math.floor(d)) * (1 + store_tp / 100.0)


# ---------------------------------------------------------------------------
# Attack-speed / swing interval
#   CBattleEntity::GetWeaponDelay (battleentity.cpp). Returns ms per round.
# ---------------------------------------------------------------------------
def _delay_to_ms(delay_stat: int) -> float:
    return delay_stat * 1000.0 / 60.0


def swing_interval_ms(main_delay: int, sub_delay: int | None,
                      haste_gear: int, haste_magic: int, haste_ability: int,
                      dual_wield: int = 0, delayp: int = 0, delay_mod: int = 0,
                      twohand_haste_ability: int = 0,
                      delay_reduction_cap: float = 0.80) -> float:
    """Combined attack-round interval in milliseconds, mirroring GetWeaponDelay.

    Haste mods are in 1/10000; dual_wield/delayp are whole percent. main/sub_delay
    are raw delay stats; pass sub_delay only when actually dual-wielding a second
    weapon (DUAL_WIELD then reduces the combined delay).
    """
    weapon_delay = _delay_to_ms(main_delay) + delay_mod
    dw_mult = 1.0
    if sub_delay is not None:
        weapon_delay += _delay_to_ms(sub_delay)
        dw_mult = 1.0 - dual_wield / 100.0

    hm = clamp(haste_magic / 10000.0, -1.0, 0.4375)
    ha = clamp((haste_ability + twohand_haste_ability) / 10000.0, -0.25, 0.25)
    hg = clamp(haste_gear / 10000.0, -0.25, 0.25)
    haste_cap = 1.0 - delay_reduction_cap
    haste_mult = clamp(1.0 - hm - ha - hg, haste_cap, 2.0)

    delay_mod_mult = 1.0 + delayp / 100.0

    min_delay = weapon_delay * 0.2
    max_delay = weapon_delay * 2.0
    final = weapon_delay * dw_mult * haste_mult * delay_mod_mult
    return clamp(final, min_delay, max_delay)
