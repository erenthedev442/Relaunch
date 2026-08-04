-----------------------------------
-- Trust: AAGK (Ark Angel GK)
-- SAM/DRG. Hasso, Konzen-ittai, Hagakure, Meditate, Sekkanoki, Jump, High Jump.
-- WS: Tachi Yukikaze/Gekko/Kasha/Fudo + Dragonfall. HP+20%.
-- Holds 3000 TP to close; Jump at low TP; High Jump on top enmity.
-- Occasional free-TP WS (refund). A-tier weaponskill power path.
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

    mob:addMod(xi.mod.HPP, 20)
    -- Retail ~790 TP Jump return (bonus + hit TP + Store TP from power package).
    mob:addMod(xi.mod.JUMP_TP_BONUS, 200)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HAGAKURE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })

    -- Self-skillchain package: Sekkanoki at 2000 TP, Meditate while building.
    mob:addGambit(ai.t.SELF, { ai.c.TP_GTE, 2000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SEKKANOKI })
    mob:addGambit(ai.t.SELF, { ai.c.TP_LT, 1000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })

    -- Jump at low TP; High Jump when holding top enmity.
    mob:addGambit(ai.t.TRIGGER_SELF_ACTION_TARGET, { ai.c.TP_LT, 1000 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.JUMP })
    mob:addGambit(ai.t.TARGET, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HIGH_JUMP })

    -- Konzen-ittai when master has WS TP and AAGK does not (never used to close).
    -- abilities.recastId for Konzen-ittai is 132.
    mob:addListener('COMBAT_TICK', 'AAGK_KONZEN', function(mobArg)
        if mobArg:hasRecast(xi.recast.ABILITY, 132) then
            return
        end

        local master = mobArg:getMaster()
        local battleTarget = mobArg:getTarget()
        if not master or not battleTarget or not battleTarget:isAlive() then
            return
        end

        if master:getTP() >= 1000 and mobArg:getTP() < 1000 then
            mobArg:useJobAbility(xi.ja.KONZEN_ITTAI, battleTarget)
        end
    end)

    -- Occasional WS without TP cost; short delay before another free WS.
    mob:setLocalVar('AAGKFreeWSReady', 0)
    mob:addListener('WEAPONSKILL_USE', 'AAGK_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == xi.mobSkill.DRAGONFALL_TRUST then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1) -- Rage Cleaves!
        end

        local now = os.time()
        local readyAt = mobArg:getLocalVar('AAGKFreeWSReady')
        if readyAt == 0 then
            readyAt = now
            mobArg:setLocalVar('AAGKFreeWSReady', now)
        end

        if now >= readyAt and math.random(1, 100) <= 30 then
            mobArg:setTP(tp)
            mobArg:setLocalVar('AAGKFreeWSReady', now + 20)
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 3000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
