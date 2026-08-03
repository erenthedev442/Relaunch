-----------------------------------
-- Trust: Lion
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LION_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    -- TODO: Trust Synergy (Aldo/Lion/Zeid)
    -- https://www.bg-wiki.com/ffxi/Cipher:_Lion

    -- Interrupt opener: Evisceration (player dagger WS; Grapeshot MS retired).
    local kInterruptWs = 25

    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.ZEID] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.ALDO] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.GILGAMESH] = xi.trust.messageOffset.TEAMWORK_3,
    })

    -- Stun all the things!
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.WS, ai.s.SPECIFIC, kInterruptWs })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.WS, ai.s.SPECIFIC, kInterruptWs })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.WS, ai.s.SPECIFIC, kInterruptWs })
    mob:addGambit(ai.t.TARGET, { ai.c.CASTING_MA,  0 }, { ai.r.WS, ai.s.SPECIFIC, kInterruptWs })

    -- A-tier: ACC + force melee range for dagger WS.
    mob:addMod(xi.mod.ACC, 150)
    mob:addMod(xi.mod.ATT, 80)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
