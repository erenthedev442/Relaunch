-----------------------------------
-- augment_catalog.lua
-- Maps catalyst item IDs to augment definitions.
-- One catalyst per augmentId. Trade the catalyst to the Augment Moogle
-- to apply the augment. The exdata value is 0 (uses the SQL base value).
--
-- Each entry: { augId=N, base=N, mult=N, disp=N, cat=N, tier=N, label='...' }
--   base : EFFECTIVE per-slot base value
--   mult : EFFECTIVE multiplier (engine: (base + boost) * mult)
--   disp : display divisor (mods stored xN divided for human display)
--   cat  : 1..11 thematic category (Sage affinity bonus key)
--            1  = Base stats
--            2  = Melee
--            3  = Magic
--            4  = Defense
--            5  = Delays
--            6  = Duration
--            7  = Pets
--            8  = Potency
--            9  = Skills
--            10 = Exp/Cap Points
--            11 = Job specific niche utilities
--   tier : 0 for all augments (RELAUNCH: every augment available at every
--          content tier; power scales via the player's Augment Tier roll band).
--   label: stat name only.
-----------------------------------
return {
    -- ── cat 1: Base stats ───────────────────────────────────────────────────────
    [1620] = { augId = 512,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'STR' },
    [2150] = { augId = 513,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'DEX' },
    [773]  = { augId = 514,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'VIT' },
    [878]  = { augId = 515,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'AGI' },
    [921]  = { augId = 516,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'INT' },
    [888]  = { augId = 517,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'MND' },
    [2841] = { augId = 518,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'CHR' },
    [860]  = { augId = 4,    base = 1,   mult = 4,   disp = 1,    cat = 1, tier = 0, label = 'HP' },
    [867]  = { augId = 18,   base = 1,   mult = 2,   disp = 1,    cat = 1, tier = 0, label = 'HP MP' },
    [841]  = { augId = 12,   base = 1,   mult = 4,   disp = 1,    cat = 1, tier = 0, label = 'MP' },

    -- ── cat 2: Melee ────────────────────────────────────────────────────────────
    [861]  = { augId = 65,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Attack' },
    [883]  = { augId = 66,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Attack' },
    [874]  = { augId = 130,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Attack Rng.Atk' },
    [880]  = { augId = 132,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Dbl.Atk. Crit.hit rate' },
    [882]  = { augId = 143,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Dbl.Atk' },
    [891]  = { augId = 144,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Triple Atk' },
    [1271] = { augId = 353,  base = 1,   mult = 4,   disp = 1,    cat = 2,  tier = 0, label = 'TP Bonus' },
    [1293] = { augId = 354,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Quadruple Attack' },
    [1108] = { augId = 333,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Conserve TP' },
    [1516] = { augId = 360,  base = 10,  mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Save TP' },
    [2148] = { augId = 41,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Crit.hit rate' },
    [2149] = { augId = 328,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Crit. hit damage' },
    [840]  = { augId = 44,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Store TP Subtle Blow' },
    [1621] = { augId = 142,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Store TP' },
    [1690] = { augId = 195,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Subtle Blow' },
    [846]  = { augId = 62,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy' },
    [847]  = { augId = 63,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Accuracy' },
    [1292] = { augId = 129,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy Rng.Acc' },
    [884]  = { augId = 68,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy Attack' },
    [1116] = { augId = 69,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Acc. Rng.Atk' },
    [1110] = { augId = 326,  base = 1,   mult = 1,   disp = 1,    cat = 2, tier = 0, label = 'Weapon Skill Acc' },
    [1473] = { augId = 327,  base = 1,   mult = 1,   disp = 1,    cat = 2, tier = 0, label = 'Weapon skill damage' },
    [865]  = { augId = 332,  base = 1,   mult = 100, disp = 100,  cat = 2, tier = 0, label = 'Sklchn.dmg' },

    -- ── cat 3: Magic ────────────────────────────────────────────────────────────
    [886]  = { augId = 64,   base = 1,   mult = 2,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc' },
    [905]  = { augId = 70,   base = 1,   mult = 2,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc. Mag.Atk.Bns' },
    [909]  = { augId = 80,   base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc./Mag. Dmg' },
    [2426] = { augId = 133,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag.Atk.Bns' },
    [2498] = { augId = 362,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic Damage' },
    [2427] = { augId = 140,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Fast Cast' },
    [2428] = { augId = 237,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Occult Acumen' },
    [2776] = { augId = 334,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic burst dmg' },
    [2777] = { augId = 335,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag. crit. hit dmg' },
    [842]  = { augId = 57,   base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic crit. hit rate' },
    [2338] = { augId = 896,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Enspell Dmg' },
    [2834] = { augId = 1157, base = 2,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Spell Interruption Rate Down' },
    [2507] = { augId = 351,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Occ. quickens spellcasting' },
    [2335] = { augId = 2044, base = 1,   mult = 15,  disp = 1,    cat = 3, tier = 0, label = 'Helix Damage',          maxBoost = 31 },
    [2531] = { augId = 2045, base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Spikes Dmg',            maxBoost = 31 },
    [2875] = { augId = 2048, base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Immunobreak Chance+',   maxBoost = 31 },
    [1850] = { augId = 1370, base = 1,   mult = 10,  disp = 1,    cat = 3, tier = 0, label = 'Enhances' },

    -- ── cat 4: Defense ──────────────────────────────────────────────────────────
    [774]  = { augId = 1152, base = 1,   mult = 10,  disp = 1,    cat = 4,  tier = 0, label = 'DEF' },
    [769]  = { augId = 134,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Mag.Def.Bns' },
    [936]  = { augId = 55,   base = 1,   mult = 100, disp = 100,  cat = 4,  tier = 0, label = 'Magic dmg. taken' },
    [1193] = { augId = 56,   base = 1,   mult = 100, disp = 100,  cat = 4,  tier = 0, label = 'Breath dmg. taken' },
    [858]  = { augId = 54,   base = 1,   mult = 100, disp = 100,  cat = 4,  tier = 0, label = 'Phys. dmg. taken' },
    [1123] = { augId = 71,   base = 1,   mult = 100, disp = 100,  cat = 4,  tier = 0, label = 'Damage Taken' },
    [2151] = { augId = 1155, base = 1,   mult = 200, disp = 100,  cat = 4,  tier = 0, label = 'Physical Damage Taken' },
    [2158] = { augId = 1156, base = 1,   mult = 200, disp = 100,  cat = 4,  tier = 0, label = 'Magic Damage Taken' },
    [771]  = { augId = 363,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Chance of successful block' },
    [772]  = { augId = 368,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Phalanx Received' },
    [776]  = { augId = 1472, base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Parrying rate' },
    [3504] = { augId = 42,   base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Enemy crit. hit rate' },
    [1617] = { augId = 1153, base = 3,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Evasion' },
    [1713] = { augId = 1154, base = 3,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Mag. Evasion' },
    [2372] = { augId = 188,  base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Resist Charm' },
    [787]  = { augId = 39,   base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Enmity' },
    [1132] = { augId = 796,  base = 10,  mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'All elemental resists' },
    [2831] = { augId = 61,   base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Occ. inc. resist to stat ailments' },

    -- ── cat 5: Delays ───────────────────────────────────────────────────────────
    [820]  = { augId = 49,   base = 1,   mult = 2,   disp = 10.24, cat = 5,  tier = 0, label = 'Haste' },
    [828]  = { augId = 186,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 0, label = 'Resist Slow' },
    [876]  = { augId = 320,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 0, label = 'Blood Pact ability delay' },
    [912]  = { augId = 324,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 0, label = 'Call Beast ability delay' },
    [1623] = { augId = 325,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 0, label = 'Quick Draw ability delay' },
    [832]  = { augId = 340,  base = 1,   mult = 1,   disp = 1,    cat = 5,  tier = 0, label = 'Phantom Roll ability delay' },
    [849]  = { augId = 348,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Elemental Magic Recast Delay' },
    [859]  = { augId = 349,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Enfeebling Magic Recast Delay' },
    [868]  = { augId = 355,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Enhancing Magic Recast Delay' },
    [793]  = { augId = 323,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Cure spellcasting time' },
    [801]  = { augId = 331,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Waltz ability delay' },
    [838]  = { augId = 347,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Healing Magic Recast Delay' },
    [817]  = { augId = 337,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Song recast delay' },
    [2827] = { augId = 322,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Song spellcasting time' },

    -- ── cat 6: Duration ─────────────────────────────────────────────────────────
    [2711] = { augId = 1264, base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 0, label = 'Meditate Effect Duration' },
    [2510] = { augId = 1248, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Enhancing Magic Effect Duration' },
    [2640] = { augId = 1249, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Helix Effect Duration' },
    [2641] = { augId = 1250, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Indi Effect Duration' },

    -- ── cat 7: Pets ─────────────────────────────────────────────────────────────
    [1718] = { augId = 109,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Dbl.Atk. Crit.hit rate' },
    [856]  = { augId = 122,  base = 20,  mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet TP Bonus' },
    [2169] = { augId = 1806, base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet STR DEX VIT' },
    [939]  = { augId = 103,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Enemy crit. hit rate' },
    [1289] = { augId = 115,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Store TP' },
    [1290] = { augId = 116,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Subtle Blow' },
    [2854] = { augId = 99,   base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet DEF' },
    [768]  = { augId = 119,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag.Def.Bns' },
    [775]  = { augId = 1247, base = 1,   mult = 200, disp = 100,  cat = 7, tier = 0, label = 'Pet Magic Dmg. Taken' },
    [825]  = { augId = 98,   base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Evasion' },
    [826]  = { augId = 111,  base = 1,   mult = 2,   disp = 10.24, cat = 7, tier = 0, label = 'Pet Haste' },
    [827]  = { augId = 117,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag. Evasion' },
    [810]  = { augId = 336,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Sic and Ready ability delay' },
    [1518] = { augId = 108,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag.Acc. Mag.Atk.Bns' },
    [2163] = { augId = 126,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Magic Damage' },
    [1408] = { augId = 104,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Enmity' },
    [1133] = { augId = 110,  base = 1,   mult = 4,   disp = 1,    cat = 7, tier = 0, label = 'Pet Regen' },
    [839]  = { augId = 124,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Acc R.Acc Atk. R.Atk' },
    [852]  = { augId = 233,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Blood Boon' },
    [1156] = { augId = 321,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Avatar perpetuation cost' },
    [1272] = { augId = 339,  base = 1,   mult = 5,   disp = 1,    cat = 7, tier = 0, label = 'Elemental Siphon' },
    [1445] = { augId = 369,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Avatar Blood Pact Dmg' },
    [1979] = { augId = 1246, base = 1,   mult = 200, disp = 100,  cat = 7, tier = 0, label = 'Pet Phy. Dmg. Taken' },
    [2518] = { augId = 2100, base = 5,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Beast Affinity',        maxBoost = 31 },

    -- ── cat 8: Potency ──────────────────────────────────────────────────────────
    [2943] = { augId = 343,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Drain/Aspir Potency' },
    [833]  = { augId = 329,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Cure potency' },
    [887]  = { augId = 356,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Potency of Cure received' },
    [1741] = { augId = 330,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Waltz potency' },
    [848]  = { augId = 137,  base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'Regen' },
    [850]  = { augId = 371,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Regen Potency' },
    [1122] = { augId = 51,   base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'HP recovered while healing' },
    [791]  = { augId = 52,   base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'MP recovered while healing' },
    [919]  = { augId = 138,  base = 1,   mult = 2,   disp = 1,    cat = 8, tier = 0, label = 'Refresh' },
    [1119] = { augId = 141,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Conserve MP' },
    [1875] = { augId = 2046, base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Phantom Roll effect',   maxBoost = 0 },
    [2729] = { augId = 341,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Repair potency' },

    -- ── cat 9: Skills ───────────────────────────────────────────────────────────
    [1616] = { augId = 278,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Melee skill' },
    [1663] = { augId = 279,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Ranged skill' },
    [1864] = { augId = 280,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Magic skill' },
    [2936] = { augId = 286,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Shield skill' },
    [2937] = { augId = 287,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Parrying Skill' },

    -- ── cat 10: Exp/Cap Points ──────────────────────────────────────────────────
    [2523] = { augId = 73,   base = 33,  mult = 1,   disp = 1,    cat = 10, tier = 0, label = 'Exp. Point +33%' },
    [942]  = { augId = 75,   base = 33,  mult = 1,   disp = 1,    cat = 10, tier = 0, label = 'Cap. Point +33%' },

    -- ── cat 11: Job specific niche utilities ────────────────────────────────────
    [897]  = { augId = 151,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Martial Arts' },
    [903]  = { augId = 194,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Kick Attacks Rate or Damage' },
    [2147] = { augId = 640,  base = 1,   mult = 2,   disp = 1,    cat = 11,  tier = 0, label = 'Counter' },
    [1591] = { augId = 370,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Reverse Flourish' },
    [926]  = { augId = 198,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Zanshin' },
    [947]  = { augId = 251,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Daken' },
    [1619] = { augId = 139,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Rapid Shot' },
    [1199] = { augId = 338,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Barrage' },
    [770]  = { augId = 153,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Shield Mastery' },
    [834]  = { augId = 212,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Recycle' },
    [829]  = { augId = 211,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Snapshot' },
    [836]  = { augId = 342,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Waltz TP cost' },
    [902]  = { augId = 43,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Charm' },
    [1291] = { augId = 67,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'All songs',             maxBoost = 1 },
    [1858] = { augId = 148,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Gilfinder' },
    [1269] = { augId = 215,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Ninja tool expertise' },
    [908]  = { augId = 147,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Treasure Hunter', maxBoost = 0 },

}
