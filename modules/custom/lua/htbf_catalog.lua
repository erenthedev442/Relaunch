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
    [xi.ki.AVATAR_PHANTOM_GEM] = 50000,  -- enters any of the 6 Avatar Prime trials
}

-- Display names for the gems the vendor sells (key item ids have no server-side
-- name lookup; the client shows the real KI name in the inventory).
catalog.gemName =
{
    [xi.ki.AVATAR_PHANTOM_GEM] = 'Avatar Phantom Gem',
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
}

return catalog
