-----------------------------------
-- func: progress
-- desc: Prints a cross-system progression summary: Hunting League rank,
--       Hunt Marks, Infamy, dungeon clears, weekly-hunt completion,
--       and Hunter's Guild standings — all in one quick readout.
--
-- Usage:  !progress
--
-- Output sections (via SYSTEM_3 / yellow chat for headers,
-- LINKSHELL channel for body lines so they're visually distinct):
--   [Progress] ── Hunting League ──
--   [Progress] ── Dungeons & Infamy ──
--   [Progress] ── Weekly Hunts ──
--   [Progress] ── Hunter's Guilds ──
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- HL tier names indexed by CharVar value (1-based).
local HL_TIER_NAMES = { 'Initiate', 'Bronze', 'Silver', 'Gold', 'Legend' }

-- Hunter's Guild rank names indexed by rep bracket.
-- Rep thresholds mirror hunters_guild_catalog.lua's rankLadder.
local function guildRankName(rep)
    if rep >= 10000 then return 'Master'
    elseif rep >= 5000  then return 'Expert'
    elseif rep >= 2000  then return 'Adept'
    elseif rep >= 500   then return 'Apprentice'
    else                     return 'Novice'
    end
end

local H = xi.msg.channel.SYSTEM_3    -- yellow (headers)
local B = xi.msg.channel.LINKSHELL   -- teal  (body rows)

commandObj.onTrigger = function(player)
    local name = player:getName()

    -- ── Hunting League ──────────────────────────────────────────
    local hlTier    = player:getCharVar('HL_Tier')           or 0
    local hlPoints  = player:getCharVar('HL_Points')         or 0
    local hlLife    = player:getCharVar('HL_Points_Lifetime') or 0
    local nmKills   = player:getCharVar('Custom_NM_Kills')   or 0

    local tierLabel = HL_TIER_NAMES[math.max(1, math.min(hlTier, 5))] or 'Initiate'
    if hlTier == 0 then tierLabel = 'Initiate' end

    player:printToPlayer('[Progress] ── Hunting League ──────────────────', H)
    player:printToPlayer(string.format('  Rank: %s (Tier %d)   Current Marks: %d', tierLabel, hlTier, hlPoints), B)
    player:printToPlayer(string.format('  Lifetime Marks: %d    Total NM Kills: %d', hlLife, nmKills), B)

    -- ── Dungeons & Infamy ────────────────────────────────────────
    local infamy       = player:getCharVar('Infamy')               or 0
    local infamyLife   = player:getCharVar('Infamy_Lifetime')       or 0
    local totalClears  = player:getCharVar('Dungeon_Clears_Total')  or 0
    local streak       = player:getCharVar('Dungeon_Streak')        or 0

    -- Per-dungeon clears
    local clearsWH  = player:getCharVar('Dungeon_Clears_whispering_halls') or 0
    local clearsVA  = player:getCharVar('Dungeon_Clears_voidwalker_arena') or 0
    local clearsEP  = player:getCharVar('Dungeon_Clears_cloister_of_sorrow') or 0
    local clearsET  = player:getCharVar('Dungeon_Clears_eternal_throne') or 0

    player:printToPlayer('[Progress] ── Dungeons & Infamy ──────────────', H)
    player:printToPlayer(string.format('  Infamy: %d   (Lifetime: %d)', infamy, infamyLife), B)
    player:printToPlayer(string.format('  Total Clears: %d   Win Streak: %d', totalClears, streak), B)
    player:printToPlayer(string.format('  Outer Bastion: %d   Voidwalker Arena: %d', clearsWH, clearsVA), B)
    player:printToPlayer(string.format('  Empyreal Paradox: %d   Eternal Throne: %d', clearsEP, clearsET), B)

    -- ── Weekly Hunts ─────────────────────────────────────────────
    local whWeek = player:getCharVar('WH_Week') or 0
    local today  = tonumber(os.date('!%Y%W')) or 0
    local thisWeek = (whWeek == today)

    local whDone = 0
    if thisWeek then
        for slot = 1, 5 do
            if (player:getCharVar(string.format('WH_S%d_Done', slot)) or 0) == 1 then
                whDone = whDone + 1
            end
        end
    end
    local whLifetime = player:getCharVar('WH_AllCleared_Lifetime') or 0

    player:printToPlayer('[Progress] ── Weekly Hunts ───────────────────', H)
    if thisWeek then
        player:printToPlayer(string.format('  This week: %d / 5 completed', whDone), B)
    else
        player:printToPlayer('  This week: not started (talk to the Hunt Board)', B)
    end
    player:printToPlayer(string.format('  All-cleared weeks: %d', whLifetime), B)

    -- ── Hunter\'s Guilds ──────────────────────────────────────────
    local afRep    = player:getCharVar('Guild_AF_Rep')    or 0
    local relicRep = player:getCharVar('Guild_Relic_Rep') or 0
    local empyRep  = player:getCharVar('Guild_Empy_Rep')  or 0
    local hlRepG   = player:getCharVar('Guild_HL_Rep')    or 0

    player:printToPlayer('[Progress] ── Hunter\'s Guilds ──────────────────', H)
    player:printToPlayer(string.format('  AF Guild: %s (%d)   Relic Guild: %s (%d)',
        guildRankName(afRep), afRep, guildRankName(relicRep), relicRep), B)
    player:printToPlayer(string.format('  Empy Guild: %s (%d)   HL Guild: %s (%d)',
        guildRankName(empyRep), empyRep, guildRankName(hlRepG), hlRepG), B)

    -- ── Daily Board ──────────────────────────────────────────────
    local today2  = tonumber(os.date('!%Y%j')) or 0
    local dbDay   = player:getCharVar('DB_Day') or 0
    local dbDone  = 0
    if dbDay == today2 then
        for slot = 1, 3 do
            if (player:getCharVar(string.format('DB_S%d_Done', slot)) or 0) == 1 then
                dbDone = dbDone + 1
            end
        end
    end
    local dbLife = player:getCharVar('DB_AllCleared_Lifetime') or 0

    player:printToPlayer('[Progress] ── Daily Board ───────────────────', H)
    if dbDay == today2 then
        player:printToPlayer(string.format('  Today: %d / 3 completed', dbDone), B)
    else
        player:printToPlayer('  Today: not started (talk to the Daily Board NPC)', B)
    end
    player:printToPlayer(string.format('  All-cleared days: %d', dbLife), B)
end

return commandObj
