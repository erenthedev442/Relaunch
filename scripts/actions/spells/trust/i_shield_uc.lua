-----------------------------------
-- Trust: Invincible Shield UC
-- Retail: WAR/COR provoke tank-DD. No native Cure/Flash list.
-- Soturi's Fury is not implemented yet — uses Raging Rush / Steel Cyclone /
-- Shield Break / Armor Break until that skill ships.
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
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)
    mob:setMobMod(xi.mobMod.CAN_PARRY, 3)

    local lvl = mob:getMainLvl()

    -- Survive without MP-gated cures (kit Flash/Cure was mismatched for WAR).
    mob:addMod(xi.mod.HPP, 25)
    mob:addMod(xi.mod.DMG, -2000) -- Damage Taken -20% (retail UC note)
    mob:addMod(xi.mod.ENMITY, 80)
    mob:addMod(xi.mod.ATT, 50)
    mob:addMod(xi.mod.ACC, 60)
    mob:addMod(xi.mod.DOUBLE_ATTACK, 15)
    xi.trust.enableTankEnmity(mob, { profile = 'strong', listenerName = 'I_SHIELD_UC_TANK_ENMITY' })

    if lvl >= 5 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    if lvl >= 15 then
        mob:addGambit(ai.t.TARGET, { ai.l.OR(
            { ai.c.READYING_WS, 0 },
            { ai.c.READYING_MS, 0 },
            { ai.c.CASTING_MA, 0 }) }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
    end

    if lvl >= 35 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.WARCRY }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.WARCRY })
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BLOOD_RAGE }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BLOOD_RAGE })
    end

    if lvl >= 45 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.AGGRESSOR }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.AGGRESSOR })
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.RESTRAINT }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RESTRAINT })
    end

    if lvl >= 60 then
        mob:addGambit(ai.t.SELF, { { ai.c.HAS_TOP_ENMITY, 0 }, { ai.c.NOT_STATUS, xi.effect.RETALIATION } }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.RETALIATION })
    end

    if lvl >= 75 then
        mob:addGambit(ai.t.TARGET, { ai.l.OR(
            { ai.c.IS_ECOSYSTEM, xi.ecosystem.UNDEAD },
            { ai.c.IS_ECOSYSTEM, xi.ecosystem.AMORPH },
            { ai.c.IS_ECOSYSTEM, xi.ecosystem.ELEMENTAL }) }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.TOMAHAWK })
    end

    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 1500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
