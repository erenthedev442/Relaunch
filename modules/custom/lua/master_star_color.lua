-----------------------------------
-- master_star_color.lua
-- Computes MasterStarTier on every game-in and stores it as a CharVar so
-- the 0x01b job_info packet can carry the value to the Ashita mastercolor
-- addon, which then draws the three job-master stars in tier-appropriate
-- colors instead of the fixed golden yellow.
--
-- Tier is floor(bonus_levels / 10), clamped to 0-7.
-- Bonus levels use the same five axes as !reallevel:
--   Gear  = getAverageItemLevel() - 99
--   Asc   = Prestige_Level_<job> CharVar (ascension ranks)
--   JP    = getSpentJobPoints() / 100
--   Merit = sum of 7 attr merits / 5
--   Reb   = Rebirth_Count_<job> * 1 (current-job Rebirths)
--
-- Tier → color rendered by the Ashita addon:
--   0  silver  (bonus  0- 9)
--   1  white   (bonus 10-19)
--   2  green   (bonus 20-29)
--   3  blue    (bonus 30-39)
--   4  cyan    (bonus 40-49)
--   5  purple  (bonus 50-59)
--   6  orange  (bonus 60-69)
--   7  red     (bonus 70+)
--
-- Needs a map restart to take effect (addOverride hook).
-- Lives in modules/custom/lua/ (merge-safe).
-----------------------------------
require('modules/module_utils')

local m = Module:new('master_star_color')

local JP_PER_LEVEL         = 100
local MERIT_ATTR_PER_LEVEL = 5
local LEVELS_PER_REBIRTH   = 1
local ATTR_MERITS = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR' }

local function computeTier(player)
    local job    = player:getMainJob()
    local ilvl   = player:getAverageItemLevel()
    local gearLv = math.max(0, ilvl - 99)
    local ascLv  = player:getCharVar('Prestige_Level_' .. job) or 0
    local jpLv   = math.floor((player:getSpentJobPoints() or 0) / JP_PER_LEVEL)

    local meritSum = 0
    for _, mName in ipairs(ATTR_MERITS) do
        meritSum = meritSum + (player:getMerit(xi.merit[mName]) or 0)
    end
    local meritLv = math.floor(meritSum / MERIT_ATTR_PER_LEVEL)

    local rebirthLv = (player:getCharVar('Rebirth_Count_' .. job) or 0) * LEVELS_PER_REBIRTH

    local bonus = gearLv + ascLv + jpLv + meritLv + rebirthLv
    return math.min(7, math.floor(bonus / 10))
end

m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)
    local tier = computeTier(player)
    player:setCharVar('MasterStarTier', tier)
end)

return m
