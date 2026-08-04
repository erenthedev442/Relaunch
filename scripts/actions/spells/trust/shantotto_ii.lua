-----------------------------------
-- Trust: Shantotto II
-- BLM/WHM. Capstone magic burst nuker (custom T2–V spell list kept).
-- Magical AA (lowest-resist element). Unique WS kit. Hold 2500 TP to close.
-- HP-10%, MBB+30, ilvl MATT+25. S-tier nuker (apex); soft 36–40k;
-- MB hard cap 79,999 via trust_power_scaling. Do not strip FC / custom spells.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_FINAL_EXAM = 3740
local AA_SKILL_LIST = 1163

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.SHANTOTTO)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    -- Retail fragility + burst traits (on top of S apex scaler — do not replace it).
    mob:addMod(xi.mod.HPP, -10)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 30)
    mob:addMod(xi.mod.MATT, 25)

    -- Custom cadence (keep — user power path).
    mob:addMod(xi.mod.FASTCAST, 50)
    mob:addMod(xi.mod.UFASTCAST, 10)
    mob:addMod(xi.mod.HASTE_MAGIC, 1000)

    -- Feed magical AA / unique WS base (nuker package has no setDamage).
    local lvl = mob:getMainLvl()
    local p   = (math.max(1, math.min(99, lvl)) / 99) ^ 1.35
    local t   = 1.18 -- S-tier
    pcall(function()
        mob:setDamage(math.floor((12 + 210 * p) * t * 0.90))
    end)

    -- MB-first (often double-bursts via FC); free nukes avoid sure resists.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE }, 2)
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 20)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 40)

    -- Magical AA (skill list 1163 → auto_attack_shantotto_ii).
    mob:setMobSkillAttack(AA_SKILL_LIST)
    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Hold to 2500 TP to close skillchains.
    mob:setTrustTPSkillSettings(ai.tp.CLOSER_UNTIL_TP, ai.s.HIGHEST, 2500)

    mob:addListener('WEAPONSKILL_USE', 'SHANTOTTO_II_WEAPONSKILL_USE', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_FINAL_EXAM then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
        end
    end)

    mob:addListener('MAGIC_USE', 'SHANTOTTO_II_MAGIC', function(mobArg, target, spell, action)
        if math.random(1, 100) <= 33 then
            xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_2)
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
