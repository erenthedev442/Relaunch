-----------------------------------
-- Mythic Forge final-form catalog
-----------------------------------

local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

local C =
{
    currencyId   = weaponForge.forgeMats.beitetsu,
    currencyName = 'Beitetsu',
    cost         = 3500,
    weapons      = {},
}

for _, chain in ipairs(weaponForge.mythicChains) do
    C.weapons[#C.weapons + 1] =
    {
        id   = chain.s3,
        name = chain.name,
        info = string.format('%s mythic weapon. Jobs: %s.', chain.type, chain.jobs),
    }
end

return C
