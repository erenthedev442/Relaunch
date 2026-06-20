-----------------------------------
-- augment_catalog.lua
-- Maps catalyst item IDs to augment definitions.
-- One catalyst per augmentId. Trade the catalyst to the Augment Moogle
-- to apply the augment. The exdata value is 0 (uses the SQL base value).
--
-- Filters applied:
--   - Skipped augments with no functional modifier (modId=0)
--   - Skipped negative-value augments on good-when-positive stats
--   - Every catalyst is verified obtainable via mob_droplist (mob drops
--     only, no crafted/fished/guild/gardened/synergy items)
--   - Foods, drinks, medicines, and other @USABLE_TYPE consumables are
--     excluded -- catalysts must be material drops from monsters
--   - RARE / EX items excluded (a Rare item can't be held in the
--     quantity a 4-at-a-time trade needs; an EX item can't be traded)
--   - Lesser augments dropped when a higher-power version of the same
--     stat already exists (e.g. Attack+1 removed; Attack+33 kept)
--   - Crafting kits excluded from the catalyst pool
--   - Augments dropped entirely if no thematic mob-drop catalyst exists
--
-- Each entry: { augId = N, base = N, mult = N, cat = N, label = '...' }
--   augId : index into sql/augments.sql (used for the actual augment)
--   base  : EFFECTIVE per-slot base the engine applies (the live value
--           after modules/custom/sql/zz_augment_rebalance.sql).
--   mult  : EFFECTIVE multiplier (engine uses mult>1 ? mult : 1).
--           Real per-slot value = (base + sageBoost 0..31) * mult.
--   disp  : display divisor -- mods stored at xN (damage-taken /100,
--           skillchain /100, ...) are divided by this so the Moogle /
--           !augstats / docs show the meaningful number. 1 = no scaling.
--   cat   : 1..13 thematic category, see CAT_NAMES in the generator.
--           Used by Augment_Sage to apply per-NM affinity bonuses.
--   label : stat NAME only -- flat numbers are stripped because every
--           augment scales with Augment Sage progress (see !augstats).
--
-- Generated from sql/augments.sql + sql/mob_droplist.sql.
-----------------------------------
return {
    -- Strength / Attack / Phys.dmg.taken
    [858]  = { augId = 54,   base = 1,   mult = 100, disp = 100,  cat = 1,  label = 'Phys. dmg. taken' },
    [861]  = { augId = 65,   base = 1,   mult = 2,  disp = 1,    cat = 1,  label = 'Attack' },
    [883]  = { augId = 66,   base = 1,   mult = 2,  disp = 1,    cat = 1,  label = 'Rng.Attack' },
    [884]  = { augId = 68,   base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Accuracy Attack' },
    [1116] = { augId = 69,   base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Rng.Acc. Rng.Atk' },
    [1123] = { augId = 71,   base = 1,   mult = 100, disp = 100,  cat = 1,  label = 'Damage Taken' },
    [1615] = { augId = 97,   base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet Attack Rng.Atk' },
    [1622] = { augId = 107,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet Attack Rng.Atk' },
    [1718] = { augId = 109,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet Dbl.Atk. Crit.hit rate' },
    [786]  = { augId = 112,  base = 1,   mult = 100, disp = 100,  cat = 1,  label = 'Pet Damage taken' },
    [853]  = { augId = 114,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet Rng.Atk' },
    [855]  = { augId = 118,  base = 1,   mult = 100, disp = 100,  cat = 1,  label = 'Pet Phys. dmg. taken' },
    [856]  = { augId = 122,  base = 20,  mult = 1,  disp = 1,    cat = 1,  label = 'Pet TP Bonus' },
    [857]  = { augId = 123,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet Dbl.Att' },
    [863]  = { augId = 127,  base = 1,   mult = 100, disp = 100,  cat = 1,  label = 'Pet Magic Damage Taken' },
    [874]  = { augId = 130,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Attack Rng.Atk' },
    [880]  = { augId = 132,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Dbl.Atk. Crit.hit rate' },
    [882]  = { augId = 143,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Dbl.Atk' },
    [891]  = { augId = 144,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Triple Atk' },
    [895]  = { augId = 145,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Counter' },
    [897]  = { augId = 146,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Dual Wield' },
    [903]  = { augId = 151,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Martial Arts' },
    [926]  = { augId = 194,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Kick Attacks Rate or Damage' },
    [947]  = { augId = 198,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Zanshin' },
    [1015] = { augId = 251,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Daken' },
    [1108] = { augId = 333,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Conserve TP' },
    [1199] = { augId = 338,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Barrage' },
    [1271] = { augId = 353,  base = 1,   mult = 2,  disp = 1,    cat = 1,  label = 'TP Bonus' },
    [1293] = { augId = 354,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Quadruple Attack' },
    [1516] = { augId = 360,  base = 10,  mult = 1,  disp = 1,    cat = 1,  label = 'Save TP' },
    [1591] = { augId = 370,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Reverse Flourish' },
    [1620] = { augId = 512,  base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'STR' },
    [2147] = { augId = 640,  base = 1,   mult = 2,  disp = 1,    cat = 1,  label = 'Counter' },
    [2151] = { augId = 1155, base = 1,   mult = 200, disp = 100,  cat = 1,  label = 'Physical Damage Taken' },
    [2158] = { augId = 1156, base = 1,   mult = 200, disp = 100,  cat = 1,  label = 'Magic Damage Taken' },
    [2168] = { augId = 1792, base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet STR' },
    [2169] = { augId = 1806, base = 1,   mult = 1,  disp = 1,    cat = 1,  label = 'Pet STR DEX VIT' },

    -- Dexterity / Accuracy / Crit
    [2148] = { augId = 41,   base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Crit.hit rate' },
    [3504] = { augId = 42,   base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Enemy crit. hit rate' },
    [840]  = { augId = 44,   base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Store TP Subtle Blow' },
    [842]  = { augId = 57,   base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Magic crit. hit rate' },
    [846]  = { augId = 62,   base = 1,   mult = 2,  disp = 1,    cat = 2,  label = 'Accuracy' },
    [847]  = { augId = 63,   base = 1,   mult = 2,  disp = 1,    cat = 2,  label = 'Rng.Accuracy' },
    [922]  = { augId = 96,   base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Accuracy Rng.Acc' },
    [935]  = { augId = 102,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Crit.hit rate' },
    [939]  = { augId = 103,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Enemy crit. hit rate' },
    [1124] = { augId = 106,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Accuracy Rng.Acc' },
    [1288] = { augId = 113,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Rng.Acc' },
    [1289] = { augId = 115,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Store TP' },
    [1290] = { augId = 116,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Pet Subtle Blow' },
    [1292] = { augId = 129,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Accuracy Rng.Acc' },
    [1619] = { augId = 139,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Rapid Shot' },
    [1621] = { augId = 142,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Store TP' },
    [1690] = { augId = 195,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Subtle Blow' },
    [2149] = { augId = 328,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Crit. hit damage' },
    [2150] = { augId = 513,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'DEX' },
    [2506] = { augId = 936,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Fire Affinity Magic Accuracy' },
    [2509] = { augId = 937,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Ice Affinity Magic Accuracy' },
    [2522] = { augId = 938,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Wind Affinity Magic Accuracy' },
    [2749] = { augId = 939,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Earth Affinity Magic Accuracy' },
    [2890] = { augId = 940,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Lightning Affinity Magic Accuracy' },
    [2938] = { augId = 941,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Water Affinity Magic Accuracy' },
    [3502] = { augId = 942,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Light Affinity Magic Accuracy' },
    [3930] = { augId = 943,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Dark Affinity Magic Accuracy' },
    [3941] = { augId = 960,  base = 1,   mult = 1,  disp = 1,    cat = 2,  label = 'Fire Affinity Magic Accuracy Recast time' },

    -- Vitality / Defense / Stoneskin
    [881]  = { augId = 33,   base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'DEF' },
    [936]  = { augId = 55,   base = 1,   mult = 100, disp = 100,  cat = 3,  label = 'Magic dmg. taken' },
    [1193] = { augId = 56,   base = 1,   mult = 100, disp = 100,  cat = 3,  label = 'Breath dmg. taken' },
    [2854] = { augId = 99,   base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Pet DEF' },
    [768]  = { augId = 119,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Pet Mag.Def.Bns' },
    [769]  = { augId = 134,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Mag.Def.Bns' },
    [770]  = { augId = 153,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Shield Mastery' },
    [771]  = { augId = 363,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Chance of successful block' },
    [772]  = { augId = 368,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Phalanx Received' },
    [773]  = { augId = 514,  base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'VIT' },
    [774]  = { augId = 1152, base = 1,   mult = 10, disp = 1,    cat = 3,  label = 'DEF' },
    [775]  = { augId = 1247, base = 1,   mult = 200, disp = 100,  cat = 3,  label = 'Pet Magic Dmg. Taken' },
    [776]  = { augId = 1472, base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Parrying rate' },
    [803]  = { augId = 1794, base = 1,   mult = 1,  disp = 1,    cat = 3,  label = 'Pet VIT' },

    -- Agility / Evasion / Haste
    [816]  = { augId = 47,   base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [818]  = { augId = 48,   base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [820]  = { augId = 49,   base = 1,   mult = 2,  disp = 10.24, cat = 4,  label = 'Haste' },
    [821]  = { augId = 50,   base = 1,   mult = 2,  disp = 10.24, cat = 4,  label = 'Slow' },
    [825]  = { augId = 98,   base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Pet Evasion' },
    [826]  = { augId = 111,  base = 1,   mult = 2,  disp = 10.24, cat = 4,  label = 'Pet Haste' },
    [827]  = { augId = 117,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Pet Mag. Evasion' },
    [828]  = { augId = 186,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Resist Slow' },
    [829]  = { augId = 211,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Snapshot' },
    [834]  = { augId = 212,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Recycle' },
    [876]  = { augId = 320,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Blood Pact ability delay' },
    [912]  = { augId = 324,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Call Beast ability delay' },
    [1623] = { augId = 325,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Quick Draw ability delay' },
    [1741] = { augId = 330,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Waltz potency' },
    [801]  = { augId = 331,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Waltz ability delay' },
    [810]  = { augId = 336,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Sic and Ready ability delay' },
    [817]  = { augId = 337,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Song recast delay' },
    [832]  = { augId = 340,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Phantom Roll ability delay' },
    [836]  = { augId = 342,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Waltz TP cost' },
    [838]  = { augId = 347,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Healing Magic Recast Delay' },
    [849]  = { augId = 348,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Elemental Magic Recast Delay' },
    [859]  = { augId = 349,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Enfeebling Magic Recast Delay' },
    [868]  = { augId = 355,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Enhancing Magic Recast Delay' },
    [878]  = { augId = 515,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'AGI' },
    [927]  = { augId = 752,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1118] = { augId = 753,  base = 33,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1121] = { augId = 754,  base = 65,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1196] = { augId = 755,  base = 97,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1265] = { augId = 756,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1275] = { augId = 757,  base = 33,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1276] = { augId = 758,  base = 65,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1277] = { augId = 759,  base = 97,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (melee,not ranged)' },
    [1279] = { augId = 760,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1280] = { augId = 761,  base = 33,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1281] = { augId = 762,  base = 65,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1282] = { augId = 763,  base = 97,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1283] = { augId = 764,  base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1296] = { augId = 765,  base = 33,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1312] = { augId = 766,  base = 65,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1470] = { augId = 767,  base = 97,  mult = 1,  disp = 1,    cat = 4,  label = 'Delay (ranged,not melee)' },
    [1617] = { augId = 1153, base = 3,   mult = 1,  disp = 1,    cat = 4,  label = 'Evasion' },
    [1713] = { augId = 1154, base = 3,   mult = 1,  disp = 1,    cat = 4,  label = 'Mag. Evasion' },
    [1861] = { augId = 1795, base = 1,   mult = 1,  disp = 1,    cat = 4,  label = 'Pet AGI' },

    -- Intelligence / Magic offense
    [854]  = { augId = 53,   base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Spell interruption rate down 1%' },
    [886]  = { augId = 64,   base = 1,   mult = 2,  disp = 1,    cat = 5,  label = 'Mag. Acc' },
    [905]  = { augId = 70,   base = 1,   mult = 2,  disp = 1,    cat = 5,  label = 'Mag. Acc. Mag.Atk.Bns' },
    [909]  = { augId = 80,   base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Mag. Acc./Mag. Dmg' },
    [914]  = { augId = 100,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Pet Mag.Acc' },
    [954]  = { augId = 101,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Pet Mag.Atk.Bns' },
    [1518] = { augId = 108,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Pet Mag.Acc. Mag.Atk.Bns' },
    [1521] = { augId = 120,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Avatar Mag.Atk.Bns' },
    [2157] = { augId = 125,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Pet Mag.Acc. Mag.Dmg' },
    [2163] = { augId = 126,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Pet Magic Damage' },
    [2426] = { augId = 133,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Mag.Atk.Bns' },
    [2427] = { augId = 140,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Fast Cast' },
    [2428] = { augId = 237,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Occult Acumen' },
    [2776] = { augId = 334,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Magic burst dmg' },
    [2777] = { augId = 335,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Mag. crit. hit dmg' },
    [2943] = { augId = 343,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Augment' },
    [921]  = { augId = 516,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'INT' },
    [2338] = { augId = 896,  base = 1,   mult = 1,  disp = 1,    cat = 5,  label = 'Enspell Dmg' },

    -- Mind / Healing / Cure
    [791]  = { augId = 52,   base = 1,   mult = 4,  disp = 1,    cat = 6,  label = 'MP recovered while healing' },
    [792]  = { augId = 289,  base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'Healing magic skill' },
    [793]  = { augId = 323,  base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'Cure spellcasting time' },
    [833]  = { augId = 329,  base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'Cure potency' },
    [887]  = { augId = 356,  base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'Potency of Cure received' },
    [888]  = { augId = 517,  base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'MND' },
    [2198] = { augId = 1797, base = 1,   mult = 1,  disp = 1,    cat = 6,  label = 'Pet MND' },

    -- Charisma / Charm / Enmity
    [787]  = { augId = 39,   base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Enmity' },
    [901]  = { augId = 40,   base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Enmity' },
    [902]  = { augId = 43,   base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Charm' },
    [1291] = { augId = 67,   base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'All songs', maxBoost = 1 },
    [1408] = { augId = 104,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Pet Enmity' },
    [1453] = { augId = 105,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Pet Enmity' },
    [1844] = { augId = 147,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Treasure Hunter' },
    [1858] = { augId = 148,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Gilfinder' },
    [2372] = { augId = 188,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Resist Charm' },
    [2827] = { augId = 322,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Song spellcasting time' },
    [2841] = { augId = 518,  base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'CHR' },
    [2850] = { augId = 1798, base = 1,   mult = 1,  disp = 1,    cat = 7,  label = 'Pet CHR' },

    -- HP / Regen
    [860]  = { augId = 4,    base = 1,   mult = 4,  disp = 1,    cat = 8,  label = 'HP' },
    [867]  = { augId = 18,   base = 1,   mult = 2,  disp = 1,    cat = 8,  label = 'HP MP' },
    [1122] = { augId = 51,   base = 1,   mult = 4,  disp = 1,    cat = 8,  label = 'HP recovered while healing' },
    [1133] = { augId = 110,  base = 1,   mult = 4,  disp = 1,    cat = 8,  label = 'Pet Regen' },
    [848]  = { augId = 137,  base = 1,   mult = 4,  disp = 1,    cat = 8,  label = 'Regen' },
    [850]  = { augId = 371,  base = 1,   mult = 1,  disp = 1,    cat = 8,  label = 'Regen Potency' },

    -- MP / Refresh
    [841]  = { augId = 12,   base = 1,   mult = 4,  disp = 1,    cat = 9,  label = 'MP' },
    [919]  = { augId = 138,  base = 1,   mult = 2,  disp = 1,    cat = 9,  label = 'Refresh' },
    [1119] = { augId = 141,  base = 1,   mult = 1,  disp = 1,    cat = 9,  label = 'Conserve MP' },

    -- Pet
    [839]  = { augId = 124,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Pet Acc R.Acc Atk. R.Atk' },
    [852]  = { augId = 233,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Blood Boon' },
    [1156] = { augId = 294,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Summoning magic skill' },
    [1272] = { augId = 321,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Avatar perpetuation cost' },
    [1445] = { augId = 339,  base = 1,   mult = 5,  disp = 1,    cat = 10, label = 'Elemental Siphon' },
    [1830] = { augId = 369,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Avatar Blood Pact Dmg' },
    [1831] = { augId = 956,  base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Thunder Affinity Avatar perp. cost' },
    [1979] = { augId = 1246, base = 1,   mult = 200, disp = 100,  cat = 10, label = 'Pet Phy. Dmg. Taken' },
    [2173] = { augId = 2040, base = 1,   mult = 1,  disp = 1,    cat = 10, label = 'Thunder Affinity' },

    -- Elemental resistance
    [1163] = { augId = 176,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Sleep' },
    [1452] = { augId = 177,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Poison' },
    [1630] = { augId = 178,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Paralyze' },
    [1638] = { augId = 179,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Blind' },
    [1667] = { augId = 180,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Silence' },
    [2337] = { augId = 181,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Virus' },
    [2549] = { augId = 182,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Petrify' },
    [2860] = { augId = 183,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Bind' },
    [784]  = { augId = 184,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Curse' },
    [797]  = { augId = 185,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Gravity' },
    [805]  = { augId = 187,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Resist Stun' },
    [824]  = { augId = 293,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark magic skill' },
    [831]  = { augId = 298,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind instrument skill' },
    [837]  = { augId = 768,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Fire resist' },
    [918]  = { augId = 769,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice resist' },
    [928]  = { augId = 770,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind resist' },
    [937]  = { augId = 771,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth resist' },
    [938]  = { augId = 772,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning resist' },
    [943]  = { augId = 773,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water resist' },
    [948]  = { augId = 774,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light resist' },
    [952]  = { augId = 775,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark resist' },
    [955]  = { augId = 792,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Fire,Wind,Lightning,Light resists' },
    [959]  = { augId = 793,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice,Earth,Water,Dark resists' },
    [1132] = { augId = 796,  base = 10,  mult = 1,  disp = 1,    cat = 11, label = 'All elemental resists' },
    [1158] = { augId = 797,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'All elemental resists' },
    [1165] = { augId = 928,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Fire Affinity' },
    [1186] = { augId = 929,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity' },
    [1187] = { augId = 930,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity' },
    [1200] = { augId = 931,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity' },
    [1201] = { augId = 932,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning Affinity' },
    [1236] = { augId = 933,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affinity' },
    [1237] = { augId = 934,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity' },
    [1263] = { augId = 935,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity' },
    [1268] = { augId = 952,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Fire Affinity Avatar perp. cost' },
    [1270] = { augId = 953,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity Avatar perp. cost' },
    [1295] = { augId = 954,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity Avatar perp. cost' },
    [1311] = { augId = 955,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity Avatar perp. cost' },
    [1313] = { augId = 957,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affinity Avatar perp. cost' },
    [1414] = { augId = 958,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity Avatar perp. cost' },
    [1443] = { augId = 959,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity Avatar perp. cost' },
    [1449] = { augId = 961,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity' },
    [1450] = { augId = 962,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity' },
    [1464] = { augId = 963,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity' },
    [1465] = { augId = 964,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning Affinity' },
    [1474] = { augId = 965,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affinity' },
    [1520] = { augId = 966,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity' },
    [1614] = { augId = 967,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity' },
    [1624] = { augId = 969,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity' },
    [1625] = { augId = 970,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity' },
    [1631] = { augId = 971,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity' },
    [1632] = { augId = 972,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning Affinity' },
    [1639] = { augId = 973,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affinity' },
    [1651] = { augId = 974,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity' },
    [1664] = { augId = 975,  base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity' },
    [1669] = { augId = 1001, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity' },
    [1687] = { augId = 1002, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity' },
    [1688] = { augId = 1003, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity' },
    [1689] = { augId = 1004, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning Affinity' },
    [1712] = { augId = 1005, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affintiy' },
    [1714] = { augId = 1006, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity' },
    [1724] = { augId = 1007, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity' },
    [1738] = { augId = 1009, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Ice Affinity' },
    [1739] = { augId = 1010, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Wind Affinity' },
    [1836] = { augId = 1011, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Earth Affinity' },
    [1843] = { augId = 1012, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Lightning Affinity' },
    [1847] = { augId = 1013, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Water Affinity' },
    [1848] = { augId = 1014, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Light Affinity' },
    [1849] = { augId = 1015, base = 1,   mult = 1,  disp = 1,    cat = 11, label = 'Dark Affinity' },
    [1850] = { augId = 1158, base = 2,   mult = 1,  disp = 1,    cat = 11, label = 'Occ. Resistance to Status Ailments' },
    [1853] = { augId = 1370, base = 1,   mult = 10, disp = 1,    cat = 11, label = 'Enhances' },

    -- Skill+
    [923]  = { augId = 257,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Hand-to-Hand skill' },
    [864]  = { augId = 258,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Dagger skill' },
    [894]  = { augId = 259,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Sword skill' },
    [916]  = { augId = 260,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Great Sword skill' },
    [920]  = { augId = 261,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Axe skill' },
    [925]  = { augId = 262,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Great Axe skill' },
    [940]  = { augId = 263,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Scythe skill' },
    [944]  = { augId = 264,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Polearm skill' },
    [953]  = { augId = 265,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Katana skill' },
    [1264] = { augId = 266,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Great Katana skill' },
    [1446] = { augId = 267,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Club skill' },
    [1592] = { augId = 268,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Staff skill' },
    [1616] = { augId = 278,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Melee skill' },
    [1663] = { augId = 279,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Ranged skill' },
    [1864] = { augId = 280,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Magic skill' },
    [2361] = { augId = 281,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Archery skill' },
    [2513] = { augId = 282,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Marksmanship skill' },
    [2524] = { augId = 283,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Throwing skill' },
    [2936] = { augId = 286,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Shield skill' },
    [2937] = { augId = 287,  base = 1,   mult = 1,  disp = 1,    cat = 12, label = 'Parrying Skill' },

    -- Weaponskill DMG+
    [1110] = { augId = 326,  base = 1,   mult = 1,  disp = 1,    cat = 13, label = 'Weapon Skill Acc' },
    [1473] = { augId = 327,  base = 1,   mult = 1,  disp = 1,    cat = 13, label = 'Weapon skill damage' },
    [865]  = { augId = 332,  base = 1,   mult = 100, disp = 100,  cat = 13, label = 'Sklchn.dmg' },
    [889]  = { augId = 743,  base = 1,   mult = 1,  disp = 1,    cat = 13, label = 'Dmg (melee,not ranged)' },
    [908]  = { augId = 749,  base = 1,   mult = 1,  disp = 1,    cat = 13, label = 'Dmg (ranged,not melee)' },

    -- Progression (Exp / Cap)
    ---   Cap. Point +33% (augId 75) uses Mod::CAPACITY_BONUS (915) in
    ---   sql/augments.sql and works out of the box.
    ---   Exp. Point +33% (augId 73) shipped with modId=0 upstream -- a real
    ---   bug (nothing attaches when the gear is equipped). Fixed in the live
    ---   DB by modules/custom/sql/fix_aug_73_exp_bonus.sql, which repoints it
    ---   at Mod::EXP_BONUS (382). Apply that SQL once and restart map.
    ---   base = 33 mirrors the live augments-table value so the site matches the
    ---   game (cap 64/slot); cat = 12 (Skill+) so the Sage's Skill+ affinity boosts.
    [2523] = { augId = 73,   base = 33,  mult = 1,  disp = 1,    cat = 12, label = 'Exp. Point +33%' },  -- peiste_skin
    [942]  = { augId = 75,   base = 33,  mult = 1,  disp = 1,    cat = 12, label = 'Cap. Point +33%' },  -- philosophers_stone
}
