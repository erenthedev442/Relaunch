-----------------------------------
-- func: spawntrialboss [boss] [target_player]
-- desc: GM tool to force-spawn an Ascension Trial boss in Provenance.
--   boss         : partial name match (diabolos / medusa / odin / sarameya /
--                  etc.). Defaults to Diabolos if omitted.
--   target_player: character NAME to receive the kill stamp on death.
--                  Defaults to whoever lands the killing blow.
--
-- Death auto-stamps Prestige_Trial_<groupId> so the player's Altar trial
-- progress is credited exactly like a normal summon. No tier scaling is
-- applied -- the boss spawns at baseline catalog stats.
--
-- Must be used while the GM is inside Provenance (zone 222).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

local cfg = require('modules/custom/lua/prestige_catalog')

-- Build a flat lowercase-name -> { groupId, boss } table across ALL tiers.
local bossMap    = {}
local validNames = {}

local function registerBoss(gid, boss)
    local key = boss.name:lower():gsub('_', ' ')
    bossMap[key] = { groupId = gid, boss = boss }
    table.insert(validNames, boss.name)
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

table.sort(validNames)

-----------------------------------
commandObj.onTrigger = function(player, bossArg, targetPlayerName)
    local zone = player:getZone()
    if not zone or zone:getID() ~= xi.zone.PROVENANCE then
        player:printToPlayer('[TrialBoss] Must be used while inside Provenance.')
        return
    end

    -- Resolve boss (default Diabolos).
    local key   = ((bossArg or 'diabolos'):lower():gsub('_', ' '))
    local entry = bossMap[key]

    if not entry then
        -- Try prefix match.
        for k, v in pairs(bossMap) do
            if k:sub(1, #key) == key then
                entry = v
                break
            end
        end
    end

    if not entry then
        player:printToPlayer(string.format(
            '[TrialBoss] Unknown boss "%s". Valid: %s',
            bossArg or '?', table.concat(validNames, ', ')))
        return
    end

    local gid  = entry.groupId
    local boss = entry.boss

    -- Spawn next to the GM (exact pattern from summonNextTrial).
    local px    = player:getXPos()
    local py    = player:getYPos()
    local pz    = player:getZPos()
    local angle = math.random() * math.pi * 2
    local sp    =
    {
        x   = px + math.cos(angle) * (cfg.trialSpawnGap or 2.5),
        y   = py,
        z   = pz + math.sin(angle) * (cfg.trialSpawnGap or 2.5),
        rot = math.random(0, 255),
    }

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = gid,
        groupZoneId          = cfg.trialBossZoneId,
        name                 = boss.name,
        x                    = sp.x,
        y                    = sp.y,
        z                    = sp.z,
        rotation             = sp.rot,
        minLevel             = boss.level,
        maxLevel             = boss.level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            -- Credit: named target if given, otherwise the killer.
            local creditPlayer = killer
            if targetPlayerName then
                local named = GetPlayerByName(targetPlayerName)
                if named then creditPlayer = named end
            end
            if creditPlayer then
                local cid = creditPlayer:getID()
                -- Stamp trial progress.
                creditPlayer:setCharVar('Prestige_Trial_' .. gid, os.time())
                -- Clear any stale Altar-tracked "alive" entry so the menu unblocks.
                if xi._prestige_summonedTrial then
                    xi._prestige_summonedTrial[cid] = nil
                end
                creditPlayer:printToPlayer(string.format(
                    '[Ascension] %s slain. Trial stamp recorded -- commune with the Altar to check your progress.',
                    boss.label), xi.msg.channel.SYSTEM_3)
            end
        end,
    })

    if not mob then
        player:printToPlayer(string.format(
            '[TrialBoss] Spawn failed for %s (groupId %d). Is the mob_groups row present?',
            boss.label, gid))
        return
    end

    mob:setSpawn(sp.x, sp.y, sp.z, sp.rot)
    mob:spawn()

    -- Apply catalog mods and HP (no tier scaling -- baseline fight).
    if boss.mods then
        for modId, value in pairs(boss.mods) do
            mob:setMod(modId, value)
        end
    end
    if boss.hpBoost then
        local newMax = math.floor(mob:getMaxHP() * boss.hpBoost)
        mob:setMaxHP(newMax)
        mob:setHP(newMax)
    end

    local creditMsg = targetPlayerName or 'whoever kills it'
    player:printToPlayer(string.format(
        '[TrialBoss] %s spawned (groupId %d). Trial credit -> %s.',
        boss.label, gid, creditMsg))

    if boss.cry then
        local players = zone:getPlayers()
        if players then
            for _, p in pairs(players) do
                if p then
                    p:printToPlayer('  ' .. boss.cry, xi.msg.channel.SYSTEM_3)
                end
            end
        end
    end
end

return commandObj
