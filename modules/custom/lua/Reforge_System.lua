-----------------------------------
-- Reforge_System.lua
-- NM-farm-to-reforged-armor system. Three currencies, three NM pools.
--
-- Components:
--   Reforge Spawner — pops one of 3 NM types on demand.
--                     AF Marks  <- Sky Gods
--                     Rel Marks <- Unity NMs
--                     Em  Marks <- Abyssea NMs
--                     Each kill drops a random BASE piece from THAT set's
--                     loot pool, plus the matching currency.
--   Reforge Vendor  — paginated browser to spend currency on upgrades:
--                       base -> +1 / +1 -> +2 / +2 -> +3
--                     Each upgrade tier costs the corresponding set's marks.
--
-- To configure: edit modules/custom/lua/reforge_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/reforge_catalog')
local hg      = require('modules/custom/lua/hunters_guild')
local wh      = require('modules/custom/lua/weekly_hunts')

local huntZoneName = catalog.huntZonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', huntZoneName))

-----------------------------------
local m = Module:new('reforge_system')

-- customMenu prompt payload is capped at 150 bytes total. Page sizes below
-- are tuned to fit even with the longest realistic labels.
local JOBS_PG_SZ = 6   -- jobs per page on the job picker

-----------------------------------
-- Currency helpers — keyed by setKey
-----------------------------------
local function getMarks(player, setKey)
    return player:getCharVar(catalog.sources[setKey].cv)
end

-- CharVar used as the global "any custom NM defeated" counter. Bumped
-- by both this module (in awardCurrency) and HuntingLeague.lua so a
-- single leaderboard captures total NM slayings across both systems.
local NM_KILL_CV = 'Custom_NM_Kills'

local function addMarks(player, setKey, n)
    local def = catalog.sources[setKey]
    -- Current balance (spendable; goes down when player upgrades).
    player:setCharVar(def.cv, player:getCharVar(def.cv) + n)
    -- Lifetime accumulator that NEVER decreases — drives the
    -- "Lifetime Marks Earned" leaderboard so spending doesn't drop
    -- you on the board.
    local lifetimeCV = def.cv .. '_Lifetime'
    player:setCharVar(lifetimeCV, player:getCharVar(lifetimeCV) + n)
end

local function spendMarks(player, setKey, n)
    local cv = catalog.sources[setKey].cv
    player:setCharVar(cv, player:getCharVar(cv) - n)
end

-- "AF:25 Rel:0 Em:0" — used in menu titles to show all three balances at once
local function balanceTriplet(player)
    return string.format('AF:%d Rel:%d Em:%d',
        getMarks(player, 'af'),
        getMarks(player, 'relic'),
        getMarks(player, 'empy'))
end

-----------------------------------
-- Helpers
-----------------------------------

-- Convert a raw DB item name (e.g. "agoge_cuisses" or "pummelers_mask+1")
-- to a display name with spaces and title case ("Agoge Cuisses", "Pummelers Mask+1").
local function toDisplayName(rawName)
    -- Replace every underscore with a space, then capitalise the first letter
    -- of each space-separated word.  "+1"/"+2"/"+3" suffixes are left intact.
    return (rawName:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest
    end))
end

