-----------------------------------
-- Trust: Maat
-- MNK/THF. Hand-to-Hand.
-- Abilities: Mantra (HP + Haste), Perfect Counter, Formless Strikes (Amorph).
-- WS: Asuran Fists / One-Ilm Punch / Combo / Dragon Kick / Howling Fist / Bear Killer (conal).
-- Uses TP ASAP @1000. Treasure Hunter 5.
-- B-tier melee_dd (bruiser) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_FORMLESS = 152
local MS_BEAR_KILLER  = 3263

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.MAAT_UC)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- THF flavor + retail note.
    mob:addMod(xi.mod.TREASURE_HUNTER, 5)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MAX_HP_BOOST }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MANTRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PERFECT_COUNTER }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PERFECT_COUNTER })

    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- ASAP @1000. RANDOM so Bear Killer (highest id) doesn't monopolize ST.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    -- Formless Strikes vs blunt-resistant Amorphs (slimes, leeches).
    mob:addListener('COMBAT_TICK', 'MAAT_FORMLESS', function(mobArg)
        local battleTarget = mobArg:getTarget()
        if not battleTarget then
            return
        end

        if
            not mobArg:hasStatusEffect(xi.effect.FORMLESS_STRIKES) and
            not mobArg:hasRecast(xi.recast.ABILITY, RECAST_FORMLESS) and
            battleTarget:getEcosystem() == xi.ecosystem.AMORPH
        then
            mobArg:useJobAbility(xi.ja.FORMLESS_STRIKES, mobArg)
        end
    end)

    -- Retail Maat Mantra: HP boost + Haste. Trusts have no Mantra merits (power 0).
    mob:addListener('ABILITY_USE', 'MAAT_MANTRA', function(mobArg, target, ability, action)
        if ability:getID() ~= xi.ja.MANTRA then
            return
        end

        local master = mobArg:getMaster()
        if not master then
            return
        end

        for _, member in pairs(master:getPartyWithTrusts() or {}) do
            if member:isAlive() and mobArg:checkDistance(member) <= 10 then
                member:delStatusEffect(xi.effect.MAX_HP_BOOST)
                member:addStatusEffect(xi.effect.MAX_HP_BOOST, {
                    power    = 20, -- 20% HPP merit proxy
                    duration = 180,
                    origin   = mobArg,
                })
                member:delStatusEffect(xi.effect.HASTE)
                member:addStatusEffect(xi.effect.HASTE, {
                    power    = 1500, -- 15%
                    duration = 180,
                    origin   = mobArg,
                })
            end
        end
    end)

    mob:addListener('WEAPONSKILL_USE', 'MAAT_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_BEAR_KILLER then
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
