-----------------------------------
-- achievements.lua
-- Personal milestone system: awards every player bonus marks + an
-- in-game announcement when they hit a landmark for the first time.
-- These are PERSONAL achievements (every eligible player earns them),
-- distinct from the server-wide World First announcements.
--
-- Integration:
--   HuntingLeague.lua calls ach.onHLKill(player, tierNum) after kill.
--   Additional hooks can call ach.check(player, milestoneId) directly.
--
-- Adding a new milestone:
--   1. Add an entry to MILESTONES with a unique id (also used as CharVar).
--   2. Implement its condition inside onHLKill (or another hook).
--   3. Ensure the CharVar 'ACH_<id>' is not accidentally set elsewhere.
-----------------------------------
require('modules/module_utils')

local M = {}

-----------------------------------
-- Milestone definitions
-- id         : unique string; CharVar stored as 'ACH_<id>'
-- reward     : Hunt Marks awarded on first completion
-- announce   : true = server-wide broadcast; false = player only
-- title      : label for the announcement / player message
-- desc       : one-line flavour description shown in the award message
-----------------------------------
local MILESTONES = {
    {
        id       = 'FIRST_HUNT',
        reward   = 50,
        announce = false,
        title    = 'First Hunt',
        desc     = 'Your first Hunting League kill - the legend begins.',
    },
    {
        id       = 'TENTH_HUNT',
        reward   = 100,
        announce = false,
        title    = 'Ten Hunts In',
        desc     = 'Veteran of ten hunts.  You know the drill.',
    },
    {
        id        = 'CENTURY',
        reward    = 300,
        announce  = true,
        title     = 'Centennial Hunter',
        desc      = '100 Hunting League kills.  No signs of stopping.',
        titleId   = xi.title.DESERT_HUNTER,
        titleName = 'Desert Hunter',
    },
    {
        id        = 'THOUSAND',
        reward    = 1000,
        announce  = true,
        title     = 'Legendary Slayer',
        desc      = '1,000 NM kills.  You have earned the title.',
        titleId   = xi.title.HERO_AMONG_HEROES,
        titleName = 'Hero Among Heroes',
    },
    {
        id       = 'TIER2_FIRST',
        reward   = 75,
        announce = false,
        title    = 'Tier II Unlocked',
        desc     = 'First kill from the Tier II roster.',
    },
    {
        id       = 'TIER3_FIRST',
        reward   = 150,
        announce = false,
        title    = 'Tier III Unlocked',
        desc     = 'First kill from the Tier III roster.',
    },
    {
        id       = 'TIER4_FIRST',
        reward   = 250,
        announce = false,
        title    = 'Tier IV Unlocked',
        desc     = 'First kill from the Tier IV roster.',
    },
    {
        id        = 'APEX_HUNTER',
        reward    = 500,
        announce  = true,
        title     = 'Apex Hunter',
        desc      = 'First Tier V kill.  These are the hardest NMs on the server.',
        titleId   = xi.title.HYDRA_HEADHUNTER,
        titleName = 'Hydra Headhunter',
    },
    {
        id       = 'MARKS_1K',
        reward   = 200,
        announce = false,
        title    = 'Mark of 1,000',
        desc     = '1,000 Hunt Marks earned over your lifetime.',
    },
    {
        id       = 'MARKS_10K',
        reward   = 500,
        announce = true,
        title    = 'Mark of 10,000',
        desc     = '10,000 lifetime Hunt Marks.  A true devotee.',
    },
    {
        id        = 'MARKS_100K',
        reward    = 2000,
        announce  = true,
        title     = 'Mark of 100,000',
        desc      = '100,000 lifetime Hunt Marks.  An absolute legend.',
        titleId   = xi.title.PARAGON_OF_WARRIOR_EXCELLENCE,
        titleName = 'Paragon of Warrior Excellence',
    },
    -- Dungeon Infamy milestones
    {
        id       = 'INFAMY_500',
        reward   = 100,
        announce = true,
        title    = 'Dungeon Aspirant',
        desc     = '500 lifetime Infamy earned from dungeon clears.',
    },
    {
        id       = 'INFAMY_1K',
        reward   = 250,
        announce = true,
        title    = 'Dungeon Veteran',
        desc     = '1,000 lifetime Infamy.  The dungeons know your name.',
    },
    {
        id       = 'INFAMY_5K',
        reward   = 750,
        announce = true,
        title    = 'Dungeon Overlord',
        desc     = '5,000 lifetime Infamy.  An unstoppable force of destruction.',
    },
}

