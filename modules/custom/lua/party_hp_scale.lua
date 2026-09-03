-----------------------------------
-- Party-size HP scale for custom content only.
--
-- Solo + trusts stays 1.0x (trusts are not PCs). A 6-box is 5.0x.
-- Open-world trash / EXP / CP farms are not marked and are never touched.
-- Solo-lock fights (Gauntlet, Maat, Job Mastery) are not wired in.
--
-- Grow-only: inviting more PCs after the pop/entry raises HP to the new
-- step and keeps current HPP. Leaving or dying never shrinks the bar.
--
-- Call afterCustomHp(mob, playerOrInstance) AFTER the content script has
-- finished setMaxHP. prepare() + ENGAGE/COMBAT_TICK catch late invites.
--
-- Wired: dungeons, Omen, Dynamis (classic + Divergence), HTBF, Hunting
-- League, Geas Fete, Voidwatch, Voidspire, world/raid bosses, affinity
-- NMs, Apex, Unity Wanted, Invasion / Domain Invasion, Prestige, Endless
-- Tower, Colosseum, Reforge, Abyssea Marks, Tournament, Game Master.
-- Not wired: open-world trash / EXP / CP, Gauntlet, Maat, Job Mastery.
-----------------------------------
local KEY = 'modules/custom/lua/party_hp_scale'
local scale = package.loaded[KEY]
if type(scale) ~= 'table' then
    scale = {}
end
package.loaded[KEY] = scale
xi.party_hp_scale = scale

scale.CURVE =
{
    [1] = 1.0,
    [2] = 1.7,
    [3] = 2.4,
    [4] = 3.2,
    [5] = 4.1,
    [6] = 5.0,
}

local LV_MARK    = 'PartyHpScale'
local LV_BASE    = 'PartyHpScaleBase'
local LV_PCS     = 'PartyHpScalePCs'
local LV_LISTEN  = 'PartyHpScaleListen'
local LV_SEEN    = 'PartyHpScaleSeen'

local function isPC(entity)
    return entity ~= nil and entity.getObjType ~= nil and entity:getObjType() == xi.objType.PC
end

local function resolvePC(entity)
    if isPC(entity) then
        return entity
    end

    if entity and entity.getMaster then
        local master = entity:getMaster()
        if isPC(master) then
            return master
        end
    end

    return nil
end

-- setMaxHP writes health.maxhp, then UpdateHealth multiplies by species
-- HPP (Manticores / Trolls are +50%). Callers that pass a catalog pool
-- therefore show 1.5x max and spawn at 67% unless the displayed bar is
-- solved back to the authored value.
function scale.setDisplayedMaxHP(mob, desired)
    local target = math.max(1, math.floor(tonumber(desired) or 0))
    if target < 1 or not mob or not mob.setMaxHP then
        return
    end

    local guess = target
    for _ = 1, 4 do
        mob:setMaxHP(guess)
        local shown = mob:getMaxHP()
        if shown <= 0 or math.abs(shown - target) <= 1 then
            return
        end

        guess = math.max(1, math.floor(guess * target / shown + 0.5))
    end
end

function scale.setCatalogHp(mob, hp)
    scale.setDisplayedMaxHP(mob, hp)
    if mob and mob.setHP and mob.getMaxHP then
        local max = mob:getMaxHP()
        if max > 0 then
            mob:setHP(max)
        end
    end
end

function scale.multiplier(pcCount)
    local n = math.floor(tonumber(pcCount) or 1)
    if n < 1 then
        n = 1
    elseif n > 6 then
        n = 6
    end

    return scale.CURVE[n]
end

function scale.isScalableMob(mob)
    if mob == nil or (mob.isAlive and not mob:isAlive()) then
        return false
    end

    if mob.isMob and not mob:isMob() then
        return false
    end

    if mob.isPet and mob:isPet() then
        return false
    end

    if mob.getMaster then
        local master = mob:getMaster()
        if isPC(master) then
            return false
        end
    end

    return true
end

function scale.countFromPlayer(player)
    player = resolvePC(player)
    if not player then
        return 1
    end

    local zoneId = player.getZoneID and player:getZoneID() or nil
    local n = 0
    local group = (player.getAlliance and player:getAlliance()) or { player }
    for _, member in ipairs(group) do
        if
            isPC(member) and
            (zoneId == nil or not member.getZoneID or member:getZoneID() == zoneId)
        then
            n = n + 1
        end
    end

    if n < 1 then
        n = 1
    elseif n > 6 then
        n = 6
    end

    return n
end

function scale.countInstancePCs(instance)
    if not instance or not instance.getChars then
        return 0
    end

    local n = 0
    for _, member in pairs(instance:getChars()) do
        if isPC(member) then
            n = n + 1
        end
    end

    if n > 6 then
        n = 6
    end

    return n
