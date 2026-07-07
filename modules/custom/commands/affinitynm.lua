-----------------------------------
-- !affinitynm [N | name]
-- Warps to any of the 24 Augment-Sage affinity NMs (for testing the affinity hunt).
--   !affinitynm            -- lists all 24 (number, NM, affinity, zone)
--   !affinitynm 4          -- warps to NM #4 (Simurgh / Accuracy)
--   !affinitynm simurgh    -- warps by name (partial, case-insensitive; matches NM or affinity)
-- Coords/zones come straight from modules/custom/sql/affinity_nm_spawns.sql.
-- These are 15-min timed spawns, so the NM is usually already up on arrival.
-- Permission 0 (all players), like !expcamp / !henge.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

-- { name, affinity, zoneName, zoneId, x, y, z } -- index = the !affinitynm number.
local nms =
{
    { 'Behemoth',         'STR',        'Batallia Downs',        105, -641.67, -23.00, 337.12 },
    { 'King Behemoth',    'Attack',     "Behemoth's Dominion",   127, -250.00, -20.00,   40.00 },
    { 'King Arthro',      'DEX',        'Kuftal Tunnel',         174,  -23.14, -10.69, -153.62 },
    { 'Simurgh',          'Accuracy',   'Rolanberry Fields',     110, -683.98, -31.00, -415.14 },
    { 'Adamantoise',      'VIT',        'Valley of Sorrows',     128,  -26.01, -0.42, -5.50 },
    { 'Genbu',            'Defense',    "Ru'Aun Gardens",        130,  247.62, -70.22, 497.76 },
    { 'Roc',              'AGI',        'Sauromugue Champaign',  120,  263.57, -0.01, -321.78 },
    { 'Seiryu',           'Evasion',    "Ru'Aun Gardens",        130,  549.17, -70.22, -79.92 },
    { 'Byakko',           'Haste',      "Ru'Aun Gardens",        130,  -396.54, -70.20, 388.56 },
    { 'Aspidochelone',    'INT',        'Cape Teriggan',         113, -156.82, 7.68, -221.20 },
    { 'Ouryu',            'Magic Atk',  'Riverne-Site B01',       29,  594.91, 0.56, -530.92 },
    { 'Bune',             'MND',        'The Boyahda Tree',      153,  374.00, 11.00, -105.00 },
    { 'Phoenix',          'Healing',    'Riverne-Site A01',       30,  685.00, -32.00, -481.00 },
    { 'Suzaku',           'CHR',        "Ru'Aun Gardens",        130,  -492.46, -70.22, -256.73 },
    { 'Kirin',            'Enmity',     "Shrine of Ru'Avitau",   178,  -68.00, 32.00, 3.50 },
    { 'Fafnir',           'HP',         "Dragon's Aery",         154,  46.00, 6.00, 18.00 },
    { 'Nidhogg',          'Regen',      "Dragon's Aery",         154,  46.00, 6.00, 24.00 },
    { 'Vrtra',            'MP',         "Ifrit's Cauldron",      205,  137.01, 0.90, -16.10 },
    { 'Tiamat',           'Refresh',    'Uleguerand Range',        5, -226.23, -39.88, -387.98 },
    { 'King Vinegarroon', 'Pet',        'Western Altepa Desert', 125,  -212.28, -0.23, -632.39 },
    { 'Khimaira',         'Ele Resist', "King Ranperre's Tomb",  190, -114.00, 0.00, 221.00 },
    { 'Cerberus',         'Status',     "King Ranperre's Tomb",  190, -130.78, -0.50, 222.42 },
    { 'Absolute Virtue',  'Skills',     "Ru'Aun Gardens",        130,   -5.57, -40.52, -385.21 },
    { 'Proto-Omega',      'WSD+',       "Ru'Aun Gardens",        130,    1.00, -34.00, -485.00 },
}

commandObj.onTrigger = function(player, arg)
    local SYS = xi.msg.channel.SYSTEM_3
    local entry

    local n = tonumber(arg)
    if n and nms[n] then
        entry = nms[n]
    elseif arg and arg ~= '' then
        local needle = string.lower(arg)
        for _, e in ipairs(nms) do
            if string.find(string.lower(e[1]), needle, 1, true)
                or string.find(string.lower(e[2]), needle, 1, true) then
                entry = e
                break
            end
        end
    end

    if not entry then
        player:printToPlayer('Affinity NMs -- warp with  !affinitynm <number|name>:', SYS)
        for i, e in ipairs(nms) do
            player:printToPlayer(string.format('  %2d. %-16s (%s) @ %s', i, e[1], e[2], e[3]), SYS)
        end
        return
    end

    player:printToPlayer(string.format('Warping to %s [%s affinity] in %s, kupo!', entry[1], entry[2], entry[3]), SYS)
    player:setPos(entry[5], entry[6], entry[7], 0, entry[4])
end

return commandObj
