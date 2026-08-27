-----------------------------------
-- !affinitynm [N | name]
-- Warps to any of the current Augment-Sage affinity NMs (for the affinity hunt).
--   !affinitynm            -- lists them all (number, NM, affinity, zone)
--   !affinitynm 4          -- warps to NM #4
--   !affinitynm behemoth   -- warps by name (partial, case-insensitive)
--   !affinitynm melee      -- warps by affinity category (partial)
--
-- The canonical roster contains all 24 collection targets. Eleven also grant a
-- trophy for a live Augment Sage affinity; the other thirteen still advance the
-- collection and award Hunt Marks.
--
-- Warp coords come from the affinity spawn points in
-- modules/custom/sql/affinity_nm_spawns.sql (mob_spawn_points, groupid 2000x).
-- Permission 0 (all players), like !expcamp / !henge.
-----------------------------------
local catalog         = require('modules/custom/lua/affinity_nm_catalog')
local affinityCatalog = require('modules/custom/lua/augment_affinity_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, arg)
    local SYS    = xi.msg.channel.SYSTEM_3
    local entry

    local n = tonumber(arg)
    if n and catalog.entries[n] then
        entry = catalog.entries[n]
    elseif arg and arg ~= '' then
        local needle = string.lower(arg)
        for _, e in ipairs(catalog.entries) do
            local profile = catalog.profiles[e.band]
            local affinity = e.registerCat and affinityCatalog.byCat(e.registerCat)
            if
                string.find(string.lower(e.display), needle, 1, true) or
                string.find(string.lower(profile.label), needle, 1, true) or
                (affinity and string.find(string.lower(affinity.label), needle, 1, true))
            then
                entry = e
                break
            end
        end
    end

    if not entry then
        player:printToPlayer(string.format(
            'Affinity NM collection: %d/%d -- warp with !affinitynm <number|name>:',
            catalog.clearCount(player), #catalog.entries), SYS)
        for _, e in ipairs(catalog.entries) do
            local profile  = catalog.profiles[e.band]
            local affinity = e.registerCat and affinityCatalog.byCat(e.registerCat)
            local purpose  = affinity and ('Sage: ' .. affinity.label) or 'Collection'
            player:printToPlayer(string.format(
                ' %s %2d. %-18s [%s, %s] @ %s',
                catalog.hasClear(player, e.index) and '*' or '-',
                e.index, e.display, profile.label, purpose, e.zone), SYS)
        end
        return
    end

    local profile  = catalog.profiles[entry.band]
    local affinity = entry.registerCat and affinityCatalog.byCat(entry.registerCat)
    player:printToPlayer(string.format(
        'Warping to %s [%s%s] in %s, kupo!',
        entry.display, profile.label, affinity and (', ' .. affinity.label .. ' affinity') or '', entry.zone), SYS)
    player:setPos(entry.x, entry.y, entry.z, 0, entry.zoneId)
end

return commandObj
