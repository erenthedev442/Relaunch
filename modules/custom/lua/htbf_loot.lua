-----------------------------------
-- htbf_loot.lua  -- retail-sourced armoury-crate loot per HTBF fight (relaunch)
--
-- One table per fightKey (consumed as catalog.fightLoot[fightKey] -> content.loot),
-- applied to ALL tiers of that fight: retail loot is per-fight; the I/II/III tiers
-- differ in difficulty + Hunt Marks, not drop pool.
--
-- Format = utils.selectFromLootGroups: an array of GROUPS; each group an array of
-- { itemId = xi.item.X, weight = N, amount = M? } (+ optional group `quantity`,
-- default 1). Within a group one entry is rolled, weighted by `weight`. itemId 0
-- is a "drop nothing" slot (NEVER nil -- the engine logs an error on a nil id).
--
-- ECONOMY-CONSCIOUS (these battlefields are REPEATABLE + the server runs an AH
-- market-maker): GROUP 1 is a reliable common material/currency reward; the rare
-- GEAR sits in a whiff-heavy GROUP 2 (the 0-slot dominant at ~850) so valuable
-- items stay genuinely rare per clear. Tune any single fight here in isolation.
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
    {
        quantity = 1,
        { itemId = 0,                 weight = 850 },
        { itemId = xi.item.FIRE_BELT, weight = 20 },
        { itemId = xi.item.FIRE_RING, weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 21132, weight = 15 },  -- Aedold (Skirmish weapon)
        { itemId = 21126, weight = 9 },  -- Aedold +1 (Skirmish weapon)
        { itemId = 21115, weight = 5 },  -- Aedold +2 (Skirmish weapon)
        { itemId = 21242, weight = 15 },  -- Bocluamni (Skirmish weapon)
        { itemId = 21236, weight = 9 },  -- Bocluamni +1 (Skirmish weapon)
        { itemId = 21230, weight = 5 },  -- Bocluamni +2 (Skirmish weapon)
        { itemId = 20787, weight = 15 },  -- Crobaci (Skirmish weapon)
        { itemId = 20775, weight = 9 },  -- Crobaci +1 (Skirmish weapon)
        { itemId = 20764, weight = 5 },  -- Crobaci +2 (Skirmish weapon)
    },
}

fightLoot.trial_by_ice =
{
    {
        { itemId = xi.item.ICE_CRYSTAL, weight = 65, amount = 6 },
        { itemId = xi.item.ICE_CLUSTER, weight = 30 },
        { itemId = xi.item.FLOESTONE,   weight = 25 },
    },
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.CALVED_CLAWS,    weight = 20 },
        { itemId = xi.item.FRAZIL_STAFF,    weight = 20 },
        { itemId = xi.item.RIMEICE_EARRING, weight = 18 },
        { itemId = xi.item.NILAS_GLOVES,    weight = 18 },
        { itemId = xi.item.ICE_BELT,        weight = 15 },
        { itemId = xi.item.ICE_RING,        weight = 15 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20833, weight = 15 },  -- Faizzeer (Skirmish weapon)
        { itemId = 20824, weight = 9 },  -- Faizzeer +1 (Skirmish weapon)
        { itemId = 20816, weight = 5 },  -- Faizzeer +2 (Skirmish weapon)
        { itemId = 21294, weight = 15 },  -- Hgafircian (Skirmish weapon)
        { itemId = 21286, weight = 9 },  -- Hgafircian +1 (Skirmish weapon)
        { itemId = 21279, weight = 5 },  -- Hgafircian +2 (Skirmish weapon)
    },
}

fightLoot.trial_by_wind =
{
    {
        { itemId = xi.item.WIND_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.WIND_CLUSTER, weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                 weight = 850 },
        { itemId = xi.item.WIND_BELT, weight = 20 },
        { itemId = xi.item.WIND_RING, weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20877, weight = 15 },  -- Iclamar (Skirmish weapon)
        { itemId = 20870, weight = 9 },  -- Iclamar +1 (Skirmish weapon)
        { itemId = 20863, weight = 5 },  -- Iclamar +2 (Skirmish weapon)
        { itemId = 20924, weight = 15 },  -- Iizamal (Skirmish weapon)
        { itemId = 20915, weight = 9 },  -- Iizamal +1 (Skirmish weapon)
        { itemId = 20907, weight = 5 },  -- Iizamal +2 (Skirmish weapon)
        { itemId = 20742, weight = 15 },  -- Iztaasu (Skirmish weapon)
        { itemId = 20736, weight = 9 },  -- Iztaasu +1 (Skirmish weapon)
        { itemId = 20725, weight = 5 },  -- Iztaasu +2 (Skirmish weapon)
    },
}

