-----------------------------------
-- Zantetsuken
-- Family: Odin (Player Pet)
-- Odin automatically performs this once after being summoned, consumes all of
-- the summoner's MP and Astral Flow, then despawns.
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0, 0
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    local damage = 0
    if target:getAnimation() ~= 33 then
        local remainingHP = target:getHP()
        damage = remainingHP > 2000000 and 1999999 or remainingHP
        petskill:setMsg(xi.msg.basic.USES_JA_TAKE_DAMAGE)
        damage = target:takeDamage(damage, pet, xi.attackType.MAGICAL, xi.damageType.DARK,
            { wakeUp = true, breakBind = true, bypassGlobalHpDamageCap = true })
    end

    -- AoE processing invokes this once per target. Consume resources and
    -- schedule dismissal exactly once, on the primary target.
    if summoner and target:getID() == action:getPrimaryTargetID() then
        summoner:setMP(0)
        summoner:delStatusEffect(xi.effect.ASTRAL_FLOW)
        pet:timer(1500, function()
            local activePet = summoner:getPet()
            if activePet and activePet:getID() == pet:getID() then
                summoner:despawnPet()
            end
        end)
    end

    return damage
end

return abilityObject
