-----------------------------------
-- augment_catalog.lua
-- Maps catalyst item IDs to augment definitions.
-- One catalyst per augmentId. Trade the catalyst to the Augment Moogle
-- to apply the augment. The exdata value is 0 (uses the SQL base value).
--
-- Filters applied:
--   - Skipped augments with no functional modifier (modId=0)
--     EXCEPTION: Exp. Point +33% (augId 73) is included despite modId=0,
--     because the engine handles XP gain specially and the augment works
--     as expected. See the "Progression (Exp / Cap)" section at the end.
--   - Skipped negative-value augments on good-when-positive stats
--   - Every catalyst is verified obtainable via mob_droplist (mob drops
--     only, no crafted/fished/guild/gardened/synergy items)
--   - Foods, drinks, medicines, and other @USABLE_TYPE consumables are
--     excluded -- catalysts must be material drops from monsters
--   - Crafting kits excluded from the catalyst pool
--   - Augments dropped entirely if no thematic mob-drop catalyst exists
--
-- 2026-05-30 audit pass — 27 WEAKER-DUPLICATE entries removed to enforce
-- "strongest version only" policy: for every stat that appeared at multiple
-- power levels (Attack+1 vs +33, HP+1/+33/+65 vs +97, Delay:-1/-33/-65 vs -97,
-- etc.) the weaker catalysts were commented out so players always get the best
-- available tier from a single trade. Affected stats: Attack, Rng.Atk, Accuracy,
-- Rng.Acc, Mag.Acc, HP, HP+MP, MP, Delay melee flat, Delay ranged flat, Evasion,
-- Mag.Evasion, DMG melee, DMG ranged, Magic dmg taken, Phys. dmg. taken.
--
-- 2026-05-29 audit pass — 15 SELF-HARM entries removed because they
-- would only make the player's character worse:
--   augId 47   Delay:+1% melee         (was catalyst 820  rainbow_thread)
--   augId 50   Slow+1                  (was catalyst 826  linen_cloth)
--   augId 744  Dmg:-1 melee            (was catalyst 924  fiend_blood)
--   augId 745  Dmg:-33 melee           (was catalyst 930  beastman_blood)
--   augId 750  Dmg:-1 ranged           (was catalyst 2014 bird_blood)
--   augId 751  Dmg:-33 ranged          (was catalyst 2015 beast_blood)
--   augId 752  Delay:+1 melee  flat    (was catalyst 1617 flytrap_leaf)
--   augId 753  Delay:+33 melee flat    (was catalyst 1714 cashmere_cloth)
--   augId 754  Delay:+65 melee flat    (was catalyst 1118 antican_pauldron)
--   augId 755  Delay:+97 melee flat    (was catalyst 1121 antican_robe)
--   augId 760  Delay:+1 ranged flat    (was catalyst 1275 amemet_skin)
--   augId 761  Delay:+33 ranged flat   (was catalyst 1276 tarasque_skin) **
--   augId 762  Delay:+65 ranged flat   (was catalyst 1277 lindwurm_skin)
--   augId 763  Delay:+97 ranged flat   (was catalyst 1279 taffeta_cloth)
--   augId 797  All elemental resists -1 (was catalyst 1295 twincoon)
-- ** tarasque_skin is also the Tier-1 reward from the AF Hunters' Guild
--    Tarasque hunt — it would have been orphaned by the deletion. Same
--    audit pass remapped it to augId 765 (Delay:-33 ranged flat, the
--    positive inverse of the deleted entry). See the [1276] entry in
--    the Agility/Evasion/Haste block below for the remap details.
-- These augments were vanilla LSB inheritance (used by Magian Trial
-- cursed/penalty items). They have no place in a player-driven
-- augment-Moogle catalyst trade. Three "uncertain effect" entries
-- were KEPT for now (augIds 43 Charm+1, 194 Kick Attacks+1, 360
-- Save TP+10) — flagged for follow-up research, not deletion.
--
-- Each entry: { augId = N, base = N, cat = N, label = '...' }
--   augId : index into sql/augments.sql (used for the actual augment)
--   base  : single-trade stat value (stacks multiply: base * count)
--   cat   : 1..13 thematic category, see CAT_NAMES in the generator.
--           Used by Augment_Sage to apply per-NM affinity bonuses.
--   label : human-readable augment description (shown in trade msg)
--
-- Generated from sql/augments.sql + sql/mob_droplist.sql.
-----------------------------------
return {
    -- Strength / Attack / Phys.dmg.taken
    -- [858] augId 25 (Attack+1) — REMOVED 2026-05-30: weaker duplicate, keep [884] Attack+33.
    -- [861] augId 29 (Rng.Atk.+1) — REMOVED 2026-05-30: weaker duplicate, keep [1116] Rng.Attack+33.
    -- [883] augId 54 (Phys. dmg. taken -1%) — REMOVED 2026-05-30: weaker duplicate, keep [2167] Physical Damage Taken -2%.
    [884]  = { augId = 65,   base = 33,  cat = 1,  label = 'Attack +33' },
    [1116] = { augId = 66,   base = 33,  cat = 1,  label = 'Rng.Attack +33' },
    [1123] = { augId = 68,   base = 1,   cat = 1,  label = 'Accuracy +1 Attack +1' },
    [1615] = { augId = 69,   base = 1,   cat = 1,  label = 'Rng.Acc. +1 Rng.Atk. +1' },
    [1622] = { augId = 71,   base = 1,   cat = 1,  label = 'Damage Taken -1%' },
    [1718] = { augId = 97,   base = 1,   cat = 1,  label = 'Pet: Attack+1 Rng.Atk.+1' },
    [640]  = { augId = 107,  base = 1,   cat = 1,  label = 'Pet: Attack+1 Rng.Atk.+1' },
    [647]  = { augId = 109,  base = 1,   cat = 1,  label = 'Pet: Dbl.Atk.+1% Crit.hit rate+1' },
    [1788] = { augId = 112,  base = 1,   cat = 1,  label = 'Pet: Damage taken -1%' },
    [1983] = { augId = 114,  base = 1,   cat = 1,  label = 'Pet: Rng.Atk.+1' },
    [1984] = { augId = 118,  base = 1,   cat = 1,  label = 'Pet: Phys. dmg. taken -1%' },
    [786]  = { augId = 122,  base = 20,  cat = 1,  label = 'Pet: TP Bonus +20' },
    [853]  = { augId = 123,  base = 1,   cat = 1,  label = 'Pet: Dbl.Att.+1%' },
    [855]  = { augId = 127,  base = 1,   cat = 1,  label = 'Pet: Magic Damage Taken -1%' },
    [856]  = { augId = 130,  base = 1,   cat = 1,  label = 'Attack+1 Rng.Atk.+1' },
    [857]  = { augId = 132,  base = 1,   cat = 1,  label = 'Dbl.Atk.+1% Crit.hit rate+1%' },
    [863]  = { augId = 143,  base = 1,   cat = 1,  label = 'Dbl.Atk.+1%' },
    [874]  = { augId = 144,  base = 1,   cat = 1,  label = 'Triple Atk.+1%' },
    [880]  = { augId = 145,  base = 1,   cat = 1,  label = 'Counter+1' },
    [882]  = { augId = 146,  base = 1,   cat = 1,  label = 'Dual Wield+1' },
    [891]  = { augId = 151,  base = 1,   cat = 1,  label = 'Martial Arts+1' },
    [895]  = { augId = 194,  base = 1,   cat = 1,  label = 'Kick Attacks+1 Rate or Damage? Assuming Rate for now.' },
    [897]  = { augId = 198,  base = 1,   cat = 1,  label = 'Zanshin+1' },
    [903]  = { augId = 251,  base = 1,   cat = 1,  label = 'Daken +1' },
    [701]  = { augId = 333,  base = 1,   cat = 1,  label = 'Conserve TP+1' },
    [703]  = { augId = 338,  base = 1,   cat = 1,  label = 'Barrage+1 (additional shots,NOT acc)' },
    [725]  = { augId = 353,  base = 50,  cat = 1,  label = 'TP Bonus +50' },
    [947]  = { augId = 354,  base = 1,   cat = 1,  label = 'Quadruple Attack+1%' },
    [1108] = { augId = 360,  base = 10,  cat = 1,  label = 'Save TP+10: Mod undefined as of yet so leaving blank.' },
    [1739] = { augId = 370,  base = 1,   cat = 1,  label = 'Reverse Flourish+1' },
    [1163] = { augId = 380,  base = 1,   cat = 1,  label = 'Physical Damage Limit +1%' },
    [1872] = { augId = 512,  base = 1,   cat = 1,  label = 'STR+1' },
    [1271] = { augId = 550,  base = 1,   cat = 1,  label = 'STR+1 DEX+1' },
    [1272] = { augId = 551,  base = 1,   cat = 1,  label = 'STR+1 VIT+1' },
    [1293] = { augId = 552,  base = 1,   cat = 1,  label = 'STR+1 AGI+1' },
    [2159] = { augId = 557,  base = 1,   cat = 1,  label = 'STR+1 CHR+1' },
    [2160] = { augId = 558,  base = 1,   cat = 1,  label = 'STR+1 INT+1' },
    [1516] = { augId = 559,  base = 1,   cat = 1,  label = 'STR+1 MND+1' },
    [2165] = { augId = 640,  base = 1,   cat = 1,  label = 'Counter +2 (increases by 2)' },
    [2167] = { augId = 1155, base = 1,   cat = 1,  label = 'Physical Damage Taken -2%' },
    [2168] = { augId = 1156, base = 1,   cat = 1,  label = 'Magic Damage Taken -2%' },
    [2171] = { augId = 1792, base = 1,   cat = 1,  label = 'Pet: STR+1' },
    [2172] = { augId = 1806, base = 1,   cat = 1,  label = 'Pet: STR+1 DEX+1 VIT+1' },

    -- Dexterity / Accuracy / Crit
    -- [2148] augId 23 (Accuracy+1) — REMOVED 2026-05-30: weaker duplicate, keep [922] Accuracy+33.
    -- [3504] augId 27 (Rng.Acc.+1) — REMOVED 2026-05-30: weaker duplicate, keep [935] Rng.Accuracy+33.
    [840]  = { augId = 41,   base = 1,   cat = 2,  label = 'Crit.hit rate+1%' },
    [842]  = { augId = 42,   base = 1,   cat = 2,  label = 'Enemy crit. hit rate-1%' },
    [846]  = { augId = 44,   base = 1,   cat = 2,  label = 'Store TP+1 Subtle Blow+1' },
    [847]  = { augId = 57,   base = 1,   cat = 2,  label = 'Magic crit. hit rate+1%' },
    [922]  = { augId = 62,   base = 33,  cat = 2,  label = 'Accuracy +33' },
    [935]  = { augId = 63,   base = 33,  cat = 2,  label = 'Rng.Accuracy +33' },
    [939]  = { augId = 96,   base = 1,   cat = 2,  label = 'Pet: Accuracy+1 Rng.Acc+1' },
    [1724] = { augId = 102,  base = 1,   cat = 2,  label = 'Pet: Crit.hit rate+1%' },
    [1124] = { augId = 103,  base = 1,   cat = 2,  label = 'Pet: Enemy crit. hit rate -1%' },
    [1288] = { augId = 106,  base = 1,   cat = 2,  label = 'Pet: Accuracy+1 Rng.Acc.+1' },
    [1289] = { augId = 113,  base = 1,   cat = 2,  label = 'Pet: Rng.Acc.+1' },
    [1290] = { augId = 115,  base = 1,   cat = 2,  label = 'Pet: Store TP+1' },
    [1292] = { augId = 116,  base = 1,   cat = 2,  label = 'Pet: Subtle Blow+1' },
    [1619] = { augId = 129,  base = 1,   cat = 2,  label = 'Accuracy+1 Rng.Acc.+1' },
    [1621] = { augId = 139,  base = 1,   cat = 2,  label = 'Rapid Shot+1' },
    [1690] = { augId = 142,  base = 1,   cat = 2,  label = 'Store TP+1' },
    [2149] = { augId = 195,  base = 1,   cat = 2,  label = 'Subtle Blow+1' },
    [2150] = { augId = 328,  base = 1,   cat = 2,  label = 'Crit. hit damage+1%' },
    [534]  = { augId = 513,  base = 1,   cat = 2,  label = 'DEX+1' },
    [2499] = { augId = 553,  base = 1,   cat = 2,  label = 'DEX+1 AGI+1' },
    [2506] = { augId = 936,  base = 1,   cat = 2,  label = 'Fire Affinity Magic Accuracy+1' },
    [2509] = { augId = 937,  base = 1,   cat = 2,  label = 'Ice Affinity Magic Accuracy+1' },
    [2522] = { augId = 938,  base = 1,   cat = 2,  label = 'Wind Affinity Magic Accuracy+1' },
    [557]  = { augId = 939,  base = 1,   cat = 2,  label = 'Earth Affinity Magic Accuracy+1' },
    [572]  = { augId = 940,  base = 1,   cat = 2,  label = 'Lightning Affinity Magic Accuracy+1' },
    [2749] = { augId = 941,  base = 1,   cat = 2,  label = 'Water Affinity Magic Accuracy+1' },
    [2890] = { augId = 942,  base = 1,   cat = 2,  label = 'Light Affinity Magic Accuracy+1' },
    [641]  = { augId = 943,  base = 1,   cat = 2,  label = 'Dark Affinity Magic Accuracy+1' },
    [643]  = { augId = 960,  base = 1,   cat = 2,  label = 'Fire Affinity: Magic Accuracy+0 Recast time -2% (Increases by 2)' },
    [645]  = { augId = 1000, base = 1,   cat = 2,  label = 'Fire Affinity: Magic Accuracy+0,Fire Affinity: Casting time -6% (increases by 6)' },
    [646]  = { augId = 1793, base = 1,   cat = 2,  label = 'Pet: DEX+1' },

    -- Vitality / Defense / Stoneskin
    [881]  = { augId = 33,   base = 1,   cat = 3,  label = 'DEF+1' },
    -- [936] augId 55 (Magic dmg. taken -1%) — REMOVED 2026-05-30: weaker duplicate, keep [2168] Magic Damage Taken -2%.
    [1193] = { augId = 56,   base = 1,   cat = 3,  label = 'Breath dmg. taken -1%' },
    [575]  = { augId = 99,   base = 1,   cat = 3,  label = 'Pet: DEF+1' },
    [2854] = { augId = 119,  base = 1,   cat = 3,  label = 'Pet: Mag.Def.Bns.+1' },
    [1654] = { augId = 134,  base = 1,   cat = 3,  label = 'Mag.Def.Bns.+1' },
    [768]  = { augId = 153,  base = 1,   cat = 3,  label = 'Shield Mastery+1 (tested in retail,this is correct)' },
    [769]  = { augId = 363,  base = 1,   cat = 3,  label = 'Chance of successful block+1' },
    [770]  = { augId = 368,  base = 1,   cat = 3,  label = 'Phalanx Received+1' },
    [771]  = { augId = 514,  base = 1,   cat = 3,  label = 'VIT+1' },
    [772]  = { augId = 1152, base = 1,   cat = 3,  label = 'DEF +10 (increases by 10)' },
    [773]  = { augId = 1247, base = 1,   cat = 3,  label = 'Pet: Magic Dmg. Taken -2%' },
    [774]  = { augId = 1472, base = 1,   cat = 3,  label = 'Parrying rate +1% (not +skill)' },
    [775]  = { augId = 1794, base = 1,   cat = 3,  label = 'Pet: VIT+1' },

    -- Agility / Evasion / Haste
    -- [816] augId 31 (Evasion+1) — REMOVED 2026-05-30: weaker duplicate, keep [1296] Evasion+3.
    -- [818] augId 37 (Mag.Evasion+1) — REMOVED 2026-05-30: weaker duplicate, keep [1312] Mag.Evasion+3.
    -- [820] augId 47 (Delay:+1% melee) — REMOVED 2026-05-29 audit: self-harm.
    [821]  = { augId = 48,   base = 1,   cat = 4,  label = 'Delay:-1% (melee,not ranged)' },
    [825]  = { augId = 49,   base = 1,   cat = 4,  label = 'Haste+1' },
    -- [826] augId 50 (Slow+1) — REMOVED 2026-05-29 audit: self-harm.
    [827]  = { augId = 98,   base = 1,   cat = 4,  label = 'Pet: Evasion+1' },
    [828]  = { augId = 111,  base = 1,   cat = 4,  label = 'Pet: Haste+1' },
    [829]  = { augId = 117,  base = 1,   cat = 4,  label = 'Pet: Mag. Evasion+1' },
    [834]  = { augId = 186,  base = 1,   cat = 4,  label = 'Resist Slow+1' },
    [876]  = { augId = 211,  base = 1,   cat = 4,  label = 'Snapshot+1' },
    [912]  = { augId = 212,  base = 1,   cat = 4,  label = 'Recycle+1' },
    [1623] = { augId = 320,  base = 1,   cat = 4,  label = 'Blood Pact ability delay -1' },
    [1741] = { augId = 324,  base = 1,   cat = 4,  label = 'Call Beast ability delay -1' },
    [650]  = { augId = 325,  base = 1,   cat = 4,  label = 'Quick Draw ability delay -1' },
    [801]  = { augId = 330,  base = 1,   cat = 4,  label = 'Waltz potency+1%' },
    [810]  = { augId = 331,  base = 1,   cat = 4,  label = 'Waltz ability delay -1' },
    [817]  = { augId = 336,  base = 1,   cat = 4,  label = 'Sic and Ready ability delay -1' },
    [824]  = { augId = 337,  base = 1,   cat = 4,  label = 'Song recast delay -1' },
    [831]  = { augId = 340,  base = 1,   cat = 4,  label = 'Phantom Roll ability delay -1' },
    [832]  = { augId = 342,  base = 1,   cat = 4,  label = 'Waltz TP cost -1' },
    [836]  = { augId = 347,  base = 1,   cat = 4,  label = 'Healing Magic Recast Delay -1%' },
    [838]  = { augId = 348,  base = 1,   cat = 4,  label = 'Elemental Magic Recast Delay -1%' },
    [868]  = { augId = 349,  base = 1,   cat = 4,  label = 'Enfeebling Magic Recast Delay -1%' },
    [878]  = { augId = 355,  base = 1,   cat = 4,  label = 'Enhancing Magic Recast Delay -1%' },
    [927]  = { augId = 515,  base = 1,   cat = 4,  label = 'AGI+1' },
    -- [1617] augId 752 (Delay:+1 melee flat) — REMOVED 2026-05-29 audit.
    -- [1714] augId 753 (Delay:+33 melee flat) — REMOVED 2026-05-29 audit.
    -- [1118] augId 754 (Delay:+65 melee flat) — REMOVED 2026-05-29 audit.
    -- [1121] augId 755 (Delay:+97 melee flat) — REMOVED 2026-05-29 audit.
    -- [1785] augId 756 (Delay:-1 melee) — REMOVED 2026-05-30: weaker duplicate, keep [2123] Delay:-97 melee.
    -- [1196] augId 757 (Delay:-33 melee) — REMOVED 2026-05-30: weaker duplicate, keep [2123] Delay:-97 melee.
    -- [1265] augId 758 (Delay:-65 melee) — REMOVED 2026-05-30: weaker duplicate, keep [2123] Delay:-97 melee.
    [2123] = { augId = 759,  base = 97,  cat = 4,  label = 'Delay:-97    (melee,not ranged)' },
    -- [1275] augId 760 (Delay:+1 ranged flat) — REMOVED 2026-05-29 audit.
    -- [1276] tarasque_skin REMAP 2026-05-29: was augId 761 (Delay:+33 ranged
    --        flat, deleted as self-harm). tarasque_skin is the AF Hunters'
    --        Guild Tier-1 reward — a wyrm-slayer trophy deserves better than
    --        an empty slot. Remapped to augId 765 (Delay:-33 ranged flat),
    --        the direct positive inverse of the deleted entry. Theme: "you
    --        slew the wyrm, take its predator speed." Shares augId 765 with
    --        the existing catalyst 1281, which is fine — the catalog supports
    --        multiple catalysts pointing at the same augId.
    [1276] = { augId = 765,  base = 33,  cat = 4,  label = 'Delay:-33 ranged (Tarasque hunt trophy)' },
    -- [1277] augId 762 (Delay:+65 ranged flat) — REMOVED 2026-05-29 audit.
    -- [1279] augId 763 (Delay:+97 ranged flat) — REMOVED 2026-05-29 audit.
    -- [1280] augId 764 (Delay:-1 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [1283] Delay:-97 ranged.
    -- [1281] augId 765 (Delay:-33 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [1283] Delay:-97 ranged.
    -- [1282] augId 766 (Delay:-65 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [1283] Delay:-97 ranged.
    [1283] = { augId = 767,  base = 97,  cat = 4,  label = 'Delay:-97    (ranged,not melee)' },
    [1296] = { augId = 1153, base = 3,   cat = 4,  label = 'Evasion +3' },
    [1312] = { augId = 1154, base = 3,   cat = 4,  label = 'Mag. Evasion +3' },
    [1470] = { augId = 1795, base = 1,   cat = 4,  label = 'Pet: AGI+1' },

    -- Intelligence / Magic offense
    -- [854] augId 35 (Mag.Acc.+1) — REMOVED 2026-05-30: weaker duplicate, keep [905] Mag.Acc.+33.
    [886]  = { augId = 53,   base = 1,   cat = 5,  label = 'Spell interruption rate down 1%' },
    [905]  = { augId = 64,   base = 33,  cat = 5,  label = 'Mag. Acc. +33' },
    [909]  = { augId = 70,   base = 33,  cat = 5,  label = 'Mag. Acc. +33 Mag.Atk.Bns +33' },
    [914]  = { augId = 80,   base = 1,   cat = 5,  label = 'Mag. Acc. +1/Mag. Dmg. +1' },
    [954]  = { augId = 100,  base = 1,   cat = 5,  label = 'Pet: Mag.Acc.+1' },
    [1740] = { augId = 101,  base = 1,   cat = 5,  label = 'Pet: Mag.Atk.Bns.+1' },
    [1518] = { augId = 108,  base = 1,   cat = 5,  label = 'Pet: Mag.Acc.+1 Mag.Atk.Bns.+1' },
    [1521] = { augId = 120,  base = 1,   cat = 5,  label = 'Avatar: Mag.Atk.Bns.+1' },
    [2220] = { augId = 125,  base = 1,   cat = 5,  label = 'Pet: Mag.Acc.+1 Mag.Dmg.+1' },
    [2326] = { augId = 126,  base = 1,   cat = 5,  label = 'Pet: Magic Damage +1' },
    [2157] = { augId = 131,  base = 1,   cat = 5,  label = 'Mag. Acc.+1 Mag.Atk.Bns+1' },
    [2163] = { augId = 133,  base = 1,   cat = 5,  label = 'Mag.Atk.Bns.+1' },
    [2426] = { augId = 140,  base = 1,   cat = 5,  label = 'Fast Cast+1%' },
    [2427] = { augId = 237,  base = 1,   cat = 5,  label = 'Occult Acumen+1' },
    [2428] = { augId = 334,  base = 1,   cat = 5,  label = 'Magic burst dmg.+1%' },
    [582]  = { augId = 335,  base = 1,   cat = 5,  label = 'Mag. crit. hit dmg.+1%' },
    [596]  = { augId = 343,  base = 1,   cat = 5,  label = '"Drain" and "Aspir" Potency +1' },
    [624]  = { augId = 362,  base = 1,   cat = 5,  label = 'Magic Damage+1' },
    [642]  = { augId = 516,  base = 1,   cat = 5,  label = 'INT+1' },
    [655]  = { augId = 554,  base = 1,   cat = 5,  label = 'INT+1 MND+1' },
    [658]  = { augId = 556,  base = 1,   cat = 5,  label = 'INT+1 MND+1 CHR+1' },
    [2943] = { augId = 896,  base = 1,   cat = 5,  label = 'Sword Enhancement Spell Damage +1' },
    [688]  = { augId = 899,  base = 1,   cat = 5,  label = 'Sword Enhancement spell damage +1% (Percent Damage)' },
    [1632] = { augId = 944,  base = 1,   cat = 5,  label = 'Fire Affinity Magic Damage+1' },
    [1651] = { augId = 945,  base = 1,   cat = 5,  label = 'Ice Affinity Magic Damage+1' },
    [1669] = { augId = 946,  base = 1,   cat = 5,  label = 'Wind Affinity Magic Damage+1' },
    [1787] = { augId = 947,  base = 1,   cat = 5,  label = 'Earth Affinity Magic Damage+1' },
    [1836] = { augId = 948,  base = 1,   cat = 5,  label = 'Lightning Affinity Magic Damage+1' },
    [1980] = { augId = 949,  base = 1,   cat = 5,  label = 'Water Affinity Magic Damage+1' },
    [1985] = { augId = 950,  base = 1,   cat = 5,  label = 'Light Affinity Magic Damage+1' },
    [2016] = { augId = 951,  base = 1,   cat = 5,  label = 'Dark Affinity Magic Damage+1' },
    [2146] = { augId = 968,  base = 1,   cat = 5,  label = 'Fire Affinity: Magic Damage+0,Fire Affinity: Casting time -2% (Increases by 2)' },
    [2151] = { augId = 1008, base = 1,   cat = 5,  label = 'Fire Affinity: Magic Damage+0,Fire Affinity: Recast time -6%' },

    -- Mind / Healing / Cure
    [791]  = { augId = 52,   base = 1,   cat = 6,  label = 'MP recovered while healing+1' },
    [792]  = { augId = 289,  base = 1,   cat = 6,  label = 'Healing magic skill+1' },
    [793]  = { augId = 323,  base = 1,   cat = 6,  label = 'Cure spellcasting time -1%' },
    [833]  = { augId = 329,  base = 1,   cat = 6,  label = 'Cure potency+1%' },
    [887]  = { augId = 356,  base = 1,   cat = 6,  label = 'Potency of Cure received+1%' },
    [888]  = { augId = 517,  base = 1,   cat = 6,  label = 'MND+1' },
    [1713] = { augId = 555,  base = 1,   cat = 6,  label = 'MND+1 CHR+1' },
    [1858] = { augId = 1797, base = 1,   cat = 6,  label = 'Pet: MND+1' },

    -- Charisma / Charm / Enmity
    [787]  = { augId = 39,   base = 1,   cat = 7,  label = 'Enmity+1' },
    [901]  = { augId = 40,   base = 1,   cat = 7,  label = 'Enmity-1' },
    [1291] = { augId = 43,   base = 1,   cat = 7,  label = 'Charm+1 Could not determine retail AUGMENT effect. Duration? Chance to land charm? Just set as chance for now.' },
    [2154] = { augId = 67,   base = 1,   cat = 7,  label = 'All songs +1' },
    [1453] = { augId = 104,  base = 1,   cat = 7,  label = 'Pet: Enmity+1' },
    [2166] = { augId = 105,  base = 1,   cat = 7,  label = 'Pet: Enmity-1' },
    [1666] = { augId = 147,  base = 1,   cat = 7,  label = 'Treasure Hunter+1' },
    [2188] = { augId = 148,  base = 1,   cat = 7,  label = 'Gilfinder+1' },
    [2198] = { augId = 188,  base = 1,   cat = 7,  label = 'Resist Charm+1' },
    [1783] = { augId = 322,  base = 1,   cat = 7,  label = 'Song spellcasting time -1%' },
    [1819] = { augId = 518,  base = 1,   cat = 7,  label = 'CHR+1' },
    [1844] = { augId = 1798, base = 1,   cat = 7,  label = 'Pet: CHR+1' },

    -- HP / Regen
    -- [860] augId 1 (HP+1) — REMOVED 2026-05-30: weaker duplicate, keep [1133] HP+97.
    -- [867] augId 2 (HP+33) — REMOVED 2026-05-30: weaker duplicate, keep [1133] HP+97.
    -- [1122] augId 3 (HP+65) — REMOVED 2026-05-30: weaker duplicate, keep [1133] HP+97.
    [1133] = { augId = 4,    base = 97,  cat = 8,  label = 'HP+97' },
    -- [2164] augId 17 (HP+1 MP+1) — REMOVED 2026-05-30: weaker duplicate, keep [2169] HP+33 MP+33.
    [2169] = { augId = 18,   base = 33,  cat = 8,  label = 'HP+33 MP+33' },
    [848]  = { augId = 51,   base = 1,   cat = 8,  label = 'HP recovered while healing+1' },
    -- [849] augId 78 (HP+2 per count) — REMOVED 2026-05-30: weaker duplicate, keep [1133] HP+97.
    -- [850] augId 79 (HP+3 per count) — REMOVED 2026-05-30: weaker duplicate, keep [1133] HP+97.
    [852]  = { augId = 110,  base = 1,   cat = 8,  label = 'Pet: Regen+1' },
    [859]  = { augId = 137,  base = 1,   cat = 8,  label = 'Regen+1' },
    [866]  = { augId = 371,  base = 1,   cat = 8,  label = 'Regen Potency+1' },

    -- MP / Refresh
    -- [841] augId 9 (MP+1) — REMOVED 2026-05-30: weaker duplicate, keep [919] MP+97.
    -- [902] augId 10 (MP+33) — REMOVED 2026-05-30: weaker duplicate, keep [919] MP+97.
    -- [699] augId 11 (MP+65) — REMOVED 2026-05-30: weaker duplicate, keep [919] MP+97.
    [919]  = { augId = 12,   base = 97,  cat = 9,  label = 'MP+97' },
    -- [921] augId 82 (MP+2 per count) — REMOVED 2026-05-30: weaker duplicate, keep [919] MP+97.
    -- [1614] augId 83 (MP+3 per count) — REMOVED 2026-05-30: weaker duplicate, keep [919] MP+97.
    [1695] = { augId = 138,  base = 1,   cat = 9,  label = 'Refresh+1' },
    [1119] = { augId = 141,  base = 1,   cat = 9,  label = 'Conserve MP+1' },

    -- Pet
    [839]  = { augId = 124,  base = 1,   cat = 10, label = 'Pet: Acc+1 R.Acc+1 Atk.+1 R.Atk.+1' },
    [926]  = { augId = 233,  base = 1,   cat = 10, label = 'Blood Boon+1' },
    [1520] = { augId = 294,  base = 1,   cat = 10, label = 'Summoning magic skill+1' },
    [1015] = { augId = 321,  base = 1,   cat = 10, label = 'Avatar perpetuation cost -1' },
    [1640] = { augId = 339,  base = 1,   cat = 10, label = 'Elemental Siphon+5 (value*5) Use Multiplier field.' },
    [1664] = { augId = 369,  base = 1,   cat = 10, label = 'Avatar: Blood Pact Dmg+1' },
    [1156] = { augId = 956,  base = 1,   cat = 10, label = 'Thunder Affinity: Avatar perp. cost -1' },
    [1445] = { augId = 1246, base = 1,   cat = 10, label = 'Pet: Phy. Dmg. Taken -2%' },

    -- Elemental resistance
    [736]  = { augId = 61,   base = 1,   cat = 11, label = 'Occ. inc. resist to stat ailments+1' },
    [737]  = { augId = 176,  base = 1,   cat = 11, label = 'Resist Sleep+1' },
    [738]  = { augId = 177,  base = 1,   cat = 11, label = 'Resist Poison+1' },
    [739]  = { augId = 178,  base = 1,   cat = 11, label = 'Resist Paralyze+1' },
    [744]  = { augId = 179,  base = 1,   cat = 11, label = 'Resist Blind+1' },
    [745]  = { augId = 180,  base = 1,   cat = 11, label = 'Resist Silence+1' },
    [746]  = { augId = 181,  base = 1,   cat = 11, label = 'Resist Virus+1' },
    [747]  = { augId = 182,  base = 1,   cat = 11, label = 'Resist Petrify+1' },
    [748]  = { augId = 183,  base = 1,   cat = 11, label = 'Resist Bind+1' },
    [749]  = { augId = 184,  base = 1,   cat = 11, label = 'Resist Curse+1' },
    [948]  = { augId = 185,  base = 1,   cat = 11, label = 'Resist Gravity+1' },
    [952]  = { augId = 187,  base = 1,   cat = 11, label = 'Resist Stun+1' },
    [955]  = { augId = 293,  base = 1,   cat = 11, label = 'Dark magic skill+1' },
    [959]  = { augId = 298,  base = 1,   cat = 11, label = 'Wind instrument skill+1' },
    [1018]  = { augId = 768,  base = 1,   cat = 11, label = 'Fire resist+1' },
    [1132]  = { augId = 769,  base = 1,   cat = 11, label = 'Ice resist+1' },
    [1162]  = { augId = 770,  base = 1,   cat = 11, label = 'Wind resist+1' },
    [1165]  = { augId = 771,  base = 1,   cat = 11, label = 'Earth resist+1' },
    [1236]  = { augId = 772,  base = 1,   cat = 11, label = 'Lightning resist+1' },
    [1237]  = { augId = 773,  base = 1,   cat = 11, label = 'Water resist+1' },
    [1269]  = { augId = 774,  base = 1,   cat = 11, label = 'Light resist+1' },
    [1270] = { augId = 775,  base = 1,   cat = 11, label = 'Dark resist+1' },
    [1273] = { augId = 792,  base = 1,   cat = 11, label = 'Fire,Wind,Lightning,Light resists+1' },
    [1274] = { augId = 793,  base = 1,   cat = 11, label = 'Ice,Earth,Water,Dark resists+1' },
    [1294] = { augId = 796,  base = 1,   cat = 11, label = 'All elemental resists+1' },
    -- [1295] augId 797 (All elemental resists -1) — REMOVED 2026-05-29 audit.
    [1313] = { augId = 928,  base = 1,   cat = 11, label = 'Fire Affinity+1' },
    [1414] = { augId = 929,  base = 1,   cat = 11, label = 'Ice Affinity+1' },
    [1443] = { augId = 930,  base = 1,   cat = 11, label = 'Wind Affinity+1' },
    [1464] = { augId = 931,  base = 1,   cat = 11, label = 'Earth Affinity+1' },
    [750]  = { augId = 932,  base = 1,   cat = 11, label = 'Lightning Affinity+1' },
    [751]  = { augId = 933,  base = 1,   cat = 11, label = 'Water Affinity+1' },
    [776]  = { augId = 934,  base = 1,   cat = 11, label = 'Light Affinity+1' },
    [784]  = { augId = 935,  base = 1,   cat = 11, label = 'Dark Affinity+1' },
    [797]  = { augId = 952,  base = 1,   cat = 11, label = 'Fire Affinity: Avatar perp. cost -1' },
    [803]  = { augId = 953,  base = 1,   cat = 11, label = 'Ice Affinity: Avatar perp. cost -1' },
    [805]  = { augId = 954,  base = 1,   cat = 11, label = 'Wind Affinity: Avatar perp. cost -1' },
    [837]  = { augId = 955,  base = 1,   cat = 11, label = 'Earth Affinity: Avatar perp. cost -1' },
    [918]  = { augId = 957,  base = 1,   cat = 11, label = 'Water Affinity: Avatar perp. cost -1' },
    [928]  = { augId = 958,  base = 1,   cat = 11, label = 'Light Affinity: Avatar perp. cost -1' },
    [937]  = { augId = 959,  base = 1,   cat = 11, label = 'Dark Affinity: Avatar perp. cost -1' },
    [938]  = { augId = 961,  base = 1,   cat = 11, label = 'Ice Affinity: (otherwise same as augID 960)' },
    [1263]  = { augId = 962,  base = 1,   cat = 11, label = 'Wind Affinity: (otherwise same as augID 960)' },
    [1268]  = { augId = 963,  base = 1,   cat = 11, label = 'Earth Affinity: (otherwise same as augID 960)' },
    [1465] = { augId = 964,  base = 1,   cat = 11, label = 'Lightning Affinity: (otherwise same as augID 960)' },
    [1519] = { augId = 965,  base = 1,   cat = 11, label = 'Water Affinity: (otherwise same as augID 960)' },
    [1667] = { augId = 966,  base = 1,   cat = 11, label = 'Light Affinity: (otherwise same as augID 960)' },
    [2327] = { augId = 967,  base = 1,   cat = 11, label = 'Dark Affinity: (otherwise same as augID 960)' },
    [2328] = { augId = 969,  base = 1,   cat = 11, label = 'Ice Affinity: (otherwise same as augID 968)' },
    [942]  = { augId = 970,  base = 1,   cat = 11, label = 'Wind Affinity: (otherwise same as augID 968)' },
    [943]  = { augId = 971,  base = 1,   cat = 11, label = 'Earth Affinity: (otherwise same as augID 968)' },
    [1712] = { augId = 972,  base = 1,   cat = 11, label = 'Lightning Affinity: (otherwise same as augID 968)' },
    [1158] = { augId = 973,  base = 1,   cat = 11, label = 'Water Affinity: (otherwise same as augID 968)' },
    [1818] = { augId = 974,  base = 1,   cat = 11, label = 'Light Affinity: (otherwise same as augID 968)' },
    [1449] = { augId = 975,  base = 1,   cat = 11, label = 'Dark Affinity: (otherwise same as augID 968)' },
    [1450] = { augId = 1001, base = 1,   cat = 11, label = 'Ice Affinity: (otherwise same as augID 1000)' },
    [1452] = { augId = 1002, base = 1,   cat = 11, label = 'Wind Affinity: (otherwise same as augID 1000)' },
    [1474] = { augId = 1003, base = 1,   cat = 11, label = 'Earth Affinity: (otherwise same as augID 1000)' },
    [1630] = { augId = 1004, base = 1,   cat = 11, label = 'Lightning Affinity: (otherwise same as augID 1000)' },
    [1875] = { augId = 1005, base = 1,   cat = 11, label = 'Water Affintiy: (otherwise same as augID 1000)' },
    [2275] = { augId = 1006, base = 1,   cat = 11, label = 'Light Affinity: (otherwise same as augID 1000)' },
    [1979] = { augId = 1007, base = 1,   cat = 11, label = 'Dark Affinity: (otherwise same as augID 1000)' },
    [506]  = { augId = 1009, base = 1,   cat = 11, label = 'Ice Affinity: (otherwise same as augID 1008)' },
    [507]  = { augId = 1010, base = 1,   cat = 11, label = 'Wind Affinity: (otherwise same as augID 1008)' },
    [508]  = { augId = 1011, base = 1,   cat = 11, label = 'Earth Affinity: (otherwise same as augID 1008)' },
    [2549] = { augId = 1012, base = 1,   cat = 11, label = 'Lightning Affinity: (otherwise same as augID 1008)' },
    [605]  = { augId = 1013, base = 1,   cat = 11, label = 'Water Affinity: (otherwise same as augID 1008)' },
    [1687] = { augId = 1014, base = 1,   cat = 11, label = 'Light Affinity: (otherwise same as augID 1008)' },
    [3211] = { augId = 1015, base = 1,   cat = 11, label = 'Dark Affinity: (otherwise same as augID 1008)' },
    [3213] = { augId = 1158, base = 2,   cat = 11, label = 'Occ. Resistance to Status Ailments +2' },
    [3215] = { augId = 1370, base = 1,   cat = 11, label = 'Enhances "Dark Seal" effect' },

    -- Skill+
    [923]  = { augId = 257,  base = 1,   cat = 12, label = 'Hand-to-Hand skill+1' },
    [644]  = { augId = 258,  base = 1,   cat = 12, label = 'Dagger skill+1' },
    [656]  = { augId = 259,  base = 1,   cat = 12, label = 'Sword skill+1' },
    [864]  = { augId = 260,  base = 1,   cat = 12, label = 'Great Sword skill+1' },
    [894]  = { augId = 261,  base = 1,   cat = 12, label = 'Axe skill+1' },
    [916]  = { augId = 262,  base = 1,   cat = 12, label = 'Great Axe skill+1' },
    [920]  = { augId = 263,  base = 1,   cat = 12, label = 'Scythe skill+1' },
    [925]  = { augId = 264,  base = 1,   cat = 12, label = 'Polearm skill+1' },
    [940]  = { augId = 265,  base = 1,   cat = 12, label = 'Katana skill+1' },
    [944]  = { augId = 266,  base = 1,   cat = 12, label = 'Great Katana skill+1' },
    [953]  = { augId = 267,  base = 1,   cat = 12, label = 'Club skill+1' },
    [1620] = { augId = 268,  base = 1,   cat = 12, label = 'Staff skill+1' },
    [1982] = { augId = 278,  base = 1,   cat = 12, label = 'Melee skill+1 (for automaton)' },
    [1264] = { augId = 279,  base = 1,   cat = 12, label = 'Ranged skill+1 (for automaton)' },
    [1446] = { augId = 280,  base = 1,   cat = 12, label = 'Magic skill+1 (for automaton)' },
    [2173] = { augId = 281,  base = 1,   cat = 12, label = 'Archery skill+1' },
    [1592] = { augId = 282,  base = 1,   cat = 12, label = 'Marksmanship skill+1' },
    [1616] = { augId = 283,  base = 1,   cat = 12, label = 'Throwing skill+1' },
    [1663] = { augId = 286,  base = 1,   cat = 12, label = 'Shield skill+1' },
    [1685] = { augId = 287,  base = 1,   cat = 12, label = 'Parrying Skill +1' },
    [2212] = { augId = 288,  base = 1,   cat = 12, label = 'Divine magic skill+1' },
    [1864] = { augId = 290,  base = 1,   cat = 12, label = 'Enha.mag. skill+1' },
    [2361] = { augId = 291,  base = 1,   cat = 12, label = 'Enfb.mag. skill+1' },
    [2513] = { augId = 292,  base = 1,   cat = 12, label = 'Elem. magic skill+1' },
    [2524] = { augId = 295,  base = 1,   cat = 12, label = 'Ninjutsu skill+1' },
    [574]  = { augId = 296,  base = 1,   cat = 12, label = 'Singing skill+1' },
    [505]  = { augId = 297,  base = 1,   cat = 12, label = 'String instrument skill+1' },
    [2936] = { augId = 299,  base = 1,   cat = 12, label = 'Blue Magic skill+1' },
    [2937] = { augId = 300,  base = 1,   cat = 12, label = 'Geomancy Skill+1' },
    [1633] = { augId = 301,  base = 1,   cat = 12, label = 'Handbell Skill+1' },

    -- Weaponskill DMG+
    [1110] = { augId = 45,   base = 1,   cat = 13, label = 'DMG:+(X+1), Increases damage rating of this weapon (Maximum X=31 for DMG+32) (Retail: melee,not ranged...Mainhand only?) Item displays a value 1 larger than stored in item' },
    [1473] = { augId = 326,  base = 1,   cat = 13, label = 'Weapon Skill Acc.+1' },
    [865]  = { augId = 327,  base = 1,   cat = 13, label = 'Weapon skill damage+1% "However, some sources apply to all swings of the weapon skill (like Magian Trials Weapon Skill Damage +n% weapons)" (i.e. this indicates the augment is for all hits)' },
    [889]  = { augId = 332,  base = 1,   cat = 13, label = 'Sklchn.dmg.+1%' },
    -- [893] augId 740 (DMG:+1 melee) — REMOVED 2026-05-30: weaker duplicate, keep [908] Dmg:+97 melee.
    -- [896] augId 741 (Dmg:+33 melee) — REMOVED 2026-05-30: weaker duplicate, keep [908] Dmg:+97 melee.
    -- [690] augId 742 (Dmg:+65 melee) — REMOVED 2026-05-30: weaker duplicate, keep [908] Dmg:+97 melee.
    [908]  = { augId = 743,  base = 97,  cat = 13, label = 'Dmg:+97    (melee,not ranged)' },
    -- [924] augId 744 (Dmg:-1 melee) — REMOVED 2026-05-29 audit: self-harm.
    -- [930] augId 745 (Dmg:-33 melee) — REMOVED 2026-05-29 audit: self-harm.
    -- [1016] augId 746 (Dmg:+1 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [2013] Dmg:+97 ranged.
    -- [1738] augId 747 (Dmg:+33 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [2013] Dmg:+97 ranged.
    -- [2323] augId 748 (Dmg:+65 ranged) — REMOVED 2026-05-30: weaker duplicate, keep [2013] Dmg:+97 ranged.
    [2013] = { augId = 749,  base = 97,  cat = 13, label = 'Dmg:+97    (ranged,not melee)' },
    -- [2014] augId 750 (Dmg:-1 ranged) — REMOVED 2026-05-29 audit: self-harm.
    -- [2015] augId 751 (Dmg:-33 ranged) — REMOVED 2026-05-29 audit: self-harm.
    [2229] = { augId = 1024, base = 1,   cat = 13, label = 'Backhand Blow:DMG+5% (increases by 5)' },
    [2365] = { augId = 1025, base = 1,   cat = 13, label = 'Spinning Attack:DMG+5% (increases by 5)' },
    [501]  = { augId = 1026, base = 1,   cat = 13, label = 'Howling Fist:DMG+5% (increases by 5)' },
    [1831] = { augId = 1027, base = 1,   cat = 13, label = 'Dragon Kick:DMG+5% (increases by 5)' },
    [1843] = { augId = 1028, base = 1,   cat = 13, label = 'Viper Bite:DMG+5% (increases by 5)' },
    [2153] = { augId = 1029, base = 1,   cat = 13, label = 'Shadowstitch:DMG+5% (increases by 5)' },
    [2158] = { augId = 1030, base = 1,   cat = 13, label = 'Cyclone:DMG+5% (increases by 5)' },
    [843]  = { augId = 1031, base = 1,   cat = 13, label = 'Evisceration:DMG+5% (increases by 5)' },
    [906]  = { augId = 1032, base = 1,   cat = 13, label = 'Burning Blade:DMG+5% (increases by 5)' },
    [1019] = { augId = 1033, base = 1,   cat = 13, label = 'Shining Blade:DMG+5% (increases by 5)' },
    [1689] = { augId = 1034, base = 1,   cat = 13, label = 'Circle Blade:DMG+5% (increases by 5)' },
    [1706] = { augId = 1035, base = 1,   cat = 13, label = 'Savage Blade:DMG+5% (increases by 5)' },
    [1725] = { augId = 1036, base = 1,   cat = 13, label = 'Freezebite:DMG+5% (increases by 5)' },
    [1784] = { augId = 1037, base = 1,   cat = 13, label = 'Shockwave:DMG+5% (increases by 5)' },
    [1155] = { augId = 1038, base = 1,   cat = 13, label = 'Ground Strike:DMG+5% (increases by 5)' },
    [1786] = { augId = 1039, base = 1,   cat = 13, label = 'Sickle Moon:DMG+5% (increases by 5)' },
    [1311] = { augId = 1040, base = 1,   cat = 13, label = 'Gale Axe:DMG+5% (increases by 5)' },
    [1455] = { augId = 1041, base = 1,   cat = 13, label = 'Spinning Axe:DMG+5% (increases by 5)' },
    [1456] = { augId = 1042, base = 1,   cat = 13, label = 'Calamity:DMG+5% (increases by 5)' },
    [1466] = { augId = 1043, base = 1,   cat = 13, label = 'Decimation:DMG+5% (increases by 5)' },
    [1469] = { augId = 1044, base = 1,   cat = 13, label = 'Iron Tempest:DMG+5% (increases by 5)' },
    [1517] = { augId = 1045, base = 1,   cat = 13, label = 'Sturmwind:DMG+5% (increases by 5)' },
    [2161] = { augId = 1046, base = 1,   cat = 13, label = 'Keen Edge:DMG+5% (increases by 5)' },
    [2162] = { augId = 1047, base = 1,   cat = 13, label = 'Steel Cyclone:DMG+5% (increase by 5)' },
    [1591] = { augId = 1048, base = 1,   cat = 13, label = 'Nightmare Scythe:DMG+5% (increases by 5)' },
    [1618] = { augId = 1049, base = 1,   cat = 13, label = 'Spinning Scythe:DMG+5% (increases by 5)' },
    [1626] = { augId = 1050, base = 1,   cat = 13, label = 'Vorpal Scythe:DMG+5% (increases by 5)' },
    [1628] = { augId = 1051, base = 1,   cat = 13, label = 'Spiral Hell:DMG+5% (increases by 5)' },
    [1650] = { augId = 1052, base = 1,   cat = 13, label = 'Leg Sweep:DMG+5% (increases by 5)' },
    [1680] = { augId = 1053, base = 1,   cat = 13, label = 'Vorpal Thrust:DMG+5% (increases by 5)' },
    [1691] = { augId = 1054, base = 1,   cat = 13, label = 'Skewer:DMG+5% (increases by 5)' },
    [1700] = { augId = 1055, base = 1,   cat = 13, label = 'Impulse Drive:DMG+5% (increases by 5)' },
    [1703] = { augId = 1056, base = 1,   cat = 13, label = 'Blade: To:DMG+5% (increases by 5)' },
    [1704] = { augId = 1057, base = 1,   cat = 13, label = 'Blade: Chi:DMG+5% (increases by 5)' },
    [2223] = { augId = 1058, base = 1,   cat = 13, label = 'Blade: Ten:DMG+5% (increases by 5)' },
    [1719] = { augId = 1059, base = 1,   cat = 13, label = 'Blade: Ku:DMG+5% (increases by 5)' },
    [2226] = { augId = 1060, base = 1,   cat = 13, label = 'Tachi: Goten:DMG+5% (increases by 5)' },
    [1816] = { augId = 1061, base = 1,   cat = 13, label = 'Tachi: Jinpu:DMG+5% (increases by 5)' },
    [2227] = { augId = 1062, base = 1,   cat = 13, label = 'Tachi: Koki:DMG+5% (increases by 5)' },
    [2235] = { augId = 1063, base = 1,   cat = 13, label = 'Tachi: Kasha:DMG+5% (increases by 5)' },
    [2274] = { augId = 1064, base = 1,   cat = 13, label = 'Brainshaker:DMG+5% (increases by 5)' },
    [2322] = { augId = 1065, base = 1,   cat = 13, label = 'Skullbreaker:DMG+5% (increases by 5)' },
    [2324] = { augId = 1066, base = 1,   cat = 13, label = 'Judgment:DMG+5% (increases by 5)' },
    [2325] = { augId = 1067, base = 1,   cat = 13, label = 'Black Halo:DMG+5% (increases by 5)' },
    [497]  = { augId = 1068, base = 1,   cat = 13, label = 'Rock Crusher:DMG+5% (increases by 5)' },
    [2175] = { augId = 1069, base = 1,   cat = 13, label = 'Shell Crusher:DMG+5% (increases by 5)' },
    [498]  = { augId = 1070, base = 1,   cat = 13, label = 'Full Swing:DMG+5% (increases by 5)' },
    [529]  = { augId = 1071, base = 1,   cat = 13, label = 'Retribution:DMG+5% (increases by 5)' },
    [2488] = { augId = 1072, base = 1,   cat = 13, label = 'Dulling Arrow:DMG+5% (increases by 5)' },
    [554]  = { augId = 1073, base = 1,   cat = 13, label = 'Blast Arrow:DMG+5% (increases by 5)' },
    [560]  = { augId = 1074, base = 1,   cat = 13, label = 'Arching Arrow:DMG+5% (increases by 5)' },
    [2808] = { augId = 1075, base = 1,   cat = 13, label = 'Empyreal Arrow:DMG+5% (increases by 5)' },
    [2809] = { augId = 1076, base = 1,   cat = 13, label = 'Hot Shot:DMG+5% (increases by 5)' },
    [2810] = { augId = 1077, base = 1,   cat = 13, label = 'Split Shot:DMG+5% (increases by 5)' },
    [2849] = { augId = 1078, base = 1,   cat = 13, label = 'Sniper Shot:DMG+5% (increases by 5)' },
    [2851] = { augId = 1079, base = 1,   cat = 13, label = 'Detonator:DMG+5% (increases by 5)' },
    [2859] = { augId = 1080, base = 1,   cat = 13, label = 'Weapon Skill:DMG+5% (increases by 5)' },
    [637]  = { augId = 1081, base = 1,   cat = 13, label = 'Final Heaven:DMG+5% (increases by 5)' },
    [499]  = { augId = 1082, base = 1,   cat = 13, label = 'Ascetics Fury:DMG+5% (increases by 5)' },
    [510]  = { augId = 1083, base = 1,   cat = 13, label = 'Stringing Pummel:DMG+5% (increases by 5)' },
    [511]  = { augId = 1084, base = 1,   cat = 13, label = 'Victory Smite:DMG+5% (increases by 5)' },
    [531]  = { augId = 1085, base = 1,   cat = 13, label = 'Mercy Stroke:DMG+5% (increases by 5)' },
    [677]  = { augId = 1086, base = 1,   cat = 13, label = 'Pyric Kleos:DMG+5% (increases by 5)' },
    [2927] = { augId = 1087, base = 1,   cat = 13, label = 'Mandalic Stab:DMG+5% (increases by 5)' },
    [2931] = { augId = 1088, base = 1,   cat = 13, label = 'Mordant Rime:DMG+5% (increases by 5)' },
    [722]  = { augId = 1089, base = 1,   cat = 13, label = 'Rudra\'s Storm:DMG+5% (increases by 5)' },
    [724]  = { augId = 1090, base = 1,   cat = 13, label = 'Knights of Round:DMG+5% (increases by 5)' },
    [1624] = { augId = 1091, base = 1,   cat = 13, label = 'Death Blossom:DMG+5% (increases by 5)' },
    [1625] = { augId = 1092, base = 1,   cat = 13, label = 'Expiacion:DMG+5% (increases by 5)' },
    [1631] = { augId = 1093, base = 1,   cat = 13, label = 'Chant du Cygne:DMG+5% (increases by 5)' },
    [1638] = { augId = 1094, base = 1,   cat = 13, label = 'Randgrith:DMG+5% (increases by 5)' },
    [1639] = { augId = 1095, base = 1,   cat = 13, label = 'Mystic Boon:DMG+5% (increases by 5)' },
    [1649] = { augId = 1096, base = 1,   cat = 13, label = 'Scourge:DMG+5% (increases by 5)' },
    [1688] = { augId = 1097, base = 1,   cat = 13, label = 'Torcleaver:DMG+5% (increases by 5)' },
    [1817] = { augId = 1098, base = 1,   cat = 13, label = 'Onslaught:DMG+5% (increases by 5)' },
    [1830] = { augId = 1099, base = 1,   cat = 13, label = 'Primal Rend:DMG+5% (increases by 5)' },
    [1861] = { augId = 1100, base = 1,   cat = 13, label = 'Cloudsplitter:DMG+5% (increases by 5)' },
    [1869] = { augId = 1101, base = 1,   cat = 13, label = 'Metatron Torment:DMG+5% (increases by 5)' },
    [1888] = { augId = 1102, base = 1,   cat = 13, label = 'King\'s Justice:DMG+5% (increases by 5)' },
    [1889] = { augId = 1103, base = 1,   cat = 13, label = 'Ukko\'s Fury:DMG+5% (increases by 5)' },
    [1981] = { augId = 1104, base = 1,   cat = 13, label = 'Catastrophe:DMG+5% (increases by 5)' },
    [2121] = { augId = 1105, base = 1,   cat = 13, label = 'Insurgency:DMG+5% (increases by 5)' },
    [2155] = { augId = 1106, base = 1,   cat = 13, label = 'Quietus:DMG+5% (increases by 5)' },
    [3502] = { augId = 1107, base = 1,   cat = 13, label = 'Geirskogul:DMG+5% (increases by 5)' },
    [3503] = { augId = 1108, base = 1,   cat = 13, label = 'Drakesbane:DMG+5% (increases by 5)' },
    [573]  = { augId = 1109, base = 1,   cat = 13, label = 'Camlann\'s Torment:DMG+5% (increases by 5)' },

    -- Progression (Exp / Cap)
    ---   Cap. Point +33% (augId 75) maps to Mod::CAPACITY_BONUS (915) in
    ---   sql/augments.sql and works out of the box.
    ---   Exp. Point +33% (augId 73) shipped with modId=0 upstream — a real
    ---   bug, nothing applied to the player when equipped. Fixed locally
    ---   by modules/custom/sql/fix_aug_73_exp_bonus.sql, which points it
    ---   at Mod::EXP_BONUS (382). Apply that SQL once and restart map.
    ---   cat = 12 (Skill+) so Augment Sage's Skill+ affinity also boosts these.
    ---   The triple-dash prefix on the explanatory lines above keeps the
    ---   docgen from picking them up as section headers -- only the
    ---   single-dash "-- Progression (Exp / Cap)" line above is a header.
    [2523] = { augId = 73,   base = 1,   cat = 12, label = 'Exp. Point +33%' },  -- peiste_skin
    [2147] = { augId = 75,   base = 1,   cat = 12, label = 'Cap. Point +33%' },  -- beastly_shank
}
