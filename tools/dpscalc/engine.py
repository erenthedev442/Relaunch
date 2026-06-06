"""Expected-value damage engine: auto-attack DPS and weaponskill damage.

This is the layer that turns a reconstructed `CombatStats` (state.py) plus a
`Target` (targets.py) and -- for weaponskills -- a `WSParams` (wsdata.py) into
average damage numbers, using only the pure math in formulas.py.

It mirrors two server routines:

  * Auto-attack: CBattleEntity::takeDamage / calculateAttackDamage in the custom
    combat scripts -- per swing, each HAND rolls multi-attack independently, each
    resulting hit rolls hit/miss then a pDIF (crit folded into the pDIF EV here).
    DPS = E[damage per round] / (swing interval in seconds).

  * Weaponskill: scripts/globals/weaponskills.lua calculateRawWSDmg +
    doPhysicalWeaponskill (Adoulin branch). The full hit sequence is:
        first hit (acc+100) -> remaining numHits-1 main hits -> main multi-procs
        -> offhand hit (if dual-wield/H2H) -> offhand multi-procs
    The first hit's fTP carries the gear fTP bonus (calculateFTPBonus:
    ANY_FTP_BONUS/256, e.g. Fotia Gorget) and every WS hit gets the derived
    accuracy bonus (ceil(gearFTP*100) + WSACC).
    then  finaldmg *= (100 + ALL_WSDMG_ALL_HITS + WEAPONSKILL_DAMAGE_BASE+id)/100,
          finaldmg += firstHitBonus (ALL_WSDMG_FIRST_HIT% of the first hit),
          finaldmg *= WEAPON_SKILL_POWER.

Target damage-taken (physicalDmgTaken / *_SDT) is treated as 1.0: the Hunting
League catalog balances its NMs through DEF/EVASION, not SDT (see targets.py).
"""
from __future__ import annotations

import math
from dataclasses import dataclass

from . import formulas as F
from .gameconf import CONF
from .state import CombatStats
from .targets import Target
from .wsdata import WSParams


# Per-slot physical hit-rate caps (scripts/globals/combat/physical_hit_rate.lua).
def _main_cap(cs: CombatStats) -> float:
    return 0.95 if (cs.wctx and cs.wctx.is_2h) else 0.99


def _off_cap(cs: CombatStats) -> float:
    return 0.99 if (cs.wctx and cs.wctx.is_h2h) else 0.95


def _crit_rate(cs: CombatStats, tgt: Target, tp_factor: float = 0.0) -> float:
    return F.swing_crit_rate(
        cs.stats.get("DEX", 0), tgt.agi(), cs.crit_rate_mod,
        tp_factor=tp_factor, target_crit_eva=tgt.crit_eva(),
    )


def _fstr(cs: CombatStats, tgt: Target, dmg_for_rank: int) -> float:
    is_h2h = bool(cs.wctx and cs.wctx.is_h2h)
    wrank = F.weapon_rank(dmg_for_rank, is_h2h_pc=is_h2h)
    return F.fstr(cs.stats.get("STR", 0), tgt.vit(), wrank)


# ---------------------------------------------------------------------------
# Auto-attack DPS
# ---------------------------------------------------------------------------
@dataclass
class AutoResult:
    dps: float
    interval_ms: float
    crit_rate: float
    # main hand
    main_hit_dmg: float          # E[damage of one landed main hit]
    main_hits_per_round: float   # E[main hits attempted per round] (multi-attack)
    main_hit_rate: float
    # offhand (zero unless dual-wield / H2H)
    off_hit_dmg: float
    off_hits_per_round: float
    off_hit_rate: float
    dmg_per_round: float
    tp_per_round: float