fightLoot.trial_by_earth =
{
    {
        { itemId = xi.item.EARTH_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.EARTH_CLUSTER, weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                  weight = 850 },
        { itemId = xi.item.EARTH_BELT, weight = 20 },
        { itemId = xi.item.EARTH_RING, weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 21013, weight = 15 },  -- Kannakiri (Skirmish weapon)
        { itemId = 21004, weight = 9 },  -- Kannakiri +1 (Skirmish weapon)
        { itemId = 20996, weight = 5 },  -- Kannakiri +2 (Skirmish weapon)
        { itemId = 21208, weight = 15 },  -- Lehbrailg (Skirmish weapon)
        { itemId = 21194, weight = 9 },  -- Lehbrailg +1 (Skirmish weapon)
        { itemId = 21179, weight = 5 },  -- Lehbrailg +2 (Skirmish weapon)
    },
}

fightLoot.trial_by_lightning =
{
    {
        { itemId = xi.item.LIGHTNING_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.LIGHTNING_CLUSTER, weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                      weight = 850 },
        { itemId = xi.item.LIGHTNING_BELT, weight = 20 },
        { itemId = xi.item.LIGHTNING_RING, weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20641, weight = 15 },  -- Leisilonu (Skirmish weapon)
        { itemId = 20634, weight = 9 },  -- Leisilonu +1 (Skirmish weapon)
        { itemId = 20623, weight = 5 },  -- Leisilonu +2 (Skirmish weapon)
        { itemId = 20553, weight = 15 },  -- Ninzas (Skirmish weapon)
        { itemId = 20546, weight = 9 },  -- Ninzas +1 (Skirmish weapon)
        { itemId = 20539, weight = 5 },  -- Ninzas +2 (Skirmish weapon)
        { itemId = 20967, weight = 15 },  -- Qatsunoci (Skirmish weapon)
        { itemId = 20961, weight = 9 },  -- Qatsunoci +1 (Skirmish weapon)
        { itemId = 20952, weight = 5 },  -- Qatsunoci +2 (Skirmish weapon)
    },
}

