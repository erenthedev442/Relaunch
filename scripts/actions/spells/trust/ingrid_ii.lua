-----------------------------------
-- Trust: Ingrid II
-- WHM/WAR. Club. Banish I–III, Cursna, Holy (MB only with Banish).
-- Ability: Self-Aggrandizement (party HP + erase one; ≥3 members <75% or asleep; 30s).
-- WS: Merciless Strike / Moonlight / Inexorable Strike / Ruthlessness (conal drain).
-- Holds to 2500 TP to close Light skillchains. Undead Killer.
-- B-tier hybrid (weaponskill) power path.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.INGRID)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

local function shouldSelfAggrandize(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    local party = master:getPartyWithTrusts()
    if not party then
        return false
    end

    local yellow = 0
    for _, member in pairs(party) do
        if member:isAlive() then
            if
                member:hasStatusEffect(xi.effect.SLEEP_I) or
                member:hasStatusEffect(xi.effect.SLEEP_II) or
                member:hasStatusEffect(xi.effect.LULLABY)
            then
                return true
            end

            if member:getHPP() < 75 then
                yellow = yellow + 1
            end
        end
    end

    return yellow >= 3
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail Undead Killer; Banish-vs-undead +10 (28/256) has no dedicated mod — trait covers flavor.
    mob:addMod(xi.mod.UNDEAD_KILLER, 15)

    -- Cursna only (no Cure line; Self-Aggrandizement is the heal).
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DOOM }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })

    -- Spells only to Magic Burst — Banish line of Divine Magic.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BANISH })

    -- Self-Aggrandizement: party heal + erase, 30s recast (not a TP WS).
    mob:setLocalVar('ingridIISelfAggReady', 0)
    mob:addListener('COMBAT_TICK', 'INGRID_II_SELF_AGG', function(mobArg)
        local now = os.time()
        if now < mobArg:getLocalVar('ingridIISelfAggReady') then
            return
        end

        if not shouldSelfAggrandize(mobArg) then
            return
        end

        mobArg:setLocalVar('ingridIISelfAggReady', now + 30)
        mobArg:useMobAbility(3646)
    end)

    -- Hold TP to close Light SCs; dump by 2500. RANDOM keeps Inexorable/Merciless/Ruthlessness in play.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 2500)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
