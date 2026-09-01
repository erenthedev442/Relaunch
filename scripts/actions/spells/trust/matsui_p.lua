-----------------------------------
-- Trust: Matsui-P
-- Spell ID: 1004 | Pool ID: 6004
-- Menu / DAT: Excenmille (S). Nametag: matsui-p (Lua overlay).
-- Do not /ma "Matsui-P" — that is seasonal spell 1003 and R0s the client.
-- Do not renameEntity to the retail string 'Matsui-P' (same DAT key).
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
    -- Overlay only. Must run before CTrustEntity::Spawn sends 0x67.
    mob:renameEntity('matsui-p', true)

    local master = mob:getMaster()
    if not master then
        return
    end

    local lvl = mob:getMainLvl()
    local upgraded = math.max(1, master:getCharVar('TrustUpgraded') or 1)
    local power = lvl * upgraded

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

    master:printToPlayer('matsui-p reporting. Try to keep up.', xi.msg.channel.PARTY, 'matsui-p')
end

spellObject.onMobDespawn = function(mob)
end

spellObject.onMobDeath = function(mob)
end

return spellObject
