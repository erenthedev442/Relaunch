-----------------------------------
-- Trust: Najelith
-- RNG/RNG. Dagger melee + Archery RA. Barrage / Double Shot.
-- WS: Sidewinder / Empyreal Arrow / Typhonic Arrow / Cyclone (preferred opener).
-- Crit rate+, Melee/RA TP+100%. NO_MOVE; melee + RA if in range.
-- CLOSER@1500; Cyclone when not closing. Rughadjeen synergy: RACC+40.
-- B-tier ranged_dd (weaponskill) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_TYPHONIC = 2090

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.RUGHADJEEN] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Enhanced crit + Melee/RA TP+100%.
    mob:addMod(xi.mod.CRITHITRATE, 15)
    mob:addMod(xi.mod.STORETP, 100)
    mob:addMod(xi.mod.RACC, 50)
    mob:addMod(xi.mod.ACC, 40)

    -- Rughadjeen synergy: +40 RACC (and Barrage accuracy via RACC).
    local master = mob:getMaster()
    if master then
        for _, member in ipairs(master:getPartyWithTrusts()) do
            if
                member:getObjType() == xi.objType.TRUST and
                member:getTrustID() == xi.magic.spell.RUGHADJEEN
            then
                mob:addMod(xi.mod.RACC, 40)
                break
            end
        end
    end

    -- Barrage while building toward closer threshold.
    mob:addGambit(ai.t.SELF, {
        { ai.c.TP_LT, 1500 },
        { ai.c.NOT_STATUS, xi.effect.BARRAGE },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })

    -- RA cadence so dagger AA still lands when in melee range.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 5)

    mob:addListener('WEAPONSKILL_USE', 'NAJELITH_WS', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_TYPHONIC then
            -- For the glory of the Empress!
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Hold to close SC; dump at 1500. HIGHEST opener = last list entry (Cyclone).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
