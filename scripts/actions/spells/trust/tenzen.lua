-----------------------------------
-- Trust: Tenzen
-----------------------------------
---@type TSpellTrust
local spellObject = {}

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

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.IROHA] = xi.trust.messageOffset.TEAMWORK_1,
    })

	-- Base level trust (power = mLevel).
	local master = mob:getMaster()
	local power = math.floor(mob:getMainLvl() * 1)
	local zpower = math.floor(mob:getMainLvl() / 5)
	-- Stats Mods --
	mob:addMod(xi.mod.ATT, power)
	mob:addMod(xi.mod.ACC, power)
	mob:addMod(xi.mod.STR, power)
	mob:addMod(xi.mod.DEX, power)
	mob:addMod(xi.mod.EVA, power)
	mob:addMod(xi.mod.MEVA, power)
	mob:addMod(xi.mod.STORETP, zpower)
	mob:addMod(xi.mod.SAVETP, 400)
	mob:addMod(xi.mod.DOUBLE_ATTACK, 10)
    mob:addMod(xi.mod.HASTE_GEAR, 1500)
    mob:addMod(xi.mod.HP, power * 2)
	mob:addMod(xi.mod.MP, power * 2)

    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
	mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MEDITATE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })
	mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HAGAKURE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HAGAKURE })

    mob:addGambit(ai.t.SELF, { ai.c.HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.THIRD_EYE })

    mob:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
