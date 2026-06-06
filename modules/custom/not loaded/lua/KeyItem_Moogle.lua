-----------------------------------
-- Southern San d'Oria Starter NPCs
-- 1. Gear_Moogle    - Gives starter gear (one-time)
-- 2. Mission_Moogle - Grants clearance for all missions
-- 3. KeyItem_Moogle - Grants every key item in the game
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Southern_San_dOria/Zone')
-----------------------------------
local m = Module:new('keyitem_moogle')

m:addOverride('xi.zones.Southern_San_dOria.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- NPC 3: KeyItem Moogle
    -- Grants every key item in the game
    -- Position: offset -3.0 on X axis
    -----------------------------------
    zone:insertDynamicEntity({
        objtype  = xi.objType.NPC,
        name     = 'KeyItem_Moogle',
        look     = 2430,
        x        = -4.2,
        y        = -9.4,
        z        =  2.0,
        rotation =  0,
        widescan =  1,

        onTrigger = function(player, npc)
            if player:getCharVar('KeyItemsReceived') == 1 then
                player:printToPlayer('You have already received all key items, kupo!')
                return
            end

            local added   = 0
            local skipped = 0

            for i = 1, 4000 do
                if not player:hasKeyItem(i) then
                    local ok = pcall(function()
                        player:addKeyItem(i)
                    end)
                    if ok then
                        added = added + 1
                    else
                        skipped = skipped + 1
                    end
                end
            end

            player:setCharVar('KeyItemsReceived', 1)
            player:printToPlayer(string.format(
                'All key items granted, kupo! Added: %d, Skipped: %d',
                added, skipped
            ))
        end,
    })
end)

return m
