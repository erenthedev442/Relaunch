-----------------------------------
-- augment_catalyst_drops.lua
--
-- 1:1 augment-catalyst drops. Each augment catalyst comes from ONE specific mob,
-- and no mob drops more than one catalyst -- the mapping lives in
-- `augment_catalyst_mobs.lua` (a tier-banded auto-assignment: T0 catalysts on
-- low-level mobs ... T4 on Lv100+, 297/299 on a mob that already dropped the item).
--
-- This REPLACES the old random tier-pool roll (augment_catalyst_pools.lua, whose
-- `roll()` is now neutered). Hooks the GLOBAL onMobDeathEx so it covers every mob
-- with no per-mob droplist edit; the assigned mob is the only place its catalyst
-- drops here. Catalysts can still also appear via their original base droplist.
--
-- Deploy: new override module -> needs a map RESTART to register (no hot-reload).
-- Pure Lua, no SQL. DROP_RATE is the one balance knob.
-----------------------------------
require('modules/module_utils')

local MAP   = require('modules/custom/lua/augment_catalyst_mobs')   -- ['Mob_Internal_Name'] = itemId
local POOLS = require('modules/custom/lua/augment_catalyst_pools')  -- M.pickForTier(tier) -> random catalyst
local m     = Module:new('augment_catalyst_drops')
local SYS   = xi.msg.channel.SYSTEM_3

-- Drop rates (tune in playtest).
--   DROP_RATE     = a MAPPED mob dropping its ONE assigned catalyst (targeted grind).
--   FALLBACK_RATE = a NON-mapped mob dropping a RANDOM level-appropriate catalyst.
-- Diagnostic (2026-07-07) found ~91% of kills are non-mapped mobs, so catalysts
-- felt absent. The fallback lets any mob contribute; the level->tier banding keeps
-- higher tiers gated to higher-level mobs (bands mirror the 1:1 map: T0<=28,
-- T1 29-49, T2 50-72, T3 73-94, T4 95+).
-- 2026-07-11 (owner): FLAT 10% EVERYWHERE — every catalyst source (mapped,
-- fallback, retail droplist via zz_catalyst_droplist_rate.sql, dungeon trash)
-- pays 10%. DROP_RATE_MULTIPLIER is 1.0 on the box (verified 2026-07-11 —
-- the committed docs table saying 3x was a stale Legendary-era import), so
-- the effective rate is exactly 10% across the board.
local DROP_RATE     = 10
local FALLBACK_RATE = 10

local function tierForLevel(lvl)
    if     lvl >= 95 then return 4
    elseif lvl >= 73 then return 3
    elseif lvl >= 50 then return 2
    elseif lvl >= 29 then return 1
    else                  return 0 end
end

-- ── DIAGNOSTIC TRACE (2026-07-07) ─────────────────────────────────────────
-- Set DEBUG = true to log one [CatalystDBG] line per player kill (which gate it
-- hit). Left in place, off, so it can be re-enabled without another code change.
local DEBUG = false
local function dbg(msg) if DEBUG then print('[CatalystDBG] ' .. msg) end end

-- itemId -> stat label, built once from the catalog (for the drop message).
local labels
local function labelFor(itemId)
    if not labels then
        labels = {}
        local ok, cat = pcall(require, 'modules/custom/lua/augment_catalog')
        if ok and type(cat) == 'table' then
            for iid, def in pairs(cat) do
                if type(def) == 'table' then labels[iid] = def.label end
            end
        end
    end
    return labels[itemId] or 'augment'
end

-- itemId -> readable ITEM name ("black_tiger_hide" -> "Black Tiger Hide"),
-- from augment_item_names.lua. Player request 2026-07-03: the drop message
-- must say WHAT ITEM dropped, not just which stat it augments.
local names
local function itemNameFor(itemId)
    if not names then
        local ok, map = pcall(require, 'modules/custom/lua/augment_item_names')
        names = (ok and type(map) == 'table') and map or {}
    end
    local n = names[itemId]
    if not n then
        return nil
    end
    n = n:gsub('_', ' ')
    return (n:gsub("(%a[%w']*)", function(w)
        return w:sub(1, 1):upper() .. w:sub(2)
    end))
end

-- Hand `itemId`'s catalyst to `player` with the drop message. Shared by the
-- mob-death path below AND the GM !catalysttest command (via xi.augmentCatalystDrops).
-- Returns true if awarded, false if the inventory was full.
local function award(player, itemId)
    local itemName = itemNameFor(itemId)
    local display  = itemName
        and string.format('%s (%s)', itemName, labelFor(itemId))
        or  labelFor(itemId)

    if player:getFreeSlotsCount() <= 0 then
        player:printToPlayer(string.format(
            '[Augments] %s dropped, but your inventory is full!', display), SYS)
        return false
    end
    pcall(function() player:addItem({ id = itemId, quantity = 1 }) end)
    player:printToPlayer(string.format(
        '[Augments] Catalyst dropped: %s. Trade it to the Augment Moogle to apply.', display), SYS)
    return true
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    -- onMobDeathEx fires once per alliance member; isKiller marks the killing blow,
    -- so we drop ONCE per kill (not per member). Non-killer members return silently
    -- (they'd flood the trace); every real player kill logs exactly one line below.
    if not isKiller or player == nil then return end

    local mname = mob:getName() or '?'
    if mob:isNM() then dbg(mname .. ' -> skip: NM (catalysts never drop from NMs)'); return end

    local itemId = MAP[mname]
    if not itemId then
        -- FALLBACK: non-mapped mob -> chance at a RANDOM level-appropriate catalyst,
        -- so any farming yields catalysts (not just the 186 assigned mobs).
        if math.random(100) > FALLBACK_RATE then
            dbg(mname .. ' -> skip: not mapped, fallback roll missed')
            return
        end
        local lvl = 0
        pcall(function() lvl = mob:getMainLvl() or 0 end)
        local fbId = POOLS.pickForTier(tierForLevel(lvl))
        if not fbId then dbg(mname .. ' -> skip: fallback tier pool empty'); return end
        local okf = award(player, fbId)
        dbg(string.format('%s (Lv%d) -> FALLBACK %s catalyst itemId=%d for %s', mname, lvl,
            okf and 'AWARDED' or 'INV-FULL', fbId, player:getName()))
        return
    end

    -- Mapped mob: its ONE assigned catalyst at the (higher) targeted rate.
    local roll = math.random(100)
    if roll > DROP_RATE then
        dbg(string.format('%s -> skip: roll %d > DROP_RATE %d', mname, roll, DROP_RATE))
        return
    end

    local ok = award(player, itemId)
    dbg(string.format('%s -> %s catalyst itemId=%d for %s', mname,
        ok and 'AWARDED' or 'INV-FULL', itemId, player:getName()))
end)

-- Exposed so the GM !catalysttest command can fire the exact award+message path in
-- isolation (bypassing the mob-death hook + the roll). `map` lets it pick a real
-- mapped catalyst when the command is called with no itemId.
xi.augmentCatalystDrops = { give = award, map = MAP }

return m
