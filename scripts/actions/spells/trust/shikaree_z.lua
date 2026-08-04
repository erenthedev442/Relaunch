-----------------------------------
-- Trust: Shikaree Z
-- DRG/WHM polearm. Raiden Thrust / Skewer / Wheeling Thrust / Impulse Drive.
-- HP-10%, MP+100%. STORE_TP for ~205 TP/hit; Jump / High Jump TP return.
-- Ancient Circle vs dragons; Super Jump on top enmity.
-- Holds TP to 2000 to close SCs. Cure @<50% / Sleep; Haste > -na (Erase if Slow).
-- B-tier melee_dd / skirmisher — no kit inject.
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

    -- HP-10% / MP+100% via mob_pool_mods (applied at spawn).
    mob:addMod(xi.mod.STORETP, 174)
    mob:addMod(xi.mod.JUMP_TP_BONUS, 164)

    -- Erase Slow so Haste can land; then Haste (self / master) before -na.
    mob:addGambit(ai.t.SELF, { ai.c.STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })
    mob:addGambit(ai.t.MASTER, { ai.c.STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })

    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    mob:addGambit(ai.t.TARGET, { ai.c.IS_ECOSYSTEM, xi.ecosystem.DRAGON }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ANCIENT_CIRCLE })

    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.JUMP })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HIGH_JUMP })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SUPER_JUMP })

    -- No HIGH_JUMP_TP_BONUS mod; top up so High Jump ≈ +410 over Jump (~1065 vs ~655).
    mob:addListener('ABILITY_USE', 'SHIKAREE_Z_HJ_TP', function(mobArg, target, ability, action)
        if ability:getID() == xi.ja.HIGH_JUMP then
            local stp = (100 + mobArg:getMod(xi.mod.STORETP)) / 100
            mobArg:addTP(math.floor(150 * stp))
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
