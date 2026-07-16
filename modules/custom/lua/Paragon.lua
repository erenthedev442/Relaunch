-----------------------------------
-- Paragon.lua
--
-- THE PARAGON BOARD: the meta-progression that Apex Trials feeds. Paragon
-- Points (banked by the Apex climb) are spent here on:
--   * Paragon Levels -- an infinite prestige track (Paragon_Level), shown on
--     !reallevel + the website leaderboard, with a scaling title flair.
--   * Perks -- small, HARD-CAPPED permanent stat boosts (login-applied addMods):
--       Vigor +HP (cap 5000), Might +ATT/RATT (1000), Precision +ACC/RACC
--       (1000), Warding +DEF (2000), Arcana +MATT/MACC/M.Dmg (1000),
--       Dominion +Pet ATK/ACC/MAB/MACC/attr/TP (1000).
--   * Daily Might -- unlock once, then claim a 2-hour throughput/sustain surge
--     once per UTC day (proven Henge-style status effects).
--
-- "Prestige + QoL + capped perks" posture: the caps are deliberately modest
-- next to maxed gear / Apex boss stats, so this is flex-and-flavour, not power
-- creep.
--
-- CharVars:
--   Paragon_Points        unspent currency (banked by Apex Trials)
--   Paragon_Level         prestige level (infinite)
--   Paragon_Perk_<id>     rank in each perk (0..maxRank)
--   Paragon_MightUnlock   1 once the Daily Might perk is bought
--   Paragon_MightDay      UTC Julian day of the last Daily Might claim
--
-- Perk mods are re-applied on every game-in (login AND zone) because zoning
-- wipes non-gear addMods -- same pattern as the cross-job trait trainer. NPC:
-- Paragon Sage in GM Home, beside the Apex Arbiter (x 7.5, z -35).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
local C = require('modules/custom/lua/paragon_catalog')

local m = Module:new('paragon')
local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Apply all owned perk mods (full totals). Safe to call on every game-in:
-- zoning/relog wipe these addMods, so re-adding the full total re-establishes
-- them without doubling.
-----------------------------------
local function applyPerks(player)
    for _, perk in ipairs(C.PERKS) do
        local rank = player:getCharVar('Paragon_Perk_' .. perk.id) or 0
        if rank > 0 then
            local total = rank * perk.perRank
            for _, modId in ipairs(C.modIds(perk)) do
                player:addMod(modId, total)
            end
        end
    end
end
xi._paragon_applyPerks = applyPerks

-----------------------------------
-- Spending actions (each re-opens the menu afterwards)
-----------------------------------
local openMenu  -- forward decl

local function reopen(player)
    player:timer(30, function(p) openMenu(p) end)
end

local function runAction(player, label, action, after)
    local ok, err = pcall(action, player)
    if not ok then
        print(string.format('[Paragon] %s error for %s: %s', label, player:getName(), tostring(err)))
        player:printToPlayer(
            '[Paragon] That action encountered an internal error. Check your current rank and points before trying again.',
            SYS)
    end

    if after then
        after(player)
    end
end

local function menuCancelled(player, eventCancelled)
    if eventCancelled then
        player:printToPlayer(
            '[Paragon] Menu interrupted by another event. Talk to the Sage or use !paragon to try again.',
            SYS)
    end
end

local function ascend(player)
    local lvl  = player:getCharVar('Paragon_Level') or 0
    local pp   = player:getCharVar('Paragon_Points') or 0
    local cost = C.levelCost(lvl)
    if pp < cost then
        player:printToPlayer(string.format('[Paragon] Ascending needs %d Paragon Points (you have %d).', cost, pp), SYS)
        return
    end
    player:setCharVar('Paragon_Points', pp - cost)
    player:setCharVar('Paragon_Level', lvl + 1)
    player:printToPlayer(string.format(
        '[Paragon] Ascended to Paragon Level %d!  Title: %s.', lvl + 1, C.titleFor(lvl + 1)), SYS)
end

local function buyPerk(player, perk)
    local rank = player:getCharVar('Paragon_Perk_' .. perk.id) or 0
    if rank >= perk.maxRank then
        player:printToPlayer(string.format('[Paragon] %s is already maxed (%d/%d).', perk.label, rank, perk.maxRank), SYS)
        return
    end
    local pp   = player:getCharVar('Paragon_Points') or 0
    local cost = C.perkRankCost(perk, rank)
    if pp < cost then
        player:printToPlayer(string.format('[Paragon] %s rank %d needs %d Paragon Points (you have %d).',
            perk.label, rank + 1, cost, pp), SYS)
        return
    end
    player:setCharVar('Paragon_Points', pp - cost)
    player:setCharVar('Paragon_Perk_' .. perk.id, rank + 1)
    -- Live-apply this rank's delta (full set is re-applied on the next game-in).
    for _, modId in ipairs(C.modIds(perk)) do
        player:addMod(modId, perk.perRank)
    end
    player:printToPlayer(string.format('[Paragon] %s -> rank %d/%d  (total +%d each stat).',
        perk.label, rank + 1, perk.maxRank, (rank + 1) * perk.perRank), SYS)
end

