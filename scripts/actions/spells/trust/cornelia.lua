-----------------------------------
-- Trust: Cornelia
-- Spell ID: 1002 | Pool ID: 6002
-- GEO/BRD incorporeal aura. Indi-Haste visual + Haste 20%, Acc/RAcc +30,
-- MAcc +30 at 99 (level-scaled). Untargetable / unkillable / no AA / no WS.
-- S-tier aura — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Indi visual: WIND allies (Indi-Haste).
local INDI_HASTE_VISUAL = 2

local function scaleStat(lvl, at99)
    return math.max(1, math.floor(at99 * lvl / 99 + 0.5))
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    mob:renameEntity('Cornelia', true)

    local master = mob:getMaster()
    local lvl = (master and master:getMainLvl()) or mob:getMainLvl() or 1

    -- HASTE_MAGIC is 10000-base (2000 = 20%). Acc aura also grants RACC.
    local hastePower = scaleStat(lvl, 2000)
    local accPower   = scaleStat(lvl, 30)
    local maccPower  = scaleStat(lvl, 30)

    -- Only Haste icon shows; Acc / RAcc / MAcc still apply (retail).
    mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
        power = INDI_HASTE_VISUAL,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_HASTE,
        subPower = hastePower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })
    mob:addStatusEffect(xi.effect.GEO_ACCURACY_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_ACCURACY_BOOST,
        subPower = accPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })
    mob:addStatusEffect(xi.effect.GEO_MAGIC_ACC_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_MAGIC_ACC_BOOST,
        subPower = maccPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    -- Incorporeal: cannot die, ignore all damage types.
    mob:setUnkillable(true)
    mob:setMod(xi.mod.UDMGPHYS, -10000)
    mob:setMod(xi.mod.UDMGRANGE, -10000)
    mob:setMod(xi.mod.UDMGMAGIC, -10000)
    mob:setMod(xi.mod.UDMGBREATH, -10000)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    if master then
        master:printToPlayer('Cornelia, at your service.', xi.msg.channel.PARTY, 'Cornelia')
    end
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if master then
        master:printToPlayer('Remember: never give up!', xi.msg.channel.PARTY, 'Cornelia')
    end
end

spellObject.onMobDeath = function(mob)
    -- Incorporeal — should not fire.
end

return spellObject
