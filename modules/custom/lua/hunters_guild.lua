-----------------------------------
-- hunters_guild.lua
--
-- Shared library for the Hunter's Guild reputation system. Called by
-- the Reforge spawner (awardCurrency) and HuntingLeague onMobDeath to
-- bump rep + apply amplifiers + announce rank-ups.
--
-- Public API:
--   hg.bumpRep(player, guildKey, baseMarks)
--       Lazy-backfills the player on first call. Adds `baseMarks` to
--       the guild's rep CharVar. Returns (newRep, newRank, didRankUp).
--       Auto-fires the rank-up chat announcement.
--
--   hg.applyAmplifier(player, guildKey, baseMarks)
--       Returns final marks after applying:
--         * the player's current rank amplifier for this guild
--         * Trinity capstone bonus (if active + applicable)
--         * Apex capstone bonus (if active + applicable; supersedes Trinity)
--       Caller adds the returned value to the player's mark balance.
--
--   hg.getRep(player, guildKey)               -> int
--   hg.getRank(player, guildKey)              -> int 1..5
--   hg.getRankLabel(player, guildKey)         -> string
--   hg.getAmplifierPercent(player, guildKey)  -> int (display: "+25")
--
-- All state lives in CharVars. No SQL, no zone NPCs required here -
-- the announce-only path is the minimum viable system; the spawner
-- modules drive everything.
-----------------------------------
local catalog = require('modules/custom/lua/hunters_guild_catalog')
local hg = {}

-- Lazy-loaded weekly_hunts reference. We can't unconditionally require
-- it at top level because the weekly_hunts module might require us
-- back (circular). The Weekly Hunt Board only consumes events, so we
-- protect-call the require + tolerate it being absent.
local _wh = nil
local function whFire(player, eventType, metadata)
    if _wh == nil then
        local ok, mod = pcall(require, 'modules/custom/lua/weekly_hunts')
        _wh = ok and mod or false
    end
    if _wh and _wh.fire then
        _wh.fire(player, eventType, metadata)
    end
end

-----------------------------------
-- Internal helpers
-----------------------------------

-- Resolve rep value -> rank index 1..5. Walks the ladder from the top
-- down so the FIRST threshold met wins.
local function rankIndexForRep(rep)
    for i = #catalog.ranks, 1, -1 do
        if rep >= catalog.ranks[i].minRep then
            return i
        end
    end
    return 1
end

local function rankDefForIndex(idx)
    return catalog.ranks[idx]
end

local function guildDef(guildKey)
    local g = catalog.guilds[guildKey]
    if not g then
        error(string.format("hunters_guild: unknown guild '%s'", tostring(guildKey)), 2)
    end
    return g
end

-- Capstone-evaluation: returns true only when EVERY required guild
-- has reached the Grandmaster threshold (max rank in the ladder).
local function meetsCapstone(player, capstone)
    local maxIdx = #catalog.ranks
    for _, gKey in ipairs(capstone.requires) do
        local g   = guildDef(gKey)
        local rep = player:getCharVar(g.repCv) or 0
        if rankIndexForRep(rep) < maxIdx then
            return false
        end
    end
    return true
end

-- Check if any capstone applies to THIS guild's marks for THIS player.
-- Apex strictly supersedes Trinity (Apex players are always also at
-- Trinity since requires{} is a superset, but the +50% replaces the
-- +25% rather than stacking).
local function capstoneBonusFor(player, guildKey)
    local apex = catalog.capstones.apex
    if (player:getCharVar(apex.achievedCv) or 0) == 1 then
        for _, k in ipairs(apex.appliesTo) do
            if k == guildKey then return apex.bonus end
        end
    end
    local trinity = catalog.capstones.trinity
    if (player:getCharVar(trinity.achievedCv) or 0) == 1 then
        for _, k in ipairs(trinity.appliesTo) do
            if k == guildKey then return trinity.bonus end
        end
    end
    return 0
end

-- Chat helpers - kept inline so the announcement format is in one
-- place (easier to tweak prose without spelunking through callers).
local function announceRankUp(player, guildKey, newRankIdx)
    local g      = guildDef(guildKey)
    local rank   = rankDefForIndex(newRankIdx)
    local ampPct = math.floor(rank.amplifier * 100 + 0.5)
    player:printToPlayer(
        string.format(
            "[Guild] You have risen to %s of the %s!  %s amplifier: +%d%%.",
            rank.label, g.label, g.markType, ampPct
        ),
        xi.msg.channel.SYSTEM_3
    )
