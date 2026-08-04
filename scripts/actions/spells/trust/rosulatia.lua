-----------------------------------
-- Trust: Rosulatia
-- BLM/DRK Leafkin. Stone I–V only. No magic burst.
-- WS: Baneful Blades / Depraved Dandia / Dryad's Kiss / Matriarchal Fiat /
--     Wildwood Indignation.
-- HP+30%, MP+100% + large non-humanoid HP/MP. Top enmity → stop casting.
-- Special AA (Tree Spike / Vines+Bind / Twister+Silence); Slow-immune.
-- Dryad's Kiss @ yellow HP (<75%). RANDOM TP. Plantoid killers.
-- A-tier nuker (pressure) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_DRYAD      = 3664
local AA_SKILL_LIST = 2102

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function canAct(mobArg)
    return mobArg:isEngaged() and
        mobArg:getCurrentAction() == xi.action.category.BASIC_ATTACK
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail HP/MP package + non-humanoid pool.
    mob:addMod(xi.mod.HPP, 30)
    mob:addMod(xi.mod.MPP, 100)
    mob:addMod(xi.mod.HP, xi.trust.modGrowthValMax(mob, 700))
    mob:addMod(xi.mod.MP, xi.trust.modGrowthValMax(mob, 400))

    -- Plantoid: intimidate beasts (family also handles vermin intimidation).
    mob:addMod(xi.mod.BEAST_KILLER, 15)

    -- Special AA ignores Slow (does not benefit from Haste/Sambas either).
    mob:addImmunity(xi.immunity.SLOW)

    -- Nuker package has no melee setDamage — feed special AA / magical WS base.
    local lvl = mob:getMainLvl()
    local p   = (math.max(1, math.min(99, lvl)) / 99) ^ 1.35
    local t   = 0.94 -- A-tier
    pcall(function()
        mob:setDamage(math.floor((12 + 210 * p) * t * 0.90))
    end)
    mob:addMod(xi.mod.ACC, math.floor((40 + 600 * p) * t))
    mob:addMod(xi.mod.ATT, math.floor((25 + 420 * p) * t))
    -- Land Stone V; free-nuke only (no MB gambit).
    mob:addMod(xi.mod.MACC, 40)
    mob:addMod(xi.mod.FASTCAST, 15)

    -- Earth free nukes (spell list is Stone I–V only; no MB).
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 20)

    mob:setMobSkillAttack(AA_SKILL_LIST)
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
    -- Uses TP randomly; does not try to skillchain / MB.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 1000)

    mob:setLocalVar('rosuHateMute', 0)
    mob:setLocalVar('rosuDryad', 0)

    mob:addListener('COMBAT_TICK', 'ROSU_AI', function(mobArg)
        -- Top enmity: stop casting (special AA only).
        local hate  = hasTopEnmity(mobArg)
        local muted = mobArg:getLocalVar('rosuHateMute') == 1
        if hate and not muted then
            mobArg:setMagicCastingEnabled(false)
            mobArg:setLocalVar('rosuHateMute', 1)
        elseif not hate and muted then
            mobArg:setMagicCastingEnabled(true)
            mobArg:setLocalVar('rosuHateMute', 0)
        end

        -- Dryad's Kiss at yellow HP.
        if
            canAct(mobArg) and
            mobArg:getHPP() < 75 and
            mobArg:getTP() >= 1000 and
            (mobArg:getLocalVar('rosuDryad') == 0 or not mobArg:hasStatusEffect(xi.effect.REGEN))
        then
            mobArg:useMobAbility(MS_DRYAD, mobArg)
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