-- Build a lookup table by id for fast access
local MILESTONE_BY_ID = {}
for _, ms in ipairs(MILESTONES) do
    MILESTONE_BY_ID[ms.id] = ms
end

local CV_POINTS = 'HL_Points'

local function getPoints(player)
    return player:getCharVar(CV_POINTS) or 0
end

local function addPoints(player, amount)
    player:setCharVar(CV_POINTS, getPoints(player) + amount)
end

-----------------------------------
-- Award a milestone to a player (only once per CharVar).
-- Returns true if the milestone was newly awarded.
-----------------------------------
local function award(player, ms)
    local achVar = 'ACH_' .. ms.id
    if (player:getCharVar(achVar) or 0) ~= 0 then
        return false  -- already earned
    end

    player:setCharVar(achVar, os.time())
    addPoints(player, ms.reward)

    -- Grant the in-game title if the milestone has one. player:addTitle()
    -- unlocks it for display without forcing it as active - the player
    -- chooses when to display it with /title.
    if ms.titleId then
        player:addTitle(ms.titleId)
        player:printToPlayer(
            string.format('[Achievement] Title unlocked: "%s" - display it with /title!',
                ms.titleName or 'Unknown'),
            xi.msg.channel.SYSTEM_3)
    end

    local personalMsg = string.format(
        '[Achievement] %s - %s  (+%d marks!)',
        ms.title, ms.desc, ms.reward)
    player:printToPlayer(personalMsg, xi.msg.channel.SYSTEM_3)

    if ms.announce then
        local broadcastMsg = string.format(
            '[Achievement] %s earned "%s"!  %s',
            player:getName(), ms.title, ms.desc)
        player:printToArea(broadcastMsg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', false)
    end

    return true
end

-----------------------------------
-- Called from HuntingLeague.lua onMobDeath after each HL kill.
-- tierNum : 1-5 tier of the NM that was killed
-----------------------------------
function M.onHLKill(player, tierNum)
    local totalKills    = player:getCharVar('Custom_NM_Kills') or 0
    local lifetimeMarks = player:getCharVar('HL_Points_Lifetime') or 0

    -- Kill-count milestones
    if totalKills == 1  then award(player, MILESTONE_BY_ID['FIRST_HUNT'])  end
    if totalKills == 10 then award(player, MILESTONE_BY_ID['TENTH_HUNT'])  end
    if totalKills == 100  then award(player, MILESTONE_BY_ID['CENTURY'])   end
    if totalKills == 1000 then award(player, MILESTONE_BY_ID['THOUSAND'])  end

    -- Tier-first milestones (first kill at each tier)
    if tierNum == 2 then award(player, MILESTONE_BY_ID['TIER2_FIRST']) end
    if tierNum == 3 then award(player, MILESTONE_BY_ID['TIER3_FIRST']) end
    if tierNum == 4 then award(player, MILESTONE_BY_ID['TIER4_FIRST']) end
    if tierNum == 5 then award(player, MILESTONE_BY_ID['APEX_HUNTER']) end

    -- Lifetime mark milestones
    -- (checked after marks are already awarded for this kill)
    if lifetimeMarks >= 1000   and lifetimeMarks - (player:getCharVar('HL_Points_Lifetime_prev') or 0) > 0 then
        award(player, MILESTONE_BY_ID['MARKS_1K'])
    end
    if lifetimeMarks >= 10000  then award(player, MILESTONE_BY_ID['MARKS_10K'])  end
    if lifetimeMarks >= 100000 then award(player, MILESTONE_BY_ID['MARKS_100K']) end
end

-----------------------------------
-- Generic check: call from any hook to test a specific milestone by id.
-- Useful for Dungeon/Reforge hooks in the future.
-----------------------------------
function M.check(player, milestoneId)
    local ms = MILESTONE_BY_ID[milestoneId]
    if ms then
        award(player, ms)
    end
end

-----------------------------------
-- Called from DungeonSystem.lua endDungeon after a successful clear and
-- after Infamy_Lifetime has been updated.
-- Checks the three lifetime Infamy thresholds.
-----------------------------------
function M.onDungeonClear(player)
    local lifetimeInfamy = player:getCharVar('Infamy_Lifetime') or 0
    if lifetimeInfamy >= 500  then award(player, MILESTONE_BY_ID['INFAMY_500']) end
    if lifetimeInfamy >= 1000 then award(player, MILESTONE_BY_ID['INFAMY_1K'])  end
    if lifetimeInfamy >= 5000 then award(player, MILESTONE_BY_ID['INFAMY_5K'])  end
end

-- Exported for the !achievements command so it can iterate milestone metadata
-- without duplicating the list.
M.MILESTONES = MILESTONES

return M
