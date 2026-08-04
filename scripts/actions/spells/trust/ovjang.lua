-----------------------------------
-- Trust: Ovjang
-- RDM/BLM Stormwaker. Slow / Silence / Paralyze / Dispel, ST nukes I–IV.
-- WS: Slapstick / Knockout / Sixth Element (preferred, Gravitation).
-- MP+20%. CLOSER@1500. Occasional wand AA between casts.
-- Dispel first. Nashmeira: enmity-10, magic damage+.
-- C-tier nuker (apprentice) — no kit inject. mbCap 10k.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_SIXTH = 3244

local function partyHasNashmeira(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getObjType() == xi.objType.TRUST and
            (
                member:getTrustID() == xi.magic.spell.NASHMEIRA or
                member:getTrustID() == xi.magic.spell.NASHMEIRA_II
            )
        then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NASHMEIRA] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.MNEJING] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:addMod(xi.mod.MPP, 20)
    mob:addMod(xi.mod.FASTCAST, 20)
    mob:addMod(xi.mod.MACC, 50)
    -- Occasional AA between casts (gains TP slowly).
    mob:addMod(xi.mod.ACC, 35)
    mob:addMod(xi.mod.ATT, 30)
    mob:addMod(xi.mod.STORETP, -20)

    if partyHasNashmeira(mob) then
        mob:addMod(xi.mod.ENMITY, -10)
        mob:addMod(xi.mod.MAGIC_DAMAGE, math.max(40, math.floor(mob:getMainLvl() * 4)))
    end

    -- Dispel first.
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })

    -- Enfeebles.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENCE }, 60)

    -- MB then free ST nukes I–IV (list-capped).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 25)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 45)

    mob:addListener('WEAPONSKILL_USE', 'OVJANG_SIXTH', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_SIXTH then
            if math.random(1, 100) <= 33 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)

    mob:setAutoAttackEnabled(true)
    -- MID_RANGE: cast from a short distance, still AA when close.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
    -- Hold to close; dump @1500. HIGHEST = Sixth Element (last on list).
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
