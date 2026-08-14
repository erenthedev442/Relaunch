-----------------------------------
-- func: hunt
-- desc: Warps you to the Hunting League hub in Escha - Zi'Tah.
--       The hub has three NPCs in a row:
--         Seals (leftmost)  — tier info, rank-up, seal shop
--         Zone Guide        — one-click teleport to any tier cluster area
--         Accessories       — neck / earring / ring / back / waist shop
--       From the Zone Guide, pick your tier to warp straight to that
--       cluster's spawner NPC without crossing the zone on foot.
--       Landing spot stays in sync with sealsPos in hunting_league_catalog.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(0.0000, -0.5000, -30.0000, 128, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to the Hunting League hub. Hunt well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
