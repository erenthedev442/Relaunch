-----------------------------------
-- Trust: Cherukiki
-- WHM/BLM. Cure I–VI, Protect/ra, Shell/ra, Regen I–IV, Haste, Slow/Para/Silence.
-- Does not engage. Favors Regen over Cure. Native Regen 5 + Regen potency.
-- ~15' when not top enmity. Haste on master / self / melee DDs (not NIN).
-- C-tier healer (support) — modest cures via trust_power_scaling.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local DIST_SAFE = 15

-- Melee DD jobs that receive Haste (explicitly excludes NIN).
local HASTE_MELEE_JOBS =
{
    [xi.job.WAR] = true,
    [xi.job.MNK] = true,
    [xi.job.THF] = true,
    [xi.job.PLD] = true,
    [xi.job.DRK] = true,
    [xi.job.BST] = true,
    [xi.job.SAM] = true,
    [xi.job.DRG] = true,
    [xi.job.BLU] = true,
    [xi.job.PUP] = true,
    [xi.job.DNC] = true,
    [xi.job.RUN] = true,
}

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function canCastNow(mobArg)
    if not mobArg:isEngaged() then
        return false
    end

    local action = mobArg:getCurrentAction()
    return action == xi.action.category.NONE or action == xi.action.category.BASIC_ATTACK
end

local function castHasteOnMelee(mobArg)
    local master = mobArg:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:isAlive() and
            member:getID() ~= mobArg:getID() and
            member:getID() ~= master:getID() and
            not member:hasStatusEffect(xi.effect.HASTE) and
            HASTE_MELEE_JOBS[member:getMainJob()]
        then
            mobArg:castSpell(xi.magic.spell.HASTE, member)
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.MAKKI_CHEBUKKI] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.KUKKI_CHEBUKKI] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.PRISHE] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.TENZEN] = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Retail: native Regen 5 + Regen Effect merits / enhanced potency (modest C-tier).
    mob:addMod(xi.mod.REGEN, 5)
    mob:addMod(xi.mod.REGEN_BONUS, 8)

    -- Regen first (favors Regen over Cure).
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.REGEN }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REGEN })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.REGEN }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REGEN })
    mob:addGambit(ai.t.MELEE, { ai.c.NOT_STATUS, xi.effect.REGEN }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.REGEN })

    -- Emergency cures only at red; wake sleeps with Cure.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })

    -- Party shields before routine cures (Regen does the rest).
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.PARTY, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })

    -- Haste: master + self via gambit; other melee (not NIN) via listener.
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.HASTE })

    -- Yellow cures are secondary to Regen (C regen-healer, not a triage machine).
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- Light enfeebles (low priority).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PARALYZE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SLOW }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SLOW }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENCE }, 60)

    mob:setAutoAttackEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)

    mob:addListener('COMBAT_TICK', 'CHERUKIKI_AI', function(mobArg)
        -- ~15' without hate; close up if she draws enmity.
        if hasTopEnmity(mobArg) then
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MELEE)
        else
            mobArg:setMobMod(xi.mobMod.TRUST_DISTANCE, DIST_SAFE)
        end

        if canCastNow(mobArg) then
            castHasteOnMelee(mobArg)
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
