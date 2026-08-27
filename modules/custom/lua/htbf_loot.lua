-----------------------------------
-- htbf_loot.lua  -- retail-sourced armoury-crate loot per HTBF fight (relaunch)
--
-- One table per fightKey (consumed as catalog.fightLoot[fightKey] -> content.loot),
-- applied to all tiers of that fight. The item roster stays per-fight, while
-- htbf.lua converts optional-entry rarity bands into tier-specific drop rates.
--
-- Format = utils.selectFromLootGroups: an array of GROUPS; each group an array of
-- { itemId = xi.item.X, weight = N, amount = M? } (+ optional group `quantity`,
-- default 1). Within a group one entry is rolled, weighted by `weight`. itemId 0
-- is a "drop nothing" slot (NEVER nil -- the engine logs an error on a nil id).
--
-- ECONOMY-CONSCIOUS (these battlefields are REPEATABLE + the server runs an AH
-- market-maker): GROUP 1 is a reliable common material/currency reward. Groups
-- containing itemId 0 are optional loot: each real entry rolls independently,
-- with source weights 50 / 80 / 120+ mapping to rare / uncommon / common tier
-- rates in htbf_catalog.lua. Treasure Hunter then improves every optional roll.
-- The legacy itemId 0 weight remains descriptive but is not rolled by HTBF.
--
-- Sourced from bg-wiki HTBF pages 2026-06-27; EVERY xi.item.* verified present in
-- scripts/enum/item.lua. Items with no enum const were omitted (notes inline).
-----------------------------------
local fightLoot = {}

