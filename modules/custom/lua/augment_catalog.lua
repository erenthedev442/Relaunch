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
--
-- OWNER REBALANCE 2026-07-11 (source: exports/augment_catalog_export_reworked.xlsx):
--   Per-augment maxBoost ceilings tightened on 19 rows (crit/multi-attack/
--   Fast Cast/Store TP/Subtle Blow/PDT/Spikes/Spell Interruption/Phalanx
--   Received/Cure cast time/Gilfinder/Exp+Cap Points). FUTURE ROLLS ONLY --
--   no sql/augments.sql change, so gear augmented before this keeps its old
--   values (grandfathered). Exp./Cap. Point: the owner target (1..32%/slot)
--   needs the engine base (33) changed in sql/augments.sql; Lua-only closest
--   fit is maxBoost=0 -> flat +33%/slot at every tier.
--   Save TP / All elemental resists / Pet TP Bonus keep their high base
--   offsets by owner decision (ceiling kept over low floor).
-----------------------------------
return {
    -- ── cat 1: Base stats ───────────────────────────────────────────────────────
    [1620] = { augId = 512,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'STR' },
    [2150] = { augId = 513,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'DEX' },
    [922]  = { augId = 514,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'VIT' },
    [878]  = { augId = 515,  base = 1,   mult = 1,   disp = 1,    cat = 1,  tier = 0, label = 'AGI' },
    [921]  = { augId = 516,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'INT' },
    [888]  = { augId = 517,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'MND' },
    [2823] = { augId = 518,  base = 1,   mult = 1,   disp = 1,    cat = 1, tier = 0, label = 'CHR' },
    [853]  = { augId = 4,    base = 1,   mult = 4,   disp = 1,    cat = 1, tier = 0, label = 'HP' },
    [818]  = { augId = 18,   base = 1,   mult = 2,   disp = 1,    cat = 1, tier = 0, label = 'HP MP' },
    [841]  = { augId = 12,   base = 1,   mult = 4,   disp = 1,    cat = 1, tier = 0, label = 'MP' },

    -- ── cat 2: Melee ────────────────────────────────────────────────────────────
    [861]  = { augId = 65,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Attack' },
    [937]  = { augId = 66,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Attack' },
    [1622]  = { augId = 130,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Attack Rng.Atk' },
    [880]  = { augId = 132,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Dbl.Atk. Crit.hit rate', maxBoost = 1 },
    [882]  = { augId = 143,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Dbl.Atk', maxBoost = 3 },
    [891]  = { augId = 144,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Triple Atk', maxBoost = 4 },
    [855] = { augId = 353,  base = 1,   mult = 4,   disp = 1,    cat = 2,  tier = 0, label = 'TP Bonus' },
    [857] = { augId = 370,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Reverse Flourish' },
    [2157] = { augId = 333,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Conserve TP' },
    [1516] = { augId = 360,  base = 10,  mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Save TP' },
    [2148] = { augId = 41,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Crit.hit rate', maxBoost = 4 },
    [2149] = { augId = 328,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Crit. hit damage', maxBoost = 4 },
    [935]  = { augId = 44,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Store TP Subtle Blow', maxBoost = 9 },
    [1621] = { augId = 142,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Store TP', maxBoost = 12 },
    [1690] = { augId = 195,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Subtle Blow', maxBoost = 12 },
    [846]  = { augId = 62,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy' },
    [847]  = { augId = 63,   base = 1,   mult = 2,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Accuracy' },
    [927] = { augId = 129,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy Rng.Acc' },
    [884]  = { augId = 68,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Accuracy Attack' },
    [1116] = { augId = 69,   base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Rng.Acc. Rng.Atk' },
    [1521] = { augId = 326,  base = 1,   mult = 1,   disp = 1,    cat = 2, tier = 0, label = 'Weapon Skill Acc' },
    [1473] = { augId = 327,  base = 1,   mult = 1,   disp = 1,    cat = 2, tier = 0, label = 'Weapon skill damage', maxBoost = 9 },
    [1163]  = { augId = 332,  base = 1,   mult = 100, disp = 100,  cat = 2, tier = 0, label = 'Sklchn.dmg', maxBoost = 9 },

    -- ── cat 3: Magic ────────────────────────────────────────────────────────────
    [886]  = { augId = 64,   base = 1,   mult = 2,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc' },
    [954]  = { augId = 70,   base = 1,   mult = 2,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc. Mag.Atk.Bns' },
    [909]  = { augId = 80,   base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag. Acc./Mag. Dmg' },
    [2426] = { augId = 133,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag.Atk.Bns', maxBoost = 14 },
    [1474] = { augId = 362,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic Damage' },
    [2427] = { augId = 140,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Fast Cast', maxBoost = 3 },
    [2428] = { augId = 237,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Occult Acumen' },
    [2889] = { augId = 334,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic burst dmg', maxBoost = 9 },
    [943] = { augId = 335,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Mag. crit. hit dmg' },
    [842]  = { augId = 57,   base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Magic crit. hit rate' },
    [2338] = { augId = 896,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Enspell Dmg' },
    [2166] = { augId = 1157, base = 2,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Spell Interruption Rate Down', maxBoost = 3 },
    [2507] = { augId = 351,  base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Occ. quickens spellcasting', maxBoost = 9 },
    [2335] = { augId = 2044, base = 1,   mult = 15,  disp = 1,    cat = 3, tier = 0, label = 'Helix Damage',          maxBoost = 7 },
    [2531] = { augId = 2045, base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Spikes Dmg',            maxBoost = 9 },
    [1606] = { augId = 2048, base = 1,   mult = 1,   disp = 1,    cat = 3, tier = 0, label = 'Immunobreak Chance+',   maxBoost = 31 },
    [955] = { augId = 1370, base = 1,   mult = 10,  disp = 1,    cat = 3, tier = 0, label = 'Enhances Dark Seal (DRK)', maxBoost = 7 },

    -- ── cat 4: Defense ──────────────────────────────────────────────────────────
    [928]  = { augId = 1152, base = 1,   mult = 10,  disp = 1,    cat = 4,  tier = 0, label = 'DEF' },
    [881]  = { augId = 134,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Mag.Def.Bns' },
    [936]  = { augId = 55,   base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Magic DT' },
    [1193] = { augId = 56,   base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Breath dmg. taken' },
    [858]  = { augId = 54,   base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Phys DT', maxBoost = 14 },
    [1123] = { augId = 71,   base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Damage Taken' },
    [2151] = { augId = 1155, base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Phys DT II', maxBoost = 14 },
    [2747] = { augId = 1156, base = 3,   mult = 30,  disp = 100,  cat = 4,  tier = 0, label = 'Magic DT II' },
    [889]  = { augId = 363,  base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Chance of successful block', maxBoost = 9 },
    [2505]  = { augId = 1472, base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Parrying rate' },
    [3504] = { augId = 42,   base = 1,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Enemy crit. hit rate' },
    [1617] = { augId = 1153, base = 3,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Evasion' },
    [2520] = { augId = 1154, base = 3,   mult = 1,   disp = 1,    cat = 4,  tier = 0, label = 'Mag. Evasion' },
    [1470] = { augId = 188,  base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Resist Charm' },
    [2235]  = { augId = 39,   base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Enmity' },
    [2549] = { augId = 796,  base = 10,  mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'All elemental resists' },
    [1638] = { augId = 61,   base = 1,   mult = 1,   disp = 1,    cat = 4, tier = 0, label = 'Occ. inc. resist to stat ailments' },

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
    [2198]  = { augId = 323,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Cure spellcasting time', maxBoost = 4 },
    [816]  = { augId = 331,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Waltz ability delay' },
    [838]  = { augId = 347,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Healing Magic Recast Delay' },
    [817]  = { augId = 337,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Song recast delay' },
    [1667] = { augId = 322,  base = 1,   mult = 1,   disp = 1,    cat = 5, tier = 0, label = 'Song spellcasting time' },

    -- ── cat 6: Duration ─────────────────────────────────────────────────────────
    [2711] = { augId = 1264, base = 1,   mult = 1,   disp = 1,    cat = 6,  tier = 0, label = 'Meditate Effect Duration' },
    [2510] = { augId = 1248, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Enhancing Magic Effect Duration' },
    [2640] = { augId = 1249, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Helix Effect Duration' },
    [2641] = { augId = 1250, base = 1,   mult = 1,   disp = 1,    cat = 6, tier = 0, label = 'Indi Effect Duration' },

    -- ── cat 7: Pets ─────────────────────────────────────────────────────────────
    [2521] = { augId = 109,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Dbl.Atk. Crit.hit rate' },
    [856]  = { augId = 122,  base = 20,  mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet TP Bonus' },
    [938] = { augId = 1806, base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet STR DEX VIT' },
    [939]  = { augId = 103,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Enemy crit. hit rate' },
    [2543] = { augId = 115,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Store TP' },
    [918] = { augId = 116,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Subtle Blow' },
    [959] = { augId = 99,   base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet DEF' },
    [768]  = { augId = 119,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag.Def.Bns' },
    [2504]  = { augId = 1247, base = 3,   mult = 30,  disp = 100,  cat = 7, tier = 0, label = 'Pet Magic Dmg. Taken' },
    [825]  = { augId = 98,   base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Evasion' },
    [821]  = { augId = 111,  base = 1,   mult = 2,   disp = 10.24, cat = 7, tier = 0, label = 'Pet Haste' },
    [827]  = { augId = 117,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag. Evasion' },
    [914]  = { augId = 336,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Sic and Ready ability delay' },
    [1518] = { augId = 108,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Mag.Acc. Mag.Atk.Bns' },
    [2163] = { augId = 126,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Magic Damage' },
    [2888] = { augId = 104,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Enmity' },
    [1133] = { augId = 110,  base = 1,   mult = 4,   disp = 1,    cat = 7, tier = 0, label = 'Pet Regen' },
    [839]  = { augId = 124,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Pet Acc R.Acc Atk. R.Atk' },
    [852]  = { augId = 233,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Blood Boon' },
    [1156] = { augId = 321,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Avatar perpetuation cost' },
    [3543] = { augId = 339,  base = 1,   mult = 5,   disp = 1,    cat = 7, tier = 0, label = 'Elemental Siphon' },
    [1452] = { augId = 369,  base = 1,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Avatar Blood Pact Dmg', maxBoost = 11 },
    [2153] = { augId = 1246, base = 3,   mult = 30,  disp = 100,  cat = 7, tier = 0, label = 'Pet Phy. Dmg. Taken' },
    [2518] = { augId = 2100, base = 5,   mult = 1,   disp = 1,    cat = 7, tier = 0, label = 'Beast Affinity',        maxBoost = 31 },

    -- ── cat 8: Potency ──────────────────────────────────────────────────────────
    [1609] = { augId = 343,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Drain/Aspir Potency' },
    [952]  = { augId = 329,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Cure potency', maxBoost = 14 },
    [887]  = { augId = 356,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Potency of Cure received' },
    [1196] = { augId = 330,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Waltz potency' },
    [848]  = { augId = 137,  base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'Regen', maxBoost = 5 },
    [850]  = { augId = 371,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Regen Potency' },
    [1122] = { augId = 51,   base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'HP recovered while healing', maxBoost = 15 },
    [2514]  = { augId = 52,   base = 1,   mult = 4,   disp = 1,    cat = 8, tier = 0, label = 'MP recovered while healing', maxBoost = 15 },
    [919]  = { augId = 138,  base = 1,   mult = 2,   disp = 1,    cat = 8, tier = 0, label = 'Refresh', maxBoost = 5 },
    [1119] = { augId = 141,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Conserve MP' },
    [1875] = { augId = 2046, base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Phantom Roll effect',   maxBoost = 5 },
    [2748] = { augId = 341,  base = 1,   mult = 1,   disp = 1,    cat = 8, tier = 0, label = 'Repair potency' },

    -- ── cat 9: Skills ───────────────────────────────────────────────────────────
    -- Do NOT re-add the three "*.skill" auto-skill rows -- they map to PUP-
    -- automaton-only mods (LSB enum: "apply only to master, does not work
    -- properly on pet mods"), so a non-PUP player trading the catalyst got no
    -- effective boost. Trap fully purged 2026-07-13:
    --   [1616] Antlion Jaw          -> augId 278  mod 101 AUTO_MELEE_SKILL
    --   [1663] Arnica Root          -> augId 279  mod 102 AUTO_RANGED_SKILL
    --   [1889] Sack of White Sand   -> augId 280  mod 103 AUTO_MAGIC_SKILL
    -- Shield skill (mod 109) and Parrying (mod 110) below ARE real combat
    -- skills that work for anyone -- those stay.
    [1607] = { augId = 286,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Shield skill' },
    [1608] = { augId = 287,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Parrying Skill' },
    -- Treasure Hunter uses `flatValue` (not tierValue) so it grants a
    -- STRICT +1 TH per augmented gear piece regardless of the player's
    -- Augment Sage tier. Reason: TH scales the endgame drop table hard
    -- (each stack tier compounds vs low-% loot), and letting a single
    -- augment climb to +5 at T5 (then multiply across 8 gear slots =
    -- TH+40) was pushing rare drops to near-guaranteed. flatValue keeps
    -- the augment desirable (players still want TH+1 in every slot they
    -- can spare) without collapsing the drop economy. The `flatValue`
    -- branch in Augment_Moogle.lua inherits the tier-fixed guards
    -- (1 catalyst per trade, 1 line per item).
    [863]  = { augId = 147,  base = 1,   mult = 1,   disp = 1,    cat = 9, tier = 0, label = 'Treasure Hunter', maxBoost = 0, flatValue = 1 },

    -- ── cat 10: Exp/Cap Points ──────────────────────────────────────────────────
    -- maxBoost=0: owner target is 1..32%/slot, but the +33 base lives in the
    -- engine (sql/augments.sql) -- Lua-only closest fit = flat +33%/slot.
    [2523] = { augId = 73,   base = 33,  mult = 1,   disp = 1,    cat = 10, tier = 0, label = 'Exp. Point +33%', maxBoost = 0 },
    -- 942 kept over the 2026-07-10 re-pick (Goblin Mess Tin): the Infamy vendor
    -- sells Philosopher's Stone at 50 Infamy (infamy_vendor_catalog.lua), so it
    -- is purchasable and not NM-gated despite its NM-only retail droplist.
    [942]  = { augId = 75,   base = 33,  mult = 1,   disp = 1,    cat = 10, tier = 0, label = 'Cap. Point +33%', maxBoost = 0 },

    -- ── cat 11: Job specific niche utilities ────────────────────────────────────
    [897]  = { augId = 151,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Martial Arts' },
    [1615]  = { augId = 194,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Kick Attacks Rate or Damage' },
    [895]  = { augId = 640,  base = 1,   mult = 2,   disp = 1,    cat = 11,  tier = 0, label = 'Counter' },
    [1591] = { augId = 354,  base = 1,   mult = 1,   disp = 1,    cat = 2,  tier = 0, label = 'Quadruple Attack', maxBoost = 3 },
    [926]  = { augId = 198,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Zanshin' },
    [947]  = { augId = 251,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Daken' },
    [1619] = { augId = 139,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Rapid Shot' },
    [1199] = { augId = 338,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Barrage' },
    [770]  = { augId = 153,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Shield Mastery' },
    [834]  = { augId = 212,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Recycle' },
    [829]  = { augId = 211,  base = 1,   mult = 1,   disp = 1,    cat = 11,  tier = 0, label = 'Snapshot' },
    [836]  = { augId = 342,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Waltz TP cost' },
    [902]  = { augId = 43,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Charm' },
    [1888] = { augId = 67,   base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'All songs',             maxBoost = 1, tierValue = 2 },
    [1630] = { augId = 148,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Gilfinder', maxBoost = 19 },
    [1269] = { augId = 215,  base = 1,   mult = 1,   disp = 1,    cat = 11, tier = 0, label = 'Ninja tool expertise' },
    -- tierValue = STEP: the line's value is STEP x your Augment Tier (TH 1..5
    -- in cat 9 Skills, All songs 2..10 above). One catalyst per trade, no
    -- roll/affinity/crit; the Moogle writes boost = STEP*tier - base so the
    -- engine's (base + boost) renders exactly STEP*tier (requires effective
    -- mult 1). Old gear keeps its already-written slots.

}
