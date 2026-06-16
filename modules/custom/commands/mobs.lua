-----------------------------------
-- func: mobs
-- desc: GM/debug. Lists the LIVE (spawned, HP > 0) mobs in your current zone,
--       nearest first, with HP% and rough distance. Optional name filter:
--         !mobs            -> everything alive nearby
--         !mobs lizard     -> only names containing "lizard"
--
--       Handy for "what's left to kill". e.g. a dungeon boss only spawns once
--       EVERY tracked mob is dead (DungeonSystem #sess.mobs == 0), so if the
--       boss won't appear, !mobs shows the straggler and how far away it is
--       (a mob stuck out-of-bounds reads as alive but very far / unreachable).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,   -- all players (read-only: lists live mobs in your zone)
    parameters = 's',
}

commandObj.onTrigger = function(player, filter)
    local zone = player:getZone()
    if not zone then
        player:printToPlayer('[mobs] you are not in a zone.', xi.msg.channel.SYSTEM_3)
        return
    end

    local px, py, pz = player:getXPos(), player:getYPos(), player:getZPos()
    local f = (filter and filter ~= '') and filter:lower() or nil

    local list = {}
    for _, m in pairs(zone:getMobs()) do
        if m:isSpawned() and m:getHPP() > 0 then
            local nm = m:getName()
            if not f or string.find(nm:lower(), f, 1, true) then
                local dx, dy, dz = m:getXPos() - px, m:getYPos() - py, m:getZPos() - pz
                list[#list + 1] =
                {
                    name = nm,
                    hpp  = m:getHPP(),
                    dist = math.floor(math.sqrt(dx * dx + dy * dy + dz * dz)),
                }
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)

    player:printToPlayer(string.format('[mobs] %d alive in %s%s:',
        #list, zone:getName(), f and (" matching '" .. filter .. "'") or ''),
        xi.msg.channel.SYSTEM_3)

    if #list == 0 then
        player:printToPlayer('  (none alive -- the zone is clear)', xi.msg.channel.SYSTEM_3)
        return
    end

    for i = 1, math.min(#list, 30) do
        local e = list[i]
        player:printToPlayer(string.format('  %-24s HP %3d%%  ~%dy', e.name, e.hpp, e.dist),
            xi.msg.channel.SYSTEM_3)
    end
    if #list > 30 then
        player:printToPlayer(string.format("  ... +%d more (use !mobs <name> to filter)", #list - 30),
            xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
