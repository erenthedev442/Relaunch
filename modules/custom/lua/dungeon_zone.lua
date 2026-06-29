-----------------------------------
-- Shared hybrid-dungeon zone hooks
-----------------------------------
local helper = {}

helper.recoverOrphan = function(player)
    if player:getCharVar('DungeonActive') == 0 or player:getInstance() then
        return
    end

    player:timer(1000, function(p)
        -- Zone-in can run just before the loader attaches PInstance.  Only
        -- recover a genuinely orphaned character after that window passes.
        if p:getCharVar('DungeonActive') ~= 0 and not p:getInstance() then
            p:setCharVar('DungeonActive', 0)
            p:setPos(1.5, 0, -15, 128, xi.zone.GM_HOME)
        end
    end)
end

helper.onInstanceZoneIn = function(player, instance)
    local entry = instance:getEntryPos()
    player:setPos(entry.x, entry.y, entry.z, entry.rot)
end

helper.onInstanceLoadFailed = function()
    return xi.zone.GM_HOME
end

return helper