end

function scale.apply(mob, pcCount)
    if not scale.isScalableMob(mob) then
        return false
    end

    if mob.getLocalVar and mob:getLocalVar(LV_MARK) ~= 1 then
        return false
    end

    local n = math.floor(tonumber(pcCount) or 0)
    if n < 1 then
        return false
    elseif n > 6 then
        n = 6
    end

    local prev = mob:getLocalVar(LV_PCS)
    if n <= prev then
        return false
    end

    local base = mob:getLocalVar(LV_BASE)
    if base <= 0 then
        base = mob:getMaxHP()
        if base <= 0 then
            return false
        end

        mob:setLocalVar(LV_BASE, base)
    end

    local newMax = math.max(1, math.floor(base * scale.CURVE[n] + 0.5))
    local oldMax = mob:getMaxHP()
    local oldHp  = mob:getHP()
    if newMax ~= oldMax and oldMax > 0 then
        local hpp = oldHp / oldMax
        scale.setDisplayedMaxHP(mob, newMax)
        mob:setHP(math.max(1, math.floor(mob:getMaxHP() * hpp + 0.5)))
    end

    mob:setLocalVar(LV_PCS, n)
    return true
end

function scale.syncFromCombat(mob, target)
    if not scale.isScalableMob(mob) then
        return
    end

    local instance = mob.getInstance and mob:getInstance() or nil
    if instance and instance.getChars then
        scale.apply(mob, scale.countInstancePCs(instance))
        return
    end

    local player = resolvePC(target)
    if player then
        scale.apply(mob, scale.countFromPlayer(player))
    end
end

function scale.prepare(mob)
    if not scale.isScalableMob(mob) then
        return
    end

    mob:setLocalVar(LV_MARK, 1)
    if not mob.addListener or mob:getLocalVar(LV_LISTEN) == 1 then
        return
    end

    mob:setLocalVar(LV_LISTEN, 1)
    mob:addListener('ENGAGE', 'PARTY_HP_SCALE', function(engaged, target)
        scale.syncFromCombat(engaged, target)
    end)
    mob:addListener('COMBAT_TICK', 'PARTY_HP_SCALE', function(ticking)
        local target = ticking.getTarget and ticking:getTarget() or nil
        scale.syncFromCombat(ticking, target)
    end)
end

-- Map a live (possibly scaled) bar back to catalog HP so persist/resume
-- paths never store a party-inflated current value.
function scale.catalogCurrentHp(mob)
    if not mob or not mob.getHP then
        return 0
    end

    local hp = mob:getHP()
    if hp <= 0 then
        return 0
    end

    local max  = mob.getMaxHP and mob:getMaxHP() or 0
    local base = mob.getLocalVar and mob:getLocalVar(LV_BASE) or 0
    if base > 0 and max > 0 then
        return math.max(1, math.floor(hp / max * base + 0.5))
    end

    return hp
end

function scale.afterCustomHp(mob, source)
    if not scale.isScalableMob(mob) then
        return
    end

    scale.prepare(mob)
    -- Content just finished setMaxHP. Treat the current bar as the new 1.0x
    -- catalog snapshot so later authored HP (adds, phase bars) is scaled
    -- once, then grow to the party that is present now.
    if mob.setLocalVar then
        mob:setLocalVar(LV_BASE, 0)
        mob:setLocalVar(LV_PCS, 0)
    end

    if source and source.getChars then
        local n = scale.countInstancePCs(source)
        if n > 0 then
            scale.apply(mob, n)
        end

        return
    end

    local instance = mob.getInstance and mob:getInstance() or nil
    if instance and instance.getChars then
        local n = scale.countInstancePCs(instance)
        if n > 0 then
            scale.apply(mob, n)
        end

        return
    end

    if source then
        scale.apply(mob, scale.countFromPlayer(source))
    end
end

function scale.syncInstance(instance)
    if not instance or not instance.getMobs then
        return
    end

    local n = scale.countInstancePCs(instance)
    local seen = instance.getLocalVar and instance:getLocalVar(LV_SEEN) or 0
    if n < seen then
        n = seen
    end

    if instance.setLocalVar then
        instance:setLocalVar(LV_SEEN, n)
    end

    if n < 1 then
        return
    end

    for _, mob in pairs(instance:getMobs()) do
        if scale.isScalableMob(mob) then
            scale.prepare(mob)
            scale.apply(mob, n)
        end
    end
end

function scale.maybeResyncInstance(instance)
    if not instance or not instance.getChars then
        return
    end

    local n = scale.countInstancePCs(instance)
    local seen = instance.getLocalVar and instance:getLocalVar(LV_SEEN) or 0
    if n > seen then
        scale.syncInstance(instance)
    end
end

return scale