fightLoot.trial_by_water =
{
    {
        { itemId = xi.item.WATER_CRYSTAL, weight = 70, amount = 6 },
        { itemId = xi.item.WATER_CLUSTER, weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.NERITIC_EARRING, weight = 18 },
        { itemId = xi.item.WATER_BELT,      weight = 20 },
        { itemId = xi.item.WATER_RING,      weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 21058, weight = 15 },  -- Shichishito (Skirmish weapon)
        { itemId = 21051, weight = 9 },  -- Shichishito +1 (Skirmish weapon)
        { itemId = 21043, weight = 5 },  -- Shichishito +2 (Skirmish weapon)
        { itemId = 21209, weight = 15 },  -- Uffrat (Skirmish weapon)
        { itemId = 21195, weight = 9 },  -- Uffrat +1 (Skirmish weapon)
        { itemId = 21180, weight = 5 },  -- Uffrat +2 (Skirmish weapon)
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
    {
        quantity = 1,
        { itemId = 0,                             weight = 850 },
        { itemId = xi.item.HEGIRA_WRISTBANDS,     weight =  30 },
        { itemId = xi.item.ISCHEMIA_CHASUBLE,     weight =  30 },
        { itemId = xi.item.SCUFFLERS_COSCIALES,   weight =  30 },
        { itemId = xi.item.METALSINGER_BELT,      weight =  25 },
        { itemId = xi.item.DOMESTICATORS_EARRING, weight =  20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 27768, weight = 15 },  -- Cizin Helm (Skirmish armor)
        { itemId = 27728, weight = 10 },  -- Cizin Helm +1 (Skirmish armor)
        { itemId = 27912, weight = 15 },  -- Cizin Mail (Skirmish armor)
        { itemId = 27874, weight = 10 },  -- Cizin Mail +1 (Skirmish armor)
        { itemId = 28018, weight = 10 },  -- Cizin Mufflers +1 (Skirmish armor)
        -- The Wyrm God sprinkle (that HTBF is unimplemented; its retail loot
        -- lives here instead -- owner 2026-07-13). Crepuscular weapons.
        { itemId = 21585, weight = 14 },  -- Crepuscular Knife (Dagger)
        { itemId = 22300, weight = 14 },  -- Crepuscular Pebble (Ammo)
        { itemId = 18566, weight = 14 },  -- Crepuscular Scythe (Scythe)
    },
}

fightLoot.warriors_path =
{
    {
        { itemId = xi.item.PLATINUM_INGOT, weight = 100 },
        { itemId = xi.item.GOLD_INGOT,     weight =  60 },
        { itemId = xi.item.DAMASCUS_INGOT, weight =  25 },
    },
    {
        quantity = 1,
        { itemId = 0,                              weight = 850 },
        { itemId = xi.item.GINSEN,                 weight =  30 },
        { itemId = xi.item.HANGAKU_NO_YUMI,        weight =  25 },
        { itemId = xi.item.SUKEROKU_HACHIMAKI,     weight =  30 },
        { itemId = xi.item.BATTLECAST_GAITERS,     weight =  30 },
        { itemId = xi.item.MIZUKAGE_NO_KUBIKAZARI, weight =  20 },
        { itemId = xi.item.SERAPHICALLER,          weight =  15 },
        { itemId = xi.item.DIVINATOR,              weight =  15 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 28192, weight = 15 },  -- Cizin Breeches (Skirmish armor)
        { itemId = 28160, weight = 10 },  -- Cizin Breeches +1 (Skirmish armor)
        { itemId = 28332, weight = 15 },  -- Cizin Greaves (Skirmish armor)
        { itemId = 28297, weight = 10 },  -- Cizin Greaves +1 (Skirmish armor)
        { itemId = 28662, weight = 15 },  -- Beatific Shield (Skirmish armor)
        { itemId = 28654, weight = 10 },  -- Beatific Shield +1 (Skirmish armor)
    },
}

fightLoot.one_to_be_feared =
{
    {
        { itemId = xi.item.ORICHALCUM_INGOT, weight =  90 },
        { itemId = xi.item.PLATINUM_INGOT,   weight =  60 },
        { itemId = xi.item.DAMASCUS_INGOT,   weight =  25 },
    },
    {
        quantity = 1,
        { itemId = 0,                           weight = 850 },
        { itemId = xi.item.DENOUEMENTS,         weight =  25 },
        { itemId = xi.item.CULMINUS,            weight =  25 },
        { itemId = xi.item.TERMINAL_HELM,       weight =  30 },
        { itemId = xi.item.TERMINAL_PLATE,      weight =  30 },
        { itemId = xi.item.CESSANCE_EARRING,    weight =  20 },
        { itemId = xi.item.CONSUMMATION_TORQUE, weight =  20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 27729, weight = 10 },  -- Otronif Mask +1 (Skirmish armor)
        { itemId = 27875, weight = 10 },  -- Otronif Harness +1 (Skirmish armor)
        { itemId = 28019, weight = 10 },  -- Otronif Gloves +1 (Skirmish armor)
        { itemId = 28161, weight = 10 },  -- Otronif Brais +1 (Skirmish armor)
        { itemId = 28298, weight = 10 },  -- Otronif Boots +1 (Skirmish armor)
        -- The Wyrm God sprinkle (unimplemented HTBF; owner 2026-07-13).
        -- Crepuscular accessories.
        { itemId = 26220, weight = 15 },  -- Crepuscular Ring
        { itemId = 26117, weight = 15 },  -- Crepuscular Earring
    },
}

fightLoot.head_wind =
{
    {
        { itemId = xi.item.GOLD_INGOT,     weight = 120 },
        { itemId = xi.item.PLATINUM_INGOT, weight =  50 },
        { itemId = xi.item.DAMASCUS_INGOT, weight =  20 },
    },
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.NILGAL_POLE,     weight =  25 },
        { itemId = xi.item.CHIDORI,         weight =  25 },
        { itemId = xi.item.SHETAL_STONE,    weight =  30 },
        { itemId = xi.item.BAGHERE_SALADE,  weight =  30 },
        { itemId = xi.item.DURGAI_LEGGINGS, weight =  30 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 27730, weight = 10 },  -- Iuitl Headgear +1 (Skirmish armor)
        { itemId = 27876, weight = 10 },  -- Iuitl Vest +1 (Skirmish armor)
        { itemId = 28020, weight = 10 },  -- Iuitl Wristbands +1 (Skirmish armor)
        { itemId = 28162, weight = 10 },  -- Iuitl Tights +1 (Skirmish armor)
        { itemId = 28299, weight = 10 },  -- Iuitl Gaiters +1 (Skirmish armor)
        -- The Wyrm God sprinkle (unimplemented HTBF; owner 2026-07-13).
        -- Crepuscular armor set (head/body/back).
        { itemId = 23797, weight = 14 },  -- Crepuscular Helm (Head)
        { itemId = 23798, weight = 14 },  -- Crepuscular Mail (Body)
        { itemId = 23799, weight = 14 },  -- Crepuscular Cloak (Back)
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
    {
        quantity = 1,
        { itemId = 0,     weight = 850 },
        { itemId = 20698, weight = 25 },  -- Fettering Blade (Sword)
        { itemId = 22118, weight = 25 },  -- Venery Bow (Archery)
        { itemId = 25708, weight = 30 },  -- Gyve Doublet (Body)
        { itemId = 27324, weight = 30 },  -- Gyve Trousers (Legs)
        { itemId = 27618, weight = 25 },  -- Laic Mantle (Back)
        { itemId = 26324, weight = 25 },  -- Latria Sash (Waist)
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
    {
        quantity = 1,
        { itemId = 0,                               weight = 850 },
        { itemId = xi.item.HIGH_QUALITY_AERN_ORGAN, weight = 40 },
        { itemId = xi.item.DAMASCUS_INGOT,          weight = 25 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 27732, weight = 10 },  -- Hagondes Hat +1 (Skirmish armor)
        { itemId = 27878, weight = 10 },  -- Hagondes Coat +1 (Skirmish armor)
        { itemId = 28022, weight = 10 },  -- Hagondes Cuffs +1 (Skirmish armor)
        { itemId = 28164, weight = 10 },  -- Hagondes Pants +1 (Skirmish armor)
        { itemId = 28301, weight = 10 },  -- Hagondes Sabots +1 (Skirmish armor)
    },
}

fightLoot.legacy_of_the_lost =
{
    {
        { itemId = xi.item.IMPERIAL_GOLD_PIECE,    weight = 80 },
        { itemId = xi.item.ONE_BYNE_BILL,          weight = 70 },
        { itemId = xi.item.IMPERIAL_MYTHRIL_PIECE, weight = 40 },
    },
    {
        quantity = 1,
        { itemId = 0,                                 weight = 850 },
        { itemId = xi.item.HIGH_QUALITY_EUVHI_ORGAN,  weight = 35 },
        { itemId = xi.item.HIGH_QUALITY_PHUABO_ORGAN, weight = 35 },
        { itemId = xi.item.DAMASCUS_INGOT,            weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 27731, weight = 10 },  -- Gendewitha Caubeen +1 (Skirmish armor)
        { itemId = 27877, weight = 10 },  -- Gendewitha Bliaut +1 (Skirmish armor)
        { itemId = 28021, weight = 10 },  -- Gendewitha Gages +1 (Skirmish armor)
        { itemId = 28163, weight = 10 },  -- Gendewitha Spats +1 (Skirmish armor)
        { itemId = 28300, weight = 10 },  -- Gendewitha Galoshes +1 (Skirmish armor)
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
    {
        quantity = 1,
        { itemId = 0,                          weight = 850 },
        { itemId = xi.item.DAMASCUS_INGOT,     weight = 30 },
        { itemId = xi.item.PHILOSOPHERS_STONE, weight = 25 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 26733, weight = 12 },  -- Yorium Barbuta (Alluvion Skirmish armor)
        { itemId = 26891, weight = 12 },  -- Yorium Cuirass (Alluvion Skirmish armor)
        { itemId = 27045, weight = 12 },  -- Yorium Gauntlets (Alluvion Skirmish armor)
        { itemId = 27232, weight = 12 },  -- Yorium Cuisses (Alluvion Skirmish armor)
        { itemId = 27402, weight = 12 },  -- Yorium Sabatons (Alluvion Skirmish armor)
        -- Maiden of the Dusk sprinkle (unimplemented HTBF; owner 2026-07-13).
        -- Malignance melee/tank pieces + the tank Sword.
        { itemId = 23735, weight = 14 },  -- Malignance Tights (Legs)
        { itemId = 23736, weight = 14 },  -- Malignance Boots (Feet)
        { itemId = 21635, weight = 14 },  -- Malignance Sword
    },
}

fightLoot.stellar_fulcrum =
{
    {
        { itemId = xi.item.GOLD_INGOT,      weight = 90 },
        { itemId = xi.item.DARKSTEEL_INGOT, weight = 70 },
        { itemId = xi.item.BEHEMOTH_HIDE,   weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                        weight = 850 },
        { itemId = xi.item.ORICHALCUM_INGOT, weight = 30 },
        { itemId = xi.item.DRAGON_TALON,     weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 26737, weight = 12 },  -- Helios Band (Alluvion Skirmish armor)
        { itemId = 26895, weight = 12 },  -- Helios Jacket (Alluvion Skirmish armor)
        { itemId = 27049, weight = 12 },  -- Helios Gloves (Alluvion Skirmish armor)
        { itemId = 27236, weight = 12 },  -- Helios Spats (Alluvion Skirmish armor)
        { itemId = 27406, weight = 12 },  -- Helios Boots (Alluvion Skirmish armor)
    },
}

fightLoot.celestial_nexus =
{
    {
        { itemId = xi.item.PLATINUM_INGOT,   weight = 90 },
        { itemId = xi.item.ORICHALCUM_INGOT, weight = 50 },
        { itemId = xi.item.BEHEMOTH_HIDE,    weight = 30 },
    },
    {
        quantity = 1,
        { itemId = 0,                      weight = 880 },
        { itemId = xi.item.DRAGON_HEART,   weight = 25 },
        { itemId = xi.item.DAMASCUS_INGOT, weight = 20 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 26736, weight = 12 },  -- Telchine Cap (Alluvion Skirmish armor)
        { itemId = 26894, weight = 12 },  -- Telchine Chasuble (Alluvion Skirmish armor)
        { itemId = 27048, weight = 12 },  -- Telchine Gloves (Alluvion Skirmish armor)
        { itemId = 27235, weight = 12 },  -- Telchine Braconi (Alluvion Skirmish armor)
        { itemId = 27405, weight = 12 },  -- Telchine Pigaches (Alluvion Skirmish armor)
        -- Maiden of the Dusk sprinkle (that HTBF is unimplemented; its retail
        -- loot lives here instead -- owner 2026-07-13). Caster-leaning pieces.
        { itemId = 22040, weight = 15 },  -- Daybreak (healer Club)
        { itemId = 22087, weight = 15 },  -- Malignance Pole (Staff)
        { itemId = 26088, weight = 15 },  -- Malignance Earring
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
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.SUPPANOMIMI,     weight = 14 },
        { itemId = xi.item.KNIGHTS_EARRING, weight = 14 },
        { itemId = xi.item.ABYSSAL_EARRING, weight = 14 },
        { itemId = xi.item.BEASTLY_EARRING, weight = 14 },
        { itemId = xi.item.BUSHINOMIMI,     weight = 14 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 26734, weight = 12 },  -- Acro Helm (Alluvion Skirmish armor)
        { itemId = 26892, weight = 12 },  -- Acro Surcoat (Alluvion Skirmish armor)
        { itemId = 27046, weight = 12 },  -- Acro Gauntlets (Alluvion Skirmish armor)
        { itemId = 27233, weight = 12 },  -- Acro Breeches (Alluvion Skirmish armor)
        { itemId = 27403, weight = 12 },  -- Acro Leggings (Alluvion Skirmish armor)
        { itemId = 26735, weight = 12 },  -- Taeon Chapeau (Alluvion Skirmish armor)
        { itemId = 26893, weight = 12 },  -- Taeon Tabard (Alluvion Skirmish armor)
        { itemId = 27047, weight = 12 },  -- Taeon Gloves (Alluvion Skirmish armor)
        { itemId = 27234, weight = 12 },  -- Taeon Tights (Alluvion Skirmish armor)
        { itemId = 27404, weight = 12 },  -- Taeon Boots (Alluvion Skirmish armor)
        -- Maiden of the Dusk sprinkle (unimplemented HTBF; owner 2026-07-13).
        -- The mage half of the Malignance armor set.
        { itemId = 23732, weight = 14 },  -- Malignance Chapeau (Head)
        { itemId = 23733, weight = 14 },  -- Malignance Tabard (Body)
        { itemId = 23734, weight = 14 },  -- Malignance Gloves (Hands)
    },
}

-- ── Ark Angels (5 distinct pools) ────────────────────────────────────────────
-- G1 = the fight's direct-drop Rem's Tale Chapter (Reforged Armor +1 material);
-- G2 = rare AA weapon/armor pool. Testimonial mats (Maliyakaleya Coral etc.)
-- omitted -- no enum const (modern Escha mats).
fightLoot.ark_angels_1 =  -- Ark Angel HM
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_6, weight = 70 },
    },
    {
        quantity = 1,
        { itemId = 0,                         weight = 850 },
        { itemId = xi.item.CASTIGATION,       weight = 12 },
        { itemId = xi.item.ANAHERA_SABER,     weight = 18 },
        { itemId = xi.item.LITHELIMB_CAP,     weight = 30 },
        { itemId = xi.item.BLOODRAIN_STRAP,   weight = 30 },
        { itemId = xi.item.MANABYSS_PIGACHES, weight = 30 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20530, weight = 12 },  -- Ohrmazd (Alluvion Skirmish weapon)
        { itemId = 20616, weight = 12 },  -- Ipetam (Alluvion Skirmish weapon)
        { itemId = 20759, weight = 12 },  -- Macbain (Alluvion Skirmish weapon)
    },
}

