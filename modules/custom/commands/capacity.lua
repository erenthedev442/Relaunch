-----------------------------------
-- func: capacity
-- desc: Warps you to a Capacity Point farm camp.
--       Usage:
--         !capacity            -> Bibiki Bay (default)
--         !capacity bibiki     -> Bibiki Bay
--         !capacity ranperre   -> King Ranperre's Tomb
--         !capacity ronfaure   -> East Ronfaure [S] north square (also !capacity3)
--         !capacity 4          -> East Ronfaure [S] south square (also !capacity4)
--       Landing spots MUST stay in sync with warpPos in the
--       corresponding catalog files.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local FARMS =
{
    {
        keys    = { 'bibiki', 'b', 'bay', '', 'default' },
        zone    = xi.zone.BIBIKI_BAY,
        pos     = { 93.0, -45.5, 928.0, 128 },
        label   = 'Bibiki Bay',
    },
    {
        keys    = { 'ranperre', 'r', 'tomb', 'kt', 'krt' },
        zone    = xi.zone.KING_RANPERRES_TOMB,
        -- Confirmed native main-floor point. Keep in sync with warpPos in
        -- ranperre_farm_catalog.lua.
        pos     = { -54.55, 7.21, 82.03, 0 },
        label   = "King Ranperre's Tomb",
    },
    {
        keys    = { 'ronfaure', 'ers', 'east', '3', 'capacity3' },
        zone    = xi.zone.EAST_RONFAURE_S,
        pos     = { 510.8990, -59.5513, 471.9462, 92 },
        label   = 'East Ronfaure [S] (north)',
    },
    {
        keys    = { '4', 'capacity4', 'ronfaure2', 'ers2', 'south' },
        zone    = xi.zone.EAST_RONFAURE_S,
        pos     = { 577.1001, -51.1170, 149.4120, 116 },
        label   = 'East Ronfaure [S] (south)',
    },
}

commandObj.onTrigger = function(player, dest)
    local key = (dest or ''):lower():gsub('%s+', '')

    -- Find the matching farm.
    for _, farm in ipairs(FARMS) do
        for _, k in ipairs(farm.keys) do
            if key == k then
                if player:getMainLvl() < 99 then
                    player:printToPlayer(
                        'Capacity Point farms require a level 99 main job.',
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                local p = farm.pos
                player:setPos(p[1], p[2], p[3], p[4], farm.zone)
                player:printToPlayer(string.format(
                    'Warped to the Capacity farm in %s. Grind well, kupo!',
                    farm.label), xi.msg.channel.SYSTEM_3)
                return
            end
        end
    end

    -- Unknown destination -- list the options.
    player:printToPlayer('Usage: !capacity [destination]', xi.msg.channel.SYSTEM_3)
    player:printToPlayer('  (no arg) / bibiki   - Bibiki Bay (120k HP)', xi.msg.channel.SYSTEM_3)
    player:printToPlayer("  ranperre            - King Ranperre's Tomb (120k HP)", xi.msg.channel.SYSTEM_3)
    player:printToPlayer('  ronfaure / 3        - East Ronfaure [S] north (also !capacity3)', xi.msg.channel.SYSTEM_3)
    player:printToPlayer('  4 / south           - East Ronfaure [S] south (also !capacity4)', xi.msg.channel.SYSTEM_3)
end

return commandObj
