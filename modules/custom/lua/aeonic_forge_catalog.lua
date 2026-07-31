-----------------------------------
-- Aeonic Forge final-form catalog
-----------------------------------

local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

local C =
{
    currencyKey  = 'escha_silt',
    currencyName = 'Escha Silt',
    cost         = 50000,
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

return C
