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
    },
}

return fightLoot
