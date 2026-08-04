-----------------------------------
-- Trust: Makki-Chebukki
-- RNG/BLM Archery. Flashy Shot / Sharpshot / Barrage.
-- WS: Flaming Arrow / Dulling Arrow / Sidewinder / Empyreal Arrow.
-- MP+100%, Store TP-40, Ranged Attacks TP+100% (~168 TP/hit at delay 500).
-- Stays out of melee range. WS at 2000 TP; does not skillchain.
-- Lightsday: paths out of range and takes no combat actions until day changes.
-- S-tier ranged_dd (weaponskill) — no kit inject (custom AI).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local function installCombatGambits(mob)
    -- Barrage only while building toward 2000 TP.
    mob:addGambit(ai.t.SELF, {
        { ai.c.TP_LT, 2000 },
        { ai.c.NOT_STATUS, xi.effect.BARRAGE },
    }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHARPSHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHARPSHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.FLASHY_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.FLASHY_SHOT })
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 })
end

local function setLightsdayIdle(mobArg, idle)
    if idle then
        mobArg:removeAllGambits()
        mobArg:setMobAbilityEnabled(false)
        mobArg:setLocalVar('makkiLightsday', 1)
    else
        if mobArg:getLocalVar('makkiLightsday') == 1 then
            installCombatGambits(mobArg)
            mobArg:setMobAbilityEnabled(true)
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 2000)
            mobArg:setLocalVar('makkiLightsday', 0)
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
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:addMod(xi.mod.MPP, 100)
    -- Store TP-40 + Ranged Attacks TP+100% (nets ~+60 Store TP → ~168 TP @ delay 500).
    mob:addMod(xi.mod.STORETP, -40)
    mob:addMod(xi.mod.STORETP, 100)

    -- RACC floor so S-tier shots connect (power path also stacks RACC).
    mob:addMod(xi.mod.RACC, 80)

    mob:setAutoAttackEnabled(false)
    -- Out of melee (~10'); LONG_RANGE 12' historically stuck m_InTransit.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)
    -- Dump at 2000; do not try to skillchain.
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 2000)

    if VanadielDayOfTheWeek() == xi.day.LIGHTSDAY then
        mob:setLocalVar('makkiLightsday', 1)
        mob:setMobAbilityEnabled(false)
    else
        installCombatGambits(mob)
        mob:setLocalVar('makkiLightsday', 0)
    end

    mob:addListener('COMBAT_TICK', 'MAKKI_LIGHTSDAY', function(mobArg)
        local lightsday = VanadielDayOfTheWeek() == xi.day.LIGHTSDAY
        if lightsday and mobArg:getLocalVar('makkiLightsday') == 0 then
            setLightsdayIdle(mobArg, true)
        elseif not lightsday and mobArg:getLocalVar('makkiLightsday') == 1 then
            setLightsdayIdle(mobArg, false)
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
