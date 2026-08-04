-----------------------------------
-- Trust: Gilgamesh
-- SAM/WAR. Great Katana.
-- Abilities: Hasso, Third Eye, Sekkanoki, Hagakure.
-- WS: Tachi: Goten / Tachi: Kasha / Iainuki / Tachi: Kamai (AoE wind).
-- Holds to 2000 TP to close skillchains.
-- At 2000 TP with Sekkanoki ready: Sekkanoki → self skillchain (WS pair).
-- A-tier melee_dd (weaponskill) power path.
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
        [xi.magic.spell.AYAME] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ALDO]  = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.LION]  = xi.trust.messageOffset.TEAMWORK_3,
    })

    -- Kamai wind lane (physical package owns AA / Iainuki / Kasha).
    mob:addMod(xi.mod.MATT, 180)
    mob:addMod(xi.mod.MACC, 100)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HAGAKURE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    -- Self-SC package: Sekkanoki at 2000 TP, then dump (CLOSER also fires at 2000).
    -- First WS under Sekkanoki leaves ~1000 TP + SC window → second WS closes.
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SEKKANOKI })

    mob:addListener('WEAPONSKILL_USE', 'GILGAMESH_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == 3435 then -- Iainuki
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    -- Hold to close; dump by 2000 (also enables the Sekkanoki self-SC loop).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
