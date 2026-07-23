-----------------------------------
-- Empyrean Forge final-form catalog
-----------------------------------

local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

local C =
{
    currencyId   = 4061,
    currencyName = 'Riftborn Boulder',
    cost         = 1000,
    weapons      = {},
}

for _, chain in ipairs(weaponForge.empyreanChains) do
    C.weapons[#C.weapons + 1] =
    {
        id   = chain.s3,
        name = chain.name,
        info = string.format('%s Empyrean weapon. Jobs: %s.', chain.type, chain.jobs),
    }
end

C.weapons[#C.weapons + 1] =
{
    id   = 11926,
    name = 'Ochain',
    info = 'Empyrean shield. Jobs: PLD.',
}

C.weapons[#C.weapons + 1] =
{
    id   = 21398,
    name = 'Marsyas',
    info = 'Aeonic wind instrument. Jobs: BRD.',
}

return C
