-----------------------------------
-- BLU spell-cost damage premiums.
--
-- The weapon catalog supplies the ordinary-geared 9x baseline. This catalog
-- makes expensive and high-set-point spells scale above that baseline once,
-- without changing each spell's stock stat, resist, or MAB relationships.
-----------------------------------

local catalog = {}

-- The elemental endgame suite costs eight Blue Magic points. Keep this list
-- explicit so its premium remains stable even if live SQL is awaiting repair.
catalog.PREMIUM_SPELLS =
{
    [719] = true, -- Searing Tempest
    [720] = true, -- Spectral Floe
    [721] = true, -- Anvil Lightning
    [722] = true, -- Entomb
    [725] = true, -- Blinding Fulgor
    [726] = true, -- Scouring Spate
    [727] = true, -- Silent Storm
    [728] = true, -- Tenebral Crush
}

function catalog.getDamageMultiplier(spell)
    if catalog.PREMIUM_SPELLS[spell:getID()] then
        return 5 / 3
    end

    local mpCost = spell:getMPCost() or 0
    if mpCost >= 150 then
        return 5 / 3
    elseif mpCost >= 100 then
        return 1.5
    elseif mpCost >= 50 then
        return 1.2
    end

    return 1
end

return catalog
