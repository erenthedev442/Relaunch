-----------------------------------
-- Trust: Cornelia
-- Spell ID: 1003  |  Pool ID: 6003
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    mob:setModelId(3119)
    mob:renameEntity('Cornelia', true)

    local master = mob:getMaster()
    local boostAmount = math.ceil((30 / 99) * (master:getMainLvl() or 1))

    mob:addStatusEffect(xi.effect.GEO_HASTE, {
        power = 6, tick = 3, origin = mob, subType = xi.effect.GEO_HASTE,
        subPower = boostAmount, tier = xi.auraTarget.ALLIES, flag = xi.effectFlag.AURA,
    })
    mob:addStatusEffect(xi.effect.GEO_ACCURACY_BOOST, {
        power = 6, tick = 3, origin = mob, subType = xi.effect.GEO_ACCURACY_BOOST,
        subPower = boostAmount, tier = xi.auraTarget.ALLIES, flag = xi.effectFlag.AURA,
    })
    mob:addStatusEffect(xi.effect.GEO_MAGIC_ACC_BOOST, {
        power = 6, tick = 3, origin = mob, subType = xi.effect.GEO_MAGIC_ACC_BOOST,
        subPower = boostAmount, tier = xi.auraTarget.ALLIES, flag = xi.effectFlag.AURA,
    })

    mob:setAutoAttackEnabled(false)
    mob:setUnkillable(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    master:printToPlayer('Cornelia, at your service.', xi.msg.channel.PARTY, 'Cornelia')
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if master then
        master:printToPlayer('Remember: never give up!', xi.msg.channel.PARTY, 'Cornelia')
    end
end

spellObject.onMobDeath = function(mob)
end

return spellObject
