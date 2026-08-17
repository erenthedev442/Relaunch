-----------------------------------
-- Pavor Nocturnus
-- Family: Diabolos (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local isAsleep =
        target:hasStatusEffect(xi.effect.SLEEP_I) or
        target:hasStatusEffect(xi.effect.SLEEP_II) or
        target:hasStatusEffect(xi.effect.LULLABY)
    local deathChance = 1

    if isAsleep then
        deathChance = utils.clamp(90 - math.max(0, target:getMainLvl() - pet:getMainLvl()) * 10, 5, 90)
    end

    if
        not target:isNM() and
        target:getAnimation() ~= 33 and
        math.random(1, 100) <= deathChance
    then
        local damage = target:getHP()

        petskill:setMsg(xi.msg.basic.SKILL_ENFEEB_IS)
        target:takeDamage(damage, pet, xi.attackType.MAGICAL, xi.damageType.DARK,
            { wakeUp = true, breakBind = true, bypassGlobalHpDamageCap = true })

        return damage
    end

    local effect = target:dispelStatusEffect()
    if effect ~= xi.effect.NONE then
        petskill:setMsg(xi.msg.basic.MAGIC_ERASE)
        return effect
    end

    petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    return xi.effect.NONE
end

return abilityObject
