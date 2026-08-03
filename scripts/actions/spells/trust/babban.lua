-----------------------------------
-- Trust: Babban Mheillea
-- MNK plantoid — Wild Oats / Head Butt / Petal Pirouette ASAP (no JAs).
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

    -- Retail: uses TP randomly, does not skillchain.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
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
