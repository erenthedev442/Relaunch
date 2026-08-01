-----------------------------------
-- Trust: Matsui-P
-- Spell ID: 1021  |  Pool ID: 6021
-- Scales with master level like a max-investment Fellow. At master level 99
-- he breaks the 99,999 trust damage ceiling and caps at 149,999.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local FELLOW_MAX_CAP = 99999
local MATSUI_MAX_CAP = 149999

local function matsuiDamageCap(master)
    local masterLvl = math.max(1, math.min(99, master:getMainLvl() or 1))
    local progress = (masterLvl - 1) / 98

    if masterLvl >= 99 then
        return MATSUI_MAX_CAP
    end

    return math.max(1, math.floor(FELLOW_MAX_CAP * progress * progress))
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    mob:setModelId(3121)
    mob:renameEntity('Matsui-P', true)

    local master = mob:getMaster()
    local lvl = mob:getMainLvl()
    local upgraded = math.max(1, master:getCharVar('TrustUpgraded') or 1)
    local power = lvl * upgraded

    mob:setLocalVar('EncounterOutgoingDamageCap', matsuiDamageCap(master))

    mob:addMod(xi.mod.HP, power * 2)
    mob:addMod(xi.mod.STR, power * 2)
    mob:addMod(xi.mod.DEX, power * 2)
    mob:addMod(xi.mod.INT, power * 2)
    mob:addMod(xi.mod.ATT, power * 3)
    mob:addMod(xi.mod.ACC, power * 3)
    mob:addMod(xi.mod.MATT, power * 3)
    mob:addMod(xi.mod.MACC, power * 3)
    mob:addMod(xi.mod.HASTE_MAGIC, 1500)
    mob:addMod(xi.mod.FASTCAST, 80)
    mob:addMod(xi.mod.CRITHITRATE, 20 + math.floor(power / 10))
    mob:addMod(xi.mod.STORETP, math.floor(power / 4))
    mob:addMod(xi.mod.WSD, 100 + math.floor(power / 5))
    mob:addMod(xi.mod.MAGIC_DAMAGE, power * 2)

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
