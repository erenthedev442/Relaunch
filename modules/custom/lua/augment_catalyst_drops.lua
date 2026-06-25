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

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    -- onMobDeathEx fires once per alliance member; isKiller marks the killing blow,
    -- so we drop ONCE per kill (not per member).
    if not isKiller or player == nil then return end

    local name   = mob:getName()
    local itemId = name and MAP[name]
    if not itemId then return end
    if math.random(100) > DROP_RATE then return end

    if player:getFreeSlotsCount() <= 0 then
        player:printToPlayer('[Augments] A catalyst dropped, but your inventory is full!', SYS)
        return
    end
    pcall(function() player:addItem({ id = itemId, quantity = 1 }) end)
    player:printToPlayer(string.format(
        '[Augments] Catalyst dropped: %s. Trade it to the Augment Moogle to apply.', labelFor(itemId)), SYS)
end)

return m
