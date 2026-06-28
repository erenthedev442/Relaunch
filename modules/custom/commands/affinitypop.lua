-----------------------------------
-- !affinitypop
-- Forces all 24 Augment-Sage affinity-hunt NMs to spawn immediately and puts
-- them on a 30s repop, regardless of the retail scripts' long HNM timers.
--
-- This is the no-restart counterpart to the affinity_nm_autopop module: the
-- module does this automatically at zone boot (needs a restart to activate),
-- while this command force-pops them on demand right now. Safe to re-run.
--
-- mobids are the VALID entity ids from affinity_nm_spawns.sql (post commit
-- 689a0a72d7): 0x1000000 | (zoneid<<12) | targid, targid < 0x700.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- The 24 affinity NM mobids (current DB values; see affinity_nm_spawns.sql).
local AFFINITY_MOBIDS =
{
    17208833, 17298946, 17491459, 17229316, 17303045,  -- Behemoth, K.Behemoth, K.Arthro, Simurgh, Adamantoise
    17507846, 17270279, 17507848, 17507849, 17241610,  -- Genbu, Roc, Seiryu, Byakko, Aspidochelone
    16897547, 17405452, 16901645, 17507854, 17507855,  -- Ouryu, Bune, Phoenix, Suzaku, Kirin
    17409552, 17409553, 17618450, 16799251, 17290772,  -- Fafnir, Nidhogg, Vrtra, Tiamat, K.Vinegarroon
    17557013, 17557014, 17311255, 17311256,            -- Khimaira, Cerberus, Absolute Virtue, Proto-Omega
}

local RESPAWN_SECONDS = 30

commandObj.onTrigger = function(player)
    local SYS = xi.msg.channel.SYSTEM_3
    local up, missing = 0, 0

    for _, mobid in ipairs(AFFINITY_MOBIDS) do
        local mob = GetMobByID(mobid)
        if mob then
            -- Keep it on the short timer past death: DESPAWN listener fires
            -- after the retail onMobDespawn, so it's the last writer.
            mob:addListener('DESPAWN', 'AFFINITY_AUTOPOP', function(m)
                m:setRespawnTime(RESPAWN_SECONDS)
            end)
            mob:setRespawnTime(RESPAWN_SECONDS)
            if not mob:isSpawned() then
                SpawnMob(mobid)
            end
            up = up + 1
        else
            missing = missing + 1
        end
    end

    player:printToPlayer(string.format(
        '[Affinity] Forced %d affinity NM(s) up (30s repop).%s', up,
        missing > 0 and string.format(' %d not loaded (zone not booted?).', missing) or ''), SYS)
    player:printToPlayer('[Affinity] Warp to them with !affinitynm <name|number>.', SYS)
end

return commandObj
