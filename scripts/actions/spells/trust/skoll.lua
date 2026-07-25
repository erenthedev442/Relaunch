-----------------------------------
-- Trust: Gemma
-- Spell ID: 901 (repurposed Nanaa Mihgo)  |  Pool ID: 5901  | 
-- Trust menu shows "Nanaa Mihgo" client-side;
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
    --
    mob:renameEntity('Gemma', true)
	mob:getMaster():printToPlayer('Stay close - I can keep us alive and inspired.', xi.msg.channel.PARTY, 'Gemma')
	local master = mob:getMaster()
	local power = mob:getMainLvl() * master:getCharVar("TrustUpgraded") -- 99 * 1 / 99 * 3 / 99 * 5 / 99 * 7 -- TrustUpgraded grows as you complete server content.
	-- Job handle for choose which BRD songs to play.
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
		[xi.job.RNG] = true,
		[xi.job.COR] = true,
	}

	-- = Stat mods =
	mob:addMod(xi.mod.HP, power * 1.5)
	mob:addMod(xi.mod.MP, power * 4)
	mob:addMod(xi.mod.DEF, power)
    mob:addMod(xi.mod.MDEF, power)
    mob:addMod(xi.mod.MEVA, power)
    mob:addMod(xi.mod.EVA,  power)
	mob:addMod(xi.mod.MATT,  power)
	mob:addMod(xi.mod.MACC, power * 2)
	mob:addMod(xi.mod.INT, power)
	mob:addMod(xi.mod.MND, power * 2)
	mob:addMod(xi.mod.HASTE_MAGIC, power)
	mob:addMod(xi.mod.FASTCAST, 15)
	mob:addMod(xi.mod.ENF_MAG_DURATION, 60) -- 60 second increase to Enfeeble duration.
	mob:addMod(xi.mod.SONG_DURATION_BONUS, 60) -- 60 second bonus to song duration.
	mob:addMod(xi.mod.ENH_MAGIC_DURATION, 120) -- 120 second bonus to Enhancing Magic duration - purely QoL.
	mob:addMod(xi.mod.REFRESH, xi.trust.modGrowthValMax(mob, 30)) -- Gradually scales from 1 - 30 Refresh at level 99.
	
	mob:addMod(xi.mod.SLEEPRES, 100) -- Negates sleep, similar to some other healer trusts.

    ----------------------------------------------------------
    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
	----------------------------------------------------------
    mob:addMod(xi.mod.STATUSRES, math.floor(power / 10))  -- Resist all status effects, calcuted at (MaxLevel / 10) rounded up, should be 10% at level 99.
    mob:addListener('EFFECTS_TICK', 'SKOLL_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)
	----------------------------------------------------------
    mob:setLocalVar('SKOLL_WIDE_AOE', 1)          -- read by the song-radius override
	----------------------------------------------------------
	
	-- = Healing Gambits: Top priority =
	
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 25 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURAGA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURAGA })
    mob:addGambit(ai.t.PARTY_DEAD, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.RAISE })
	mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
	
	-- = Silence 2nd Priority --
	mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENCE }, 60) -- reduced Gemma's accuracy so keep 60seconds recast incase Silence resists.
	
	-- = Status Removal --
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA  })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA  })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA   })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA    })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA   })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA   })
	mob:addGambit(ai.t.SELF,  { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
	
	-- = Enhancing Magic --
	mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PROTECT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PROTECTRA })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.SHELL }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.SHELLRA })
    mob:addGambit(ai.t.MASTER, { ai.c.NOT_STATUS, xi.effect.HASTE }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.HASTE })
	
	-- = Aquaveil logic --
	mob:addGambit(ai.t.SELF, { { ai.c.NOT_STATUS, xi.effect.AQUAVEIL }, { ai.c.NOT_PT_HAS_TANK, 0 } }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AQUAVEIL })	

	-- = Bard Songs; Choosen based on the summoners main job. --
	local masterJob = master and master:getMainJob()
	local lvl = mob:getMainLvl()
	
	if masterJob and meleeJobs[masterJob] then
		-- Master is a melee or hybrid.
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.MADRIGAL }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.MADRIGAL })  -- ACC
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.MINUET }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.VALOR_MINUET }) -- ATT/RATT
	
	elseif masterJob and casterJobs[masterJob] then
		-- Master is a caster job.
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.ETUDE }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.INT_ETUDE })  -- INT+
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.BALLAD }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.MAGES_BALLAD }) -- Refresh
	
	elseif masterJob and rangedJobs[masterJob] then
		-- Master if a Ranged Job
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.PRELUDE }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PRELUDE })  -- RACC
		mob:addGambit(ai.t.SELF, 
			{ ai.c.NOT_STATUS, xi.effect.MINUET }, 
			{ ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily._VALOR_MINUET }) -- ATT/RATT
	end

    mob:addGambit(ai.t.SELF, { 
		{ ai.c.NOT_STATUS, xi.effect.AQUAVEIL }, { ai.c.NOT_PT_HAS_TANK, 0 } },
		{ ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.AQUAVEIL }
	)
	
    mob:addGambit(ai.t.TARGET, { ai.c.STATUS_FLAG, xi.effectFlag.DISPELABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.DISPEL })
end

spellObject.onMobDespawn = function(mob)

end

spellObject.onMobDeath = function(mob)
	mob:getMaster():printToPlayer('The song... ends here...', xi.msg.channel.PARTY, 'Gemma')
    -- Same as above.
end

return spellObject
