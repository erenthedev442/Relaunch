-----------------------------------
-- new_char_starter_marks.lua
-- Grants new characters a starter stipend of Hunt Marks so they can
-- immediately purchase a Bronze weapon from the Gear Progression NPC
-- without needing to grind first (breaks the chicken-and-egg loop
-- where you need gear to do kills and kills to get gear currency).
--
-- Starter grant: 25 HL Points
--   Bronze weapons cost 10-30 marks, so this covers one entry-level
--   purchase with a small buffer.
--
-- Also prints a welcome message explaining the server's core systems.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('new_char_starter_marks')

local STARTER_MARKS = 25
local CV_POINTS     = 'HL_Points'

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    -- Grant starter Hunt Marks (only if this is truly a fresh character;
    -- charCreate is called once on creation, never on login).
    local current = player:getCharVar(CV_POINTS) or 0
    player:setCharVar(CV_POINTS, current + STARTER_MARKS)
end)

-- Welcome message fires on first login (onPlayerLogin fires on every
-- login, so we gate on a CharVar that is set only once).
m:addOverride('xi.player.onPlayerLogin', function(player)
    super(player)

    if (player:getCharVar('WELCOME_SHOWN') or 0) == 0 then
        player:setCharVar('WELCOME_SHOWN', 1)

        local lines = {
            '=== Welcome to Legendary ===',
            string.format('A starter gift of %d Hunt Marks is waiting in your pocket.', STARTER_MARKS),
            'NEW CHARACTER? Type  !gmhome  and visit the setup Moogles there:',
            '  - Character Upgrader  -- weapon skills, spells, Trusts, capped skills',
            string.format('  - EXP Camp Moogle     -- warp to a camp and level to 99 (%gx EXP, fast!)', xi.settings.main.EXP_RATE),
            '  - Gear Moogle         -- a starter gear kit to get you going',
            'Then summon your Trusts and type  !hunt  to start the Hunting League.',
            'Handy anytime:  !buff (Refresh/Regen)  -  !progress  -  !help',
            'Full walkthrough: https://www.ffxi-legendary.com/getting-started/first-steps/',
            'Good luck, and enjoy the hunt!',
        }
        for _, line in ipairs(lines) do
            player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
        end
    end
end)

return m