local function dailyMight(player)
    local unlocked = (player:getCharVar('Paragon_MightUnlock') or 0) == 1
    if not unlocked then
        local pp = player:getCharVar('Paragon_Points') or 0
        if pp < C.DAILY_MIGHT_UNLOCK then
            player:printToPlayer(string.format('[Paragon] Unlocking Daily Might costs %d Paragon Points (you have %d).',
                C.DAILY_MIGHT_UNLOCK, pp), SYS)
            return
        end
        player:setCharVar('Paragon_Points', pp - C.DAILY_MIGHT_UNLOCK)
        player:setCharVar('Paragon_MightUnlock', 1)
        player:printToPlayer('[Paragon] Daily Might unlocked! Claim it here once per day.', SYS)
        return
    end

    local today = tonumber(os.date('!%Y%j')) or 0  -- UTC Julian day (matches daily_login_bonus)
    if (player:getCharVar('Paragon_MightDay') or 0) == today then
        player:printToPlayer("[Paragon] You've already claimed Paragon's Might today. Come back tomorrow.", SYS)
        return
    end
    player:setCharVar('Paragon_MightDay', today)

    local dur = C.DAILY_MIGHT_DURATION
    player:addStatusEffect(xi.effect.MAX_HP_BOOST, { power = C.DAILY_MIGHT_HP,      duration = dur, origin = player, tick = 0, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REGAIN,       { power = C.DAILY_MIGHT_REGAIN,  duration = dur, origin = player, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REFRESH,      { power = C.DAILY_MIGHT_REFRESH, duration = dur, origin = player, tick = 3, subType = 0, subPower = 0 })
    player:addStatusEffect(xi.effect.REGEN,        { power = C.DAILY_MIGHT_REGEN,   duration = dur, origin = player, tick = 3, subType = 0, subPower = 0 })
    player:printToPlayer("[Paragon] Paragon's Might surges through you! +HP, Regain, Refresh & Regen for 2 hours.", SYS)
end

-----------------------------------
-- Menu
--
-- Two-tier structure because the client's GMPROMPT UI caps at 8 rows -- with 6
-- perks + Ascend + Daily Might + Close, a flat list would overflow. Main menu
-- keeps the top-level choices (Ascend, Perks..., Daily Might, Close); the
-- Perks submenu is a flat list of every perk in the catalog plus Back. Adding
-- another perk in paragon_catalog.lua auto-shows up in the submenu (up to 7 --
-- one more slot before the submenu itself needs to page).
-----------------------------------
local openPerksMenu  -- forward decl

openMenu = function(player)
    local lvl  = player:getCharVar('Paragon_Level') or 0
    local pp   = player:getCharVar('Paragon_Points') or 0
    local dailyLabel = (player:getCharVar('Paragon_MightUnlock') or 0) == 1
        and 'Claim Daily Might'
        or string.format('Unlock Daily Might (%d PP)', C.DAILY_MIGHT_UNLOCK)

    player:printToPlayer(string.format(
        '[Paragon] Level %d (%s).  Paragon Points: %d.  Next Ascend: %d PP.',
        lvl, C.titleFor(lvl), pp, C.levelCost(lvl)), SYS)

    local options = {
        { 'Ascend', function(p)
            runAction(p, 'Ascend', ascend, reopen)
        end },
        { 'Perks...', function(p)
            -- customMenu erases the current response context after this
            -- callback returns. Defer the submenu so its new context survives.
            p:timer(30, function(q) openPerksMenu(q) end)
        end },
        { dailyLabel, function(p)
            runAction(p, 'Daily Might', dailyMight, reopen)
        end },
        { 'Close', function() end },
    }
    player:customMenu({
        title       = 'Paragon',
        options     = options,
        onCancelled = menuCancelled,
    })
end
xi._paragon_openMenu = openMenu

openPerksMenu = function(player)
    local pp = player:getCharVar('Paragon_Points') or 0
    player:printToPlayer(string.format('[Paragon] Perks -- Paragon Points: %d.', pp), SYS)
    for _, perk in ipairs(C.PERKS) do
        local rank = player:getCharVar('Paragon_Perk_' .. perk.id) or 0
        local cost = (rank < perk.maxRank) and tostring(C.perkRankCost(perk, rank)) .. ' PP' or 'MAX'
        player:printToPlayer(string.format('   %-10s rank %d/%d  (next: %s)', perk.label, rank, perk.maxRank, cost), SYS)
    end

    local options = {}
    for _, perk in ipairs(C.PERKS) do
        local p = perk  -- capture per-iteration so the closure binds THIS row's perk
        options[#options + 1] = { perk.label, function(pl)
            runAction(pl, p.label, function(q)
                buyPerk(q, p)
            end, function(q)
                q:timer(30, function(nextPlayer) openPerksMenu(nextPlayer) end)
            end)
        end }
    end
    options[#options + 1] = { 'Back', function(pl) reopen(pl) end }
    player:customMenu({
        title       = 'Paragon Perks',
        options     = options,
        onCancelled = menuCancelled,
    })
end
xi._paragon_openPerksMenu = openPerksMenu

-----------------------------------
-- Re-apply perks on every game-in (login AND zone) -- mods are wiped on zone.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, ...)
    super(player, ...)
    player:timer(2000, function(p) applyPerks(p) end)
end)

-----------------------------------
-- NPC: Paragon Sage in GM Home
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Paragon_Sage',
        packetName = string.format('%sParagon Sage', xi.icon.STAR_LARGE),
        look       = 215,
        x          = C.NPC_POS.x,
        y          = C.NPC_POS.y,
        z          = C.NPC_POS.z,
        rotation   = C.NPC_POS.rot,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer(
                '[Paragon] Spend Paragon Points (earned in Apex Trials) on prestige levels, capped perks, and the Daily Might buff.', SYS)
            player:timer(30, function(p) openMenu(p) end)
        end,
    })
    utils.unused(npc)
end)

return m
