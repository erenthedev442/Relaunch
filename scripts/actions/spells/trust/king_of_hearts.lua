-----------------------------------
-- Trust: King of Hearts
-- RDM/WHM Arcana buffer. Master-only Haste/Refresh/Phalanx (+ Temper self),
-- Dia-first, Cure@50%, Erase/-na (master → self → party), MB Firaga,
-- Cardian WS (Shuffle / Double Down / Deal Out / Bludgeon after Level Up).
-- A-tier buffer + meleeChip. Permanent Composure +50% enh on others.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local HASTE_II_POWER = 3000 -- ~Haste II (307/1024)

local function hasWeakHaste(entity)
    local effect = entity:getStatusEffect(xi.effect.HASTE)
    if not effect then
        return true
    end

    return effect:getPower() < HASTE_II_POWER
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail: HP+25%, MP+80%; permanent Composure; +50% enh duration on others.
    mob:addMod(xi.mod.HPP, 25)
    mob:addMod(xi.mod.MPP, 80)
    mob:addMod(xi.mod.AUGMENT_COMPOSURE, 50)
    mob:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = 0, origin = mob })

    ----------------------------------------------------------------
    -- Priority: Erase / -na (master → self → party)
    ----------------------------------------------------------------
    local naList =
    {
        { xi.effect.POISON,         xi.magic.spell.POISONA },
        { xi.effect.PARALYSIS,      xi.magic.spell.PARALYNA },
        { xi.effect.BLINDNESS,      xi.magic.spell.BLINDNA },
        { xi.effect.SILENCE,        xi.magic.spell.SILENA },
        { xi.effect.PETRIFICATION,  xi.magic.spell.STONA },
        { xi.effect.DISEASE,        xi.magic.spell.VIRUNA },
        { xi.effect.CURSE_I,        xi.magic.spell.CURSNA },
    }

    for _, tgt in ipairs({ ai.t.MASTER, ai.t.SELF, ai.t.PARTY }) do
        for _, entry in ipairs(naList) do
            mob:addGambit(tgt, { ai.c.STATUS, entry[1] }, { ai.r.MA, ai.s.SPECIFIC, entry[2] })
        end

        mob:addGambit(tgt, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    end

    -- Cure players / party at ≤50% HP.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Opens with Dia; keeps trying if immune (effect never sticks).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.DIA }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.DIA }, 60)

    -- Master-only Haste / Refresh / Phalanx (not other trusts/players).
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.REFRESH }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.PHALANX }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PHALANX })

    -- Phalanx on highest enmity (party / alter ego).
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.NOT_STATUS, xi.effect.PHALANX }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PHALANX })

    -- Self Temper (melee AA / WS).
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MULTI_STRIKES }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.TEMPER })

    -- MB Firaga off Fire-compatible SC (Liquefaction / Fusion / Light).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Haste II overwrite if master still on Haste I.
    mob:addListener('COMBAT_TICK', 'KOH_HASTE_II', function(mobArg)
        local action = mobArg:getCurrentAction()
        if
            action ~= xi.action.category.NONE and
            action ~= xi.action.category.BASIC_ATTACK and
            action ~= xi.action.category.MOBABILITY_FINISH
        then
            return
        end

        local master = mobArg:getMaster()
        if
            master and
            master:isAlive() and
            hasWeakHaste(master) and
            master:hasStatusEffect(xi.effect.HASTE)
        then
            mobArg:castSpell(xi.magic.spell.HASTE_II, master)
        end
    end)

    -- Random Level Up: restore HP/MP, unlock Bludgeon.
    mob:addListener('COMBAT_TICK', 'KOH_LEVEL_UP', function(mobArg)
        if mobArg:getLocalVar('kohLevelUp') == 1 then
            return
        end

        if not mobArg:isEngaged() then
            return
        end

        if math.random(1, 450) ~= 1 then
            return
        end

        mobArg:setLocalVar('kohLevelUp', 1)
        mobArg:addHP(math.floor(mobArg:getMaxHP() * 0.25))
        mobArg:addMP(math.floor(mobArg:getMaxMP() * 0.25))
    end)

    -- Keep Composure if stripped.
    mob:addListener('COMBAT_TICK', 'KOH_COMPOSURE', function(mobArg)
        if not mobArg:hasStatusEffect(xi.effect.COMPOSURE) then
            mobArg:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = 0, origin = mobArg })
        end
    end)

    -- Random TP use, no skillchain intent. Melee range AA.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
