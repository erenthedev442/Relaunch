-----------------------------------
-- Applies overlevel_combat while a player below 99 has enmity on a much
-- higher mob. UDMG mods cover the 16–29 gap (int16 caps around 4x).
-- At 30+ the pulse is gone: a real auto / spell / TP move from that foe
-- is made lethal (Lua TP numbers here; C++ ApplyOverlevelIncomingPierce
-- covers autos, spells, and takeDamage).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local combat = require('modules/custom/lua/overlevel_combat')

local m = Module:new('overlevel_penalty')

local UDMG_VAR = 'OverlevelUDMG'
local WARN_VAR = 'OverlevelWarn'
local LISTENER = 'OVERLEVEL_PENALTY_TICK'

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

local function mobLevelFromEnmity(player)
    -- Only hate / engagement. Cursor-targeting a 105 in a mixed zone must
    -- not apply the gap — that was the layout problem with the old pulse.
    local best = mobLevel(player.getTarget and player:getTarget())

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

    local foeLevel = mobLevelFromEnmity(player)
    if foeLevel <= 0 then
        clearTaken(player)
        return
    end

    local gap     = combat.gap(playerLevel, foeLevel)
    local allowed = combat.allowedGap(player)
    if gap <= allowed then
        clearTaken(player)
        return
    end

    -- 30+: attacker-specific pierce on the actual hit. Do not stamp global
    -- UDMG or a nearby on-level mob also hits 4x while the 105 is on hate.
    if combat.shouldPierceIncoming(gap) then
        clearTaken(player)
    else
        setTaken(player, combat.udmgFromMult(combat.incomingMult(gap, allowed)))
    end

    local now = os.time()
    if now >= (player:getLocalVar(WARN_VAR) or 0) then
        player:setLocalVar(WARN_VAR, now + 15)
        player:printToPlayer('This foe is far above your level. Its blows will ignore your defenses.', xi.msg.channel.SYSTEM_3)
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

-- TP move combat-log number matches the lethal HP debit from takeDamage.
m:addOverride('xi.mobskills.processDamage', function(actor, target, skill, action, info)
    local ok = super(actor, target, skill, action, info)
    if ok and info and type(info.damage) == 'number' then
        info.damage = combat.applyIncomingPierce(actor, target, info.damage)
    end

    return ok
end)

return m
