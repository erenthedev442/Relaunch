-----------------------------------
-- func: capacity
-- desc: Warps you to a Capacity Point farm camp.
--       Usage:
--         !capacity            -> Bibiki Bay (default)
--         !capacity bibiki     -> Bibiki Bay
--         !capacity ranperre   -> King Ranperre's Tomb
--       Landing spots MUST stay in sync with warpPos in the
--       corresponding catalog files (capacity_farm_catalog.lua /
--       ranperre_farm_catalog.lua).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
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
end

return commandObj
