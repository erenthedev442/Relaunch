"""
scoring_weights.py -- SINGLE SOURCE OF TRUTH for the gear-scoring weight maps.

Imported by tools/score_armor.py, tools/score_weapons.py,
tools/score_accessories.py and tools/docgen/generators/gear_finder.py so the
role weights, sanity caps and DD-latent set can never drift between them again.
(Previously each file kept its own hand-synced copy.)

  ROLE_WEIGHTS[role][modId]  -> multiplier applied to that mod for that role
  MOD_SANITY_CAP[modId]      -> clamp magnitude before weighting (CAP_DEFAULT otherwise)
  DD_ALWAYS_LATENTS          -> latentIds that count at FULL weight for DPS/WS
  CAP_DEFAULT                -> fallback clamp
"""
from __future__ import annotations

ROLE_WEIGHTS = {
    'DPS': {
        259: 8.0,     # DUAL_WIELD
        302: 8.0,     # TRIPLE_ATTACK
        430: 8.0,     # QUAD_ATTACK
        288: 6.0,     # DOUBLE_ATTACK
        62: 5.0,      # ATTP
        165: 4.0,     # CRITHITRATE
        387: -3.0,    # UDMGPHYS
        8: 2.0,       # STR
        9: 2.0,       # DEX
        73: 2.0,      # STORETP
        11: 1.5,      # AGI
        25: 1.5,      # ACC
        421: 1.5,     # CRIT_DMG_INCREASE
        23: 1.0,      # ATT
        368: 1.0,     # REGAIN
        1039: 1.0,    # TRIPLE_ATTACK_DMG
        289: 0.5,     # SUBTLE_BLOW
        432: 0.3,     # ENSPELL_DMG_BONUS
        113: 0.2,     # ENHANCE
        362: 0.1,     # JUMP_ATT_BONUS
        506: 0.1,     # EXTRA_DMG_CHANCE
        508: 0.1,     # THIRD_EYE_COUNTER_RATE
        954: 0.1,     # BERSERK_DURATION
        361: 0.05,    # JUMP_TP_BONUS
        384: 0.05,    # HASTE_GEAR
        507: 0.05,    # OCC_DO_EXTRA_DMG
        160: -0.03,   # DMG
        161: -0.03,   # DMGPHYS
    },
    'WS': {
        840: 5.0,     # ALL_WSDMG_ALL_HITS
        949: 5.0,     # WS_NO_DEPLETE
        421: 3.0,     # CRIT_DMG_INCREASE
        841: 3.0,     # ALL_WSDMG_FIRST_HIT
        1144: 3.0,    # ANY_FTP_BONUS
        8: 2.0,       # STR
        9: 2.0,       # DEX
        165: 2.0,     # CRITHITRATE
        11: 1.5,      # AGI
        23: 1.5,      # ATT
        25: 1.5,      # ACC
        48: 1.0,      # WSACC
        570: 1.0,     # WEAPONSKILL_DAMAGE_BASE
        113: 0.2,     # ENHANCE
        506: 0.1,     # EXTRA_DMG_CHANCE
        507: 0.05,    # OCC_DO_EXTRA_DMG
        345: 0.04,    # TP_BONUS
        175: 0.01,    # SKILLCHAINDMG
    },
    'TANK': {
        370: 8.0,     # REGEN
        387: -8.0,    # UDMGPHYS
        389: -8.0,    # UDMGMAGIC
        3: 3.0,       # HPP
        27: 3.0,      # ENMITY
        29: 3.0,      # MDEF
        63: 3.0,      # DEFP
        10: 2.0,      # VIT
        291: 1.5,     # COUNTER
        1: 1.0,       # DEF
        166: 1.0,     # CRITICAL_HIT_EVASION
        2: 0.5,       # HP
        68: 0.5,      # EVA
        108: 0.5,     # EVASION
        168: 0.5,     # SPELLINTERRUPT
        109: 0.3,     # SHIELD
        31: 0.2,      # MEVA
        113: 0.2,     # ENHANCE
        110: 0.1,     # PARRY
        160: -0.06,   # DMG
        161: -0.06,   # DMGPHYS
        163: -0.06,   # DMGMAGIC
        162: -0.04,   # DMGBREATH
        164: -0.04,   # DMGRANGE
    },
    'CASTER': {
        311: 4.0,     # MAGIC_DAMAGE
        28: 3.0,      # MATT
        12: 2.0,      # INT
        30: 2.0,      # MACC
        170: 2.0,     # FASTCAST
        6: 1.0,       # MPP
        13: 1.0,      # MND
        114: 0.5,     # ENFEEBLE
        115: 0.5,     # ELEM
        168: 0.5,     # SPELLINTERRUPT
        113: 0.2,     # ENHANCE
        5: 0.05,      # MP
        160: -0.03,   # DMG
        163: -0.03,   # DMGMAGIC
    },
    'HEAL': {
        369: 30.0,    # REFRESH
        13: 2.0,      # MND
        170: 2.0,     # FASTCAST
        374: 2.0,     # CURE_POTENCY
        6: 1.5,       # MPP
        30: 1.0,      # MACC
        14: 0.5,      # CHR
        112: 0.5,     # HEALING
        168: 0.5,     # SPELLINTERRUPT
        519: 0.5,     # CURE_CAST_TIME
        113: 0.2,     # ENHANCE
        5: 0.05,      # MP
        160: -0.03,   # DMG
        163: -0.03,   # DMGMAGIC
    },
    'PET': {
        1040: 5.0,    # AVATAR_LVL_BONUS
        126: 4.0,     # BP_DAMAGE
        994: 3.0,     # PET_ATTR_BONUS
        117: 2.0,     # SUMMONING
        346: 2.0,     # PERPETUATION_REDUCTION
        357: 1.5,     # BP_DELAY
        541: 1.5,     # BP_DELAY_II
        990: 1.5,     # PET_ATK_DEF
        991: 1.5,     # PET_ACC_EVA
        992: 1.5,     # PET_MAB_MDB
        993: 1.5,     # PET_MACC_MEVA
        995: 1.0,     # PET_TP_BONUS
        6: 0.5,       # MPP
        113: 0.2,     # ENHANCE
        5: 0.03,      # MP
    },
}