fightLoot.ark_angels_2 =  -- Ark Angel TT
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_10, weight = 70 },
    },
    {
        quantity = 1,
        { itemId = 0,                         weight = 850 },
        { itemId = xi.item.ANAHERA_SCYTHE,    weight = 18 },
        { itemId = xi.item.VENABULUM,         weight = 12 },
        { itemId = xi.item.THEURGISTS_SLACKS, weight = 30 },
        { itemId = xi.item.SCAMPS_SOLLERETS,  weight = 30 },
        { itemId = xi.item.FRAVASHI_MANTLE,   weight = 25 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20901, weight = 12 },  -- Inanna (Alluvion Skirmish weapon)
        { itemId = 20809, weight = 12 },  -- Kumbhakarna (Alluvion Skirmish weapon)
        { itemId = 20857, weight = 12 },  -- Svarga (Alluvion Skirmish weapon)
    },
}

fightLoot.ark_angels_3 =  -- Ark Angel MR
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_8, weight = 70 },
    },
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.RAIMITSUKANE,    weight = 12 },
        { itemId = xi.item.ANAHERA_TABAR,   weight = 18 },
        { itemId = xi.item.REGIMEN_MITTENS, weight = 30 },
        { itemId = xi.item.FELISTRIS_MASK,  weight = 30 },
        { itemId = xi.item.SEKHMET_CORSET,  weight = 25 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20718, weight = 12 },  -- Claidheamh Soluis (Alluvion Skirmish weapon)
        { itemId = 21169, weight = 12 },  -- Keraunos (Alluvion Skirmish weapon)
        { itemId = 21105, weight = 12 },  -- Nehushtan (Alluvion Skirmish weapon)
    },
}

