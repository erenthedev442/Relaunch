-----------------------------------
-- Trust: Margret
-- RNG/THF Archery. Decoy / Double / Barrage / Sharpshot / Stealth Shot.
-- WS: Piercing Arrow / Sidewinder / Arching Arrow / Refulgent Arrow.
-- Treasure Hunter 3, Store TP+40, Ranged Attacks TP+100% (~252 TP/hit).
-- Stays out of melee. Stacks JAs to support TP moves. WS at 2000; no SC.
-- Enemy under ~12% HP: RA only (no WS / JAs).
-- C-tier ranged_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local LOW_HP_HOLD = 12 -- retail ~10–15%

local function installCombatGambits(mob)
    -- Barrage only while building toward 2000 TP.
    mob:addGambit(ai.t.SELF, {
        { ai.c.TP_LT, 2000 },
        { ai.c.NOT_STATUS, xi.effect.BARRAGE },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.STEALTH_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.STEALTH_SHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DECOY_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DECOY_SHOT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
end

local function installAaOnlyGambits(mob)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
end

local function setLowHpHold(mobArg, hold)
    if hold then
        mobArg:removeAllGambits()
        installAaOnlyGambits(mobArg)
        mobArg:setMobAbilityEnabled(false)
        mobArg:setLocalVar('margretHold', 1)
    else
        if mobArg:getLocalVar('margretHold') == 1 then
            mobArg:removeAllGambits()
            installCombatGambits(mobArg)
            mobArg:setMobAbilityEnabled(true)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 2000)
            mobArg:setLocalVar('margretHold', 0)
        end
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.AMCHUCHU] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.LHE_LHANGAVO] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:addMod(xi.mod.TREASURE_HUNTER, 3)
    -- Store TP+40 + Ranged Attacks TP+100% (nets +140 Store TP → ~252 TP @ delay 360).
    mob:addMod(xi.mod.STORETP, 40)
    mob:addMod(xi.mod.STORETP, 100)
    mob:addMod(xi.mod.RACC, 60)

    mob:setAutoAttackEnabled(false)
    -- Out of melee (~10'); LONG_RANGE 12' historically stuck m_InTransit.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)
    -- Dump at 2000; do not try to skillchain.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 2000)

    installCombatGambits(mob)
    mob:setLocalVar('margretHold', 0)

    mob:addListener('COMBAT_TICK', 'MARGRET_LOW_HP', function(mobArg)
        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local low = battleTarget:getHPP() < LOW_HP_HOLD
        if low and mobArg:getLocalVar('margretHold') == 0 then
            setLowHpHold(mobArg, true)
        elseif not low and mobArg:getLocalVar('margretHold') == 1 then
            setLowHpHold(mobArg, false)
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