end

local function announceCapstone(player, capstoneKey)
    local cap = catalog.capstones[capstoneKey]
    if not cap then return end
    local bonusPct = math.floor(cap.bonus * 100 + 0.5)
    local appliesTo
    if #cap.appliesTo == #catalog.guildOrder then
        appliesTo = 'all marks'
    else
        local names = {}
        for _, k in ipairs(cap.appliesTo) do
            table.insert(names, catalog.guilds[k].markType)
        end
        appliesTo = table.concat(names, ' / ')
    end
    -- Per-player chat for the achiever.
    player:printToPlayer(
        string.format("*** [Guild] %s ACHIEVED! +%d%% bonus to %s. ***",
            cap.label:upper(), bonusPct, appliesTo),
        xi.msg.channel.SYSTEM_3
    )
    -- Server-wide announcement so other players see the milestone.
    -- printToArea on a player only reaches their zone, so we use the
    -- yell channel via messageText to broadcast more widely.
    local broadcast = string.format(
        "%s has achieved %s status, kupo!",
        player:getName(), cap.label
    )
    -- Best-effort broadcast: yell channel may not propagate cross-zone
    -- without a specific zone setup. Fall back to per-player + the
    -- achievement is durable in the CharVar regardless.
    player:PrintToArea(broadcast, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM)
end

-- One-time per player: copy lifetime marks -> starting guild rep so
-- existing veterans don't lose all their progress when the system
-- goes live. Gated by catalog.backfillFromLifetime + a CharVar flag.
local function backfillIfNeeded(player)
    if not catalog.backfillFromLifetime then return end
    if (player:getCharVar(catalog.backfillFlagCv) or 0) == 1 then return end

    -- Set the flag FIRST so a mid-backfill crash doesn't replay it.
    player:setCharVar(catalog.backfillFlagCv, 1)

    local granted = {}
    for _, gKey in ipairs(catalog.guildOrder) do
        local g           = guildDef(gKey)
        local existing    = player:getCharVar(g.repCv) or 0
        local lifetimeRep = player:getCharVar(g.lifetimeCv) or 0
        -- Only grant if the player has NO current rep AND has some
        -- lifetime marks. Skips replays on hot-reload of the module.
        if existing == 0 and lifetimeRep > 0 then
            player:setCharVar(g.repCv, lifetimeRep)
            granted[#granted + 1] = string.format(
                "%s: %d rep (%s)", g.label,
                lifetimeRep, rankDefForIndex(rankIndexForRep(lifetimeRep)).label
            )
        end
    end

    if #granted > 0 then
        player:printToPlayer(
            "[Guild] Welcome, hunter. Your lifetime kills have been credited:",
            xi.msg.channel.SYSTEM_3)
        for _, line in ipairs(granted) do
            player:printToPlayer("  " .. line, xi.msg.channel.SYSTEM_3)
        end
        -- Backfill might have crossed a capstone threshold immediately.
        -- Trigger capstone checks AFTER all guilds are filled.
        hg.checkCapstones(player)
    end
end

-----------------------------------
-- Public API
-----------------------------------

function hg.getRep(player, guildKey)
    return player:getCharVar(guildDef(guildKey).repCv) or 0
end

function hg.getRank(player, guildKey)
    return rankIndexForRep(hg.getRep(player, guildKey))
end

function hg.getRankLabel(player, guildKey)
    return rankDefForIndex(hg.getRank(player, guildKey)).label
end

function hg.getAmplifierPercent(player, guildKey)
    local rankAmp    = rankDefForIndex(hg.getRank(player, guildKey)).amplifier
    local capstone   = capstoneBonusFor(player, guildKey)
    return math.floor((rankAmp + capstone) * 100 + 0.5)
end

-- Returns next-rank info for menus: (nextRankLabel, repNeeded, repCurrent)
-- or nil if already at max.
function hg.getNextRankInfo(player, guildKey)
    local idx = hg.getRank(player, guildKey)
    if idx >= #catalog.ranks then return nil end
    local nextDef = rankDefForIndex(idx + 1)
    return nextDef.label, nextDef.minRep, hg.getRep(player, guildKey)
