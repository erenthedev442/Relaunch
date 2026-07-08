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

local MAP = require('modules/custom/lua/augment_catalyst_mobs')  -- ['Mob_Internal_Name'] = itemId
local m   = Module:new('augment_catalyst_drops')
local SYS = xi.msg.channel.SYSTEM_3

local DROP_RATE = 50   -- % chance the assigned mob drops its catalyst (tune in playtest)

-- ── TEMP DIAGNOSTIC (2026-07-07) ──────────────────────────────────────────
-- Trace WHY a catalyst drop does / doesn't fire. Every PLAYER-killed mob logs ONE
-- [CatalystDBG] line to map-server.log naming the gate it hit. If you kill a mob
-- and see NO [CatalystDBG] line at all, onMobDeathEx never fired for it (the mob
-- wasn't claimed by you -> the C++ only calls it for the claimer). Grep the log for
-- 'CatalystDBG'. Set DEBUG = false (or delete this block) once diagnosed.
local DEBUG = true
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
    if not itemId then dbg(mname .. ' -> skip: not in the catalyst mob map'); return end

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
