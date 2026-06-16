-----------------------------------
-- AbysseaMarks
-- Lets players spend Hunt Marks to pop Abyssea ??? NMs
-- when they lack the normal pop key items.
-- The NM's killer earns Gil + Infamy with multipliers for
-- partying with real players and fighting without trusts.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/abyssea')

local m = Module:new('AbysseaMarks')

local MARKS_CV        = 'HL_Points'
local INFAMY_CV       = 'Infamy'
local INFAMY_LIFE_CV  = 'Infamy_Lifetime'
local MARKS_INFAMY_LV = '[MarksPopInfamy]'
local MARKS_GIL_LV    = '[MarksPopGil]'

-- Per zone tier: mark cost, rewards, spawn level, HP, and flat stat mods applied
-- at spawn time.  atkDef is added to ATT, DEF, MATT.  accEva is added to ACC,
-- EVA, MACC, MEVA.  Level drives the formula-based stat floor on top of these.
local zoneConfig =
{
    -- Visions of Abyssea
    [xi.zone.ABYSSEA_KONSCHTAT]        = { cost = 200, infamy = 25, gil =   250000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    [xi.zone.ABYSSEA_TAHRONGI]         = { cost = 200, infamy = 25, gil =   250000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    [xi.zone.ABYSSEA_LA_THEINE]        = { cost = 200, infamy = 25, gil =   250000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    -- Scars of Abyssea
    [xi.zone.ABYSSEA_ATTOHWA]          = { cost = 350, infamy = 40, gil =   500000, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    [xi.zone.ABYSSEA_MISAREAUX]        = { cost = 350, infamy = 40, gil =   500000, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    [xi.zone.ABYSSEA_VUNKERL]          = { cost = 350, infamy = 40, gil =   500000, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    -- Heroes of Abyssea
    [xi.zone.ABYSSEA_ALTEPA]           = { cost = 500, infamy = 60, gil =   750000, level = 155, maxHP = 10000000, atkDef =  8666, accEva = 5000 },
    [xi.zone.ABYSSEA_ULEGUERAND]       = { cost = 500, infamy = 60, gil =   750000, level = 155, maxHP = 10000000, atkDef =  8666, accEva = 5000 },
    [xi.zone.ABYSSEA_GRAUBERG]         = { cost = 500, infamy = 60, gil =   750000, level = 155, maxHP = 10000000, atkDef =  8666, accEva = 5000 },
}

local function spawnViaMark(p, mobId, cost, nmName, cfg)
    local cur = p:getCharVar(MARKS_CV) or 0
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
    local spawned = SpawnMob(mobId)
    spawned:updateClaim(p)
    spawned:setLevel(cfg.level)
    spawned:setMaxHP(cfg.maxHP)
    spawned:setHP(cfg.maxHP)
    spawned:addMod(xi.mod.ATT,  cfg.atkDef)
    spawned:addMod(xi.mod.DEF,  cfg.atkDef)
    spawned:addMod(xi.mod.MATT, cfg.atkDef)
    spawned:addMod(xi.mod.ACC,  cfg.accEva)
    spawned:addMod(xi.mod.EVA,  cfg.accEva)
    spawned:addMod(xi.mod.MACC, cfg.accEva)
    spawned:addMod(xi.mod.MEVA, cfg.accEva)
    spawned:setLocalVar('[ClaimedBy]', p:getID())
    spawned:setLocalVar(MARKS_INFAMY_LV, cfg.infamy)
    spawned:setLocalVar(MARKS_GIL_LV,    cfg.gil)
    p:printToPlayer(
        string.format('[Abyssea] %d Hunt Marks spent. %s appears!', cost, nmName),
        xi.msg.channel.SYSTEM_3)
end

local function offerMarksPop(player, mobId, cfg)
    local mob = GetMobByID(mobId)
    if not mob then return end
    local nmName = mob:getName():gsub('_', ' ')
    local pts    = player:getCharVar(MARKS_CV) or 0
    local cost   = cfg.cost

    local label, callback
    if pts >= cost then
        label    = string.format('Pop: %d marks', cost)
        callback = function(pl)
            spawnViaMark(pl, mobId, cost, nmName, cfg)
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

-- Returns (partyMult, trustMult).
-- partyMult = 2.0 when 2+ real PCs are in party, else 1.0.
-- trustMult = 1.5 when NO non-PC members (trusts) are in party, else 1.0.
-- Wrapped in pcall so a missing API never breaks the reward path.
local function calcMultipliers(player)
    local partyMult = 1.0
    local trustMult = 1.0

    local ok = pcall(function()
        local pcCount    = 0
        local trustCount = 0
        for i = 0, 5 do
            local mem = player:getPartyMember(i)
            if mem then
                if mem:getObjType() == xi.objType.PC then
                    pcCount    = pcCount    + 1
                else
                    trustCount = trustCount + 1
                end
            end
        end
        if pcCount >= 2    then partyMult = 2.0 end
        if trustCount == 0 then trustMult = 1.5 end
    end)

    -- If the API call failed, default to no bonus (safe fallback).
    if not ok then
        partyMult = 1.0
        trustMult = 1.0
    end

    return partyMult, trustMult
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

    -- Trade-to-pop ??? (mobId == 0): required items don't exist on this server.
    -- Silently release the player instead of firing the "trade X item" cutscene.
    if cfg and mobId == 0 then
        player:release()
        return false
    end

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
                local ok, err = pcall(offerMarksPop, player, mobId, cfg)
                if ok then
                    player:release()  -- free client from ??? interaction lock before menu opens
                    return false
                end
                -- fall through to super so the player sees SOMETHING
            end
        end
    end

    return super(player, npc, mobId, kis, tradeReqs)
end)

-- ============================================================
-- Reward on kill
-- Awards Gil + Infamy to every PC in the party on a marks-popped NM
-- kill, with multipliers for:
--   x2.0  — 2+ real players in party
--   x1.5  — no trusts in party
-- Multipliers stack (solo no-trust = x1.5, party no-trust = x3).
-- ============================================================
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if not isKiller or player == nil then return end
    if player:getObjType() ~= xi.objType.PC then return end

    local infamyBase = mob:getLocalVar(MARKS_INFAMY_LV)
    local gilBase    = mob:getLocalVar(MARKS_GIL_LV)
    if (not infamyBase or infamyBase == 0) and (not gilBase or gilBase == 0) then return end

    pcall(function()
        local partyMult, trustMult = calcMultipliers(player)
        local totalMult = partyMult * trustMult

        local infamyEarned = math.floor(infamyBase * totalMult)
        local gilEarned    = math.floor(gilBase    * totalMult)

        -- Build reward message once; same for every member.
        local parts = {}
        if infamyEarned > 0 then table.insert(parts, string.format('+%d Infamy', infamyEarned)) end
        if gilEarned    > 0 then table.insert(parts, string.format('+%dg', gilEarned))           end

        local bonusParts = {}
        if partyMult > 1.0 then table.insert(bonusParts, 'party')     end
        if trustMult > 1.0 then table.insert(bonusParts, 'no trusts') end

        local msg = string.format('[Abyssea] %s', table.concat(parts, ', '))
        if #bonusParts > 0 then
            msg = msg .. string.format('  (x%.1f: %s)', totalMult, table.concat(bonusParts, ' + '))
        end

        -- Distribute to every online PC in the party.
        for i = 0, 5 do
            local mem = player:getPartyMember(i)
            if mem and mem:getObjType() == xi.objType.PC then
                if infamyEarned > 0 then
                    mem:setCharVar(INFAMY_CV,      (mem:getCharVar(INFAMY_CV)      or 0) + infamyEarned)
                    mem:setCharVar(INFAMY_LIFE_CV, (mem:getCharVar(INFAMY_LIFE_CV) or 0) + infamyEarned)
                end
                if gilEarned > 0 then mem:addGil(gilEarned) end
                mem:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
            end
        end
    end)
end)

return m
