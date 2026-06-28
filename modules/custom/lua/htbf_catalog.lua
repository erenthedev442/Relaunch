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
    trial_by_fire =
    {
        zone = xi.zone.CLOISTER_OF_FLAMES, entryNpc = 'FP_Entrance', exitNpc = 'Fire_Protocrystal',
        gem = xi.ki.AVATAR_PHANTOM_GEM, baseIndex = 3, baseBattlefieldId = 4000,
        mobs = { 'Ifrit_Prime_TBF' }, maxPlayers = 6, label = 'Trial by Fire',
    },
    -- The other 5 Avatar Primes (same structure; fill mobs/entrance from each base
    -- script, then add the 3 tier files). Kept here as the rollout list:
    -- trial_by_ice      -> Cloister_of_Frost   / IP_Entrance  / Ifrit? (Shiva_Prime_TBI)
    -- trial_by_wind     -> Cloister_of_Gales   / GP_Entrance  / Garuda_Prime_*
    -- trial_by_earth    -> Cloister_of_Tremors / TP_Entrance  / Titan_Prime_*
    -- trial_by_lightning-> Cloister_of_Storms  / SP_Entrance  / Ramuh_Prime_*
    -- trial_by_water    -> Cloister_of_Tides   / WP_Entrance  / Leviathan_Prime_*
}

return catalog
