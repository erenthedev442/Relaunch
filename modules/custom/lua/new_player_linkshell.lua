-----------------------------------
-- new_player_linkshell.lua  (REVIVED 2026-06-13 as the global server linkshell)
-- Hands EVERY character the server-wide "Legendary" linkpearl exactly once and
-- auto-equips it. One login hook covers BOTH the existing playerbase (on their
-- next login) and every future new character (on first login), gated by the
-- GlobalLS_Pearl CharVar so it fires only once per character.
--
-- IMPORTANT (2026-06-13): addLinkpearl's AUTO-EQUIP path (equip=true) writes a
-- char_equip row for the secondary linkshell slot (equipslotid 17) with a
-- GARBAGE containerid (observed 99/97/85). On the character's NEXT login the
-- engine's LoadEquip dereferences that non-existent container and SEGFAULTS the
-- whole map server -- a single new player crash-loops the server for everyone.
-- So we now grant the pearl WITHOUT auto-equipping (equip=false): the player
-- gets it in their bag and drags it into a linkshell slot themselves. (A live
-- safety net `equip_guard.service` on the box also scrubs any container>16
-- rows; this change removes the source so that guard can eventually retire.)
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
        -- signature) from the linkshells row matching LS_NAME, and adds it to
        -- inventory. equip=FALSE: do NOT use the engine auto-equip path (it
        -- corrupts the linkshell-slot char_equip row -> LoadEquip segfault; see
        -- header). Returns false if the linkshell row is missing or the
        -- inventory is full -- we leave DONE_VAR unset in that case so it retries
        -- on the next login.
        if p:addLinkpearl(LS_NAME, false) then
            p:setCharVar(DONE_VAR, 1)
            p:printToPlayer(string.format(
                'You have received the server linkpearl [%s], kupo! Equip it in a linkshell slot (drag it onto your /linkshell or /linkshell2 slot) to join the global chat -- say hello to everyone!',
                LS_NAME), xi.msg.channel.SYSTEM_3)
        end
    end)
end)

return m
