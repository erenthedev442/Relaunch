-----------------------------------
-- Trust: Semih Lafihna
-- RNG — Barrage / Sharpshot / Double Shot + ranged WS (Sidewinder / Arching / Stellar / Lux).
-- Barrage only while building TP so she actually weaponskills.
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
        [xi.magic.spell.STAR_SIBYL] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.AJIDO_MARUJIDO] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- Barrage only while under 1000 TP — otherwise every shot is Barrage and WS never fires.
    mob:addGambit(ai.t.SELF, { { ai.c.TP_LT, 1000 }, { ai.c.NOT_STATUS, xi.effect.BARRAGE } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })

    mob:addListener('WEAPONSKILL_USE', 'SEMIH_LAFIHNA_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 199 then -- Empyreal Arrow (player WS)
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
    mob:setAutoAttackEnabled(false)

    -- Gets 252 TP per hit even at level 1, see https://www.bg-wiki.com/ffxi/BGWiki:Trusts#Semih_Lafihna
    mob:addMod(xi.mod.STORETP, 86)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
    -- MID_RANGE: LONG_RANGE parked RA in transit (no TP/WS).
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
