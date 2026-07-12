-----------------------------------
-- Reforge_System.lua
-- NM-farm-to-reforged-armor system. Three currencies, three NM pools.
--
-- Components:
--   Reforge Spawner - pops one of 3 NM types on demand.
--                     AF Marks  <- Sky Gods
--                     Rel Marks <- Unity NMs
--                     Em  Marks <- Abyssea NMs
--                     Each kill drops a random BASE piece from THAT set's
--                     loot pool, plus the matching currency.
--   Reforge Vendor  - paginated browser to spend currency on upgrades:
--                       base -> +1 / +1 -> +2 / +2 -> +3
--                     Each upgrade tier costs the corresponding set's marks.
--
-- To configure: edit modules/custom/lua/reforge_catalog.lua only.
-----------------------------------
require('modules/module_utils')
local catalog    = require('modules/custom/lua/reforge_catalog')
local hg         = require('modules/custom/lua/hunters_guild')
local wh         = require('modules/custom/lua/weekly_hunts')
-- Hardcore NM mechanics engine (stance dance / AoE / adds / drain / doom /
-- enrage / phases). Shared library; per-NM configs live in catalog.mechCfgs.
local mechanics  = require('modules/custom/lua/mob_mechanics_library')

local huntZoneName = catalog.huntZonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', huntZoneName))

-----------------------------------
local m = Module:new('reforge_system')

-- customMenu prompt payload is capped at 150 bytes total. Page sizes below
-- are tuned to fit even with the longest realistic labels.
local JOBS_PG_SZ = 6   -- jobs per page on the job picker
-- Un-engaged NM auto-despawn window (seconds). A popped NM that nobody
-- engages within this time vanishes on its own; engaging cancels it (see
-- onMobEngage / onMobRoam in the spawner). Tunable in the catalog; 0 disables.
local DESPAWN_SECS = catalog.unengagedDespawnSecs or 180

-----------------------------------
-- Salvage trade: set of all base-tier item IDs across every job/set/slot.
-- Built once at module load so the onTrade handler has an O(1) lookup.
-----------------------------------
local _basePieceIds = {}
do
    for _, jobPieces in pairs(catalog.pieces) do
        for _, setKey in ipairs({ 'af', 'relic', 'empy' }) do
            local set = jobPieces[setKey]
            if set then
                for _, slot in pairs(set) do
                    -- slot[1] is always the base tier
                    if slot[1] and slot[1] > 0 then
                        _basePieceIds[slot[1]] = true
                    end
                end
            end
        end
    end
end

-----------------------------------
-- Currency helpers - keyed by setKey
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
    -- Lifetime accumulator that NEVER decreases - drives the
    -- "Lifetime Marks Earned" leaderboard so spending doesn't drop
    -- you on the board.
    local lifetimeCV = def.cv .. '_Lifetime'
    player:setCharVar(lifetimeCV, player:getCharVar(lifetimeCV) + n)
end

local function spendMarks(player, setKey, n)
    local cv = catalog.sources[setKey].cv
    player:setCharVar(cv, player:getCharVar(cv) - n)
end

