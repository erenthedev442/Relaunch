-----------------------------------
-- online_tracker.lua
-- Maintains an in-memory set of currently-online players updated on
-- every non-zoning login (xi.player.onGameIn). Used by the !who command.
--
-- Since LSB exposes no logout hook, stale entries (crashed clients,
-- network drops) are lazily pruned via GetPlayerByName at query time:
-- if the function returns nil the player is no longer in-world.
--
-- Exported API (attached to the Module table so require() callers get it):
--   m.getOnline()   → sorted list of { name, tier, loginAt }
--                     highest-tier first, alphabetical within tier
-----------------------------------
require('modules/module_utils')

-- In-memory set: charname → { name, tier, loginAt }
-- Resets on server restart — acceptable for a small server.
local _online = {}

local m = Module:new('online_tracker')

-----------------------------------
-- Returns a sorted list of currently-online players.
-- Lazily prunes entries for players who have disconnected.
-----------------------------------
function m.getOnline()
    local result = {}
    for name, info in pairs(_online) do
        if GetPlayerByName(name) then
            table.insert(result, info)
        else
            _online[name] = nil   -- prune disconnected / crashed client
        end
    end
    -- Sort: highest HL tier first; alphabetical within tier.
    table.sort(result, function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        return a.name < b.name
    end)
    return result
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        _online[player:getName()] = {
            name    = player:getName(),
            tier    = player:getCharVar('HL_Tier') or 0,
            loginAt = os.time(),
        }
    end
end)

return m
