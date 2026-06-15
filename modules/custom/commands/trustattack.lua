-----------------------------------
-- func: trustattack  (TOGGLE)
-- desc: Run once to turn ON: while on, you AUTO-ENGAGE whatever mob you have
--       targeted (cursor target), so you and your trusts attack it hands-free --
--       point at the next mob and you all switch to it. Run again to turn OFF.
--       Macro:  /console !trustattack
--
--       WHY this engages YOU: the engine (CTrustController::DoCombatTick,
--       trust_controller.cpp) force-disengages a trust every combat tick whenever
--       its master is idle, so trusts simply cannot fight while you stand
--       un-engaged. The only way to keep them swinging is to put you in combat --
--       so this engages you (you auto-attack the mob too). The engage fires only
--       on a target CHANGE, so your (and the trusts') swing timer never resets.
--
--       No global tick exists in LSB Lua, so while TrustAtkOn is 1 a re-arming
--       per-player timer re-checks your target every couple seconds. The companion
--       onGameIn module (trust_auto_attack_rearm) restarts the loop after a
--       zone/login -- THAT half needs a map restart to go live; until then re-run
--       the command after you change zones.
-----------------------------------
require('modules/module_utils')

local CV      = 'TrustAtkOn'   -- charVar: 1 = auto-engage mode on
local TICK_MS = 2000           -- target re-check cadence
local lastTgt = {}             -- [playerId] = last targ id we engaged on

-- Engage the CALLER on the target. Trusts mirror their master: the engine
-- disengages them the instant the master is idle (trust_controller.cpp), so
-- putting YOU in combat is the only thing that keeps the trusts on the mob.
-- Engage on a target change only -> the swing timer never resets.
local function engageOnTarget(player, target)
    player:engage(target:getTargID())
    lastTgt[player:getID()] = target:getTargID()
end

-- One re-check: if you have a living enemy selected and it differs from what we
-- last engaged on, engage it -- you and your trusts switch to it. Same target ->
-- leave you swinging (no reset).
local function tick(player)
    local target = player:getCursorTarget()
    if target == nil or not target:isMob() or not target:isAlive() then
        return
    end
    if lastTgt[player:getID()] ~= target:getTargID() then
        engageOnTarget(player, target)
    end
end

-- Re-arming loop: re-arms only while the mode is on, so a toggle-off stops it.
local function arm(player)
    if (player:getCharVar(CV) or 0) ~= 1 then
        return
    end
    player:timer(TICK_MS, function(p)
        if p and (p:getCharVar(CV) or 0) == 1 then
            pcall(function() tick(p) end)
            arm(p)
        end
    end)
end

-- Exposed so the onGameIn re-arm module can restart the loop after a zone.
xi.trustAtk = { arm = arm }

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if (player:getCharVar(CV) or 0) == 1 then
        player:setCharVar(CV, 0)
        lastTgt[player:getID()] = nil
        player:printToPlayer('[Trust Attack] OFF - you stop auto-engaging your target.', xi.msg.channel.SYSTEM_3)
    else
        player:setCharVar(CV, 1)
        lastTgt[player:getID()] = nil   -- force the next tick to (re)engage
        player:printToPlayer('[Trust Attack] ON - target a mob and you + your trusts attack it automatically (you auto-engage too). Run !trustattack again to stop.', xi.msg.channel.SYSTEM_3)
        arm(player)
    end
end

return commandObj
