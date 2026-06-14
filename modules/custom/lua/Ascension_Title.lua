-----------------------------------
-- Ascension_Title.lua
-- Gives ascended players a tiered, menacing TITLE under their name -- the text
-- half of the Ascension "master-status" marker. (The gold master STARS above the
-- name are switched on for ascended players via a small C++ flag in
-- char_update.cpp / char_status.cpp -- see the FJB core-patches checklist.)
--
-- Tier comes from the account-wide lifetime ascension count
-- (Prestige_Total_Ascensions, stamped by Prestige_System.tryAscend). On login we:
--   * GRANT (addTitle) every tier title the player has earned, so they're all
--     wearable from the title menu, and
--   * DISPLAY (setTitle) the highest one ONLY the first time they climb into a new
--     tier -- after that we never re-force it, so the player stays free to wear
--     whatever title they like.
--
-- Title ids are from scripts/enum/title.lua -- swap any of them to taste. A few
-- other menacing options: HELLSBANE(11), BLACK_DRAGON_SLAYER(7),
-- DISPERSER_OF_DARKNESS(551), CONQUEROR_OF_FATE(421), DREAD_PURGER(1035).
--
-- Lives in modules/custom/ (survives upstream merges); auto-loads via the
-- `custom/lua/` folder entry in modules/init.txt. Replaces the old aura module.
-----------------------------------
require('modules/module_utils')

local m = Module:new('ascension_title')

-- Account-wide lifetime ascensions (same var the achievements feed / old aura read).
local ASCENSION_VAR = 'Prestige_Total_Ascensions'
-- Highest tier index we've already auto-DISPLAYED for this char, so we only set the
-- title active on a genuine rank-UP and never stomp the player's own title choice.
local SHOWN_VAR = 'Ascension_Title_Shown'

-- Tiers in ASCENDING `min` order; the highest whose `min` the player meets is "top".
-- title = an id from scripts/enum/title.lua.
local TIERS =
{
    { min =  1, title = xi.title.BLOODY_BERSERKER,           label = 'Ascendant'    }, -- "Bloody Berserker"
    { min =  5, title = xi.title.BLACK_DEATH,                label = 'Exalted'      }, -- "Black Death"
    { min = 10, title = xi.title.SWORN_TO_THE_DARK_DIVINITY, label = 'Transcendent' }, -- "Sworn to the Dark Divinity"
}

m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)

    local count  = player:getCharVar(ASCENSION_VAR) or 0
    local topIdx = nil

    -- Grant every tier title they've earned (wearable from the title menu).
    for i, t in ipairs(TIERS) do
        if count >= t.min then
            topIdx = i
            if not player:hasTitle(t.title) then
                player:addTitle(t.title)
            end
        end
    end

    if not topIdx then
        return  -- not ascended yet -- no title.
    end

    -- Auto-display the top tier only when they've newly climbed into it.
    if (player:getCharVar(SHOWN_VAR) or 0) < topIdx then
        player:setTitle(TIERS[topIdx].title)
        player:setCharVar(SHOWN_VAR, topIdx)
    end
end)

return m
