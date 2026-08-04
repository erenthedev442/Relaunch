-----------------------------------
-- Trust: Arciela II
-- Offensive RDM/BLM. Alternates Ascension (Light) / Descension (Dark)
-- every 90s. Mode-gated nukes + WS. Job-based Haste II / Flurry II / Refresh II.
-- A-tier hybrid (burst) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MODE_SECONDS = 90
local ASCENSION    = 1
local DESCENSION   = 2

local MS_ASCENSION = 3697
local MS_DESCENSION = 3698
local MS_NAAKUAL   = 3705

-- Haste II jobs (retail).
local HASTE_JOBS =
{
    [xi.job.WAR] = true, [xi.job.MNK] = true, [xi.job.THF] = true,
    [xi.job.PLD] = true, [xi.job.DRK] = true, [xi.job.BST] = true,
    [xi.job.SAM] = true, [xi.job.NIN] = true, [xi.job.DRG] = true,
    [xi.job.BLU] = true, [xi.job.PUP] = true, [xi.job.DNC] = true,
    [xi.job.RUN] = true,
}

-- Flurry II: RNG / COR.
local FLURRY_JOBS =
{
    [xi.job.RNG] = true,
    [xi.job.COR] = true,
}

-- Refresh II: WHM/BLM/RDM/PLD/SMN/GEO/RUN/SCH*, or WHM sub.
local REFRESH_JOBS =
{
    [xi.job.WHM] = true, [xi.job.BLM] = true, [xi.job.RDM] = true,
    [xi.job.PLD] = true, [xi.job.SMN] = true, [xi.job.GEO] = true,
    [xi.job.RUN] = true, [xi.job.SCH] = true,
}

local function canAct(mobArg)
    local action = mobArg:getCurrentAction()
    return mobArg:isEngaged() and
        (action == xi.action.category.NONE or
            action == xi.action.category.BASIC_ATTACK or
            action == xi.action.category.MOBABILITY_FINISH)
end

local function schBlockingRefresh(member)
    return member:getMainJob() == xi.job.SCH and
        (member:hasStatusEffect(xi.effect.SUBLIMATION_ACTIVATED) or
            member:hasStatusEffect(xi.effect.SUBLIMATION_COMPLETE))
end

local function wantsRefresh(member)
    if not member:isAlive() or member:hasStatusEffect(xi.effect.REFRESH) then
        return false
    end

    if schBlockingRefresh(member) then
        return false
    end

    if REFRESH_JOBS[member:getMainJob()] then
        return true
    end

    return member:getSubJob() == xi.job.WHM
end

local function wantsHaste(member)
    return member:isAlive() and
        HASTE_JOBS[member:getMainJob()] and
        not member:hasStatusEffect(xi.effect.HASTE)
end

local function wantsFlurry(member)
    return member:isAlive() and
        FLURRY_JOBS[member:getMainJob()] and
        not member:hasStatusEffect(xi.effect.FLURRY) and
        not member:hasStatusEffect(xi.effect.FLURRY_II) and
        not member:hasStatusEffect(xi.effect.HASTE)
end

local function tryJobBuffs(mobArg)
    if mobArg:getLocalVar('ArcielaMode') ~= ASCENSION or not canAct(mobArg) then
        return
    end

    local master = mobArg:getMaster()
    if not master then
        return
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if wantsFlurry(member) then
            mobArg:castSpell(xi.magic.spell.FLURRY_II, member)
            return
        end
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if wantsHaste(member) then
            mobArg:castSpell(xi.magic.spell.HASTE_II, member)
            return
        end
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if wantsRefresh(member) then
            mobArg:castSpell(xi.magic.spell.REFRESH_II, member)
            return
        end
    end
end

local function removeGambits(mob, gambits)
    for _, id in ipairs(gambits or {}) do
        mob:removeGambit(id)
    end
end

local function setMode(mob, mode, gambits)
    removeGambits(mob, gambits)

    local nextGambits = {}
    if mode == ASCENSION then
        -- Light: enhance + Fire / Wind / Thunder nukes (and MB of those).
        nextGambits =
        {
            mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT }),
            mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL }),
            -- MB first (double-burst when window allows), then free nukes.
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FIRE }),
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.THUNDER }),
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.AERO }),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.FIRE }, 40),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.THUNDER }, 40),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.AERO }, 40),
        }
    else
        -- Dark: enfeeble + Earth / Water / Ice nukes.
        nextGambits =
        {
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ADDLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ADDLE }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZARD }),
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.STONE }),
            mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.WATER }),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.BLIZZARD }, 40),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.STONE }, 40),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.WATER }, 40),
        }
    end

    mob:setLocalVar('ArcielaMode', mode)
    mob:setLocalVar('ArcielaModeChanged', os.time())
    return nextGambits
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ARCIELA)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.LION_II]      = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.PRISHE_II]    = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.NASHMEIRA_II] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.LILISETTE_II] = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Retail identity; hybrid A (burst) package owns AA/WS/nuke curve.
    mob:addMod(xi.mod.MPP, 50)
    mob:addMod(xi.mod.ENH_MAGIC_DURATION, 25)
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.UFASTCAST, 25)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 45)

    -- Always available: Dispel (either mode).
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })

    local modeGambits = setMode(mob, ASCENSION, {})

    -- 90s Ascension <-> Descension; pulse damages the battle target.
    mob:addListener('COMBAT_TICK', 'ARCIELA_II_MODE', function(mobArg)
        if os.time() - mobArg:getLocalVar('ArcielaModeChanged') < MODE_SECONDS then
            return
        end

        local nextMode = mobArg:getLocalVar('ArcielaMode') == ASCENSION and DESCENSION or ASCENSION
        modeGambits = setMode(mobArg, nextMode, modeGambits)

        local battleTarget = mobArg:getTarget()
        if battleTarget and canAct(mobArg) then
            mobArg:useMobAbility(nextMode == ASCENSION and MS_ASCENSION or MS_DESCENSION, battleTarget)
        end
    end)

    -- Job-accurate Haste II / Flurry II / Refresh II while in Ascension.
    mob:addListener('COMBAT_TICK', 'ARCIELA_II_JOB_BUFFS', function(mobArg)
        tryJobBuffs(mobArg)
    end)

    -- Naakual's Vengeance: low HP, 1000 TP, 5-minute CD. AoE Light + full restore.
    mob:setLocalVar('naakualReady', 0)
    mob:addListener('COMBAT_TICK', 'ARCIELA_II_NAAKUAL', function(mobArg)
        if mobArg:getLocalVar('naakualReady') > os.time() then
            return
        end

        if mobArg:getHPP() >= 35 or mobArg:getTP() < 1000 or not canAct(mobArg) then
            return
        end

        local battleTarget = mobArg:getTarget()
        if not battleTarget then
            return
        end

        mobArg:setLocalVar('naakualReady', os.time() + 300)
        mobArg:useMobAbility(MS_NAAKUAL, battleTarget)
    end)

    -- WS at 1000 TP (mode-gated by skill checks).
    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
