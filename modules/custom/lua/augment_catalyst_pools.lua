-----------------------------------
-- augment_catalyst_pools.lua
--
-- Ties augment-catalyst FARMING DIFFICULTY to the augment TIER it unlocks.
-- Each augment in augment_catalog.lua carries a `tier` (0-4); the augment
-- system already gates those tiers on content (T0 = Day 1, T1 = HL Rank 3,
-- T2 = HL Rank 5, T3 = Prestige Lv15, T4 = endgame). This module groups every
-- catalyst by that tier into a drop POOL, and the NM death handlers (Hunting
-- League, Prestige) roll ONE random catalyst from the pool matching the NM's
-- difficulty -- so the content that gates a tier also drops its catalysts.
--
-- SOFT gating (owner choice 2026-06-24): this is IN ADDITION to whatever else
-- drops a catalyst; it doesn't remove any existing drop source. The tier NM is
-- just the clear, reliable farm. Catalysts are no longer sold for gil (the
-- !shop augments category was removed) -- this is the intended replacement.
--
-- Plain require()-library. xi.* only inside functions (call-time), per the
-- module auto-load rule.
-----------------------------------
local M = {}

-- HL rank (the hunting_league_catalog `tier` field, 1-5) -> augment-tier pool.
-- Rank 1-2 feed T0, Rank 3 feeds T1, Rank 4-5 feed T2. Shinryu (Rank 5 elite)
-- and Prestige are special-cased by their callers (T4 / T3).
M.HL_RANK_TIER = { [1] = 0, [2] = 0, [3] = 1, [4] = 2, [5] = 2 }

-- Chance (%) per eligible NM kill that a catalyst drops at all. One knob to
-- tune the whole economy; lower = rarer catalysts. (Which catalyst you get is
-- uniform-random within the tier pool, so a specific augment is still a grind.)
M.DROP_RATE = 50

-- Lazily-built: pools[tier] = { itemId, ... }; labels[itemId] = 'stat name'.
local pools, labels

local function build()
    if pools then return end
    pools  = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }
    labels = {}
    -- Force-reload so a hot-reloaded augment_catalog.lua is picked up without
    -- a map restart (mirrors the old shop.lua catalog pull).
    package.loaded['modules/custom/lua/augment_catalog'] = nil
    local ok, cat = pcall(require, 'modules/custom/lua/augment_catalog')
    if ok and type(cat) == 'table' then
        for itemId, def in pairs(cat) do
            if type(def) == 'table' and def.tier ~= nil and pools[def.tier] then
                table.insert(pools[def.tier], itemId)
                labels[itemId] = def.label or 'augment'
            end
        end
    end
end

-- Return a random catalyst itemId from tier `t`'s pool (nil if the tier is empty
-- or invalid). Builds the pools on first use. Unlike M.roll (disabled), this is a
-- pure picker -- used by the open-world FALLBACK drop in augment_catalyst_drops.lua
-- so any non-mapped mob can still yield a level-appropriate catalyst.
function M.pickForTier(t)
    build()
    local pool = pools[t]
    -- RELAUNCH all-tier-0 catalog: augment_catalog.lua deliberately tags EVERY
    -- catalyst tier 0 ("every augment available at every content tier; power
    -- scales via the player's Augment Tier roll band"), so pools[1..4] are
    -- EMPTY. The open-world FALLBACK drop bands by MOB LEVEL into tiers 1-4 for
    -- any mob level >= 29 -- which meant pickForTier returned nil and silently
    -- awarded NOTHING on essentially all farming content, making the configured
    -- 10% fallback effectively 0% (the "catalysts feel way rarer than 10%"
    -- reports, diagnosed 2026-07-17). Fall back to the flat tier-0 pool (all
    -- catalysts) when the requested tier is empty, so every non-mapped mob
    -- honors FALLBACK_RATE regardless of level. Still prefers tiers 1-4 first
    -- if they are ever repopulated.
    if not pool or #pool == 0 then
        pool = pools[0]
    end
    if not pool or #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

-- Roll a tier-`augTier` catalyst onto `player` at `rate`% (default DROP_RATE).
-- No-op if the pool is empty, the roll misses, or the player's inventory is
-- full (with a heads-up in the latter case so the drop isn't silently eaten).
function M.roll(player, augTier, rate)
    -- DISABLED 2026-06-25: the random tier-pool roll was replaced by 1:1
    -- specific-mob drops (augment_catalyst_drops.lua -- each catalyst comes from
    -- one assigned mob, no mob drops two). Left as a no-op so the existing
    -- HL / Prestige / Abyssea callers need no edits. Delete this line to restore.
    do return end
    if player == nil or augTier == nil then return end
    build()
    local pool = pools[augTier]
    if not pool or #pool == 0 then return end
    if math.random(100) > (rate or M.DROP_RATE) then return end

    local itemId = pool[math.random(#pool)]
    if player:getFreeSlotsCount() <= 0 then
        player:printToPlayer('[Augments] An augment catalyst dropped, but your inventory is full!', xi.msg.channel.SYSTEM_3)
        return
    end
    player:addItem({ id = itemId, quantity = 1 })
    player:printToPlayer(
        string.format('[Augments] Catalyst dropped: %s (Tier %d). Trade it to the Augment Moogle to apply.',
            labels[itemId] or 'augment', augTier),
        xi.msg.channel.SYSTEM_3)
end

return M
