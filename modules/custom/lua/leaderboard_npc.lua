-----------------------------------
-- leaderboard_npc.lua
-- "The Chronicler" NPC at Reisenjima Henge. Shows the player a personal
-- stat summary (kill counts, unique NMs, competitive metrics) and
-- points them to the live leaderboard website for server-wide rankings.
--
-- The NPC cannot query across all players in Lua (no DB access), so it
-- shows YOUR stats only and defers cross-player ranking to the website,
-- which regenerates from the live DB several times a day.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Reisenjima_Henge/Zone')
local catalog = require('modules/custom/lua/hunting_league_catalog')

local m = Module:new('leaderboard_npc')

local TIER_NAMES = { 'Initiate', 'Bronze', 'Silver', 'Gold', 'Legend' }

-- Total HL NMs available for the encyclopedia completion counter.
local function countTotalNMs()
    local n = 0
    for _, td in ipairs(catalog.tiers) do
        n = n + #td.mobs
    end
    return n
end
local TOTAL_NMS = countTotalNMs()

m:addOverride('xi.zones.Reisenjima_Henge.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'The Chronicler',
        packetName = string.format('%sThe Chronicler', xi.icon.STAR_LARGE),
        look       = 3017,
        -- Positioned to the right of the Accessories NPC (same Y/Z row).
        x          = 8.4861,
        y          = 5.5090,
        z          = -12.1827,
        rotation   = 230,
        widescan   = 1,

        onTrade = function(player, npcArg, trade)
            player:printToPlayer('I only deal in glory, not goods.', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npcArg)
            local H = xi.msg.channel.SYSTEM_3
            local B = xi.msg.channel.LINKSHELL

            -- Gather player's competitive stats.
            local hlTier    = player:getCharVar('HL_Tier')            or 0
            local hlLife    = player:getCharVar('HL_Points_Lifetime') or 0
            local nmKills   = player:getCharVar('Custom_NM_Kills')    or 0
            local dungeons  = player:getCharVar('Dungeon_Clears_Total')   or 0
            local sweeps    = player:getCharVar('WH_AllCleared_Lifetime') or 0
            local infamy    = player:getCharVar('Infamy_Lifetime')        or 0

            -- Count distinct NMs defeated.
            local uniqueNMs = 0
            for _, td in ipairs(catalog.tiers) do
                for _, mob in ipairs(td.mobs) do
                    if (player:getCharVar('NMKilled_' .. mob.groupId) or 0) ~= 0 then
                        uniqueNMs = uniqueNMs + 1
                    end
                end
            end

            -- Count earned achievements.
            local ACH_IDS = { 'FIRST_HUNT','TENTH_HUNT','CENTURY','THOUSAND',
                               'TIER2_FIRST','TIER3_FIRST','TIER4_FIRST','APEX_HUNTER',
                               'MARKS_1K','MARKS_10K','MARKS_100K' }
            local achEarned = 0
            for _, id in ipairs(ACH_IDS) do
                if (player:getCharVar('ACH_' .. id) or 0) ~= 0 then
                    achEarned = achEarned + 1
                end
            end

            local tierName = TIER_NAMES[math.max(1, math.min(hlTier, 5))] or 'Initiate'
            if hlTier == 0 then tierName = 'Initiate' end

            player:printToPlayer('[The Chronicler] ── Your Legendary Record ──────────────', H)
            player:printToPlayer(string.format('  Rank: %-8s  NM Kills: %-6d  Lifetime Marks: %d', tierName, nmKills, hlLife), B)
            player:printToPlayer(string.format('  Unique NMs: %d/%d   Dungeons Cleared: %d   Weekly Sweeps: %d', uniqueNMs, TOTAL_NMS, dungeons, sweeps), B)
            player:printToPlayer(string.format('  Lifetime Infamy: %d   Achievements: %d/%d', infamy, achEarned, #ACH_IDS), B)
            player:printToPlayer('[The Chronicler] ── Server Leaderboards ───────────────', H)
            player:printToPlayer('  Full rankings at:', B)
            player:printToPlayer('  richardknutzjr.github.io/FFXI-Private-Server-FJB/community/leaderboards/', B)
            player:printToPlayer('  Tip: !nms  !progress  !achievements  !featured', B)
        end,
    })
    utils.unused(npc)
end)

return m
