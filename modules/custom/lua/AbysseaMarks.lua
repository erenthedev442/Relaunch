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

-- Per zone tier: mark cost + rewards, then the spawn stat block applied at pop.
--   level   drives the formula-based base-stat floor for that level
--   maxHP   flat HP override (setMaxHP)
--   att / def / matt           melee attack / defense / magic attack added
--   acc / eva / macc / meva     accuracy / evasion / magic acc / magic eva added
--   da      Double Attack % (extra swings)
--   haste   HASTE_GEAR (100 = 1% faster attack round)
--   eleRes  added to ALL 8 elemental magic-evasion mods (Fire..Dark) -- an
--           elemental-nuke resistance layered on top of meva
-- RELAUNCH Phase 2 retune (2026-06-24): cut to the relaunch power curve
-- (original design "Mob Retune Targets", Abyssea rows). att/def/maxHP land in
-- the design's per-tier ranges -- Visions(T1) def 900-1100 / att 4-5.5k / HP
-- 375-565k, Scars(T2) def 1.2-1.5k / att 5.5-7.5k / HP 780k-1.2M, Heroes(T3)
-- def 1.8-2.2k / att 7-9k / HP 1.55-2.3M -- and the secondary stats (matt/acc/
-- eva/macc/meva/da/haste/eleRes) are scaled to match so the mob stays coherent
-- (and hittable) at relaunch player power. Was the old Legendary band (att
-- 10-18k, HP 4-10M), which one-shot and out-tanked a relaunch party.
local zoneConfig =
{
    -- Visions of Abyssea  (Lv135 -- softest marks NMs)
    [xi.zone.ABYSSEA_KONSCHTAT] = { cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 135, maxHP =  500000, att =  5000, def = 1000, matt = 1667, acc = 1300, eva = 1000, macc = 1000, meva = 1000, da =  5, haste =  50, eleRes =  75 },
    [xi.zone.ABYSSEA_TAHRONGI]  = { cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 135, maxHP =  500000, att =  5000, def = 1000, matt = 1667, acc = 1300, eva = 1000, macc = 1000, meva = 1000, da =  5, haste =  50, eleRes =  75 },
    [xi.zone.ABYSSEA_LA_THEINE] = { cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 135, maxHP =  500000, att =  5000, def = 1000, matt = 1667, acc = 1300, eva = 1000, macc = 1000, meva = 1000, da =  5, haste =  50, eleRes =  75 },
    -- Scars of Abyssea  (Lv145)
    [xi.zone.ABYSSEA_ATTOHWA]   = { cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 145, maxHP = 1000000, att =  6500, def = 1350, matt = 3000, acc = 1750, eva = 1667, macc = 1667, meva = 1667, da =  8, haste =  75, eleRes = 125 },
    [xi.zone.ABYSSEA_MISAREAUX] = { cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 145, maxHP = 1000000, att =  6500, def = 1350, matt = 3000, acc = 1750, eva = 1667, macc = 1667, meva = 1667, da =  8, haste =  75, eleRes = 125 },
    [xi.zone.ABYSSEA_VUNKERL]   = { cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 145, maxHP = 1000000, att =  6500, def = 1350, matt = 3000, acc = 1750, eva = 1667, macc = 1667, meva = 1667, da =  8, haste =  75, eleRes = 125 },
    -- Heroes of Abyssea  (Lv155 -- top marks NMs; still below the Ascension gate)
    [xi.zone.ABYSSEA_ALTEPA]    = { cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 155, maxHP = 1900000, att =  8000, def = 2000, matt = 4000, acc = 2500, eva = 2500, macc = 2500, meva = 2500, da = 10, haste = 100, eleRes = 175 },
    [xi.zone.ABYSSEA_GRAUBERG]  = { cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 155, maxHP = 1900000, att =  8000, def = 2000, matt = 4000, acc = 2500, eva = 2500, macc = 2500, meva = 2500, da = 10, haste = 100, eleRes = 175 },
    [xi.zone.ABYSSEA_ULEGUERAND]= { cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 155, maxHP = 1900000, att =  8000, def = 2000, matt = 4000, acc = 2500, eva = 2500, macc = 2500, meva = 2500, da = 10, haste = 100, eleRes = 175 },
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
    spawned:setMaxHP(cfg.maxHP)
    spawned:setHP(cfg.maxHP)
    spawned:addMod(xi.mod.ATT,  cfg.att)
    spawned:addMod(xi.mod.DEF,  cfg.def)
    spawned:addMod(xi.mod.MATT, cfg.matt)
    spawned:addMod(xi.mod.ACC,  cfg.acc)
    spawned:addMod(xi.mod.EVA,  cfg.eva)
    spawned:addMod(xi.mod.MACC, cfg.macc)
    spawned:addMod(xi.mod.MEVA, cfg.meva)
    spawned:addMod(xi.mod.DOUBLE_ATTACK, cfg.da)     -- extra swings -> a real melee threat
    spawned:addMod(xi.mod.HASTE_GEAR,    cfg.haste)  -- faster attack round (100 = 1%)
    -- Elemental-nuke resistance: raise magic evasion vs all 8 elements so
    -- Fire/Blizzard/Thunder/etc. get resisted more often (on top of meva above).
    for _, emod in ipairs({
        xi.mod.FIRE_MEVA,    xi.mod.ICE_MEVA,   xi.mod.WIND_MEVA,  xi.mod.EARTH_MEVA,
        xi.mod.THUNDER_MEVA, xi.mod.WATER_MEVA, xi.mod.LIGHT_MEVA, xi.mod.DARK_MEVA,
    }) do
        spawned:addMod(emod, cfg.eleRes)
    end
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
        callback = function(pl) pl:printToPlayer('[Abyssea] Not enough Hunt Marks.', xi.msg.channel.SYSTEM_3) end
    end

    player:timer(30, function(p)
        p:customMenu({
            title   = nmName,
            options = {
                { label, callback },
                { 'Close', function() end },
            },
        })
    end)
end

-- Returns (partyMult, trustMult).
-- partyMult = 2.0 when 2+ real PCs are in party, else 1.0.
-- trustMult = 1.5 when NO trusts anywhere in the party, else 1.0.
--
-- IMPORTANT: getPartyMember / PParty->members hold PC-type entities ONLY
-- (src/map/party.cpp:604 gates AddMember to TYPE_PC). Trusts live in each
-- PC's own PChar->PTrusts vector, so the previous getPartyMember loop could
-- never see them and the "no trusts" bonus was awarded on EVERY Abyssea
-- kill regardless of trust presence.
--
-- getPartyWithTrusts() (src/map/lua/lua_baseentity.cpp:11493) wraps
-- CCharEntity::ForPartyWithTrusts which iterates PCs AND every PC's PTrusts
-- (charentity.h:418) -- for solo it yields self + own PTrusts, for a party
-- it yields all PCs + all their PTrusts. So counting isTrust() entries
-- gives an accurate zone-wide trust total. Wrapped in pcall so a missing
-- API never breaks the reward path.
local function calcMultipliers(player)
    local partyMult = 1.0
    local trustMult = 1.0

    local ok = pcall(function()
        local pcCount    = 0
        local trustCount = 0
        local all = player:getPartyWithTrusts() or {}
        for _, mem in ipairs(all) do
            if mem:isTrust() then
                trustCount = trustCount + 1
            else
                pcCount = pcCount + 1
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
-- ??? marks-pop hook  (xi.abyssea.marksPopHook)
-- Registered as a HOOK, not an addOverride: the stock
-- xi.abyssea.qmOnTrigger calls this first (the call is baked into
-- abyssea.lua).  A Lua-sync reload of abyssea.lua re-defines
-- qmOnTrigger but CANNOT remove this hook, so the ??? pop survives.
-- Return nil to fall through to the stock function; return
-- true/false when we've handled it (offered the pop / released).
-- ============================================================
xi.abyssea.marksPopHook = function(player, npc, mobId, kis, tradeReqs)
    local cfg = zoneConfig[player:getZoneID()]
    if not cfg then
        return nil  -- not a marks zone -> stock handles
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

    -- Mob already up: let the stock qmOnTrigger handle it.
    if mob:isSpawned() then
        return nil
    end

    -- Mob is NOT spawned: ALWAYS route through the marks-pop so every ??? pop in a
    -- marks zone grants Infamy, regardless of whether the player holds the Abyssea
    -- Key Items. (Previously this was gated on "missing a required KI", which
    -- silently excluded every KI-holder from earning Infamy -- once a player got
    -- the KIs, the ??? fell back to the stock free pop with no Infamy.) The marks
    -- cost is now the price for everyone; the KI/trade isn't consumed for these NMs.
    local ok = pcall(offerMarksPop, player, mobId, cfg)
    if ok then
        player:release()
        return false
    end

    return nil  -- offer errored -> let stock handle so the ??? still works
end

-- ============================================================
-- Reward on kill  (xi.mob.marksRewardHook)
-- Registered as a HOOK, not an addOverride: the stock
-- xi.mob.onMobDeathEx calls this at the end (call baked into
-- mobs.lua), so a Lua-sync reload of mobs.lua can't clobber it.
-- The core calls this once per in-zone alliance/party member (ForAlliance in
-- luautils OnMobDeath), so it awards Gil + Infamy + Cruor to EACH of them on a
-- marks-popped NM kill, with multipliers for:
--   x2.0  - 2+ real players in party
--   x1.5  - no trusts in party
-- Multipliers stack (solo no-trust = x1.5, party no-trust = x3).
-- ============================================================
xi.mob.marksRewardHook = function(mob, player, isKiller, isWeaponSkillKill)
    -- The core fans OnMobDeath out with ForAlliance and calls onMobDeathEx -> this
    -- hook ONCE PER in-zone alliance/party member (luautils.cpp OnMobDeath;
    -- mobentity.cpp: "called for all alliance / party members"). So we just award
    -- to THIS member and let the engine decide who -- which covers the WHOLE
    -- in-zone alliance, not only the killer's party.
    --
    -- The old version gated on isKiller (discarding every other member's call) and
    -- then hand-walked the party via getPartyMember(i, 0). That walk only saw the
    -- killer's OWN party (allianceparty = 0, never the rest of an alliance) and was
    -- index-fragile (getPartyMember(0,0) returns self, not members[0]) -- which is
    -- exactly why some members got no Infamy. Per-member award fixes it. Mirrors
    -- allied_notes_drop.lua.  (isKiller / isWeaponSkillKill are unused now.)
    if mob == nil or player == nil then return end
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

        -- Award to THIS member (engine already calls us once per in-zone member).
        if infamyEarned > 0 then
            player:setCharVar(INFAMY_CV,      (player:getCharVar(INFAMY_CV)      or 0) + infamyEarned)
            player:setCharVar(INFAMY_LIFE_CV, (player:getCharVar(INFAMY_LIFE_CV) or 0) + infamyEarned)
        end
        if gilEarned   > 0 then player:addGil(gilEarned)                 end
        if cruorEarned > 0 then player:addCurrency('cruor', cruorEarned) end

        -- Reward message for this member.
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
        player:printToPlayer(msg, xi.msg.channel.SYSTEM_3)
    end)

    -- Tier-gated augment catalyst (soft gating): Abyssea HEROES marks-NMs
    -- (Lv155, the hardest Abyssea band) drop a Tier-4 catalyst -- a second T4
    -- source alongside Shinryu. Fires per in-zone member, like the rewards above.
    pcall(function()
        local cfg = zoneConfig[player:getZoneID()]
        if cfg and cfg.level >= 155 then
            require('modules/custom/lua/augment_catalyst_pools').roll(player, 4)
        end
    end)
end

return m
