-----------------------------------
-- Trust: Naja Salaheem
-- MNK/WAR. Club. Focus / Dodge / Counterstance (on top enmity).
-- WS: True Strike / Hexa Strike / Peacebreaker / Black Halo.
-- Peacebreaker: low dmg + DEF/MDEF Down. ~100 TP per hit. ASAP@1000.
-- C-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_PEACEBREAKER = 3215

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.NAJA_UC)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.GESSHO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.RONGELOUTS] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.ABQUHBAH] = xi.trust.messageOffset.TEAMWORK_3,
    })

    -- Retail: ~100 TP per hit (high Store TP on delay-240 club).
    mob:addMod(xi.mod.STORETP, 100)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    -- Uses WS at 1000 TP; Black Halo last on list for HIGHEST preference.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FOCUS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FOCUS })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DODGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DODGE })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.COUNTERSTANCE })

    mob:addListener('WEAPONSKILL_USE', 'NAJA_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_PEACEBREAKER then
            -- Cha-ching! Thirty gold coins!
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
