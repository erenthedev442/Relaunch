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

-- The persistent progression contract is intentionally defined beside the
-- battlefield data. Every consumer (entry, vendor, and Ambuscade) asks this
-- one API rather than reimplementing combinations of charvars.
catalog.progress =
{
    tierVar       = 'HTBF_Cleared_T',
    finalDoneVar  = 'HTBF_FinalTest_Done',
}

function catalog.progress.get(player)
    local result =
    {
        tier1 = (player:getCharVar(catalog.progress.tierVar .. '1') or 0) >= 1,
        tier2 = (player:getCharVar(catalog.progress.tierVar .. '2') or 0) >= 1,
        tier3 = (player:getCharVar(catalog.progress.tierVar .. '3') or 0) >= 1,
    }
    result.finalProving = (player:getCharVar(catalog.progress.finalDoneVar) or 0) >= 1 or result.tier3
    result.finalReady = result.tier1 and result.tier2 and not result.finalProving
    return result
end

function catalog.progress.recordClear(player, tier, isFinalProving)
    if tier >= 1 and tier <= 3 then
        player:setCharVar(catalog.progress.tierVar .. tier, 1)
    end
    if isFinalProving then
        player:setCharVar(catalog.progress.finalDoneVar, 1)
        player:setCharVar(catalog.progress.tierVar .. '3', 1)
    end
end

-- Real trusts per tier. The Adventuring Fellow is a free extra and is excluded
-- from this count by htbf.lua.
catalog.trustCap = { [1] = 2, [2] = 3, [3] = 4 }
catalog.firstClearMultiplier = 2

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
    [xi.ki.DAWN_PHANTOM_GEM]          = 200000,  -- Dawn (Empyreal Paradox) -- final CoP boss, priciest
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
    [xi.ki.DAWN_PHANTOM_GEM]          = 'Dawn Phantom Gem',
    [xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM] = 'Puppet in Peril Phantom Gem',
    [xi.ki.LEGACY_PHANTOM_GEM]        = 'Legacy Phantom Gem',
    [xi.ki.SHADOW_LORD_PHANTOM_GEM]   = 'Shadow Lord Phantom Gem',
    [xi.ki.STELLAR_FULCRUM_PHANTOM_GEM] = "Return to Delkfutt's Tower Phantom Gem",
    [xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM] = 'Celestial Nexus Phantom Gem',
    [xi.ki.DIVINE_PHANTOM_GEM]        = 'Divine Phantom Gem',
    [xi.ki.PHANTOM_GEM_OF_APATHY]     = 'Phantom Gem of Apathy',
    [xi.ki.PHANTOM_GEM_OF_COWARDICE]  = 'Phantom Gem of Cowardice',
    [xi.ki.PHANTOM_GEM_OF_ENVY]       = 'Phantom Gem of Envy',
    [xi.ki.PHANTOM_GEM_OF_ARROGANCE]  = 'Phantom Gem of Arrogance',
    [xi.ki.PHANTOM_GEM_OF_RAGE]       = 'Phantom Gem of Rage',
}

-- The five Ark Angel gems are bound to five different Shimmering Circles.
-- Surface that mapping at the vendor; otherwise players naturally try every
-- gem at circle I and conclude that Ark Angels II-V do not exist.
catalog.gemUseHint =
{
    [xi.ki.PHANTOM_GEM_OF_APATHY]    = 'Use at Shimmering Circle I.',
    [xi.ki.PHANTOM_GEM_OF_COWARDICE] = 'Use at Shimmering Circle II.',
    [xi.ki.PHANTOM_GEM_OF_ENVY]      = 'Use at Shimmering Circle III.',
    [xi.ki.PHANTOM_GEM_OF_ARROGANCE] = 'Use at Shimmering Circle IV.',
    [xi.ki.PHANTOM_GEM_OF_RAGE]      = 'Use at Shimmering Circle V.',
}

