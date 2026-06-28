-----------------------------------
-- !affinitypop
-- Forces all 24 Augment-Sage affinity-hunt NMs to spawn immediately and puts
-- them on a 30s repop, regardless of the retail scripts' long HNM timers.
--
-- This is the no-restart counterpart to the affinity_nm_autopop module: the
-- module does this automatically at zone boot (needs a restart to activate),
-- while this command force-pops them on demand right now. Safe to re-run.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- The 24 affinity NM mobids (from affinity_nm_spawns.sql / affinity_nm_autopop).
local AFFINITY_MOBIDS =
{
    433921, 524034, 716547, 454404, 528133,          -- Behemoth, K.Behemoth, K.Arthro, Simurgh, Adamantoise
    732934, 495367, 732936, 732937, 466698,          -- Genbu, Roc, Seiryu, Byakko, Aspidochelone
    122635, 630540, 126733, 732942, 732943,          -- Ouryu, Bune, Phoenix, Suzaku, Kirin
    634640, 634641, 843538, 24339, 515860,           -- Fafnir, Nidhogg, Vrtra, Tiamat, K.Vinegarroon
    782101, 782102, 536343, 536344,                  -- Khimaira, Cerberus, Absolute Virtue, Proto-Omega
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