def auto_attack_dps(cs: CombatStats, tgt: Target) -> AutoResult:
    wc = cs.wctx
    assert wc is not None, "CombatStats.wctx required for the DPS engine"

    crit = _crit_rate(cs, tgt)
    eva, dfn = tgt.evasion(), tgt.defense()
    hits_per_swing = F.expected_hits_per_swing(cs.qa, cs.ta, cs.da)

    # --- main hand ---
    fstr_m = _fstr(cs, tgt, cs.main_dmg_for_rank)
    pdif_m = F.melee_pdif_ev(cs.att, dfn, wc.main_skill, crit, cs.crit_dmg)
    hr_m = F.hit_rate(cs.acc, eva, _main_cap(cs))
    main_hit_dmg = (cs.main_dmg + fstr_m) * pdif_m
    main_per_round = hits_per_swing
    e_main = main_per_round * hr_m * main_hit_dmg

    # --- offhand ---
    off_hit_dmg = off_per_round = hr_o = e_off = 0.0
    if wc.has_offhand:
        fstr_o = _fstr(cs, tgt, cs.sub_dmg_for_rank)
        pdif_o = F.melee_pdif_ev(cs.sub_att, dfn, wc.sub_skill, crit, cs.crit_dmg)
        hr_o = F.hit_rate(cs.sub_acc, eva, _off_cap(cs))
        off_hit_dmg = (cs.sub_dmg + fstr_o) * pdif_o
        off_per_round = hits_per_swing
        e_off = off_per_round * hr_o * off_hit_dmg

    dmg_per_round = e_main + e_off

    # --- swing interval ---
    # Dual-wield (two real weapons) sums delays and lets DUAL_WIELD shave them;
    # H2H and single-/two-handers swing on the main delay alone.
    sub_delay = wc.sub_delay if (wc.has_offhand and not wc.is_h2h) else None
    interval = F.swing_interval_ms(
        wc.main_delay, sub_delay,
        cs.haste_gear, cs.haste_magic, cs.haste_ability,
        dual_wield=cs.dual_wield,
    )

    dps = dmg_per_round / (interval / 1000.0) if interval > 0 else 0.0

    # --- TP gained per round (for weaving WS into total DPS) ---
    is_dw = wc.has_offhand and not wc.is_h2h
    tp_main = (main_per_round * hr_m
               * F.tp_per_hit(wc.main_delay, cs.store_tp, cs.dual_wield, is_dw))
    tp_off = 0.0
    if wc.has_offhand:
        off_delay = wc.sub_delay if not wc.is_h2h else wc.main_delay
        tp_off = (off_per_round * hr_o
                  * F.tp_per_hit(off_delay, cs.store_tp, cs.dual_wield, is_dw))
    tp_per_round = tp_main + tp_off

    return AutoResult(
        dps=dps, interval_ms=interval, crit_rate=crit,
        main_hit_dmg=main_hit_dmg, main_hits_per_round=main_per_round,
        main_hit_rate=hr_m,
        off_hit_dmg=off_hit_dmg, off_hits_per_round=off_per_round,
        off_hit_rate=hr_o,
        dmg_per_round=dmg_per_round, tp_per_round=tp_per_round,
    )


# ---------------------------------------------------------------------------
# Weaponskill damage (expected value at a given TP)
# ---------------------------------------------------------------------------
@dataclass
class WSResult:
    name: str
    tp: int
    damage: float                # final EV after WEAPON_SKILL_POWER
    first_hit_dmg: float
    main_base: float             # per-hit base (weaponDmg + fSTR + wsc)
    num_hits: int
    crit_rate: float
    ftp_first: float
    expected_main_hits: float    # natural + multi (mainhand), EV
    expected_off_hits: float


def _ws_multi_extra_hits(cs: CombatStats, n_roll_opportunities: int) -> float:
    """Expected EXTRA hits from DA/TA/QA across `n_roll_opportunities` rolls,
    with the engine's 2-proc cap (weaponskills.lua getMultiAttacks loop)."""
    per_roll = F.expected_hits_per_swing(cs.qa, cs.ta, cs.da) - 1.0
    if per_roll <= 0:
        return 0.0
    qa = F.clamp(cs.qa, 0, 100) / 100.0
    ta = F.clamp(cs.ta, 0, 100) / 100.0
    da = F.clamp(cs.da, 0, 100) / 100.0
    p_proc = 1.0 - (1 - qa) * (1 - ta) * (1 - da)
    if p_proc <= 1e-9:
        return 0.0
    e_extra_given_proc = per_roll / p_proc
    exp_procs = min(n_roll_opportunities * p_proc, 2.0)
    return e_extra_given_proc * exp_procs


