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
local encounterCatalog = require('modules/custom/lua/abyssea_marks_catalog')
local encounterRuntime = require('modules/custom/lua/abyssea_marks_mechanics')
local encounterBalance = require('modules/custom/lua/abyssea_marks_balance')

local MARKS_CV         = 'HL_Points'
local INFAMY_CV        = 'Infamy'
local INFAMY_LIFE_CV   = 'Infamy_Lifetime'
local MARKS_INFAMY_LV  = '[MarksPopInfamy]'
local MARKS_GIL_LV     = '[MarksPopGil]'
local MARKS_CRUOR_LV   = '[MarksPopCruor]'

-- Per zone tier: mark cost + rewards, then the common pacing block applied at
-- pop.  Individual difficulty comes from abyssea_marks_catalog.lua.
--   level   is applied with setMobLevel before the overlay
--   maxHP   flat HP override (setMaxHP)
--   att / def / matt           melee attack / defense / magic attack added
--   acc / eva / macc / meva     accuracy / evasion / magic acc / magic eva added
--   weaponDmg  flat main-hand damage added to melee and physical TP moves
--   da      Double Attack % (extra swings)
--   haste   HASTE_GEAR (100 = 1% faster attack round)
--   eleRes  added to ALL 8 elemental magic-evasion mods (Fire..Dark) -- an
--           elemental-nuke resistance layered on top of meva
-- Threat is calibrated against the pre-Abyssea player baseline: roughly 3,000
-- ACC, 1,000 EVA, 3,400 DEF, and 35% DT.  Defense and HP preserve the proven
-- Relic clear-time budget; offense, weapon damage, and tempo make survival and
-- mechanics matter throughout that budget.
local zoneConfig =
{
    -- Visions: Relic entry tier; 5-7 minute solo target.
    [xi.zone.ABYSSEA_KONSCHTAT] = { tier = 1, cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 120, maxHP =  4000000, att = 6500, def =  850, matt = 2000, acc =  700, eva =  800, macc =  700, meva = 250, weaponDmg = 300, da = 20, haste = 1000, eleRes =  50 },
    [xi.zone.ABYSSEA_TAHRONGI]  = { tier = 1, cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 120, maxHP =  4000000, att = 6500, def =  850, matt = 2000, acc =  700, eva =  800, macc =  700, meva = 250, weaponDmg = 300, da = 20, haste = 1000, eleRes =  50 },
    [xi.zone.ABYSSEA_LA_THEINE] = { tier = 1, cost = 200, infamy = 25, gil = 250000, cruor = 1000, level = 120, maxHP =  4000000, att = 6500, def =  850, matt = 2000, acc =  700, eva =  800, macc =  700, meva = 250, weaponDmg = 300, da = 20, haste = 1000, eleRes =  50 },
    -- Scars: two-rule encounters, tuned around Relic + one Atma.
    [xi.zone.ABYSSEA_ATTOHWA]   = { tier = 2, cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 130, maxHP =  8000000, att = 8000, def = 1200, matt = 3200, acc =  900, eva = 1100, macc =  900, meva = 400, weaponDmg = 350, da = 25, haste = 1500, eleRes =  75 },
    [xi.zone.ABYSSEA_MISAREAUX] = { tier = 2, cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 130, maxHP =  8000000, att = 8000, def = 1200, matt = 3200, acc =  900, eva = 1100, macc =  900, meva = 400, weaponDmg = 350, da = 25, haste = 1500, eleRes =  75 },
    [xi.zone.ABYSSEA_VUNKERL]   = { tier = 2, cost = 350, infamy = 40, gil = 500000, cruor = 1500, level = 130, maxHP =  8000000, att = 8000, def = 1200, matt = 3200, acc =  900, eva = 1100, macc =  900, meva = 400, weaponDmg = 350, da = 25, haste = 1500, eleRes =  75 },
    -- Heroes: full set pieces, tuned around Relic + up to two Atma.
    [xi.zone.ABYSSEA_ALTEPA]    = { tier = 3, cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 150, maxHP = 14000000, att = 9500, def = 1650, matt = 4500, acc = 1100, eva = 1400, macc = 1100, meva = 550, weaponDmg = 400, da = 30, haste = 2000, eleRes = 100 },
    [xi.zone.ABYSSEA_GRAUBERG]  = { tier = 3, cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 150, maxHP = 14000000, att = 9500, def = 1650, matt = 4500, acc = 1100, eva = 1400, macc = 1100, meva = 550, weaponDmg = 400, da = 30, haste = 2000, eleRes = 100 },
    [xi.zone.ABYSSEA_ULEGUERAND]= { tier = 3, cost = 500, infamy = 60, gil = 750000, cruor = 2000, level = 150, maxHP = 14000000, att = 9500, def = 1650, matt = 4500, acc = 1100, eva = 1400, macc = 1100, meva = 550, weaponDmg = 400, da = 30, haste = 2000, eleRes = 100 },
}
for zoneId, cfg in pairs(zoneConfig) do
    assert(
        cfg.maxHP == encounterBalance.tiers[cfg.tier].hp,
        string.format('Abyssea HP contract drift in zone %d', zoneId))
