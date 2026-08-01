-----------------------------------
-- func: buff
-- desc: Grants the zone-appropriate regional buff (Signet / Sanction /
--       Sigil / Ionis) plus Refresh, Regen, Regain, Composure, and
--       Reraise III to the player.
--       Refresh = 10% of max MP per tick below 99; flat +10 MP/tick at 99+
--       Regen   = 10% of max HP per tick below 99; 3.5% at 99+ (35% of original)
--       Regain  = scales with player level (1 per 10 levels, min 1)
--       Reraise = tier III (power 3, highest HP restored on death)
--       Potency rules live in modules/custom/lua/buff_sustain.lua.
--
--       Regional buff is chosen from the player's current region:
--         Vana'diel conquest regions (0..22)   -> Signet
--         Aht Urhgan       regions (28..32)    -> Sanction
--         WotG past-era    regions (33..40)    -> Sigil
--         Adoulin          regions (44..45)    -> Ionis
--         Anywhere else (instanced/Abyssea)    -> Signet (safe fallback)
-----------------------------------
---@type TCommand
local commandObj = {}
local sustain = require('modules/custom/lua/buff_sustain')

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's'
}

commandObj.onTrigger = function(player, target)
    local targ

    if target ~= nil then
        targ = GetPlayerByName(target)
        if targ == nil then
            player:printToPlayer(string.format('Player "%s" not found.', target))
            return
        end
    else
        targ = player
    end

    local regionalName, refreshPower, regenPower, regainPower = sustain.apply(targ, player)

    local sustainMsg = string.format('Regen: %d/tick | Refresh: %d/tick | ', regenPower, refreshPower)
    targ:printToPlayer(string.format(
        'Buffs applied! %s | %sRegain: %d/tick | Composure | Reraise III | Duration: 5 hours',
        regionalName, sustainMsg, regainPower
    ))
end

return commandObj
