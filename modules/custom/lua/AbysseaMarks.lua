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

local MARKS_CV         = 'HL_Points'
local INFAMY_CV        = 'Infamy'
local INFAMY_LIFE_CV   = 'Infamy_Lifetime'
local MARKS_INFAMY_LV  = '[MarksPopInfamy]'
local MARKS_GIL_LV     = '[MarksPopGil]'
local MARKS_CRUOR_LV   = '[MarksPopCruor]'

-- Per zone tier: mark cost, rewards, spawn level, HP, and flat stat mods applied
-- at spawn time.  atkDef is added to ATT, DEF, MATT.  accEva is added to ACC,
-- EVA, MACC, MEVA.  Level drives the formula-based stat floor on top of these.
local zoneConfig =
{
    -- Visions of Abyssea
    [xi.zone.ABYSSEA_KONSCHTAT]        = { cost = 200, infamy = 25, gil =   250000, cruor = 1000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    [xi.zone.ABYSSEA_TAHRONGI]         = { cost = 200, infamy = 25, gil =   250000, cruor = 1000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    [xi.zone.ABYSSEA_LA_THEINE]        = { cost = 200, infamy = 25, gil =   250000, cruor = 1000, level = 135, maxHP =  4000000, atkDef =  3333, accEva = 2000 },
    -- Scars of Abyssea
    [xi.zone.ABYSSEA_ATTOHWA]          = { cost = 350, infamy = 40, gil =   500000, cruor = 1500, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    [xi.zone.ABYSSEA_MISAREAUX]        = { cost = 350, infamy = 40, gil =   500000, cruor = 1500, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    [xi.zone.ABYSSEA_VUNKERL]          = { cost = 350, infamy = 40, gil =   500000, cruor = 1500, level = 145, maxHP =  7000000, atkDef =  6000, accEva = 3333 },
    -- Heroes of Abyssea
    [xi.zone.ABYSSEA_ALTEPA]           = { cost = 500, infamy = 60, gil =   750000, cruor = 2000, level = 155, maxHP = 10000000, atkDef =  8666, accEva = 5000 },
    [xi.zone.ABYSSEA_GRAUBERG]         = { cost = 500, infamy = 60, gil =   750000, cruor = 2000, level = 155, maxHP = 10000000, atkDef =  8666, accEva = 5000 },
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
    -- Spawn 3 units behind the player so the mob lands in open ground
    -- rather than clipping into terrain features (trees, hills) at the ???.
    -- Formula mirrors nearPosition() in utils.cpp (radian=π → behind).
    local rot = p:getRotPos()
    local rad = (rot / 256.0) * 2 * math.pi + math.pi
    local dist = 3.0
    local dx = p:getXPos() + math.cos(2 * math.pi - rad) * dist
    local dy = p:getYPos()
    local dz = p:getZPos() + math.sin(2 * math.pi - rad) * dist
    mob:setSpawn(dx, dy, dz)
    local spawned = SpawnMob(mobId)
    spawned:updateClaim(p)
    spawned:updateEnmity(p)  -- immediately engage spawner; no delay before attacking
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
    spawned:setLocalVar(MARKS_INFAMY_LV,  cfg.infamy)
    spawned:setLocalVar(MARKS_GIL_LV,    cfg.gil)
    spawned:setLocalVar(MARKS_CRUOR_LV,  cfg.cruor)
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
        for i = 0, (player:getPartySize() or 1) - 1 do
            local mem = player:getPartyMember(i, 0)
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
    if not cfg then
        return super(player, npc, mobId, kis, tradeReqs)
    end

    -- Safety fallback: mobId == 0 means no mob to spawn.
    if mobId == 0 then
        player:release()
        return false
    end

    local mob = GetMobByID(mobId)
    if not mob then
        player:release()
        return false
    end

    -- Mob already up: nothing for marks system to do.
    if mob:isSpawned() then
        return super(player, npc, mobId, kis, tradeReqs)
    end

    -- Mob is NOT spawned.  Offer marks pop when:
    --   (a) #kis == 0: trade-pop NM or Misareaux/Vunkerl stub (no KI method exists)
    --   (b) player is missing at least one required KI
    local hasAllKis = type(kis) == 'table' and #kis > 0
    if hasAllKis then
        for _, ki in ipairs(kis) do
            if ki ~= 0 and not player:hasKeyItem(ki) then
                hasAllKis = false
                break
            end
        end
    end

    if not hasAllKis then
        local ok = pcall(offerMarksPop, player, mobId, cfg)
        if ok then
            player:release()
            return false
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
    local cruorBase  = mob:getLocalVar(MARKS_CRUOR_LV)
    if (not infamyBase or infamyBase == 0) and (not gilBase or gilBase == 0) and (not cruorBase or cruorBase == 0) then return end

    pcall(function()
        local partyMult, trustMult = calcMultipliers(player)
        local totalMult = partyMult * trustMult

        local infamyEarned = math.floor(infamyBase * totalMult)
        local gilEarned    = math.floor(gilBase    * totalMult)
        local cruorEarned  = math.floor(cruorBase  * totalMult)

        -- Build reward message once; same for every member.
        local parts = {}
        if infamyEarned > 0 then table.insert(parts, string.format('+%d Infamy', infamyEarned)) end
        if gilEarned    > 0 then table.insert(parts, string.format('+%dg', gilEarned))           end
        if cruorEarned  > 0 then table.insert(parts, string.format('+%d Cruor', cruorEarned))    end

        local bonusParts = {}
        if partyMult > 1.0 then table.insert(bonusParts, 'party')     end
        if trustMult > 1.0 then table.insert(bonusParts, 'no trusts') end

        local msg = string.format('[Abyssea] %s', table.concat(parts, ', '))
        if #bonusParts > 0 then
            msg = msg .. string.format('  (x%.1f: %s)', totalMult, table.concat(bonusParts, ' + '))
        end

        -- Distribute to every online PC in the party.
        -- getPartyMember(0) always returns self; 1..N-1 returns other members.
        for i = 0, (player:getPartySize() or 1) - 1 do
            local mem = player:getPartyMember(i, 0)
            if mem and mem:getObjType() == xi.objType.PC then
                if infamyEarned > 0 then
                    mem:setCharVar(INFAMY_CV,      (mem:getCharVar(INFAMY_CV)      or 0) + infamyEarned)
                    mem:setCharVar(INFAMY_LIFE_CV, (mem:getCharVar(INFAMY_LIFE_CV) or 0) + infamyEarned)
                end
                if gilEarned   > 0 then mem:addGil(gilEarned)                       end
                if cruorEarned > 0 then mem:addCurrency('cruor', cruorEarned)        end
                mem:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
            end
        end
    end)
end)

return m
