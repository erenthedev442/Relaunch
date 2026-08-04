-----------------------------------
-- Trust: Robel-Akbel
-- BLM/SMN Staff. ST nukes I–V, -aja, Stun.
-- WS: Spirit Taker / Quietus Sphere (AoE Dark) / Null Blast (MP = dmg, MEVA down).
-- MB -aja (double-burst attempt). Avoids sure resists. Stun interrupts.
-- Null Blast when MP low. Occult Acumen. NO_MOVE; staff AA if nearby.
-- WS @2000 no SC hold. Kayeel: +FC. Karaha @1000 TP: opens SC.
-- B-tier nuker (burst) — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local MS_NULL = 3538

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function partyHasKayeel(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == xi.magic.spell.KAYEEL_PAYEEL
        then
            return true
        end
    end

    return false
end

local function karahaReady(mob)
    local master = mob:getMaster()
    if not master then
        return false
    end

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if
            member:getObjType() == xi.objType.TRUST and
            member:getTrustID() == xi.magic.spell.KARAHA_BARUHA and
            member:getTP() >= 1000
        then
            return true
        end
    end

    return false
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.KAYEEL_PAYEEL] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.KARAHA_BARUHA] = xi.trust.messageOffset.TEAMWORK_2,
    })

    -- High FC for MB windows; Kayeel synergy stacks more.
    mob:addMod(xi.mod.FASTCAST, 45)
    mob:addMod(xi.mod.UFASTCAST, 15)
    mob:addMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED, 40)
    mob:addMod(xi.mod.MACC, 55)
    mob:addMod(xi.mod.OCCULT_ACUMEN, 60)
    -- Staff AA when the target is in range.
    mob:addMod(xi.mod.ACC, 40)
    mob:addMod(xi.mod.ATT, 35)

    if partyHasKayeel(mob) then
        mob:addMod(xi.mod.FASTCAST, 25)
        mob:addMod(xi.mod.UFASTCAST, 10)
    end

    -- Stun interrupts.
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_WS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_MS, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })
    mob:addGambit(ai.t.TARGET, { ai.c.READYING_JA, 0 }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STUN })

    -- Magic burst with -aja (highest IDs on trimmed list); try to double-burst.
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE }, 2)

    -- Free nukes: avoid sure resists (not a perfect weakness pick).
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 25)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 50)

    mob:addListener('WEAPONSKILL_USE', 'ROBEL_NULL_BLAST', function(mobArg, target, skill, tp, action, damage)
        if skill:getID() == MS_NULL then
            if math.random(1, 100) <= 40 then
                xi.trust.message(mobArg, xi.trust.messageOffset.SPECIAL_MOVE_1)
            end
        end
    end)

    mob:setAutoAttackEnabled(true)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
    -- Default: dump @2000, no SC hold.
    mob:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 2000)
    mob:setLocalVar('robelHateMute', 0)
    mob:setLocalVar('robelTpMode', 0)

    mob:addListener('COMBAT_TICK', 'ROBEL_AI', function(mobArg)
        -- Top enmity: stop casting (staff AA only).
        local hate = hasTopEnmity(mobArg)
        local muted = mobArg:getLocalVar('robelHateMute') == 1
        if hate and not muted then
            mobArg:setMagicCastingEnabled(false)
            mobArg:setLocalVar('robelHateMute', 1)
        elseif not hate and muted then
            mobArg:setMagicCastingEnabled(true)
            mobArg:setLocalVar('robelHateMute', 0)
        end

        -- Prefer Null Blast when MP is low (last on skill list / HIGHEST).
        local wantMode
        if mobArg:getMPP() < 35 then
            wantMode = 1 -- Null Blast
        elseif karahaReady(mobArg) then
            wantMode = 2 -- Open for Karaha
        else
            wantMode = 0 -- Normal dump @2000
        end

        if mobArg:getLocalVar('robelTpMode') == wantMode then
            return
        end

        mobArg:setLocalVar('robelTpMode', wantMode)
        if wantMode == 1 then
            mobArg:setTrustTPSkillSettings(ai.tp.ASAP, ai.s.HIGHEST, 1000)
        elseif wantMode == 2 then
            mobArg:setTrustTPSkillSettings(ai.tp.OPENER, ai.s.HIGHEST, 1000)
        else
            mobArg:setTrustTPSkillSettings(ai.tp.RANDOM, ai.s.RANDOM, 2000)
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
