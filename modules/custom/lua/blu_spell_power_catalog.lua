-----------------------------------
-- BLU spell-tax: weapon amp share + MP/set-point premiums.
--
-- Cheap spells (Foot Kick) only get a slice of the 9x-105x weapon table.
-- 8-point and high-MP spells keep the full weapon boost.
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

-- Canonical set points from blue_spell_list (plus Restoral 7 from the repair).
catalog.SET_POINTS =
{
    [513] = 3, [515] = 5, [517] = 1, [519] = 3, [521] = 4, [522] = 2,
    [524] = 2, [527] = 3, [529] = 2, [530] = 4, [531] = 3, [532] = 4,
    [533] = 3, [534] = 4, [535] = 1, [536] = 1, [537] = 2, [538] = 4,
    [539] = 3, [540] = 4, [541] = 2, [542] = 2, [543] = 2, [544] = 2,
    [545] = 4, [547] = 1, [548] = 3, [549] = 1, [551] = 1, [554] = 5,
    [555] = 3, [557] = 4, [560] = 3, [561] = 3, [563] = 3, [564] = 4,
    [565] = 4, [567] = 2, [569] = 4, [570] = 2, [572] = 1, [573] = 3,
    [574] = 2, [575] = 4, [576] = 3, [577] = 2, [578] = 3, [579] = 4,
    [581] = 4, [582] = 2, [584] = 2, [585] = 4, [587] = 2, [588] = 2,
    [589] = 5, [591] = 4, [592] = 2, [593] = 3, [594] = 3, [595] = 5,
    [596] = 2, [597] = 2, [598] = 4, [599] = 2, [603] = 3, [604] = 5,
    [605] = 3, [606] = 2, [608] = 3, [610] = 4, [611] = 5, [612] = 4,
    [613] = 5, [614] = 3, [615] = 5, [616] = 5, [617] = 3, [618] = 2,
    [620] = 3, [621] = 2, [622] = 2, [623] = 3, [626] = 3, [628] = 3,
    [629] = 3, [631] = 3, [632] = 3, [633] = 5, [634] = 5, [636] = 4,
    [637] = 5, [638] = 3, [640] = 4, [641] = 5, [642] = 3, [643] = 3,
    [644] = 4, [645] = 4, [646] = 4, [647] = 2, [648] = 1, [650] = 2,
    [651] = 4, [652] = 3, [653] = 2, [654] = 4, [655] = 3, [656] = 3,
    [657] = 3, [658] = 4, [659] = 4, [660] = 3, [661] = 5, [662] = 3,
    [663] = 4, [664] = 2, [665] = 1, [666] = 3, [667] = 2, [668] = 3,
    [669] = 2, [670] = 4, [671] = 4, [672] = 5, [673] = 4, [674] = 1,
    [675] = 3, [677] = 3, [678] = 3, [679] = 3, [680] = 4, [681] = 5,
    [682] = 2, [683] = 4, [684] = 4, [685] = 3, [686] = 4, [687] = 2,
    [688] = 2, [689] = 3, [690] = 5, [692] = 4, [693] = 5, [694] = 3,
    [695] = 4, [696] = 5, [697] = 4, [698] = 2, [699] = 2, [700] = 6,
    [701] = 6, [702] = 6, [703] = 6, [704] = 6, [705] = 4, [706] = 2,
    [707] = 5, [708] = 6, [709] = 7, [710] = 6, [711] = 7, [712] = 6,
    [713] = 6, [714] = 6, [715] = 6, [716] = 6, [717] = 6, [719] = 8,
    [720] = 8, [721] = 8, [722] = 8, [723] = 7, [724] = 7, [725] = 8,
    [726] = 8, [727] = 8, [728] = 8,
}

catalog.FACTOR_FULL     = 1.00
catalog.FACTOR_HIGH     = 0.45
catalog.FACTOR_MID      = 0.20
catalog.FACTOR_CHEAP    = 0.06

local function factorFromPoints(points)
    if points >= 8 then
        return catalog.FACTOR_FULL
    elseif points >= 6 then
        return catalog.FACTOR_HIGH
    elseif points >= 4 then
        return catalog.FACTOR_MID
    end

    return catalog.FACTOR_CHEAP
end

local function factorFromMP(mpCost)
    if mpCost >= 150 then
        return catalog.FACTOR_FULL
    elseif mpCost >= 100 then
        return catalog.FACTOR_HIGH
    elseif mpCost >= 50 then
        return catalog.FACTOR_MID
    end

    return catalog.FACTOR_CHEAP
end

function catalog.getSetPoints(spell)
    if spell.getSetPoints then
        local live = spell:getSetPoints()
        if live and live > 0 then
            return live
        end
    end

    return catalog.SET_POINTS[spell:getID()] or 0
end

function catalog.getSpellFactor(spell)
    if catalog.PREMIUM_SPELLS[spell:getID()] then
        return catalog.FACTOR_FULL
    end

    local mpCost = spell:getMPCost() or 0
    local points = catalog.getSetPoints(spell)
    return math.max(factorFromPoints(points), factorFromMP(mpCost))
end

function catalog.getEffectiveWeaponMultiplier(weaponMultiplier, spell)
    local factor = catalog.getSpellFactor(spell)
    return 1 + (weaponMultiplier - 1) * factor
end

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
