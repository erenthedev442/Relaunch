-----------------------------------
-- unity_wanted.lua
-- Unity Concord "Wanted" battle system for Legendary Relaunch.
--
-- Board NPC in Celennia Memorial Library (zone 284):
--   Shows weekly featured NM (double reward), all 56 NMs by tier,
--   deducts accolades, warps player to Escha-Zi'tah (zone 288),
--   and spawns the chosen NM dynamically.
--
-- Spawner in Escha-Zi'tah (zone 288):
--   On zone-in, if a player has UW_NM charVar set, spawn the NM
--   near them. onMobDeath awards accolades and clears state.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Celennia_Memorial_Library/Zone')
require('scripts/zones/Escha_ZiTah/Zone')

local m = Module:new('unity_wanted')

local catalog = require('modules/custom/lua/unity_wanted_catalog')
local S       = xi.msg.channel.SYSTEM_3
local ICON    = xi.icon and xi.icon.STAR_LARGE or ''
local PAGE    = 5  -- NMs per menu page (stay ≤ 7 to respect customMenu 150-byte limit)

-- charVar keys
local CV_NM = 'UW_NM'  -- catalog NM id queued for spawn (0 = none)

-- Lookup tables
local nmById   = {}
local nmByName = {}
for _, nm in ipairs(catalog.nms) do
    nmById[nm.id]     = nm
    nmByName[nm.name] = nm
end

local function weeklyFeaturedId()
    return (math.floor(os.time() / 604800) % #catalog.nms) + 1
end

local function showMenu(player, menu)
    local snap = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

-----------------------------------
-- Spawn logic
-----------------------------------
local function spawnWantedNm(player, nm)
    local zone = GetZone(catalog.huntZoneId)
    if not zone then return end

    local existing = zone:queryEntitiesByName(nm.name)
    if existing then
        for _, e in ipairs(existing) do
            if e:getHP() > 0 then
                player:printToPlayer(
                    string.format('[Unity] %s is already up, kupo! Wait for it to fall.', nm.label), S)
                player:setCharVar(CV_NM, 0)
                return
            end
        end
    end

    local spawnPos    = catalog.arena['T' .. nm.tier]
    local despawnSecs = catalog.despawnSecs

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = nm.groupId,
        groupZoneId          = catalog.huntZoneId,
        name                 = nm.name,
        x                    = spawnPos.x,
        y                    = spawnPos.y,
        z                    = spawnPos.z,
        rotation             = spawnPos.rot,
        minLevel             = nm.minLv,
        maxLevel             = nm.maxLv,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobEngage = function(engMob)
            engMob:setLocalVar('UW_DespawnAt', 0)
        end,

        onMobDisengage = function(disMob)
            if despawnSecs > 0 then
                disMob:setLocalVar('UW_DespawnAt', os.time() + despawnSecs)
            end
        end,

        onMobRoam = function(roamMob)
            local dl = roamMob:getLocalVar('UW_DespawnAt')
            if dl > 0 and os.time() >= dl then
                DespawnMob(roamMob:getID())
            end
        end,

        onMobDeath = function(deadMob, killer)
            if not killer then return end
            local nmDef = nmByName[deadMob:getName()]
            if not nmDef then return end
            local reward = catalog.rewards[nmDef.tier]
            local isWeekly = (nmDef.id == weeklyFeaturedId())
            if isWeekly then
                reward = reward * 2
                killer:printToPlayer(
                    string.format('[Unity] Weekly bonus! %s yields double accolades!', nmDef.label), S)
            end
            killer:addCurrency('unity_accolades', reward)
            -- Lifetime EARNED accolades (never reduced by shop spending).
            -- Read by trust_progression_cap.lua's 3rd-trust-slot gate.
            killer:setCharVar('Unity_Accolades_Lifetime',
                (killer:getCharVar('Unity_Accolades_Lifetime') or 0) + reward)
            -- Distinct-NM conquest tally (read by trust_progression_cap.lua's
            -- 3rd-trust-slot gate). The per-NM flag dedupes so re-kills don't count.
            local conqFlag = 'UW_Conq_' .. nmDef.id
            if (killer:getCharVar(conqFlag) or 0) == 0 then
                killer:setCharVar(conqFlag, 1)
                killer:setCharVar('Unity_NMs_Conquered',
                    (killer:getCharVar('Unity_NMs_Conquered') or 0) + 1)
            end
            killer:printToPlayer(
                string.format('[Unity] %s defeated! +%d accolades (total: %d)', nmDef.label,
                    reward, killer:getCurrency('unity_accolades')), S)
            killer:setCharVar(CV_NM, 0)
        end,
    })
    if not mob then
        player:setCharVar(CV_NM, 0)
        player:printToPlayer('[Unity] Spawn failed — zone may be full. Try again or contact a GM.', S)
        return
    end
    player:printToPlayer(string.format('[Unity] %s has appeared! Good luck, kupo!', nm.label), S)
