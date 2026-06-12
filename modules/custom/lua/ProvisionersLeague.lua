-----------------------------------
-- ProvisionersLeague.lua
-- THE PROVISIONERS' LEAGUE: the non-combat league. Two tracks, one
-- ladder:
--
--   FISHING - catch fish anywhere, then WEIGH IN by trading them to
--   the League Steward at Reisenjima Henge. Points are derived from
--   the engine's own fish table (skill level, big, legendary), so
--   every catchable fish in the game scores. A weekly featured fish
--   pays x3 - that's the tournament; weekly score feeds the website
--   leaderboard.
--
--   CRAFTING - every HQ turn-in the Crafting Exchange (GM Home)
--   accepts also credits league points (marks / 10). That hook lives
--   in CraftingExchange_NPC.lua and lazy-requires this module.
--
-- Lifetime points climb 5 ranks (Apprentice -> Legendary Provisioner)
-- with mark bonuses on each rank-up. CharVars:
--   League_Points     lifetime league points (ranks + leaderboard)
--   League_Rank       last rank index awarded (1-5)
--   League_WeekStamp  ISO week of the current weekly score
--   League_WeekScore  points earned this ISO week (tournament board)
--   League_Turnins    count of fish weigh-ins (flavor stat)
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/provisioners_catalog')
require('scripts/globals/hobbies/fishing/data')   -- xi.fishing.catchData
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('provisioners_league')

-----------------------------------
-- Fish points table, derived once at load from the engine data.
-- catchData rows are positional; the fields we read:
--   [1] skillLvl   [8] isBig   [17] isLegendary
-----------------------------------
local fishPoints = {}   -- itemId -> points
local fishIds    = {}   -- sorted ids for deterministic featured pick