end

local function realPlayerScale(player)
    local count = 1
    local ok, party = pcall(function() return player:getParty() end)
    if ok and party then
        local seen = {}
        count = 0
        for _, member in ipairs(party) do
            local memberOk, isPc = pcall(function() return member:isPC() end)
            if memberOk and isPc and member:getZoneID() == player:getZoneID() then
                local id = member:getID()
                if not seen[id] then
                    seen[id] = true
                    count = count + 1
                end
            end
        end
        count = math.max(1, count)
    end

    return encounterBalance.hpScale(count), count
end

local function logicalCopyIsSpawned(mobId, nmName)
    local key = encounterCatalog.normalize(nmName)
    -- Most flagship copies use *_OFFSET +0/+4/+8; Misareaux uses +0/+5/+10.
    -- Looking across both layouts catches the copy selected at any of the QMs.
    for _, offset in ipairs({ -10, -8, -5, -4, 0, 4, 5, 8, 10 }) do
        local candidate = GetMobByID(mobId + offset)
        if
            candidate and
            encounterCatalog.normalize(candidate:getName()) == key and
            candidate:isSpawned()
        then
            return true
        end
    end

    return false
end

local function spawnViaMark(p, mobId, cost, nmName, cfg)
    local cur = p:getCharVar(MARKS_CV) or 0
    if cur < cost then
        p:printToPlayer('[Abyssea] Not enough Hunt Marks.', xi.msg.channel.SYSTEM_3)
        return
    end
    local mob = GetMobByID(mobId)
    if not mob or logicalCopyIsSpawned(mobId, nmName) then
        p:printToPlayer('[Abyssea] This logical NM is already present.', xi.msg.channel.SYSTEM_3)
        return
    end
    local encounter = encounterCatalog.get(nmName)
    if not encounter then
        p:printToPlayer(
            string.format('[Abyssea] %s has no encounter definition. No marks were spent.', nmName),
            xi.msg.channel.SYSTEM_3)
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

    -- Normalize level before applying the custom pacing block. setMobLevel
    -- recalculates retail base stats, so it must precede HP and additive mods.
    spawned:setMobLevel(cfg.level, false)
    local hpScale, pcCount = realPlayerScale(p)
    local scaledHP = math.floor(cfg.maxHP * hpScale)
    spawned:setMaxHP(scaledHP)
    spawned:setHP(scaledHP)
    spawned:addMod(xi.mod.ATT,  cfg.att)
    spawned:addMod(xi.mod.DEF,  cfg.def)
    spawned:addMod(xi.mod.MATT, cfg.matt)
    spawned:addMod(xi.mod.ACC,  cfg.acc)
    spawned:addMod(xi.mod.EVA,  cfg.eva)
    spawned:addMod(xi.mod.MACC, cfg.macc)
    spawned:addMod(xi.mod.MEVA, cfg.meva)
    -- MAIN_DMG_RATING feeds getWeaponDmg(), so it strengthens both ordinary
    -- swings and physical TP moves such as Dead Dive and Grand Slam.
    spawned:addMod(xi.mod.MAIN_DMG_RATING, cfg.weaponDmg)
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
    spawned:setLocalVar('[MarksTier]', cfg.tier)
    spawned:setLocalVar('[MarksRealPCs]', pcCount)

    encounterRuntime.attach(spawned, encounter, p)
    spawned:updateClaim(p)
    spawned:updateEnmity(p)  -- immediately engage after the full profile is armed

    p:printToPlayer(
        string.format('[Abyssea] %d Hunt Marks spent. %s appears! (%d real PC%s)',
            cost, nmName, pcCount, pcCount == 1 and '' or 's'),
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

-- Tuning knobs, hoisted so tools/docgen can read the LIVE values via
-- lua_const() instead of mirroring them (the docgen previously hardcoded
-- 2.0 / 1.5 in abyssea_nms.py — same drift pattern as elsewhere).
local PARTY_MULT = 2.0    -- >=2 real PCs in party -> Gil/Infamy x this
local TRUST_MULT = 1.5    -- 0 trusts in party    -> Gil/Infamy x this

-- One complete zone roster opens the next Atma progression step. Attohwa has
-- 17 logical marks NMs (the old plan/audit counted 16); the duplicate OFFSET
-- QMs are alternate copies and do not increase these totals.
local ZONE_ROSTER_SIZE =
{
    [xi.zone.ABYSSEA_KONSCHTAT] = 15,
    [xi.zone.ABYSSEA_TAHRONGI]  = 15,
    [xi.zone.ABYSSEA_LA_THEINE] = 15,
    [xi.zone.ABYSSEA_ATTOHWA]   = 17,
    [xi.zone.ABYSSEA_MISAREAUX] = 16,
    [xi.zone.ABYSSEA_VUNKERL]   = 16,
    [xi.zone.ABYSSEA_ALTEPA]    = 14,
    [xi.zone.ABYSSEA_GRAUBERG]  = 14,
    [xi.zone.ABYSSEA_ULEGUERAND]= 14,
}

local function recordRosterClear(player, mob, cfg)
    local encounter = encounterCatalog.get(mob:getName())
    if not encounter then return end

    local stampVar = string.format('AbyNM_%03d', encounter.index)
    if player:getCharVar(stampVar) ~= 0 then return end

    player:setCharVar(stampVar, 1)
    local zoneId = player:getZoneID()
    local countVar = string.format('AbyZone_%d', zoneId)
    local count = (player:getCharVar(countVar) or 0) + 1
    player:setCharVar(countVar, count)

    -- A first clear refunds half the tier's pop cost. This makes roster
    -- exploration desirable without changing repeat-farm economics.
    local firstBonus = math.floor(cfg.cost / 2)
    player:setCharVar(MARKS_CV, (player:getCharVar(MARKS_CV) or 0) + firstBonus)
    player:printToPlayer(
        string.format('[Abyssea] FIRST CLEAR: %s (%d/%d in this zone). +%d Hunt Marks.',
            encounter.label, count, ZONE_ROSTER_SIZE[zoneId] or count, firstBonus),
        xi.msg.channel.SYSTEM_3)

    local needed = ZONE_ROSTER_SIZE[zoneId]
    if not needed or count < needed then return end

    if cfg.tier == 1 and not player:hasKeyItem(xi.ki.LUNAR_ABYSSITE1) then
        player:addKeyItem(xi.ki.LUNAR_ABYSSITE1)
        player:printToPlayer(
            '[Abyssea] VISIONS ROSTER COMPLETE! Lunar Abyssite unlocks your first Atma slot.',
            xi.msg.channel.SYSTEM_1)
    elseif cfg.tier == 2 and not player:hasKeyItem(xi.ki.LUNAR_ABYSSITE2) then
        player:addKeyItem(xi.ki.LUNAR_ABYSSITE2)
        player:printToPlayer(
            '[Abyssea] SCARS ROSTER COMPLETE! A second Lunar Abyssite unlocks another Atma slot.',
            xi.msg.channel.SYSTEM_1)
    end
end

-- Retail weakness selection already runs through the zone mixin. Add the
-- marks-fight combat payoff after the stock stagger/Atma bookkeeping.
m:addOverride('xi.abyssea.procMonster', function(mob, player, triggerType)
    super(mob, player, triggerType)
    encounterRuntime.onProc(mob, player, triggerType)
end)

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
        if pcCount >= 2    then partyMult = PARTY_MULT end
        if trustCount == 0 then trustMult = TRUST_MULT end
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

        local cfg = zoneConfig[player:getZoneID()]
        if cfg then
            recordRosterClear(player, mob, cfg)
        end
    end)

    -- Tier-gated augment catalyst (soft gating): Abyssea HEROES marks-NMs
    -- (tier 3, the hardest Abyssea band) drop a Tier-4 catalyst -- a second T4
    -- source alongside Shinryu. Fires per in-zone member, like the rewards above.
    pcall(function()
        local cfg = zoneConfig[player:getZoneID()]
        if cfg and cfg.tier == 3 then
            require('modules/custom/lua/augment_catalyst_pools').roll(player, 4)
        end
    end)
end

return m
