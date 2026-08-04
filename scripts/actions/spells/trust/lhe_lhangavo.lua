-----------------------------------
-- Trust: Lhe Lhangavo
-- MNK/WAR. Hand-to-Hand.
-- Abilities: Dodge (top enmity), Chakra (+Invigorate Regen), Impetus,
--   Focus (when ACC soft), Formless Strikes (phys-resistant ecosystems),
--   Provoke (master <50% HP).
-- WS: Backhand Blow / Raging Fists / Dragon Kick / Asuran Fists.
-- Holds TP until 2000 to close skillchains (RANDOM).
-- S-tier melee_dd (bruiser) power path — no kit inject (custom CLOSER AI).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_FOCUS    = 36
local RECAST_FORMLESS = 152

local function isPhysResistantEco(eco)
    return eco == xi.ecosystem.AMORPH
        or eco == xi.ecosystem.ELEMENTAL
        or eco == xi.ecosystem.UNDEAD
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Impetus uptime.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.IMPETUS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.IMPETUS })

    -- Dodge when holding top enmity.
    mob:addGambit(ai.t.SELF, {
        { ai.c.HAS_TOP_ENMITY, 0 },
        { ai.c.NOT_STATUS, xi.effect.DODGE },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DODGE })

    -- Chakra when hurt; Invigorate Regen applied via ABILITY_USE (trusts have no merits).
    mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAKRA })

    -- Provoke when the summoner is in danger.
    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2000)

    mob:addListener('COMBAT_TICK', 'LHE_FOCUS_FORMLESS', function(mobArg)
        local battleTarget = mobArg:getTarget()
        if not battleTarget then
            return
        end

        -- Focus when ACC looks soft vs the current target.
        if
            not mobArg:hasStatusEffect(xi.effect.FOCUS) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FOCUS) and
            mobArg:getACC() < battleTarget:getEVA() + 40
        then
            mobArg:useJobAbility(xi.ja.FOCUS, mobArg)
            return
        end

        -- Formless Strikes vs physical-resistant ecosystems (leech/slime, elemental, ghost).
        if
            not mobArg:hasStatusEffect(xi.effect.FORMLESS_STRIKES) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FORMLESS) and
            isPhysResistantEco(battleTarget:getEcosystem())
        then
            mobArg:useJobAbility(xi.ja.FORMLESS_STRIKES, mobArg)
        end
    end)

    -- Invigorate: Chakra grants Regen (merit proxy for trusts).
    mob:addListener('ABILITY_USE', 'LHE_INVIGORATE', function(mobArg, target, ability, action)
        if ability:getID() ~= xi.ja.CHAKRA then
            return
        end

        if mobArg:hasStatusEffect(xi.effect.REGEN) then
            mobArg:delStatusEffect(xi.effect.REGEN)
        end

        mobArg:addStatusEffect(xi.effect.REGEN, { power = 10, duration = 90, origin = mobArg, tick = 3 })
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
