-----------------------------------
-- Trust: Adelheid
-- SCH/BLM Club. Dark Arts / Addendum: Black. Cure I–IV, Storms, Helices,
-- single-target nukes I–V, Stun.
-- WS: Paralyzing / Silencing / Binding Microtube + Twirling Dervish (AoE @50).
-- Storm vs weakness (else day) → helix → storm-element nukes; MB helix on SC.
-- Stun interrupts. Cure tank@50% / party@33%. ~100 TP/hit; ASAP@1000.
-- C-tier nuker (scholar) — no kit inject. mbCap 10k.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Adelheid
    if caster:getEminenceProgress(936) then
        xi.roe.onRecordTrigger(caster, 936)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Dark Arts does not punish her cures (retail).
    mob:addMod(xi.mod.CURE_POTENCY, 25)
    mob:addMod(xi.mod.FASTCAST, 15)
    -- Club delay 240 → ~100 TP/hit with modest Store TP.
    mob:addMod(xi.mod.STORETP, 50)
    mob:addMod(xi.mod.MACC, 40)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DARK_ARTS }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DARK_ARTS })
    if mob:getMainLvl() >= 30 then
        mob:addGambit(ai.t.SELF, {
            { ai.c.STATUS, xi.effect.DARK_ARTS },
            { ai.c.NOT_STATUS, xi.effect.ADDENDUM_BLACK },
        }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.ADDENDUM_BLACK })
    end

    -- Interrupts before setup / free nukes.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Emergency cures (tank priority).
    mob:addGambit(ai.t.TANK, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 33 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- MB helix/nuke matching SC element (helix IDs sort last → preferred).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })

    -- Storm vs weakness, else day.
    mob:addGambit(ai.t.SELF, { ai.c.NO_STORM, 0 }, { ai.r.MA, ai.s.STORM_MOB_WEAKNESS, 0 })
    mob:addGambit(ai.t.SELF, { ai.c.NO_STORM, 0 }, { ai.r.MA, ai.s.STORM_DAY, 0 })

    -- Helix vs weakness, else day.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.HELIX }, { ai.r.MA, ai.s.HELIX_MOB_WEAKNESS, 0 })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.HELIX }, { ai.r.MA, ai.s.HELIX_DAY, 0 })

    -- Free nukes matching target weakness (≈ storm element after setup).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 30)

    mob:addListener('WEAPONSKILL_USE', 'ADELHEID_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == xi.mobSkill.TWIRLING_DERVISH then
            if math.random(1, 100) <= 33 then
                -- You may want to cover your ears!
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Dump TP ASAP (casting often takes priority over WS).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
