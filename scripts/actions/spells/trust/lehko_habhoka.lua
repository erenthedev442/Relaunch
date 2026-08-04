-----------------------------------
-- Trust: Lehko Habhoka
-- THF/BLM. Dagger + throwing. Single-target elemental I–II.
-- WS: Iridal Pierce (AoE Light) / Lunar Revolution (conal) / Debonair Rush / Inspirit.
-- ASAP @1000 TP. High DA/TA. Occasional throwing RA. No magic burst.
-- Nukes more often vs Elementals (piercing-resistant). Inspirit is opportunistic.
-- MP+150% (pool mod). C-tier hybrid (skirmisher) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ROMAA_MIHGO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ROBEL_AKBEL] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Enhanced Magic Accuracy + abnormally high DA/TA (on top of hybrid package).
    mob:addMod(xi.mod.MACC, 40 + math.floor(mob:getMainLvl() / 2))
    mob:addMod(xi.mod.DOUBLE_ATTACK, 20)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 12)
    -- Iridal Pierce light lane.
    mob:addMod(xi.mod.MATT, 60)
    mob:addMod(xi.mod.MAGIC_DAMAGE, 800)

    -- No magic burst. Occasional nukes; more often vs Elementals (piercing-resistant).
    mob:addGambit(ai.t.TARGET, { ai.c.IS_ECOSYSTEM, xi.ecosystem.ELEMENTAL }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, 0 }, 20)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, 0 }, 60)

    -- Throwing in conjunction with auto-attacks.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 10)

    -- WS right at 1000 TP (Inspirit is on the list — opportunistic, not party-gated).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('WEAPONSKILL_USE', 'LEHKO_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 3231 then -- Debonair Rush
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
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