-----------------------------------
-- Award helpers
-----------------------------------
local function rollLootDrop(player, srcDef, mobLabel)
    -- Job-targeted drop bias: catalog.mainJobBias is the probability the
    -- piece is drawn from a 5-item pool of the killer's main job (instead
    -- of the ~110-item set-wide pool). If the killer's job has no entries
    -- in catalog.pieces, fall through to the full pool.
    local mainJob = player:getMainJob()
    local jobPool = catalog.buildJobLootPool(mainJob, srcDef.setKey)
    local bias    = catalog.mainJobBias or 0
    local useJob  = (#jobPool > 0) and (math.random() < bias)
    local pool    = useJob and jobPool or catalog.buildLootPool(srcDef.setKey)

    if #pool == 0 then
        player:printToPlayer(
            string.format('[Reforge] %s loot pool is empty -- populate reforge_catalog.lua, kupo!',
                srcDef.label),
            xi.msg.channel.SYSTEM_3
        )
        return
    end
    if player:getFreeSlotsCount() == 0 then
        player:printToPlayer('[Reforge] Inventory full -- no piece awarded, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end
    local itemId    = pool[math.random(#pool)]
    local addedItem = player:addItem({ id = itemId, quantity = 1 })
    local rawName   = addedItem and addedItem:getName() or string.format('item %d', itemId)
    local itemName  = toDisplayName(rawName)
    local tag       = useJob and ' (main-job match!)' or ''
    player:printToPlayer(
        string.format('[Reforge] %s dropped a base %s piece (%s)%s!', mobLabel, srcDef.setKey:upper(), itemName, tag),
        xi.msg.channel.SYSTEM_3
    )
end

local function awardCurrency(player, srcDef, mobDef)
    local base = mobDef.marks or 0

    -- Hunter's Guild integration (v2):
    --   * marks awarded use the AMPLIFIED value, factoring in:
    --       - current guild rank (Apprentice +0% ... Grandmaster +100%)
    --       - Trinity capstone (+25% to AF/Relic/Empy when active)
    --       - Apex capstone (+50% to ALL when active; supersedes Trinity)
    --   * rep is NO LONGER bumped here. Under the v2 design (2026-05-29)
    --     guild rep comes only from killing the dedicated vanilla HNMs
    --     listed in catalog.huntTargets — see hunters_guild_hunts.lua.
    --     Reforge kills still BENEFIT from rank (amplifier still flows),
    --     but they no longer GRANT rank progress.
    local final = hg.applyAmplifier(player, srcDef.setKey, base)
    local bonus = final - base

    addMarks(player, srcDef.setKey, final)

    -- Single global counter for the "Top NM Slayers" leaderboard.
    -- Counts each killed NM once, regardless of which currency pool.
    player:setCharVar(NM_KILL_CV, (player:getCharVar(NM_KILL_CV) or 0) + 1)

    -- Award message shows base + bonus split so the player can see
    -- the amplifier working. Plain message when no bonus is active.
    if bonus > 0 then
        player:printToPlayer(
            string.format('[Reforge] +%d %s  (base %d + guild bonus %d), kupo!',
                final, srcDef.currencyName, base, bonus),
            xi.msg.channel.SYSTEM_3
        )
    else
        player:printToPlayer(
            string.format('[Reforge] +%d %s, kupo!', final, srcDef.currencyName),
            xi.msg.channel.SYSTEM_3
        )
    end

    -- Note: Weekly Hunt Board nm_kill event is fired by the spawner's
    -- onMobDeath closure (not here) so it has access to spawnedAt for
    -- the Speed Demon objective's secondsToKill metadata.
end

-----------------------------------
-- VENDOR MENU GRAPH
-----------------------------------
local vendorMenu = { title = '', options = {} }

local buildVendorMain
local buildJobMenu
local buildSetMenu
local buildSlotMenu
local buildUpgradeMenu

buildVendorMain = function(player)
    vendorMenu.title = 'Reforge Vendor  ' .. balanceTriplet(player)
    vendorMenu.options =
    {
        { 'Browse Sets',          function(p) buildJobMenu(p, 1) end },
        { 'View Currency Detail', function(p)
            for _, setKey in ipairs(catalog.sourceOrder) do
                local s = catalog.sources[setKey]
                p:printToPlayer(string.format('%s: %d', s.currencyName, getMarks(p, setKey)),
                    xi.msg.channel.SYSTEM_3)
            end
            buildVendorMain(p)
        end },
        { 'Close', function(p) p:printToPlayer('Reforge well, kupo!', xi.msg.channel.SYSTEM_3) end },
    }
    player:timer(50, function(p) p:customMenu(vendorMenu) end)
end

buildJobMenu = function(player, page)
    local jobs   = catalog.jobs
    local nPages = math.max(1, math.ceil(#jobs / JOBS_PG_SZ))
    page = math.max(1, math.min(page, nPages))
    local startIdx = (page - 1) * JOBS_PG_SZ + 1
    local endIdx   = math.min(startIdx + JOBS_PG_SZ - 1, #jobs)

    local options = {}
    for i = startIdx, endIdx do
        local j = jobs[i]
        table.insert(options, { j.label, function(p) buildSetMenu(p, j) end })
    end
    if page > 1 then
        table.insert(options, { string.format('<< %d/%d', page - 1, nPages),
            function(p) buildJobMenu(p, page - 1) end })
    end
    if page < nPages then
        table.insert(options, { string.format('%d/%d >>', page + 1, nPages),
            function(p) buildJobMenu(p, page + 1) end })
    end
    table.insert(options, { '<< Back', function(p) buildVendorMain(p) end })

    vendorMenu.title   = string.format('Pick Job (%d/%d)', page, nPages)
    vendorMenu.options = options
    player:timer(50, function(p) p:customMenu(vendorMenu) end)
end

buildSetMenu = function(player, jobDef)
    local jobPieces = catalog.pieces[jobDef.id]
    local options   = {}

    local function setOption(setKey, label)
        local set = jobPieces and jobPieces[setKey]
        if not set then
            return  -- silently omit — this job's armor set isn't cataloged yet
        end
        table.insert(options, { label, function(p) buildSlotMenu(p, jobDef, setKey, set) end })
    end

    setOption('af',    'AF (Sky Gods)')
    setOption('relic', 'Relic (Unity)')
    setOption('empy',  'Empy (Abyssea)')
    table.insert(options, { '<< Back', function(p) buildJobMenu(p, 1) end })

    vendorMenu.title   = string.format('[%s] Pick Set  %s', jobDef.label, balanceTriplet(player))
    vendorMenu.options = options
    player:timer(50, function(p) p:customMenu(vendorMenu) end)
end

buildSlotMenu = function(player, jobDef, setKey, set)
    local options = {}
    local slotOrder = { 'head', 'body', 'hands', 'legs', 'feet' }
    for _, slotKey in ipairs(slotOrder) do
        local tiers = set[slotKey]
        if tiers and tiers[1] and tiers[1] > 0 then
            table.insert(options, {
                slotKey:gsub('^%l', string.upper),
                function(p) buildUpgradeMenu(p, jobDef, setKey, slotKey, tiers) end,
            })
        end
    end
    table.insert(options, { '<< Back', function(p) buildSetMenu(p, jobDef) end })

    local cur = catalog.sources[setKey]
    vendorMenu.title = string.format('[%s/%s] Pick Slot  %s:%d',
        jobDef.label, setKey, cur.currencyShort, getMarks(player, setKey))
    vendorMenu.options = options
    player:timer(50, function(p) p:customMenu(vendorMenu) end)
end

buildUpgradeMenu = function(player, jobDef, setKey, slotKey, tiers)
    local options    = {}
    local cur        = catalog.sources[setKey]
    local tierLabels = { 'base', '+1', '+2', '+3' }
    local costTable  = catalog.upgradeCost[setKey]
    local tierCosts  = { nil, costTable.plus1, costTable.plus2, costTable.plus3 }

    for tierIdx = 2, 4 do
        local fromId = tiers[tierIdx - 1]
        local toId   = tiers[tierIdx]
        if fromId and toId and fromId > 0 and toId > 0 then
            local cost   = tierCosts[tierIdx]
            local has    = player:hasItem(fromId)
            local canPay = getMarks(player, setKey) >= cost
            local flag   = (has and canPay) and '' or ' *'

            table.insert(options, {
                string.format('To %s [%d %s]%s', tierLabels[tierIdx], cost, cur.currencyShort, flag),
                function(p)
                    if not p:hasItem(fromId) then
                        p:printToPlayer(
                            string.format('You need the %s piece first, kupo!', tierLabels[tierIdx - 1]),
                            xi.msg.channel.SYSTEM_3)
                        buildUpgradeMenu(p, jobDef, setKey, slotKey, tiers)
                        return
                    end
                    if getMarks(p, setKey) < cost then
                        p:printToPlayer(
                            string.format('Need %d %s, kupo!', cost, cur.currencyName),
                            xi.msg.channel.SYSTEM_3)
                        buildUpgradeMenu(p, jobDef, setKey, slotKey, tiers)
                        return
                    end
                    if p:getFreeSlotsCount() == 0 then
                        p:printToPlayer('Inventory full! Free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
                        buildUpgradeMenu(p, jobDef, setKey, slotKey, tiers)
                        return
                    end

                    spendMarks(p, setKey, cost)
                    p:delItem(fromId, 1)
                    p:addItem({ id = toId, quantity = 1 })
                    p:printToPlayer(
                        string.format('Upgraded to %s, kupo!  (-%d %s)', tierLabels[tierIdx], cost, cur.currencyName),
                        xi.msg.channel.SYSTEM_3)
                    buildUpgradeMenu(p, jobDef, setKey, slotKey, tiers)
                end,
            })
        end
    end

    table.insert(options, { '<< Back',
        function(p) buildSlotMenu(p, jobDef, setKey, catalog.pieces[jobDef.id][setKey]) end })

    vendorMenu.title = string.format('[%s/%s/%s]  %s:%d',
        jobDef.label, setKey, slotKey, cur.currencyShort, getMarks(player, setKey))
    vendorMenu.options = options
    player:timer(50, function(p) p:customMenu(vendorMenu) end)
end

-----------------------------------
-- SPAWNER MENU GRAPH
--
-- Top level lists the 3 source categories. Picking one opens the NM list
-- for that source.  Killing one of those NMs awards a base piece from that
-- set + the set's currency.
-----------------------------------
local spawnerMenu = { title = '', options = {} }

local buildSpawnerMain
local buildSourceNMMenu

buildSpawnerMain = function(player)
    local options = {}
    for _, setKey in ipairs(catalog.sourceOrder) do
        local s = catalog.sources[setKey]
        table.insert(options, {
            -- "Sky Gods (AF)" — short so we stay under the 150-byte cap
            string.format('%s (%s)', s.label, s.currencyShort),
            function(p) buildSourceNMMenu(p, s) end,
        })
    end
    table.insert(options, { 'Close', function(p) p:printToPlayer('Hunt well, kupo!', xi.msg.channel.SYSTEM_3) end })

    -- Title carries the three balances; rows stay terse.
    spawnerMenu.title   = 'Spawner  ' .. balanceTriplet(player)
    spawnerMenu.options = options
    player:timer(50, function(p) p:customMenu(spawnerMenu) end)
end

buildSourceNMMenu = function(player, srcDef)
    local options = {}
    for _, mob in ipairs(srcDef.mobs) do
        local md = mob
        -- "<name>  +<n>" — currency context is in the title; some NM names
        -- (e.g. Itzpapalotl, Hadhayosh) are long enough that adding "Spawn "
        -- and a currency suffix per row would push the menu past 150 bytes.
        table.insert(options, {
            string.format('%s  +%d', md.label, md.marks),
            function(p)
                local z = p:getZone()

                -- Don't stack duplicates if already alive
                local existing = z:queryEntitiesByName(md.name)
                if existing then
                    for _, e in ipairs(existing) do
                        if e:getHP() > 0 then
                            p:printToPlayer(string.format('%s is already up, kupo!', md.label), xi.msg.channel.SYSTEM_3)
                            buildSourceNMMenu(p, srcDef)
                            return
                        end
                    end
                end

                local mPos = catalog.mobSpawnPos
                -- Record spawn time so Speed Demon (kill within 60s)
                -- objectives can compute secondsToKill. Captured by the
                -- onMobDeath closure below — survives all the way to
                -- the wh.fire() call after the kill.
                local spawnedAt = os.time()
                local mob = z:insertDynamicEntity({
                    objtype              = xi.objType.MOB,
                    groupId              = md.groupId,
                    groupZoneId          = catalog.huntZoneId,
                    name                 = md.name,
                    x                    = mPos.x,
                    y                    = mPos.y,
                    z                    = mPos.z,
                    rotation             = mPos.rot,
                    -- REQUIRED: without these the engine defaults to lv255
                    -- and players can't land hits.
                    minLevel             = md.minLv,
                    maxLevel             = md.maxLv,
                    -- Detection bitfield from xi.detects. Without this, the
                    -- engine logs "has no detection methods!" per spawn AND
                    -- the NM never auto-aggros. Same field handling as HL
                    -- and the Game Master; read in luautils.cpp.
                    detection            = xi.detects.SIGHT_AND_HEARING,
                    isAggroable          = true,
                    releaseIdOnDisappear = true,

                    onMobDeath = function(deadMob, killer)
                        if not killer then return end
                        rollLootDrop(killer, srcDef, md.label)
                        awardCurrency(killer, srcDef, md)
                        -- Weekly Hunt Board nm_kill — fired here (not
                        -- in awardCurrency) so the spawn-closure's
                        -- spawnedAt is in scope for secondsToKill.
                        wh.fire(killer, 'nm_kill', {
                            system        = 'reforge',
                            setKey        = srcDef.setKey,
                            level         = md.minLv or 0,
                            partySize     = killer:getPartySize() or 1,
                            secondsToKill = os.time() - spawnedAt,
                        })
                    end,
                })
                if not mob then
                    p:printToPlayer(
                        string.format('Failed to spawn %s (groupId %d missing?), kupo!', md.label, md.groupId),
                        xi.msg.channel.SYSTEM_3)
                    buildSourceNMMenu(p, srcDef)
                    return
                end
                mob:setSpawn(mPos.x, mPos.y, mPos.z, mPos.rot)
                mob:spawn()

                -- Block capacity points on kill. Reforge has its own
                -- currency (RF_*_Marks); without this gate, a Lv250 NM
                -- × EXP_RATE=10 dumps hundreds of thousands of CP per
                -- kill. Requires MOBMOD_NO_CAPACITY_POINTS=200 + the
                -- early-return in src/map/utils/charutils.cpp.
                mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

                -- Apply stat mods AFTER spawn() — spawn() recalculates
                -- stats from the pool and would wipe anything set
                -- earlier. Mirrors the Hunting League spawn path so
                -- catalog tweaks behave the same way across systems.
                if md.mods then
                    for modId, value in pairs(md.mods) do
                        mob:setMod(modId, value)
                    end
                end

                -- HP scaling: catalog field hpBoost = multiplier
                -- (e.g. 12 = 12× base HP). Lv250 Kirin/Tinnin/Hadhayosh
                -- get 25× base HP — a real fight, not a 5-second melt.
                if md.hpBoost then
                    local newMax = mob:getMaxHP() * md.hpBoost
                    mob:setMaxHP(newMax)
                    mob:setHP(newMax)
                end
                p:printToPlayer(
                    string.format('%s has appeared!  Slay it for %d %s + base piece, kupo!',
                        md.label, md.marks, srcDef.currencyName),
                    xi.msg.channel.SYSTEM_3)
                buildSourceNMMenu(p, srcDef)
            end,
        })
    end
    table.insert(options, { '<< Back', function(p) buildSpawnerMain(p) end })

    spawnerMenu.title   = string.format('%s  (%s)', srcDef.label, srcDef.currencyName)
    spawnerMenu.options = options
    player:timer(50, function(p) p:customMenu(spawnerMenu) end)
end

-----------------------------------
-- NPC placement
-----------------------------------
m:addOverride(catalog.huntZonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    local sPos = catalog.spawnerPos
    local Spawner = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Reforge_Spawner',
        packetName = string.format('%sNM Spawner', xi.icon.STAR_LARGE),
        look       = 2430,
        x = sPos.x, y = sPos.y, z = sPos.z, rotation = sPos.rot,
        widescan   = 1,
        onTrade    = function(p) p:printToPlayer('No trades, kupo!', xi.msg.channel.SYSTEM_3) end,
        onTrigger  = function(p) p:timer(50, function(pp) buildSpawnerMain(pp) end) end,
    })
    utils.unused(Spawner)

    local vPos = catalog.vendorPos
    local Vendor = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Reforge_Vendor',
        packetName = string.format('%sGear Sets', xi.icon.STAR_LARGE),
        look       = 2430,
        x = vPos.x, y = vPos.y, z = vPos.z, rotation = vPos.rot,
        widescan   = 1,
        onTrade    = function(p) p:printToPlayer('No trades -- use the menu, kupo!', xi.msg.channel.SYSTEM_3) end,
        onTrigger  = function(p) p:timer(50, function(pp) buildVendorMain(pp) end) end,
    })
    utils.unused(Vendor)
end)

return m
