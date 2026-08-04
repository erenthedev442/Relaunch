-----------------------------------
-- Trust: Rughadjeen
-- PLD/PLD. Spells: Holy, Flash, Cure I-IV, Raise.
-- Abilities: Sentinel, Divine Emblem, Holy Circle, Chivalry.
-- WS: Power Slash, Sickle Moon, Ground Strike, Victory Beacon (conal).
-- Fast Cast, Cure Potency Received +30%, DT-5%, HP+20%, MP+20%.
-- Algol: Enfire + 3% Triple Attack.
-- Holy Circle vs Undead. Cure party <75% HP or asleep.
-- WS at 1000 TP (lower priority than emergency gambits where possible).
-- Chivalry at <50% MP. Raise KO'd party in range.
-- Serpent General synergy: DT-29% with Mihli/Gadalar/Zazarg/Najelith.
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
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.NASHMEIRA] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.GADALAR] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.NAJELITH] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.ZAZARG] = xi.trust.messageOffset.TEAMWORK_4,
        [xi.magic.spell.MIHLI_ALIAPOH] = xi.trust.messageOffset.TEAMWORK_5
    })

    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)

    mob:addMod(xi.mod.FASTCAST, 30)
    mob:addMod(xi.mod.CURE_POTENCY_RCVD, 30)
    mob:addMod(xi.mod.TRIPLE_ATTACK, 3)
    mob:addMod(xi.mod.ATT, 40)
    mob:addMod(xi.mod.ACC, 55)
    mob:addMod(xi.mod.DMG, -500) -- Damage Taken -5%
    mob:addMod(xi.mod.HPP, 20)
    mob:addMod(xi.mod.MPP, 20)
    mob:setMod(xi.mod.SHIELDBLOCKRATE, 30)
    xi.trust.enableTankEnmity(mob, { tickCE = 6000, tickVE = 12000, actionCE = 3000, actionVE = 6000, tickSeconds = 2, drainMaster = 10, includeParty = true, listenerName = 'RUGHADJEEN_TANK_ENMITY' })

    local lvl = mob:getMainLvl()

    -- Algol Additional Effect: Fire DMG, procs around 33%, dmg ~30 at lvl 99.
    local potency = utils.clamp(math.floor(lvl * 0.26), 3, 30)
    mob:addMod(xi.mod.ENSPELL, xi.element.FIRE)
    mob:addMod(xi.mod.ENSPELL_DMG, potency)
    mob:addMod(xi.mod.ENSPELL_CHANCE, 33)

    local lastSynergyBonus = 0
    mob:addListener('COMBAT_TICK', 'RUGHADJEEN_CTICK', function(mobArg)
        local synergyMembers =
        {
            xi.magic.spell.MIHLI_ALIAPOH,
            xi.magic.spell.GADALAR,
            xi.magic.spell.ZAZARG,
            xi.magic.spell.NAJELITH
        }

        local synergyCount = 0
        local party = mobArg:getMaster():getPartyWithTrusts()

        for _, member in pairs(party) do
            if member:getObjType() == xi.objType.TRUST then
                local trustId = member:getTrustID()
                for _, sId in ipairs(synergyMembers) do
                    if trustId == sId then
                        synergyCount = synergyCount + 1
                        break
                    end
                end
            end
        end

        -- Any other serpent general → Damage Taken -29% while in combat.
        local targetBonus = (synergyCount >= 1) and -2900 or 0
        if targetBonus ~= lastSynergyBonus then
            mobArg:delMod(xi.mod.DMG, lastSynergyBonus)
            mobArg:addMod(xi.mod.DMG, targetBonus)
            lastSynergyBonus = targetBonus
        end
    end)

    if lvl >= 5 then
        mob:addGambit(ai.t.TARGET, { ai.c.IS_ECOSYSTEM, xi.ecosystem.UNDEAD }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HOLY_CIRCLE })
    end

    if lvl >= 30 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
    end

    if lvl >= 50 then
        mob:addGambit(ai.t.SELF, { { ai.c.MPP_LT, 50 }, { ai.c.TP_GTE, 1000 } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.CHIVALRY })
    end

    if lvl >= 75 then
        -- Divine Emblem → Holy (self buff, then nuke)
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DIVINE_EMBLEM }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DIVINE_EMBLEM })
        mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, {
            { ai.c.STATUS, xi.effect.DIVINE_EMBLEM },
        }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HOLY })
    end

    mob:addGambit(ai.t.TARGET,     { ai.c.NOT_STATUS,   xi.effect.FLASH     }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH       })
    mob:addGambit(ai.t.PARTY,      { ai.c.HPP_LT,       75                  }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.CURE  })
    mob:addGambit(ai.t.PARTY_DEAD, { ai.c.MPP_GTE,      200                 }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.RAISE })
    mob:addGambit(ai.t.TARGET,     { ai.c.IS_ECOSYSTEM, xi.ecosystem.UNDEAD }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HOLY        })
    mob:addGambit(ai.t.PARTY,      { ai.c.STATUS,       xi.effect.SLEEP_I   }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE        })

    -- WS at 1000 TP; RANDOM select across Power Slash / Sickle Moon / Ground Strike / Victory Beacon.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)

    mob:addListener('WEAPONSKILL_USE', 'RUGHADJEEN_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == xi.mobSkill.VICTORY_BEACON_TRUST then
            -- Do not despair! The Goddess of Victory fights by our side!
            if math.random(1, 100) <= 33 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
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
