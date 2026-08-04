-----------------------------------
-- Trust: Mihli Aliapoh
-- WHM/WHM. Cure I–VI, Protect/ra, Shell/ra, -na, Slow, Paralyze.
-- JA: Afflatus Solace. WS: True Strike / Brainshaker / Hexa Strike / Scouring Bubbles (AoE).
-- Cure Potency +5%, Healing Magic Skill+, modest Cursna+.
-- Status on self first. Cure: party <50% / asleep; tank <75%.
-- TP randomly (no SC); prefers Scouring Bubbles.
-- C-tier healer + meleeChip for club WS.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SCOURING_BUBBLES = 3203
local CLUB_WS = { 166, 162, 168 } -- True Strike / Brainshaker / Hexa Strike

local function canAct(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Mihli Aliapoh
    if caster:getEminenceProgress(934) then
        xi.roe.onRecordTrigger(caster, 934)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.RUGHADJEEN] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.GADALAR] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.NAJELITH] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.ZAZARG] = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Retail cure identity (on top of C support package).
    mob:addMod(xi.mod.CURE_POTENCY, 5)
    mob:addMod(xi.mod.HEALING, 80) -- ≈ +5% cure / skill edge vs other C healers
    mob:addMod(xi.mod.ENHANCES_CURSNA, 2)

    -- 1) Status removal — self first, then party.
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BANE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })

    -- Afflatus Solace up before triage.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AFFLATUS_SOLACE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AFFLATUS_SOLACE })

    -- 2) Cures: wake sleep; tank <75%; party orange <50%.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- 3) Buffs.
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })

    -- 4) Enfeebles last: Slow then Paralyze.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)

    mob:addListener('WEAPONSKILL_USE', 'MIHLI_ALIAPOH_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_SCOURING_BUBBLES and math.random(1, 100) <= 33 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- Bah! Guess I'll pull out another one of my trrricks!
        end
    end)

    -- Random TP (no SC). Prefer Scouring Bubbles (~70%). Gambit WS off — listener owns dumps.
    mob:setMobAbilityEnabled(false)
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('COMBAT_TICK', 'MIHLI_WS', function(mobArg)
        if not canAct(mobArg) or mobArg:getTP() < 1000 then
            return
        end

        -- Match RANDOM trigger odds (~tp_value/10000 per tick at 1000+ TP).
        if math.random(1, 10000) >= 1000 then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local skillId = MS_SCOURING_BUBBLES
        if math.random(1, 100) > 70 then
            skillId = CLUB_WS[math.random(#CLUB_WS)]
        end

        mobArg:setMobAbilityEnabled(true)
        mobArg:useMobAbility(skillId, battleTarget)
        mobArg:setMobAbilityEnabled(false)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
