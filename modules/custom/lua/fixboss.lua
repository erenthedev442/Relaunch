return {
    cmdProps = {
        name       = 'fixboss',
        permission = 1,
        parameters = '',
    },
    onTrigger = function(player, args)
        local target = player:getTarget()
        if not target then
            player:printToPlayer('[fixboss] No target selected.')
            return
        end
        if target:isPC() then
            player:printToPlayer('[fixboss] Target is a player - aborting.')
            return
        end
        local x, y, z, rot, zone = player:getPos()
        target:setPos(x, y, z, rot, zone)
        player:printToPlayer(string.format('[fixboss] Moved "%s" to (%.2f, %.2f, %.2f).', target:getName(), x, y, z))
    end,
}
