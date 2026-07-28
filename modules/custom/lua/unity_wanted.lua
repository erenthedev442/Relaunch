-----------------------------------
-- unity_wanted.lua
-- Unity Concord "Wanted" battle system for Legendary Relaunch.
--
-- Retail junction flow (owner request 2026-07-12, self-service rev same day):
--   * The Ethereal Junction in each NM's retail zone is SELF-SERVICE: click
--     it at ANY time -- no registration -- pick the zone's Wanted NM, expend
--     the accolades, fight. Chain-pop as long as your accolades hold out;
--     stumbling on a junction in the wild works too.
--   * The hub Board is a taxi + info service: pick an NM and it warps you to
--     the right junction (plus shop / pledge / +1 upgrades as before).
--   * Stock junction NPCs get ON_TRIGGER listeners; missing or stock-hidden
--     junctions use a custom NPC at a verified-safe anchor
--     (unity_junction_map.lua).
--   * onMobDeath awards accolades and clears state (unchanged).
--   * NM stats/groups still live in zone 288 mob_groups; the engine's
--     InstantiateDynamicMob(group, groupZone, targetZone) spawns them
--     cross-zone at the junction.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
require('scripts/zones/Escha_ZiTah/Zone')

local m = Module:new('unity_wanted')

local catalog  = require('modules/custom/lua/unity_wanted_catalog')
local jmap     = require('modules/custom/lua/unity_junction_map')
local mechanics = require('modules/custom/lua/unity_wanted_mechanics')
local progress = require('modules/custom/lua/unity_wanted_progress')
local S        = xi.msg.channel.SYSTEM_3
local ICON     = xi.icon and xi.icon.STAR_LARGE or ''
local PAGE     = 5  -- NMs per menu page (stay ≤ 7 to respect customMenu 150-byte limit)


-- Lookup tables
local nmById = {}
local nmsByZone = {}  -- junction zone id -> { nm, ... } (1-2 NMs per zone)
for _, nm in ipairs(catalog.nms) do
    nmById[nm.id] = nm
    local zid = jmap.byNm[nm.name]
    if zid then
        nmsByZone[zid] = nmsByZone[zid] or {}
        table.insert(nmsByZone[zid], nm)
    else
        printf('[unity_wanted] WARN: %s has no junction zone mapping', nm.name)
    end
end

