-----------------------------------
-- !unitywarp
-- Self-service travel to any Unity Wanted NM's Ethereal Junction -- the same
-- destinations the hub Board (the Unity NPC reached via !hub) sends you to.
-- Text-select, like a warp menu:
--   !unitywarp            -> numbered list of NMs and their junction zones
--   !unitywarp <#>        -> warp to that entry's junction
--   !unitywarp <text>     -> warp to the first NM/zone whose name contains <text>
--
-- This is WARP-ONLY. Popping the NM at the junction still costs accolades and
-- requires the contract to be unlocked -- that gate lives on the junction NPC
-- (unity_wanted.lua) and is unchanged. Destinations are sourced live from the
-- same catalog + junction map the Board uses, so the two never drift.
--
-- Lives in modules/custom/commands/ so it auto-registers as !unitywarp and
-- hot-reloads with no restart (init.txt loads the whole dir).
-- Created 2026-08-10 (owner request: "!unitywarp like expwarp, same places as
-- the hub Unity NPC").
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,     -- player command, same access as !hub / !unity
    parameters = 's',   -- optional: a number (list index) or a name fragment
}

local S       = xi.msg.channel.SYSTEM_3
local catalog = require('modules/custom/lua/unity_wanted_catalog')
local jmap    = require('modules/custom/lua/unity_junction_map')

-- Build the ordered destination list from the catalog: only NMs that actually
-- have a mapped junction with a warp point. Sorted by tier then label so the
-- printed numbering is stable across reloads (and matches what a player sees).
local function buildDests()
    local dests = {}
    for _, nm in ipairs(catalog.nms) do
        local zoneId = jmap.byNm[nm.name]
        local jz     = zoneId and jmap.junctions[zoneId]
        if jz and jz.points and jz.points[1] then
            dests[#dests + 1] =
            {
                label    = nm.label or nm.name,
                tier     = nm.tier or 0,
                zoneId   = zoneId,
                zoneName = (jz.zoneName or ''):gsub('_', ' '),
                pt       = jz.points[1],
            }
        end
    end
    table.sort(dests, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        return a.label < b.label
    end)
    return dests
end

local function listDests(player, dests)
    player:printToPlayer('>>> UNITY WARP <<<   use:  !unitywarp <#>', S)
    for i, d in ipairs(dests) do
        player:printToPlayer(string.format('  %2d. [T%d] %-22s -> %s',
            i, d.tier, d.label, d.zoneName), S)
    end
    player:printToPlayer('  (warp only -- popping the NM still needs accolades + unlock at the junction)', S)
end

commandObj.onTrigger = function(player, arg)
    local dests = buildDests()
    if #dests == 0 then
        player:printToPlayer('[UnityWarp] No junction destinations are mapped, kupo.', S)
        return
    end

    -- No argument: show the selectable list.
    if not arg or arg == '' then
        listDests(player, dests)
        return
    end

    -- Resolve the pick: numeric index first, then a case-insensitive substring
    -- match against the NM label or its junction zone name.
    local pick
    local n = tonumber(arg)
    if n and dests[n] then
        pick = dests[n]
    else
        local needle = tostring(arg):lower()
        for _, d in ipairs(dests) do
            if d.label:lower():find(needle, 1, true)
                or d.zoneName:lower():find(needle, 1, true) then
                pick = d
                break
            end
        end
    end

    if not pick then
        player:printToPlayer(string.format(
            '[UnityWarp] No match for "%s". Run !unitywarp for the list.', tostring(arg)), S)
        return
    end

    -- Same landing spot / offset the hub Board uses.
    local pt = pick.pt
    player:printToPlayer(string.format('[UnityWarp] -> %s  (%s)', pick.label, pick.zoneName), S)
    player:setPos(pt.x + 1.5, pt.y, pt.z + 1.5, pt.rot or 0, pick.zoneId)
end

return commandObj
