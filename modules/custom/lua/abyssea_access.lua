-----------------------------------
-- Abyssea is the 75-99 channel, not a rebirth / boost skip of the exp camps.
-- Level 1s with Rebirth or Ascension stats were walking in (or being carried)
-- and riding trash + pyxis XP to 99. Entry, zone-in, and script XP all
-- check the same floor. GMs are exempt.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')
require('scripts/globals/abyssea/sturdypyxis/experience')

local m = Module:new('abyssea_access')

local function isGM(player)
    return player and player.getGMLevel and player:getGMLevel() > 0
end

xi.abyssea.canEnterAbyssea = function(player)
    if not player then
        return false
    end

    if isGM(player) then
        return true
    end

    return player:getMainLvl() >= xi.abyssea.MIN_ENTRY_LEVEL
end

m:addOverride('xi.abyssea.onZoneIn', function(player)
    if xi.abyssea.ejectIfIneligible(player) then
        return
    end

    super(player)
end)

m:addOverride('xi.abyssea.afterZoneIn', function(player)
    if xi.abyssea.ejectIfIneligible(player) then
        return
    end

    super(player)
end)

xi.pyxis.exp.giveExperience = function(npc, player)
    local alliance = player:getAlliance()
    local exp      = npc:getLocalVar('EXP')

    for _, member in ipairs(alliance) do
        if
            member:getZoneID() == player:getZoneID() and
            member:isPC() and
            xi.abyssea.canEnterAbyssea(member)
        then
            member:addExp(exp)
        end
    end
end

return m