DD_ALWAYS_LATENTS = [7, 10, 41]
CAP_DEFAULT = 200

MOD_SANITY_CAP = {
    31: 300,          # MEVA
    62: 30,           # ATTP
    63: 30,           # DEFP
    117: 100,         # SUMMONING
    126: 50,          # BP_DAMAGE
    160: 5000,        # DMG
    161: 5000,        # DMGPHYS
    162: 5000,        # DMGBREATH
    163: 5000,        # DMGMAGIC
    164: 5000,        # DMGRANGE
    165: 20,          # CRITHITRATE
    170: 30,          # FASTCAST
    175: 2000,        # SKILLCHAINDMG
    259: 15,          # DUAL_WIELD
    288: 20,          # DOUBLE_ATTACK
    302: 20,          # TRIPLE_ATTACK
    345: 500,         # TP_BONUS
    346: 30,          # PERPETUATION_REDUCTION
    357: 100,         # BP_DELAY
    361: 300,         # JUMP_TP_BONUS
    369: 10,          # REFRESH
    384: 300,         # HASTE_GEAR
    387: 30,          # UDMGPHYS
    389: 30,          # UDMGMAGIC
    421: 30,          # CRIT_DMG_INCREASE
    430: 20,          # QUAD_ATTACK
    507: 300,         # OCC_DO_EXTRA_DMG
    541: 100,         # BP_DELAY_II
    570: 50,          # WEAPONSKILL_DAMAGE_BASE
    840: 50,          # ALL_WSDMG_ALL_HITS
    841: 50,          # ALL_WSDMG_FIRST_HIT
    949: 10,          # WS_NO_DEPLETE
    990: 50,          # PET_ATK_DEF
    991: 50,          # PET_ACC_EVA
    992: 50,          # PET_MAB_MDB
    993: 50,          # PET_MACC_MEVA
    994: 50,          # PET_ATTR_BONUS
    995: 50,          # PET_TP_BONUS
    1040: 10,         # AVATAR_LVL_BONUS
    1144: 100,        # ANY_FTP_BONUS
}
