-----------------------------------
-- func: dungeon
-- desc: Show current Dungeon System status — Infamy balance, active
--       session info if any, and quick abort.
--
-- Usage:
--   !dungeon          -- print status
--   !dungeon abort    -- abort active dungeon session (no reward)
--
-- The actual dungeon entry / vendor flows live on the Dungeon Master
-- and Infamy Vendor NPCs at GM Home (modules/custom/lua/DungeonSystem.lua).
-----------------------------------
local catalog = require('modules/custom/lua/dungeon_catalog')
local dungeon = require('modules/custom/lua/DungeonSystem')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, action)
    local infamy   = player:getCharVar(catalog.currencyCv) or 0
    local lifetime = player:getCharVar('Infamy_Lifetime') or 0

    if action == 'abort' then
        -- Defer to the module's central end path — same code that
        -- runs on death / timeout. If there's no session, the module
        -- silently no-ops.
        dungeon.endDungeon(player, 'manual')
        return
    end

    if action == 'home' then
        -- SAFETY RAIL #3: emergency escape hatch.
        -- Warps the player straight to GM Home regardless of session
        -- state. Use cases:
        --   * Player got stuck in a dungeon zone with no live session
        --     (somehow — server restart mid-run, etc.).
        --   * Mob spawn failed and player wandered around looking for
        --     enemies that never came.
        --   * Any future "I ended up somewhere I can't get out of"
        --     scenario.
        --
        -- Also force-ends the session if one exists, so the player
        -- can pick a fresh dungeon from a clean state.
        if dungeon.endDungeon then
            -- Best-effort end; harmless no-op when there's no session.
            pcall(function() dungeon.endDungeon(player, 'manual') end)
        end
        local exit = catalog.exitWarp
        player:setPos(exit.x, exit.y, exit.z, exit.rotation, exit.zoneId)
        player:printToPlayer(
            '[Dungeon] Emergency warp to GM Home. Any active session was cancelled.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer('=== Dungeon System ===', xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        string.format('  Infamy balance:   %d  (lifetime earned: %d)',
            infamy, lifetime),
        xi.msg.channel.SYSTEM_3)

    -- Per-dungeon clear counts.
    local anyClears = false
    for _, d in ipairs(catalog.dungeons) do
        local clears = player:getCharVar('Dungeon_Clears_' .. d.id) or 0
        if clears > 0 then
            if not anyClears then
                player:printToPlayer('  Clears by dungeon:', xi.msg.channel.SYSTEM_3)
                anyClears = true
            end
            player:printToPlayer(
                string.format('    %-32s %d', d.label, clears),
                xi.msg.channel.SYSTEM_3)
        end
    end
    if not anyClears then
        player:printToPlayer('  No clears yet — talk to the Dungeon Master at GM Home, kupo!',
            xi.msg.channel.SYSTEM_3)
    end

    player:printToPlayer('  Use "!dungeon abort" to abandon an active session.',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer('  Use "!dungeon home"  for an emergency warp out, no questions asked.',
        xi.msg.channel.SYSTEM_3)
end

return commandObj
