-----------------------------------
-- smn_avatar_equalize.lua
--
-- Scales player-avatar Blood Pacts from their completed stock damage. Physical
-- and magical pact formulas therefore retain WSC, hit count, BP Damage, pet
-- MAB/MACC, summoning skill, master augments, magic bursts and resists.
--
-- The two avatar-BP damage choke-points are xi.summon.avatarFinalAdjustments
-- for PHYSICAL pacts (camisado, eclipse_bite, rush, hysteric_assault, ...) and
-- xi.mobskills.processDamage for MAGICAL pacts (inferno, diamond_dust, ...); see each
-- override below.
--
-- Only real damage is scaled. The original's miss / Perfect Dodge / Third Eye /
-- shield / invincible returns (0), full shadow-absorb (a small shadowsUsed count),
-- and drains (negative) all pass through untouched, and the mob's own damage cap is
-- re-applied (target:checkDamageCap) so NM damage-cap mechanics still hold.
--
-- Pure-Lua override module -> needs ONE map restart to load (no rebuild). Pairs with
-- smn_avatar_boost.lua, whose pet stats feed the stock calculation.
--
-- TUNING: the shared pet curve and master-weapon companion caps are in
-- standard_ws_tuning_catalog.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/summon')

local m = Module:new('smn_avatar_equalize')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')
local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')

local MIN_REAL_DAMAGE = 10
xi.summon.avatarProgression = xi.summon.avatarProgression or {}
local avatarProgression = xi.summon.avatarProgression
avatarProgression.physicalScalingBypass =
    avatarProgression.physicalScalingBypass or setmetatable({}, { __mode = 'k' })
local physicalScalingBypass = avatarProgression.physicalScalingBypass
avatarProgression.magicalScalingBypass =
    avatarProgression.magicalScalingBypass or setmetatable({}, { __mode = 'k' })
local magicalScalingBypass = avatarProgression.magicalScalingBypass
avatarProgression.physicalFinalizationInProgress =
    avatarProgression.physicalFinalizationInProgress or
    setmetatable({}, { __mode = 'k' })
local physicalFinalizationInProgress =
    avatarProgression.physicalFinalizationInProgress

local function isSmnAvatar(mob)
    if not mob or not mob:isAvatar() then
        return false
    end

    local master = mob:getMaster()

    return master ~= nil and master:isPC() and master:getMainJob() == xi.job.SMN
end

local function getDamageProfile(mob, target, skill)
    local master = mob:getMaster()
    local multiplier = progression.getPetDamageMultiplier(master, target)
    local cap = progression.setPetDamageCap(mob, master)
    if skill:isAoE() or skill:isConal() then
        multiplier = 1 + (multiplier - 1) * 0.50
        cap = math.floor(cap * 0.50)
    end

    -- Match BST/DRG/PUP companion leveling: sub-99 pets cannot chunk more
    -- than 33% of the target's max HP in one hit (Legendary leveling clamp).
    if master and master:getMainLvl() < progression.ENDGAME_PLAYER_LEVEL then
        cap = math.min(cap, math.floor(target:getMaxHP() * levelingHpCap.FRACTION))
    end

    return multiplier, cap
end

-- Reusable guarded entry point for exceptional BP scripts which cannot use one
-- of the standard physical/magical choke points. Non-damage, non-SMN and
-- absorbed values are deliberately returned unchanged.
avatarProgression.scaleDamage = function(mob, target, skill, damage)
    if
        type(damage) ~= 'number' or
        damage <= MIN_REAL_DAMAGE or
        not isSmnAvatar(mob)
    then
        return damage
    end

    local multiplier, cap = getDamageProfile(mob, target, skill)
    return target:checkDamageCap(
        progression.applyMultiplier(damage, multiplier, cap))
end

-- Hybrid BPs must finish native physical processing (BP_DAMAGE, shadows,
-- immunities and mitigation) before building their magical rider, but must not
-- consume the normal physical progression pass at that point.
avatarProgression.finalizePhysicalWithoutProgression = function(info, mob, skill, target, skilltype, damagetype, shadowbehav)
    physicalScalingBypass[mob] = true
    local ok, damage = pcall(
        xi.summon.avatarFinalAdjustments,
        info, mob, skill, target, skilltype, damagetype, shadowbehav)
    physicalScalingBypass[mob] = nil

    if not ok then
        error(damage)
    end

    return damage
