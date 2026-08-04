-----------------------------------
-- Trust: Ajido-Marujido
-- BLM/RDM. Cure I–IV, Dispel, Slow, Paralyze, single-target nukes I–V.
-- No TP moves/abilities. Weak H2H palm-blast AA; NO_MOVE.
-- Dispel > Cure@25% > MB > enfeebles > weakness nukes.
-- Top enmity: stop casting, palm-blast until hate moves on.
-- Cure Potency+25%, Fast Cast, MB Bonus, elevated MACC (A+ magic skills).
-- C-tier nuker (apprentice) — no kit inject. mbCap 10k.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.SHANTOTTO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.STAR_SIBYL] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.KORU_MORU] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.KARAHA_BARUHA] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.SEMIH_LAFIHNA] = xi.trust.messageOffset.TEAMWORK_5,
    })

    -- Retail trait package (on top of C apprentice scaler).
    mob:addMod(xi.mod.CURE_POTENCY, 25)
    mob:addMod(xi.mod.FASTCAST, 35)
    mob:addMod(xi.mod.UFASTCAST, 10)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 25)
    -- A+ Elemental / Enfeebling / Healing → land rate (skill floors via MACC).
    mob:addMod(xi.mod.MACC, 80)

    -- Dispel first.
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })

    -- Emergency cures (red HP).
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Magic burst windows.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Enfeebles (skip if already applied).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)

    -- Free nukes vs weakness (avoids sure-resist elements).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 25)

    -- Weak palm-blast AA; no TP kit.
    mob:setAutoAttackEnabled(true)
    mob:setMobAbilityEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    -- Draw hate → stop casting; resume when enmity moves on.
    mob:setLocalVar('ajidoHateMute', 0)
    mob:addListener('COMBAT_TICK', 'AJIDO_HATE_MUTE', function(mobArg)
        local hate = hasTopEnmity(mobArg)
        local muted = mobArg:getLocalVar('ajidoHateMute') == 1

        if hate and not muted then
            mobArg:setMagicCastingEnabled(false)
            mobArg:setLocalVar('ajidoHateMute', 1)
        elseif not hate and muted then
            mobArg:setMagicCastingEnabled(true)
            mobArg:setLocalVar('ajidoHateMute', 0)
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
