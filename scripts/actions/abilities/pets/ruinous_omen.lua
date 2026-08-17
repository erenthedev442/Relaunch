-----------------------------------
-- Ruinous Omen
-- Family: Diabolos (Player Pet)
-- Astral Flow Blood Pact
-----------------------------------
---@type TAbilityPet
local abilityObject = {}
local avatarProgression = require('modules/custom/lua/smn_avatar_equalize')

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local hpPercent = math.random(10, 90) / 100
    local damageCap = math.max(0, target:getHP() - 1)
    if target:isNM() then
        hpPercent = math.min(hpPercent, 0.10)
        damageCap = math.min(damageCap, math.floor(target:getHP() * 0.10))
    end

    local params = {}

    params.baseDamage     = math.max(1, math.floor(target:getHP() * hpPercent))
    params.fTP            = { 1.0, 1.0, 1.0 }
    params.element        = xi.element.DARK
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.DARK
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.canMagicBurst  = true
    params.primaryMessage = xi.msg.basic.USES_JA_TAKE_DAMAGE

    local info = xi.mobskills.mobMagicalMove(pet, target, petskill, action, params)

    -- Apply shared progression exactly once, then enforce this pact's stricter
    -- leave-at-1/NM ceiling before native mitigation, enmity and reporting.
    info.damage = math.min(
        avatarProgression.scaleDamage(pet, target, petskill, info.damage),
        damageCap)
    local damageApplied = avatarProgression.processDamageWithoutProgression(
        pet, target, petskill, action, info)

    if damageApplied then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)
    end

    if target:getID() == action:getPrimaryTargetID() then
        summoner:setMP(0)
    end

    return info.damage
end

return abilityObject