end

-- Exceptional magical pacts can apply progression and their own stricter
-- ceiling before native processDamage handles mitigation, enmity and reporting.
avatarProgression.processDamageWithoutProgression = function(actor, target, skill, action, info)
    magicalScalingBypass[actor] = true
    local ok, applied = pcall(
        xi.mobskills.processDamage, actor, target, skill, action, info)
    magicalScalingBypass[actor] = nil

    if not ok then
        error(applied)
    end

    return applied
end

-- Scale a hybrid's positive physical and magical lanes as one BP so the
-- weapon-tier ceiling is shared, then restore the lane split for native damage
-- typing. Negative elemental absorption is never progression-scaled.
avatarProgression.scaleHybridDamage = function(mob, target, skill, physicalDamage, magicalDamage)
    if
        not isSmnAvatar(mob) or
        type(physicalDamage) ~= 'number' or
        type(magicalDamage) ~= 'number'
    then
        return physicalDamage, magicalDamage
    end

    local positivePhysical = math.max(physicalDamage, 0)
    local positiveMagical = math.max(magicalDamage, 0)
    local positiveTotal = positivePhysical + positiveMagical
    if positiveTotal <= MIN_REAL_DAMAGE then
        return physicalDamage, magicalDamage
    end

    local scaledTotal = avatarProgression.scaleDamage(mob, target, skill, positiveTotal)
    local scaledPhysical = math.floor(scaledTotal * positivePhysical / positiveTotal)
    local scaledMagical = scaledTotal - scaledPhysical

    if physicalDamage < 0 then
        scaledPhysical = physicalDamage
    end

    if magicalDamage < 0 then
        scaledMagical = magicalDamage
    end

    return scaledPhysical, scaledMagical
end

-- Scale every avatar's physical Blood Pact after its native formula.
m:addOverride('xi.summon.avatarFinalAdjustments', function(info, mob, skill, target, skilltype, damagetype, shadowbehav)
    physicalFinalizationInProgress[mob] = true
    local ok, natural = pcall(
        super, info, mob, skill, target, skilltype, damagetype, shadowbehav)
    physicalFinalizationInProgress[mob] = nil

    if not ok then
        error(natural)
    end

    if physicalScalingBypass[mob] then
        return natural
    end

    -- Scale only a real damage hit; let misses (0), full shadow-absorb (a small
    -- shadowsUsed count) and drains (negative) fall through exactly as before.
    local scaled = avatarProgression.scaleDamage(mob, target, skill, natural)
    xi.summon.reportPetOverCap(mob, scaled)

    return scaled
end)

-- Scale every avatar's magical Blood Pact (Inferno, Diamond Dust,
-- Judgment Bolt, Grand Fall, Aerial Blast, ...). Magical pacts finalize through
-- mobMagicalMove (resists + magic burst already baked in) and apply via
-- processDamage -> takeDamage. We set the damage here BEFORE super(), so enmity and the
-- over-cap check both see the normalized value, and a magic burst can't overshoot the
-- cap. processDamage is shared by every mob skill, so the isSmnAvatar gate makes all
-- non-avatar callers a pass-through.
m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    if not magicalScalingBypass[actor] then
        info.damage = avatarProgression.scaleDamage(actor, target, skill, info.damage)
    end

    return super(actor, target, skill, action, info)
end)

-- Physical BPs report after progression above; hybrid scripts report their
-- combined physical + magical result. Suppress the native pre-scale report.
m:addOverride('xi.summon.reportPetOverCap', function(mob, dmg)
    if physicalFinalizationInProgress[mob] then
        return
    end

    return super(mob, dmg)
end)

m.scaleDamage = avatarProgression.scaleDamage
m.scaleHybridDamage = avatarProgression.scaleHybridDamage
m.finalizePhysicalWithoutProgression =
    avatarProgression.finalizePhysicalWithoutProgression
m.processDamageWithoutProgression =
    avatarProgression.processDamageWithoutProgression

return m
