-----------------------------------
-- Area: Ru'Lude Gardens
--  NPC: Marjory
-- Type: Records of Eminence chain (Filled to Capacity -> Over Capacity -> Way Over Capacity)
-- Role:
--   1) Gate the new (March 2026) Filled-to-Capacity -> Over-Capacity -> Way-Over-Capacity
--      RoE chain that ultimately rewards Marjory's Thesis (200 alter ego points).
--   2) Retroactively grant Marjory's Thesis to players who completed the chain
--      before the 2026-03-10 retail update.
-- !pos -3.9 2 139 243
-- Source: FFXI-EventsDump dumps/Ru'Lude Gardens/17772853 - Marjory.md
-----------------------------------
---@type TNpcEntity
local entity = {}

-- Trust spell ID ranges (per scripts/commands/addalltrusts.lua):
--   896-999 and 1003-1019 (IDs 1000-1002 are not valid trust spells).
local function countLearnedTrusts(player)
    local count = 0

    for spellId = 896, 999 do
        if player:hasSpell(spellId) then
            count = count + 1
        end
    end

    for spellId = 1003, 1019 do
        if player:hasSpell(spellId) then
            count = count + 1
        end
    end

    return count
end

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    local hasBracelet     = player:hasKeyItem(xi.ki.CIPHER_BRACELET)
    local hasJobBreaker   = player:hasKeyItem(xi.ki.JOB_BREAKER)
    local hasMinTrusts    = countLearnedTrusts(player) >= 86
    local wayOverComplete = player:getEminenceCompleted(4088)
    local thesisGranted   = player:getCharVar('MARJORY_THESIS_GRANTED') == 1

    if wayOverComplete and not thesisGranted then
        -- Retroactive grant path (player completed the chain before the March 2026 update).
        player:startEvent(10307)
        return
    end

    if wayOverComplete then
        -- Post-completion idle.
        player:startEvent(10286)
        return
    end

    if not hasJobBreaker or not hasMinTrusts then
        -- "Meager aura" gate.
        player:startEvent(10282)
        return
    end

    if not hasBracelet then
        -- Must see Syndella first for cipher_bracelet KI.
        player:startEvent(10304)
        return
    end

    if player:getCharVar('MARJORY_FILLED_CHAIN_STARTED') == 1 then
        -- Already started -- give the reminder event.
        player:startEvent(10284)
    else
        -- Eligible -- give the main intro / hand-off.
        player:startEvent(10283)
    end
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid == 10283 and option == 1 then
        player:setCharVar('MARJORY_FILLED_CHAIN_STARTED', 1)
        -- The actual RoE record activation (Filled to Capacity) is wired separately in Task 13.
    elseif csid == 10307 then
        if npcUtil.giveItem(player, xi.item.COPY_OF_MARJORYS_THESIS) then
            player:setCharVar('MARJORY_THESIS_GRANTED', 1)
        end
    end
end

return entity
