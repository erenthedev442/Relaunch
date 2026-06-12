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
        announce = true,
        title    = 'Tier III Unlocked',
        desc     = 'First kill from the Tier III roster.',
    },
    {
        id       = 'TIER4_FIRST',
        reward   = 250,
        announce = true,
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
    -- Dungeon clear count milestones
    {
        id       = 'FIRST_DUNGEON',
        reward   = 150,
        announce = false,
        title    = 'First Dungeon Clear',
        desc     = 'Survived your first dungeon run.',
    },
    {
        id       = 'TEN_DUNGEONS',
        reward   = 300,
        announce = true,
        title    = 'Dungeon Diver',
        desc     = '10 lifetime dungeon clears.',
    },
    {
        id       = 'FIFTY_DUNGEONS',
        reward   = 750,
        announce = true,
        -- 'Dungeon Conqueror' since 2026-06-12: was 'Dungeon Veteran', which
        -- collided with INFAMY_1K's label above. Display-only (achievements
        -- key on id), so already-earned progress is unaffected.
        title    = 'Dungeon Conqueror',
        desc     = '50 lifetime dungeon clears.  The dungeons fear you.',
    },
    -- Wave fight milestones
    {
        id       = 'FIRST_WAVE',
        reward   = 100,
        announce = false,
        title    = 'Wave Rider',
        desc     = 'Survived your first wave fight.',
    },
    {
        id       = 'WAVE_FIGHTER',
        reward   = 200,
        announce = true,
        title    = 'Wave Fighter',
        desc     = '10 lifetime wave fights cleared.',
    },
    {
        id       = 'WAVE_LEGEND',
        reward   = 600,
        announce = true,
        title    = 'Wave Legend',
        desc     = '50 lifetime wave fights.  The arena never rests.',
    },
    -- Prestige / Ascension milestones
    {
        id       = 'FIRST_ASCENSION',
        reward   = 500,
        announce = true,
        title    = 'First Ascension',
        desc     = 'Your first Prestige ascension.  The legend grows.',
    },
    {
        id       = 'TEN_ASCENSIONS',
        reward   = 1000,
        announce = true,
        title    = 'Ascending Master',
        desc     = '10 lifetime Prestige ascensions.',
    },
    {
        id       = 'FIFTY_ASCENSIONS',
        reward   = 3000,
        announce  = true,
        title     = 'Eternal Ascendant',
        desc      = '50 lifetime ascensions.  Beyond all mortal limits.',
        titleId   = xi.title.PARAGON_OF_WARRIOR_EXCELLENCE,
        titleName = 'Paragon of Warrior Excellence',
    },
    -- Treasure Hunting milestones
    {
        id       = 'TH_FIRST_CHEST',
        reward   = 100,
        announce = false,
        title    = 'X Marks the Spot',
        desc     = 'Unearthed your first buried strongbox.',
    },
    {
        id       = 'TH_10_CHESTS',
        reward   = 500,
        announce = true,
        title    = 'Master Cartographer',
        desc     = '10 strongboxes unearthed across Vana\'diel.',
    },
    -- Provisioners' League milestones
    {
        id       = 'LEAGUE_FIRST_TURNIN',
        reward   = 50,
        announce = false,
        title    = 'First Weigh-In',
        desc     = 'Your first catch on the League scales.',
    },
    {
        id       = 'LEAGUE_RANK3',
        reward   = 300,
        announce = true,
        title    = 'Expert Provisioner',
        desc     = 'Reached rank 3 of the Provisioners\' League.',
    },
    {
        id       = 'LEAGUE_RANK5',
        reward   = 2000,
        announce = true,
        title    = 'Legendary Provisioner',
        desc     = 'The League\'s summit.  Rods bend and kilns roar at your name.',
    },
    -- Raid milestones
    {
        id        = 'RAID_FIRST_KILL',
        reward    = 500,
        announce  = true,
        title     = 'Star-Slayer',
        desc      = 'Felled the Star-Devourer for the first time.',
    },
    {
        id        = 'RAID_10_KILLS',
        reward    = 1500,
        announce  = true,
        title     = 'Devourer of the Devourer',
        desc      = '10 Star-Devourer kills.  It fears YOU now.',
    },
    -- Invasion defense milestones
    {
        id       = 'INV_FIRST_DEFENSE',
        reward   = 150,
        announce = false,
        title    = 'Sanctuary Defender',
        desc     = 'Helped repel your first Voidsent invasion.',
    },
    {
        id       = 'INV_10_DEFENSES',
        reward   = 500,
        announce = true,
        title    = 'Bulwark of the Sanctuary',
        desc     = '10 successful invasion defenses.  The moogles sleep soundly.',
    },
    {
        id       = 'INV_100_KILLS',
        reward   = 300,
        announce = true,
        title    = 'Voidsent Bane',
        desc     = '100 Voidsent invaders cut down.',
    },
    -- Colosseum ladder milestones
    {
        id       = 'COL_FIRST_WIN',
        reward   = 100,
        announce = false,
        title    = 'First Blood',
        desc     = 'Won your first Colosseum duel.',
    },
    {
        id       = 'COL_10_WINS',
        reward   = 300,
        announce = true,
        title    = 'Arena Regular',
        desc     = '10 Colosseum victories.  The crowd knows your name.',
    },
    {
        id       = 'COL_RATING_1400',
        reward   = 500,
        announce = true,
        title    = 'Contender',
        desc     = 'Reached 1400 arena rating.',
    },
    {
        id       = 'COL_RATING_1600',
        reward   = 1500,
        announce = true,
        title    = 'Arena Champion',
        desc     = 'Reached 1600 arena rating.  The ladder bows.',
    },
    -- Mythic+ keystone milestones (level = highest key TIMED, any dungeon)
    {
        id       = 'KEYSTONE_5',
        reward   = 300,
        announce = true,
        title    = 'Keystone Climber',
        desc     = 'Cleared a Mythic+5 keystone dungeon.',
    },
    {
        id       = 'KEYSTONE_10',
        reward   = 750,
        announce = true,
        title    = 'Keystone Conqueror',
        desc     = 'Cleared a Mythic+10.  The key only goes deeper.',
    },
    {
        id       = 'KEYSTONE_15',
        reward   = 2000,
        announce = true,
        title    = 'Keystone Legend',
        desc     = 'Cleared a Mythic+15.  Few will ever stand here.',
    },
    -- Augment milestones
    {
        id       = 'AUGMENT_NOVICE',
        reward   = 75,
        announce = false,
        title    = 'Augment Novice',
        desc     = '5 lifetime augmentation trades.',
    },
    {
        id       = 'AUGMENT_EXPERT',
        reward   = 300,
        announce = true,
        title    = 'Augment Expert',
        desc     = '50 lifetime augmentation trades.',
    },
    {
        id       = 'AUGMENT_MASTER',
        reward   = 1000,
        announce  = true,
        title     = 'Augment Master',
        desc      = '200 lifetime augmentations.  Gear transformed by your hands.',
        titleId   = xi.title.HERO_AMONG_HEROES,
        titleName = 'Hero Among Heroes',
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

-----------------------------------
-- Called from DungeonSystem.lua after incrementing Dungeon_Clears_Total.
-- Checks dungeon clear count milestones (in addition to infamy, which
-- M.onDungeonClear already handles).
-----------------------------------
function M.onDungeonCount(player)
    local clears = player:getCharVar('Dungeon_Clears_Total') or 0
    if clears >= 1  then award(player, MILESTONE_BY_ID['FIRST_DUNGEON'])  end
    if clears >= 10 then award(player, MILESTONE_BY_ID['TEN_DUNGEONS'])   end
    if clears >= 50 then award(player, MILESTONE_BY_ID['FIFTY_DUNGEONS']) end
end

-----------------------------------
-- Called from GameMaster.lua after a successful wave-fight completion.
-- wavesTotal is informational (not used here but kept for future tiers).
-----------------------------------
function M.onWaveClear(player)
    local clears = player:getCharVar('Wave_Clears_Total') or 0
    if clears >= 1  then award(player, MILESTONE_BY_ID['FIRST_WAVE'])   end
    if clears >= 10 then award(player, MILESTONE_BY_ID['WAVE_FIGHTER']) end
    if clears >= 50 then award(player, MILESTONE_BY_ID['WAVE_LEGEND'])  end
end

-----------------------------------
-- Called from Prestige_System.lua after a successful ascension.
-----------------------------------
function M.onAscension(player)
    local total = player:getCharVar('Prestige_Total_Ascensions') or 0
    if total >= 1  then award(player, MILESTONE_BY_ID['FIRST_ASCENSION'])  end
    if total >= 10 then award(player, MILESTONE_BY_ID['TEN_ASCENSIONS'])   end
    if total >= 50 then award(player, MILESTONE_BY_ID['FIFTY_ASCENSIONS']) end
end

-----------------------------------
-- Called from TreasureHunt.lua after a strongbox is unearthed
-- (TH_Found already updated).
-----------------------------------
function M.onTreasureFound(player)
    local found = player:getCharVar('TH_Found') or 0
    if found >= 1  then award(player, MILESTONE_BY_ID['TH_FIRST_CHEST']) end
    if found >= 10 then award(player, MILESTONE_BY_ID['TH_10_CHESTS'])   end
end

-----------------------------------
-- Called from ProvisionersLeague.lua after a fish weigh-in
-- (League_Turnins already updated) and after rank-ups.
-----------------------------------
function M.onLeagueTurnIn(player)
    if (player:getCharVar('League_Turnins') or 0) >= 1 then
        award(player, MILESTONE_BY_ID['LEAGUE_FIRST_TURNIN'])
    end
end

function M.onLeagueRank(player, rank)
    if rank >= 3 then award(player, MILESTONE_BY_ID['LEAGUE_RANK3']) end
    if rank >= 5 then award(player, MILESTONE_BY_ID['LEAGUE_RANK5']) end
end

-----------------------------------
-- Called from RaidBoss.lua for each credited player after a kill,
-- AFTER Raid_Kills has been updated.
-----------------------------------
function M.onRaidKill(player)
    local kills = player:getCharVar('Raid_Kills') or 0
    if kills >= 1  then award(player, MILESTONE_BY_ID['RAID_FIRST_KILL']) end
    if kills >= 10 then award(player, MILESTONE_BY_ID['RAID_10_KILLS'])   end
end

-----------------------------------
-- Called from Invasion.lua for each participant after a victorious
-- defense, AFTER Inv_Wins / Inv_Kills have been updated.
-----------------------------------
function M.onInvasionResult(player)
    local wins  = player:getCharVar('Inv_Wins')  or 0
    local kills = player:getCharVar('Inv_Kills') or 0
    if wins >= 1    then award(player, MILESTONE_BY_ID['INV_FIRST_DEFENSE']) end
    if wins >= 10   then award(player, MILESTONE_BY_ID['INV_10_DEFENSES'])   end
    if kills >= 100 then award(player, MILESTONE_BY_ID['INV_100_KILLS'])     end
end

-----------------------------------
-- Called from Colosseum.lua after every duel result (win or loss),
-- AFTER Col_Wins / Col_Best_Rating have been updated.
-----------------------------------
function M.onColosseumResult(player)
    local wins = player:getCharVar('Col_Wins') or 0
    local best = player:getCharVar('Col_Best_Rating') or 0
    if wins >= 1     then award(player, MILESTONE_BY_ID['COL_FIRST_WIN'])    end
    if wins >= 10    then award(player, MILESTONE_BY_ID['COL_10_WINS'])      end
    if best >= 1400  then award(player, MILESTONE_BY_ID['COL_RATING_1400']) end
    if best >= 1600  then award(player, MILESTONE_BY_ID['COL_RATING_1600']) end
end

-----------------------------------
-- Called from DungeonSystem.lua when a NEW personal-best keystone
-- level is recorded (level = the key level just cleared).
-----------------------------------
function M.onKeystoneBest(player, level)
    if level >= 5  then award(player, MILESTONE_BY_ID['KEYSTONE_5'])  end
    if level >= 10 then award(player, MILESTONE_BY_ID['KEYSTONE_10']) end
    if level >= 15 then award(player, MILESTONE_BY_ID['KEYSTONE_15']) end
end

-----------------------------------
-- Called from Augment_Moogle.lua after a confirmed augmentation trade.
-- Augment_Count is already incremented before this fires.
-----------------------------------
function M.onAugmentTrade(player)
    local count = player:getCharVar('Augment_Count') or 0
    if count >= 5   then award(player, MILESTONE_BY_ID['AUGMENT_NOVICE'])  end
    if count >= 50  then award(player, MILESTONE_BY_ID['AUGMENT_EXPERT'])  end
    if count >= 200 then award(player, MILESTONE_BY_ID['AUGMENT_MASTER'])  end
end

-- Exported for the !achievements command so it can iterate milestone metadata
-- without duplicating the list.
M.MILESTONES = MILESTONES

return M
