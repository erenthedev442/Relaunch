-----------------------------------
-- Trust: Brygid
-- GEO/BRD incorporeal aura. Permanent Indi-CHR visual + CHR (stacks with
-- player Indi-CHR via CHR_BOOST), Indi-Barrier DEF%, Indi-Fend MDEF.
-- Untargetable / unkillable / no AA / no WS. B-tier aura — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Indi visual: LIGHT allies (Indi-CHR).
local INDI_CHR_VISUAL = 6

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

    local lvl = mob:getMainLvl()
    -- Retail @99: +5 CHR, ~9.7% DEF, +5 MDEF.
    local chrPower  = scaleStat(lvl, 5)
    local defPower  = scaleStat(lvl, 10) -- DEFP % (~9.7 at 99)
    local mdefPower = scaleStat(lvl, 5)

    -- Visible Indi-CHR colure. CHR applied as CHR_BOOST so it stacks with
    -- player Indi-CHR (GEO_CHR_BOOST) instead of overwriting it.
    mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
        power = INDI_CHR_VISUAL,
        tick = 3,
        origin = mob,
        subType = xi.effect.CHR_BOOST,
        subPower = chrPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    -- Indi-Barrier / Indi-Fend (no separate icons on retail Brygid).
    mob:addStatusEffect(xi.effect.GEO_DEFENSE_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_DEFENSE_BOOST,
        subPower = defPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })
    mob:addStatusEffect(xi.effect.GEO_MAGIC_DEF_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_MAGIC_DEF_BOOST,
        subPower = mdefPower,
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
