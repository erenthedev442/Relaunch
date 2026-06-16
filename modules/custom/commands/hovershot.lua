-----------------------------------
-- !hovershot
--
-- Triggers Hover Shot (the RNG Lv95 job ability) server-side.
--
-- The retail abilityId for hover_shot is unknown to the LSB project, so the
-- standard abilities table row cannot make the client show or accept the
-- ability via /ja. This command bypasses the client lookup and runs the
-- server-side effect directly, mirroring what the JA would do.
--
-- Requirements: RNG main job, level >= 95.
-- Recast: 180 seconds (3 minutes), enforced via per-player localVar.
-- Overwrites Decoy Shot (retail parity; handled in useHoverShot).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local RECAST   = 180
local CD_VAR   = 'cmdja_hovershot_cd'
local CH       = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player)
    if player:getMainJob() ~= xi.job.RNG then
        player:printToPlayer('Hover Shot: requires RNG as your main job.', CH)
        return
    end

    if player:getMainLvl() < 95 then
        player:printToPlayer('Hover Shot: requires RNG level 95 (you are level ' .. player:getMainLvl() .. ').', CH)
        return
    end

    local remain = player:getLocalVar(CD_VAR) - os.time()
    if remain > 0 then
        player:printToPlayer(string.format('Hover Shot is recharging (%ds remaining).', remain), CH)
        return
    end

    xi.job_utils.ranger.useHoverShot(player, player, nil, nil)
    player:setLocalVar(CD_VAR, os.time() + RECAST)
    player:printToPlayer('Hover Shot: active. Fire on the move to build RACC/RATT stacks.', CH)
end

return commandObj
