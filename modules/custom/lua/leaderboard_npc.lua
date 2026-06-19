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
require('scripts/zones/Escha_ZiTah/Zone')
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

m:addOverride('xi.zones.Escha_ZiTah.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'The Chronicler',
        packetName = string.format('%sThe Chronicler', xi.icon.STAR_LARGE),
        look       = 3017,
        -- Right end of the Hunting League vendor row in Escha Zi'Tah hub.
        x          = 32.0000,
        y          = -0.5000,
        z          = -30.0000,
        rotation   = 128,
        widescan   = 1,

        onTrade = function(player, npcArg, trade)
            player:printToPlayer('I only deal in glory, not goods.', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npcArg)
            local H = xi.msg.channel.SYSTEM_3
            local B = xi.msg.channel.SYSTEM_1

            -- Gather player's competitive stats.
            local hlTier    = player:getCharVar('HL_Tier')            or 0
            local hlLife    = player:getCharVar('HL_Points_Lifetime') or 0
            local nmKills   = player:getCharVar('Custom_NM_Kills')    or 0
            local sweeps    = player:getCharVar('WH_AllCleared_Lifetime') or 0
            local infamy    = player:getCharVar('Infamy_Lifetime')        or 0

            -- Ascension (Prestige) endgame layer: account-wide lifetime
            -- ascensions, plus this character's highest single-job prestige
            -- level (per-job CharVar Prestige_Level_<jobId>, jobs 1..22).
            local ascensions  = player:getCharVar('Prestige_Ascensions_Total') or 0
            local topPrestige = 0
            for jobId = 1, 22 do
                local lv = player:getCharVar(string.format('Prestige_Level_%d', jobId)) or 0
                if lv > topPrestige then topPrestige = lv end
            end

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

            player:printToPlayer('[The Chronicler] -- Your Legendary Record --------------', H)
            player:printToPlayer(string.format('  Rank: %-8s  NM Kills: %-6d  Lifetime Marks: %d', tierName, nmKills, hlLife), B)
            player:printToPlayer(string.format('  Unique NMs: %d/%d   Weekly Sweeps: %d', uniqueNMs, TOTAL_NMS, sweeps), B)
            player:printToPlayer(string.format('  Lifetime Infamy: %d   Achievements: %d/%d', infamy, achEarned, #ACH_IDS), B)
            player:printToPlayer(string.format('  Ascensions: %d   Highest Prestige: P%d', ascensions, topPrestige), B)
            local colRating = player:getCharVar('Col_Rating') or 0
            if colRating > 0 then
                player:printToPlayer(string.format('  Arena: %d rating (best %d)   W-L: %d-%d',
                    colRating,
                    player:getCharVar('Col_Best_Rating') or 0,
                    player:getCharVar('Col_Wins')   or 0,
                    player:getCharVar('Col_Losses') or 0), B)
            end
            local invWins = player:getCharVar('Inv_Wins') or 0
            if invWins > 0 then
                player:printToPlayer(string.format('  Invasions repelled: %d   Voidsent slain: %d',
                    invWins, player:getCharVar('Inv_Kills') or 0), B)
            end
            local raidKills = player:getCharVar('Raid_Kills') or 0
            if raidKills > 0 then
                player:printToPlayer(string.format('  Star-Devourer kills: %d', raidKills), B)
            end
            local leaguePts = player:getCharVar('League_Points') or 0
            if leaguePts > 0 then
                player:printToPlayer(string.format('  League points: %d   Fish weighed: %d',
                    leaguePts, player:getCharVar('League_Turnins') or 0), B)
            end
            local chests = player:getCharVar('TH_Found') or 0
            if chests > 0 then
                player:printToPlayer(string.format('  Strongboxes unearthed: %d', chests), B)
            end
            local derbyRaces = player:getCharVar('Derby_Races') or 0
            if derbyRaces > 0 then
                local profit = player:getCharVar('Derby_Profit') or 0
                player:printToPlayer(string.format('  Derby: %d wins / %d races   Lifetime: %s%d gil',
                    player:getCharVar('Derby_Wins') or 0, derbyRaces,
                    profit >= 0 and '+' or '', profit), B)
            end
            -- Combat records: show all-tier personal bests in a single line each.
            local maxNuke  = 0
            local maxBurst = 0
            local maxHeal  = 0
            local maxSC    = 0
            local maxDmg30 = 0
            for t = 1, 4 do
                local function cv(base) return player:getCharVar(base .. '_T' .. t) or 0 end
                if cv('MaxNuke')  > maxNuke  then maxNuke  = cv('MaxNuke')  end
                if cv('MaxBurst') > maxBurst then maxBurst = cv('MaxBurst') end
                if cv('MaxHeal')  > maxHeal  then maxHeal  = cv('MaxHeal')  end
                if cv('MaxSC')    > maxSC    then maxSC    = cv('MaxSC')    end
                if cv('MaxDmg30') > maxDmg30 then maxDmg30 = cv('MaxDmg30') end
            end
            if maxNuke > 0 or maxBurst > 0 or maxHeal > 0 or maxDmg30 > 0 then
                player:printToPlayer('[The Chronicler] -- Combat Records -------------------', H)
                player:printToPlayer(string.format('  Nuke: %s  Burst: %s  Heal: %s  Dmg/30s: %s',
                    maxNuke  > 0 and tostring(maxNuke)  or '--',
                    maxBurst > 0 and tostring(maxBurst) or '--',
                    maxHeal  > 0 and tostring(maxHeal)  or '--',
                    maxDmg30 > 0 and tostring(maxDmg30) or '--'), B)
                if maxSC > 0 then
                    player:printToPlayer(string.format('  Skillchain: %d', maxSC), B)
                end
            end
            player:printToPlayer('[The Chronicler] -- Server Leaderboards ---------------', H)
            player:printToPlayer('  Full rankings at:', B)
            player:printToPlayer('  legendary-ffxi.pages.dev/community/leaderboards/', B)
            player:printToPlayer('  Tip: !nms  !progress  !achievements  !featured', B)
        end,
    })
    utils.unused(npc)
end)

return m
