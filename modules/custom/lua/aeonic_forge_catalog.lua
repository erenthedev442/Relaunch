-----------------------------------
-- Aeonic Forge final-form catalog
-----------------------------------

local weaponForge = require('modules/custom/lua/weapon_forge_catalog')
local aeonicMaat  = require('modules/custom/lua/aeonic_maat_catalog')
local repeatCredits = require('modules/custom/lua/rema_repeat_credits')

local C =
{
    currencyKey  = 'escha_silt',
    currencyName = 'Escha Silt',
    cost         = 100000,
    weapons      = {},
}

for _, chain in ipairs(weaponForge.chains) do
    C.weapons[#C.weapons + 1] =
    {
        id   = chain.aeonic.s3.id,
        name = chain.aeonic.s3.name,
        info = string.format('%s Aeonic weapon. Jobs: %s.', chain.type, chain.jobs),
    }
end

-- Shield and instrument have no WS pilgrimage or Maat trial. Same
-- first-Aeonic unlock as the damage repeats; Relic/Empyrean already treat
-- Aegis/Ochain and Gjallarhorn/Daurdabla this way.
C.weapons[#C.weapons + 1] =
{
    id   = 26403,
    name = 'Srivatsa',
    info = 'Aeonic shield. Jobs: PLD.',
}

C.weapons[#C.weapons + 1] =
{
    id   = 21398,
    name = 'Marsyas',
    info = 'Aeonic wind instrument. Jobs: BRD.',
}

function C.canRepeat(player, finalId)
    if (player:getCharVar('WF_Aeonic_Final') or 0) ~= 1 then
        return false, 'first_aeonic'
    end
    if repeatCredits.available(player, 'aeonic') <= 0 then
        return false, 'no_credit'
    end
    if not aeonicMaat.byFinalId[finalId] then
        return true, nil
    end
    if not aeonicMaat.isComplete(player, finalId) then
        return false, 'maat'
    end
    return true, nil
end

return C
