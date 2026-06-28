-----------------------------------
-- htbf_catalog.lua
--
-- Data for the custom retail-style High-Tier Mission Battlefields (HTBF) on the
-- relaunch server. Each retail story-boss battlefield gets THREE difficulty tiers
-- (I / II / III), entered by trading a Phantom Gem key item (bought for gil at the
-- HTBF vendor -- see HTBF_Vendor.lua) and picking a tier from the entrance menu.
--
-- The engine needs NO change: each tier is its own Battlefield (unique
-- battlefieldId + a unique `index` on the existing entrance NPC) that REUSES the
-- base fight's boss and scales it per-instance in setupBattlefield (see htbf.lua).
--
-- To add a fight: add an entry here + drop 3 tiny tier files under
-- scripts/battlefields/<Zone>/<key>_ht{1,2,3}.lua (each: return
-- require('modules/custom/lua/htbf').register('<key>', <tier>)).
--
-- TUNE: gem prices, per-tier scaling, and loot all live here.
-----------------------------------
local catalog = {}

-- Gil price per PHANTOM GEM (flat -- retail: one gem enters, tier is chosen at the
-- entrance menu, one gem consumed per attempt regardless of tier). Keyed by the
-- gem key-item id. The HTBF vendor (HTBF_Vendor.lua) sells these for gil.
catalog.gemPrice =
{
    [xi.ki.AVATAR_PHANTOM_GEM]        = 50000,   -- enters any of the 6 Avatar Prime trials
    [xi.ki.SAVAGES_PHANTOM_GEM]       = 100000,  -- The Savage (Monarch Linn)
    [xi.ki.WARRIORS_PATH_PHANTOM_GEM] = 100000,  -- The Warrior's Path (Sealion's Den)
    [xi.ki.FEARED_ONE_PHANTOM_GEM]    = 150000,  -- One to be Feared (Sealion's Den)
    [xi.ki.HEAD_WIND_PHANTOM_GEM]     = 100000,  -- Head Wind (Boneyard Gully)
    [xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM] = 120000, -- Puppet in Peril (Jade Sepulcher)
    [xi.ki.LEGACY_PHANTOM_GEM]        = 120000,  -- Legacy of the Lost (Talacca Cove)
    [xi.ki.SHADOW_LORD_PHANTOM_GEM]   = 150000,  -- Shadow Lord (Throne Room)
    [xi.ki.STELLAR_FULCRUM_PHANTOM_GEM] = 150000, -- Return to Delkfutt's Tower (Stellar Fulcrum)
    [xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM] = 200000, -- The Celestial Nexus
    [xi.ki.DIVINE_PHANTOM_GEM]        = 200000,  -- Divine Might (La'Loff Amphitheater)
    [xi.ki.PHANTOM_GEM_OF_APATHY]     = 150000,  -- Ark Angel battle 1 (La'Loff)
    [xi.ki.PHANTOM_GEM_OF_COWARDICE]  = 150000,  -- Ark Angel battle 2
    [xi.ki.PHANTOM_GEM_OF_ENVY]       = 150000,  -- Ark Angel battle 3
    [xi.ki.PHANTOM_GEM_OF_ARROGANCE]  = 150000,  -- Ark Angel battle 4
    [xi.ki.PHANTOM_GEM_OF_RAGE]       = 150000,  -- Ark Angel battle 5
}

-- Display names for the gems the vendor sells (key item ids have no server-side
-- name lookup; the client shows the real KI name in the inventory).
catalog.gemName =
{
    [xi.ki.AVATAR_PHANTOM_GEM]        = 'Avatar Phantom Gem',
    [xi.ki.SAVAGES_PHANTOM_GEM]       = "Savage's Phantom Gem",
    [xi.ki.WARRIORS_PATH_PHANTOM_GEM] = "Warrior's Path Phantom Gem",
    [xi.ki.FEARED_ONE_PHANTOM_GEM]    = 'Feared One Phantom Gem',
    [xi.ki.HEAD_WIND_PHANTOM_GEM]     = 'Head Wind Phantom Gem',
    [xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM] = 'Puppet in Peril Phantom Gem',
    [xi.ki.LEGACY_PHANTOM_GEM]        = 'Legacy Phantom Gem',
    [xi.ki.SHADOW_LORD_PHANTOM_GEM]   = 'Shadow Lord Phantom Gem',
    [xi.ki.STELLAR_FULCRUM_PHANTOM_GEM] = 'Stellar Fulcrum Phantom Gem',
    [xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM] = 'Celestial Nexus Phantom Gem',
    [xi.ki.DIVINE_PHANTOM_GEM]        = 'Divine Phantom Gem',
    [xi.ki.PHANTOM_GEM_OF_APATHY]     = 'Phantom Gem of Apathy',
    [xi.ki.PHANTOM_GEM_OF_COWARDICE]  = 'Phantom Gem of Cowardice',
    [xi.ki.PHANTOM_GEM_OF_ENVY]       = 'Phantom Gem of Envy',
    [xi.ki.PHANTOM_GEM_OF_ARROGANCE]  = 'Phantom Gem of Arrogance',
    [xi.ki.PHANTOM_GEM_OF_RAGE]       = 'Phantom Gem of Rage',
}

-- The vendor groups gems by expansion so each customMenu stays under BOTH client
-- caps (max 8 options + 150-byte title+labels). A flat 16-gem list would hide
-- half the gems (incl. the headline Avatar gem) and blow the byte cap. Ordered.
catalog.gemCategories =
{
    { label = 'Avatar Prime Trials',     gems = { xi.ki.AVATAR_PHANTOM_GEM } },
    { label = 'Chains of Promathia',     gems = { xi.ki.SAVAGES_PHANTOM_GEM, xi.ki.WARRIORS_PATH_PHANTOM_GEM, xi.ki.FEARED_ONE_PHANTOM_GEM, xi.ki.HEAD_WIND_PHANTOM_GEM } },
    { label = 'Treasures of Aht Urhgan', gems = { xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM, xi.ki.LEGACY_PHANTOM_GEM } },
    { label = 'Rise of the Zilart',      gems = { xi.ki.SHADOW_LORD_PHANTOM_GEM, xi.ki.STELLAR_FULCRUM_PHANTOM_GEM, xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM, xi.ki.DIVINE_PHANTOM_GEM } },
    { label = 'Ark Angels',              gems = { xi.ki.PHANTOM_GEM_OF_APATHY, xi.ki.PHANTOM_GEM_OF_COWARDICE, xi.ki.PHANTOM_GEM_OF_ENVY, xi.ki.PHANTOM_GEM_OF_ARROGANCE, xi.ki.PHANTOM_GEM_OF_RAGE } },
}

-- Per-tier scaling applied to the reused base boss(es) (silent difficulty -- no
-- player-visible multiplier). lvl/hp are multipliers; att/def/macc/meva are flat
-- mod adds layered on top. Tier I ~ a slightly-buffed base; III is the wall.
-- Keep mob mods < 31k (int16); HP is int32 so the big lever is hp.
catalog.tierScale =
{
    [1] = { name = 'I',   lvl = 1.00, hp = 1.5,  att = 1000,  def = 600,  macc = 200, meva = 200 },
    [2] = { name = 'II',  lvl = 1.10, hp = 4.0,  att = 2500,  def = 1400, macc = 500, meva = 500 },
    [3] = { name = 'III', lvl = 1.20, hp = 10.0, att = 4500,  def = 2400, macc = 900, meva = 900 },
}

-- Reward: gil + Hunt Marks per tier on a win (placeholder economy hook; the real
-- retail per-fight LOOT tables get added to each fight's `loot` field as they are
-- sourced from bg-wiki). selectFromLootGroups armoury-crate loot can also be set
-- per fight via entry.loot[tier].
catalog.tierReward =
{
    [1] = { gil = 30000,  marks = 50 },
    [2] = { gil = 120000, marks = 200 },
    [3] = { gil = 400000, marks = 600 },
}

-- Default armoury-crate loot (the chest that spawns on a win). Override per fight
-- with catalog.fights[key].loot[tier] for retail-exact drops. Deliberately MODEST
-- -- tier-scaled crafting spoils, NO gear/relics -- because these battlefields are
-- REPEATABLE and dumping retail gear here would flood the AH economy; the gil +
-- Hunt Marks reward is the real payout. Each tier rolls 1 material (quantity 1),
-- value scaling I -> III. Raw weights used directly (xi.loot.weight enum values
-- 140/100/70/50/30/10/2) so the catalog carries no module load-order dependency;
-- itemId 0 = a "drop nothing" slot (a nil id would spam the error log -- never nil).
catalog.tierLoot =
{
    [1] =
    {
        {
            { itemId = xi.item.GOLD_INGOT,         weight = 140 },
            { itemId = xi.item.PHILOSOPHERS_STONE, weight =  50 },
            { itemId = xi.item.DAMASCUS_INGOT,     weight =  30 },
        },
    },
    [2] =
    {
        {
            { itemId = xi.item.PLATINUM_INGOT,     weight = 100 },
            { itemId = xi.item.DAMASCUS_INGOT,     weight =  50 },
            { itemId = xi.item.BEITETSU,           weight =  20 },
        },
    },
    [3] =
    {
        {
            { itemId = xi.item.ORICHALCUM_INGOT,   weight =  90 },
            { itemId = xi.item.BEITETSU,           weight =  50 },
            { itemId = xi.item.RIFTBORN_BOULDER,   weight =  30 },
        },
    },
}

-- Per-fight RETAIL armoury-crate loot (bg-wiki-sourced, all ids verified). Keyed
-- by fightKey; applied to every tier of that fight. Overrides tierLoot. Lives in
-- its own file (one table per fight) -- tune individual fights there.
catalog.fightLoot = require('modules/custom/lua/htbf_loot')

-- ── Fights ──────────────────────────────────────────────────────────────────
-- key              -> used by the tier files + vendor
-- zone/entryNpc/exitNpc -> the existing burning-circle entrance (battlefield base)
-- gem              -> Phantom Gem key item required to enter (xi.ki.*)
-- baseIndex        -> first free menu index on that entrance NPC (tiers take
--                     baseIndex, +1, +2). MUST not collide with the base fights
--                     already on that NPC.
-- baseBattlefieldId-> first battlefield id for this fight (tiers take +0,+1,+2);
--                     high range (4000+) to avoid the stock id space.
-- mobs             -> the base boss entity name(s) to reuse + scale.
-- The 6 Avatar Prime trials share AVATAR_PHANTOM_GEM (retail). Indices 0/1/2 on
-- each Cloister FP/IP/etc. entrance are taken by base/trial-size/waking -> tiers
-- start at 3.
catalog.fights =
{
    -- The 6 Avatar Prime trials. All share AVATAR_PHANTOM_GEM (retail: one gem
    -- enters any trial). baseIndex = first FREE menu slot on that Cloister's
    -- entrance (audited: each Cloister uses 0..3 or 0..4 for base/trial-size/
    -- waking/sugar-coated/carbuncle/class-reunion/puppet). 30-min, 6-player.
    trial_by_fire =
    {
        zone = xi.zone.CLOISTER_OF_FLAMES,  entryNpc = 'FP_Entrance', exitNpc = 'Fire_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 4, baseBattlefieldId = 4000,
        mobs = { 'Ifrit_Prime_TBF' }, label = 'Trial by Fire',
    },
    trial_by_ice =
    {
        zone = xi.zone.CLOISTER_OF_FROST,   entryNpc = 'IP_Entrance', exitNpc = 'Ice_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4010,
        mobs = { 'Shiva_Prime_TBI' }, label = 'Trial by Ice',
    },
    trial_by_wind =
    {
        zone = xi.zone.CLOISTER_OF_GALES,   entryNpc = 'WP_Entrance', exitNpc = 'Wind_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4020,
        mobs = { 'Garuda_Prime_TBW' }, label = 'Trial by Wind',
    },
    trial_by_earth =
    {
        zone = xi.zone.CLOISTER_OF_TREMORS, entryNpc = 'EP_Entrance', exitNpc = 'Earth_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4030,
        mobs = { 'Titan_Prime_TBE' }, label = 'Trial by Earth',
    },
    trial_by_lightning =
    {
        zone = xi.zone.CLOISTER_OF_STORMS,  entryNpc = 'LP_Entrance', exitNpc = 'Lightning_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4040,
        mobs = { 'Ramuh_Prime_TBL' }, label = 'Trial by Lightning',
    },
    trial_by_water =
    {
        zone = xi.zone.CLOISTER_OF_TIDES,   entryNpc = 'WP_Entrance', exitNpc = 'Water_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 4, baseBattlefieldId = 4050,
        mobs = { 'Leviathan_Prime_TBW' }, label = 'Trial by Water',
    },

    -- ── CoP boss battlefields ───────────────────────────────────────────────
    -- Complex multi-group / per-arena-mobId fights: reuse the base fight's full
    -- groups (+ tick/section logic) via reuseBaseId, just re-gated on the fight's
    -- own gem and scaled. baseIndex audited per entrance.
    the_savage =
    {
        zone = xi.zone.MONARCH_LINN, entryNpc = 'SD_Entrance',
        exitNpcs = { 'SD_BCNM_Exit_1', 'SD_BCNM_Exit_2', 'SD_BCNM_Exit_3' },
        gem = xi.ki.SAVAGES_PHANTOM_GEM, baseIndex = 7, baseBattlefieldId = 4060,
        reuseBaseId = xi.battlefield.id.SAVAGE, label = 'The Savage',
    },
    warriors_path =
    {
        zone = xi.zone.SEALIONS_DEN, entryNpc = '_0w0', exitNpc = 'Airship_Door',
        gem = xi.ki.WARRIORS_PATH_PHANTOM_GEM, baseIndex = 2, baseBattlefieldId = 4070,
        reuseBaseId = xi.battlefield.id.WARRIORS_PATH, label = "The Warrior's Path",
    },
    -- One to be Feared shares Sealion's Den entrance _0w0 (base 0/1, Warrior's
    -- Path HTBF 2/3/4) -> this goes at 5/6/7. Event-driven Omega/Ultima phases
    -- ride along via the reused sections + exit hooks. 45-min limit (2700s).
    one_to_be_feared =
    {
        zone = xi.zone.SEALIONS_DEN, entryNpc = '_0w0', exitNpc = 'Airship_Door',
        gem = xi.ki.FEARED_ONE_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4080,
        reuseBaseId = xi.battlefield.id.ONE_TO_BE_FEARED, timeLimit = 2700,
        label = 'One to be Feared',
    },
    head_wind =
    {
        zone = xi.zone.BONEYARD_GULLY, entryNpc = '_081',
        exitNpcs = { '_082', '_084', '_086' },
        gem = xi.ki.HEAD_WIND_PHANTOM_GEM, baseIndex = 7, baseBattlefieldId = 4090,
        reuseBaseId = xi.battlefield.id.HEAD_WIND, label = 'Head Wind',
    },

    -- ── ToAU boss battlefields ──────────────────────────────────────────────
    -- Bases restrict to arena 1; the HTBF uses arenas 2-3 (mobIds for all 3
    -- arenas exist in the base groups) so it never blocks the base mission.
    puppet_in_peril =
    {
        zone = xi.zone.JADE_SEPULCHER, entryNpc = '_1v0',
        exitNpcs = { '_1v1', '_1v2', '_1v3' },
        gem = xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4100,
        reuseBaseId = xi.battlefield.id.PUPPET_IN_PERIL, allowedAreas = { [2] = true, [3] = true },
        label = 'Puppet in Peril',
    },
    legacy_of_the_lost =
    {
        zone = xi.zone.TALACCA_COVE, entryNpc = '_1l0',
        exitNpcs = { '_1l1', '_1l2', '_1l3' },
        gem = xi.ki.LEGACY_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4110,
        reuseBaseId = xi.battlefield.id.LEGACY_OF_THE_LOST, allowedAreas = { [2] = true, [3] = true },
        label = 'Legacy of the Lost',
    },

    -- ── Rise of the Zilart boss battlefields ────────────────────────────────
    shadow_lord =
    {
        zone = xi.zone.THRONE_ROOM, entryNpc = '_4l1',
        exitNpcs = { '_4l2', '_4l3', '_4l4' },
        gem = xi.ki.SHADOW_LORD_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4120,
        reuseBaseId = xi.battlefield.id.SHADOW_LORD_BATTLE, label = 'Shadow Lord',
    },
    stellar_fulcrum =
    {
        zone = xi.zone.STELLAR_FULCRUM, entryNpc = '_4z0',
        exitNpcs = { '_4z1', '_4z2', '_4z3' },
        gem = xi.ki.STELLAR_FULCRUM_PHANTOM_GEM, baseIndex = 1, baseBattlefieldId = 4130,
        reuseBaseId = xi.battlefield.id.RETURN_TO_DELKFUTTS_TOWER, label = "Return to Delkfutt's Tower",
    },
    celestial_nexus =
    {
        zone = xi.zone.THE_CELESTIAL_NEXUS, entryNpc = '_513',
        exitNpcs = { '_514', '_515' },
        gem = xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM, baseIndex = 1, baseBattlefieldId = 4140,
        reuseBaseId = xi.battlefield.id.CELESTIAL_NEXUS, label = 'The Celestial Nexus',
    },
    -- Divine Might: 18-player, multi-entrance (qm1_1..qm1_5). Base uses index 5
    -- across them; HTBF at 13/14/15 (kept above the Ark Angel HTBF range 10-12).
    divine_might =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpcs = { 'qm1_1', 'qm1_2', 'qm1_3', 'qm1_4', 'qm1_5' },
        exitNpc = 'qm2',
        gem = xi.ki.DIVINE_PHANTOM_GEM, baseIndex = 13, baseBattlefieldId = 4150,
        reuseBaseId = xi.battlefield.id.DIVINE_MIGHT, maxPlayers = 18, label = 'Divine Might',
    },

    -- Ark Angels: 5 separate fights, each on its own La'Loff entrance (qm1_1..
    -- qm1_5) with its own gem. Base uses idx 0-4 per entrance (+ Divine Might at
    -- idx 5 / its HTBF at 13-15), so Ark Angel HTBF tiers sit at 10/11/12.
    ark_angels_1 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_1', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_APATHY, baseIndex = 10, baseBattlefieldId = 4160,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_1, label = 'Ark Angels I',
    },
    ark_angels_2 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_2', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_COWARDICE, baseIndex = 10, baseBattlefieldId = 4170,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_2, label = 'Ark Angels II',
    },
    ark_angels_3 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_3', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_ENVY, baseIndex = 10, baseBattlefieldId = 4180,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_3, label = 'Ark Angels III',
    },
    ark_angels_4 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_4', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_ARROGANCE, baseIndex = 10, baseBattlefieldId = 4190,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_4, label = 'Ark Angels IV',
    },
    ark_angels_5 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_5', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_RAGE, baseIndex = 10, baseBattlefieldId = 4200,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_5, label = 'Ark Angels V',
    },
}

return catalog
