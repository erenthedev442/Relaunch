-----------------------------------
-- !unity
-- Shows the player's Unity Wanted NM progress: per-tier conquest counts,
-- weekly-featured NM, current accolade balance, and the specific NMs that
-- still need a first kill. The 5th trust-slot gate (trust_progression_cap)
-- reads Unity_NMs_Conquered, so this is also the "am I close?" readout.
-- Ported/created 2026-07-13 (player report: 'need a way to see which ones
-- I've fought to unlock additional trusts').
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',   -- optional 'conquered' | 'c'
}

local S       = xi.msg.channel.SYSTEM_3
local catalog = require('modules/custom/lua/unity_wanted_catalog')
local progress = require('modules/custom/lua/unity_wanted_progress')

-- Weekly-featured NM id: match unity_wanted.lua's rotation exactly so the
-- Board's "Weekly" line and !unity's "*" marker never disagree.
local function weeklyFeaturedId()
    if not catalog.nms or #catalog.nms == 0 then return 0 end
    return (math.floor(os.time() / 604800) % #catalog.nms) + 1
end

local function line(player, fmt, ...)
    player:printToPlayer('  ' .. string.format(fmt, ...), S)
end

commandObj.onTrigger = function(player, mode)
    -- Default view shows the NMs that STILL need a kill; '!unity conquered'
    -- (or 'c') flips to the already-beaten list.
    local wantConquered = (mode == 'conquered' or mode == 'c')

    local total   = player:getCharVar('Unity_NMs_Conquered') or 0
    local acc     = player:getCurrency('unity_accolades') or 0
    local weekly  = weeklyFeaturedId()

    player:printToPlayer('>>> UNITY WANTED PROGRESS <<<', S)
    line(player, 'Accolades: %d   Total NMs conquered: %d/%d',
        acc, total, #catalog.nms)

    -- Bucket the catalog by tier, split each into fought / unfought.
    local buckets = { [1] = { fought = {}, remaining = {} },
                      [2] = { fought = {}, remaining = {} },
                      [3] = { fought = {}, remaining = {} } }
    for _, nm in ipairs(catalog.nms) do
        local bucket = buckets[nm.tier]
        if bucket then
            local done = (player:getCharVar('UW_Conq_' .. nm.id) or 0) == 1
            local mark = (nm.id == weekly) and (nm.label .. ' *') or nm.label
            table.insert(done and bucket.fought or bucket.remaining, mark)
        end
    end

    for tier = 1, 3 do
        local b = buckets[tier]
        local total_tier = #b.fought + #b.remaining
        if total_tier > 0 then
            player:printToPlayer(' ', S)
            local lock = progress.isTierUnlocked(player, tier) and 'unlocked' or 'locked'
            line(player, 'Tier %d: %d/%d conquered [%s]', tier, #b.fought, total_tier, lock)
            local show = wantConquered and b.fought or b.remaining
            local label = wantConquered and 'Conquered' or 'Remaining'
            if #show == 0 then
                local empty = wantConquered and '(none yet)' or '(all conquered!)'
                line(player, '  %s: %s', label, empty)
            else
                -- Wrap NM names at ~90 chars per printed line so long tiers stay readable.
                local buf, width = {}, 0
                for _, name in ipairs(show) do
                    if width + #name > 90 and #buf > 0 then
                        line(player, '  %s: %s', label, table.concat(buf, ', '))
                        buf, width = {}, 0
                    end
                    table.insert(buf, name)
                    width = width + #name + 2
                end
                if #buf > 0 then
                    line(player, '  %s: %s', label, table.concat(buf, ', '))
                end
            end
        end
    end

    player:printToPlayer(' ', S)
    -- 5th-trust-slot gate: conquer every Unity Wanted NM.
    local remaining = #catalog.nms - total
    if remaining > 0 then
        line(player, 'Conquer %d more to unlock the 5th trust slot. (* = this week\'s bonus NM)',
            remaining)
    else
        line(player, 'All Unity Wanted NMs conquered! 5th trust slot is unlocked.')
    end
    line(player, 'Use  !unity conquered  to list the NMs you have already beaten.')
end

return commandObj
