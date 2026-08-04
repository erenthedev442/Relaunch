-----------------------------------
-- Trust: Tenzen
-- SAM/SAM Great Katana. Amatsu Torimai / Kazakiri / Yukiarashi /
-- Tsukioboro / Hanaikusa / Tsukikage. Hasso, Save TP+400, Meditate,
-- Hagakure, Third Eye. ~203 TP/hit (STORE_TP + delay 440).
-- Holds to 1500 to close. When Meditate + Hagakure ready: 3-step Light
-- (Yukiarashi > Tsukioboro > Hanaikusa). C-tier weaponskill — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Story / Trust Amatsu IDs (shared Lua; Trust fTP branched in mobskills).
local WS_YUKIARASHI = 1392
local WS_TSUKIOBORO = 1393
local WS_HANAIKUSA  = 1394

local RECAST_HAGAKURE = 54
local RECAST_MEDITATE = 134

local SOLO_SEQ =
{
    WS_YUKIARASHI,
    WS_TSUKIOBORO,
    WS_HANAIKUSA,
}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.TENZEN_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Tenzen
    if caster:getEminenceProgress(935) then
        xi.roe.onRecordTrigger(caster, 935)
    end

    return xi.trust.spawn(caster, spell)
end

local function soloPackageReady(mob)
    return not mob:hasRecast(xi.recast.ABILITY, RECAST_HAGAKURE) and
        not mob:hasRecast(xi.recast.ABILITY, RECAST_MEDITATE)
end

local function queueSoloWS(mob, step)
    mob:timer(1800, function(mobArg)
        if mobArg:getLocalVar('tenzenSoloStep') ~= step then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            mobArg:setLocalVar('tenzenSoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
            return
        end

        if mobArg:hasStatusEffect(xi.effect.HAGAKURE) then
            mobArg:setTP(math.max(mobArg:getTP(), 2000))
        end

        mobArg:useMobAbility(SOLO_SEQ[step], target)
    end)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.IROHA] = xi.trust.messageOffset.TEAMWORK_1,
    })

    mob:addMod(xi.mod.SAVETP, 400)
    -- Delay 440 base ~124 TP; +64 STP → ~203 / hit (power package may add more STP).
    mob:addMod(xi.mod.STORETP, 64)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    mob:setLocalVar('tenzenSoloStep', 0)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)

    -- 3-step Light when Hagakure + Meditate are both ready.
    mob:addListener('COMBAT_TICK', 'TENZEN_SOLO_SC', function(mobArg)
        if mobArg:getLocalVar('tenzenSoloStep') > 0 then
            return
        end

        if not soloPackageReady(mobArg) then
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
            return
        end

        -- Package ready: hold for solo @2000 (don't spend closing foreign SCs).
        mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 3000)

        if not mobArg:hasStatusEffect(xi.effect.HAGAKURE) then
            mobArg:useJobAbility(xi.ja.HAGAKURE, mobArg)
            return
        end

        if mobArg:getTP() < 2000 then
            return
        end

        local target = mobArg:getTarget()
        if not target or not target:isAlive() then
            return
        end

        mobArg:useJobAbility(xi.ja.MEDITATE, mobArg)
        mobArg:setLocalVar('tenzenSoloStep', 1)
        mobArg:useMobAbility(WS_YUKIARASHI, target)
    end)

    mob:addListener('WEAPONSKILL_USE', 'TENZEN_SOLO_WS', function(mobArg, target, skill, tp, action, damage)
        local step = mobArg:getLocalVar('tenzenSoloStep')
        if step <= 0 then
            return
        end

        if skill:getID() ~= SOLO_SEQ[step] then
            return
        end

        if step >= #SOLO_SEQ then
            mobArg:setLocalVar('tenzenSoloStep', 0)
            mobArg:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
            return
        end

        local nextStep = step + 1
        mobArg:setLocalVar('tenzenSoloStep', nextStep)
        queueSoloWS(mobArg, nextStep)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
