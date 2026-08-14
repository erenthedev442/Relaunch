-----------------------------------
-- !huntwarp <name>
-- Warp to the spawn point of a Hunters' Guild NM.
-- Costs 100,000 gil per use (charged only after a successful warp).
--
-- Usage:
--   !huntwarp fafnir      -- unique match: warps + charges
--   !huntwarp king        -- multi-match: popup picker (King Vinegarroon, etc.)
--   !huntwarp             -- usage help + guild summary
--
-- Matches typed text against the NM's label and internal key (case-insensitive
-- substring). Sorted most-accessible first: guild order (AF -> Relic -> Empy ->
-- HL), then lowest tier. Source of truth for the NM list + coords is
-- modules/custom/lua/huntnm_warp_table.lua, which mirrors the site's
-- Hunters' Guild page (www.ffxi-legendary.com/progression/hunters-guild/).
--
-- Same shape as !augwarp -- if you know that command, you know this one.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

local SYS       = xi.msg.channel.SYSTEM_3
local GIL_COST  = 100000
local GUILD_ORDER = { AF = 1, Relic = 2, Empy = 3, HL = 4 }

local function chargeAndWarp(player, entry)
    if player:getGil() < GIL_COST then
        player:printToPlayer(string.format(
            '[Huntwarp] Need %d gil to warp (have %d). No warp performed.',
            GIL_COST, player:getGil()), SYS)
        return
    end

    -- Charge first, then warp. If setPos ever throws, gil comes back on the
    -- pcall path so the player never pays for a no-op.
    player:delGil(GIL_COST)
    local ok, err = pcall(function()
        player:setPos(entry.x, entry.y, entry.z, entry.rot, entry.zone)
    end)
    if not ok then
        player:addGil(GIL_COST)
        player:printToPlayer(string.format(
            '[Huntwarp] Warp to %s failed (%s). Gil refunded.',
            entry.label, tostring(err)), SYS)
        return
    end

    player:printToPlayer(string.format(
        '[Huntwarp] Warped to %s -- %s Hunters Guild tier %d target (-%d gil).',
        entry.zoneName, entry.guild, entry.tier, GIL_COST), SYS)
end

local function usage(player)
    player:printToPlayer(string.format(
        '!huntwarp <name>  --  Warp to a Hunters Guild NM (%d gil).', GIL_COST), SYS)
    player:printToPlayer('  e.g.  !huntwarp fafnir  |  !huntwarp king vinegarroon  |  !huntwarp jormungand', SYS)
    player:printToPlayer('  Full NM list: https://www.ffxi-legendary.com/progression/hunters-guild/', SYS)
end

commandObj.onTrigger = function(player, arg)
    local ok, warpTable = pcall(require, 'modules/custom/lua/huntnm_warp_table')
    if not ok or type(warpTable) ~= 'table' then
        player:printToPlayer('[Huntwarp] Warp table not loaded -- report this to a GM.', SYS)
        return
    end

    if not arg or arg == '' then
        usage(player)
        return
    end

    local needle  = string.lower(arg)
    local matches = {}
    for _, e in ipairs(warpTable) do
        if string.find(string.lower(e.label), needle, 1, true)
        or string.find(string.lower(e.key),   needle, 1, true) then
            matches[#matches + 1] = e
        end
    end

    if #matches == 0 then
        player:printToPlayer(string.format(
            '[Huntwarp] No Hunters Guild NM matches "%s". Try a tier-1 name like fafnir / tarasque / bune.', arg), SYS)
        return
    end

    -- Most-accessible first: exact label match, then guild order (AF < Relic <
    -- Empy < HL), then lowest tier.
    table.sort(matches, function(a, b)
        local ax = (string.lower(a.label) == needle)
        local bx = (string.lower(b.label) == needle)
        if ax ~= bx then return ax end
        local ag = GUILD_ORDER[a.guild] or 99
        local bg = GUILD_ORDER[b.guild] or 99
        if ag ~= bg then return ag < bg end
        return a.tier < b.tier
    end)

    -- Single match: charge + go.
    if #matches == 1 then
        chargeAndWarp(player, matches[1])
        return
    end

    -- Multi-match: picker menu (customMenu caps at 8 options, keep labels short).
    local shown   = math.min(#matches, 8)
    local options = {}
    for i = 1, shown do
        local e = matches[i]
        local label = string.format('%s (%s T%d)', e.label, e.guild, e.tier)
        options[i] = { label, function(q) chargeAndWarp(q, e) end }
    end
    options[shown + 1] = { 'Close', function() end }

    local title = string.format('Huntwarp [%dk gil]', GIL_COST / 1000)
    player:timer(30, function(pp) pp:customMenu({ title = title, options = options }) end)

    if #matches > shown then
        player:printToPlayer(string.format(
            '  (+%d more matches -- refine your query to narrow the list)', #matches - shown), SYS)
    end
end

return commandObj