end

-----------------------------------
-- CML Board NPC
-----------------------------------
m:addOverride('xi.zones.Celennia_Memorial_Library.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }
    local mainScreen, tierScreen, confirmScreen, pledgeScreen, rewardScreen  -- forward declarations

    local function show(player)
        showMenu(player, menu)
    end

    local function leaderName(id)
        for _, l in ipairs(catalog.leaders) do
            if l.id == id then return l.name end
        end
        return 'none'
    end

    mainScreen = function(player)
        local featuredId = weeklyFeaturedId()
        local featured   = nmById[featuredId]
        menu.title   = string.format('%sUnity Concord [%d acc]', ICON, player:getCurrency('unity_accolades'))
        menu.options = {
            { string.format('Weekly: %s (2x)', featured and featured.label or '?'),
              function(p) if featured then confirmScreen(p, featured) end end },
            { 'Tier 1  Lv 75-80',   function(p) tierScreen(p, 1, 1) end },
            { 'Tier 2  Lv 99-119',  function(p) tierScreen(p, 2, 1) end },
            { 'Tier 3  Lv 120+',    function(p) tierScreen(p, 3, 1) end },
            { string.format('Unity: %s', leaderName(player:getUnityLeader())),
              function(p) pledgeScreen(p, 1) end },
            { 'Unity Rewards',      function(p) rewardScreen(p, 1) end },
            { 'Leave', function(p) p:printToPlayer('[Unity] Safe hunting!', S) end },
        }
        show(player)
    end

    tierScreen = function(player, tier, page)
        local tierNms = {}
        for _, nm in ipairs(catalog.nms) do
            if nm.tier == tier then table.insert(tierNms, nm) end
        end
        local start  = (page - 1) * PAGE + 1
        local finish = math.min(start + PAGE - 1, #tierNms)
        local cost   = catalog.costs[tier]
        local reward = catalog.rewards[tier]
        local weekly = weeklyFeaturedId()

        menu.title = string.format('T%d Hunts | cost %d / +%d acc', tier, cost, reward)
        local opts = {}
        for i = start, finish do
            local nm  = tierNms[i]
            local nm_ = nm
            local star = (nm.id == weekly) and '*' or ''
            table.insert(opts, {
                string.format('%s%s', nm.label, star),
                function(p) confirmScreen(p, nm_) end,
            })
        end
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) tierScreen(p, tier, page - 1) end })
        end
        if finish < #tierNms then
            table.insert(opts, { 'Next >>', function(p) tierScreen(p, tier, page + 1) end })
        end
        table.insert(opts, { '<< Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    confirmScreen = function(player, nm)
        local cost   = catalog.costs[nm.tier]
        local reward = catalog.rewards[nm.tier]
        local have   = player:getCurrency('unity_accolades')
        local bonus  = (nm.id == weeklyFeaturedId()) and 2 or 1
        local arenaStr = 'T' .. nm.tier
        local wp       = catalog.warpPos[arenaStr]
        local canAfford = have >= cost

        menu.title = string.format('[%s] Lv %d', nm.label, nm.minLv)
        menu.options = {
            {
                canAfford
                    and string.format('Hunt!  [%d acc -> +%d acc]', cost, reward * bonus)
                    or  string.format('Need %d acc (have %d)', cost, have),
                function(p)
                    if p:getCurrency('unity_accolades') < cost then
                        p:printToPlayer(string.format(
                            '[Unity] Need %d accolades (have %d), kupo.', cost, have), S)
                        confirmScreen(p, nm)
                        return
                    end
                    p:delCurrency('unity_accolades', cost)
                    p:setCharVar(CV_NM, nm.id)
                    p:setPos(wp.x, wp.y, wp.z, wp.rot, catalog.huntZoneId)
                    p:printToPlayer(string.format(
                        '[Unity] Entering the arena to hunt %s!', nm.label), S)
                end,
            },
            { '<< Back', function(p) tierScreen(p, nm.tier, 1) end },
        }
        show(player)
    end

    -----------------------------------
    -- Pledge / change your Unity (all 11 leaders). Free, no RoE grind.
    -----------------------------------
    pledgeScreen = function(player, page)
        local leaders = catalog.leaders
        local per     = 6
        local start   = (page - 1) * per + 1
        local finish  = math.min(start + per - 1, #leaders)
        local current = player:getUnityLeader()

        menu.title = 'Pledge to a Unity'
        local opts = {}
        for i = start, finish do
            local l    = leaders[i]
            local mark = (l.id == current) and ' *' or ''
            table.insert(opts, {
                l.name .. mark,
                function(p)
                    p:setUnityLeader(l.id)
                    -- Mark "All for One" (RoE 5) done so the retail service NPC and
                    -- the force-join-leader-1 bypass respect this choice.
                    if not p:getEminenceCompleted(5) then
                        xi.roe.onRecordTrigger(p, 5)
                    end
                    p:printToPlayer(string.format('[Unity] You now stand with %s, kupo!', l.name), S)
                    mainScreen(p)
                end,
            })
        end
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) pledgeScreen(p, page - 1) end })
        end
        if finish < #leaders then
            table.insert(opts, { 'Next >>', function(p) pledgeScreen(p, page + 1) end })
        end
        table.insert(opts, { '<< Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    -----------------------------------
    -- Accolade reward shop. Spend unity_accolades on catalog.shop items.
    -----------------------------------
    rewardScreen = function(player, page)
        local shop   = catalog.shop
        local per    = 4  -- keep title + 4 'Label (cost)' rows + nav under the 150-byte menu cap
        local start  = (page - 1) * per + 1
        local finish = math.min(start + per - 1, #shop)

        menu.title = 'Unity Rewards'
        local opts = {}
        for i = start, finish do
            local s = shop[i]
            table.insert(opts, {
                string.format('%s (%d)', s.label, s.cost),
                function(p)
                    local have = p:getCurrency('unity_accolades')
                    if have < s.cost then
                        p:printToPlayer(string.format('[Unity] Need %d accolades (have %d), kupo.', s.cost, have), S)
                        rewardScreen(p, page)
                        return
                    end
                    if p:getFreeSlotsCount() < 1 then
                        p:printToPlayer('[Unity] Your inventory is full, kupo!', S)
                        rewardScreen(p, page)
                        return
                    end
                    p:delCurrency('unity_accolades', s.cost)
                    p:addItem(s.item, 1)
                    p:printToPlayer(string.format('[Unity] Received %s. (%d accolades left)',
                        s.label, p:getCurrency('unity_accolades')), S)
                    rewardScreen(p, page)
                end,
            })
        end
        if page > 1 then
            table.insert(opts, { '<< Prev', function(p) rewardScreen(p, page - 1) end })
        end
        if finish < #shop then
            table.insert(opts, { 'Next >>', function(p) rewardScreen(p, page + 1) end })
        end
        table.insert(opts, { '<< Back', function(p) mainScreen(p) end })
        menu.options = opts
        show(player)
    end

    local Board = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Unity_Wanted_Board',
        packetName = string.format('%sUnity Wanted', ICON),
        look       = 2419,
        x          = catalog.boardPos.x,
        y          = catalog.boardPos.y,
        z          = catalog.boardPos.z,
        rotation   = catalog.boardPos.rot,
        widescan   = 1,
        onTrade    = function(player, npc, trade)
            player:printToPlayer('[Unity] Use the board menu, kupo!', S)
        end,
        onTrigger  = function(player, npc)
            mainScreen(player)
        end,
    })
    utils.unused(Board)
end)

