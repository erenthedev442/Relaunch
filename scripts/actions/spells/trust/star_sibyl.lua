-----------------------------------
-- Trust: Star Sibyl
-- Spell ID: 935 | Pool ID: 5935
-- GEO/BRD incorporeal aura. Permanent Indi-Acumen colure (ice) + MATT
-- (MAGIC_ATK_BOOST so it stacks with player Indi-Acumen) + MACC.
-- Untargetable / unkillable / no AA / no WS. B-tier aura — no kit inject.
--
-- @99: Magic Attack+19, Magic Accuracy+19.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

-- Indi visual: ICE allies (Indi-Acumen).
local INDI_ACUMEN_VISUAL = 1

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
    local mattPower = scaleStat(lvl, 19)
    local maccPower = scaleStat(lvl, 19)

    -- Visible Indi-Acumen colure. MATT via MAGIC_ATK_BOOST so it stacks with
    -- player Indi-Acumen (GEO_MAGIC_ATK_BOOST) instead of overwriting it.
    mob:addStatusEffect(xi.effect.COLURE_ACTIVE, {
        power = INDI_ACUMEN_VISUAL,
        tick = 3,
        origin = mob,
        subType = xi.effect.MAGIC_ATK_BOOST,
        subPower = mattPower,
        tier = xi.auraTarget.ALLIES,
        flag = xi.effectFlag.AURA,
    })

    -- Bundled MACC (retail sphere; helps trust Dispel breakpoints).
    mob:addStatusEffect(xi.effect.GEO_MAGIC_ACC_BOOST, {
        power = 6,
        tick = 3,
        origin = mob,
        subType = xi.effect.GEO_MAGIC_ACC_BOOST,
        subPower = maccPower,
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
