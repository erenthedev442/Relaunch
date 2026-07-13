-----------------------------------
-- smn_avatar_equalize.lua
--
-- "Everyone similar to Siren." Normalizes every player avatar's Blood Pact -- physical
-- AND magical -- to one skill-scaled target, so all avatars do ~the same damage per
-- pact regardless of hit count (1 vs Shiva's Rush = 5), per-pact base, or element.
--
-- WHY: smn_avatar_boost.lua makes avatars DD via a FLAT BP_DAMAGE (45x) + huge ATT.
-- The ATT maxes physical pDif vs ANY NM, but a flat multiplier just AMPLIFIES the
-- natural per-pact variance: 3-hit physical pacts (Siren's Hysteric Assault, Garuda's
-- Predator Claws, ...) land in the 131k "sweet spot", 1-hit pacts do ~1/3 of that,
-- and Shiva's 5-hit Rush overshoots the cap and WRAPS to a tiny on-screen number. So
-- only a few avatars feel good -- the "only Siren works" report.
--
-- THE FIX: override the two avatar-BP damage choke-points and REPLACE the final damage
-- with a flat target in the CONFIG.base..ceiling band -- xi.summon.avatarFinalAdjustments
-- for PHYSICAL pacts (camisado, eclipse_bite, rush, hysteric_assault, ...) and
-- xi.mobskills.processDamage for MAGICAL pacts (inferno, diamond_dust, ...); see each
-- override below. Original tuning sat right under the 131k display-wrap cap; the
-- 2026-07-13 80% cut brings it well below that (see CONFIG comment). We also no-op the
-- pet over-cap whisper for SMN avatars since normalized damage stays under the cap.
--
-- Only REAL damage is replaced. The original's miss / Perfect Dodge / Third Eye /
-- shield / invincible returns (0), full shadow-absorb (a small shadowsUsed count),
-- and drains (negative) all pass through untouched, and the mob's own damage cap is
-- re-applied (target:checkDamageCap) so NM damage-cap mechanics still hold.
--
-- SCOPE: every damaging Blood Pact -- any avatar, physical or magical. Magic bursts are
-- flattened to the same target too, so a skillchain nuke can't overshoot the cap or
-- out-damage a physical pact; "everyone equal" stays literal. (Non-damage pacts -- buffs,
-- heals, sleeps, drains -- are untouched: they never exceed CONFIG.threshold.)
--
-- Pure-Lua override module -> needs ONE map restart to load (no rebuild). Pairs with
-- smn_avatar_boost.lua (which still drives auto-attacks + survivability + the big
-- pre-normalization damage that keeps real hits above CONFIG.threshold).
--
-- TUNING: edit CONFIG. base/ceiling set the damage band; perSkill keeps gear
-- progression. Keep ceiling < 131071 so the on-screen number never wraps.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/summon')

local m = Module:new('smn_avatar_equalize')

-- 2026-07-13 owner call: cut normalized damage target by 80% (SMN avatars were OP
-- against everything outside the endgame NMs this was originally dimensioned for).
-- The 131,071 client display-wrap cap is no longer the shape constraint at these
-- numbers; ceiling stays well under it.
local CONFIG =
{
    base      = 20000, -- target Blood Pact damage with summoning skill exactly at cap (was 100000)
    perSkill  =   300, -- + per point of summoning skill OVER cap (was 1500)
    ceiling   = 25600, -- hard ceiling on the normalized damage (was 128000)
    threshold =  5000, -- only normalize REAL damage; at/below this it's shadows/anticipate/miss/0
}

local function isSmnAvatar(mob)
    if not mob or not mob:isAvatar() then
        return false
    end

    local master = mob:getMaster()

    return master ~= nil and master:isPC() and master:getMainJob() == xi.job.SMN
end

local function targetDamage(mob)
    local over = math.max(xi.summon.getSummoningSkillOverCap(mob), 0)

    return math.min(CONFIG.base + over * CONFIG.perSkill, CONFIG.ceiling)
end

-- Flatten every avatar's PHYSICAL Blood Pact to the same band.
m:addOverride('xi.summon.avatarFinalAdjustments', function(info, mob, skill, target, skilltype, damagetype, shadowbehav)
    local natural = super(info, mob, skill, target, skilltype, damagetype, shadowbehav)

    -- Replace ONLY a real damage hit; let misses (0), full shadow-absorb (a small
    -- shadowsUsed count) and drains (negative) fall through exactly as before.
    if type(natural) == 'number' and natural > CONFIG.threshold and isSmnAvatar(mob) then
        return target:checkDamageCap(targetDamage(mob))
    end

    return natural
end)

-- Flatten every avatar's MAGICAL Blood Pact to the same band (Inferno, Diamond Dust,
-- Judgment Bolt, Grand Fall, Aerial Blast, ...). Magical pacts finalize through
-- mobMagicalMove (resists + magic burst already baked in) and apply via
-- processDamage -> takeDamage. We set the damage here BEFORE super(), so enmity and the
-- over-cap check both see the normalized value, and a magic burst can't overshoot the
-- cap. processDamage is shared by every mob skill, so the isSmnAvatar gate makes all
-- non-avatar callers a pass-through.
m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    if isSmnAvatar(actor) and type(info.damage) == 'number' and info.damage > CONFIG.threshold then
        info.damage = target:checkDamageCap(targetDamage(actor))
    end

    return super(actor, target, skill, action, info)
end)

-- Normalized damage is under the cap, so the "true (over-cap) damage" whisper would
-- just report the discarded pre-normalization number. Silence it for SMN avatars only
-- (automaton / BST / other pets keep theirs).
m:addOverride('xi.summon.reportPetOverCap', function(mob, dmg)
    if isSmnAvatar(mob) then
        return
    end

    return super(mob, dmg)
end)

return m
