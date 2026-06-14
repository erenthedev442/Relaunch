-----------------------------------
-- func: trustattack  (TOGGLE)
-- desc: Run once to turn ON "trust auto-attack": your own summoned trusts keep
--       engaging whatever you have targeted (cursor target -- works before you
--       engage too), fight after fight, with no need to re-run the command.
--       Run it again to turn it OFF.  Macro:  /console !trustattack
--
--       No global tick exists in LSB Lua, so while the TrustAtkOn charVar is 1 a
--       re-arming per-player timer re-checks your target every couple seconds and
--       points your trusts at it WHEN IT CHANGES (so it never resets a trust that
--       is already on the right target). The companion onGameIn module
--       (trust_auto_attack_rearm) restarts the loop after a zone/login so the
--       toggle survives both -- THAT half needs a map restart to go live; until
--       then the toggle works within the zone you enable it in (re-run on a zone).
--
-- Pure Lua. Only the caller's OWN trusts (a party can hold several masters').
-----------------------------------
require('modules/module_utils')

local CV      = 'TrustAtkOn'   -- charVar: 1 = auto-attack mode on
local TICK_MS = 2000           -- target re-check cadence
local lastTgt = {}             -- [playerId] = last targ id the trusts were sent to

-- Point the caller's own trusts at the target.
local function sendTrusts(player, target)
    local targID = target:getTargID()
    local myId   = player:getID()
    for _, member in ipairs(player:getPartyWithTrusts()) do
        if member:isTrust() then
            local master = member:getMaster()
            if master ~= nil and master:getID() == myId then
                member:engage(targID)
            end
        end
    end
    lastTgt[myId] = targID
end

-- One re-check: if you have a living enemy selected and it differs from where the
-- trusts were last sent, send them. Same target -> leave them swinging (no reset).
local function tick(player)
    local target = player:getCursorTarget()
    if target == nil or not target:isMob() or not target:isAlive() then
        return
    end
    if lastTgt[player:getID()] ~= target:getTargID() then
        sendTrusts(player, target)
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
        player:printToPlayer('[Trust Attack] Auto-attack OFF - your trusts stop chasing your target.', xi.msg.channel.SYSTEM_3)
    else
        player:setCharVar(CV, 1)
        lastTgt[player:getID()] = nil   -- force the next tick to (re)send
        player:printToPlayer('[Trust Attack] Auto-attack ON - your trusts will keep attacking whatever you target. Run !trustattack again to stop.', xi.msg.channel.SYSTEM_3)
        arm(player)
    end
end

return commandObj
