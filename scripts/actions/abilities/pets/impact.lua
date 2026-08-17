-----------------------------------
-- Impact
-- Family: Fenrir (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

local statDownEffects =
{
    xi.effect.STR_DOWN,
    xi.effect.DEX_DOWN,
    xi.effect.VIT_DOWN,
    xi.effect.AGI_DOWN,
    xi.effect.INT_DOWN,
    xi.effect.MND_DOWN,
    xi.effect.CHR_DOWN,
}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local params = {}

    params.baseDamage      = pet:getMainLvl() + 2
    params.fTP             = { 5.3570, 8.0273, 10.7031 }
    params.dex_wSC         = 0.15
    params.chr_wSC         = 0.15
    params.element         = xi.element.DARK
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.DARK
    params.shadowBehavior  = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.dStatMultiplier = 1.5
    params.canMagicBurst   = true
    params.primaryMessage  = xi.msg.basic.USES_JA_TAKE_DAMAGE

    local info = xi.mobskills.mobMagicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)

        local potency = math.max(1, math.floor(summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) / 20))
        for _, effect in ipairs(statDownEffects) do
            xi.mobskills.mobStatusEffectMove(pet, target, effect, potency, 0, 180)
        end
    end

    return info.damage
end

return abilityObject