-- The vendor groups fights by expansion so each customMenu stays under BOTH
-- client caps (max 8 options + 150-byte title+labels). Fight keys, rather than
-- gem IDs, preserve the selected destination for the six shared Avatar gems.
catalog.gemCategories =
{
    { label = 'Avatar Prime Trials', fightKeys = { 'trial_by_fire', 'trial_by_ice', 'trial_by_wind', 'trial_by_earth', 'trial_by_lightning', 'trial_by_water' } },
    { label = 'Chains of Promathia', fightKeys = { 'the_savage', 'warriors_path', 'one_to_be_feared', 'head_wind', 'dawn' } },
    { label = 'Treasures of Aht Urhgan', fightKeys = { 'puppet_in_peril', 'legacy_of_the_lost' } },
    { label = 'Rise of the Zilart', fightKeys = { 'shadow_lord', 'stellar_fulcrum', 'celestial_nexus', 'divine_might' } },
    { label = 'Ark Angels', fightKeys = { 'ark_angels_1', 'ark_angels_2', 'ark_angels_3', 'ark_angels_4', 'ark_angels_5' } },
}

-- WARP DESTINATIONS: the HTBF vendor can warp you straight to any battlefield
-- entrance (owner request 2026-07-12 -- saves the cross-zone trek). Coords are
-- each fight's entrance-NPC position pulled live from npc_list; grouped by the
-- same expansions as the gem menu so it browses the same way. FREE (a QoL warp;
-- you still need the gem + a clear at the entrance). One entry per fight -- some
-- share an entrance (Warrior's Path / One to be Feared) and that's fine.
catalog.warpDestinations =
{
    { label = 'Avatar Prime Trials', dests =
        {
            { fightKey = 'trial_by_fire', name = 'Trial by Fire', zone = 207, x = -722.13, y = -1.40, z = -597.96, rot = 0 },
            { fightKey = 'trial_by_ice', name = 'Trial by Ice', zone = 203, x = 560.01, y = -0.83, z = 600.02, rot = 0 },
            { fightKey = 'trial_by_wind', name = 'Trial by Wind', zone = 201, x = -359.05, y = -0.13, z = -379.98, rot = 0 },
            { fightKey = 'trial_by_earth', name = 'Trial by Earth', zone = 209, x = -539.95, y = 0.46, z = -493.87, rot = 0 },
            { fightKey = 'trial_by_lightning', name = 'Trial by Lightning', zone = 202, x = 535.09, y = -14.93, z = 493.01, rot = 0 },
            { fightKey = 'trial_by_water', name = 'Trial by Water', zone = 211, x = 558.99, y = 35.10, z = 562.96, rot = 0 },
        } },
    { label = 'Chains of Promathia', dests =
        {
            { fightKey = 'the_savage', name = 'The Savage', zone = 31, x = -39.11, y = -3.35, z = -539.99, rot = 0 },
            { fightKey = 'warriors_path', name = "The Warrior's Path", zone = 32, x = 612.00, y = 130.90, z = 770.03, rot = 0 },
            { fightKey = 'one_to_be_feared', name = 'One to be Feared', zone = 32, x = 612.00, y = 130.90, z = 770.03, rot = 0 },
            { fightKey = 'head_wind', name = 'Head Wind', zone = 8, x = -619.42, y = -1.52, z = 505.67, rot = 0 },
            { fightKey = 'dawn', name = 'Dawn', zone = 36, x = 540.04, y = -1.18, z = -597.68, rot = 0 },
        } },
    { label = 'Treasures of Aht Urhgan', dests =
        {
            { fightKey = 'puppet_in_peril', name = 'Puppet in Peril', zone = 67, x = 300.00, y = -2.52, z = -200.00, rot = 0 },
            { fightKey = 'legacy_of_the_lost', name = 'Legacy of the Lost', zone = 57, x = -100.00, y = -9.40, z = -87.00, rot = 0 },
        } },
    { label = 'Rise of the Zilart', dests =
        {
            { fightKey = 'shadow_lord', name = 'Shadow Lord', zone = 165, x = -115.85, y = -8.66, z = 0.00, rot = 0 },
            { fightKey = 'stellar_fulcrum', name = "Return to Delkfutt's Tower", zone = 179, x = -519.99, y = -6.30, z = 22.35, rot = 0 },
            { fightKey = 'celestial_nexus', name = 'The Celestial Nexus', zone = 181, x = -582.07, y = -8.07, z = -32.35, rot = 0 },
            { fightKey = 'divine_might', name = 'Divine Might', zone = 180, x = -605.06, y = -22.68, z = 483.94, rot = 190 },
        } },
    { label = 'Ark Angels', dests =
        {
            { fightKey = 'ark_angels_1', name = 'Ark Angel HM', zone = 180, x = -605.06, y = -22.68, z = 483.94, rot = 190 },
            { fightKey = 'ark_angels_2', name = 'Ark Angel TT', zone = 180, x = -264.78, y = -137.31, z = 374.52, rot = 115 },
            { fightKey = 'ark_angels_3', name = 'Ark Angel MR', zone = 180, x = 14.15, y = -224.33, z = 488.12, rot = 166 },
            { fightKey = 'ark_angels_4', name = 'Ark Angel EV', zone = 180, x = 235.65, y = -173.57, z = 361.27, rot = 217 },
            { fightKey = 'ark_angels_5', name = 'Ark Angel GK', zone = 180, x = 556.00, y = -38.21, z = 520.63, rot = 11 },
        } },
}

catalog.warpByFight = {}
for _, group in ipairs(catalog.warpDestinations) do
    for _, destination in ipairs(group.dests) do
        catalog.warpByFight[destination.fightKey] = destination
    end
end

-- Difficulty profiles preserve each retail fight's mobs, TP moves, phase logic,
-- and scripts. Only ordinary combat stats are adjusted; no drain, regen, or
-- artificial time-extension mechanics are added.
catalog.tierScale =
{
    avatar =
    {
        -- Avatars trade the old 22x-HP wall for a healthier spread of level,
        -- defense, evasion, and magic evasion. They remain retail-style fights.
        [1] = { name = 'I',   lvl = 1.35, hp = 3.5,  att = 1800, def = 1800, macc = 450,  meva = 700,  eva = 500  },
        [2] = { name = 'II',  lvl = 1.65, hp = 8.0,  att = 4000, def = 4200, macc = 1000, meva = 1500, eva = 1100 },
        [3] = { name = 'III', lvl = 2.00, hp = 16.0, att = 7000, def = 7500, macc = 1800, meva = 2600, eva = 1900 },
    },
    standard =
    {
        [1] = { name = 'I',   lvl = 1.25, hp = 3.0,  att = 1800, def = 1500, macc = 400,  meva = 500,  eva = 350  },
        [2] = { name = 'II',  lvl = 1.50, hp = 7.0,  att = 4000, def = 3300, macc = 900,  meva = 1100, eva = 800  },
        [3] = { name = 'III', lvl = 1.75, hp = 15.0, att = 7000, def = 5800, macc = 1700, meva = 2000, eva = 1400 },
    },
    mechanics =
    {
        -- Multi-enemy and event-driven fights get pressure from offense and
        -- defense while their retail mechanics, rather than oversized HP, lead.
        [1] = { name = 'I',   lvl = 1.25, hp = 2.5,  att = 2000, def = 1400, macc = 450,  meva = 450,  eva = 300  },
        [2] = { name = 'II',  lvl = 1.50, hp = 6.0,  att = 4500, def = 3000, macc = 1000, meva = 1000, eva = 700  },
        [3] = { name = 'III', lvl = 1.75, hp = 12.0, att = 8000, def = 5200, macc = 1900, meva = 1800, eva = 1200 },
    },
    epic =
    {
        [1] = { name = 'I',   lvl = 1.25, hp = 3.0,  att = 2200, def = 1700, macc = 500,  meva = 550,  eva = 400  },
        [2] = { name = 'II',  lvl = 1.50, hp = 7.0,  att = 5000, def = 3800, macc = 1100, meva = 1200, eva = 900  },
        [3] = { name = 'III', lvl = 1.75, hp = 14.0, att = 9000, def = 6500, macc = 2100, meva = 2200, eva = 1600 },
    },
}

-- Guaranteed completion rewards. First completion of each individual
-- fight+tier pays 2x gil and marks; item loot is still rolled once.
catalog.tierReward =
{
    simple =
    {
        [1] = { gil = 10000, marks = 10 },
        [2] = { gil = 30000, marks = 25 },
        [3] = { gil = 75000, marks = 60 },
    },
    standard =
    {
        [1] = { gil = 15000,  marks = 20 },
        [2] = { gil = 50000,  marks = 50 },
        [3] = { gil = 100000, marks = 100 },
    },
    epic =
    {
        [1] = { gil = 20000,  marks = 30 },
        [2] = { gil = 75000,  marks = 75 },
        [3] = { gil = 150000, marks = 150 },
    },
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

-- Server-side staging positions for custom battlefield IDs. The six elemental
-- cloisters share the same three arena layouts. These are verified walkable
-- points beside each arena's internal Protocrystal, translated for areas 2/3.
local avatarEntryPos =
{
    [1] = {  497.6078,  55.5905, -434.2727, 154 },
    [2] = {   17.6858,  -4.4115,  -34.3137, 154 },
    [3] = { -382.3442, -64.4185,  445.6693, 154 },
}

-- Titan's verified point is one yalm farther forward than Ifrit's. Preserve
-- that exact safe placement and translate it against Titan's own Protocrystals.
local titanEntryPos =
{
    [1] = {  496.9633,  55.5569, -433.3694, 156 },
    [2] = {   17.0843,  -4.4421,  -33.3584, 156 },
    [3] = { -382.9837, -64.4591,  446.6106, 156 },
}

-- Proven walkable points on each La'Loff arena platform. The previous points
-- extended 30 yalms backward from the bosses and crossed outside the platform,
-- dropping players below the arena.
local laLoffEntryPos =
{
    [1] = {   -7.509,  -19.727,  1.150, 0 },
    [2] = { -556.221, -243.678, 43.545, 0 },
    [3] = {  483.759, -318.678, 66.249, 0 },
}

-- One-time bridge from Tier II into the real Tier III roster. Final Proving
-- reuses Garuda Prime but applies roughly half of the Avatar Tier III scaling.
-- Clearing it sets both completionVar (unlocks every real T3) and tierClearVar
-- (satisfies Ambuscade's existing T3-clear requirement).
catalog.finalTest =
{
    fightKey       = 'trial_by_wind',
    label          = 'Final Proving',
    battlefieldId  = 4220,
    index          = 11,
    completionVar  = 'HTBF_FinalTest_Done',
    tierClearVar   = 'HTBF_Cleared_T3',
    scale          = { name = 'Final', lvl = 1.50, hp = 8.0, att = 3500, def = 3750, macc = 900, meva = 1300, eva = 950 },
    reward         = { gil = 75000, marks = 60 },
    entryPosByArea = avatarEntryPos,
    warp            = { zone = 201, x = -359.05, y = -0.13, z = -379.98, rot = 0 },
}

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
-- The 6 Avatar Prime trials share AVATAR_PHANTOM_GEM (retail). Base fights sit at
-- indices 0..3 on each Cloister entrance; retail also RESERVED slot 4 in the
-- client dialog DAT for an unimplemented HTMBF tier (e.g. Cloister of Flames DAT
-- slot 4 = "Trial by Fire"). A tier landing on slot 4 renders a duplicate-looking
-- row instead of the intended blank ("Which battlefield will you enter?" >
-- Trial by Fire / Waking the Beast / Trial by Fire again). So HTBF tiers start
-- at slot 8 -- well past every retail-defined DAT label -- and rely on the
-- printEntranceLegend chat message (htbf.lua) to name the blank rows.
catalog.fights =
{
    -- The 6 Avatar Prime trials. All share AVATAR_PHANTOM_GEM (retail: one gem
    -- enters any trial). baseIndex = 8 uniformly: retail base fights sit at
    -- indices 0..3 and the DAT has labeled slot 4 as "Trial by [Element]"
    -- (unimplemented HTMBF placeholder), so a tier landing there renders a
    -- duplicate-looking row -- see header. Slot 8 is well past every
    -- retail-defined DAT label on these entrances. 30-min, 6-player.
    trial_by_fire =
    {
        zone = xi.zone.CLOISTER_OF_FLAMES,  entryNpc = 'FP_Entrance', exitNpc = 'Fire_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4000,
        mobs = { 'Ifrit_Prime_TBF' }, label = 'Trial by Fire',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = avatarEntryPos,
    },
    trial_by_ice =
    {
        zone = xi.zone.CLOISTER_OF_FROST,   entryNpc = 'IP_Entrance', exitNpc = 'Ice_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4010,
        mobs = { 'Shiva_Prime_TBI' }, label = 'Trial by Ice',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = avatarEntryPos,
    },
    trial_by_wind =
    {
        zone = xi.zone.CLOISTER_OF_GALES,   entryNpc = 'WP_Entrance', exitNpc = 'Wind_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4020,
        mobs = { 'Garuda_Prime_TBW' }, label = 'Trial by Wind',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = avatarEntryPos,
    },
    trial_by_earth =
    {
        zone = xi.zone.CLOISTER_OF_TREMORS, entryNpc = 'EP_Entrance', exitNpc = 'Earth_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4030,
        mobs = { 'Titan_Prime_TBE' }, label = 'Trial by Earth',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = titanEntryPos,
    },
    trial_by_lightning =
    {
        zone = xi.zone.CLOISTER_OF_STORMS,  entryNpc = 'LP_Entrance', exitNpc = 'Lightning_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4040,
        mobs = { 'Ramuh_Prime_TBL' }, label = 'Trial by Lightning',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = avatarEntryPos,
    },
    trial_by_water =
    {
        zone = xi.zone.CLOISTER_OF_TIDES,   entryNpc = 'WP_Entrance', exitNpc = 'Water_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 8, baseBattlefieldId = 4050,
        mobs = { 'Leviathan_Prime_TBW' }, label = 'Trial by Water',
        difficulty = 'avatar', rewardClass = 'simple', entryPosByArea = avatarEntryPos,
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
        difficulty = 'standard', rewardClass = 'standard',
        entryPosByArea =
        {
            -- Safe staging point beside each arena's Spatial Displacement.
            -- Areas 2/3 are translated copies of the same Monarch Linn arena.
            [1] = { -526.2602,  80.1184, -0.3888, 128 },
            [2] = {   73.7848,   0.5194, -0.3308, 128 },
            [3] = {  673.5318, -79.8806, -0.2078, 128 },
        },
    },
    warriors_path =
    {
        zone = xi.zone.SEALIONS_DEN, entryNpc = '_0w0', exitNpc = 'Airship_Door',
        gem = xi.ki.WARRIORS_PATH_PHANTOM_GEM, baseIndex = 2, baseBattlefieldId = 4070,
        label = "The Warrior's Path",
        difficulty = 'standard', rewardClass = 'standard',
        -- Use the dedicated level-99 HTMBF Tenzen/Chebukki groups rather than
        -- the level-70 story group. Each tier owns a separate set of entities.
        groupsForTier = function(tier)
            local first = 16908322 + (tier - 1) * 12
            return
            {
                {
                    mobIds =
                    {
                        { first },
                        { first + 4 },
                        { first + 8 },
                    },
                    allDeath = function(battlefield)
                        battlefield:setStatus(xi.battlefield.status.WON)
                    end,
                },
                {
                    mobIds =
                    {
                        { first + 1, first + 2, first + 3 },
                        { first + 5, first + 6, first + 7 },
                        { first + 9, first + 10, first + 11 },
                    },
                },
            }
        end,
        entryPosByArea =
        {
            [1] = { -646.335, -231.648,  486.0, 215 },
            [2] = {   -6.354, -151.648,  126.0, 215 },
            [3] = {  633.622,  -71.648, -233.0, 215 },
        },
    },
    -- One to be Feared shares Sealion's Den entrance _0w0 (base 0/1, Warrior's
    -- Path HTBF 2/3/4) -> this goes at 5/6/7. Event-driven Omega/Ultima phases
    -- ride along via the reused sections + exit hooks. 45-min limit (2700s).
    one_to_be_feared =
    {
        zone = xi.zone.SEALIONS_DEN, entryNpc = '_0w0', exitNpc = 'Airship_Door',
        gem = xi.ki.FEARED_ONE_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4080,
        timeLimit = 2700,
        label = 'One to be Feared', difficulty = 'mechanics', rewardClass = 'epic',
        -- Retail HTMBF is Omega -> Ultima only. The mission battlefield also
        -- contains Mammets and story cutscenes, so it must not be reused here.
        groupsForTier = function(tier)
        local first = 16908382 + (tier - 1) * 30
            return
            {
                {
                    mobIds =
                    {
                        { first },
                        { first + 10 },
                        { first + 20 },
                    },
                    allDeath = function(battlefield)
                        local ultimaId = first + 1 + (battlefield:getArea() - 1) * 10
                        SpawnMob(ultimaId)
                    end,
                },
                {
                    mobIds =
                    {
                        { first + 1 },
                        { first + 11 },
                        { first + 21 },
                    },
                    spawned = false,
                    allDeath = function(battlefield)
                        battlefield:setStatus(xi.battlefield.status.WON)
                    end,
                },
            }
        end,
        entryPosByArea =
        {
            [1] = { -643.105, -231.648,  486.0, 192 },
            [2] = {   -3.124, -151.648,  126.0, 192 },
            [3] = {  636.852,  -71.648, -233.0, 192 },
        },
    },
    head_wind =
    {
        zone = xi.zone.BONEYARD_GULLY, entryNpc = '_081',
        exitNpcs = { '_082', '_084', '_086' },
        gem = xi.ki.HEAD_WIND_PHANTOM_GEM, baseIndex = 7, baseBattlefieldId = 4090,
        reuseBaseId = xi.battlefield.id.HEAD_WIND, label = 'Head Wind',
        difficulty = 'mechanics', rewardClass = 'standard',
        entryPosByArea =
        {
            [1] = { -570.0, 2.4, -461.0, 0 },
            [2] = {   -7.0, 2.8,  101.0, 0 },
            [3] = {  472.0, 3.0,  583.0, 0 },
        },
    },
    -- Dawn (the final CoP fight vs Promathia). Empyreal Paradox entrance
    -- TR_Entrance already carries the base Dawn (index 0) + Apocalypse Nigh
    -- (index 1), so HTBF tiers sit at 2/3/4. Multi-phase (P1 -> cutscene ->
    -- P2 Promathia): the phase-2 spawn rides in on onEventFinishBattlefield,
    -- now copied by the registrar. Prishe + Selhteus allies come along via the
    -- reused setupBattlefield. 6-player, 30-min.
    dawn =
    {
        zone = xi.zone.EMPYREAL_PARADOX, entryNpc = 'TR_Entrance', exitNpc = 'Transcendental_Radiance',
        gem = xi.ki.DAWN_PHANTOM_GEM, baseIndex = 12, baseBattlefieldId = 4210,
        reuseBaseId = xi.battlefield.id.DAWN, label = 'Dawn',
        difficulty = 'epic', rewardClass = 'epic',
        -- Promathia's mission pools have only 8k/12k HP and already carry
        -- bespoke defensive mechanics. Huge flat DEF from the generic epic
        -- profile made autos deal zero while the tiny scaled HP evaporated to
        -- capped WS. Give him real HTBF HP with moderate additive stats.
        tierScaleOverride =
        {
            [1] = { name = 'I',   lvl = 1.25, hp = 3.0,  minHp = 1500000, att = 1200, def = 700,  macc = 400,  meva = 500,  eva = 300 },
            [2] = { name = 'II',  lvl = 1.50, hp = 7.0,  minHp = 3000000, att = 2600, def = 1400, macc = 850,  meva = 1000, eva = 600 },
            [3] = { name = 'III', lvl = 1.75, hp = 14.0, minHp = 6000000, att = 4500, def = 2400, macc = 1500, meva = 1700, eva = 1000 },
        },
        entryPosByArea =
        {
            [1] = { -520.0, -120.0,  493.8, 190 },
            [2] = {  520.0,    0.0,  493.8, 190 },
            [3] = { -520.0,  120.0, -545.5, 190 },
        },
    },

    -- ── ToAU boss battlefields ──────────────────────────────────────────────
    -- Bases restrict to arena 1; the HTBF uses arenas 2-3 (mobIds for all 3
    -- arenas exist in the base groups) so it never blocks the base mission.
    puppet_in_peril =
    {
        zone = xi.zone.JADE_SEPULCHER, entryNpc = '_1v0',
        exitNpcs = { '_1v1', '_1v2', '_1v3' },
        gem = xi.ki.PUPPET_IN_PERIL_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4100,
        -- The base group's area-2/3 entities have placeholder 0,0,0 spawns.
        -- Keep HTBF on the one complete arena rather than entering a void.
        reuseBaseId = xi.battlefield.id.PUPPET_IN_PERIL, allowedAreas = { [1] = true },
        label = 'Puppet in Peril', difficulty = 'standard', rewardClass = 'standard',
        entryPosByArea = { [1] = { 239.0, -32.0, 207.0, 0 } },
    },
    legacy_of_the_lost =
    {
        zone = xi.zone.TALACCA_COVE, entryNpc = '_1l0',
        exitNpcs = { '_1l1', '_1l2', '_1l3' },
        gem = xi.ki.LEGACY_PHANTOM_GEM, baseIndex = 5, baseBattlefieldId = 4110,
        -- As above, only area 1 has real Gessho spawn coordinates.
        reuseBaseId = xi.battlefield.id.LEGACY_OF_THE_LOST, allowedAreas = { [1] = true },
        label = 'Legacy of the Lost', difficulty = 'standard', rewardClass = 'standard',
        entryPosByArea = { [1] = { -180.0, 39.1, 147.0, 0 } },
    },

    -- ── Rise of the Zilart boss battlefields ────────────────────────────────
    shadow_lord =
    {
        zone = xi.zone.THRONE_ROOM, entryNpc = '_4l1',
        exitNpcs = { '_4l2', '_4l3', '_4l4' },
        gem = xi.ki.SHADOW_LORD_PHANTOM_GEM, baseIndex = 12, baseBattlefieldId = 4120,
        reuseBaseId = xi.battlefield.id.SHADOW_LORD_BATTLE, label = 'Shadow Lord',
        difficulty = 'standard', rewardClass = 'standard',
        entryPosByArea =
        {
            [1] = {  -464.5, -167.2, -273.0, 0 },
            [2] = {  -784.8, -407.2, -513.0, 0 },
            [3] = { -1104.6, -647.2, -753.0, 0 },
        },
    },
    stellar_fulcrum =
    {
        zone = xi.zone.STELLAR_FULCRUM, entryNpc = '_4z0',
        exitNpcs = { '_4z1', '_4z2', '_4z3' },
        gem = xi.ki.STELLAR_FULCRUM_PHANTOM_GEM, baseIndex = 12, baseBattlefieldId = 4130,
        reuseBaseId = xi.battlefield.id.RETURN_TO_DELKFUTTS_TOWER, label = "Return to Delkfutt's Tower",
        difficulty = 'standard', rewardClass = 'standard',
        entryPosByArea =
        {
            [1] = { 0.0,  202.5, -375.0, 64 },
            [2] = { 0.0,    2.5,   22.0, 64 },
            [3] = { 0.0, -197.5,  415.0, 64 },
        },
    },
    celestial_nexus =
    {
        zone = xi.zone.THE_CELESTIAL_NEXUS, entryNpc = '_513',
        exitNpcs = { '_514', '_515' },
        gem = xi.ki.CELESTIAL_NEXUS_PHANTOM_GEM, baseIndex = 12, baseBattlefieldId = 4140,
        reuseBaseId = xi.battlefield.id.CELESTIAL_NEXUS, label = 'The Celestial Nexus',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea =
        {
            [1] = { -32.0, -18.0,  -35.0, 128 },
            [2] = { 456.3, -21.1,  659.5, 128 },
            [3] = { 505.6,  -4.1, -680.2, 128 },
        },
    },
    -- Divine Might: 18-player, multi-entrance (qm1_1..qm1_5). Base uses index 5
    -- across them; HTBF at 13/14/15 (kept above the Ark Angel HTBF range 10-12).
    -- entryPosByArea: the base fight's arena-warp is driven by the
    -- client DAT keyed on battlefieldId; our custom HTBF ids (4150+) aren't in
    -- the DAT, so the client never warps and the player is left at the entry NPC
    -- (shimmering circle) with the countdown ticking. htbf.register() reads this
    -- and setPos'es the player itself after enterBattlefield(). Each staging
    -- point is about 30 yalms from the corresponding arena's first enemy.
    divine_might =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpcs = { 'qm1_1', 'qm1_2', 'qm1_3', 'qm1_4', 'qm1_5' },
        exitNpc = 'qm2',
        gem = xi.ki.DIVINE_PHANTOM_GEM, baseIndex = 16, baseBattlefieldId = 4150,
        reuseBaseId = xi.battlefield.id.DIVINE_MIGHT, maxPlayers = 18, label = 'Divine Might',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
    },

    -- Ark Angels: 5 separate fights, each on its own La'Loff entrance (qm1_1..
    -- qm1_5) with its own gem. Base uses idx 0-4 per entrance (+ Divine Might at
    -- idx 5 / its HTBF at 13-15), so Ark Angel HTBF tiers sit at 10/11/12.
    -- entryPosByArea: same DAT-warp workaround as Divine Might above.
    ark_angels_1 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_1', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_APATHY, baseIndex = 12, baseBattlefieldId = 4160,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_1, label = 'Ark Angel HM',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
        passiveOnEntry = true,
        winOnPrimaryDeath = true,
    },
    ark_angels_2 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_2', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_COWARDICE, baseIndex = 12, baseBattlefieldId = 4170,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_2, label = 'Ark Angel TT',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
        passiveOnEntry = true,
        winOnPrimaryDeath = true,
    },
    ark_angels_3 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_3', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_ENVY, baseIndex = 12, baseBattlefieldId = 4180,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_3, label = 'Ark Angel MR',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
        passiveOnEntry = true,
        winOnPrimaryDeath = true,
    },
    ark_angels_4 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_4', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_ARROGANCE, baseIndex = 12, baseBattlefieldId = 4190,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_4, label = 'Ark Angel EV',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
        passiveOnEntry = true,
        winOnPrimaryDeath = true,
    },
    ark_angels_5 =
    {
        zone = xi.zone.LALOFF_AMPHITHEATER, entryNpc = 'qm1_5', exitNpc = 'qm2',
        gem = xi.ki.PHANTOM_GEM_OF_RAGE, baseIndex = 12, baseBattlefieldId = 4200,
        reuseBaseId = xi.battlefield.id.ARK_ANGELS_5, label = 'Ark Angel GK',
        difficulty = 'epic', rewardClass = 'epic',
        entryPosByArea = laLoffEntryPos,
        passiveOnEntry = true,
        winOnPrimaryDeath = true,
    },
}

return catalog
