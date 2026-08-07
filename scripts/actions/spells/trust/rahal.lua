-----------------------------------
-- Trust: Rahal
-- PLD/WAR. Spells: Cure I-IV, Flash, Phalanx, Enlight.
-- Abilities: Sentinel, Berserk, Provoke, Shield Bash.
-- WS: Fast Blade, Seraph Blade, Swift Blade, Savage Blade.
-- Possesses Dragon Killer (mob_pool_mods).
-- Aggressive tank who uses Berserk. Prioritizes Flash over Provoke.
-- Cures party only below 33% HP (highest tier). Sentinel below 33% HP.
-- Interrupts TP moves / casting with Shield Bash.
-- Holds up to 2500 TP to close skillchains.
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
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.TRION] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.CURILLA] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.EXCENMILLE] = xi.trust.messageOffset.TEAMWORK_3,
        -- Exc_S slot is Matsui-P; keep Exc teamwork line on base Exc only.
    })

    mob:setMobMod(xi.mobMod.CAN_SHIELD_BLOCK, 1)

    -- Dragon Killer handled in mob_pool_mods
    mob:addMod(xi.mod.ENMITY, 40)
    mob:addMod(xi.mod.ATT, 35)
    mob:addMod(xi.mod.ACC, 50)
    mob:addMod(xi.mod.DEF, 180)  -- B tank: less paper than before vs Valaineral/August
    mob:addMod(xi.mod.DMG, -1200) -- Damage Taken -12%
    mob:addMod(xi.mod.VIT, 40)
    mob:addMod(xi.mod.HPP, 15)
    mob:setMod(xi.mod.SHIELDBLOCKRATE, 30)
    xi.trust.enableTankEnmity(mob, { tickCE = 4500, tickVE = 9000, actionCE = 2200, actionVE = 4500, tickSeconds = 2, drainMaster = 8, includeParty = true, listenerName = 'RAHAL_TANK_ENMITY' })

    local lvl = mob:getMainLvl()

    -- Flash before Provoke (priority).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.FLASH }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.FLASH })

    if lvl >= 10 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_HAS_TOP_ENMITY, 0 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.PROVOKE })
    end

    if lvl >= 15 then
        -- Interrupt TP abilities and casting (high-tier spells included via CASTING_MA).
        mob:addGambit(ai.t.TARGET, { ai.l.OR(
            { ai.c.CASTING_MA, 0 },
            { ai.c.READYING_JA, 0 },
            { ai.c.READYING_MS, 0 },
            { ai.c.READYING_WS, 0 }) }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SHIELD_BASH })
    end

    if lvl >= 30 then
        mob:addGambit(ai.t.SELF, { ai.c.NOT_STATUS, xi.effect.BERSERK }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.BERSERK })
        mob:addGambit(ai.t.SELF, { ai.c.HPP_LT, 33 }, { ai.r.JA, ai.s.SPECIFIC, xi.ja.SENTINEL })
    end

    -- Cure only for party below 33% (highest available); wake sleep with Cure.
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 33 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.SELF,  { ai.c.NOT_STATUS, xi.effect.ENLIGHT }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ENLIGHT })
    mob:addGambit(ai.t.SELF,  { ai.c.NOT_STATUS, xi.effect.PHALANX }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.PHALANX })

    -- Hold TP to close skillchains.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
