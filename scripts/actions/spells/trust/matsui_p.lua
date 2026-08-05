-----------------------------------
-- Trust: Matsui-P
-- Spell ID: 1003  |  Pool ID: 6003  (client menu name: Matsui-P)
-- Known-good summon config (pre-round5). Wrong kit on purpose until
-- summon is re-verified; then kit can be retuned carefully.
-- Exception hard cap via trust_power_scaling. Script keeps kit + flavor.
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
    -- Model comes from mob_pools look 0x0000310C (3121), not setModelId.
    mob:renameEntity('Matsui-P', true)

    local master = mob:getMaster()
    local lvl = mob:getMainLvl()
    local upgraded = math.max(1, master:getCharVar('TrustUpgraded') or 1)
    local power = lvl * upgraded

    -- Flavor on top of global scaler floors (do not fight EncounterOutgoingDamageCap).
    mob:addMod(xi.mod.HP, power)
    mob:addMod(xi.mod.STR, math.floor(power * 0.5))
    mob:addMod(xi.mod.DEX, math.floor(power * 0.5))
    mob:addMod(xi.mod.INT, math.floor(power * 0.5))
    mob:addMod(xi.mod.ATT, power)
    mob:addMod(xi.mod.ACC, power)
    mob:addMod(xi.mod.MATT, power)
    mob:addMod(xi.mod.MACC, power)
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.CRITHITRATE, 15 + math.floor(power / 15))
    mob:addMod(xi.mod.STORETP, math.floor(power / 6))
    -- xi.mod.WSD was removed; ALL_WSDMG_ALL_HITS is the current equivalent.
    mob:addMod(xi.mod.ALL_WSDMG_ALL_HITS, 50 + math.floor(power / 8))
    mob:addMod(xi.mod.MAGIC_DAMAGE, math.floor(power * 0.75))
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 40)

    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 60)
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.HASSO }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.HASSO })
    mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.MEDITATE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.MEDITATE })

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2000)

    master:printToPlayer('Matsui-P reporting. Try to keep up.', xi.msg.channel.PARTY, 'Matsui-P')
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
end

return spellObject
