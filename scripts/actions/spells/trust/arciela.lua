-----------------------------------
-- Trust: Arciela
-- Support RDM/PLD. Bellatrix Light (enhance + Illustrious Aid) /
-- Shadows (enfeeble + Dynastic Gravitas). Guiding Light either stance.
-- Refresh/Haste only on master + self; Haste II overwrites Haste I.
-- Light magical AA. Stationary (NO_MOVE). B-tier buffer + meleeChip.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local STANCE_LIGHT   = 1
local STANCE_SHADOWS = 2

local MS_LIGHT    = 3115
local MS_SHADOWS  = 3116
local AA_SKILL_LIST = 2103

local HASTE_II_POWER = 3000 -- ~Haste II threshold (307/1024)

local function removeGambits(mob, gambits)
    for _, id in ipairs(gambits or {}) do
        mob:removeGambit(id)
    end
end

local function hasWeakHaste(entity)
    local effect = entity:getStatusEffect(xi.effect.HASTE)
    if not effect then
        return true
    end

    return effect:getPower() < HASTE_II_POWER
end

local function needsEnhance(mob)
    local master = mob:getMaster()
    if not master or not master:isAlive() then
        return false
    end

    if
        not master:hasStatusEffect(xi.effect.PROTECT) or
        not master:hasStatusEffect(xi.effect.SHELL) or
        not master:hasStatusEffect(xi.effect.REFRESH) or
        hasWeakHaste(master)
    then
        return true
    end

    if
        not mob:hasStatusEffect(xi.effect.PROTECT) or
        not mob:hasStatusEffect(xi.effect.SHELL) or
        not mob:hasStatusEffect(xi.effect.REFRESH) or
        hasWeakHaste(mob)
    then
        return true
    end

    return false
end

local function needsEnfeeble(mob)
    local target = mob:getTarget()
    if not target or not target:isAlive() then
        return false
    end

    return
        not target:hasStatusEffect(xi.effect.SLOW) or
        not target:hasStatusEffect(xi.effect.PARALYSIS) or
        not target:hasStatusEffect(xi.effect.ADDLE)
end

local function yellowPartyCount(mob)
    local master = mob:getMaster()
    if not master then
        return 0
    end

    local count = 0
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and member:getHPP() < 75 then
            count = count + 1
        end
    end

    return count
end

local function setStance(mob, stance, gambits)
    removeGambits(mob, gambits)

    local nextGambits = {}
    if stance == STANCE_LIGHT then
        nextGambits =
        {
            -- Enhance: master first, then self only (not other trusts).
            mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT }),
            mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL }),
            mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.REFRESH }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH }),
            mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE }),
            mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECT }),
            mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELL }),
            mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.REFRESH }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REFRESH }),
            mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE }),
        }
    else
        nextGambits =
        {
            mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 30),
            mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ADDLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ADDLE }, 30),
        }
    end

    local prev = mob:getLocalVar('ArcielaStance')
    mob:setLocalVar('ArcielaStance', stance)

    if prev ~= stance then
        -- No cooldown: play stance anim when switching for spell priority.
        -- Skill-AA trusts sit in MOBABILITY_FINISH between swings.
        local action = mob:getCurrentAction()
        if
            action == xi.action.category.NONE or
            action == xi.action.category.BASIC_ATTACK or
            action == xi.action.category.MOBABILITY_FINISH
        then
            mob:useMobAbility(stance == STANCE_LIGHT and MS_LIGHT or MS_SHADOWS, mob)
        end
    end

    return nextGambits
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.ARCIELA_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MORIMAR]   = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.DARRCUILN] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.TEODOR]    = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.AUGUST]    = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Retail identity (B buffer package owns the rest).
    mob:addMod(xi.mod.MPP, 20)
    mob:addMod(xi.mod.REGAIN, 25)
    mob:addMod(xi.mod.REFRESH, 1) -- Auto-Refresh I

    -- Light magical AA (anim variants on skill list 2103).
    mob:setMobSkillAttack(AA_SKILL_LIST)

    local modeGambits = setStance(mob, STANCE_LIGHT, {})

    -- Haste II overwrite: if master/self still on weak Haste, recast HIGHEST (II).
    mob:addListener('COMBAT_TICK', 'ARCIELA_HASTE_II', function(mobArg)
        if mobArg:getLocalVar('ArcielaStance') ~= STANCE_LIGHT then
            return
        end

        local action = mobArg:getCurrentAction()
        if
            action ~= xi.action.category.NONE and
            action ~= xi.action.category.BASIC_ATTACK and
            action ~= xi.action.category.MOBABILITY_FINISH
        then
            return
        end

        local master = mobArg:getMaster()
        if master and master:isAlive() and hasWeakHaste(master) and master:hasStatusEffect(xi.effect.HASTE) then
            mobArg:castSpell(xi.magic.spell.HASTE_II, master)
            return
        end

        if hasWeakHaste(mobArg) and mobArg:hasStatusEffect(xi.effect.HASTE) then
            mobArg:castSpell(xi.magic.spell.HASTE_II, mobArg)
        end
    end)

    -- Stance switch as needed (no CD). Enhance / Aid priority over enfeeble.
    mob:addListener('COMBAT_TICK', 'ARCIELA_STANCE', function(mobArg)
        local want = mobArg:getLocalVar('ArcielaStance')
        if yellowPartyCount(mobArg) >= 2 or needsEnhance(mobArg) then
            want = STANCE_LIGHT
        elseif needsEnfeeble(mobArg) then
            want = STANCE_SHADOWS
        end

        if want ~= mobArg:getLocalVar('ArcielaStance') then
            modeGambits = setStance(mobArg, want, modeGambits)
        end
    end)

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1000)
    -- Stationary after engage; NO_MOVE inches into cast range when needed.
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
