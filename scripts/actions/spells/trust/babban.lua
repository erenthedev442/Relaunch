-----------------------------------
-- Trust: Babban Mheillea
-- MNK plantoid. No JAs. Wild Oats / Head Butt / Photosynthesis / Petal Pirouette.
-- HP-10% (pool) + large non-humanoid HP. Guard/Counter. RANDOM TP, no skillchains.
-- Photosynthesis daytime-only via mobskill check. Mandragora gear for dialogue.
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

    -- Large HP pool common to non-humanoids (on top of C bruiser + pool HPP-10%).
    mob:addMod(xi.mod.HP, xi.trust.modGrowthValMax(mob, 600))
    -- MNK Guard / Counter feel (traits; reinforce so plantoid MS kit still tanks hits).
    mob:addMod(xi.mod.GUARD_PERCENT, 15)
    mob:addMod(xi.mod.COUNTER, 12)

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
