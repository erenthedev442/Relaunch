-----------------------------------
-- Trust: Lilisette
-- DNC/DNC. Dagger (appears DW; single AA per round).
-- TP moves: Whirling Edge (AoE) / Dancer's Fury / Rousing Samba /
--   Sensual Dance / Thorn Dance / Vivifying Waltz.
-- No skillchain participation. Default dump ~1500 TP.
-- Vivifying / Thorn prioritized when conditions are met.
-- A-tier melee_dd (skirmisher) power path — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_THORN     = 3308
local MS_SENSUAL   = 3309
local MS_FURY      = 3310
local MS_WHIRLING  = 3311
local MS_ROUSING   = 3312
local MS_VIVIFYING = 3313

local OFFENSE_POOL = { MS_WHIRLING, MS_FURY, MS_ROUSING, MS_SENSUAL }

local function countPartyHpBands(mob)
    local yellow = 0 -- <75%
    local orange = 0 -- <50%
    local master = mob:getMaster()
    if not master then
        return yellow, orange
    end

    for _, member in ipairs(master:getPartyWithTrusts()) do
        if member:isAlive() and mob:checkDistance(member) <= 20 then
            local hpp = member:getHPP()
            if hpp < 50 then
                orange = orange + 1
                yellow = yellow + 1
            elseif hpp < 75 then
                yellow = yellow + 1
            end
        end
    end

    return yellow, orange
end

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.LILISETTE_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Visual DW only — dagger trusts are already single-swing (no H2H/DW flag).
    mob:setMobMod(xi.mobMod.DUAL_WIELD, 0)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Block built-in picker; custom priority below (no SC closer).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 3001)

    mob:addListener('COMBAT_TICK', 'LILISETTE_TP', function(mobArg)
        local tp = mobArg:getTP()
        if tp < 1000 then
            return
        end

        -- Cooldown gate so failed/queued skills don't spam.
        if mobArg:getLocalVar('liliWsLock') > GetSystemTime() then
            return
        end

        if not mobArg:isEngaged() then
            return
        end

        if mobArg:getCurrentAction() ~= xi.action.category.BASIC_ATTACK then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget or not battleTarget:isAlive() then
            return
        end

        local skillId = nil

        -- Thorn Dance: top enmity, can fire under 1500 TP.
        if
            hasTopEnmity(mobArg) and
            not mobArg:hasStatusEffect(xi.effect.DEFENSE_BOOST)
        then
            skillId = MS_THORN
        else
            local yellow, orange = countPartyHpBands(mobArg)
            -- Vivifying: @1000 if anyone orange; @1500 if 2+ yellow.
            if
                (orange >= 1 and tp >= 1000) or
                (yellow >= 2 and tp >= 1500)
            then
                skillId = MS_VIVIFYING
            elseif tp >= 1500 then
                skillId = OFFENSE_POOL[math.random(#OFFENSE_POOL)]
            end
        end

        if not skillId then
            return
        end

        mobArg:setLocalVar('liliWsLock', GetSystemTime() + 4)

        if skillId == MS_FURY or skillId == MS_WHIRLING then
            mobArg:useMobAbility(skillId, battleTarget)
        else
            mobArg:useMobAbility(skillId, mobArg)
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
