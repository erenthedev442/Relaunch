-----------------------------------
-- Trust: Ferreous Coffin
-- WHM/WAR. Cure I–VI, Raise I–III, -na, Erase, Haste. WS: Randgrith only.
-- Auto Refresh II. HP-10%, MP+35% (pool mods). High Cursna success.
-- -na / Cursna only on top enmity. Raise III only on KO party.
-- Haste on all party jobs. TP ASAP (Evade Down / Light openers).
-- Relic aftermath ACC+20. C-tier healer + meleeChip for Randgrith.
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
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Auto Refresh II (Cleric's Bliaut +2). HP/MP% via mob_pool_mods.
    mob:addMod(xi.mod.REFRESH, 2)
    -- High Cursna success (retail note).
    mob:addMod(xi.mod.ENHANCES_CURSNA, 20)
    -- Retail Double Attack.
    mob:addMod(xi.mod.DOUBLE_ATTACK, 12)

    -- Raise III only (retail: only Raise III on KO party in range).
    mob:addGambit(ai.t.PARTY_DEAD, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.RAISE_III })

    -- Status removal only on highest enmity (Doom/Cursna first).
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.CURSE_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.BANE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.TOP_ENMITY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })

    -- Wake sleeps; triage cures (C-tier healer potency from scaler).
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Haste on all party members regardless of job; Erase Slow.
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    mob:addListener('WEAPONSKILL_USE', 'FERREOUS_COFFIN_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() ~= xi.mobSkill.RANDGRITH_1 then
            return
        end

        if math.random(1, 100) <= 66 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- Return to the dust whence you came! Randgrith!!!
        end

        -- Relic aftermath ACC+20; duration scales with TP (20/40/60s).
        local duration = 20
        if tp >= 3000 then
            duration = 60
        elseif tp >= 2000 then
            duration = 40
        end

        mobArg:addStatusEffect(xi.effect.ACCURACY_BOOST, { power = 20, duration = duration, origin = mobArg })
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Dump TP ASAP — only Randgrith on list (Evade Down / Light openers).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