-----------------------------------
-- Escha-Zi'tah zone-in: spawn queued NM
-----------------------------------
m:addOverride('xi.zones.Escha_ZiTah.Zone.onZoneIn', function(player, prevZone)
    super(player, prevZone)
    local nmId = player:getCharVar(CV_NM)
    if not nmId or nmId == 0 then return end
    local nm = nmById[nmId]
    if not nm then
        player:setCharVar(CV_NM, 0)
        return
    end
    -- 2-second delay: ensures client is stable before mob pop
    player:timer(2000, function(p)
        if p:getZoneID() == catalog.huntZoneId then
            spawnWantedNm(p, nm)
        end
    end)
end)

-----------------------------------
-- Bypass the retail Unity "10 RoE records" gate.
-- On Relaunch there is no retail RoE grind; auto-join leader 1 then forward.
-- We replace xi.unity.onTrigger directly (not via addOverride, which is for
-- zone-module paths only). The original is preserved in _origUnityTrigger.
-----------------------------------
do
    local _orig = xi.unity and xi.unity.onTrigger
    xi.unity = xi.unity or {}
    xi.unity.onTrigger = function(player, npc)
        if not player:getEminenceCompleted(5) then
            player:setUnityLeader(1)
            xi.roe.onRecordTrigger(player, 5)
        end
        if _orig then _orig(player, npc) end
    end
end

return m
