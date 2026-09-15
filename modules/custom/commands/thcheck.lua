-----------------------------------
-- !thcheck
-- Treasure Hunter diagnostic. Shows:
--   1. your live TREASURE_HUNTER mod (capped at 14, or 17 on main THF).
--      99 /THF is +3 from the trait and still stops at 14.
--   2. the cap that actually reaches mobs,
--   3. your current target's APPLIED TH level (m_THLvl) -- engage/hit a mob,
--      then run this to see exactly what TH it received.
--
-- This pinpoints where the chain breaks: mod 0 = augments not summing; mod 40
-- but target TH 0 = not being applied on your kills; target TH 4 but bad drops
-- = the drop/Abyssea path.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local SYS  = xi.msg.channel.SYSTEM_3
    local th = player:getMod(xi.mod.TREASURE_HUNTER)

    local cap = xi.combat.treasureHunter.playerCap(player)
    player:printToPlayer(string.format('[TH] Your Treasure Hunter (all sources): %d / %d', th, cap), SYS)
    if player:getMainJob() == xi.job.THF then
        player:printToPlayer('[TH] Main THF: TH I/II/III sit above the shared 14. Need +14 from gear / augments / prestige to reach 17 at 90.', SYS)
    else
        player:printToPlayer('[TH] HARD CAP TH14 -- gear, augments, prestige, rebirth, and /THF cannot exceed it. 99 /THF is +3 from trait (need +11 elsewhere). Main THF reaches 17 at 90.', SYS)
    end

    local ok, target = pcall(function() return player:getTarget() end)
    if ok and target and target:isMob() then
        local mth = target:getTHlevel()
        player:printToPlayer(string.format('[TH] Target "%s" applied TH right now: %d  <-- this is what drops use.',
            target:getName(), mth), SYS)
        if mth == 0 and th > 0 then
            player:printToPlayer('[TH] Target shows 0 despite your TH > 0 -- hit it once (melee or a nuke) and re-run; if it stays 0 your TH is not transferring.', SYS)
        end
    else
        player:printToPlayer('[TH] No mob targeted. Engage a mob, hit it, then re-run to read its applied TH.', SYS)
    end
end

return commandObj
