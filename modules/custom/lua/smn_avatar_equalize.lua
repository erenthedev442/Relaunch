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
-- TUNING: the shared pet curve is in standard_ws_tuning_catalog.lua.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/summon')

local m = Module:new('smn_avatar_equalize')
local progression = require('modules/custom/lua/standard_ws_tuning_catalog')

local MIN_REAL_DAMAGE = 10

local function isSmnAvatar(mob)
    if not mob or not mob:isAvatar() then
        return false
    end

    local master = mob:getMaster()

    return master ~= nil and master:isPC() and master:getMainJob() == xi.job.SMN
end

local function scaleDamage(mob, target, skill, damage)
    local master = mob:getMaster()
    local multiplier = progression.getPetDamageMultiplier(master, target)
    local cap = progression.DAMAGE_CAP
    if skill:isAoE() then
        multiplier = 1 + (multiplier - 1) * 0.50
        cap = math.floor(cap * 0.50)
    end

    -- Match BST/DRG/PUP companion leveling: sub-99 pets cannot chunk more
    -- than 40% of the target's max HP in one hit (stops leveling blitzes).
    if master and master:getMainLvl() < progression.ENDGAME_PLAYER_LEVEL then
        cap = math.min(cap, math.floor(target:getMaxHP() * 0.40))
    end

    return progression.applyMultiplier(damage, multiplier, cap)
end

-- Scale every avatar's physical Blood Pact after its native formula.
m:addOverride('xi.summon.avatarFinalAdjustments', function(info, mob, skill, target, skilltype, damagetype, shadowbehav)
    local natural = super(info, mob, skill, target, skilltype, damagetype, shadowbehav)

    -- Scale only a real damage hit; let misses (0), full shadow-absorb (a small
    -- shadowsUsed count) and drains (negative) fall through exactly as before.
    if type(natural) == 'number' and natural > MIN_REAL_DAMAGE and isSmnAvatar(mob) then
        return target:checkDamageCap(scaleDamage(mob, target, skill, natural))
    end

    return natural
end)

-- Scale every avatar's magical Blood Pact (Inferno, Diamond Dust,
-- Judgment Bolt, Grand Fall, Aerial Blast, ...). Magical pacts finalize through
-- mobMagicalMove (resists + magic burst already baked in) and apply via
-- processDamage -> takeDamage. We set the damage here BEFORE super(), so enmity and the
-- over-cap check both see the normalized value, and a magic burst can't overshoot the
-- cap. processDamage is shared by every mob skill, so the isSmnAvatar gate makes all
-- non-avatar callers a pass-through.
m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    if isSmnAvatar(actor) and type(info.damage) == 'number' and info.damage > MIN_REAL_DAMAGE then
        info.damage = target:checkDamageCap(
            scaleDamage(actor, target, skill, info.damage))
    end

    return super(actor, target, skill, action, info)
end)

-- Scaled damage is explicitly capped, so the over-cap whisper is redundant.
-- Silence it for SMN avatars only
-- (automaton / BST / other pets keep theirs).
m:addOverride('xi.summon.reportPetOverCap', function(mob, dmg)
    if isSmnAvatar(mob) then
        return
    end

    return super(mob, dmg)
end)

return m