fightLoot.ark_angels_4 =  -- Ark Angel EV
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_7, weight = 70 },
    },
    {
        quantity = 1,
        { itemId = 0,                       weight = 850 },
        { itemId = xi.item.ANAHERA_SWORD,   weight = 18 },
        { itemId = xi.item.CAGLIOSTROS_ROD, weight = 12 },
        { itemId = xi.item.OSMIUM_CUISSES,  weight = 30 },
        { itemId = xi.item.PATRICIUS_RING,  weight = 25 },
        { itemId = xi.item.DYNASTY_MITTS,   weight = 30 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 20946, weight = 12 },  -- Olyndicus (Alluvion Skirmish weapon)
        { itemId = 21224, weight = 12 },  -- Phaosphaelia (Alluvion Skirmish weapon)
        { itemId = 21476, weight = 12 },  -- Doomsday (Alluvion Skirmish weapon)
    },
}

fightLoot.ark_angels_5 =  -- Ark Angel GK
{
    {
        { itemId = xi.item.COPY_OF_REMS_TALE_CHAPTER_9, weight = 70 },
    },
    {
        quantity = 1,
        { itemId = 0,                        weight = 850 },
        { itemId = xi.item.TUNGLMYRKVI,      weight = 12 },
        { itemId = xi.item.ANAHERA_BLADE,    weight = 18 },
        { itemId = xi.item.AGITATORS_COLLAR, weight = 25 },
        { itemId = xi.item.LURID_MITTS,      weight = 30 },
        { itemId = xi.item.DAIHANSHI_HABAKI, weight = 30 },
        -- Skirmish sprinkle (BG-wiki categories, owner 2026-07-12):
        { itemId = 21037, weight = 12 },  -- Nenekirimaru (Alluvion Skirmish weapon)
        { itemId = 20989, weight = 12 },  -- Izuna (Alluvion Skirmish weapon)
        { itemId = 27627, weight = 12 },  -- Svalinn (Alluvion Skirmish weapon)
        { itemId = 21404, weight = 12 },  -- Linos (Alluvion Skirmish weapon)
    },
}

return fightLoot