-- ── Avatar Prime trials (share AVATAR_PHANTOM_GEM) ───────────────────────────
-- bg-wiki only populates treasure for Shiva Prime + Leviathan Prime; the other
-- four have empty (Information Needed) tables, so they fall back to the canonical
-- elemental Belt/Ring avatar-fight gear. G1 = elemental crystal + cluster.
fightLoot.trial_by_fire =
{
    {
        { itemId = xi.item.FIRE_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.FIRE_CLUSTER, weight = 30 },
    },
    { -- BiS (ilvl 119): 6 item(s) x weight 50, whiff 700
        quantity = 1,
        { itemId = 0, weight = 700 },
        { itemId = 21115, weight = 50 },  -- Aedold +2 (Skirmish weapon)
        { itemId = 21230, weight = 50 },  -- Bocluamni +2 (Skirmish weapon)
        { itemId = 20764, weight = 50 },  -- Crobaci +2 (Skirmish weapon)
        { itemId = 20716, weight = 50 },  -- Perfervid Sword (RDM Sword)
        { itemId = 21036, weight = 50 },  -- Atakigiri (Katana)
        { itemId = 28285, weight = 50 },  -- Coalrake Sabots (Feet)
    },
    { -- Endgame (ilvl 111-118): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 21126, weight = 80 },  -- Aedold +1 (Skirmish weapon)
        { itemId = 21236, weight = 80 },  -- Bocluamni +1 (Skirmish weapon)
        { itemId = 20775, weight = 80 },  -- Crobaci +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 3 item(s) x weight 120, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = 21132, weight = 120 },  -- Aedold (Skirmish weapon)
        { itemId = 21242, weight = 120 },  -- Bocluamni (Skirmish weapon)
        { itemId = 20787, weight = 120 },  -- Crobaci (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 27594, weight = 80 },  -- Annealed Mantle (Back)
        { itemId = 21421, weight = 80 },  -- Immolation Grip (Grip)
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.FIRE_BELT, weight = 180 },
        { itemId = xi.item.FIRE_RING, weight = 180 },
    },
}
fightLoot.trial_by_ice =
{
    {
        { itemId = xi.item.ICE_CRYSTAL, weight = 65, amount = 6 },
        { itemId = xi.item.ICE_CLUSTER, weight = 30 },
        { itemId = xi.item.FLOESTONE,   weight = 25 },
    },
    { -- BiS (ilvl 119): 5 item(s) x weight 50, whiff 750
        quantity = 1,
        { itemId = 0, weight = 750 },
        { itemId = xi.item.CALVED_CLAWS, weight = 50 },
        { itemId = xi.item.FRAZIL_STAFF, weight = 50 },
        { itemId = xi.item.NILAS_GLOVES, weight = 50 },
        { itemId = 20816, weight = 50 },  -- Faizzeer +2 (Skirmish weapon)
        { itemId = 21279, weight = 50 },  -- Hgafircian +2 (Skirmish weapon)
    },
    { -- Endgame (ilvl 111-118): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 20824, weight = 80 },  -- Faizzeer +1 (Skirmish weapon)
        { itemId = 21286, weight = 80 },  -- Hgafircian +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 2 item(s) x weight 120, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 20833, weight = 120 },  -- Faizzeer (Skirmish weapon)
        { itemId = 21294, weight = 120 },  -- Hgafircian (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.RIMEICE_EARRING, weight = 80 },
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.ICE_BELT, weight = 180 },
        { itemId = xi.item.ICE_RING, weight = 180 },
    },
}
fightLoot.trial_by_wind =
{
    {
        { itemId = xi.item.WIND_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.WIND_CLUSTER, weight = 30 },
    },
    { -- BiS (ilvl 119): 6 item(s) x weight 50, whiff 700
        quantity = 1,
        { itemId = 0, weight = 700 },
        { itemId = 20863, weight = 50 },  -- Iclamar +2 (Skirmish weapon)
        { itemId = 20907, weight = 50 },  -- Iizamal +2 (Skirmish weapon)
        { itemId = 20725, weight = 50 },  -- Iztaasu +2 (Skirmish weapon)
        { itemId = 20615, weight = 50 },  -- Levante Dagger
        { itemId = 20808, weight = 50 },  -- Tramontane Axe
        { itemId = 28286, weight = 50 },  -- Ostro Greaves (Legs)
    },
    { -- Endgame (ilvl 111-118): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 20870, weight = 80 },  -- Iclamar +1 (Skirmish weapon)
        { itemId = 20915, weight = 80 },  -- Iizamal +1 (Skirmish weapon)
        { itemId = 20736, weight = 80 },  -- Iztaasu +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 3 item(s) x weight 120, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = 20877, weight = 120 },  -- Iclamar (Skirmish weapon)
        { itemId = 20924, weight = 120 },  -- Iizamal (Skirmish weapon)
        { itemId = 20742, weight = 120 },  -- Iztaasu (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 28538, weight = 80 },  -- Lebeche Ring
        { itemId = 28441, weight = 80 },  -- Ponente Sash (Waist)
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.WIND_BELT, weight = 180 },
        { itemId = xi.item.WIND_RING, weight = 180 },
    },
}
fightLoot.trial_by_earth =
{
    {
        { itemId = xi.item.EARTH_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.EARTH_CLUSTER, weight = 30 },
    },
    { -- BiS (ilvl 119): 5 item(s) x weight 50, whiff 750
        quantity = 1,
        { itemId = 0, weight = 750 },
        { itemId = 20996, weight = 50 },  -- Kannakiri +2 (Skirmish weapon)
        { itemId = 21179, weight = 50 },  -- Lehbrailg +2 (Skirmish weapon)
        { itemId = 21102, weight = 50 },  -- Mafic Cudgel (Club)
        { itemId = 20757, weight = 50 },  -- Foreshock Sword
        { itemId = 21357, weight = 50 },  -- Togakushi Shuriken (NIN Throwing)
    },
    { -- Endgame (ilvl 111-118): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 21004, weight = 80 },  -- Kannakiri +1 (Skirmish weapon)
        { itemId = 21194, weight = 80 },  -- Lehbrailg +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 2 item(s) x weight 120, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 21013, weight = 120 },  -- Kannakiri (Skirmish weapon)
        { itemId = 21208, weight = 120 },  -- Lehbrailg (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 28535, weight = 80 },  -- Supershear Ring
        { itemId = 21358, weight = 80 },  -- Plumose Sachet (Waist)
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.EARTH_BELT, weight = 180 },
        { itemId = xi.item.EARTH_RING, weight = 180 },
    },
}
fightLoot.trial_by_lightning =
{
    {
        { itemId = xi.item.LIGHTNING_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.LIGHTNING_CLUSTER, weight = 30 },
    },
    { -- BiS (ilvl 119): 6 item(s) x weight 50, whiff 700
        quantity = 1,
        { itemId = 0, weight = 700 },
        { itemId = 20623, weight = 50 },  -- Leisilonu +2 (Skirmish weapon)
        { itemId = 20539, weight = 50 },  -- Ninzas +2 (Skirmish weapon)
        { itemId = 20952, weight = 50 },  -- Qatsunoci +2 (Skirmish weapon)
        { itemId = 21166, weight = 50 },  -- Staccato Staff
        { itemId = 21274, weight = 50 },  -- Donar Gun (COR)
        { itemId = 28142, weight = 50 },  -- Brontes Cuisses (Legs)
    },
    { -- Endgame (ilvl 111-118): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 20634, weight = 80 },  -- Leisilonu +1 (Skirmish weapon)
        { itemId = 20546, weight = 80 },  -- Ninzas +1 (Skirmish weapon)
        { itemId = 20961, weight = 80 },  -- Qatsunoci +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 3 item(s) x weight 120, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = 20641, weight = 120 },  -- Leisilonu (Skirmish weapon)
        { itemId = 20553, weight = 120 },  -- Ninzas (Skirmish weapon)
        { itemId = 20967, weight = 120 },  -- Qatsunoci (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 28354, weight = 80 },  -- Voltsurge Torque (Neck)
        { itemId = 28432, weight = 80 },  -- Ukko Sash (Waist)
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.LIGHTNING_BELT, weight = 180 },
        { itemId = xi.item.LIGHTNING_RING, weight = 180 },
    },
}
fightLoot.trial_by_water =
{
    {
        { itemId = xi.item.WATER_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.WATER_CLUSTER, weight = 30 },
    },
    { -- BiS (ilvl 119): 2 item(s) x weight 50, whiff 900
        quantity = 1,
        { itemId = 0, weight = 900 },
        { itemId = 21043, weight = 50 },  -- Shichishito +2 (Skirmish weapon)
        { itemId = 21180, weight = 50 },  -- Uffrat +2 (Skirmish weapon)
    },
    { -- Endgame (ilvl 111-118): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 21051, weight = 80 },  -- Shichishito +1 (Skirmish weapon)
        { itemId = 21195, weight = 80 },  -- Uffrat +1 (Skirmish weapon)
    },
    { -- Mid (ilvl 100-110): 2 item(s) x weight 120, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 21058, weight = 120 },  -- Shichishito (Skirmish weapon)
        { itemId = 21209, weight = 120 },  -- Uffrat (Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.NERITIC_EARRING, weight = 80 },
    },
    { -- Non-ilvl (level <75): 2 item(s) x weight 180, whiff 640
        quantity = 1,
        { itemId = 0, weight = 640 },
        { itemId = xi.item.WATER_BELT, weight = 180 },
        { itemId = xi.item.WATER_RING, weight = 180 },
    },
}
-- ── Chains of Promathia ──────────────────────────────────────────────────────
-- Real HTBF gear pools. The retail "testimonial" materials (Maliyakaleya Coral,
-- Hepatizon Ore, etc.) are Adoulin-era and absent from this enum, so G1 uses
-- CoP-era ingots matching the tierLoot palette.
fightLoot.the_savage =
{
    {
        { itemId = xi.item.GOLD_INGOT,     weight = 120 },
        { itemId = xi.item.PLATINUM_INGOT, weight =  50 },
        { itemId = xi.item.DAMASCUS_INGOT, weight =  20 },
    },
    { -- BiS (ilvl 119): 11 item(s) x weight 50, whiff 450
        quantity = 1,
        { itemId = 0, weight = 450 },
        { itemId = xi.item.HEGIRA_WRISTBANDS, weight = 50 },
        { itemId = xi.item.ISCHEMIA_CHASUBLE, weight = 50 },
        { itemId = xi.item.SCUFFLERS_COSCIALES, weight = 50 },
        { itemId = 27728, weight = 50 },  -- Cizin Helm +1 (Skirmish armor)
        { itemId = 27874, weight = 50 },  -- Cizin Mail +1 (Skirmish armor)
        { itemId = 28018, weight = 50 },  -- Cizin Mufflers +1 (Skirmish armor)
        { itemId = 21585, weight = 50 },  -- Crepuscular Knife (Dagger)
        { itemId = 18566, weight = 50 },  -- Crepuscular Scythe (Scythe)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Endgame (ilvl 111-118): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 27768, weight = 80 },  -- Cizin Helm (Skirmish armor)
        { itemId = 27912, weight = 80 },  -- Cizin Mail (Skirmish armor)
    },
    { -- Non-ilvl (level 95-99): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = xi.item.METALSINGER_BELT, weight = 80 },
        { itemId = xi.item.DOMESTICATORS_EARRING, weight = 80 },
        { itemId = 22300, weight = 80 },  -- Crepuscular Pebble (Ammo)
    },
    { -- Non-ilvl (level <75): 1 item(s) x weight 180, whiff 820
        quantity = 1,
        { itemId = 0, weight = 820 },
        { itemId = 15322, weight = 180 },  -- Herald's Gaiters (SAM/DRG Feet)
    },
}
fightLoot.warriors_path =
{
    {
        { itemId = xi.item.PLATINUM_INGOT, weight = 100 },
        { itemId = xi.item.GOLD_INGOT,     weight =  60 },
        { itemId = xi.item.DAMASCUS_INGOT, weight =  25 },
    },
    { -- BiS (ilvl 119): 9 item(s) x weight 50, whiff 550
        quantity = 1,
        { itemId = 0, weight = 550 },
        { itemId = xi.item.HANGAKU_NO_YUMI, weight = 50 },
        { itemId = xi.item.SUKEROKU_HACHIMAKI, weight = 50 },
        { itemId = xi.item.BATTLECAST_GAITERS, weight = 50 },
        { itemId = xi.item.SERAPHICALLER, weight = 50 },
        { itemId = xi.item.DIVINATOR, weight = 50 },
        { itemId = 28160, weight = 50 },  -- Cizin Breeches +1 (Skirmish armor)
        { itemId = 28297, weight = 50 },  -- Cizin Greaves +1 (Skirmish armor)
        { itemId = 28654, weight = 50 },  -- Beatific Shield +1 (Skirmish armor)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Endgame (ilvl 111-118): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = 28192, weight = 80 },  -- Cizin Breeches (Skirmish armor)
        { itemId = 28332, weight = 80 },  -- Cizin Greaves (Skirmish armor)
        { itemId = 28662, weight = 80 },  -- Beatific Shield (Skirmish armor)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = xi.item.GINSEN, weight = 80 },
        { itemId = xi.item.MIZUKAGE_NO_KUBIKAZARI, weight = 80 },
    },
}
fightLoot.one_to_be_feared =
{
    {
        { itemId = xi.item.ORICHALCUM_INGOT, weight =  90 },
        { itemId = xi.item.PLATINUM_INGOT,   weight =  60 },
        { itemId = xi.item.DAMASCUS_INGOT,   weight =  25 },
    },
    { -- BiS (ilvl 119): 10 item(s) x weight 50, whiff 500
        quantity = 1,
        { itemId = 0, weight = 500 },
        { itemId = xi.item.DENOUEMENTS, weight = 50 },
        { itemId = xi.item.CULMINUS, weight = 50 },
        { itemId = xi.item.TERMINAL_HELM, weight = 50 },
        { itemId = xi.item.TERMINAL_PLATE, weight = 50 },
        { itemId = 27729, weight = 50 },  -- Otronif Mask +1 (Skirmish armor)
        { itemId = 27875, weight = 50 },  -- Otronif Harness +1 (Skirmish armor)
        { itemId = 28019, weight = 50 },  -- Otronif Gloves +1 (Skirmish armor)
        { itemId = 28161, weight = 50 },  -- Otronif Brais +1 (Skirmish armor)
        { itemId = 28298, weight = 50 },  -- Otronif Boots +1 (Skirmish armor)
        { itemId = 26117, weight = 50 },  -- Crepuscular Earring
    },
    { -- Non-ilvl (level 95-99): 3 item(s) x weight 80, whiff 760
        quantity = 1,
        { itemId = 0, weight = 760 },
        { itemId = xi.item.CESSANCE_EARRING, weight = 80 },
        { itemId = xi.item.CONSUMMATION_TORQUE, weight = 80 },
        { itemId = 26220, weight = 80 },  -- Crepuscular Ring
    },
}
fightLoot.head_wind =
{
    {
        { itemId = xi.item.GOLD_INGOT,     weight = 120 },
        { itemId = xi.item.PLATINUM_INGOT, weight =  50 },
        { itemId = xi.item.DAMASCUS_INGOT, weight =  20 },
    },
    { -- BiS (ilvl 119): 12 item(s) x weight 50, whiff 400
        quantity = 1,
        { itemId = 0, weight = 400 },
        { itemId = xi.item.NILGAL_POLE, weight = 50 },
        { itemId = xi.item.CHIDORI, weight = 50 },
        { itemId = xi.item.BAGHERE_SALADE, weight = 50 },
        { itemId = xi.item.DURGAI_LEGGINGS, weight = 50 },
        { itemId = 27730, weight = 50 },  -- Iuitl Headgear +1 (Skirmish armor)
        { itemId = 27876, weight = 50 },  -- Iuitl Vest +1 (Skirmish armor)
        { itemId = 28020, weight = 50 },  -- Iuitl Wristbands +1 (Skirmish armor)
        { itemId = 28162, weight = 50 },  -- Iuitl Tights +1 (Skirmish armor)
        { itemId = 28299, weight = 50 },  -- Iuitl Gaiters +1 (Skirmish armor)
        { itemId = 23797, weight = 50 },  -- Crepuscular Helm (Head)
        { itemId = 23798, weight = 50 },  -- Crepuscular Mail (Body)
        { itemId = 23799, weight = 50 },  -- Crepuscular Cloak (Back)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.SHETAL_STONE, weight = 80 },
    },
}
-- Dawn (Promathia). Its own retail HTBF gear pool. G1 = CoP-era ingots (the
-- retail testimonial mats -- Maliyakaleya Coral etc. -- are Adoulin-era and have
-- no enum const here). G2 = the six Dawn reward pieces.
fightLoot.dawn =
{
    {
        { itemId = xi.item.ORICHALCUM_INGOT, weight =  90 },
        { itemId = xi.item.GOLD_INGOT,       weight =  70 },
        { itemId = xi.item.DAMASCUS_INGOT,   weight =  25 },
    },
    { -- BiS (ilvl 119): 4 item(s) x weight 50, whiff 800
        quantity = 1,
        { itemId = 0, weight = 800 },
        { itemId = 20698, weight = 50 },  -- Fettering Blade (Sword)
        { itemId = 22118, weight = 50 },  -- Venery Bow (Archery)
        { itemId = 25708, weight = 50 },  -- Gyve Doublet (Body)
        { itemId = 27324, weight = 50 },  -- Gyve Trousers (Legs)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 27618, weight = 80 },  -- Laic Mantle (Back)
        { itemId = 26324, weight = 80 },  -- Latria Sash (Waist)
    },
}
-- ── Treasures of Aht Urhgan (mission fights -- no retail crate) ───────────────
-- Imperial currency + HQ Aht Urhgan organs as the thematic reward.
fightLoot.puppet_in_peril =
{
    {
        { itemId = xi.item.IMPERIAL_MYTHRIL_PIECE, weight = 90 },
        { itemId = xi.item.ONE_BYNE_BILL,          weight = 70 },
        { itemId = xi.item.IMPERIAL_GOLD_PIECE,    weight = 25 },
    },
    { -- materials (preserved from prior Group 2)
        quantity = 1,
        { itemId = 0, weight = 850 },
        { itemId = xi.item.HIGH_QUALITY_AERN_ORGAN, weight = 40 },
        { itemId = xi.item.DAMASCUS_INGOT, weight = 25 },
    },
    { -- BiS (ilvl 119): 12 item(s) x weight 50, whiff 400
        quantity = 1,
        { itemId = 0, weight = 400 },
        { itemId = 27732, weight = 50 },  -- Hagondes Hat +1 (Skirmish armor)
        { itemId = 27878, weight = 50 },  -- Hagondes Coat +1 (Skirmish armor)
        { itemId = 28022, weight = 50 },  -- Hagondes Cuffs +1 (Skirmish armor)
        { itemId = 28164, weight = 50 },  -- Hagondes Pants +1 (Skirmish armor)
        { itemId = 28301, weight = 50 },  -- Hagondes Sabots +1 (Skirmish armor)
        { itemId = 21368, weight = 50 },  -- Bestas Bane (Great Axe)
        { itemId = 27862, weight = 50 },  -- Savas Jawshan (Body)
        { itemId = 28151, weight = 50 },  -- Sifahir Slacks (Legs)
        { itemId = 27710, weight = 50 },  -- Sahip Helm (Head)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = 28498, weight = 80 },  -- Pratik Earring
    },
}
fightLoot.legacy_of_the_lost =
{
    {
        { itemId = xi.item.IMPERIAL_GOLD_PIECE,    weight = 80 },
        { itemId = xi.item.ONE_BYNE_BILL,          weight = 70 },
        { itemId = xi.item.IMPERIAL_MYTHRIL_PIECE, weight = 40 },
    },
    { -- materials (preserved from prior Group 2)
        quantity = 1,
        { itemId = 0, weight = 850 },
        { itemId = xi.item.HIGH_QUALITY_EUVHI_ORGAN, weight = 35 },
        { itemId = xi.item.HIGH_QUALITY_PHUABO_ORGAN, weight = 35 },
        { itemId = xi.item.DAMASCUS_INGOT, weight = 20 },
    },
    { -- BiS (ilvl 119): 11 item(s) x weight 50, whiff 450
        quantity = 1,
        { itemId = 0, weight = 450 },
        { itemId = 27731, weight = 50 },  -- Gendewitha Caubeen +1 (Skirmish armor)
        { itemId = 27877, weight = 50 },  -- Gendewitha Bliaut +1 (Skirmish armor)
        { itemId = 28021, weight = 50 },  -- Gendewitha Gages +1 (Skirmish armor)
        { itemId = 28163, weight = 50 },  -- Gendewitha Spats +1 (Skirmish armor)
        { itemId = 28300, weight = 50 },  -- Gendewitha Galoshes +1 (Skirmish armor)
        { itemId = 27709, weight = 50 },  -- Ptica Headgear
        { itemId = 27861, weight = 50 },  -- Karmesin Vest (Body)
        { itemId = 28288, weight = 50 },  -- Kandza Crackows (Feet)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = 21367, weight = 80 },  -- Tengu-no-Hane (NIN Back)
        { itemId = 28448, weight = 80 },  -- Tengu-no-Obi (Waist)
    },
}
-- ── Rise of the Zilart ───────────────────────────────────────────────────────
-- Mission fights (no retail crate) -> forge-tier ingots/hides; Celestial Nexus
-- rarest. Divine Might is the only one with real retail gear (its 5 earrings).
fightLoot.shadow_lord =
{
    {
        { itemId = xi.item.DARKSTEEL_INGOT, weight = 100 },
        { itemId = xi.item.MYTHRIL_INGOT,   weight =  70 },
        { itemId = xi.item.GOLD_INGOT,      weight =  40 },
    },
    { -- materials (preserved from prior Group 2)
        quantity = 1,
        { itemId = 0, weight = 850 },
        { itemId = xi.item.DAMASCUS_INGOT, weight = 30 },
        { itemId = xi.item.PHILOSOPHERS_STONE, weight = 25 },
    },
    { -- BiS (ilvl 119): 12 item(s) x weight 50, whiff 400
        -- Malignance pieces removed 2026-07-31 (reserved for future content).
        quantity = 1,
        { itemId = 0, weight = 400 },
        { itemId = 26733, weight = 50 },  -- Yorium Barbuta (Alluvion Skirmish armor)
        { itemId = 26891, weight = 50 },  -- Yorium Cuirass (Alluvion Skirmish armor)
        { itemId = 27045, weight = 50 },  -- Yorium Gauntlets (Alluvion Skirmish armor)
        { itemId = 27232, weight = 50 },  -- Yorium Cuisses (Alluvion Skirmish armor)
        { itemId = 27402, weight = 50 },  -- Yorium Sabatons (Alluvion Skirmish armor)
        { itemId = 20858, weight = 50 },  -- Lightreaver (Great Sword)
        { itemId = 28009, weight = 50 },  -- Onimusha-no-Kote (Hands)
        { itemId = 27858, weight = 50 },  -- Dread Jupon (DRK Body)
        { itemId = 28148, weight = 50 },  -- Perdition Slops (MNK/BLM Legs)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.TREPIDITY_MANTLE, weight = 80 },
    },
}
fightLoot.stellar_fulcrum =
{
    {
        { itemId = xi.item.GOLD_INGOT,      weight = 90 },
        { itemId = xi.item.DARKSTEEL_INGOT, weight = 70 },
        { itemId = xi.item.BEHEMOTH_HIDE,   weight = 30 },
    },
    { -- materials (preserved from prior Group 2)
        quantity = 1,
        { itemId = 0, weight = 850 },
        { itemId = xi.item.ORICHALCUM_INGOT, weight = 30 },
        { itemId = xi.item.DRAGON_TALON, weight = 20 },
    },
    { -- BiS (ilvl 119): 12 item(s) x weight 50, whiff 400
        quantity = 1,
        { itemId = 0, weight = 400 },
        { itemId = 26737, weight = 50 },  -- Helios Band (Alluvion Skirmish armor)
        { itemId = 26895, weight = 50 },  -- Helios Jacket (Alluvion Skirmish armor)
        { itemId = 27049, weight = 50 },  -- Helios Gloves (Alluvion Skirmish armor)
        { itemId = 27236, weight = 50 },  -- Helios Spats (Alluvion Skirmish armor)
        { itemId = 27406, weight = 50 },  -- Helios Boots (Alluvion Skirmish armor)
        { itemId = 20770, weight = 50 },  -- Mes'yohi Sword
        { itemId = 21122, weight = 50 },  -- Mes'yohi Rod
        { itemId = 27886, weight = 50 },  -- Mes'yohi Haubergeon (Body)
        { itemId = 28172, weight = 50 },  -- Mes'yohi Slacks (Legs)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
}
fightLoot.celestial_nexus =
{
    {
        { itemId = xi.item.PLATINUM_INGOT,   weight = 90 },
        { itemId = xi.item.ORICHALCUM_INGOT, weight = 50 },
        { itemId = xi.item.BEHEMOTH_HIDE,    weight = 30 },
    },
    { -- materials (preserved from prior Group 2)
        quantity = 1,
        { itemId = 0, weight = 850 },
        { itemId = xi.item.DRAGON_HEART, weight = 25 },
        { itemId = xi.item.DAMASCUS_INGOT, weight = 20 },
    },
    { -- BiS (ilvl 119): 13 item(s) x weight 50, whiff 350
        -- Malignance Pole removed 2026-07-31 (reserved for future content).
        quantity = 1,
        { itemId = 0, weight = 350 },
        { itemId = 26736, weight = 50 },  -- Telchine Cap (Alluvion Skirmish armor)
        { itemId = 26894, weight = 50 },  -- Telchine Chasuble (Alluvion Skirmish armor)
        { itemId = 27048, weight = 50 },  -- Telchine Gloves (Alluvion Skirmish armor)
        { itemId = 27235, weight = 50 },  -- Telchine Braconi (Alluvion Skirmish armor)
        { itemId = 27405, weight = 50 },  -- Telchine Pigaches (Alluvion Skirmish armor)
        { itemId = 22040, weight = 50 },  -- Daybreak (healer Club)
        { itemId = 20632, weight = 50 },  -- Vanir Knife (Dagger)
        { itemId = 21284, weight = 50 },  -- Vanir Gun
        { itemId = 27887, weight = 50 },  -- Vanir Cotehardie (Body)
        { itemId = 28310, weight = 50 },  -- Vanir Boots
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        -- Malignance Earring removed 2026-07-31 (reserved for future content).
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = 21380, weight = 80 },  -- Vanir Battery (Ammo)
    },
}
-- Divine Might: the 5 reward earrings (retail a quest CHOICE -> here a weighted
-- single-earring drop), gated hard behind the 0-slot (~7.6% any earring/clear).
fightLoot.divine_might =
{
    {
        { itemId = xi.item.SQUARE_OF_RAINBOW_VELVET, weight = 90 },
        { itemId = xi.item.GOLD_INGOT,               weight = 70 },
        { itemId = xi.item.DAMASCUS_INGOT,           weight = 25 },
    },
    { -- BiS (ilvl 119): 14 item(s) x weight 50, whiff 300
        -- Malignance armor removed 2026-07-31 (reserved for future content).
        quantity = 1,
        { itemId = 0, weight = 300 },
        { itemId = 26734, weight = 50 },  -- Acro Helm (Alluvion Skirmish armor)
        { itemId = 26892, weight = 50 },  -- Acro Surcoat (Alluvion Skirmish armor)
        { itemId = 27046, weight = 50 },  -- Acro Gauntlets (Alluvion Skirmish armor)
        { itemId = 27233, weight = 50 },  -- Acro Breeches (Alluvion Skirmish armor)
        { itemId = 27403, weight = 50 },  -- Acro Leggings (Alluvion Skirmish armor)
        { itemId = 26735, weight = 50 },  -- Taeon Chapeau (Alluvion Skirmish armor)
        { itemId = 26893, weight = 50 },  -- Taeon Tabard (Alluvion Skirmish armor)
        { itemId = 27047, weight = 50 },  -- Taeon Gloves (Alluvion Skirmish armor)
        { itemId = 27234, weight = 50 },  -- Taeon Tights (Alluvion Skirmish armor)
        { itemId = 27404, weight = 50 },  -- Taeon Boots (Alluvion Skirmish armor)
        { itemId = 27888, weight = 50 },  -- Kyujutsugi (SAM/GEO Body)
        { itemId = 21381, weight = 50 },  -- Seraphicaller (BRD horn)
        { itemId = 21452, weight = 50 },  -- Divinator (mage club)
        { itemId = 22261, weight = 50 },  -- Divinator II (mage club HQ)
    },
    { -- Non-ilvl (level 95-99): 7 item(s) x weight 80, whiff 440
        quantity = 1,
        { itemId = 0, weight = 440 },
        { itemId = 21425, weight = 80 },  -- Lentus Grip
        { itemId = 28616, weight = 80 },  -- Fravashi Mantle (Back)
        { itemId = 28517, weight = 80 },  -- Crematio Earring
        { itemId = 28515, weight = 80 },  -- Trux Earring
        { itemId = 28519, weight = 80 },  -- Tripudio Earring
        { itemId = 28516, weight = 80 },  -- Sanare Earring
        { itemId = 28518, weight = 80 },  -- Gelai Earring
    },
    { -- Non-ilvl (level <75): 5 item(s) x weight 180, whiff 100
        quantity = 1,
        { itemId = 0, weight = 100 },
        { itemId = xi.item.SUPPANOMIMI, weight = 180 },
        { itemId = xi.item.KNIGHTS_EARRING, weight = 180 },
        { itemId = xi.item.ABYSSAL_EARRING, weight = 180 },
        { itemId = xi.item.BEASTLY_EARRING, weight = 180 },
        { itemId = xi.item.BUSHINOMIMI, weight = 180 },
    },
}
-- ── Ark Angels (5 distinct pools) ────────────────────────────────────────────
-- G1 = the fight's direct-drop Rem's Tale Chapter (Reforged Armor +1 material);
-- G2 = rare AA weapon/armor pool. Testimonial mats (Maliyakaleya Coral etc.)
-- omitted -- no enum const (modern Escha mats).
fightLoot.ark_angels_1 =
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_6, weight = 70 },
    },
    { -- BiS (ilvl 119): 7 item(s) x weight 50, whiff 650
        quantity = 1,
        { itemId = 0, weight = 650 },
        { itemId = xi.item.CASTIGATION, weight = 50 },
        { itemId = xi.item.ANAHERA_SABER, weight = 50 },
        { itemId = xi.item.LITHELIMB_CAP, weight = 50 },
        { itemId = xi.item.MANABYSS_PIGACHES, weight = 50 },
        { itemId = 20530, weight = 50 },  -- Ohrmazd (Alluvion Skirmish weapon)
        { itemId = 20616, weight = 50 },  -- Ipetam (Alluvion Skirmish weapon)
        { itemId = 20759, weight = 50 },  -- Macbain (Alluvion Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.BLOODRAIN_STRAP, weight = 80 },
    },
}
fightLoot.ark_angels_2 =
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_10, weight = 70 },
    },
    { -- BiS (ilvl 119): 7 item(s) x weight 50, whiff 650
        quantity = 1,
        { itemId = 0, weight = 650 },
        { itemId = xi.item.ANAHERA_SCYTHE, weight = 50 },
        { itemId = xi.item.VENABULUM, weight = 50 },
        { itemId = xi.item.THEURGISTS_SLACKS, weight = 50 },
        { itemId = xi.item.SCAMPS_SOLLERETS, weight = 50 },
        { itemId = 20901, weight = 50 },  -- Inanna (Alluvion Skirmish weapon)
        { itemId = 20809, weight = 50 },  -- Kumbhakarna (Alluvion Skirmish weapon)
        { itemId = 20857, weight = 50 },  -- Svarga (Alluvion Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.FRAVASHI_MANTLE, weight = 80 },
    },
}
fightLoot.ark_angels_3 =
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_8, weight = 70 },
    },
    { -- BiS (ilvl 119): 7 item(s) x weight 50, whiff 650
        quantity = 1,
        { itemId = 0, weight = 650 },
        { itemId = xi.item.RAIMITSUKANE, weight = 50 },
        { itemId = xi.item.ANAHERA_TABAR, weight = 50 },
        { itemId = xi.item.REGIMEN_MITTENS, weight = 50 },
        { itemId = xi.item.FELISTRIS_MASK, weight = 50 },
        { itemId = 20718, weight = 50 },  -- Claidheamh Soluis (Alluvion Skirmish weapon)
        { itemId = 21169, weight = 50 },  -- Keraunos (Alluvion Skirmish weapon)
        { itemId = 21105, weight = 50 },  -- Nehushtan (Alluvion Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.SEKHMET_CORSET, weight = 80 },
    },
}
fightLoot.ark_angels_4 =
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_7, weight = 70 },
    },
    { -- BiS (ilvl 119): 7 item(s) x weight 50, whiff 650
        quantity = 1,
        { itemId = 0, weight = 650 },
        { itemId = xi.item.ANAHERA_SWORD, weight = 50 },
        { itemId = xi.item.CAGLIOSTROS_ROD, weight = 50 },
        { itemId = xi.item.OSMIUM_CUISSES, weight = 50 },
        { itemId = xi.item.DYNASTY_MITTS, weight = 50 },
        { itemId = 20946, weight = 50 },  -- Olyndicus (Alluvion Skirmish weapon)
        { itemId = 21224, weight = 50 },  -- Phaosphaelia (Alluvion Skirmish weapon)
        { itemId = 21476, weight = 50 },  -- Doomsday (Alluvion Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 1 item(s) x weight 80, whiff 920
        quantity = 1,
        { itemId = 0, weight = 920 },
        { itemId = xi.item.PATRICIUS_RING, weight = 80 },
    },
}
fightLoot.ark_angels_5 =
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_9, weight = 70 },
    },
    { -- BiS (ilvl 119): 7 item(s) x weight 50, whiff 650
        quantity = 1,
        { itemId = 0, weight = 650 },
        { itemId = xi.item.TUNGLMYRKVI, weight = 50 },
        { itemId = xi.item.ANAHERA_BLADE, weight = 50 },
        { itemId = xi.item.LURID_MITTS, weight = 50 },
        { itemId = xi.item.DAIHANSHI_HABAKI, weight = 50 },
        { itemId = 21037, weight = 50 },  -- Nenekirimaru (Alluvion Skirmish weapon)
        { itemId = 20989, weight = 50 },  -- Izuna (Alluvion Skirmish weapon)
        { itemId = 27627, weight = 50 },  -- Svalinn (Alluvion Skirmish weapon)
    },
    { -- Non-ilvl (level 95-99): 2 item(s) x weight 80, whiff 840
        quantity = 1,
        { itemId = 0, weight = 840 },
        { itemId = xi.item.AGITATORS_COLLAR, weight = 80 },
        { itemId = 21404, weight = 80 },  -- Linos (Alluvion Skirmish weapon)
    },
}
return fightLoot
