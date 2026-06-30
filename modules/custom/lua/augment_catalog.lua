-----------------------------------
-- augment_catalog.lua
-- Maps catalyst item IDs to augment definitions.
-- One catalyst per augmentId. Trade the catalyst to the Augment Moogle
-- to apply the augment. The exdata value is 0 (uses the SQL base value).
--
-- Each entry: { augId=N, base=N, mult=N, cat=N, tier=N, label='...' }
--   augId : index into sql/augments.sql
--   base  : EFFECTIVE per-slot base value
--   mult  : EFFECTIVE multiplier (engine: (base + boost) * mult)
--   disp  : display divisor (mods stored xN divided for human display)
--   cat   : 1..24 thematic category (Sage affinity bonus key)
--             1  = STR          (Behemoth)
--             2  = Attack       (King Behemoth)
--             3  = DEX          (King Arthro)
--             4  = Accuracy     (Simurgh)
--             5  = VIT          (Adamantoise)
--             6  = Defense      (Genbu)
--             7  = AGI          (Roc)
--             8  = Evasion      (Seiryu)
--             9  = Haste        (Byakko)
--             10 = INT          (Aspidochelone)
--             11 = Magic ATK    (Ouryu)
--             12 = MND          (Bune)
--             13 = Healing      (Phoenix)
--             14 = CHR          (Suzaku)
--             15 = Enmity       (Kirin)
--             16 = HP           (Fafnir)
--             17 = Regen        (Nidhogg)
--             18 = MP           (Vrtra)
--             19 = Refresh      (Tiamat)
--             20 = Pet          (King Vinegarroon)
--             21 = Ele Resist   (Khimaira)
--             22 = Status       (Cerberus)
--             23 = Skills       (Absolute Virtue)
--             24 = WSD+         (Proto-Omega)
--   tier  : MINIMUM Augment Sage rank required to use this catalyst
--             0 = free (all ranks)
--             1 = rank 1 Initiate  (skills, basic utilities)
--             2 = rank 2 Adept     (core universal combat stats)
--             3 = rank 3 Magus     (damage multipliers, HP/MP/Regen/Refresh)
--             4 = rank 4 Sage      (top-tier universal: Haste, DA, Crit dmg, Dmg+)
--   label : stat name only (numbers stripped; scales with Sage progress)
--
-- DESIGN PRINCIPLE: job-specific or class-specific augments stay at tier 0
-- (freely accessible). Higher tiers are reserved for UNIVERSALLY powerful
-- augments that benefit every job. Players must invest in Augment Sage rank
-- to unlock the most character-defining enhancements.
--
-- Generated from sql/augments.sql + sql/mob_droplist.sql.
-----------------------------------
return {
    -- ── cat 1: STR ────────────────────────────────────────────────────────────
    [1620] = { augId = 512,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 1, label = 'STR' },
    [895]  = { augId = 145,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 2, label = 'Counter' },
    [897]  = { augId = 151,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 2, label = 'Martial Arts' },
    [903]  = { augId = 194,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 2, label = 'Kick Attacks Rate or Damage' },
    [2147] = { augId = 640,  base = 1,   mult = 2,   disp = 1,    cat = 1,  tier = 2, label = 'Counter' },

    -- ── cat 2: Attack ─────────────────────────────────────────────────────────
    [861]  = { augId = 65,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 1, label = 'Attack' },
    [883]  = { augId = 66,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 1, label = 'Rng.Attack' },
    [874]  = { augId = 130,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 1, label = 'Attack Rng.Atk' },
    [880]  = { augId = 132,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 3, label = 'Dbl.Atk. Crit.hit rate' },
    [882]  = { augId = 143,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 2, label = 'Dbl.Atk' },
    [891]  = { augId = 144,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 3, label = 'Triple Atk' },
    [1271] = { augId = 353,  base = 1,   mult = 4,   disp = 1,    cat = 2,  tier = 4, label = 'TP Bonus' },
    [1293] = { augId = 354,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 4, label = 'Quadruple Attack' },
    [1108] = { augId = 333,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 2, label = 'Conserve TP' },
    [1516] = { augId = 360,  base = 10,  mult = 1,   disp = 1,    cat = 2,  tier = 2, label = 'Save TP' },
    [1591] = { augId = 370,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 1, label = 'Reverse Flourish' },
    [2711] = { augId = 1264, base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 4, label = 'Meditate Effect Duration' },

    -- ── cat 3: DEX ────────────────────────────────────────────────────────────
    [2150] = { augId = 513,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 1, label = 'DEX' },
    [2148] = { augId = 41,   base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 3, label = 'Crit.hit rate' },
    [2149] = { augId = 328,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 4, label = 'Crit. hit damage' },
    [840]  = { augId = 44,   base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 4, label = 'Store TP Subtle Blow' },
    [1621] = { augId = 142,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 3, label = 'Store TP' },
    [1690] = { augId = 195,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 3, label = 'Subtle Blow' },
    [926]  = { augId = 198,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 1, label = 'Zanshin' },
    [947]  = { augId = 251,  base = 1,   mult = 1,   disp = 1,    cat = 3,  tier = 1, label = 'Daken' },

    -- ── cat 4: Accuracy ───────────────────────────────────────────────────────
    [846]  = { augId = 62,   base = 1,   mult = 2,   disp = 1,    cat = 4,  tier = 1, label = 'Accuracy' },
    [847]  = { augId = 63,   base = 1,   mult = 2,   disp = 1,    cat = 4,  tier = 1, label = 'Rng.Accuracy' },
    [1292] = { augId = 129,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 2, label = 'Accuracy Rng.Acc' },
    [884]  = { augId = 68,   base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 2, label = 'Accuracy Attack' },
    [1116] = { augId = 69,   base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 2, label = 'Rng.Acc. Rng.Atk' },
    [1619] = { augId = 139,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 4, label = 'Rapid Shot' },
    [1199] = { augId = 338,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 4, label = 'Barrage' },

    -- ── cat 5: VIT ────────────────────────────────────────────────────────────
    [773]  = { augId = 514,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 1, label = 'VIT' },

    -- ── cat 6: Defense ────────────────────────────────────────────────────────
    [881]  = { augId = 33,   base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 1, label = 'DEF' },
    [774]  = { augId = 1152, base = 1,   mult = 10,  disp = 1,    cat = 6,  tier = 1, label = 'DEF' },
    [769]  = { augId = 134,  base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 2, label = 'Mag.Def.Bns' },
    [936]  = { augId = 55,   base = 1,   mult = 100, disp = 100,  cat = 6,  tier = 3, label = 'Magic dmg. taken' },
    [1193] = { augId = 56,   base = 1,   mult = 100, disp = 100,  cat = 6,  tier = 4, label = 'Breath dmg. taken' },
    [858]  = { augId = 54,   base = 1,   mult = 100, disp = 100,  cat = 6,  tier = 3, label = 'Phys. dmg. taken' },
    [1123] = { augId = 71,   base = 1,   mult = 100, disp = 100,  cat = 6,  tier = 4, label = 'Damage Taken' },
    [2151] = { augId = 1155, base = 1,   mult = 200, disp = 100,  cat = 6,  tier = 3, label = 'Physical Damage Taken' },
    [2158] = { augId = 1156, base = 1,   mult = 200, disp = 100,  cat = 6,  tier = 3, label = 'Magic Damage Taken' },
    [770]  = { augId = 153,  base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 4, label = 'Shield Mastery' },
    [771]  = { augId = 363,  base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 4, label = 'Chance of successful block' },
    [772]  = { augId = 368,  base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 4, label = 'Phalanx Received' },
    [776]  = { augId = 1472, base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 3, label = 'Parrying rate' },
    [3504] = { augId = 42,   base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 1, label = 'Enemy crit. hit rate' },

    -- ── cat 7: AGI ────────────────────────────────────────────────────────────
    [878]  = { augId = 515,  base = 1,   mult = 1,   disp = 1,    cat = 7,  tier = 1, label = 'AGI' },
    [834]  = { augId = 212,  base = 1,   mult = 1,   disp = 1,    cat = 7,  tier = 1, label = 'Recycle' },

    -- ── cat 8: Evasion ────────────────────────────────────────────────────────
    [1617] = { augId = 1153, base = 3,   mult = 1,   disp = 1,    cat = 8,  tier = 0, label = 'Evasion' },
    [1713] = { augId = 1154, base = 3,   mult = 1,   disp = 1,    cat = 8,  tier = 1, label = 'Mag. Evasion' },
    [829]  = { augId = 211,  base = 1,   mult = 1,   disp = 1,    cat = 8,  tier = 2, label = 'Snapshot' },

    -- ── cat 9: Haste ──────────────────────────────────────────────────────────
    [820]  = { augId = 49,   base = 1,   mult = 2,   disp = 10.24, cat = 9,  tier = 1, label = 'Haste' },
    [821]  = { augId = 50,   base = 1,   mult = 2,   disp = 10.24, cat = 9,  tier = 4, label = 'Slow' },
    [828]  = { augId = 186,  base = 1,   mult = 1,   disp = 1,    cat = 9,  tier = 4, label = 'Resist Slow' },
    -- Weapon delay (melee)
    -- Weapon delay (ranged)
    -- Ability delays
    [876]  = { augId = 320,  base = 1,   mult = 1,   disp = 1,    cat = 9,  tier = 4, label = 'Blood Pact ability delay' },
    [912]  = { augId = 324,  base = 1,   mult = 1,   disp = 1,    cat = 9,  tier = 4, label = 'Call Beast ability delay' },
    [1623] = { augId = 325,  base = 1,   mult = 1,   disp = 1,    cat = 9,  tier = 4, label = 'Quick Draw ability delay' },
    [832]  = { augId = 340,  base = 1,   mult = 1,   disp = 1,    cat = 9,  tier = 4, label = 'Phantom Roll ability delay' },

    -- ── cat 10: INT ───────────────────────────────────────────────────────────
    [921]  = { augId = 516,  base = 1,   mult = 1,   disp = 1,    cat = 10, tier = 1, label = 'INT' },
    [2510] = { augId = 1248, base = 1,   mult = 1,   disp = 1,    cat = 10, tier = 1, label = 'Enhancing Magic Effect Duration' },
    [2640] = { augId = 1249, base = 1,   mult = 1,   disp = 1,    cat = 10, tier = 4, label = 'Helix Effect Duration' },

    -- ── cat 11: Magic ATK ─────────────────────────────────────────────────────
    [886]  = { augId = 64,   base = 1,   mult = 2,   disp = 1,    cat = 11, tier = 1, label = 'Mag. Acc' },
    [905]  = { augId = 70,   base = 1,   mult = 2,   disp = 1,    cat = 11, tier = 4, label = 'Mag. Acc. Mag.Atk.Bns' },
    [909]  = { augId = 80,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 2, label = 'Mag. Acc./Mag. Dmg' },
    [2426] = { augId = 133,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 3, label = 'Mag.Atk.Bns' },
    [2498] = { augId = 362,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 3, label = 'Magic Damage' },
    [2427] = { augId = 140,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 1, label = 'Fast Cast' },
    [2428] = { augId = 237,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 4, label = 'Occult Acumen' },
    [2776] = { augId = 334,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 3, label = 'Magic burst dmg' },
    [2777] = { augId = 335,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 3, label = 'Mag. crit. hit dmg' },
    [842]  = { augId = 57,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 3, label = 'Magic crit. hit rate' },
    [2943] = { augId = 343,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 1, label = 'Drain/Aspir Potency' },
    [2338] = { augId = 896,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 2, label = 'Enspell Dmg' },
    [854]  = { augId = 53,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 1, label = 'Spell interruption rate down 1%' },
    [2834] = { augId = 1157, base = 2,   mult = 1,   disp = 1,    cat = 11, tier = 1, label = 'Spell Interruption Rate Down 2%' },
    [2507] = { augId = 351,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 4, label = 'Occ. quickens spellcasting' },
    -- Elemental / Enfeebling / Enhancing magic recast delays
    [849]  = { augId = 348,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Elemental Magic Recast Delay' },
    [859]  = { augId = 349,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Enfeebling Magic Recast Delay' },
    [868]  = { augId = 355,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Enhancing Magic Recast Delay' },
    -- Element affinity + magic accuracy
    [2506] = { augId = 936,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Fire Affinity Magic Accuracy' },
    [2509] = { augId = 937,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Ice Affinity Magic Accuracy' },
    [2522] = { augId = 938,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Wind Affinity Magic Accuracy' },
    [2749] = { augId = 939,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Earth Affinity Magic Accuracy' },
    [2890] = { augId = 940,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Lightning Affinity Magic Accuracy' },
    [2938] = { augId = 941,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Water Affinity Magic Accuracy' },
    [3502] = { augId = 942,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Light Affinity Magic Accuracy' },
    [3930] = { augId = 943,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Dark Affinity Magic Accuracy' },
    [3941] = { augId = 960,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 4, label = 'Fire Affinity Magic Accuracy Recast time' },
    -- Custom magic augments
    [2335] = { augId = 2044, base = 1,   mult = 15,  disp = 1,    cat = 11, tier = 4, label = 'Helix Damage',          maxBoost = 31 },
    [2531] = { augId = 2045, base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Spikes Dmg',            maxBoost = 31 },
    [2875] = { augId = 2048, base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 5, label = 'Immunobreak Chance+',   maxBoost = 31 },

    -- ── cat 12: MND ───────────────────────────────────────────────────────────
    [888]  = { augId = 517,  base = 1,   mult = 1,   disp = 1,    cat = 12, tier = 1, label = 'MND' },

    -- ── cat 13: Healing ───────────────────────────────────────────────────────
    [833]  = { augId = 329,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 1, label = 'Cure potency' },
    [887]  = { augId = 356,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 1, label = 'Potency of Cure received' },
    [792]  = { augId = 289,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 1, label = 'Healing magic skill' },
    [793]  = { augId = 323,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 4, label = 'Cure spellcasting time' },
    [1741] = { augId = 330,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 1, label = 'Waltz potency' },
    [801]  = { augId = 331,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 4, label = 'Waltz ability delay' },
    [836]  = { augId = 342,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 4, label = 'Waltz TP cost' },
    [838]  = { augId = 347,  base = 1,   mult = 1,   disp = 1,    cat = 13, tier = 1, label = 'Healing Magic Recast Delay' },

    -- ── cat 14: CHR ───────────────────────────────────────────────────────────
    [2841] = { augId = 518,  base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'CHR' },
    [902]  = { augId = 43,   base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'Charm' },
    [2372] = { augId = 188,  base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'Resist Charm' },
    [1291] = { augId = 67,   base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 5, label = 'All songs',             maxBoost = 1 },
    [817]  = { augId = 337,  base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'Song recast delay' },
    [2827] = { augId = 322,  base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'Song spellcasting time' },
    [1858] = { augId = 148,  base = 1,   mult = 1,   disp = 1,    cat = 14, tier = 1, label = 'Gilfinder' },

    -- ── cat 15: Enmity ────────────────────────────────────────────────────────
    [787]  = { augId = 39,   base = 1,   mult = 1,   disp = 1,    cat = 15, tier = 1, label = 'Enmity' },
    [901]  = { augId = 40,   base = 1,   mult = 1,   disp = 1,    cat = 15, tier = 1, label = 'Enmity' },

    -- ── cat 16: HP ────────────────────────────────────────────────────────────
    [860]  = { augId = 4,    base = 1,   mult = 4,   disp = 1,    cat = 16, tier = 1, label = 'HP' },
    [867]  = { augId = 18,   base = 1,   mult = 2,   disp = 1,    cat = 16, tier = 3, label = 'HP MP' },

    -- ── cat 17: Regen ─────────────────────────────────────────────────────────
    [848]  = { augId = 137,  base = 1,   mult = 4,   disp = 1,    cat = 17, tier = 4, label = 'Regen' },
    [850]  = { augId = 371,  base = 1,   mult = 1,   disp = 1,    cat = 17, tier = 1, label = 'Regen Potency' },
    [1122] = { augId = 51,   base = 1,   mult = 4,   disp = 1,    cat = 17, tier = 0, label = 'HP recovered while healing' },

    -- ── cat 18: MP ────────────────────────────────────────────────────────────
    [841]  = { augId = 12,   base = 1,   mult = 4,   disp = 1,    cat = 18, tier = 1, label = 'MP' },
    [791]  = { augId = 52,   base = 1,   mult = 4,   disp = 1,    cat = 18, tier = 0, label = 'MP recovered while healing' },

    -- ── cat 19: Refresh ───────────────────────────────────────────────────────
    [919]  = { augId = 138,  base = 1,   mult = 2,   disp = 1,    cat = 19, tier = 1, label = 'Refresh' },
    [1119] = { augId = 141,  base = 1,   mult = 1,   disp = 1,    cat = 19, tier = 1, label = 'Conserve MP' },

    -- ── cat 20: Pet ───────────────────────────────────────────────────────────
    -- Pet stats pulled from old cat 1
    [1615] = { augId = 97,   base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Attack Rng.Atk' },
    [1718] = { augId = 109,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Dbl.Atk. Crit.hit rate' },
    [786]  = { augId = 112,  base = 1,   mult = 100, disp = 100,  cat = 20, tier = 1, label = 'Pet Damage taken' },
    [853]  = { augId = 114,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Rng.Atk' },
    [855]  = { augId = 118,  base = 1,   mult = 100, disp = 100,  cat = 20, tier = 1, label = 'Pet Phys. dmg. taken' },
    [856]  = { augId = 122,  base = 20,  mult = 1,   disp = 1,    cat = 20, tier = 0, label = 'Pet TP Bonus' },
    [857]  = { augId = 123,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Dbl.Att' },
    [863]  = { augId = 127,  base = 1,   mult = 100, disp = 100,  cat = 20, tier = 1, label = 'Pet Magic Damage Taken' },
    [2169] = { augId = 1806, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet STR DEX VIT' },
    -- Pet stats pulled from old cat 2
    [922]  = { augId = 96,   base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Accuracy Rng.Acc' },
    [935]  = { augId = 102,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Crit.hit rate' },
    [939]  = { augId = 103,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Enemy crit. hit rate' },
    [1124] = { augId = 106,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Accuracy Rng.Acc' },
    [1288] = { augId = 113,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Rng.Acc' },
    [1289] = { augId = 115,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Store TP' },
    [1290] = { augId = 116,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Subtle Blow' },
    [2842] = { augId = 1793, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet DEX' },
    -- Pet stats pulled from old cat 3
    [2854] = { augId = 99,   base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet DEF' },
    [768]  = { augId = 119,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag.Def.Bns' },
    [775]  = { augId = 1247, base = 1,   mult = 200, disp = 100,  cat = 20, tier = 1, label = 'Pet Magic Dmg. Taken' },
    [803]  = { augId = 1794, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet VIT' },
    -- Pet stats pulled from old cat 4
    [825]  = { augId = 98,   base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Evasion' },
    [826]  = { augId = 111,  base = 1,   mult = 2,   disp = 10.24, cat = 20, tier = 2, label = 'Pet Haste' },
    [827]  = { augId = 117,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag. Evasion' },
    [810]  = { augId = 336,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 3, label = 'Sic and Ready ability delay' },
    [1861] = { augId = 1795, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet AGI' },
    -- Pet stats pulled from old cat 5
    [914]  = { augId = 100,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag.Acc' },
    [954]  = { augId = 101,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag.Atk.Bns' },
    [1518] = { augId = 108,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag.Acc. Mag.Atk.Bns' },
    [1521] = { augId = 120,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Avatar Mag.Atk.Bns' },
    [2157] = { augId = 125,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Mag.Acc. Mag.Dmg' },
    [2163] = { augId = 126,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Magic Damage' },
    [2847] = { augId = 1796, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet INT' },
    -- Pet stats pulled from old cat 6
    [2198] = { augId = 1797, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet MND' },
    -- Pet stats pulled from old cat 7
    [1408] = { augId = 104,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 0, label = 'Pet Enmity' },
    [1453] = { augId = 105,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 0, label = 'Pet Enmity' },
    [2850] = { augId = 1798, base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet CHR' },
    -- Pet stats pulled from old cat 8
    [1133] = { augId = 110,  base = 1,   mult = 4,   disp = 1,    cat = 20, tier = 1, label = 'Pet Regen' },
    -- Core pet utilities (old cat 10)
    [839]  = { augId = 124,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Pet Acc R.Acc Atk. R.Atk' },
    [852]  = { augId = 233,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 0, label = 'Blood Boon' },
    [1015] = { augId = 294,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Summoning magic skill' },
    [1156] = { augId = 321,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 0, label = 'Avatar perpetuation cost' },
    [1272] = { augId = 339,  base = 1,   mult = 5,   disp = 1,    cat = 20, tier = 0, label = 'Elemental Siphon' },
    [1445] = { augId = 369,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 1, label = 'Avatar Blood Pact Dmg' },
    [1979] = { augId = 1246, base = 1,   mult = 200, disp = 100,  cat = 20, tier = 1, label = 'Pet Phy. Dmg. Taken' },
    -- Avatar element affinities (old cat 11)
    [1268] = { augId = 952,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Fire Affinity Avatar perp. cost' },
    [1270] = { augId = 953,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Ice Affinity Avatar perp. cost' },
    [1295] = { augId = 954,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Wind Affinity Avatar perp. cost' },
    [1311] = { augId = 955,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Earth Affinity Avatar perp. cost' },
    [1313] = { augId = 957,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Water Affinity Avatar perp. cost' },
    [1414] = { augId = 958,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Light Affinity Avatar perp. cost' },
    [1443] = { augId = 959,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Dark Affinity Avatar perp. cost' },
    [1830] = { augId = 956,  base = 1,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Thunder Affinity Avatar perp. cost' },
    -- Beast affinity
    [2518] = { augId = 2100, base = 5,   mult = 1,   disp = 1,    cat = 20, tier = 4, label = 'Beast Affinity',        maxBoost = 31 },

    -- ── cat 21: Ele Resist ────────────────────────────────────────────────────
    [1132] = { augId = 796,  base = 10,  mult = 1,   disp = 1,    cat = 21, tier = 0, label = 'All elemental resists' },
    [1158] = { augId = 797,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 0, label = 'All elemental resists' },
    -- Element affinities (passive elemental identity, not resists)
    [1165] = { augId = 928,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Fire Affinity' },
    [1186] = { augId = 929,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Ice Affinity' },
    [1187] = { augId = 930,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Wind Affinity' },
    [1200] = { augId = 931,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Earth Affinity' },
    [1201] = { augId = 932,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Lightning Affinity' },
    [1236] = { augId = 933,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Water Affinity' },
    [1237] = { augId = 934,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Light Affinity' },
    [1263] = { augId = 935,  base = 1,   mult = 1,   disp = 1,    cat = 21, tier = 4, label = 'Dark Affinity' },
    [1850] = { augId = 1370, base = 1,   mult = 10,  disp = 1,    cat = 21, tier = 0, label = 'Enhances' },

    -- ── cat 22: Status ────────────────────────────────────────────────────────
    [2831] = { augId = 61,   base = 1,   mult = 1,   disp = 1,    cat = 22, tier = 2, label = 'Occ. inc. resist to stat ailments' },

    -- ── cat 23: Skills ────────────────────────────────────────────────────────
    -- Weapon skills
    [923]  = { augId = 257,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Hand-to-Hand skill' },
    [864]  = { augId = 258,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Dagger skill' },
    [894]  = { augId = 259,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Sword skill' },
    [916]  = { augId = 260,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Great Sword skill' },
    [920]  = { augId = 261,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Axe skill' },
    [925]  = { augId = 262,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Great Axe skill' },
    [940]  = { augId = 263,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Scythe skill' },
    [944]  = { augId = 264,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Polearm skill' },
    [953]  = { augId = 265,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Katana skill' },
    [1264] = { augId = 266,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Great Katana skill' },
    [1446] = { augId = 267,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Club skill' },
    [1592] = { augId = 268,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Staff skill' },
    [1616] = { augId = 278,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Melee skill' },
    [1663] = { augId = 279,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Ranged skill' },
    [1864] = { augId = 280,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Magic skill' },
    [2361] = { augId = 281,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Archery skill' },
    [2513] = { augId = 282,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Marksmanship skill' },
    [2524] = { augId = 283,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Throwing skill' },
    [2936] = { augId = 286,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Shield skill' },
    [2937] = { augId = 287,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Parrying Skill' },
    -- Magic skills
    [1725] = { augId = 288,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Divine magic skill' },
    [824]  = { augId = 293,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Dark magic skill' },
    [1740] = { augId = 290,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Enha.mag. skill' },
    [1817] = { augId = 291,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Enfb.mag. skill' },
    [1854] = { augId = 292,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Elem. magic skill' },
    [2154] = { augId = 295,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Ninjutsu skill' },
    [2155] = { augId = 296,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Singing skill' },
    [2161] = { augId = 297,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'String instrument skill' },
    [831]  = { augId = 298,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Wind instrument skill' },
    [2171] = { augId = 299,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Blue Magic skill' },
    [2212] = { augId = 300,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Geomancy Skill' },
    [2334] = { augId = 301,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 1, label = 'Handbell Skill' },
    -- Exp/Cap points
    [2523] = { augId = 73,   base = 33,  mult = 1,   disp = 1,    cat = 23, tier = 0, label = 'Exp. Point +33%' },
    [942]  = { augId = 75,   base = 33,  mult = 1,   disp = 1,    cat = 23, tier = 2, label = 'Cap. Point +33%' },
    -- Job-specific niche utilities
    [1875] = { augId = 2046, base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 5, label = 'Phantom Roll effect',   maxBoost = 0 },
    [1269] = { augId = 215,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 0, label = 'Ninja tool expertise' },
    [2729] = { augId = 341,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 0, label = 'Repair potency' },
    [2641] = { augId = 1250, base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 0, label = 'Indi Effect Duration' },
    [908]  = { augId = 147,  base = 1,   mult = 1,   disp = 1,    cat = 23, tier = 0, label = 'Treasure Hunter', maxBoost = 0 },

    -- ── cat 24: WSD+ ──────────────────────────────────────────────────────────
    [1110] = { augId = 326,  base = 1,   mult = 1,   disp = 1,    cat = 24, tier = 2, label = 'Weapon Skill Acc' },
    [1473] = { augId = 327,  base = 1,   mult = 1,   disp = 1,    cat = 24, tier = 5, label = 'Weapon skill damage' },
    [865]  = { augId = 332,  base = 1,   mult = 100, disp = 100,  cat = 24, tier = 4, label = 'Sklchn.dmg' },
    [889]  = { augId = 743,  base = 1,   mult = 1,   disp = 1,    cat = 24, tier = 4, label = 'Dmg (melee,not ranged)' },
}
