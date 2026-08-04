-----------------------------------
-- Trust: Semih Lafihna
-- RNG/WAR Archery. Sharpshot / Barrage / Stealth Shot / Double Shot.
-- WS: Arching / Stellar (AoE Eva Down) / Lux (Def Down) / Sidewinder (preferred dump).
-- Store TP+40, Ranged Attacks TP+100% (~252 TP/hit). Stays out of melee.
-- CLOSER@2000; Sidewinder when not closing. Stellar/Lux close T3.
-- C-tier ranged_dd (skirmisher) — no kit inject. Strong while leveling (early Sidewinder).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_STELLAR = 3489

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.STAR_SIBYL] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.AJIDO_MARUJIDO] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Store TP+40 + Ranged Attacks TP+100% → ~252 TP/hit with archery delay.
    mob:addMod(xi.mod.STORETP, 40)
    mob:addMod(xi.mod.STORETP, 100)
    mob:addMod(xi.mod.RACC, 60)

    -- Barrage only while building toward closer threshold.
    mob:addGambit(ai.t.SELF, {
        { ai.c.TP_LT, 2000 },
        { ai.c.NOT_STATUS, xi.effect.BARRAGE },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STEALTH_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.STEALTH_SHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })

    mob:addListener('WEAPONSKILL_USE', 'SEMIH_LAFIHNA_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_STELLAR then
            -- I'll show you no quarter!
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:setAutoAttackEnabled(false)
    -- Out of melee (~10'); LONG_RANGE 12' historically stuck m_InTransit.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)
    -- Hold to close SC; dump at 2000. HIGHEST opener = last list entry (Sidewinder).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
