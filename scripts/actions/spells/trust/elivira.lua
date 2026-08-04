-----------------------------------
-- Trust: Elivira
-- RNG/WAR. Sword melee + Marksmanship RA. Berserk / Barrage / Decoy / Double Shot.
-- WS: Split Shot / Slug Shot / Heavy Shot / Coronach.
-- Store TP-30, melee/RA TP+100%. Coronach → relic AM (Enmity-10).
-- Holds position (NO_MOVE). Melee if in range; RA on a short cadence.
-- Barrage only while building TP. ASAP@1000 but closes SC when possible.
-- C-tier ranged_dd (skirmisher) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_CORONACH = 216

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail TP package: Store TP-30 + Attacks TP+100% (net ~+70 Store TP).
    mob:addMod(xi.mod.STORETP, -30)
    mob:addMod(xi.mod.STORETP, 100)

    -- RACC floor so C-tier RA connects; ACC for sword swings.
    mob:addMod(xi.mod.RACC, 60)
    mob:addMod(xi.mod.ACC, 40)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
    -- Barrage only under 1000 TP — otherwise every shot is Barrage and WS never fires.
    mob:addGambit(ai.t.SELF, { { ai.c.TP_LT, 1000 }, { ai.c.NOT_STATUS, xi.effect.BARRAGE } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BARRAGE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DOUBLE_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DOUBLE_SHOT })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.DECOY_SHOT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DECOY_SHOT })

    -- RA cadence (not every tick) so sword AA still lands when she is in range.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 6)

    -- Coronach: Annihilator-style relic aftermath (Enmity -10).
    mob:addListener('WEAPONSKILL_USE', 'ELIVIRA_CORONACH_AM', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() ~= MS_CORONACH then
            return
        end

        local duration = math.max(20, math.floor(tp * 0.02))
        if mobArg:hasStatusEffect(xi.effect.ENMITY_DOWN) then
            mobArg:delStatusEffect(xi.effect.ENMITY_DOWN)
        end

        mobArg:addStatusEffect(xi.effect.ENMITY_DOWN, {
            power    = 10,
            duration = duration,
            origin   = mobArg,
        })
    end)

    -- Keep AA on (sword). Hold spawn position — neither close nor kite.
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Use TP at 1000; close a skillchain when one is available.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1000)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
