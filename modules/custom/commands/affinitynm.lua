-----------------------------------
-- !affinitynm [N | name]
-- Warps to any of the current Augment-Sage affinity NMs (for the affinity hunt).
--   !affinitynm            -- lists them all (number, NM, affinity, zone)
--   !affinitynm 4          -- warps to NM #4
--   !affinitynm behemoth   -- warps by name (partial, case-insensitive)
--   !affinitynm melee      -- warps by affinity category (partial)
--
-- Roster is read LIVE from modules/custom/lua/augment_affinity_catalog.lua so it
-- always matches the registrable affinities. (Before 2026-07-13 this held a stale
-- hardcoded 24-NM table from the pre-2026-07-06 stat-family scheme, so e.g.
-- `!affinitynm dex` warped to King Arthro -- a reworked-out NM that no longer
-- registers an affinity. Now only the live catalog NMs are listed.)
--
-- Warp coords come from the affinity spawn points in
-- modules/custom/sql/affinity_nm_spawns.sql (mob_spawn_points, groupid 2000x).
-- Permission 0 (all players), like !expcamp / !henge.
-----------------------------------
local catalog = require('modules/custom/lua/augment_affinity_catalog')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

-- Warp coords per affinity NM, keyed by the catalog's `nm` field. If the Sage
-- roster ever gains a NEW NM, add its coords here (from affinity_nm_spawns.sql);
-- the command warns rather than warping to nowhere when coords are missing.
local WARP =
{
    ['Behemoth']         = { zone = 105, x = -670.00, y = -23.00, z =  352.00 },
    ['King_Behemoth']    = { zone = 127, x = -267.50, y = -19.80, z =   73.70 },
    ['Ouryu']            = { zone =  29, x =  618.78, y =   0.56, z = -552.23 },
    ['Genbu']            = { zone = 130, x =  261.87, y = -70.22, z =  526.41 },
    ['Byakko']           = { zone = 130, x = -419.40, y = -70.20, z =  410.96 },
    ['Aspidochelone']    = { zone = 113, x = -175.33, y =   7.68, z = -247.30 },
    ['King_Vinegarroon'] = { zone = 125, x = -239.00, y =  -0.23, z = -650.00 },
    ['Phoenix']          = { zone =  30, x =  685.00, y = -31.76, z = -481.00 },
    ['Absolute_Virtue']  = { zone = 130, x =   -6.03, y = -40.52, z = -417.21 },
    ['Proto-Omega']      = { zone = 130, x =    1.00, y = -38.60, z = -485.00 },
    ['Kirin']            = { zone = 178, x =  -68.00, y =  32.58, z =    3.50 },
}

-- Roster built live from the Sage catalog. index = the !affinitynm number.
local function buildRoster()
    local roster = {}
    for _, row in ipairs(catalog.affinities or {}) do
        roster[#roster + 1] =
        {
            name  = (row.nm or ''):gsub('_', ' '),
            key   = row.nm,
            label = row.label or '',
            zone  = row.nmZone or '?',
            warp  = WARP[row.nm],
        }
    end
    return roster
end

commandObj.onTrigger = function(player, arg)
    local SYS    = xi.msg.channel.SYSTEM_3
    local roster = buildRoster()
    local entry

    local n = tonumber(arg)
    if n and roster[n] then
        entry = roster[n]
    elseif arg and arg ~= '' then
        local needle = string.lower(arg)
        for _, e in ipairs(roster) do
            if string.find(string.lower(e.name), needle, 1, true)
                or string.find(string.lower(e.label), needle, 1, true) then
                entry = e
                break
            end
        end
    end

    if not entry then
        player:printToPlayer('Affinity NMs -- warp with  !affinitynm <number|name>:', SYS)
        for i, e in ipairs(roster) do
            player:printToPlayer(string.format('  %2d. %-16s (%s) @ %s', i, e.name, e.label, e.zone), SYS)
        end
        return
    end

    if not entry.warp then
        player:printToPlayer(string.format('%s [%s] has no warp coordinates configured -- tell a GM.', entry.name, entry.label), SYS)
        return
    end

    player:printToPlayer(string.format('Warping to %s [%s affinity] in %s, kupo!', entry.name, entry.label, entry.zone), SYS)
    player:setPos(entry.warp.x, entry.warp.y, entry.warp.z, 0, entry.warp.zone)
end

return commandObj
