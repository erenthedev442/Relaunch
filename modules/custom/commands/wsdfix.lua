-----------------------------------
-- func: wsdfix
-- desc: GM one-shot, NO-RESTART hotpatch. Injects the restored "Weapon skill
--       damage" catalyst (High-Quality Scorpion Shell, item 1473 -> augId 327)
--       into the LIVE augment catalog table in memory, so the Augment Moogle
--       offers it again without a map restart.
--
-- Why this works: Augment_Moogle.lua does `local catalog = require(...)` once at
-- boot, and the Moogle NPC's onTrade reads catalog[itemId] from that upvalue.
-- require() returns the SAME table object, so mutating it in place here is seen
-- immediately by the already-inserted NPC -- no zone re-init, no restart.
--
-- Idempotent. Throwaway: the committed augment_catalog.lua makes this permanent
-- at the next real deploy/restart, after which this file can be deleted.
-- Lives in modules/custom/commands/ -> auto-registers (hot-loads) as !wsdfix.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1, -- GM only
    parameters = '',
}

commandObj.onTrigger = function(player)
    local catalog = require('modules/custom/lua/augment_catalog')
    catalog[1473] = { augId = 327, base = 1, mult = 1, disp = 1, cat = 13, label = 'Weapon skill damage' }

    local ok = catalog[1473] ~= nil and catalog[1473].augId == 327
    player:printToPlayer(string.format(
        '[wsdfix] HQ Scorpion Shell (1473) -> Weapon skill damage (327): %s',
        ok and 'LIVE' or 'FAILED'), xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '[wsdfix] Trade a High-Quality Scorpion Shell to the Augment Moogle to confirm.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
