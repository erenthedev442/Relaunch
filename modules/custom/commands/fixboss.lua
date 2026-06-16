-----------------------------------
-- func: fixboss [mob_name]
-- desc: Teleports a mob to the GM's current position.
--       With no argument: moves the GM's current target.
--       With a name arg:  finds that mob by name in the current zone.
--
--       Usage (GM must be in the same zone as the mob):
--         !fixboss
--         !fixboss The Void Maw
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

commandObj.onTrigger = function(player, nameArg)
    local zone = player:getZone()
    if not zone then
        player:printToPlayer('[fixboss] You are not in a zone.')
        return
    end

    local target = nil

    if nameArg and nameArg ~= '' then
        local needle = nameArg:lower()
        local mobs = zone:getMobs()
        if mobs then
            for _, m in pairs(mobs) do
                if m:isSpawned() and m:getName():lower():find(needle, 1, true) then
                    target = m
                    break
                end
            end
        end
        if not target then
            player:printToPlayer(string.format('[fixboss] No spawned mob named "%s" found in %s.', nameArg, zone:getName()))
            return
        end
    else
        target = player:getTarget()
        if not target then
            player:printToPlayer('[fixboss] No target and no name given. Usage: !fixboss [mob_name]')
            return
        end
        if target:isPC() then
            player:printToPlayer('[fixboss] Target is a player. Usage: !fixboss [mob_name]')
            return
        end
    end

    local x, y, z, rot, zoneId = player:getPos()
    target:setPos(x, y, z, rot, zoneId)
    player:printToPlayer(string.format('[fixboss] Moved "%s" to (%.2f, %.2f, %.2f).', target:getName(), x, y, z))
end

return commandObj
