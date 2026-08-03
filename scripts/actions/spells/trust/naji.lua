-----------------------------------
-- Trust: Naji
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    local bastokFirstTrust = caster:getCharVar('Quest[1][92]Prog')
    local zone = caster:getZoneID()

    if
        bastokFirstTrust == 1 and
        (zone == xi.zone.NORTH_GUSTABERG or zone == xi.zone.SOUTH_GUSTABERG)
    then
        caster:setCharVar('Quest[1][92]Prog', 2)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.AYAME] = xi.trust.messageOffset.TEAMWORK_1,
    })

    -- Adventuring Fellows use Naji only as a raw melee chassis. Their role
    -- overlay decides whether Provoke is appropriate; ordinary Naji retains
    -- his retail tanking gambit.
    local master = mob:getMaster()
    if not master or master:getLocalVar('fellowTrustSpawn') ~= 1 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    -- Retail: WS at 1000 TP, does not skillchain. Kit also sets ASAP; keep explicit.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
