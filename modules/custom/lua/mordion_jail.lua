-----------------------------------
-- Mordion Gaol helpers: persist jail/pardon in the DB and disconnect
-- instead of live-zoning. Live setPos/warp in or out of zone 131 has
-- been crashing the map process (heap smash in m_charsToChangeZone).
-----------------------------------
local KEY = 'modules/custom/lua/mordion_jail'
local jail = package.loaded[KEY]
if type(jail) ~= 'table' then
    jail = {}
end
package.loaded[KEY] = jail
xi.mordionJail = jail

jail.ZONE         = (xi.zone and xi.zone.MORDION_GAOL) or 131
jail.RELEASE_ZONE = (xi.zone and xi.zone.LOWER_JEUNO) or 245
-- Must match CLuaBaseEntity::resetPlayer (Lower Jeuno).
jail.RELEASE      = { 33.464, -5.000, 69.162, 86 }

-- Same 32 cells as scripts/commands/jail.lua (floor 1 then floor 2).
jail.cells =
{
    { -620,   11,  660 },
    { -180,   11,  660 },
    {  260,   11,  660 },
    {  700,   11,  660 },
    { -620,   11,  220 },
    { -180,   11,  220 },
    {  260,   11,  220 },
    {  700,   11,  220 },
    { -620,   11, -220 },
    { -180,   11, -220 },
    {  260,   11, -220 },
    {  700,   11, -220 },
    { -620,   11, -620 },
    { -180,   11, -620 },
    {  260,   11, -620 },
    {  700,   11, -620 },
    { -620, -400,  660 },
    { -180, -400,  660 },
    {  260, -400,  660 },
    {  700, -400,  660 },
    { -620, -400,  220 },
    { -180, -400,  220 },
    {  260, -400,  220 },
    {  700, -400,  220 },
    { -620, -400, -220 },
    { -180, -400, -220 },
    {  260, -400, -220 },
    {  700, -400, -220 },
    { -620, -400, -620 },
    { -180, -400, -620 },
    {  260, -400, -620 },
    {  700, -400, -620 },
}

function jail.cellId(value)
    local cell = math.floor(tonumber(value) or 1)
    if cell < 1 or cell > #jail.cells then
        return 1
    end

    return cell
end

function jail.cellDest(cellId)
    return jail.cells[jail.cellId(cellId)]
end

function jail.isJailedVar(value)
    return (tonumber(value) or 0) >= 1
end

function jail.isJailedPlayer(player)
    return player ~= nil and player.getCharVar ~= nil and jail.isJailedVar(player:getCharVar('inJail'))
end

function jail.refuseTravel(player)
    if not jail.isJailedPlayer(player) then
        return false
    end

    player:printToPlayer('You cannot leave Mordion Gaol.', xi.msg.channel.SYSTEM_3)
    return true
end

function jail.persistJail(charId, cellId)
    local dest = jail.cellDest(cellId)
    SendToJailOffline(charId, jail.cellId(cellId), dest[1], dest[2], dest[3], 0)
    return dest
end

function jail.disconnectSoon(player, message)
    if message then
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end

    player:timer(1000, function(p)
        if p and p.leaveGame then
            p:leaveGame()
        end
    end)
end

-- Online jail: write inJail + cell coords/zone to DB, align in-memory
-- xyz so logout SaveCharPosition cannot stamp the old world coords into
-- zone 131, then disconnect. Next login lands in the cell.
function jail.applyOnlineJail(player, cellId)
    cellId = jail.cellId(cellId)
    player:setCharVar('inJail', cellId)
    local dest = jail.persistJail(player:getID(), cellId)
    player:setPos(dest[1], dest[2], dest[3], 0)
    jail.disconnectSoon(player, 'You have been jailed. Log in again to serve your sentence.')
end

-- Online pardon: clear the flag, resetPlayer writes Lower Jeuno into
-- chars (no live zone-out), align xyz, then disconnect.
function jail.applyOnlinePardon(gm, player)
    player:setCharVar('inJail', 0)
    gm:resetPlayer(player:getName())
    local release = jail.RELEASE
    player:setPos(release[1], release[2], release[3], release[4])
    jail.disconnectSoon(player, 'You have been pardoned. Log in again in Lower Jeuno.')
end

function jail.applyOfflinePardon(gm, name)
    local charId = GetPlayerIDByName(name)
    if
        charId == nil or
        charId <= 0 or
        charId >= 0xFFFFFFFF
    then
        return false
    end

    SetCharVar(charId, 'inJail', 0)
    gm:resetPlayer(name)
    return true
end

-- If a jailed player is anywhere except Mordion (portal warp, leftover
-- escape, command warp), persist the cell and kick. Do not live-zone
-- them back — that is the crashy path.
function jail.enforceSentence(player)
    if not jail.isJailedPlayer(player) then
        return false
    end

    if player:getZoneID() == jail.ZONE then
        return false
    end

    local cellId = jail.cellId(player:getCharVar('inJail'))
    local dest   = jail.persistJail(player:getID(), cellId)
    player:setPos(dest[1], dest[2], dest[3], 0)
    jail.disconnectSoon(player, 'You are still serving a jail sentence. Log in again.')
    return true
end

return jail
