-----------------------------------
-- new_char_wardrobe_sizes.lua
-- Upstream's xi.player.charCreate only resizes Inventory and Mog Satchel
-- (player.lua lines ~119-122). Mog Wardrobes 1-8 keep the engine default
-- of 0 slots, so new characters can't store anything in their wardrobes
-- until they manually... actually, there's no normal in-game way to get
-- wardrobe slots either. Just hand them out at max on creation.
--
-- Pure-Lua override - survives upstream pulls.
--
-- CANONICAL wardrobe-sizing owner (2026-06-25). The old `mission_wardrobe_unlocks`
-- module was REMOVED: it zeroed all 8 wardrobes at charCreate (gating them behind
-- missions), which fought this module AND was dead on relaunch -- Character_Upgrader
-- auto-completes every mission via setMissionStatus, not npcUtil.completeMission, so
-- that module's grant hook never fired. Net effect was order-fragile (new chars could
-- briefly end up with 0 wardrobe slots). Now there is one deterministic charCreate
-- owner (this file); Character_Upgrader.bumpWardrobeSizes re-affirms the same target
-- on first login as an idempotent safety net. Both fill to START_INVENTORY -- no conflict.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('new_char_wardrobe_sizes')

-- All 8 wardrobe container IDs (from scripts/enum/inventory_location.lua)
local WARDROBE_LOCATIONS = {
    xi.inv.WARDROBE,
    xi.inv.WARDROBE2,
    xi.inv.WARDROBE3,
    xi.inv.WARDROBE4,
    xi.inv.WARDROBE5,
    xi.inv.WARDROBE6,
    xi.inv.WARDROBE7,
    xi.inv.WARDROBE8,
}

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    -- changeContainerSize is a DELTA function, not an absolute setter.
    -- Compute the gap from the current size so calling this twice (or
    -- on a partially-bumped char) doesn't overshoot.
    local target = xi.settings.main.START_INVENTORY
    for _, loc in ipairs(WARDROBE_LOCATIONS) do
        local delta = target - player:getContainerSize(loc)
        if delta > 0 then
            player:changeContainerSize(loc, delta)
        end
    end
end)

return m
