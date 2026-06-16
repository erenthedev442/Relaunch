-----------------------------------
-- func: cleartrial <player>
-- desc: GM tool to unstick an Ascension Trial for a player.
--   Clears the in-memory "boss alive" flag so the Altar menu stops
--   saying the boss is still up, then optionally stamps the given boss
--   kill so the trial counts as complete for that boss.
--
--   Usage:
--     !cleartrial PlayerName          -> clears the alive flag only
--     !cleartrial PlayerName diabolos -> clears alive flag + stamps Diabolos kill
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

local cfg = require('modules/custom/lua/prestige_catalog')

-- Build groupId lookup by boss name (same as spawntrialboss).
local bossMap = {}

local function registerBoss(gid, boss)
    local key = boss.name:lower():gsub('_', ' ')
    bossMap[key] = { groupId = gid, boss = boss }
end

for gid, boss in pairs(cfg.trialBosses or {}) do
    registerBoss(gid, boss)
end

if cfg.trialScaling and cfg.trialScaling.tiers then
    for _, tier in ipairs(cfg.trialScaling.tiers) do
        if tier.roster and tier.roster.bosses then
            for gid, boss in pairs(tier.roster.bosses) do
                registerBoss(gid, boss)
            end
        end
    end
end

-----------------------------------
commandObj.onTrigger = function(player, targetName, bossArg)
    if not targetName then
        player:printToPlayer('Usage: !cleartrial <player> [boss_name]')
        return
    end

    local targ = GetPlayerByName(targetName)
    if not targ then
        player:printToPlayer(string.format('[ClearTrial] Player "%s" not found (must be online).', targetName))
        return
    end

    local pid = targ:getID()
    local cleared = false

    -- Clear the Altar's "boss alive" flag.
    if xi._prestige_summonedTrial then
        if xi._prestige_summonedTrial[pid] then
            xi._prestige_summonedTrial[pid] = nil
            cleared = true
        end
    else
        player:printToPlayer('[ClearTrial] WARNING: xi._prestige_summonedTrial not available -- the map server')
        player:printToPlayer('  needs a restart to expose this table. The flag could not be cleared.')
    end

    -- Optionally stamp a boss kill.
    local stamped = nil
    if bossArg then
        local key   = bossArg:lower():gsub('_', ' ')
        local entry = bossMap[key]
        if not entry then
            for k, v in pairs(bossMap) do
                if k:sub(1, #key) == key then entry = v; break end
            end
        end
        if entry then
            targ:setCharVar('Prestige_Trial_' .. entry.groupId, os.time())
            stamped = entry.boss.label
        else
            player:printToPlayer(string.format('[ClearTrial] Unknown boss "%s" -- flag cleared but no stamp applied.', bossArg))
        end
    end

    -- Report.
    if cleared then
        player:printToPlayer(string.format('[ClearTrial] Alive-flag cleared for %s.', targetName))
    else
        player:printToPlayer(string.format('[ClearTrial] No alive-flag was set for %s (already clear).', targetName))
    end

    if stamped then
        player:printToPlayer(string.format('[ClearTrial] Stamped "%s" kill for %s.', stamped, targetName))
    end

    targ:printToPlayer('[Ascension] A GM has reset your trial state. Try the Altar again.', xi.msg.channel.SYSTEM_3)
end

return commandObj
