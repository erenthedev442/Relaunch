-----------------------------------
-- Trust: Meat, the Immovable  --  the ULTIMATE TANK
-- Spell ID: 899 (repurposed Excenmille) | Pool ID: 5899 | Model: tiny Tarutaru -- Koru-Moru trust model 0x0BF1 (species 255, kept for stats)

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
    mob:renameEntity('Meat', true)
	mob:getMaster():printToPlayer('Stand behind me and fear nothing.', xi.msg.channel.PARTY, 'Meat')
    
	local master = mob:getMaster()
	local power = mob:getMainLvl() * master:getCharVar("TrustUpgraded") -- 99 * 1 / 99 * 3 / 99 * 5 / 99 * 7 -- TrustUpgraded grows as you complete server content.

	mob:setAutoAttackEnabled(true)
    -- = Stat Mods = --
    mob:addMod(xi.mod.HP,  power * 4)
    mob:addMod(xi.mod.DEF, power)
    mob:addMod(xi.mod.MDEF, power)
    mob:addMod(xi.mod.MEVA, power)
	mob:addMod(xi.mod.VIT, power)
	mob:addMod(xi.mod.STR, power / 2)
    mob:addMod(xi.mod.EVA,  power)
	mob:addMod(xi.mod.ACC, power * 4)
	mob:addMod(xi.mod.MACC, power * 3)
    mob:addMod(xi.mod.SHIELDBLOCKRATE, 35)
    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)
    mob:addMod(xi.mod.ENMITY, 100)
    mob:addMod(xi.mod.FASTCAST, 10)
    mob:addMod(xi.mod.SPELLINTERRUPT, 30)
    mob:addMod(xi.mod.MP, power)

    mob:addMod(xi.mod.STATUSRES, math.floor(power / 5))
    mob:addListener('EFFECTS_TICK', 'MEAT_AILMENT_WARD', function(mobArg)
        for _, eff in ipairs({ xi.effect.AMNESIA, xi.effect.DOOM, xi.effect.CURSE_I, xi.effect.CURSE_II }) do
            if mobArg:hasStatusEffect(eff) then
                mobArg:delStatusEffectSilent(eff)
            end
        end
    end)

    -- = Tanking Gambits = --
    mob:addGambit(ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    -- Divine Emblem fires just before Flash -> a hugely enmity-enhanced Flash.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.DIVINE_EMBLEM })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH })
    -- Shield Bash attempts to interupt a mobs cast.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH})
	mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH})
	mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH})
	-- = Damage mitigation = --
	mob:addGambit(ai.t.SELF,   { ai.c.NOT_STATUS, xi.effect.SENTINEL }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
	mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.MAJESTY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MAJESTY })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.REPRISAL }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.REPRISAL })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.PHALANX  }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PHALANX })

    -- Back up self heal, typical PLD.
    mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST,  xi.magic.spellFamily.CURE })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.RANDOM, 1500)
end

spellObject.onMobDespawn = function(mob)

end

spellObject.onMobDeath = function(mob)
	mob:getMaster():printToPlayer('The rest is on you..', xi.msg.channel.PARTY, 'Meat')
    -- Should never fire -- Meat is unkillable. Left intentionally silent.
end

return spellObject
