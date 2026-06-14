-----------------------------------
-- Area: Ru'Lude Gardens
--  NPC: Syndella
-- Type: Alter Ego Points system unlock (March 2026 retail)
-- Role: Grants the cipher_bracelet KI that unlocks the Alter Ego Points upgrade screen,
--       plus a starter Trust Tome (item 6717, +100 AEP) on first acceptance.
-- Prereqs:
--   - Player has at least one learned Trust spell (any nation Trust quest completed).
--   - Player owns the job_breaker key item (main job has hit lvl 99 milestone).
-- !pos 3.8 2 137 243
-- Source: FFXI-EventsDump dumps/Ru'Lude Gardens/17772854 - Syndella.md
-- Retail capture verified: captures/processed/2026-05-04-alter-ego-points/
-----------------------------------

-- Trust spell ID ranges (per scripts/commands/addalltrusts.lua):
--   896-999 and 1003-1019 (IDs 1000-1002 are not valid trust spells).
-- Kept in sync with Marjory.lua -- update both files together if the range changes.
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

---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    local hasBracelet   = player:hasKeyItem(xi.ki.CIPHER_BRACELET)
    local hasJobBreaker = player:hasKeyItem(xi.ki.JOB_BREAKER)
    local hasAnyTrust   = countLearnedTrusts(player) > 0

    if hasBracelet then
        -- Already-have-it greet.
        player:startEvent(10303)
        return
    end

    if not hasAnyTrust then
        -- "Beyond your current abilities" gate -- no Trust spells learned.
        player:startEvent(10301)
        return
    end

    if not hasJobBreaker then
        -- Need job_breaker first (lvl 99 milestone).
        player:startEvent(10302)
        return
    end

    -- Eligible -- fire the grant event.
    player:startEvent(10300)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid == 10300 and option == 1 then
        if npcUtil.giveKeyItem(player, xi.ki.CIPHER_BRACELET) then
            -- Per SE article + retail capture: a starter Trust Tome is granted on system unlock.
            npcUtil.giveItem(player, xi.item.TRUST_MAGIC_TOME)
        end
    end
end

return entity
