-----------------------------------
-- Overlevel combat (leveling only).
-- A padded level-1 cannot farm 105s. Players below 99 may stretch 15–20
-- levels above them if they are deep into Ascension / Rebirth / Paragon.
-- Past 20 the incoming multiplier is severe. At 30+ they die.
-- Combat level is GetMLevel (Level Sync / restriction), never real job
-- level, so a maxed rebirth 99 synced to 65 is treated as a 65.
-----------------------------------
local rebirthCatalog = require('modules/custom/lua/job_rebirth_catalog')

local combat = {}

combat.ENDGAME_LEVEL         = 99
combat.BASE_GAP              = 15
combat.MAX_BONUS_GAP         = 5
combat.HARD_GAP              = 30
combat.OUTGOING_SCRATCH_GAP  = 40
combat.OUTGOING_SCRATCH_MIN  = 10
combat.OUTGOING_SCRATCH_MAX  = 100
combat.UDMG_CAP              = 32767

-- Retail effect IDs (scripts/enum/effect.lua) so this file stays loadable
-- from the standalone test runner without requiring xi.effect.
local EFFECT_LEVEL_RESTRICTION = 143
local EFFECT_LEVEL_SYNC        = 269

function combat.combatLevel(player)
    if player and player.getMainLvl then
        return player:getMainLvl() or 0
    end

    return 0
end

function combat.isLevelLocked(player)
    if not player or not player.hasStatusEffect then
        return false
    end

    return player:hasStatusEffect(EFFECT_LEVEL_SYNC) or player:hasStatusEffect(EFFECT_LEVEL_RESTRICTION)
end

function combat.progressionBonus(player)
    if not player or not player.getCharVar then
        return 0
    end

    -- Synced / restricted players use the same free band as anyone else at
    -- that combat level. Prestige and rebirth do not stretch the gap.
    if combat.isLevelLocked(player) then
        return 0
    end

    local job        = player.getMainJob and player:getMainJob() or 0
    local ascensions = player:getCharVar('Prestige_Ascensions_Total') or 0
    local prestige   = job > 0 and (player:getCharVar(string.format('Prestige_Level_%d', job)) or 0) or 0
    local rebirths   = rebirthCatalog.rebirthCount(player, job)
    local paragon    = player:getCharVar('Paragon_Level') or 0
    local bonus      = math.floor(ascensions / 4) + math.floor(prestige / 8) + math.floor(rebirths / 10) + math.floor(paragon / 10)
    if bonus > combat.MAX_BONUS_GAP then
        return combat.MAX_BONUS_GAP
    end

    if bonus < 0 then
        return 0
    end

    return bonus
end

function combat.allowedGap(player)
    return combat.BASE_GAP + combat.progressionBonus(player)
end

function combat.gap(playerLevel, mobLevel)
    return (mobLevel or 0) - (playerLevel or 0)
end

-- Incoming: 1.0 inside the allowed band, then ramps. Always lethal at 30+.
function combat.incomingMult(gap, allowed)
    allowed = allowed or combat.BASE_GAP
    if (gap or 0) <= 0 then
        return 1
    end

    if gap >= combat.HARD_GAP then
        return 100
    end

    if gap <= allowed then
        return 1
    end

    if gap <= 20 then
        return 1 + 0.4 * (gap - allowed)
    end

    return 4 + 6 * (gap - 20)
end

-- Outgoing: full damage through +20, then crushed. Almost nothing at 30+.
function combat.outgoingMult(gap)
    if (gap or 0) <= 20 then
        return 1
    end

    if gap >= combat.HARD_GAP then
        return 0.01
    end

    return math.max(0.05, 1 - 0.1 * (gap - 20))
end

function combat.udmgFromMult(mult)
    local extra = math.floor(((mult or 1) - 1) * 10000)
    if extra < 0 then
        return 0
    end

    if extra > combat.UDMG_CAP then
        return combat.UDMG_CAP
    end

    return extra
end

function combat.clampOutgoing(gap, damage)
    if type(damage) ~= 'number' or damage <= 0 then
        return damage
    end

    local scaled = math.max(0, math.floor(damage * combat.outgoingMult(gap)))
    if (gap or 0) < combat.OUTGOING_SCRATCH_GAP then
        return scaled
    end

    -- 40+ levels above the attacker: 10-100, never a fraction of a nuke.
    if scaled < combat.OUTGOING_SCRATCH_MIN then
        return combat.OUTGOING_SCRATCH_MIN
    end

    if scaled > combat.OUTGOING_SCRATCH_MAX then
        return combat.OUTGOING_SCRATCH_MAX
    end

    return scaled
end

function combat.scaleOutgoing(sourceLevel, target, damage)
    if type(damage) ~= 'number' or damage <= 0 then
        return damage
    end

    if (sourceLevel or 0) >= combat.ENDGAME_LEVEL then
        return damage
    end

    if not target or not target.getMainLvl then
        return damage
    end

    if target.isMob and not target:isMob() then
        return damage
    end

    return combat.clampOutgoing(combat.gap(sourceLevel, target:getMainLvl()), damage)
end

function combat.pulseFraction(gap, allowed)
    if (gap or 0) >= combat.HARD_GAP then
        return 1
    end

    if gap > 20 then
        return 0.10 + 0.04 * (gap - 20)
    end

    if gap > (allowed or combat.BASE_GAP) then
        return 0.04 * (gap - allowed)
    end

    return 0
end

return combat
