-----------------------------------
-- !affinitypop
-- Forces all 24 Augment-Sage affinity-hunt NMs to spawn immediately and puts
-- them on a 30s repop, regardless of the retail scripts' long HNM timers.
--
-- This is the no-restart counterpart to the affinity_nm_autopop module: the
-- module does this automatically at zone boot (needs a restart to activate),
-- while this command force-pops them on demand right now. Safe to re-run.
--
-- mobids are the VALID entity ids from affinity_nm_spawns.sql: 0x1000000 |
-- (zoneid<<12) | targid, with targid < 0x400 (mobs/NPCs live below 0x400; the
-- 0x400-0x6FF range is PC-only in CZoneEntities::GetEntity, so a mob there is
-- never found by GetMobByID).
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
    17208197, 17298310, 17490823, 17228680, 17302409,  -- Behemoth, K.Behemoth, K.Arthro, Simurgh, Adamantoise
    17310621, 17269643, 17310622, 17310623, 17240974,  -- Genbu, Roc, Seiryu, Byakko, Aspidochelone
    16896911, 17404816, 16901009, 17310624, 17507219,  -- Ouryu, Bune, Phoenix, Suzaku, Kirin
    17408916, 17408917, 17617814, 16798615, 17290136,  -- Fafnir, Nidhogg, Vrtra, Tiamat, K.Vinegarroon
    17556377, 17556378, 17310619, 17310620,            -- Khimaira, Cerberus, Absolute Virtue, Proto-Omega
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
            -- One-time "no longer registers" notice for the 13 reworked-out NMs
            -- (trophy grants live in augment_affinity_grants.lua, catalog-driven).
            if xi.affinityAutopop and xi.affinityAutopop.deathNotice then
                mob:addListener('DEATH', 'AFFINITY_NOTICE', function(m, killer)
                    xi.affinityAutopop.deathNotice(m, killer)
                end)
            end
            -- Fix the "NPC" display name (re-apply each spawn). Display-only.
            if xi.affinityAutopop and xi.affinityAutopop.applyName then
                mob:addListener('SPAWN', 'AFFINITY_NAME', function(m)
                    xi.affinityAutopop.applyName(m)
                end)
                if mob:isSpawned() then xi.affinityAutopop.applyName(mob) end
            end
            -- Sky gods: re-open the island yellow portal their retail onMobSpawn
            -- closes -- always-up gods otherwise lock the islands permanently.
            if xi.affinityAutopop and xi.affinityAutopop.openGodPortal then
                mob:addListener('SPAWN', 'AFFINITY_PORTAL', function(m)
                    xi.affinityAutopop.openGodPortal(m)
                end)
                if mob:isSpawned() then xi.affinityAutopop.openGodPortal(mob) end
            end
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
