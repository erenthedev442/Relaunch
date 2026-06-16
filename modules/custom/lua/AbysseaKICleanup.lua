-----------------------------------
-- AbysseaKICleanup
-- One-shot migration: removes all Abyssea NM pop key items from every
-- character on their next true login.  Gated by charVar so it runs
-- exactly once per character regardless of restarts.
-----------------------------------
require('modules/module_utils')

local m = Module:new('AbysseaKICleanup')

-- Numeric IDs of every key item used to pop Abyssea ??? NMs.
-- These are retail KIs that are now meaningless on this server because
-- the AbysseaMarks module lets players pop NMs via Hunt Marks instead.
local ABYSSEA_POP_KIS =
{
    1459, 1460, 1461, 1462, 1463, 1464, 1465, 1466, 1467, 1468,
    1469, 1470, 1471, 1472, 1473, 1474, 1475, 1476, 1477, 1478,
    1479, 1480, 1481, 1482, 1483, 1484, 1485, 1486, 1488, 1489,
    1490, 1491, 1492, 1493, 1494, 1495, 1496, 1497, 1518, 1519,
    1520, 1521, 1522, 1528, 1529, 1530, 1531, 1532,
}

local CLEANUP_CV = 'AbysseaKICleanupDone'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not firstLogin then return end
    if player:getCharVar(CLEANUP_CV) ~= 0 then return end

    local removed = 0
    for _, ki in ipairs(ABYSSEA_POP_KIS) do
        if player:hasKeyItem(ki) then
            player:delKeyItem(ki)
            removed = removed + 1
        end
    end

    player:setCharVar(CLEANUP_CV, 1)

    if removed > 0 then
        player:printToPlayer(
            string.format('[Server] Removed %d obsolete Abyssea key item(s).', removed),
            xi.msg.channel.SYSTEM_3)
    end
end)

return m
