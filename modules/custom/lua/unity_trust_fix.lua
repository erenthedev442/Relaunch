-----------------------------------
-- unity_trust_fix.lua
-- After any unity NPC interaction, ensure the player's UC trust for their
-- current unity is present in their spell list.
--
-- Root cause: UpdateUnityTrust() in roe.cpp only grants the UC trust when
-- prev_accolades OR current_accolades >= 5 (in char_points).  On this server
-- the Charcter Upgrader grants UC trusts via the blanket addSpell loop, so
-- players START with the trust.  But when they pledge, changeUnityLeader()
-- zeros those accolade currencies BEFORE calling setUnityLeader(), so
-- UpdateUnityTrust() sees 0 and fires the else-branch that removes the trust.
-- Re-pledging to any unity repeats the cycle.
--
-- Fix: after super() runs, call addSpell(trustId) for the current unity
-- leader.  addSpell() is a no-op if the spell is already known (returns false)
-- so this is safe to fire on every unity NPC event, not just pledges.
-----------------------------------
require('modules/module_utils')

local m = Module:new('unity_trust_fix')

-- Mirror of ROE_TRUST_ID[11] from src/map/roe.h, indexed 1-11.
local UNITY_TRUST_ID =
{
    [1]  = 953,  -- Pieuje
    [2]  = 1005, -- Ayame
    [3]  = 954,  -- Invincible Shield
    [4]  = 955,  -- Apururu
    [5]  = 1006, -- Maat
    [6]  = 1007, -- Aldo
    [7]  = 956,  -- Jakoh
    [8]  = 1008, -- Naja
    [9]  = 957,  -- Flaviria
    [10] = 980,  -- Yoran-Oran
    [11] = 981,  -- Sylvie
}

m:addOverride('xi.unity.onEventFinish', function(player, csid, option, npc)
    xi.unity.onEventFinish.super(player, csid, option, npc)

    local leader = player:getUnityLeader()
    if leader and leader > 0 and leader <= 11 then
        local trustId = UNITY_TRUST_ID[leader]
        if trustId then
            player:addSpell(trustId, { silentLog = true })
        end
    end
end)

return m