def ws_damage(cs: CombatStats, tgt: Target, ws: WSParams, tp: int) -> WSResult:
    wc = cs.wctx
    assert wc is not None, "CombatStats.wctx required for the WS engine"

    tp_used = int(F.clamp(tp + cs.tp_bonus, 0, 3000))
    eva, dfn = tgt.evasion(), tgt.defense()

    # WSC + per-hit base damage (Adoulin: alpha = 1, bonusWSmods = 0).
    wsc = F.wsc(cs.stats, ws.wsc)
    fstr_m = _fstr(cs, tgt, cs.main_dmg_for_rank)
    main_base = math.floor(cs.main_dmg + fstr_m + wsc)
    off_base = cs.sub_dmg + fstr_m + wsc          # offhand uses the SAME fSTR

    # fTP (first hit), reset to 1 on later hits unless the WS carries it.
    # gearFTP (ANY_FTP_BONUS/256, e.g. Fotia Gorget) rides on the first hit's
    # fTP; weaponskills.lua resets ftp to a plain 1 afterwards (only multiHitfTP
    # WS carry the bonus to every hit), which ftp_rest already reflects.
    ftp_first = F.ftp(tp_used, ws.ftp) + cs.gear_ftp
    ftp_rest = ftp_first if ws.multi_hit_ftp else 1.0

    # Gear adds accuracy to every WS hit: ceil(gearFTP*100) + WSACC
    # (weaponskills.lua doPhysicalWeaponskill: gearAcc + getMod(WSACC)).
    ws_acc_bonus = math.ceil(cs.gear_ftp * 100) + cs.ws_acc

    # WS-only modifiers folded into the pDIF EV.
    atk_mult = F.ftp(tp_used, ws.atk_varies)                       # atkVaries
    ign = (F.ftp(tp_used, ws.ignored_def) if ws.ignored_def else 0.0)
    crit = (_crit_rate(cs, tgt, tp_factor=F.ftp(tp_used, ws.crit_varies))
            if ws.crit_varies else 0.0)

    def pdif(att: int, skill: int) -> float:
        return F.melee_pdif_ev(att, dfn, skill, crit, cs.crit_dmg,
                               atk_mult=atk_mult, ignore_def_factor=ign)

    pdif_m = pdif(cs.att, wc.main_skill)
    cap_m = _main_cap(cs)
    hr_first = F.hit_rate(cs.acc + ws_acc_bonus + 100, eva, cap_m)  # +100 acc
    hr_main = F.hit_rate(cs.acc + ws_acc_bonus, eva, cap_m)

    # First hit.
    first_dmg = hr_first * main_base * ftp_first * pdif_m
    first_hit_bonus = first_dmg * cs.ws_dmg_first / 100.0

    # Remaining natural mainhand hits.
    rem_main_hits = max(ws.num_hits - 1, 0)
    rem_main = rem_main_hits * hr_main * main_base * ftp_rest * pdif_m

    # Mainhand multi-attack extra hits (numHits roll opportunities).
    main_multi = (_ws_multi_extra_hits(cs, ws.num_hits)
                  * hr_main * main_base * ftp_rest * pdif_m)

    # Offhand base hit + offhand multi-attacks (one roll opportunity).
    off_total = 0.0
    exp_off_hits = 0.0
    if wc.has_offhand:
        pdif_o = pdif(cs.sub_att, wc.sub_skill)
        hr_off = F.hit_rate(cs.sub_acc + ws_acc_bonus, eva, _off_cap(cs))
        off_hit = hr_off * off_base * ftp_rest * pdif_o
        off_multi = (_ws_multi_extra_hits(cs, 1)
                     * hr_off * off_base * ftp_rest * pdif_o)
        off_total = off_hit + off_multi
        exp_off_hits = hr_off * (1.0 + _ws_multi_extra_hits(cs, 1))

    raw = first_dmg + rem_main + main_multi + off_total

    bonusdmg = cs.ws_dmg_all + cs.ws_dmg_for(ws.ws_id)
    final = raw * (100 + bonusdmg) / 100.0 + first_hit_bonus
    final = final * CONF.weapon_skill_power

    exp_main_hits = (hr_first
                     + rem_main_hits * hr_main
                     + _ws_multi_extra_hits(cs, ws.num_hits) * hr_main)

    return WSResult(
        name=ws.name, tp=tp_used, damage=final,
        first_hit_dmg=first_dmg * CONF.weapon_skill_power,
        main_base=main_base, num_hits=ws.num_hits, crit_rate=crit,
        ftp_first=ftp_first,
        expected_main_hits=exp_main_hits, expected_off_hits=exp_off_hits,
    )


# ---------------------------------------------------------------------------
# Combined "rotation" DPS = auto-attack DPS + a WS woven in each time TP hits
# 1000. First-order: layers the WS on top of uninterrupted auto-swings.
# ---------------------------------------------------------------------------
@dataclass
class RotationResult:
    auto: AutoResult
    ws: WSResult
    total_dps: float
    secs_to_ws: float


def rotation_dps(cs: CombatStats, tgt: Target, ws: WSParams,
                 ws_tp: int = 1000) -> RotationResult:
    auto = auto_attack_dps(cs, tgt)
    wsr = ws_damage(cs, tgt, ws, ws_tp)
    if auto.tp_per_round <= 0 or auto.interval_ms <= 0:
        return RotationResult(auto, wsr, auto.dps, math.inf)
    rounds_to_ws = ws_tp / auto.tp_per_round
    secs_to_ws = rounds_to_ws * auto.interval_ms / 1000.0
    total = auto.dps + (wsr.damage / secs_to_ws if secs_to_ws > 0 else 0.0)
    return RotationResult(auto, wsr, total, secs_to_ws)
