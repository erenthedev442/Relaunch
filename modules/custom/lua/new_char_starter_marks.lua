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

local STARTER_MARKS  = 25
local CV_POINTS      = 'HL_Points'
local LEGENDARY_RING = 26169                 -- modules/custom/sql/legendary_ring.sql (Rare/Ex)
local CV_RING        = 'NewChar_Ring_Grant'  -- 1 = owed the starter Legendary Ring

m:addOverride('xi.player.charCreate', function(player)
    super(player)

    -- Grant starter Hunt Marks (only if this is truly a fresh character;
    -- charCreate is called once on creation, never on login).
    local current = player:getCharVar(CV_POINTS) or 0
    player:setCharVar(CV_POINTS, current + STARTER_MARKS)

    -- Flag the starter Legendary Ring as owed. The item itself is handed over
    -- on first login (below): inventory containers aren't safely writable at
    -- creation time, so delivery is deferred -- same pattern as
    -- modules/custom/lua/legacy_ring_grant.lua.
    player:setCharVar(CV_RING, 1)
end)

-- Welcome message fires on first login (onPlayerLogin fires on every
-- login, so we gate on a CharVar that is set only once).
m:addOverride('xi.player.onPlayerLogin', function(player)
    super(player)

    -- Deliver the starter Legendary Ring (flagged at charCreate). Idempotent
    -- and inventory-safe: the ring is Rare/Ex so a character can only ever hold
    -- one; if the bag is full we keep the flag set and retry on the next login.
    if (player:getCharVar(CV_RING) or 0) == 1 then
        if player:hasItem(LEGENDARY_RING) then
            player:setCharVar(CV_RING, 0)
        elseif player:getFreeSlotsCount() > 0 then
            player:addItem(LEGENDARY_RING)
            player:setCharVar(CV_RING, 0)
        end
        -- bag full: leave the flag set; it retries next login
    end

    if (player:getCharVar('WELCOME_SHOWN') or 0) == 0 then
        player:setCharVar('WELCOME_SHOWN', 1)

        local lines = {
            '=== Welcome to Legendary ===',
            string.format('A starter gift of %d Hunt Marks and a Legendary Ring is waiting for you.', STARTER_MARKS),
            'NEW CHARACTER? Type !hub and visit the setup NPCs there:',
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
