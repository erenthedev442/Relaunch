-----------------------------------
-- Trust: Abenzio
-- MNK/WAR Goobbue. No spells / no JAs.
-- WS: Blow (stun), Uppercut, Antiphase (AoE silence), Blank Gaze (conal paralysis).
-- HP+20%. Plantoid family (intimidates beasts, intimidated by vermin).
-- Kick Attacks via arm vines (no kick anim). Uses TP randomly; no skillchains.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local isWearingMandragoraGear = function(player)
    local wearingHead = player:getEquipID(xi.slot.HEAD) == 26705 or player:getEquipID(xi.slot.HEAD) == 26706
    local wearingBody = player:getEquipID(xi.slot.BODY) == 27854 or player:getEquipID(xi.slot.BODY) == 27855
    return wearingHead and wearingBody
end

spellObject.onMobSpawn = function(mob)
    local master = mob:getMaster()
    if isWearingMandragoraGear(master) then
        xi.trust.message(mob, xi.trust.messageOffset.SPAWN)
    end

    mob:addMod(xi.mod.HPP, 20)
    -- MNK Kick Attacks (Goobbue uses arm-vine kick anim).
    mob:addMod(xi.mod.KICK_ATTACK_RATE, 20)
    -- Monstrous Max HP Boost feel on top of C bruiser package.
    mob:addMod(xi.mod.HP, xi.trust.modGrowthValMax(mob, 500))

    -- Uses TP randomly; does not try to skillchain.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)
end

spellObject.onMobDespawn = function(mob)
    local master = mob:getMaster()
    if isWearingMandragoraGear(master) then
        xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
    end
end

spellObject.onMobDeath = function(mob)
    local master = mob:getMaster()
    if isWearingMandragoraGear(master) then
        xi.trust.message(mob, xi.trust.messageOffset.DEATH)
    end
end

return spellObject
