-----------------------------------
-- Trust: Corvus, the Black Arrow
-- Spell ID: 902 (repurposed Curilla)  |  Pool ID: 5902
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
    mob:renameEntity('Corvus', true)
	mob:getMaster():printToPlayer('spawnmessage here', xi.msg.channel.PARTY, 'Corvus')
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
	
	local rangedJobs = 
	{
		[xi.job.COR] = true,
		[xi.job.RNG] = true,
	}

    -- Ranged DD: he shoots, he never swings. He maintains 10y from the target --
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, 10)

	-- = Stats mods = --
    mob:addMod(xi.mod.HP, power)
    mob:addMod(xi.mod.DEF, power / 2)
    mob:addMod(xi.mod.MDEF, power / 2)
    mob:addMod(xi.mod.MEVA, power / 2)
	mob:addMod(xi.mod.RATT, power * 2)
	mob:addMod(xi.mod.RACC, power * 2) 
	mob:addMod(xi.mod.STR, power)
    mob:addMod(xi.mod.DEX, power)
    mob:addMod(xi.mod.AGI, power * 2)
    mob:addMod(xi.mod.RAPID_SHOT, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.DOUBLE_SHOT_RATE, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.CRITHITRATE, 10 + math.floor(power / 10))
    mob:addMod(xi.mod.STORETP, math.floor(power / 5))
	mob:addMod(xi.mod.PHANTOM_DURATION, 60) 
	
    mob:addMod(xi.mod.STATUSRES, math.floor(power / 10))
    mob:addListener('EFFECTS_TICK', 'CORVUS_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)

    -- ---- Threat control ----
    mob:addMod(xi.mod.ENMITY, -50) -- halve all the hate his shots generate

	local master = mob:getMaster()
	local masterJob = master and master:getMainJob()
	local lvl = mob:getMainLvl()

	if lvl < 99 then
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.CORSAIRS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.CORSAIRS_ROLL }) -- Use EXP boost if player isn't already max level
	end

	if masterJob and meleeJobs[masterJob] then
		-- Master is a melee or hybrid.
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.CHAOS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAOS_ROLL })  -- Attack
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.HUNTERS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.HUNTERS_ROLL }) -- ACC/RACC
	
	elseif masterJob and casterJobs[masterJob] then
		-- Master is a caster job.
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.WIZARDS_ROLL },
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.WIZARDS_ROLL })  -- MATT
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.WARLOCKS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.WARLOCKS_ROLL })  -- MACC Roll
	elseif masterJob and rangedJobs[masterJob] then
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.CHAOS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.CHAOS_ROLL })  -- Attack
		mob:addGambit(ai.t.PARTY, 
			{ ai.c.NOT_STATUS, xi.effect.HUNTERS_ROLL }, 
			{ ai.r.JA, ai.s.SPECIFIC, xi.ja.HUNTERS_ROLL }) -- ACC/RACC
	end

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.RANDOM, 3000)

    -- ---- Ranged auto-shots: bread-and-butter damage + TP building. ----
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, ai.s.SPECIFIC, 0 }, 5)
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
	mob:getMaster():printToPlayer('deathmessage here', xi.msg.channel.PARTY, 'Corvus')
    -- Same as above.
end

return spellObject
