-----------------------------------
-- Trust: Kuyin Hathdenna
-- Spell ID: 950 | Pool ID: 5950
-- GEO/BRD incorporeal aura. Permanent Indi-Precision colure (thunder) +
-- Acc/RAcc (ACCURACY_BOOST so it stacks with player Indi-Precision) + DEX.
-- Untargetable / unkillable / no AA / no WS. A-tier aura — no kit inject.
--
-- @99: Acc+24, RAcc+24, DEX+5. Mog Garden DEX +0–2 is not tracked here
-- (garden contract ranks are not modeled), so base DEX+5 only.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Indi visual: THUNDER allies (Indi-Precision).
local INDI_PRECISION_VISUAL = 4

local function scaleStat(lvl, at99)
    return math.max(1, math.floor(at99 * lvl / 99 + 0.5))
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    local master = mob:getMaster()
    local lvl = (master and master:getMainLvl()) or mob:getMainLvl() or 1
    local accPower = scaleStat(lvl, 24)
    local dexPower = scaleStat(lvl, 5)

    -- Visible Indi-Precision colure. Acc/RAcc via ACCURACY_BOOST so they
    -- stack with player Indi-Precision (GEO_ACCURACY_BOOST) instead of
    -- overwriting it. Aura applicator sets child power from subPower;
    -- accuracy_boost treats ALWAYS_EXPIRING as Acc=RAcc=power.
    mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
        power = INDI_PRECISION_VISUAL,
        tick = 3,
        origin = mob,
        subType = xi.effect.ACCURACY_BOOST,
        subPower = accPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    -- DEX from retail Indi-Precision package (GEO path; no player conflict).
    mob:addStatusEffect(xi.effect.GEO_DEX_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_DEX_BOOST,
        subPower = dexPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    -- Incorporeal: cannot die, ignore all damage types.
    mob:setUnkillable(true)
    mob:setMod(xi.mod.UDMGPHYS, -10000)
    mob:setMod(xi.mod.UDMGRANGE, -10000)
    mob:setMod(xi.mod.UDMGMAGIC, -10000)
    mob:setMod(xi.mod.UDMGBREATH, -10000)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    -- Incorporeal — should not fire; keep message hook for safety.
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