-- BASE-item -> +1 upgrade map, built from the catalog's drops (NQ id, +1 id)
-- and upgradeCost (keyed by the dropping NM's tier). Trade the base item to
-- the Unity Wanted Board with enough Unity Accolades to receive the +1.
local upgradeById = {}
for _, nm in ipairs(catalog.nms) do
    for _, d in ipairs(nm.drops or {}) do
        if d.plus1 then
            upgradeById[d.id] = {
                plus1     = d.plus1,
                plus1Name = d.plus1Name or (d.name .. ' +1'),
                name      = d.name,
                cost      = catalog.upgradeCost[nm.tier] or 0,
                tier      = nm.tier,
            }
        end
    end
end

local function weeklyFeaturedId()
    return (math.floor(os.time() / 604800) % #catalog.nms) + 1
end

local function showMenu(player, menu)
    local snap = { title = menu.title, options = menu.options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

local JUNCTION_SPAWN_DISTANCE = 10

local function junctionSpawnPosition(npc)
    local rotation = npc:getRotPos()
    local ok, position = pcall(GetFurthestValidPosition, npc, JUNCTION_SPAWN_DISTANCE, 0)
    if ok and type(position) == 'table' and position.x ~= nil then
        return {
            x   = position.x,
            y   = position.y,
            z   = position.z,
            rot = (rotation + 128) % 256,
        }
    end

    -- Navmesh probing can fail in zones without a loaded mesh. Fall back to
    -- the junction's facing rather than the old fixed +X/+Z diagonal.
    local radians = (rotation / 256) * 2 * math.pi
    return {
        x   = npc:getXPos() + math.cos(radians) * JUNCTION_SPAWN_DISTANCE,
        y   = npc:getYPos(),
        z   = npc:getZPos() - math.sin(radians) * JUNCTION_SPAWN_DISTANCE,
        rot = (rotation + 128) % 256,
    }
end

-----------------------------------
-- Spawn logic
-----------------------------------
local function spawnWantedNm(player, nm, pos)
    if not progress.isNmUnlocked(player, nm) then
        player:printToPlayer(string.format(
            '[Unity] This contract is sealed. First %s.',
            progress.nmUnlockRequirement(player, nm)), S)
        return 'refund'
    end

    -- Spawns in the PLAYER'S zone (at the junction); the mob group still
    -- belongs to zone 288 -- InstantiateDynamicMob supports the cross-zone
    -- group reference.
    local zone = player:getZone()
    if not zone then return end

    local existing = zone:queryEntitiesByName(nm.name)
    if existing then
        for _, e in ipairs(existing) do
            if e:getHP() > 0 then
                player:printToPlayer(
                    string.format('[Unity] %s is already up, kupo! Wait for it to fall.', nm.label), S)
                return 'refund'
            end
        end
    end

    local spawnPos    = pos or catalog.arena['T' .. nm.tier]
    local despawnSecs = catalog.despawnSecs
    local ownerName   = player:getName()

    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = nm.groupId,
        groupZoneId          = catalog.huntZoneId,
        name                 = nm.name,
        x                    = spawnPos.x,
        y                    = spawnPos.y,
        z                    = spawnPos.z,
        rotation             = spawnPos.rot,
        minLevel             = catalog.combatLevel or nm.minLv,
        maxLevel             = catalog.combatLevel or nm.maxLv,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobEngage = function(engMob)
            engMob:setLocalVar('UW_DespawnAt', 0)
            -- Player opened the fight themselves during the grace window --
            -- flip the mob back to normal aggression so it fights back and
            -- flag the grace timer to no-op when it fires.
            engMob:setLocalVar('UW_GraceCleared', 1)
            engMob:setMobMod(xi.mobMod.NO_AGGRO, 0)
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

        onMobDeath = function(deadMob)
            -- LSB invokes onMobDeath once per eligible alliance member. Settle
            -- this paid hunt exactly once against the player who purchased it;
            -- do not rely on the runtime mob name or final-hit entity.
            if deadMob:getLocalVar('UW_Rewarded') == 1 then return end

            local owner = GetPlayerByName(ownerName)
            if not owner then return end

            deadMob:setLocalVar('UW_Rewarded', 1)
            if owner:getHP() <= 0 then
                owner:printToPlayer(string.format(
                    '[Unity] %s falls, but the contract fails because you were knocked out.',
                    nm.label), S)
                return
            end

            local reward = catalog.rewards[nm.tier]
            local isWeekly = (nm.id == weeklyFeaturedId())
            if isWeekly then
                reward = reward * 2
                owner:printToPlayer(
                    string.format('[Unity] Weekly bonus! %s yields double accolades!', nm.label), S)
            end
            owner:addCurrency('unity_accolades', reward)
            -- Lifetime EARNED accolades (never reduced by shop spending).
            -- Read by trust_progression_cap.lua's Unity progression display.
            owner:setCharVar('Unity_Accolades_Lifetime',
                (owner:getCharVar('Unity_Accolades_Lifetime') or 0) + reward)
            -- Distinct-NM conquest tally (read by trust_progression_cap.lua's
            -- 4th-trust-slot gate). The per-NM flag dedupes so re-kills don't count.
            local conqFlag = 'UW_Conq_' .. nm.id
            if (owner:getCharVar(conqFlag) or 0) == 0 then
                owner:setCharVar(conqFlag, 1)
                owner:setCharVar('Unity_NMs_Conquered',
                    (owner:getCharVar('Unity_NMs_Conquered') or 0) + 1)
            end
            owner:printToPlayer(
                string.format('[Unity] %s defeated! +%d accolades (total: %d)', nm.label,
                    reward, owner:getCurrency('unity_accolades')), S)
        end,
    })
    if not mob then
        player:printToPlayer('[Unity] Spawn failed — zone may be full. Try again or contact a GM.', S)
        return 'refund'
    end

    -- insertDynamicEntity only allocates and registers the entity. As with the
    -- other dynamic NM systems, set its spawn point and explicitly pop it.
    mob:setSpawn(spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.rot)
    mob:spawn()

    -- Dynamic entities do not load retail per-NM scripts. Apply the shared
    -- tier profile and the mark's telegraphed encounter mechanics explicitly.
    mechanics.applyDifficulty(mob, nm, catalog.difficulty)
    mechanics.attach(mob, nm, player)

    -- Grace period: spawn pre-claimed to the paying player with the NM's
    -- AGGRO SUPPRESSED for N seconds -- the player can prepare in peace, but
    -- can OPEN THE FIGHT AT ANY TIME by attacking the mob directly. The mob
    -- reads red to the owner (updateClaim locks it to the owner's alliance)
    -- but stays fully targetable, so the player never has to wait through the
    -- grace timer if they're ready sooner. Player report 2026-07-13:
    -- - "NM spawned right on top of me, no time to summon trusts before aggro"
    --   -> keep grace, but only for the NM->player direction.
    -- - "60s wait needs to only be for the NM attacking, if we attack it we
    --   should be able to start the fight" (owner escalation 2026-07-13).
    --   -> NO_AGGRO suppresses mob-side aggression; onMobEngage clears the
    --      flag the instant the player attacks, restoring normal AI.
    mob:updateClaim(player)
    local grace = catalog.graceSeconds or 0
    if grace > 0 then
        mob:setMobMod(xi.mobMod.NO_AGGRO, 1)
        mob:setLocalVar('UW_GraceCleared', 0)
        player:printToPlayer(string.format(
            "[Unity] %s awakens... it holds back for %ds -- attack when you're ready.",
            nm.label, grace), S)
        mob:timer(grace * 1000, function(m)
            if not m or m:isDead() then return end
            -- If the player already engaged, onMobEngage flipped this to 1;
            -- do nothing so the message doesn't double-print.
            if m:getLocalVar('UW_GraceCleared') == 1 then return end
            m:setLocalVar('UW_GraceCleared', 1)
            m:setMobMod(xi.mobMod.NO_AGGRO, 0)
            m:updateEnmity(player)
            player:printToPlayer(string.format('[Unity] %s attacks!', nm.label), S)
        end)
    end

    -- Start the initial idle timer after spawn(), which can reset mob state.
    if despawnSecs > 0 then
        mob:setLocalVar('UW_DespawnAt', os.time() + despawnSecs)
    end

    player:printToPlayer(string.format('[Unity] %s has appeared! Good luck, kupo!', nm.label), S)
end

-----------------------------------
-- CML Board NPC
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
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
            { 'Tier 1  Lv99 Entry', function(p) tierScreen(p, 1, 1) end },
            { 'Tier 2  Lv99 Mid',   function(p) tierScreen(p, 2, 1) end },
            { 'Tier 3  Lv99 High',  function(p) tierScreen(p, 3, 1) end },
            { string.format('Unity: %s', leaderName(player:getUnityLeader())),
              function(p) pledgeScreen(p, 1) end },
            { 'Unity Rewards',      function(p) rewardScreen(p, 1) end },
            { 'Upgrades', function(p)
                p:printToPlayer('[Unity] Wanted NMs drop the BASE version of their gear, kupo!', S)
                p:printToPlayer(string.format(
                    '[Unity] Trade the base item to this board + accolades for the +1: T1 %d / T2 %d / T3 %d.',
                    catalog.upgradeCost[1], catalog.upgradeCost[2], catalog.upgradeCost[3]), S)
            end },
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
        local bonus  = (nm.id == weeklyFeaturedId()) and 2 or 1
        local zoneId = jmap.byNm[nm.name]
        local jz     = zoneId and jmap.junctions[zoneId]

        menu.title = string.format('[%s] Lv %d', nm.label, catalog.combatLevel or nm.minLv)
        menu.options = {
            {
                string.format('Travel to its junction [pop: %d acc -> +%d]', cost, reward * bonus),
                function(p)
                    if not progress.isNmUnlocked(p, nm) then
                        p:printToPlayer(string.format(
                            '[Unity] This contract is sealed. First %s.',
                            progress.nmUnlockRequirement(p, nm)), S)
                        return
                    end
                    if not jz then
                        p:printToPlayer('[Unity] No junction is mapped for that mark, kupo!', S)
                        return
                    end
                    local pt = jz.points[1]
                    p:printToPlayer(string.format(
                        '[Unity] Touch the Ethereal Junction to call %s forth (%d accolades).',
                        nm.label, cost), S)
                    p:setPos(pt.x + 1.5, pt.y, pt.z + 1.5, pt.rot, zoneId)
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
        look       = 234,
        x          = catalog.boardPos.x,
        y          = catalog.boardPos.y,
        z          = catalog.boardPos.z,
        rotation   = catalog.boardPos.rot,
        widescan   = 1,
        -- Upgrade trade: BASE Unity drop + enough Unity Accolades -> the +1.
        -- One item per trade; unknown items are refused untouched.
        onTrade    = function(player, npc, trade)
            local up, slotQty = nil, 0
            for slot = 0, 7 do
                local tradeItem = trade:getItem(slot)
                if tradeItem then
                    slotQty = slotQty + (trade:getSlotQty(slot) or 1)
                    up = up or upgradeById[tradeItem:getID()]
                end
            end
            if up == nil or slotQty ~= 1 then
                player:printToPlayer('[Unity] Trade me ONE base Wanted-NM drop to upgrade it to +1, kupo! (T1 '
                    .. catalog.upgradeCost[1] .. ' / T2 ' .. catalog.upgradeCost[2]
                    .. ' / T3 ' .. catalog.upgradeCost[3] .. ' accolades)', S)
                return
            end
            local have = player:getCurrency('unity_accolades')
            if have < up.cost then
                player:printToPlayer(string.format(
                    '[Unity] Upgrading %s to %s costs %d accolades — you have %d, kupo!',
                    up.name, up.plus1Name, up.cost, have), S)
                return
            end
            if player:getFreeSlotsCount() <= 0 then
                player:printToPlayer('[Unity] Make a free inventory slot first, kupo!', S)
                return
            end
            player:delCurrency('unity_accolades', up.cost)
            player:tradeComplete()
            player:addItem({ id = up.plus1, quantity = 1 })
            player:printToPlayer(string.format(
                '[Unity] %s reforged into %s for %d accolades! (%d left)',
                up.name, up.plus1Name, up.cost, player:getCurrency('unity_accolades')), S)
        end,
        onTrigger  = function(player, npc)
            mainScreen(player)
        end,
    })
    utils.unused(Board)
end)

-----------------------------------
-- Ethereal Junctions: registered marks pop HERE for accolades.
-- Stock junction NPCs (81 rows in sql/npc_list.sql) are plain script-less
-- npc_list entries -- an ON_TRIGGER listener is the whole wiring (same
-- pattern as the Geas-Fete ??? points). Zones whose retail junction rows
-- never made it into stock data get a custom junction dynamic NPC at a
-- verified-safe anchor (unity_junction_map.lua, custom = true).
-----------------------------------
local function junctionMenu(player, zoneId, npc)
    local zoneNms = nmsByZone[zoneId]
    if not zoneNms or #zoneNms == 0 then
        player:printToPlayer('[Unity] The junction hums with otherworldly energy.', S)
        return
    end

    local weekly = weeklyFeaturedId()
    local have   = player:getCurrency('unity_accolades')
    local opts   = {}

    for _, nm in ipairs(zoneNms) do
        local nmRef  = nm
        local cost   = catalog.costs[nm.tier]
        local reward = catalog.rewards[nm.tier]
        local bonus  = (nm.id == weekly) and 2 or 1
        local star   = (nm.id == weekly) and '*' or ''
        table.insert(opts, {
            string.format('%s%s [%d acc -> +%d]', nmRef.label, star, cost, reward * bonus),
            function(p)
                if not progress.isNmUnlocked(p, nmRef) then
                    p:printToPlayer(string.format(
                        '[Unity] This contract is sealed. First %s.',
                        progress.nmUnlockRequirement(p, nmRef)), S)
                    return
                end
                if p:getCurrency('unity_accolades') < cost then
                    p:printToPlayer(string.format('[Unity] Need %d accolades (have %d), kupo.',
                        cost, p:getCurrency('unity_accolades')), S)
                    return
                end
                p:delCurrency('unity_accolades', cost)
                local outcome = spawnWantedNm(p, nmRef, junctionSpawnPosition(npc))
                if outcome == 'refund' then
                    p:addCurrency('unity_accolades', cost)
                    p:printToPlayer(string.format('[Unity] Your %d accolades are returned.', cost), S)
                end
            end,
        })
    end
    table.insert(opts, { 'Never mind', function() end })

    showMenu(player, {
        title   = string.format('Ethereal Junction [%d acc]', have),
        options = opts,
    })
end

local function revealCustomJunction(npc)
    npc:setStatus(xi.status.NORMAL)
    npc:setAnimation(0)
    npc:setAnimationSub(5)
end

for zoneId, jz in pairs(jmap.junctions) do
    require(string.format('scripts/zones/%s/Zone', jz.zoneName))
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', jz.zoneName), function(zone)
        super(zone)
        local capturedZoneId = zoneId
        local capturedJz     = jz
        for _, pt in ipairs(capturedJz.points) do
            if pt.custom then
                local jnpc = zone:insertDynamicEntity({
                    objtype    = xi.objType.NPC,
                    name       = 'Ethereal_Junction',
                    packetName = 'Ethereal Junction',
                    look       = 2447,  -- stock junction model (npc_list look blob 0x8F09)
                    x          = pt.x,
                    y          = pt.y,
                    z          = pt.z,
                    rotation   = pt.rot,
                    namevis    = 116,
                    entityFlags = 3,
                    widescan   = 1,
                    onTrigger  = function(player, trigNpc)
                        junctionMenu(player, capturedZoneId, trigNpc)
                    end,
                })
                if jnpc then
                    -- Match stock Ethereal Junction rows: animation 0,
                    -- animation-sub 5, namevis 116, entity flags 3.
                    revealCustomJunction(jnpc)
                end
                utils.unused(jnpc)
            else
                local npc = GetNPCByID(pt.id)
                if npc then
                    -- Stock SOA Ethereal Junction rows ship with status = 2
                    -- (DISAPPEAR) in npc_list: GetNPCByID still finds them (so
                    -- no "missing" warning fires) but the CLIENT never renders
                    -- them, so players see no junction to click. 7 stock
                    -- junctions across 5 zones were hidden this way -- incl.
                    -- Jugner Forest, so Emperor Arthro had no reachable junction
                    -- (reported 2026-07-17). Force NORMAL so the rift is visible
                    -- and interactable. Same pattern as
                    -- conquest_regional_npcs_always_up.lua; guarded on a real
                    -- position so an origin placeholder is never surfaced.
                    if pt.x ~= 0 or pt.z ~= 0 then
                        npc:setStatus(xi.status.NORMAL)
                    end
                    npc:addListener('ON_TRIGGER', 'UNITY_JUNCTION', function(player, trigNpc)
                        junctionMenu(player, capturedZoneId, trigNpc)
                    end)
                else
                    printf('[unity_wanted] junction npc %i missing in zone %i', pt.id, zoneId)
                end
            end
        end
    end)
end

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
