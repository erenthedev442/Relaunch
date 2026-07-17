-----------------------------------
-- legendary_ring_aura.lua   (RELAUNCH)
--
-- Keeps the Legendary Ring's permanent "legendary" AURA glow on across ZONING
-- and LOGIN. The ring's item script (scripts/items/legendary_ring.lua) applies
-- the glow on equip, but status effects like this drop when a player changes
-- zone (or logs out), so a worn ring would stop glowing after the first zone.
--
-- The engine calls InteractionGlobal.onZoneIn(player, prevZone, fn) on every
-- zone change INCLUDING the zone-in that fires at login, so a single global
-- override re-applies the glow to anyone wearing item 26169. Purely additive:
-- runs the normal dispatcher, returns whatever it returned, and just adds the
-- re-apply as a side effect (safe to co-exist with disable_zonein_cutscenes,
-- which overrides the same function).
--
-- AURA_EFFECT must match the item script's AURA_EFFECT. AFTERGLOW (489) is the
-- Relic/Mythic/Aeonic weapon glow -- pure visual, no stats.
--
-- addOverride patches a global at module load -> a map RESTART registers it.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/interaction/interaction_global')

local m = Module:new('legendary_ring_aura')

local RING_ID     = 26169
-- AFTERGLOW (489) has no standalone client visual (aura only renders in the
-- relic/mythic aftermath weapon context) -- wearers got an icon but no glow.
-- MUMORS_RADIANCE (613) renders its body glow from the effect alone.
local AURA_EFFECT     = xi.effect.MUMORS_RADIANCE -- keep in sync with scripts/items/legendary_ring.lua
local OLD_AURA_EFFECT = xi.effect.AFTERGLOW       -- legacy; cleared so old wearers don't keep a dead icon
local AURA_DUR    = 31536000             -- 1 year (re-applied every zone-in)

local function isWearingRing(player)
    local r1 = player:getEquippedItem(xi.slot.RING1)
    if r1 and r1:getID() == RING_ID then return true end
    local r2 = player:getEquippedItem(xi.slot.RING2)
    return r2 ~= nil and r2:getID() == RING_ID
end

m:addOverride('InteractionGlobal.onZoneIn', function(player, prevZone, fallbackFn)
    local ret = super(player, prevZone, fallbackFn)

    -- Delay so equipment + stats are settled after the zone-in (same 1500ms
    -- the auto-buff modules use). Guarded by hasStatusEffect so we never stack.
    player:timer(1500, function(p)
        if p:hasStatusEffect(OLD_AURA_EFFECT) then
            p:delStatusEffect(OLD_AURA_EFFECT)
        end
        if isWearingRing(p) and not p:hasStatusEffect(AURA_EFFECT) then
            p:addStatusEffect(AURA_EFFECT, { power = 1, duration = AURA_DUR, origin = p })
        end
    end)

    return ret
end)

return m
