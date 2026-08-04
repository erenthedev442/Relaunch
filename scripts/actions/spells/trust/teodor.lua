-----------------------------------
-- Trust: Teodor
-- BLM/DRK. Unique WS + special cane AA (slash / dark / silence).
-- HP+35%, MP+50%. No curative healing (CURE_POTENCY_RCVD -100).
-- MB-only nukes (-ga/-ja). RANDOM TP; no skillchains.
-- Start from Scratch @<50% → dark aura → Hemocladis @2000 TP.
-- S-tier hybrid (apex) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SCRATCH    = 3631
local MS_HEMOCLADIS = 3636
local AA_SKILL_LIST = 2101

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

local function applyTpSettings(mob, hasAura)
    if hasAura then
        -- Hold random WS; script fires Hemocladis at 2000.
        mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
    else
        mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MORIMAR] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:addMod(xi.mod.HPP, 35)
    mob:addMod(xi.mod.MPP, 50)
    -- Curative magic (Cure/Curaga) does nothing; Regen / BLU / BPs still work.
    mob:addMod(xi.mod.CURE_POTENCY_RCVD, -100)
    mob:addImmunity(xi.immunity.ASPIR)
    -- Special AA ignores Slow (does not benefit from Haste/Sambas either).
    mob:addImmunity(xi.immunity.SLOW)

    mob:setMobSkillAttack(AA_SKILL_LIST)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Retail: elemental magic only to magic burst (-ga/-ja list).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    mob:setLocalVar('teoAura', 0)
    mob:setLocalVar('teoScratch', 0)
    mob:setLocalVar('teoWsLock', 0)
    applyTpSettings(mob, false)

    mob:addListener('COMBAT_TICK', 'TEODOR_AI', function(mobArg)
        local hasAura = mobArg:getLocalVar('teoAura') ~= 0
        applyTpSettings(mobArg, hasAura)

        -- Start from Scratch under 50% (needs TP to consume).
        if
            not hasAura and
            canAct(mobArg) and
            mobArg:getHPP() < 50 and
            mobArg:getTP() >= 1000
        then
            mobArg:setLocalVar('teoScratch', 1)
            mobArg:useMobAbility(MS_SCRATCH, mobArg)
            return
        end

        -- Aura: build to 2000 and Hemocladis.
        if
            hasAura and
            mobArg:getTP() >= 2000 and
            mobArg:getLocalVar('teoWsLock') == 0 and
            canAct(mobArg)
        then
            local battleTarget = mobArg:getTarget()
            if battleTarget and battleTarget:isAlive() then
                mobArg:setLocalVar('teoWsLock', 1)
                mobArg:useMobAbility(MS_HEMOCLADIS, battleTarget)
            end
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'TEODOR_WS', function(mobArg, target, skill, tp, action, damage)
        mobArg:setLocalVar('teoWsLock', 0)

        if skill:getID() == MS_HEMOCLADIS then
            if math.random(1, 100) <= 33 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
