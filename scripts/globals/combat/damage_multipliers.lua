-----------------------------------
xi = xi or {}
xi.combat = xi.combat or {}
xi.combat.damage = xi.combat.damage or {}
-----------------------------------
-- Augment PDT-II / MDT-II is 1% per piece (one line, like Treasure Hunter).
-- Ten pieces = 10%. Extra slots cannot push past that. Unique weapons
-- (Burtgang / Epeolatry / Aegis) keep their own II on top.
xi.combat.damage.AUGMENT_DT_II_CAP = 0.10
xi.combat.damage.AUGMENT_DT_II_RAW = 1000

-- Native II on unique weapons. Keep in lockstep with sql/item_mods.sql.
xi.combat.damage.UNIQUE_PDT_II =
{
    [18997] = -1000, [19066] = -1200, [19086] = -1400,
    [19618] = -1600, [19716] = -1600,
    [19825] = -1800, [19954] = -1800, [20649] = -1800,
    [20650] = -1800, [20687] = -1800,
    [21685] = -2500,
}
xi.combat.damage.UNIQUE_MDT_II =
{
    [15070] = -2500,
    [16195] = -3000, [16196] = -3500, [16197] = -4000,
    [16198] = -4500, [16200] = -5000,
    [11927] = -5000,
}

xi.combat.damage.equippedUniqueII = function(target, uniqueMap)
    local sum = 0
    if not target or not target.getEquipID then
        return 0
    end

    for slot = 0, 15 do
        local ok, itemId = pcall(target.getEquipID, target, slot)
        if ok and itemId and uniqueMap[itemId] then
            sum = sum + uniqueMap[itemId]
        end
    end

    return sum
end

xi.combat.damage.cappedAugmentII = function(totalRaw, uniqueRaw)
    local augRaw = (totalRaw or 0) - (uniqueRaw or 0)
    if augRaw < -xi.combat.damage.AUGMENT_DT_II_RAW then
        augRaw = -xi.combat.damage.AUGMENT_DT_II_RAW
    elseif augRaw > 0 then
        augRaw = 0
    end

    return ((uniqueRaw or 0) + augRaw) / 10000
end
-----------------------------------

xi.combat.damage.physicalElementSDT = function(target, physicalElement)
    if
        physicalElement < xi.damageType.PIERCING or
        physicalElement > xi.damageType.HTH
    then
        return 1
    end

    local physicalElementSDTModifier =
    {
        [xi.damageType.PIERCING] = xi.mod.PIERCE_SDT,
        [xi.damageType.SLASHING] = xi.mod.SLASH_SDT,
        [xi.damageType.BLUNT   ] = xi.mod.IMPACT_SDT,
        [xi.damageType.HTH     ] = xi.mod.HTH_SDT,
    }

    local sdt = 1 + target:getMod(physicalElementSDTModifier[physicalElement]) / 10000

    return utils.clamp(sdt, 0, 3)
end

xi.combat.damage.magicalElementSDT = function(target, magicalElement)
    if
        magicalElement < xi.element.FIRE or
        magicalElement > xi.element.DARK
    then
        return 1
    end

    local sdt = 1 + target:getMod(xi.data.element.getElementalSDTModifier(magicalElement)) / 10000

    return utils.clamp(sdt, 0, 3)
end

xi.combat.damage.calculateDamageAdjustment = function(target, isPhysical, isMagical, isRanged, isBreath)
    -- NOTE: -2500 -> 25% less damage taken by target. 2500 -> 25% more damage taken  by target.
    local targetDamageTaken = 1

    -- "Damage Taken -x%"
    local globalDamageTaken           = target:getMod(xi.mod.DMG) / 10000

    -- "Physical Damage Taken -X%", "Physical Damage Taken II -X%"
    local physicalDamageTaken         = isPhysical and target:getMod(xi.mod.DMGPHYS) / 10000 or 0
    local physicalDamageTakenII       = isPhysical and xi.combat.damage.cappedAugmentII(
        target:getMod(xi.mod.DMGPHYS_II),
        xi.combat.damage.equippedUniqueII(target, xi.combat.damage.UNIQUE_PDT_II)) or 0
    local physicalDamageTakenUncapped = isPhysical and target:getMod(xi.mod.UDMGPHYS) / 10000 or 0

    -- "Magic Damage Taken -X%", "Magic Damage Taken II -X%"
    local magicDamageTaken            = isMagical and target:getMod(xi.mod.DMGMAGIC) / 10000 or 0
    local magicDamageTakenII          = isMagical and xi.combat.damage.cappedAugmentII(
        target:getMod(xi.mod.DMGMAGIC_II),
        xi.combat.damage.equippedUniqueII(target, xi.combat.damage.UNIQUE_MDT_II)) or 0
    local magicDamageTakenUncapped    = isMagical and target:getMod(xi.mod.UDMGMAGIC) / 10000 or 0

    -- "Ranged Damage Taken -X%" (Doesn't actually exist in gear. Physical damage taken has both.)
    local rangedDamageTaken           = isRanged and target:getMod(xi.mod.DMGRANGE) / 10000 or 0
    local rangedDamageTakenUncapped   = isRanged and target:getMod(xi.mod.UDMGRANGE) / 10000 or 0

    -- "Breath Damage Taken -X%"
    local breathDamageTaken           = isBreath and target:getMod(xi.mod.DMGBREATH) / 10000 or 0
    local breathDamageTakenUncapped   = isBreath and target:getMod(xi.mod.UDMGBREATH) / 10000 or 0

     -- The combination of regular "Damage Taken" and "<type> Damage Taken" caps at 50% both ways.
    local combinedDamageTaken = utils.clamp(globalDamageTaken + physicalDamageTaken + magicDamageTaken + rangedDamageTaken + breathDamageTaken, -0.5, 0.5)

    -- "<type> Damage Taken II" bypasses the regular cap. Unique weapons keep
    -- their full II; augment II is already clamped to 10% above.
    targetDamageTaken = utils.clamp(targetDamageTaken + combinedDamageTaken + physicalDamageTakenII + magicDamageTakenII, 0.125, 1.875)

     -- Uncapped damage modifiers. Cap is 100% both ways anyway, just in case.
    targetDamageTaken = utils.clamp(targetDamageTaken + physicalDamageTakenUncapped + magicDamageTakenUncapped + rangedDamageTakenUncapped + breathDamageTakenUncapped, 0, 2)

    -- Player-cast Pyric Bulwark marks its shield with subPower 255. Consume that
    -- shield only after its modifiers have protected this physical damage event.
    if isPhysical then
        local physicalShield = target:getStatusEffect(xi.effect.PHYSICAL_SHIELD)
        if
            physicalShield and
            physicalShield:getPower() == 1 and
            physicalShield:getSubPower() == 255
        then
            target:delStatusEffectSilent(xi.effect.PHYSICAL_SHIELD)
        end
    end

    return targetDamageTaken
end

xi.combat.damage.scarletDeliriumMultiplier = function(actor)
    -- Scarlet delirium are 2 different status effects. SCARLET_DELIRIUM_1 is the one that boosts power.
    if not actor:hasStatusEffect(xi.effect.SCARLET_DELIRIUM_1) then
        return 1
    end

    local scarletDeliriumMultiplier = 1 + actor:getStatusEffect(xi.effect.SCARLET_DELIRIUM_1):getPower() / 1000

    return scarletDeliriumMultiplier
end
