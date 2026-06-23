-----------------------------------
-- HuntingLeague.lua
-- Progressive NM hunting system with a Hunt Marks currency.
--
-- Components:
--   Hub NPC     - Hunt zone. Shows rank, points, tier unlock, reward shop.
--   Spawner NPC - Hunt zone. Pops current-tier NMs on demand via
--                 insertDynamicEntity (no mob_spawn_points required).
--   onMobDeath  - Wired inline per-mob inside each dynamic entity table;
--                 no zone-level override or stubs needed.
--
-- To configure: edit hunting_league_catalog.lua only.
-- Each mob.groupId must match a mob_groups row (hunting_league_mobs.sql).
--
-- Player CharVars:
--   HL_Points  - accumulated Hunt Marks
--   HL_Tier    - highest tier unlocked (1-5, defaults to 1)
-----------------------------------
require('modules/module_utils')
local catalog    = require('modules/custom/lua/hunting_league_catalog')
local hg         = require('modules/custom/lua/hunters_guild')
local wh         = require('modules/custom/lua/weekly_hunts')
local ach        = require('modules/custom/lua/achievements')
local se         = require('modules/custom/lua/seasonal_events')
-- Hardcore NM mechanics engine (stance dance / AoE / adds / drain / doom /
-- enrage / phases). Shared library; per-NM configs live in catalog.mechCfgs.
local mechanics  = require('modules/custom/lua/mob_mechanics_library')
-- Ascension (Prestige) layer. One-directional require: Prestige_System pulls
-- in only catalogs, never HuntingLeague, so there is no circular dependency.
local prestige = require('modules/custom/lua/Prestige_System')

-- Require the hunt zone so the override path is resolvable.
local huntZoneName = catalog.huntZonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', huntZoneName))

-----------------------------------
local m = Module:new('hunting_league')

local CV_POINTS  = 'HL_Points'
local CV_TIER    = 'HL_Tier'
local MAX_TIER   = #catalog.tiers
-- Un-engaged NM auto-despawn window (seconds). A popped NM that nobody
-- engages within this time vanishes on its own; engaging it cancels the
-- countdown (see onMobEngage / onMobRoam in the spawner below). Tunable in
-- the catalog; 0 disables.
local DESPAWN_SECS = catalog.unengagedDespawnSecs or 180
-- customMenu prompt payload is capped at 150 bytes total
-- (title + every option label, each NUL-terminated).
--
-- Budget breakdown:
--   Category list  - slot names avg ~7 chars; all 9 fit on one page (~126 bytes).
--   Item list      - name-only labels (no cost) capped at 15 chars per row;
--                    6 items + compact title + nav ~ 141 bytes worst-case.
--   Preview        - up to 4 stat lines (~20 chars each) + Buy + Back ~ 120 bytes.
--
-- Cost is shown only in the preview title, keeping list rows short enough to
-- fit 6 items per page - most categories need zero pagination.
local SHOP_PG_SZ    = 6    -- items per page inside a category
local CAT_PG_SZ     = 9    -- categories per page (all 9 fit on one page)
local MAX_ITEM_NAME = 15   -- item labels truncated to this before adding to menu row

-----------------------------------
-- CharVar helpers
-----------------------------------
local function getPoints(player)
    return player:getCharVar(CV_POINTS)
end

local function addPoints(player, amount)
    player:setCharVar(CV_POINTS, getPoints(player) + amount)
end

local function spendPoints(player, amount)
    player:setCharVar(CV_POINTS, getPoints(player) - amount)
end

local function getTier(player)
    local t = player:getCharVar(CV_TIER)
    return (t < 1) and 1 or t
end

local function setTier(player, tier)
    player:setCharVar(CV_TIER, tier)
end

-----------------------------------
-- NPC menus
-----------------------------------
local hubMenu = { title = '', options = {} }

local buildSealsMain         -- Seals NPC top menu (tier + seals shop)
local buildAccessoriesMain   -- Accessories NPC top menu (lists non-seal categories)
local buildTierInfoMenu
local buildUnlockMenu
local buildCategoryMenu
local buildItemPreviewMenu

-- Find the index of a named reward category in the catalog. Returns nil if
-- absent. Used by buildSealsMain to jump directly into the "Seals" shop.
local function findCategoryIdx(label)
    for i, cat in ipairs(catalog.rewardCategories) do
        if cat.label == label then return i end
    end
    return nil
end

-- Lazy-cached lookup; the catalog's category order is fixed at module load.
local SEALS_CAT_IDX = nil
local function getSealsCatIdx()
    if SEALS_CAT_IDX == nil then
        SEALS_CAT_IDX = findCategoryIdx('Seals') or false   -- false sentinel
    end
    return SEALS_CAT_IDX or nil
end

-- Returns true if a given category index is the Seals category. Used by
-- buildCategoryMenu's "<< Back" to route to the right NPC's main menu.
local function isSealsCat(catIdx)
    return getSealsCatIdx() == catIdx
end

