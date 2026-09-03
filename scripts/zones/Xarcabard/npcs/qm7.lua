-----------------------------------
-- Area: Xarcabard
--  NPC: qm7 (???)
-- Involved in Quests: RNG AF3 quest - Unbridled Passion
-- Also the open pop for Koenigstiger (Mastery Sigil rotation).
-- !pos -295.065 -25.054 151.250 112
-----------------------------------
local ID = zones[xi.zone.XARCABARD]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    local tiger = GetMobByID(ID.mob.KOENIGSTIGER)
    if not tiger then
        return
    end

    if tiger:isAlive() then
        player:messageSpecial(ID.text.PRESENCE_IN_CAVE)
        return
    end

    if tiger:isSpawned() then
        player:messageSpecial(ID.text.CAVERN_CONTINUES)
        return
    end

    -- RNG AF3 keeps its cutscene pop. Anyone else (Mastery rotation, etc.)
    -- can spawn the tiger from this ??? — it used to require unbridledPassion
    -- == 4, which made the NM uncampable.
    if player:getCharVar('unbridledPassion') == 4 then
        player:startEvent(8)
        return
    end

    player:messageSpecial(ID.text.MONSTER_APPEARS)
    SpawnMob(ID.mob.KOENIGSTIGER):updateClaim(player)
end

entity.onEventFinish = function(player, csid, option, npc)
    if csid == 8 then
        player:messageSpecial(ID.text.MONSTER_APPEARS)
        SpawnMob(ID.mob.KOENIGSTIGER):updateClaim(player)
    end
end

return entity
