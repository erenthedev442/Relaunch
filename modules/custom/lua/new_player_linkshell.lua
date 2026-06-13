-----------------------------------
-- new_player_linkshell.lua  (REVIVED 2026-06-13 as the global server linkshell)
-- Hands EVERY character the server-wide "Legendary" linkpearl exactly once and
-- auto-equips it. One login hook covers BOTH the existing playerbase (on their
-- next login) and every future new character (on first login), gated by the
-- GlobalLS_Pearl CharVar so it fires only once per character.
--
-- The engine's addLinkpearl auto-equips + connects linkpearls to the SECONDARY
-- linkshell slot (/l2); that is intentional here (owner's choice) -- it is the
-- only path that joins LS chat the same session without a relog. Players who
-- want it in their main slot can just drag it there in-game.
--
-- Requires the "Legendary" linkshell row to exist in the `linkshells` table
-- (sql/zz_global_linkshell.sql); addLinkpearl looks it up by name.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('new_player_linkshell')

local LS_NAME  = 'Legendary'
local DONE_VAR = 'GlobalLS_Pearl'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- Real-login discriminator captured BEFORE super() (which clears gameLogin),
    -- mirroring announce_player_login.lua. Only act on an actual login from
    -- character select, never on a plain zone change.
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if not isLogin or (player:getCharVar(DONE_VAR) or 0) == 1 then
        return
    end

    -- Defer a few seconds so the inventory is fully loaded before we add + equip,
    -- and so this message lands just after the login MOTD tips.
    player:timer(4000, function(p)
        if (p:getCharVar(DONE_VAR) or 0) == 1 then
            return
        end
        -- addLinkpearl: spawns the linkpearl, stamps its exdata (LS id / color /
        -- signature) from the linkshells row matching LS_NAME, adds it to
        -- inventory, and (equip = true) equips + connects it to LS chat in the
        -- secondary slot. Returns false if the linkshell row is missing or the
        -- inventory is full -- we leave DONE_VAR unset in that case so it retries
        -- on the next login.
        if p:addLinkpearl(LS_NAME, true) then
            p:setCharVar(DONE_VAR, 1)
            p:printToPlayer(string.format(
                'You have received the server linkpearl [%s], kupo! It is equipped in your second linkshell slot -- say hello to everyone!',
                LS_NAME), xi.msg.channel.SYSTEM_3)
        end
    end)
end)

return m
