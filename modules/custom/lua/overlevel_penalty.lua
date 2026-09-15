-----------------------------------
-- Applies overlevel_combat while a player below 99 is fighting a much
-- higher mob. UDMG mods cover the first hits (int16 caps around 4x);
-- a once-per-second pulse finishes the "one shot" at 30+ levels.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local combat = require('modules/custom/lua/overlevel_combat')

local m = Module:new('overlevel_penalty')

local UDMG_VAR   = 'OverlevelUDMG'
local TICK_VAR   = 'OverlevelSec'
local WARN_VAR   = 'OverlevelWarn'
local LISTENER   = 'OVERLEVEL_PENALTY_TICK'

local TAKEN_MODS =
{
    xi.mod.UDMGPHYS,
    xi.mod.UDMGMAGIC,
    xi.mod.UDMGRANGE,
    xi.mod.UDMGBREATH,
}

local function setTaken(player, udmg)
    local prev = player:getLocalVar(UDMG_VAR) or 0
    local delta = udmg - prev
    if delta == 0 then
        return
    end

    for i = 1, #TAKEN_MODS do
        player:addMod(TAKEN_MODS[i], delta)
    end

    player:setLocalVar(UDMG_VAR, udmg)
end

local function clearTaken(player)
    setTaken(player, 0)
end

local function mobLevel(ent)
    if ent and ent.isMob and ent:isMob() and ent.getMainLvl then
        return ent:getMainLvl()
    end

    return 0
end

local function mobLevelFromTarget(player)
    -- Battle target only exists while engaged. Spell spam without drawing
    -- a weapon still generates hate — use cursor + notoriety as well.
    local best = mobLevel(player.getTarget and player:getTarget())
    best = math.max(best, mobLevel(player.getCursorTarget and player:getCursorTarget()))

    local list = player.getNotorietyList and player:getNotorietyList()
    if type(list) == 'table' then
        for _, mob in pairs(list) do
            best = math.max(best, mobLevel(mob))
        end
    end

    local pet = player.getPet and player:getPet()
    if pet and pet.getTarget then
        best = math.max(best, mobLevel(pet:getTarget()))
    end

    return best
end

local function applyPenalty(player)
    if not player or not player.isAlive or not player:isAlive() then
        return
    end

    -- GetMLevel: Level Sync and restriction already write the displayed
    -- combat level, so a 99 synced to 65 is treated as 65.
    local playerLevel = combat.combatLevel(player)
    if playerLevel >= combat.ENDGAME_LEVEL then
        clearTaken(player)
        return
    end

    local mobLevel = mobLevelFromTarget(player)
    if mobLevel <= 0 then
        clearTaken(player)
        return
    end

    local gap     = combat.gap(playerLevel, mobLevel)
    local allowed = combat.allowedGap(player)
    if gap <= allowed then
        clearTaken(player)
        return
    end

    setTaken(player, combat.udmgFromMult(combat.incomingMult(gap, allowed)))

    local now = os.time()
    if now == (player:getLocalVar(TICK_VAR) or 0) then
        return
    end

    player:setLocalVar(TICK_VAR, now)

    local pulse = combat.pulseFraction(gap, allowed)
    if pulse > 0 then
        local hit = math.max(1, math.floor(player:getMaxHP() * pulse))
        player:takeDamage(hit)
    end

    if now >= (player:getLocalVar(WARN_VAR) or 0) then
        player:setLocalVar(WARN_VAR, now + 15)
        player:printToPlayer('This foe is far above your level. The gap will crush you.', xi.msg.channel.SYSTEM_3)
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    player:addListener('TICK', LISTENER, applyPenalty)
end)

m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    clearTaken(player)
    super(player, ...)
end)

return m