-----------------------------------
-- SEALS NPC main menu
--   At the old Hub position. Owns tier-info + unlock-next-tier + the
--   single-category Seals shop. Title shows tier + mark balance.
-----------------------------------
buildSealsMain = function(player)
    local pts      = getPoints(player)
    local tier     = getTier(player)
    local tierName = catalog.tiers[tier].name

    local unlockLabel
    if tier < MAX_TIER then
        local cost = catalog.tiers[tier + 1].unlockCost
        unlockLabel = string.format('Unlock Next Tier  [%d/%d]', pts, cost)
    else
        unlockLabel = 'Max Tier Reached'
    end

    -- Currency name only in the title; option labels stay short.
    hubMenu.title   = string.format('Hunt Seals [%s] %d %s', tierName, pts, catalog.currencyName)
    hubMenu.options =
    {
        {
            string.format('View Tier Info  [%s]', tierName),
            function(playerArg) buildTierInfoMenu(playerArg) end,
        },
        {
            unlockLabel,
            function(playerArg)
                if getTier(playerArg) < MAX_TIER then
                    buildUnlockMenu(playerArg)
                else
                    playerArg:printToPlayer('You have reached the highest rank, kupo!', xi.msg.channel.SYSTEM_3)
                    buildSealsMain(playerArg)
                end
            end,
        },
        {
            'Buy Seals',
            function(playerArg)
                local idx = getSealsCatIdx()
                if idx then
                    buildCategoryMenu(playerArg, idx, 1)
                else
                    playerArg:printToPlayer('No "Seals" category found in catalog, kupo!', xi.msg.channel.SYSTEM_3)
                    buildSealsMain(playerArg)
                end
            end,
        },
        {
            'Close',
            function(playerArg)
                playerArg:printToPlayer('Hunt well, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        },
    }
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- ACCESSORIES NPC main menu
--   Lists every reward category EXCEPT Seals (which belongs to the
--   Seals NPC). Same UX as the old "Reward Shop" category picker.
-----------------------------------
buildAccessoriesMain = function(player)
    local pts     = getPoints(player)
    local cats    = catalog.rewardCategories
    local options = {}

    for i, cat in ipairs(cats) do
        if cat.label ~= 'Seals' then
            local ci = i
            table.insert(options, {
                cat.label,
                function(playerArg) buildCategoryMenu(playerArg, ci, 1) end,
            })
        end
    end

    table.insert(options, {
        'Close',
        function(playerArg)
            playerArg:printToPlayer('Spend wisely, kupo!', xi.msg.channel.SYSTEM_3)
        end,
    })

    hubMenu.title   = string.format('Hunt Accessories [%d %s]', pts, catalog.currencyName)
    hubMenu.options = options
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

buildTierInfoMenu = function(player)
    local tier    = getTier(player)
    local tierDef = catalog.tiers[tier]
    local options = {}

    -- Drop the padding (%-26s) and the per-row currency name; keep it compact
    -- so the 150-byte customMenu cap is respected when a tier has 3+ mobs.
    for _, mob in ipairs(tierDef.mobs) do
        table.insert(options, {
            string.format('%s  +%d', mob.label, mob.points),
            function(playerArg) buildTierInfoMenu(playerArg) end,
        })
    end

    if tier < MAX_TIER then
        local next = catalog.tiers[tier + 1]
        table.insert(options, {
            string.format('[Next] %s  cost %d', next.name, next.unlockCost),
            function(playerArg) buildTierInfoMenu(playerArg) end,
        })
    end

    table.insert(options, { '<< Back', function(playerArg) buildSealsMain(playerArg) end })

    hubMenu.title   = string.format('[%s] NM List (+%s)', tierDef.name, catalog.currencyName)
    hubMenu.options = options
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

buildUnlockMenu = function(player)
    local tier    = getTier(player)
    local pts     = getPoints(player)
    local nextIdx = tier + 1
    local nextDef = catalog.tiers[nextIdx]
    local cost    = nextDef.unlockCost
    local options = {}

    if pts >= cost then
        table.insert(options, {
            -- Keep this label SHORT: the customMenu click round-trip (Mes[128])
            -- is title + this label + player name + boilerplate. Repeating the
            -- rank name here pushed long-named players (e.g. Duffaluffagus) over
            -- 128 bytes on the Rank IV unlock, killing the button. Cost only.
            string.format('Yes - pay %d %s', cost, catalog.currencyName),
            function(playerArg)
                spendPoints(playerArg, cost)
                setTier(playerArg, nextIdx)
                playerArg:printToPlayer(
                    string.format('%s unlocked!  %d %s remaining, kupo!',
                        nextDef.name, getPoints(playerArg), catalog.currencyName),
                    xi.msg.channel.SYSTEM_3
                )
                -- Server-wide tier promotion announcement.
                local broadcastMsg = string.format(
                    '[Hunting League] \xe2\x98\x85 %s has advanced to %s!  Congratulations!',
                    playerArg:getName(), nextDef.name)
                playerArg:printToArea(broadcastMsg,
                    xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
                buildSealsMain(playerArg)
            end,
        })
    else
        table.insert(options, {
            string.format('Not enough  [%d / %d]', pts, cost),
            function(playerArg) buildSealsMain(playerArg) end,
        })
    end

    table.insert(options, { '<< Back', function(playerArg) buildSealsMain(playerArg) end })

    -- Title drops the redundant cost (it's in the Yes label) to keep the
    -- click round-trip under the 128-byte customMenu cap for long player names.
    hubMenu.title   = string.format('Unlock %s?', nextDef.name)
    hubMenu.options = options
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-- (the old buildShopCategoryMenu was removed when the Hub was split into
--  the Seals + Accessories NPCs; each NPC's main menu now lists exactly
--  the categories that belong to it.)

-----------------------------------
-- buildCategoryMenu  (catIdx = index into rewardCategories, page = item page)
-- Second level: lists items in the chosen category, SHOP_PG_SZ per page.
--
-- Labels show item name only (no cost) - cost is shown in the preview title
-- when the player clicks an item.  This keeps each row <= 15 chars so 6 items
-- fit per page within the 150-byte customMenu cap:
--   title "Earrings [250M] 1/1" (21) + 6x16 + navx3x9 ~ 141 bytes ✓
-----------------------------------
buildCategoryMenu = function(player, catIdx, page)
    local pts   = getPoints(player)
    local cat   = catalog.rewardCategories[catIdx]
    local items = cat.items

    local nPages = math.max(1, math.ceil(#items / SHOP_PG_SZ))
    page = math.max(1, math.min(page, nPages))

    local startIdx = (page - 1) * SHOP_PG_SZ + 1
    local endIdx   = math.min(startIdx + SHOP_PG_SZ - 1, #items)
    local options  = {}

    for i = startIdx, endIdx do
        local r = items[i]
        local rname = r.name
        if #rname > MAX_ITEM_NAME then
            rname = rname:sub(1, MAX_ITEM_NAME - 1) .. '*'
        end
        table.insert(options, {
            rname,
            function(playerArg)
                buildItemPreviewMenu(playerArg, r, catIdx, page)
            end,
        })
    end

    if page > 1 then
        table.insert(options, {
            string.format('<< %d/%d', page - 1, nPages),
            function(playerArg) buildCategoryMenu(playerArg, catIdx, page - 1) end,
        })
    end
    if page < nPages then
        table.insert(options, {
            string.format('%d/%d >>', page + 1, nPages),
            function(playerArg) buildCategoryMenu(playerArg, catIdx, page + 1) end,
        })
    end
    -- Back routes to whichever NPC owns this category:
    --   Seals  category   -> Seals NPC main menu
    --   Anything else     -> Accessories NPC main menu
    table.insert(options, { '<< Back',
        function(playerArg)
            if isSealsCat(catIdx) then
                buildSealsMain(playerArg)
            else
                buildAccessoriesMain(playerArg)
            end
        end })

    -- Compact title: slot + balance + page indicator.
    -- "Earrings [250M] 1/1" = 21 chars - leaves comfortable room for 6 item rows.
    hubMenu.title   = string.format('%s [%dM] %d/%d', cat.label, pts, page, nPages)
    hubMenu.options = options
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- buildItemPreviewMenu
-- Third level: shows stat lines for the selected item + Buy / Back.
-- catIdx / itemPage are used so "Back" returns to the right category page.
--
-- Byte budget: title + each option label (NUL-terminated) <= 150 bytes.
-- Up to 4 stat lines (~20 chars) + Buy/Need + Back ~ 120 bytes - safe.
-----------------------------------
-- Per-purchase stack cap. FFXI items stack to 99 per inventory slot;
-- exceeding this in a single addItem call would either split into a new
-- slot (taking extra inventory space) or silently drop the overflow. So
-- we cap a single "buy max" click at one full stack and let the player
-- click again if they want more.
local SEAL_STACK_CAP = 99

-- Shared purchase routine - used by both the single-buy path (non-seal
-- items) and the multi-quantity path (seals). Handles the inventory
-- check, mark deduction, item grant, and chat confirmation in one place.
local function doBuyReward(p, reward, qty, catIdx, itemPage)
    -- Spell rewards TEACH the spell (addSpell) instead of granting an item.
    -- The custom scroll item ids (29696-29698) aren't in the client's item
    -- data, so a usable scroll never shows a "Use" option -- a player could
    -- never learn it that way. addSpell is job-agnostic (the spell only shows
    -- when on a job that can cast it), so it's safe to learn on any job; cast
    -- it on the job listed in the reward's stats. No inventory slot needed.
    if reward.learnSpell then
        if p:hasSpell(reward.learnSpell) then
            p:printToPlayer(
                string.format('[Hunting League] You already know %s, kupo!', reward.name),
                xi.msg.channel.SYSTEM_3)
            buildCategoryMenu(p, catIdx, itemPage)
            return
        end
        spendPoints(p, reward.cost)
        p:addSpell(reward.learnSpell)
        p:printToPlayer(
            string.format('[Hunting League] Learned %s for %d %s!  (%d remaining), kupo! Cast it on the listed job.',
                reward.name, reward.cost, catalog.currencyName, getPoints(p)),
            xi.msg.channel.SYSTEM_3)
        buildCategoryMenu(p, catIdx, itemPage)
        return
    end

    local totalCost = reward.cost * qty
    local added = p:addItem({ id = reward.id, quantity = qty })
    if not added then
        p:printToPlayer('Inventory full! Free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
        buildItemPreviewMenu(p, reward, catIdx, itemPage)
        return
    end
    spendPoints(p, totalCost)
    if qty == 1 then
        p:printToPlayer(
            string.format('[Hunting League] Purchased %s for %d %s!  (%d remaining), kupo!',
                reward.name, totalCost, catalog.currencyName, getPoints(p)),
            xi.msg.channel.SYSTEM_3
        )
    else
        p:printToPlayer(
            string.format('[Hunting League] Purchased %d x %s for %d %s!  (%d remaining), kupo!',
                qty, reward.name, totalCost, catalog.currencyName, getPoints(p)),
            xi.msg.channel.SYSTEM_3
        )
    end
    buildCategoryMenu(p, catIdx, itemPage)
end

buildItemPreviewMenu = function(player, reward, catIdx, itemPage)
    local pts     = getPoints(player)
    local options = {}

    -- Stat lines - clicking any stat line re-shows the preview (no-op).
    for _, line in ipairs(reward.stats or { '(no stat data)' }) do
        table.insert(options, {
            line,
            function(p) buildItemPreviewMenu(p, reward, catIdx, itemPage) end,
        })
    end

    -- Seals category gets a multi-quantity buy menu (1 / 10 / max). Every
    -- other category is single-purchase only because they're discrete gear
    -- pieces - you only ever need one Brutal Earring.
    local maxAffordable = math.floor(pts / reward.cost)
    if isSealsCat(catIdx) then
        if maxAffordable < 1 then
            table.insert(options, {
                string.format('Need %d  (have %d)', reward.cost, pts),
                function(p) buildItemPreviewMenu(p, reward, catIdx, itemPage) end,
            })
        else
            -- Buy 1 - always available if you can afford one.
            table.insert(options, {
                string.format('Buy 1  [%d]', reward.cost),
                function(p) doBuyReward(p, reward, 1, catIdx, itemPage) end,
            })
            -- Buy 10 - only shown if affordable, and only if it would
            -- actually be a distinct amount from "Buy max" below.
            if maxAffordable >= 10 and maxAffordable > 10 then
                table.insert(options, {
                    string.format('Buy 10  [%d]', reward.cost * 10),
                    function(p) doBuyReward(p, reward, 10, catIdx, itemPage) end,
                })
            end
            -- Buy max - capped at one full stack per click so we never
            -- silently spill into a second inventory slot.
            if maxAffordable > 1 then
                local cappedMax = math.min(maxAffordable, SEAL_STACK_CAP)
                table.insert(options, {
                    string.format('Buy %d  [%d]', cappedMax, reward.cost * cappedMax),
                    function(p) doBuyReward(p, reward, cappedMax, catIdx, itemPage) end,
                })
            end
        end
    else
        -- Non-seal: original single-buy UX.
        if pts >= reward.cost then
            table.insert(options, {
                string.format('Buy  [%d / %d marks]', pts, reward.cost),
                function(p) doBuyReward(p, reward, 1, catIdx, itemPage) end,
            })
        else
            table.insert(options, {
                string.format('Need %d  (have %d)', reward.cost, pts),
                function(p) buildItemPreviewMenu(p, reward, catIdx, itemPage) end,
            })
        end
    end

    table.insert(options, { '<< Back', function(p) buildCategoryMenu(p, catIdx, itemPage) end })

    hubMenu.title   = string.format('[%s]  %d %s', reward.name, reward.cost, catalog.currencyName)
    hubMenu.options = options
    local snapshot = { title = hubMenu.title, options = hubMenu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Spawner NPC builder
-- Uses insertDynamicEntity(objtype=MOB) to create real CMobEntity instances
-- on demand.  No mob_spawn_points rows are required - only mob_groups.
-- Kill detection is wired inline via each mob's onMobDeath table field.
-----------------------------------
local function insertSpawnerNPC(zone)
    -- Each tier has its own spawner NPC placed at the tier's cluster area.
    -- Each NPC opens directly to its own mob list; no tier-picker needed.
    local mobMenu = { title = '', options = {} }

    local function buildMobMenu(player, tierNum)
        local tierDef = catalog.tiers[tierNum]
        if not tierDef then
            return
        end
        local options = {}

        for _, mobDef in ipairs(tierDef.mobs) do
            local md = mobDef
            local td = tierDef  -- capture for the onMobDeath closure
            local backHere = function(p) buildMobMenu(p, tierNum) end

            table.insert(options, {
                string.format('Spawn %s  (+%d)', md.label, md.points),
                function(playerArg)
                    local z = playerArg:getZone()

                    -- Guard: don't stack duplicates if already alive.
                    local existing = z:queryEntitiesByName(md.name)
                    if existing then
                        for _, e in ipairs(existing) do
                            if e:getHP() > 0 then
                                playerArg:printToPlayer(
                                    string.format('%s is already up, kupo!', md.label),
                                    xi.msg.channel.SYSTEM_3
                                )
                                backHere(playerArg)
                                return
                            end
                        end
                    end

                    local mPos = md.spawnPos or catalog.mobSpawnPos
                    -- Record spawn time so Speed Demon (kill within 60s
                    -- of spawn) objectives can compute secondsToKill.
                    -- Captured by the onMobDeath closure below.
                    local spawnedAt = os.time()
                    local mob  = z:insertDynamicEntity({
                        objtype              = xi.objType.MOB,
                        groupId              = md.groupId,
                        groupZoneId          = catalog.huntZoneId,
                        name                 = md.name,
                        x                    = mPos.x,
                        y                    = mPos.y,
                        z                    = mPos.z,
                        rotation             = mPos.rot,
                        -- REQUIRED: without these, GenerateDynamicEntity defaults the
                        -- mob to level 255 and players can't land hits on it. The
                        -- engine also logs an error per spawn ("No minLevel set").
                        minLevel             = md.minLv,
                        maxLevel             = md.maxLv,
                        -- Detection bitfield from xi.detects. Without this, the
                        -- engine logs "has no detection methods!" per spawn AND
                        -- the mob never auto-aggros. SIGHT_AND_HEARING (0x003)
                        -- is the standard aggressive-mob config. Custom field
                        -- read in src/map/lua/luautils.cpp insertDynamicEntity.
                        detection            = xi.detects.SIGHT_AND_HEARING,
                        isAggroable          = true,
                        releaseIdOnDisappear = true,

                        -- Idle despawn: an un-engaged NM cleans itself up after
                        -- DESPAWN_SECS so an ignored/accidental pop (or one that's
                        -- tagged then abandoned) doesn't clog the arena or block a
                        -- re-pop behind the dup-spawn guard. State machine on the
                        -- HL_DespawnAt localVar (absolute os.time deadline):
                        --   * stamped after spawn() below   (initial countdown)
                        --   * onMobEngage    -> 0            (fighting; no despawn)
                        --   * onMobDisengage -> re-armed     (abandoned; count again)
                        --   * onMobRoam      -> despawns once past the deadline
                        -- onMobRoam fires only while alive AND un-engaged, so it
                        -- can never interrupt an active fight.
                        onMobEngage = function(engagedMob)
                            engagedMob:setLocalVar('HL_DespawnAt', 0)
                        end,

                        onMobDisengage = function(disMob)
                            if DESPAWN_SECS > 0 then
                                disMob:setLocalVar('HL_DespawnAt', os.time() + DESPAWN_SECS)
                            end
                        end,

                        onMobRoam = function(roamMob)
                            local deadline = roamMob:getLocalVar('HL_DespawnAt')
                            if deadline > 0 and os.time() >= deadline then
                                -- Idle despawn uses DespawnMob (no onMobDeath), so free
                                -- the mechanics state here too (idempotent; pcall-safe).
                                mechanics.cleanup(roamMob)
                                DespawnMob(roamMob:getID())
                            end
                        end,

                        onMobFight = function(mfMob, mfTarget)
                            mechanics.tick(mfMob, mfTarget)
                        end,

                        onMobDeath = function(deadMob, killer, optParams)
                            mechanics.cleanup(deadMob)
                            if not killer then return end
                            local playerTier = getTier(killer)
                            if playerTier < td.tier then
                                killer:printToPlayer(
                                    string.format('[Hunting League] Unlock %s to earn marks from %s, kupo!',
                                        td.name, md.label),
                                    xi.msg.channel.SYSTEM_3
                                )
                                return
                            end

                            -- Prime Voucher: the Prime Weapon TRIAL 3 turn-in
                            -- (the Maze Monger Crown, item 3038). ~1% drop from any Hunting League NM;
                            -- only drops while the player still needs it, so it
                            -- never clutters once Trial 3 is done. Also grantable
                            -- via !primevoucher. pcall-guarded so a reward error
                            -- can never break the mark-award logic below.
                            pcall(function()
                                if (killer:getCharVar('PW_Trial3_Done') or 0) == 0
                                    and math.random(100) <= 1
                                then
                                    require('modules/custom/lua/prime_voucher_reward').award(killer, 1, 'Hunting League')
                                end
                            end)

                            -- Hunter's Guild integration (v2):
                            --   * marks awarded use the AMPLIFIED value, factoring
                            --     in League guild rank + Apex capstone bonus.
                            --   * rep is NO LONGER bumped here. Under the v2
                            --     design (2026-05-29), League Hunters' rep comes
                            --     only from killing the dedicated vanilla HNMs
                            --     listed in catalog.huntTargets.hl (Bune,
                            --     Carmine Dobsonfly, Aspidochelone, Behemoth,
                            --     Jormungand) - see hunters_guild_hunts.lua.
                            -- Lifetime counter uses the BASE value too - it's a
                            -- raw "how much did you grind" stat, not "how much
                            -- did you bank with bonuses".
                            local baseMarks  = md.points
                            local finalMarks = hg.applyAmplifier(killer, 'hl', baseMarks)
                            finalMarks       = se.applyBonus(killer, finalMarks)
                            local bonus      = finalMarks - baseMarks
                            addPoints(killer, finalMarks)
                            -- Lifetime mark counter (never decreases when marks
                            -- are spent). Drives the "Marks Earned (Lifetime)"
                            -- leaderboard.
                            killer:setCharVar('HL_Points_Lifetime',
                                (killer:getCharVar('HL_Points_Lifetime') or 0) + baseMarks)
                            -- Global "any custom NM" counter shared with Reforge_System.
                            -- Drives the "Top NM Slayers" docs leaderboard so HL and
                            -- Reforge kills accumulate to the same total.
                            killer:setCharVar('Custom_NM_Kills',
                                (killer:getCharVar('Custom_NM_Kills') or 0) + 1)

                            -- First-kill bonus: award extra marks the very first
                            -- time this player defeats this specific NM.  Creates
                            -- a "new NM!" moment for every unique hunt they tackle.
                            local isFirstKill = (killer:getCharVar('NMKilled_' .. md.groupId) or 0) == 0
                            if isFirstKill then
                                local firstBonus = baseMarks
                                addPoints(killer, firstBonus)
                                killer:printToPlayer(
                                    string.format('[Hunting League] *** FIRST KILL: %s! +%d bonus marks! ***',
                                        md.label, firstBonus),
                                    xi.msg.channel.SYSTEM_3
                                )
                            end

                            -- Weekly Featured Hunt: one NM per tier rotates each
                            -- ISO week.  First kill of the featured NM that week
                            -- awards 2x base marks as a bonus on top of the
                            -- regular reward (stacks with First-Kill bonus).
                            -- Week index: seconds-since-epoch / 604800 (7 days).
                            local weekIdx = math.floor(os.time() / 604800)
                            local tierMobs = td.mobs
                            local featIdx  = (weekIdx % #tierMobs) + 1
                            local featMob  = tierMobs[featIdx]
                            if featMob and md.groupId == featMob.groupId then
                                local weekVar = string.format('HL_Featured_%d_%d', weekIdx, md.groupId)
                                if (killer:getCharVar(weekVar) or 0) == 0 then
                                    local featBonus = baseMarks * 2
                                    addPoints(killer, featBonus)
                                    killer:setCharVar(weekVar, 1)
                                    killer:printToPlayer(
                                        string.format('[Hunting League] *** FEATURED HUNT this week: %s! +%d bonus marks! ***',
                                            md.label, featBonus),
                                        xi.msg.channel.SYSTEM_3
                                    )
                                end
                            end

                            -- Party bonus: extra marks when hunting with others.
                            -- Goes to the killing-blow player only.
                            -- 2-3 party members = +25% base marks; 4+ = +50%.
                            do
                                local ps = killer:getPartySize() or 1
                                local pb = 0
                                if ps >= 4 then
                                    pb = math.floor(baseMarks * 0.50)
                                elseif ps >= 2 then
                                    pb = math.floor(baseMarks * 0.25)
                                end
                                if pb > 0 then
                                    addPoints(killer, pb)
                                    killer:printToPlayer(
                                        string.format('[Hunting League] Party bonus (%d players): +%d marks!', ps, pb),
                                        xi.msg.channel.SYSTEM_3)
                                end
                            end

                            -- Kill streak bonus: consecutive kills within 5 minutes
                            -- earn escalating bonus marks.
                            -- 3 kills = +10% | 5 kills = +20% | 10+ kills = +50%
                            do
                                local now    = os.time()
                                local last   = killer:getCharVar('HL_Streak_LastKill') or 0
                                local streak = killer:getCharVar('HL_Streak_Count')    or 0
                                if now - last <= 300 then
                                    streak = streak + 1
                                else
                                    streak = 1  -- gap > 5 min resets streak
                                end
                                killer:setCharVar('HL_Streak_LastKill', now)
                                killer:setCharVar('HL_Streak_Count',    streak)
                                local mult = 0
                                if     streak >= 10 then mult = 0.50
                                elseif streak >=  5 then mult = 0.20
                                elseif streak >=  3 then mult = 0.10
                                end
                                if mult > 0 then
                                    local sb = math.floor(baseMarks * mult)
                                    addPoints(killer, sb)
                                    killer:printToPlayer(
                                        string.format('[Hunting League] x%d kill streak! +%d bonus marks!', streak, sb),
                                        xi.msg.channel.SYSTEM_3)
                                end
                            end

                            -- Distinct-NM stamp. One CharVar per groupId killed.
                            -- The "NM Encyclopedia" leaderboard counts these via
                            -- a LIKE pattern, so each unique kill is +1 toward
                            -- the completionist score.
                            killer:setCharVar('NMKilled_' .. md.groupId, 1)
                            -- Speed-board anchors: first HL kill (any tier) and
                            -- first Rank V kill. setIfUnset semantics - only the
                            -- earliest timestamp wins. os.time() returns the
                            -- current Unix epoch in seconds.
                            if (killer:getCharVar('HL_FirstKill_At') or 0) == 0 then
                                killer:setCharVar('HL_FirstKill_At', os.time())
                            end
                            if td.tier >= 5 and (killer:getCharVar('HL_RankVKill_At') or 0) == 0 then
                                killer:setCharVar('HL_RankVKill_At', os.time())
                            end
                            -- Award message shows base + bonus split so the
                            -- player can see the Guild amplifier working.
                            if bonus > 0 then
                                killer:printToPlayer(
                                    string.format('[Hunting League] %s defeated!  +%d %s  (base %d + guild bonus %d)  (Total: %d), kupo!',
                                        md.label, finalMarks, catalog.currencyName,
                                        baseMarks, bonus, getPoints(killer)),
                                    xi.msg.channel.SYSTEM_3
                                )
                            else
                                killer:printToPlayer(
                                    string.format('[Hunting League] %s defeated!  +%d %s  (Total: %d), kupo!',
                                        md.label, finalMarks,
                                        catalog.currencyName, getPoints(killer)),
                                    xi.msg.channel.SYSTEM_3
                                )
                            end

                            -- Weekly Hunt Board: fire an nm_kill event so any
                            -- active objective listening for kills (NM Slayer,
                            -- Apex Hunter, League Devotee, Climbing Force,
                            -- Pack Hunter, Speed Demon, Untouchable) gets
                            -- credit. Metadata covers system / tier / level /
                            -- party size / kill speed so each matcher has
                            -- everything it needs.
                            wh.fire(killer, 'nm_kill', {
                                system        = 'hl',
                                tier          = td.tier,
                                level         = md.minLv or 0,
                                partySize     = killer:getPartySize() or 1,
                                secondsToKill = os.time() - spawnedAt,
                            })

                            -- Personal achievement milestones (first kills,
                            -- kill-count thresholds, lifetime mark thresholds).
                            ach.onHLKill(killer, td.tier)

                            -- Treasure Hunting map roll. Lazy + guarded
                            -- so hunts never break if the module is out.
                            local okTh, th = pcall(require, 'modules/custom/lua/TreasureHunt')
                            if okTh and th and th.onHuntKill then
                                pcall(function() th.onHuntKill(killer, td.tier) end)
                            end

                            -- Ascension Trial: a Tier-5 (Legend) kill stamps
                            -- progress toward the next ascension. The module
                            -- ignores groupIds that aren't on the Trial roster.
                            if td.tier >= 5 then
                                prestige.onLegendKill(killer, md.groupId)
                            end

                            -- Catalog-defined trophy drops. Guaranteed unless
                            -- `rate` (1-100) is specified on the drop entry.
                            if md.drops then
                                for _, drop in ipairs(md.drops) do
                                    local rate = drop.rate or 100
                                    if math.random(100) <= rate then
                                        killer:addItem({ id = drop.id, quantity = drop.qty or 1 })
                                        killer:printToPlayer(
                                            string.format('[Hunting League] Trophy drop from %s!', md.label),
                                            xi.msg.channel.SYSTEM_3)
                                    end
                                end
                            end
                        end,
                    })

                    if not mob then
                        playerArg:printToPlayer(
                            string.format('Failed to spawn %s (groupId %d missing?), kupo!',
                                md.label, md.groupId),
                            xi.msg.channel.SYSTEM_3
                        )
                        backHere(playerArg)
                        return
                    end

                    mob:setSpawn(mPos.x, mPos.y, mPos.z, mPos.rot)
                    mob:spawn()

                    -- Arm the un-engaged despawn (absolute deadline). onMobRoam
                    -- removes the NM if it's still un-engaged past this time;
                    -- onMobEngage clears it. Stamped after spawn() so the stat
                    -- recalculation spawn() performs can't wipe it.
                    if DESPAWN_SECS > 0 then
                        mob:setLocalVar('HL_DespawnAt', os.time() + DESPAWN_SECS)
                    end

                    -- Capacity/Job Points are INTENTIONALLY enabled on HL NMs
                    -- (2026-06-14). They are single-target pops, so the engine's
                    -- level-scaled CP (x EXP_RATE*CAPACITY_RATE, currently ~x9;
                    -- 30,000 CP per Job Point) is a deliberate, difficulty-scaled
                    -- JP source. Previously suppressed via NO_CAPACITY_POINTS=1 --
                    -- removed; that was tuned for an old 10x world and zeroed ALL
                    -- JP. Multi-mob wave/add systems still set the flag.

                    -- Apply stat mods AFTER spawn().
                    -- spawn() recalculates stats from the pool, so anything set
                    -- before it gets wiped. Mods applied here persist correctly.
                    -- hp is handled separately via xi.mobMod.HP_BOOST (percent).
                    if md.mods then
                        for modId, value in pairs(md.mods) do
                            mob:setMod(modId, value)
                        end
                    end

                    -- HP scaling: catalog field hpBoost = multiplier (e.g. 10 = 10x HP).
                    -- setMaxHP() directly writes health.maxhp and calls UpdateHealth().
                    -- setHP() then fills current HP up to the new maximum.
                    if md.hpBoost then
                        local newMax = mob:getMaxHP() * md.hpBoost
                        mob:setMaxHP(newMax)
                        mob:setHP(newMax)
                    end

                    -- Spawn the NM already aggroed onto the player who popped it,
                    -- so it engages immediately instead of idling at the pop point
                    -- (same pattern as the Abyssea marks pop). Claims it for the
                    -- spawner; the resulting onMobEngage also clears the un-engaged
                    -- despawn timer set above.
                    mob:updateClaim(playerArg)
                    mob:updateEnmity(playerArg)

                    -- Attach hardcore mechanics AFTER spawn() + stat/HP setup +
                    -- claim so the library records the correct starting HP.
                    -- catalog.mechCfgs is keyed by groupId; a missing entry is a
                    -- no-op (library returns immediately on nil cfg).
                    mechanics.attach(mob, catalog.mechCfgs and catalog.mechCfgs[md.groupId])

                    playerArg:printToPlayer(
                        string.format('%s has appeared!  Slay it for %d %s, kupo!',
                            md.label, md.points, catalog.currencyName),
                        xi.msg.channel.SYSTEM_3
                    )
                    backHere(playerArg)
                end,
            })
        end -- for _, mobDef

        table.insert(options, {
            'Close',
            function(playerArg)
                playerArg:printToPlayer('Good hunting, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        })

        local pts       = getPoints(player)
        mobMenu.title   = string.format('[%s]  %d %s', tierDef.name, pts, catalog.currencyName)
        mobMenu.options = options
        player:timer(30, function(p) p:customMenu(mobMenu) end)
    end

    -- One spawner NPC per tier, placed at each tier's cluster area.
    -- Each NPC only shows mobs for its own tier - no tier-picker needed.
    for _, tierDef in ipairs(catalog.tiers) do
        local td     = tierDef
        local pos    = td.spawnerPos or catalog.spawnerPos
        local suffix = td.name:match('%-%s*(.+)$') or td.name
        local Spawner = zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = string.format('HuntingLeague_Spawner_T%d', td.tier),
            packetName = string.format('%sR%d: %s', xi.icon.STAR_LARGE, td.tier, suffix),
            look       = 2430,
            x          = pos.x,
            y          = pos.y,
            z          = pos.z,
            rotation   = pos.rot,
            widescan   = 1,

            onTrade = function(player, npc, trade)
                player:printToPlayer('No trades, kupo!', xi.msg.channel.SYSTEM_3)
            end,

            onTrigger = function(player, npc)
                player:timer(50, function(p)
                    if getTier(p) < td.tier then
                        p:printToPlayer(
                            string.format('[Hunting League] Unlock %s to use this spawner, kupo!', td.name),
                            xi.msg.channel.SYSTEM_3
                        )
                        return
                    end
                    buildMobMenu(p, td.tier)
                end)
            end,
        })
        utils.unused(Spawner)
    end
end

-----------------------------------
-- Zone Guide NPC
-- Hub NPC that offers a one-click teleport to any of the five tier cluster
-- areas so players never have to run across the zone.
-----------------------------------
local function insertZoneGuideNPC(zone)
    local menu = { title = 'Hunting Grounds', options = {} }

    local function buildMenu(player)
        local options = {}
        for _, tierDef in ipairs(catalog.tiers) do
            local td     = tierDef
            local wp     = td.warpPos or td.spawnerPos or catalog.spawnerPos
            local suffix = td.name:match('%-%s*(.+)$') or td.name
            table.insert(options, {
                string.format('R%d: %s', td.tier, suffix),
                function(playerArg)
                    playerArg:timer(100, function(p)
                        p:setPos(wp.x, wp.y, wp.z, wp.rot or 0, xi.zone.ESCHA_ZITAH)
                    end)
                end,
            })
        end
        table.insert(options, {
            'Close',
            function(playerArg)
                playerArg:printToPlayer('Safe travels, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        })
        menu.options = options
        player:timer(30, function(p) p:customMenu(menu) end)
    end

    local pos      = catalog.zoneGuidePos
    local GuideNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'HuntingLeague_ZoneGuide',
        packetName = string.format('%sZone Guide', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(p) buildMenu(p) end)
        end,
    })
    utils.unused(GuideNPC)
end

-----------------------------------
-- Hunt zone override
-- Places two hub NPCs (Seals, Accessories) and a Zone Guide NPC at the
-- zone-in area, plus five tier-specific spawner NPCs spread across the zone.
-- Weapons + Armor NPCs are registered by their own module files.
-----------------------------------
m:addOverride(catalog.huntZonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -- Seals NPC (replaces the old Hub at its position; !hunt lands here).
    -- Holds tier-info + unlock-next-tier + Seals shop.
    local sPos     = catalog.sealsPos
    local SealsNPC = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'HuntingLeague_Seals',
        packetName = string.format('%sSeals', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = sPos.x,
        y          = sPos.y,
        z          = sPos.z,
        rotation   = sPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(p) buildSealsMain(p) end)
        end,
    })
    utils.unused(SealsNPC)

    -- Accessories NPC (Neck / Earrings / Rings / Back / Waist).
    local aPos     = catalog.accessoriesPos
    local AccNPC   = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'HuntingLeague_Accessories',
        packetName = string.format('%sAccessories', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = aPos.x,
        y          = aPos.y,
        z          = aPos.z,
        rotation   = aPos.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades - use the menu, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(p) buildAccessoriesMain(p) end)
        end,
    })
    utils.unused(AccNPC)

    insertZoneGuideNPC(zone)
    insertSpawnerNPC(zone)
end)

return m
