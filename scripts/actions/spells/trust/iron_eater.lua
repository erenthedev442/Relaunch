-----------------------------------
-- Trust: Iron Eater
-- WAR/WAR. Great Axe. No spells.
-- Abilities: Provoke (master <50% HP), Berserk, Restraint.
-- WS: Shield Break / Armor Break / Steel Cyclone.
-- 5/5 Double Attack merits + enhanced DA / Store TP.
-- With Restraint: hold WS until 35–40 attacks land (past 3000 TP), then random WS.
-- Without Restraint: WS ASAP @1000.
-- B-tier melee_dd (bruiser) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local function armRestraintHold(mob)
    mob:setLocalVar('ieRestraintHits', 0)
    mob:setLocalVar('ieRestraintThreshold', math.random(35, 40))
    -- TP never exceeds 3000 — blocks WS until the hit threshold is met.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)
end

local function clearRestraintHold(mob)
    mob:setLocalVar('ieRestraintHits', 0)
    mob:setLocalVar('ieRestraintThreshold', 0)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NAJI] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- 5/5 DA merits + enhanced DA / Store TP (bruiser package already stacks DA/STP).
    mob:addMod(xi.mod.DOUBLE_ATTACK, 25)
    mob:addMod(xi.mod.STORETP, 40)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RESTRAINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })

    -- Provoke only when the summoner's HP is low (not off other trusts).
    mob:addGambit(ai.t.MASTER, { ai.c.HPP_LT, 50 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })

    clearRestraintHold(mob)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Enter hold mode when Restraint goes up.
    mob:addListener('EFFECT_GAIN', 'IRON_EATER_RESTRAINT_GAIN', function(mobArg, effect)
        if effect:getEffectType() == xi.effect.RESTRAINT then
            armRestraintHold(mobArg)
        end
    end)

    mob:addListener('EFFECT_LOSE', 'IRON_EATER_RESTRAINT_LOSE', function(mobArg, effect)
        if effect:getEffectType() == xi.effect.RESTRAINT then
            clearRestraintHold(mobArg)
        end
    end)

    -- Count auto-attack rounds under Restraint; release WS after 35–40 hits.
    mob:addListener('ATTACK', 'IRON_EATER_RESTRAINT_HITS', function(mobArg, target, action)
        if not mobArg:hasStatusEffect(xi.effect.RESTRAINT) then
            return
        end

        local hits = mobArg:getLocalVar('ieRestraintHits') + 1
        mobArg:setLocalVar('ieRestraintHits', hits)

        local threshold = mobArg:getLocalVar('ieRestraintThreshold')
        if threshold == 0 then
            threshold = math.random(35, 40)
            mobArg:setLocalVar('ieRestraintThreshold', threshold)
        end

        if hits >= threshold then
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
        end
    end)

    -- After dumping under Restraint, re-arm the hold for the next charge.
    mob:addListener('WEAPONSKILL_USE', 'IRON_EATER_RESTRAINT_WS', function(mobArg, target, skill, tp, action, damage)
        if mobArg:hasStatusEffect(xi.effect.RESTRAINT) then
            armRestraintHold(mobArg)
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
