-----------------------------------
-- Trust: Mnejing
-- PLD / Valoredge. No spells.
-- Abilities: Strobe I-II (Provoke), Shield Bash, Disruptor, Flashbulb.
-- WS: Chimera Ripper, String Clipper, Shield Subverter (conal Silence).
-- Passive -37.5% DT. Barrier Module (block rate + Shield Mastery).
-- Holds up to 1500 TP to close skillchains (RANDOM, not always highest tier).
-- Interrupts TP moves with Shield Bash. Flashbulb Flash generates high enmity.
-- Disruptor is highly accurate vs buffs other trusts may miss.
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

    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)
    mob:setMobMod(xi.mobMod.CAN_PARRY, 3)

    -- Barrier Module
    mob:setMod(xi.mod.SHIELD_MASTERY_TP, 40)
    mob:setMod(xi.mod.SHIELDBLOCKRATE, 45)

    -- Entry automaton tank: hate tools + TP moves; still below Amchuchu/B tanks.
    mob:addMod(xi.mod.ENMITY, 55)
    mob:addMod(xi.mod.ATT, 40)
    mob:addMod(xi.mod.ACC, 60)
    mob:addMod(xi.mod.MACC, 100) -- Disruptor lands where other trusts may skip
    mob:addMod(xi.mod.DMG, -3750) -- Passive -37.5% Damage Taken (DMG is /10000)
    -- Lower HP than most tanks; DT carries survivability instead of HPP.
    xi.trust.enableTankEnmity(mob, { tickCE = 3800, tickVE = 7600, actionCE = 1900, actionVE = 3800, tickSeconds = 3, drainMaster = 5, includeParty = true, listenerName = 'MNEJING_TANK_ENMITY' })

    local lastSynergyBonus = 0

    mob:addListener('COMBAT_TICK', 'MNEJING_CTICK', function(mobArg)
        local targetBonus = 0
        local party = mobArg:getMaster():getPartyWithTrusts()

        for _, member in pairs(party) do
            if member:getObjType() == xi.objType.TRUST then
                if member:getTrustID() == xi.magic.spell.NASHMEIRA then
                    targetBonus = 10
                end
            end
        end

        if targetBonus ~= lastSynergyBonus then
            mobArg:delMod(xi.mod.DEF, lastSynergyBonus)
            mobArg:delMod(xi.mod.ENMITY, lastSynergyBonus)
            mobArg:addMod(xi.mod.DEF, targetBonus)
            mobArg:addMod(xi.mod.ENMITY, targetBonus)

            lastSynergyBonus = targetBonus
        end
    end)

    -- Strobe (Provoke). Strobe II enmity at 80+.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS,      0                        }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.PROVOKE_AUTOMATON     }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS,  xi.effect.FLASH          }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.FLASHBULB_AUTOMATON   }, 45)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0                        }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.SHIELD_BASH_AUTOMATON }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0                        }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.SHIELD_BASH_AUTOMATON }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MS, ai.s.SPECIFIC, xi.mobSkill.DISRUPTOR_AUTOMATON   }, 15)

    -- Hold TP to close; RANDOM so he does not always pick the highest-tier closer.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
