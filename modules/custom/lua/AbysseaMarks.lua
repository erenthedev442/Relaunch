-----------------------------------
-- AbysseaMarks
-- Lets players spend Hunt Marks to pop Abyssea ??? NMs
-- when they lack the normal pop key items.
-- The NM's killer earns a small Infamy reward.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')

local m = Module:new('AbysseaMarks')

local MARKS_CV        = 'HL_Points'
local INFAMY_CV       = 'Infamy'
local INFAMY_LIFE_CV  = 'Infamy_Lifetime'
local MARKS_INFAMY_LV = '[MarksPopInfamy]'

-- Mark cost and Infamy reward per zone tier.
local zoneConfig =
{
    -- Visions of Abyssea (entry)
    [xi.zone.ABYSSEA_KONSCHTAT]        = { cost = 200, infamy = 1 },
    [xi.zone.ABYSSEA_TAHRONGI]         = { cost = 200, infamy = 1 },
    [xi.zone.ABYSSEA_LA_THEINE]        = { cost = 200, infamy = 1 },
    -- Scars of Abyssea
    [xi.zone.ABYSSEA_ATTOHWA]          = { cost = 350, infamy = 2 },
    [xi.zone.ABYSSEA_MISAREAUX]        = { cost = 350, infamy = 2 },
    [xi.zone.ABYSSEA_VUNKERL]          = { cost = 350, infamy = 2 },
    -- Heroes of Abyssea
    [xi.zone.ABYSSEA_ALTEPA]           = { cost = 500, infamy = 3 },
    [xi.zone.ABYSSEA_ULEGUERAND]       = { cost = 500, infamy = 3 },
    [xi.zone.ABYSSEA_GRAUBERG]         = { cost = 500, infamy = 3 },
    -- Empyreal Paradox
    [xi.zone.ABYSSEA_EMPYREAL_PARADOX] = { cost = 750, infamy = 5 },
}

local function spawnViaMark(p, mobId, cost, nmName, infamy)
    local cur = p:getCharVar(MARKS_CV)
    if cur < cost then
        p:printToPlayer('[Abyssea] Not enough Hunt Marks.', xi.msg.channel.SYSTEM_3)
        return
    end
    local mob = GetMobByID(mobId)
    if not mob or mob:isSpawned() then
        p:printToPlayer('[Abyssea] This NM is already present.', xi.msg.channel.SYSTEM_3)
        return
    end
    p:setCharVar(MARKS_CV, cur - cost)
    local dx = p:getXPos() + math.random(-1, 1)
    local dy = p:getYPos()
    local dz = p:getZPos() + math.random(-1, 1)
    mob:setSpawn(dx, dy, dz)
    SpawnMob(mobId):updateClaim(p)
    GetMobByID(mobId):setLocalVar('[ClaimedBy]', p:getID())
    GetMobByID(mobId):setLocalVar(MARKS_INFAMY_LV, infamy)
    p:printToPlayer(
        string.format('[Abyssea] %d Hunt Marks spent. %s appears!', cost, nmName),
        xi.msg.channel.SYSTEM_3)
end

local function offerMarksPop(player, mobId, cfg)
    local mob = GetMobByID(mobId)
    if not mob then return end
    local nmName = mob:getName():gsub('_', ' ')
    local pts    = player:getCharVar(MARKS_CV)
    local cost   = cfg.cost

    local label, callback
    if pts >= cost then
        label    = string.format('Pop: %d marks', cost)
        callback = function(pl)
            spawnViaMark(pl, mobId, cost, nmName, cfg.infamy)
        end
    else
        label    = string.format('Pop: %d marks (need %d more)', cost, cost - pts)
        callback = nil
    end

    player:timer(30, function(p)
        p:customMenu({
            title   = nmName,
            options = {
                { label, callback },
                { 'Close', nil },
            },
        })
    end)
end

-- ============================================================
-- Override qmOnTrigger
-- When a player taps ??? and is missing pop KIs, skip the
-- "missing key items" cutscene and offer a marks-based pop
-- via customMenu instead.  Normal KI pops fall through to
-- super unchanged.
-- ============================================================
m:addOverride('xi.abyssea.qmOnTrigger', function(player, npc, mobId, kis, tradeReqs)
    local cfg = zoneConfig[player:getZoneID()]

    if cfg and mobId ~= 0 and kis and #kis > 0 then
        local mob = GetMobByID(mobId)
        if mob and not mob:isSpawned() then
            local validKis = true
            for _, ki in ipairs(kis) do
                if ki ~= 0 and not player:hasKeyItem(ki) then
                    validKis = false
                    break
                end
            end

            if not validKis then
                offerMarksPop(player, mobId, cfg)
                return false
            end
        end
    end

    return super(player, npc, mobId, kis, tradeReqs)
end)

-- ============================================================
-- Infamy on kill
-- Awards Infamy to whoever delivers the killing blow on a
-- marks-popped NM.  The Infamy amount is stored on the mob
-- at spawn time.
-- ============================================================
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if not isKiller or player == nil then return end
    if player:getObjType() ~= xi.objType.PC then return end

    local infamy = mob:getLocalVar(MARKS_INFAMY_LV)
    if not infamy or infamy == 0 then return end

    pcall(function()
        player:setCharVar(INFAMY_CV,      (player:getCharVar(INFAMY_CV)      or 0) + infamy)
        player:setCharVar(INFAMY_LIFE_CV, (player:getCharVar(INFAMY_LIFE_CV) or 0) + infamy)
        player:printToPlayer(
            string.format('[Abyssea] +%d Infamy earned.', infamy),
            xi.msg.channel.SYSTEM_3)
    end)
end)

return m
