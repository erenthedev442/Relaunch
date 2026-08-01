-----------------------------------
-- !fixodin
-- Hotfix invisible Mythic Forge Odin (live zone, no targeting).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

local ODIN_MODEL_ID = 0x0725

commandObj.onTrigger = function(player)
    local zone = player:getZone()
    if not zone or zone:getID() ~= xi.zone.ABDHALJS_ISLE_PURGONORGO then
        player:printToPlayer('[fixodin] Stand on Abdhaljs Isle-Purgonorgo (hub).')
        return
    end

    local fixed = 0
    for _, entity in pairs(zone:queryEntitiesByName('DE_Odin%')) do
        if entity:isNPC() then
            entity:setModelId(ODIN_MODEL_ID)
            fixed = fixed + 1
        end
    end

    player:printToPlayer(fixed > 0
        and '[fixodin] Odin model restored — should be targetable now.'
        or '[fixodin] No Odin Mythic Forge NPC found here.')
end

return commandObj
