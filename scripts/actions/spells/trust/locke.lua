-----------------------------------
-- Trust: Locke, the Forgotten Bandit
-- Replaces Aldo
-- THF/DNC melee DD + support
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
    mob:renameEntity('Locke', true)
	mob:getMaster():printToPlayer('I prefer the term "treasure hunter"!', xi.msg.channel.PARTY, 'Locke')
	local master = mob:getMaster()
	local power = mob:getMainLvl() * master:getCharVar("TrustUpgraded")

    local meleeJobs =
    {
        [xi.job.WAR] = true,
        [xi.job.MNK] = true,
        [xi.job.THF] = true,
        [xi.job.PLD] = true,
        [xi.job.DRK] = true,
        [xi.job.BST] = true,
        [xi.job.SAM] = true,
        [xi.job.NIN] = true,
        [xi.job.DRG] = true,
        [xi.job.BLU] = true,
        [xi.job.PUP] = true,
        [xi.job.DNC] = true,
        [xi.job.RUN] = true,
		[xi.job.COR] = true, -- adding COR as a melee job mainly because theres no ranged benefiting step.
		[xi.job.RNG] = true, -- Same logic as above.
    }

    local casterJobs =
    {
        [xi.job.WHM] = true,
        [xi.job.BLM] = true,
        [xi.job.RDM] = true,
        [xi.job.BRD] = true,
        [xi.job.SMN] = true,
        [xi.job.BLU] = true,
        [xi.job.SCH] = true,
        [xi.job.GEO] = true,
        [xi.job.RUN] = true,
    }

    local function addStepMaintenance(listenerName, effectId, jobAbilityId)
        local maxStepPower = 5
        local refreshBelow = 30000 -- 30 seconds, in milliseconds.
        local retrySeconds = 5
        local stepGambit = nil

        mob:addListener('COMBAT_TICK', listenerName, function(mobArg)
            local target = mobArg:getTarget()

            if not target then
                if stepGambit then
                    mobArg:removeGambit(stepGambit)
                    stepGambit = nil
                end

                return
            end

            local effect = target:getStatusEffect(effectId)
            local power = effect and effect:getPower() or 0
            local timeRemaining = effect and effect:getTimeRemaining() or 0

            local shouldStep =
                power < maxStepPower or
                (
                    power >= maxStepPower and
                    timeRemaining < refreshBelow
                )

            if shouldStep and not stepGambit then
                stepGambit = mobArg:addGambit(
                    ai.t.TARGET,
                    { ai.c.ALWAYS, 0 },
                    { ai.r.JA, ai.s.SPECIFIC, jobAbilityId },
                    retrySeconds
                )
            elseif not shouldStep and stepGambit then
                mobArg:removeGambit(stepGambit)
                stepGambit = nil
            end
        end)
    end

    -----------------------------------
    -- Combat Behavior
    -----------------------------------
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 2)

    -----------------------------------
    -- Survivability
    -----------------------------------
    mob:addMod(xi.mod.HP, power)
    mob:addMod(xi.mod.DEF, power / 2)
    mob:addMod(xi.mod.MDEF, power / 2)
    mob:addMod(xi.mod.MEVA, power / 2)

    -----------------------------------
    -- Status Immunities
    -----------------------------------
    mob:addMod(xi.mod.STATUSRES, math.floor(power / 10))
    mob:addListener('EFFECTS_TICK', 'LOCKE_AILMENT_WARD', function(mobArg)
        for _, effect in ipairs({
            xi.effect.AMNESIA,
            xi.effect.DOOM,
            xi.effect.CURSE_I,
            xi.effect.CURSE_II,
        }) do
            if mobArg:hasStatusEffect(effect) then
                mobArg:delStatusEffectSilent(effect)
            end
        end
    end)

    -----------------------------------
    -- Enmity Control
    -----------------------------------
    mob:addMod(xi.mod.ENMITY, -20)
    -----------------------------------
    -- Melee Damage Package
    -----------------------------------
    mob:addMod(xi.mod.ATT, power * 2)
    mob:addMod(xi.mod.ACC, power * 3)
    mob:addMod(xi.mod.STR, power)
    mob:addMod(xi.mod.DEX, power * 2)
    mob:addMod(xi.mod.AGI, power)
    mob:addMod(xi.mod.CRITHITRATE, 15 + math.floor(power / 10))
    mob:addMod(xi.mod.CRIT_DMG_INCREASE, 15 + math.floor(power / 10))
    mob:addMod(xi.mod.DOUBLE_ATTACK, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.TRIPLE_ATTACK, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.QUAD_ATTACK, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.HASTE_GEAR, 1400 + math.floor(power / 2))
    mob:addMod(xi.mod.STORETP, math.floor(power / 5))
    mob:addMod(xi.mod.EVA, power)

    -----------------------------------
    -- Treasure Hunter Handler see LockeTH.lua
    -----------------------------------
    local master = mob:getMaster()
    local lockeTH = 1

    if master then
        lockeTH = master:getCharVar('LockeTH')

        if lockeTH < 1 then
            lockeTH = 1
        elseif lockeTH > 30 then
            lockeTH = 30
        end
    end

    mob:addMod(xi.mod.TREASURE_HUNTER, lockeTH)

    -----------------------------------
    -- /DNC Mods
    -----------------------------------
    mob:addMod(xi.mod.WALTZ_POTENCY, math.floor(power / 10)) -- scaled with level and upgrade paths.
    mob:addMod(xi.mod.SAMBA_DURATION, 60) -- Samba+ duration QoL so isn't using it more often.

    -----------------------------------
    -- Weaponskills -- Uses Rudra's Storm and Mandalic Stab
    -----------------------------------
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)

    -----------------------------------
    -- Gambits
    -----------------------------------
    mob:addGambit(
        ai.t.SELF,
        { ai.c.NOT_STATUS, xi.effect.HASTE_SAMBA },
        { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASTE_SAMBA }
    )

    -- Box Step: stack to 5 first, then only refresh when under 30 seconds.
    addStepMaintenance(
        'LOCKE_BOX_STEP_MAINTENANCE',
        xi.effect.SLUGGISH_DAZE_1,
        xi.ja.BOX_STEP
    )

    local masterJob = master and master:getMainJob()

    if masterJob and meleeJobs[masterJob] then
        -- Quickstep for melee masters.
        addStepMaintenance(
            'LOCKE_QUICKSTEP_MAINTENANCE',
            xi.effect.LETHARGIC_DAZE_1,
            xi.ja.QUICKSTEP
        )
    elseif masterJob and casterJobs[masterJob] then
        -- Stutter Step for caster masters.
        addStepMaintenance(
            'LOCKE_STUTTER_STEP_MAINTENANCE',
            xi.effect.WEAKENED_DAZE_1,
            xi.ja.STUTTER_STEP
        )
    end

    mob:addGambit(
        ai.t.MASTER,
        { ai.c.HPP_LT, 50 },
        { ai.r.JA, ai.s.SPECIFIC, xi.ja.CURING_WALTZ_IV }
    )

    mob:addGambit(
        ai.t.SELF,
        { ai.c.HPP_LT, 45 },
        { ai.r.JA, ai.s.SPECIFIC, xi.ja.CURING_WALTZ_IV }
    )
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
	mob:getMaster():printToPlayer("After all the plunder I got us, you still couldn't protect me", xi.msg.channel.PARTY, 'Locke')
end

return spellObject
