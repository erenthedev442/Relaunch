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
local catalog = require('modules/custom/lua/affinity_nm_catalog')

commandObj.cmdprops =
{
    permission = 5, -- GM level 5 only
    parameters = '',
}

commandObj.onTrigger = function(player)
    local SYS = xi.msg.channel.SYSTEM_3
    local up, missing = 0, 0

    if not xi.affinityAutopop or not xi.affinityAutopop.configureMob then
        player:printToPlayer('[Affinity] Autopop module is not loaded.', SYS)
        return
    end

    for _, entry in ipairs(catalog.entries) do
        if xi.affinityAutopop.configureMob(entry.mobId) then
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