do
    local s = catalog.scoring
    for itemId, row in pairs(xi.fishing.catchData or {}) do
        local skill     = row[1] or 1
        local isBig     = row[8] and true or false
        local legendary = row[17] and true or false
        local pts = math.max(1, math.floor(skill / s.skillDivisor))
        if isBig then pts = pts * s.bigMult end
        if legendary then pts = pts * s.legendaryMult end
        fishPoints[itemId] = pts
        fishIds[#fishIds + 1] = itemId
    end
    table.sort(fishIds)
end

-- Reverse xi.item lookup for display names ('GOLD_CARP' -> 'Gold Carp').
-- Built lazily on first use - the enum is large.
local itemNames = nil
local function fishName(itemId)
    if not itemNames then
        itemNames = {}
        for name, id in pairs(xi.item or {}) do
            if type(id) == 'number' and not itemNames[id] then
                itemNames[id] = name
            end
        end
    end
    local raw = itemNames[itemId]
    if not raw then return 'fish #' .. itemId end
    raw = raw:gsub('_%d+$', '')   -- BASTORE_SARDINE_1 -> BASTORE_SARDINE
    raw = raw:gsub('_', ' '):lower():gsub('(%a)([%w]*)', function(a, b)
        return a:upper() .. b
    end)
    return raw
end

-----------------------------------
-- Weekly featured fish (deterministic, Monday 00:00 UTC anchor).
-----------------------------------
local SECONDS_PER_WEEK = 604800
local MONDAY_ANCHOR    = 259200
local function currentIsoWeek()
    return math.floor((os.time() + MONDAY_ANCHOR) / SECONDS_PER_WEEK)
end

local featuredPool = nil
local function getFeaturedFish()
    if not featuredPool then
        featuredPool = {}
        for _, id in ipairs(fishIds) do
            local row = xi.fishing.catchData[id]
            local skill = row[1] or 0
            if not row[17]   -- no legendaries
               and skill >= catalog.featured.minSkill
               and skill <= catalog.featured.maxSkill then
                featuredPool[#featuredPool + 1] = id
            end
        end
    end
    if #featuredPool == 0 then return nil end
    return featuredPool[(currentIsoWeek() % #featuredPool) + 1]
end

-----------------------------------
-- Rank helpers
-----------------------------------
local function rankForPoints(points)
    local rank = 1
    for i, r in ipairs(catalog.ranks) do
        if points >= r.points then rank = i end
    end
    return rank
end

local function rankLabel(idx)
    local r = catalog.ranks[math.max(1, math.min(idx, #catalog.ranks))]
    return r and r.label or 'Provisioner'
end

-----------------------------------
-- The single scoring entry point (fishing weigh-ins AND the crafting
-- hook funnel through here). Handles lifetime points, weekly score,
-- rank-ups, and achievements.
-----------------------------------
local function addLeaguePoints(player, pts, sourceLabel)
    if pts <= 0 then return end

    local before = player:getCharVar('League_Points') or 0
    local after  = before + pts
    player:setCharVar('League_Points', after)

    -- Weekly tournament score (stamp-reset pattern).
    local week = currentIsoWeek()
    if (player:getCharVar('League_WeekStamp') or 0) ~= week then
        player:setCharVar('League_WeekStamp', week)
        player:setCharVar('League_WeekScore', 0)
    end
    local weekScore = (player:getCharVar('League_WeekScore') or 0) + pts
    player:setCharVar('League_WeekScore', weekScore)

    player:printToPlayer(string.format(
        '[League] +%d league points (%s). Lifetime: %d | This week: %d.',
        pts, sourceLabel or 'turn-in', after, weekScore),
        xi.msg.channel.SYSTEM_3)

    -- Rank-up sweep (a big turn-in can cross several thresholds).
    local oldRank = player:getCharVar('League_Rank') or 1
    local newRank = rankForPoints(after)
    if newRank > oldRank then
        player:setCharVar('League_Rank', newRank)
        for r = oldRank + 1, newRank do
            local bonus = catalog.ranks[r].bonusMarks or 0
            if bonus > 0 then
                player:setCharVar('HL_Points',
                    (player:getCharVar('HL_Points') or 0) + bonus)
            end
            player:printToPlayer(string.format(
                '[League] *** RANK UP: %s! +%d marks ***',
                rankLabel(r), bonus), xi.msg.channel.SYSTEM_3)
        end
        local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
        if okAch and ach and ach.onLeagueRank then
            pcall(function() ach.onLeagueRank(player, newRank) end)
        end
    end
end

-- Exported for CraftingExchange_NPC.lua (lazy pcall require there).
m.onCraftTurnIn = function(player, marks)
    local pts = math.max(1, math.floor((marks or 0) / catalog.scoring.craftDivisor))
    addLeaguePoints(player, pts, 'crafting')
end

-----------------------------------
-- The League Steward NPC - weigh-ins by trade, info by trigger.
-----------------------------------
local menu = { title = 'League Steward', options = {} }

m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)
    local steward = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'League_Steward',
        packetName = string.format('%sLeague Steward', xi.icon.STAR_LARGE),
        look       = 3017,
        x = catalog.npcPos.x, y = catalog.npcPos.y, z = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            -- Weigh-in: every slot must be a recognized fish. Mixed
            -- trades are bounced whole so nothing is eaten by mistake.
            local total, fishCount = 0, 0
            local featured = getFeaturedFish()
            local featuredHits = 0

            for slot = 0, 7 do
                local item = trade:getItem(slot)
                if item then
                    local id  = item:getID()
                    local pts = fishPoints[id]
                    if not pts then
                        player:printToPlayer(string.format(
                            '[League] %s is not a fish I can weigh. Fish only, please!',
                            fishName(id)), xi.msg.channel.SYSTEM_3)
                        return
                    end
                    local qty = trade:getSlotQty(slot) or 1
                    if id == featured then
                        pts = pts * catalog.scoring.featuredMult
                        featuredHits = featuredHits + qty
                    end
                    total     = total + pts * qty
                    fishCount = fishCount + qty
                end
            end

            if fishCount == 0 then
                player:printToPlayer('[League] Trade me your catch to weigh it in!',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            -- Consume every slot (all verified fish), then score.
            for slot = 0, 7 do
                if trade:getItem(slot) then
                    trade:confirmSlot(slot)
                end
            end
            trade:confirmTrade()

            player:setCharVar('League_Turnins',
                (player:getCharVar('League_Turnins') or 0) + fishCount)

            if featuredHits > 0 then
                player:printToPlayer(string.format(
                    '[League] %d featured %s in the basket - x%d points!',
                    featuredHits, fishName(featured), catalog.scoring.featuredMult),
                    xi.msg.channel.SYSTEM_3)
            end
            addLeaguePoints(player, total,
                string.format('%d fish weighed', fishCount))

            local okAch, ach = pcall(require, 'modules/custom/lua/achievements')
            if okAch and ach and ach.onLeagueTurnIn then
                pcall(function() ach.onLeagueTurnIn(player) end)
            end
        end,

        onTrigger = function(player, npc)
            local pts      = player:getCharVar('League_Points') or 0
            local rank     = rankForPoints(pts)
            local week     = currentIsoWeek()
            local weekScore = ((player:getCharVar('League_WeekStamp') or 0) == week)
                and (player:getCharVar('League_WeekScore') or 0) or 0
            local featured = getFeaturedFish()

            player:printToPlayer(string.format(
                '[League Steward] %s - %d lifetime points | %d this week.',
                rankLabel(rank), pts, weekScore), xi.msg.channel.SYSTEM_3)

            local options = {
                { 'This week\'s featured fish', function(p)
                    if featured then
                        p:printToPlayer(string.format(
                            '[League] Featured fish: %s - x%d points at the scales this week! (Rotates Monday 00:00 UTC.)',
                            fishName(featured), catalog.scoring.featuredMult),
                            xi.msg.channel.SYSTEM_3)
                    end
                end },
                { 'How the League works', function(p)
                    p:printToPlayer('[League] TRADE me fish to weigh them in - rarer and bigger pays more, the featured fish pays triple. HQ crafts turned in at the Crafting Exchange also score. Climb 5 ranks for mark bonuses; weekly scores hit the website leaderboard.',
                        xi.msg.channel.SYSTEM_3)
                end },
                { 'My next rank', function(p)
                    local myPts  = p:getCharVar('League_Points') or 0
                    local myRank = rankForPoints(myPts)
                    if myRank >= #catalog.ranks then
                        p:printToPlayer('[League] You stand at the summit, Legendary Provisioner.',
                            xi.msg.channel.SYSTEM_3)
                    else
                        local nxt = catalog.ranks[myRank + 1]
                        p:printToPlayer(string.format(
                            '[League] %s at %d points - %d to go (+%d marks on rank-up).',
                            nxt.label, nxt.points, nxt.points - myPts, nxt.bonusMarks),
                            xi.msg.channel.SYSTEM_3)
                    end
                end },
                { 'Close', function(p) end },
            }
            menu.options = options
            local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
            player:timer(50, function(p) p:customMenu(snapshot) end)
        end,
    })
    utils.unused(steward)
end)

return m