-- "AF:25 Rel:0 Em:0" - used in menu titles to show all three balances at once
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
    -- Drop CHANCE: NM kills no longer guarantee a piece. Marks (awardCurrency)
    -- are the steady deterministic path; a piece is a catalog.dropChance bonus.
    -- Drops are always the BASE (i109) piece -- the start of the upgrade line
    -- (owner request 2026-07-11; pre-upgraded +1/+2/+3 drops skipped the
    -- base->+3 mark grind the vendor is built around).
    if math.random() >= (catalog.dropChance or 1.0) then
        return
    end

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

    local itemId    = pool[math.random(#pool)]  -- pools are base-tier ids
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
    --     listed in catalog.huntTargets - see hunters_guild_hunts.lua.
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
    local snapshot = { title = vendorMenu.title, options = vendorMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
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
    local snapshot = { title = vendorMenu.title, options = vendorMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

buildSetMenu = function(player, jobDef)
    local jobPieces = catalog.pieces[jobDef.id]
    local options   = {}

    local function setOption(setKey, label)
        local set = jobPieces and jobPieces[setKey]
        if not set then
            return  -- silently omit - this job's armor set isn't cataloged yet
        end
        table.insert(options, { label, function(p) buildSlotMenu(p, jobDef, setKey, set) end })
    end

    setOption('af',    'AF (Sky Gods)')
    setOption('relic', 'Relic (Unity)')
    setOption('empy',  'Empy (Abyssea)')
    table.insert(options, { '<< Back', function(p) buildJobMenu(p, 1) end })

    vendorMenu.title   = string.format('[%s] Pick Set  %s', jobDef.label, balanceTriplet(player))
    vendorMenu.options = options
    local snapshot = { title = vendorMenu.title, options = vendorMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
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
    local snapshot = { title = vendorMenu.title, options = vendorMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
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
    local snapshot = { title = vendorMenu.title, options = vendorMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
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

buildSpawnerMain = function(player, station)
    local options = {}
    for _, setKey in ipairs(catalog.sourceOrder) do
        local s = catalog.sources[setKey]
        table.insert(options, {
            -- "Sky Gods (AF)" - short so we stay under the 150-byte cap
            string.format('%s (%s)', s.label, s.currencyShort),
            function(p) buildSourceNMMenu(p, s, station) end,
        })
    end
    table.insert(options, { 'Close', function(p) p:printToPlayer('Hunt well, kupo!', xi.msg.channel.SYSTEM_3) end })

    -- Title carries the station number + the three balances; rows stay terse.
    spawnerMenu.title   = string.format('Spawner %d  %s', station.id, balanceTriplet(player))
    spawnerMenu.options = options
    local snapshot = { title = spawnerMenu.title, options = spawnerMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

buildSourceNMMenu = function(player, srcDef, station)
    local options = {}
    for _, mob in ipairs(srcDef.mobs) do
        local md = mob
        -- "<name> +<n>" - currency context is in the title. The label's
        -- internal whitespace is collapsed to a single space so any cosmetic
        -- column-padding in the catalog (which never aligns in the client's
        -- proportional font anyway) can't eat into the 150-byte menu budget
        -- enforced below. Long names (Itzpapalotl, Hadhayosh) make every byte
        -- count - unpadded the empy menu is 138 bytes; padded it was 167 and
        -- overflowed, truncating the apex NM's row so it couldn't be spawned.
        table.insert(options, {
            string.format('%s +%d', (md.label:gsub('%s+', ' ')), md.marks),
            function(p)
                local z = p:getZone()

                -- Per-station single-occupancy guard. Each spawner station hosts
                -- at most ONE live NM at a time, tracked on station.activeMob
                -- (cleared in onMobDeath and the idle-despawn branch of onMobRoam).
                -- This replaces the old zone-wide queryEntitiesByName(md.name)
                -- guard on purpose: that guard let only ONE copy of a given NM
                -- exist in the whole zone, so a second party couldn't pop the same
                -- NM. Per-station occupancy is what lets many parties farm the hub
                -- -- including the SAME NM type -- concurrently. The getHP() call is
                -- pcall-guarded because station.activeMob may reference an entity
                -- that was released (releaseIdOnDisappear) if a despawn path was
                -- missed; a failed/zero read is treated as "station free".
                if station.activeMob then
                    local ok, hp = pcall(function() return station.activeMob:getHP() end)
                    if ok and hp and hp > 0 then
                        p:printToPlayer(
                            string.format('Station %d already has an NM up, kupo! (try another station)', station.id),
                            xi.msg.channel.SYSTEM_3)
                        buildSourceNMMenu(p, srcDef, station)
                        return
                    end
                    station.activeMob = nil
                end

                local mPos = station.mobSpawnPos
                -- Record spawn time so Speed Demon (kill within 60s)
                -- objectives can compute secondsToKill. Captured by the
                -- onMobDeath closure below - survives all the way to
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

                    -- Idle despawn: an un-engaged NM cleans itself up after
                    -- DESPAWN_SECS so an ignored/accidental pop (or one tagged
                    -- then abandoned) doesn't clog the spawn area or block a
                    -- re-pop behind the dup-spawn guard. State machine on the
                    -- RF_DespawnAt localVar (absolute os.time deadline):
                    --   * stamped after spawn() below   (initial countdown)
                    --   * onMobEngage    -> 0            (fighting; no despawn)
                    --   * onMobDisengage -> re-armed     (abandoned; count again)
                    --   * onMobRoam      -> despawns once past the deadline
                    -- onMobRoam fires only while alive AND un-engaged, so it
                    -- can never interrupt an active fight. Mirrors HuntingLeague.
                    onMobEngage = function(engagedMob)
                        engagedMob:setLocalVar('RF_DespawnAt', 0)
                    end,

                    onMobDisengage = function(disMob)
                        if DESPAWN_SECS > 0 then
                            disMob:setLocalVar('RF_DespawnAt', os.time() + DESPAWN_SECS)
                        end
                    end,

                    onMobRoam = function(roamMob)
                        local deadline = roamMob:getLocalVar('RF_DespawnAt')
                        if deadline > 0 and os.time() >= deadline then
                            -- Idle despawn: free mechanics state before removing
                            -- (idempotent + pcall-safe in the library).
                            mechanics.cleanup(roamMob)
                            -- Free the station so it can be re-popped immediately.
                            station.activeMob = nil
                            DespawnMob(roamMob:getID())
                        end
                    end,

                    onMobFight = function(mfMob, mfTarget)
                        mechanics.tick(mfMob, mfTarget)
                    end,

                    onMobDeath = function(deadMob, killer)
                        mechanics.cleanup(deadMob)
                        -- Free the station the instant its NM dies so the next
                        -- party can pop here without waiting on the corpse.
                        station.activeMob = nil
                        if not killer then return end
                        rollLootDrop(killer, srcDef, md.label)
                        awardCurrency(killer, srcDef, md)
                        -- Weekly Hunt Board nm_kill - fired here (not
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
                    buildSourceNMMenu(p, srcDef, station)
                    return
                end
                -- Mark this station occupied. Cleared in onMobDeath / idle-despawn.
                station.activeMob = mob
                mob:setSpawn(mPos.x, mPos.y, mPos.z, mPos.rot)
                mob:spawn()

                -- [DIAG 2026-07-09, RESOLVED 2026-07-11] The "all NMs pop at /
                -- occupancy reports Spawner 3" bug was the shared-closure case:
                -- all three spawner NPCs were inserted with the SAME name
                -- ('Reforge_Spawner'), and the engine caches dynamic-entity
                -- callbacks by name, so every NPC ran the last station's
                -- onTrigger. Fixed by unique per-station names above. This
                -- one-line trace stays to verify station routing on live;
                -- grep the map log for: [Reforge][DIAG]
                print(string.format(
                    '[Reforge][DIAG] pop=%s station.id=%d mPos=(%.2f,%.2f,%.2f) actual=(%.2f,%.2f,%.2f)',
                    tostring(md.name), station.id,
                    mPos.x, mPos.y, mPos.z,
                    mob:getXPos(), mob:getYPos(), mob:getZPos()))

                -- Arm the un-engaged despawn (absolute deadline). onMobRoam
                -- removes the NM if still un-engaged past this time; onMobEngage
                -- clears it. Stamped after spawn() so spawn()'s stat recalc
                -- can't wipe it. Mirrors HuntingLeague.
                if DESPAWN_SECS > 0 then
                    mob:setLocalVar('RF_DespawnAt', os.time() + DESPAWN_SECS)
                end

                -- Capacity/Job Points are INTENTIONALLY enabled on this NM
                -- (2026-06-14). It is a single-target, on-demand pop, so the
                -- engine's level-scaled CP (x EXP_RATE*CAPACITY_RATE, currently
                -- ~x9; 30,000 CP per Job Point) is a deliberate, difficulty-
                -- scaled JP source: a Lv250 NM ~= 9.75 JP/kill, a Lv150 ~= 0.48.
                -- Previously suppressed via NO_CAPACITY_POINTS=1 -- removed
                -- because that was tuned for an old 10x world and zeroed ALL JP.
                -- Multi-mob wave/add systems (Invasion/Dungeon/Raid/Colosseum)
                -- still set the flag so mass clears can't be CP-farmed.

                -- Apply stat mods AFTER spawn() - spawn() recalculates
                -- stats from the pool and would wipe anything set
                -- earlier. Mirrors the Hunting League spawn path so
                -- catalog tweaks behave the same way across systems.
                if md.mods then
                    for modId, value in pairs(md.mods) do
                        mob:setMod(modId, value)
                    end
                end

                -- HP scaling: catalog field hpBoost = multiplier
                -- (e.g. 12 = 12x base HP). Lv250 Kirin/Tinnin/Hadhayosh
                -- get 25x base HP - a real fight, not a 5-second melt.
                if md.hpBoost then
                    local newMax = mob:getMaxHP() * md.hpBoost
                    mob:setMaxHP(newMax)
                    mob:setHP(newMax)
                end

                -- Attach hardcore mechanics AFTER spawn() + stat/HP setup so
                -- the library records the correct starting HP. Reforge NMs keep
                -- hostile pulses limited to the current hate target's party.
                local mechCfg = catalog.mechCfgs and catalog.mechCfgs[md.groupId]
                if mechCfg then
                    mechCfg.targetPartyOnly = true
                end
                mechanics.attach(mob, mechCfg)

                p:printToPlayer(
                    string.format('%s has appeared!  Slay it for %d %s + base piece, kupo!',
                        md.label, md.marks, srcDef.currencyName),
                    xi.msg.channel.SYSTEM_3)
                -- Close the spawner on a successful pop. Selecting the option
                -- already dismisses the client menu; re-showing the NM list here
                -- (as the "already up" / "failed to spawn" error paths do) left
                -- the menu stuck open and forced a manual dismiss. Just return.
            end,
        })
    end
    table.insert(options, { '<< Back', function(p) buildSpawnerMain(p, station) end })

    -- Title mirrors the spawner main menu's "<set> (<short>)" form (e.g.
    -- "Abyssea NMs (Em)"). Using currencyShort instead of the full
    -- currencyName ("Empy Marks") keeps the whole menu under the wire cap.
    spawnerMenu.title   = string.format('%s (%s)', srcDef.label, srcDef.currencyShort)
    spawnerMenu.options = options

    -- Wire-safety guard. SetCustomMenuContext (luautils.cpp) serializes the
    -- menu as the title plus every option label, each wrapped in quotes
    -- (+2 bytes), and the client only receives the first 150 bytes (Mes[150]
    -- in the GP_SERV_COMMAND_CHAT_STD packet, packets/s2c/0x017_chat_std.h).
    -- Overflow truncates the tail: the last NM renders cut off AND its click
    -- can't exact-match in HandleCustomMenu, so it silently no-ops. That is
    -- exactly what made the Lv250 apex NM (Hadhayosh) unspawnable. Warn to
    -- the console if a future NM/label addition blows the budget again.
    local menuBytes = #spawnerMenu.title + 2
    for _, opt in ipairs(spawnerMenu.options) do
        menuBytes = menuBytes + #opt[1] + 2
    end
    if menuBytes > 150 then
        print(string.format(
            '[Reforge] WARNING: "%s" spawn menu is %d bytes (>150 cap) -- its last NM will render truncated and be unclickable. Shorten labels or paginate the NM list.',
            srcDef.label, menuBytes))
    end

    local snapshot = { title = spawnerMenu.title, options = spawnerMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- NPC placement
-----------------------------------
m:addOverride(catalog.huntZonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -- One "NM Spawner" NPC per station (catalog.stations). Each carries its
    -- own station table into the menu closures, so its pops land at that
    -- station's mobSpawnPos and its occupancy is tracked independently. This
    -- is the "multiple spawn NPCs so many people can play at once" mechanic:
    -- N stations => N parties can each have their own NM up simultaneously.
    for _, station in ipairs(catalog.stations) do
        local st   = station
        local sPos = st.spawnerPos
        local Spawner = zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            -- name MUST be unique per station: the engine caches dynamic-entity
            -- callbacks by name (luautils GenerateDynamicEntity binds them at
            -- xi.zones.<zone>.npcs['DE_'..name]), so identical names make every
            -- spawner run the LAST station's onTrigger -- the 2026-07-11 "all
            -- spawners say Station 3 occupied" bug. Mirrors HuntingLeague's
            -- per-tier spawner naming.
            name       = string.format('Reforge_Spawner_%d', st.id),
            packetName = string.format('%sNM Spawner %d', xi.icon.STAR_LARGE, st.id),
            look       = 92,
            x = sPos.x, y = sPos.y, z = sPos.z, rotation = sPos.rot,
            widescan   = 1,
            onTrade    = function(p) p:printToPlayer('No trades, kupo!', xi.msg.channel.SYSTEM_3) end,
            onTrigger  = function(p) p:timer(50, function(pp) buildSpawnerMain(pp, st) end) end,
        })
        utils.unused(Spawner)
    end

    local vPos = catalog.vendorPos
    local Vendor = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Reforge_Vendor',
        packetName = string.format('%sGear Sets', xi.icon.STAR_LARGE),
        look       = 93,
        x = vPos.x, y = vPos.y, z = vPos.z, rotation = vPos.rot,
        widescan   = 1,
        onTrade    = function(p, npc, trade)
            -- Salvage mechanic: trade exactly 5 identical base-tier pieces
            -- for 15 Hunt Marks (HL_Points).
            local tradeSize = trade:getSlotCount()
            if tradeSize == 5 then
                -- Collect all traded item IDs to verify they are all the same.
                local firstId = nil
                local allSame = true
                for slot = 0, tradeSize - 1 do
                    local itemId = trade:getItemId(slot)
                    if firstId == nil then
                        firstId = itemId
                    elseif itemId ~= firstId then
                        allSame = false
                        break
                    end
                end

                if allSame and firstId and _basePieceIds[firstId] then
                    trade:confirmTrade()
                    local current = p:getCharVar('HL_Points')
                    p:setCharVar('HL_Points', current + 15)
                    p:printToPlayer('[Reforge] Salvaged 5 redundant pieces - +15 Hunt Marks awarded.', xi.msg.channel.SYSTEM_3)
                    return
                end
            end

            p:printToPlayer('No trades -- use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,
        onTrigger  = function(p) p:timer(50, function(pp) buildVendorMain(pp) end) end,
    })
    utils.unused(Vendor)
end)

return m
