-----------------------------------
-- Trust: Ullegore
-- BLM/DRK (Corse costume). ST I–V, Comet, Stun.
-- WS: Memento Mori (MAB) / Silence Seal (AoE) / Envoutement (Dark, no Curse) /
--     Bored to Tears (weak Slow + flavor message).
-- HP+30%, MP+300% (massive MP). Memento before Comet. Stun interrupts.
-- Arcana Killer. Not undead (can be cured / drained). A-tier nuker (pressure).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_MEMENTO = 3624
local MS_BORED   = 3627

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail HP/MP package (~5000 MP at endgame with scaler).
    mob:addMod(xi.mod.HPP, 30)
    mob:addMod(xi.mod.MPP, 300)
    mob:addMod(xi.mod.MP, xi.trust.modGrowthValMax(mob, 1800))
    mob:addMod(xi.mod.ARCANA_KILLER, 15)
    mob:addMod(xi.mod.FASTCAST, 20)
    mob:addMod(xi.mod.MACC, 50)
    -- Staff AA when in range (nuker package has no melee axes).
    mob:addMod(xi.mod.ACC, 40)
    mob:addMod(xi.mod.ATT, 45)
    local lvl = mob:getMainLvl()
    local p   = (math.max(1, math.min(99, lvl)) / 99) ^ 1.35
    local t   = 0.94 -- A-tier
    pcall(function()
        mob:setDamage(math.floor((12 + 210 * p) * t * 0.85))
    end)

    -- Memento Mori when lacking Magic Atk Boost (feeds Comet).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MAGIC_ATK_BOOST }, { ai.r.MS, ai.s.SPECIFIC, MS_MEMENTO })

    -- Stun interrupts enemy TP moves / abilities.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Comet after Memento (or whenever available); then free ST nukes.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.COMET }, 28)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 22)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 45)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Dump TP for Corse kit; RANDOM = no SC hold.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Prefer Memento immediately before Comet if somehow still unbuffed.
    mob:addListener('COMBAT_TICK', 'ULLE_MEMENTO_COMET', function(mobArg)
        if
            canAct(mobArg) and
            mobArg:getTP() >= 1000 and
            not mobArg:hasStatusEffect(xi.effect.MAGIC_ATK_BOOST) and
            mobArg:getMainLvl() >= 94 and
            mobArg:getMPP() >= 25
        then
            mobArg:useMobAbility(MS_MEMENTO, mobArg)
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'ULLE_BORED_MSG', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_BORED then
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
