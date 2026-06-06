-----------------------------------
-- func: huntrank
-- desc: Displays the player's Hunter's Guild status across all four
--       guilds — current rank, rep, amplifier %, and progress to the
--       next rank. Also shows Trinity / Apex capstone status, and
--       the v2 Vana'diel hunt-target list per guild so the player
--       knows what to go kill.
--
-- v2 (2026-05-29) design note:
--   Reputation is earned ONLY by killing the dedicated vanilla HNMs
--   listed in hunters_guild_catalog.huntTargets — see
--   modules/custom/lua/hunters_guild_hunts.lua for the override hook.
--   Reforge / HL kills no longer grant rep (they still BENEFIT from
--   the amplifier the rep unlocks, just don't grow it).
-----------------------------------
local catalog = require('modules/custom/lua/hunters_guild_catalog')
local hg      = require('modules/custom/lua/hunters_guild')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',  -- optional 'targets' arg; bare !huntrank shows status only
}

local function showStatus(player)
    player:printToPlayer(string.format('=== Hunter\'s Guild Status — %s ===', player:getName()),
        xi.msg.channel.SYSTEM_3)

    -- One line per guild, in display order.
    for _, gKey in ipairs(catalog.guildOrder) do
        player:printToPlayer('  ' .. hg.formatGuildLine(player, gKey),
            xi.msg.channel.SYSTEM_3)
    end

    -- Capstone status. Show both, with a tick mark for achieved.
    local trinityDone = (player:getCharVar(catalog.capstones.trinity.achievedCv) or 0) == 1
    local apexDone    = (player:getCharVar(catalog.capstones.apex.achievedCv) or 0) == 1

    local trinityMark = trinityDone and '[X]' or '[ ]'
    local apexMark    = apexDone    and '[X]' or '[ ]'

    player:printToPlayer(string.format(
        '  %s Trinity Hunter  (Grandmaster in AF + Relic + Empy) — +25%% to those marks',
        trinityMark), xi.msg.channel.SYSTEM_3)
    player:printToPlayer(string.format(
        '  %s Apex Hunter     (Grandmaster in ALL four guilds)   — +50%% to ALL marks',
        apexMark), xi.msg.channel.SYSTEM_3)

    player:printToPlayer(
        '  ( type "!huntrank targets" to see the NM hunt list per guild )',
        xi.msg.channel.SYSTEM_3)
end

local function showTargets(player)
    player:printToPlayer('=== Hunter\'s Guild — Vana\'diel Hunt Targets ===',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  Each kill of these NMs grants rep to the matching guild.',
        xi.msg.channel.SYSTEM_3)

    for _, gKey in ipairs(catalog.guildOrder) do
        local g = catalog.guilds[gKey]
        player:printToPlayer(string.format('-- %s --', g.label),
            xi.msg.channel.SYSTEM_3)
        local targets = catalog.huntTargets[gKey] or {}
        for _, t in ipairs(targets) do
            -- Replace underscores with spaces for the zone label so
            -- "Dragons_Aery" reads as "Dragons Aery" in chat.
            local zoneLabel = (t.zone or '?'):gsub('_', ' ')
            player:printToPlayer(string.format(
                '  T%d  +%d  %s  (%s)',
                t.tier, t.baseRep, t.label, zoneLabel),
                xi.msg.channel.SYSTEM_3)
        end
    end
end

commandObj.onTrigger = function(player, arg)
    if arg and string.lower(arg) == 'targets' then
        showTargets(player)
    else
        showStatus(player)
    end
end

return commandObj