end

-- Sums rankAmp + capstoneBonus and returns the multiplier you'd apply
-- to base marks. e.g. Veteran (0.25) + Trinity (0.25) = 1.50.
function hg.getMultiplier(player, guildKey)
    local rankAmp  = rankDefForIndex(hg.getRank(player, guildKey)).amplifier
    local capstone = capstoneBonusFor(player, guildKey)
    return 1.0 + rankAmp + capstone
end

-- Final mark calculation. Caller passes the NM's BASE mark value and
-- gets back the amplified value to actually add to the player's CV.
-- floor() to avoid fractional marks; players accept "felt right" over
-- "perfectly granular".
function hg.applyAmplifier(player, guildKey, baseMarks)
    if baseMarks == nil or baseMarks <= 0 then return 0 end
    return math.floor(baseMarks * hg.getMultiplier(player, guildKey))
end

-- Bump the player's rep for this guild by `baseMarks` (the NM's BASE
-- mark value, NOT the amplified payout). Lazy-backfills, then handles
-- rank-up + capstone announcements as side effects.
-- Returns (newRep, newRankIdx, didRankUp).
function hg.bumpRep(player, guildKey, baseMarks)
    if baseMarks == nil or baseMarks <= 0 then
        return hg.getRep(player, guildKey), hg.getRank(player, guildKey), false
    end

    backfillIfNeeded(player)

    local g       = guildDef(guildKey)
    local oldRep  = player:getCharVar(g.repCv) or 0
    local oldRank = rankIndexForRep(oldRep)
    local newRep  = oldRep + baseMarks
    player:setCharVar(g.repCv, newRep)
    local newRank = rankIndexForRep(newRep)

    local didRankUp = newRank > oldRank
    if didRankUp then
        announceRankUp(player, guildKey, newRank)
        -- Weekly Hunt Board: notify "Guild Climber" / similar objectives
        -- that the player just ranked up. Done BEFORE capstone checks so
        -- the rank-up fires regardless of whether this also triggers a
        -- capstone.
        whFire(player, 'guild_rankup', { guild = guildKey, newRank = newRank })
        -- Hitting Grandmaster on this guild might unlock Trinity or Apex.
        if newRank >= #catalog.ranks then
            hg.checkCapstones(player)
        end
    end
    return newRep, newRank, didRankUp
end

-- Evaluate Trinity + Apex eligibility. Fires the achievement chat
-- announcement once per capstone (gated by the achievedCv flag).
-- Called automatically by bumpRep on rank-ups; also called explicitly
-- after backfill in case a veteran qualifies immediately.
function hg.checkCapstones(player)
    -- Apex first: if it triggers, it also implies Trinity but we want
    -- Apex's bigger announcement to take precedence at fire time.
    -- (Order doesn't matter for math; bonuses are evaluated separately
    -- at award time and Apex supersedes Trinity in capstoneBonusFor.)
    for _, capKey in ipairs({ 'apex', 'trinity' }) do
        local cap = catalog.capstones[capKey]
        local already = (player:getCharVar(cap.achievedCv) or 0) == 1
        if not already and meetsCapstone(player, cap) then
            player:setCharVar(cap.achievedCv, 1)
            announceCapstone(player, capKey)
        end
    end
end

-- Convenience for chat commands / NPC menus: returns the full guild
-- status string for one guild as a single line of text.
function hg.formatGuildLine(player, guildKey)
    local g       = guildDef(guildKey)
    local rep     = hg.getRep(player, guildKey)
    local rank    = rankDefForIndex(hg.getRank(player, guildKey))
    local ampPct  = hg.getAmplifierPercent(player, guildKey)
    local nextLbl, nextNeed = hg.getNextRankInfo(player, guildKey)
    if nextLbl then
        return string.format(
            "%-24s [%-11s +%3d%%]  %6d / %d  -> %s",
            g.label, rank.label, ampPct, rep, nextNeed, nextLbl
        )
    else
        return string.format(
            "%-24s [%-11s +%3d%%]  %6d  (MAX RANK)",
            g.label, rank.label, ampPct, rep
        )
    end
end

return hg
