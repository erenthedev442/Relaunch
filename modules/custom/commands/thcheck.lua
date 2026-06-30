-----------------------------------
-- !thcheck
-- Treasure Hunter diagnostic. Shows:
--   1. your live TREASURE_HUNTER mod (gear + augments summed by the engine),
--   2. the cap that actually reaches mobs (4 non-THF / 8 THF main; melee
--      first-swing hits proc higher, up to 12 + JP cap),
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
    local th   = player:getMod(xi.mod.TREASURE_HUNTER)
    local mjob = player:getMainJob()
    local cap  = (mjob == xi.job.THF) and 8 or 4

    player:printToPlayer(string.format('[TH] Your Treasure Hunter (gear+augments): %d', th), SYS)
    player:printToPlayer(string.format('[TH] Reaches mobs on claim/cast: capped at %d (%s main). Melee first-swings proc higher (up to ~12).',
        cap, (mjob == xi.job.THF) and 'THF' or 'non-THF'), SYS)

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
