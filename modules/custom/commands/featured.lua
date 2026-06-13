-----------------------------------
-- func: featured
-- desc: Shows which NM is the Weekly Featured Hunt for each Hunting
--       League tier.  Featured NMs award 2x base marks on the first
--       kill of the week - the bonus stacks with the First-Kill bonus.
--
-- The featured NM rotates deterministically each ISO week using the
-- same formula as HuntingLeague.lua's kill handler:
--   weekIdx = floor(os.time() / 604800)
--   featIdx = (weekIdx % #tierMobs) + 1
-- so this command always agrees with what the server rewards.
--
-- Usage: !featured
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local catalog = require('modules/custom/lua/hunting_league_catalog')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

commandObj.onTrigger = function(player)
    local weekIdx = math.floor(os.time() / 604800)

    player:printToPlayer('[Featured Hunt] == This Week\'s Bonus NMs ==============', H)
    player:printToPlayer('  First kill of each featured NM awards +2x base marks!', B)

    for _, tierDef in ipairs(catalog.tiers) do
        local mobs = tierDef.mobs
        if mobs and #mobs > 0 then
            local featIdx = (weekIdx % #mobs) + 1
            local featMob = mobs[featIdx]
            if featMob then
                local weekVar = string.format('HL_Featured_%d_%d', weekIdx, featMob.groupId)
                local done    = (player:getCharVar(weekVar) or 0) ~= 0
                local status  = done and '* earned' or '+2x marks!'
                player:printToPlayer(
                    string.format('  %s  |  %s  [%s]', tierDef.name, featMob.label, status), B)
            end
        end
    end

    player:printToPlayer('[Featured Hunt] Type !hunt to warp and start hunting!', B)
end

return commandObj
