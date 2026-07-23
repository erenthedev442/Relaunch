-----------------------------------
-- Final Ambuscade weapon / linked weaponskill tuning
-----------------------------------

local catalog =
{
    DAMAGE_CAP             = 99999,
    DAMAGE_MULTIPLIER      = 110,
    DAMAGE_CAP_LOCAL_VAR   = 'AmbuscadeWsDamageCap',
    DAMAGE_MULT_LOCAL_VAR  = 'AmbuscadeWsDamageMultiplier',
    BY_WS                   = {},
}

local entries =
{
    { itemId = 21519, wsId = xi.weaponskill.ASURAN_FISTS,   slot = xi.slot.MAIN,   name = 'Karambit' },
    { itemId = 21565, wsId = xi.weaponskill.EVISCERATION,   slot = xi.slot.MAIN,   name = 'Tauret' },
    { itemId = 21621, wsId = xi.weaponskill.SAVAGE_BLADE,   slot = xi.slot.MAIN,   name = 'Naegling' },
    { itemId = 21674, wsId = xi.weaponskill.GROUND_STRIKE,  slot = xi.slot.MAIN,   name = 'Nandaka' },
    { itemId = 21722, wsId = xi.weaponskill.DECIMATION,     slot = xi.slot.MAIN,   name = 'Dolichenus' },
    { itemId = 21779, wsId = xi.weaponskill.STEEL_CYCLONE,  slot = xi.slot.MAIN,   name = 'Lycurgos' },
    { itemId = 21830, wsId = xi.weaponskill.SPIRAL_HELL,    slot = xi.slot.MAIN,   name = 'Drepanum' },
    { itemId = 21883, wsId = xi.weaponskill.IMPULSE_DRIVE,  slot = xi.slot.MAIN,   name = 'Shining One' },
    { itemId = 21922, wsId = xi.weaponskill.BLADE_KU,       slot = xi.slot.MAIN,   name = 'Gokotai' },
    { itemId = 21975, wsId = xi.weaponskill.TACHI_KASHA,    slot = xi.slot.MAIN,   name = 'Hachimonji' },
    { itemId = 22031, wsId = xi.weaponskill.BLACK_HALO,     slot = xi.slot.MAIN,   name = 'Maxentius' },
    { itemId = 22086, wsId = xi.weaponskill.RETRIBUTION,    slot = xi.slot.MAIN,   name = 'Xoanon' },
    { itemId = 22107, wsId = xi.weaponskill.EMPYREAL_ARROW, slot = xi.slot.RANGED, name = 'Ullr' },
}

for _, entry in ipairs(entries) do
    catalog.BY_WS[entry.wsId] = entry
end

catalog.entries = entries

catalog.getEntry = function(itemId, wsId, slot)
    local entry = catalog.BY_WS[wsId]
    if entry and entry.itemId == itemId and entry.slot == slot then
        return entry
    end

    return nil
end

return catalog
