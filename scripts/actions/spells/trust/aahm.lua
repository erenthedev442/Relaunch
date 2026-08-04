-----------------------------------
-- Trust: AAHM
-- NIN/WAR hybrid. A-tier melee_dd damage path via trust_power_scaling.
-- Party has NIN/PLD/RUN: DD stance (Innin + Berserk).
-- No other tank: tank stance (Yonin + Warcry). Provoke in both as subtank.
-- WS at 1000 TP; does not skillchain.
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

    mob:addMobMod(xi.mobMod.CAN_PARRY, 3)

    -- Retail: HP+20%, Utsusemi +1. No flat DT-5% (tier package owns survivability).
    mob:addMod(xi.mod.UTSUSEMI_BONUS, 1)
    mob:addMod(xi.mod.FASTCAST, 30)
    mob:addMod(xi.mod.ENMITY, 15)
    mob:addMod(xi.mod.DUAL_WIELD, 10)
    mob:addMod(xi.mod.HPP, 20)

    -- Subtank only — light enmity ticks so he does not peel from dedicated tanks.
    -- Primary hate tools remain Provoke / Flash-tier tools from other trusts.
    xi.trust.enableTankEnmity(mob, {
        profile       = 'steady',
        listenerName  = 'AAHM_TANK_ENMITY',
        includeParty  = true,
        forceRetarget = true,
    })

    local lvl = mob:getMainLvl()
    local lastSynergyBonus = 0

    mob:addListener('COMBAT_TICK', 'AAHM_CTICK', function(mobArg)
        local synergyMembers =
        {
            xi.magic.spell.AAEV,
            xi.magic.spell.AAMR,
            xi.magic.spell.AATT,
            xi.magic.spell.AAGK,
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

        local targetBonus = (synergyCount == #synergyMembers) and 50 or 0
        if targetBonus ~= lastSynergyBonus then
            mobArg:delMod(xi.mod.MEVA, lastSynergyBonus)
            mobArg:addMod(xi.mod.MEVA, targetBonus)
            lastSynergyBonus = targetBonus
        end
    end)

    if lvl >= 10 then
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    if lvl >= 30 then
        -- DD stance when another NIN/PLD/RUN is present.
        mob:addGambit(ai.t.SELF, {
            { ai.c.PT_HAS_TANK, 0 },
            { ai.c.NOT_STATUS, xi.effect.BERSERK },
        }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    end

    if lvl >= 40 then
        -- No party tank: tank stance (Yonin). Party has tank: DD stance (Innin).
        mob:addGambit(ai.t.SELF, {
            { ai.c.NOT_PT_HAS_TANK, 0 },
            { ai.c.NOT_STATUS, xi.effect.YONIN },
        }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.YONIN })
        mob:addGambit(ai.t.SELF, {
            { ai.c.PT_HAS_TANK, 0 },
            { ai.c.NOT_STATUS, xi.effect.INNIN },
        }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.INNIN })
    end

    if lvl >= 70 then
        -- Warcry only in tank stance (no other NIN/PLD/RUN).
        mob:addGambit(ai.t.SELF, {
            { ai.c.NOT_PT_HAS_TANK, 0 },
            { ai.c.NOT_STATUS, xi.effect.WARCRY },
        }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
    end

    -- Migawari first so fights open with it when available.
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MIGAWARI }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.MIGAWARI_ICHI })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.COPY_IMAGE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.UTSUSEMI })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HOJO }, 30)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.KURAYAMI }, 30)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)

    mob:addListener('WEAPONSKILL_USE', 'AAHM_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action)
        if skill:getID() == xi.mobSkill.CROSS_REAVER_3 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- Apathy strikes!
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
