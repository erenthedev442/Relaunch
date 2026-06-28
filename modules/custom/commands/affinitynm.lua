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
    { 'Behemoth',         'STR',        'Batallia Downs',        105, -670.00, -23.00,  352.00 },
    { 'King Behemoth',    'Attack',     "Behemoth's Dominion",   127,  171.18,   4.29, -124.58 },
    { 'King Arthro',      'DEX',        'Kuftal Tunnel',         174,  -27.91, -10.69, -185.26 },
    { 'Simurgh',          'Accuracy',   'Rolanberry Fields',     110,  340.00,   0.38,  179.00 },
    { 'Adamantoise',      'VIT',        'Valley of Sorrows',     128,  -98.00,  -0.05,  -39.00 },
    { 'Genbu',            'Defense',    "Shrine of Ru'Avitau",   178,  892.85,  99.50,  718.02 },
    { 'Roc',              'AGI',        'Sauromugue Champaign',  120,  479.94,   7.67, -286.00 },
    { 'Seiryu',           'Evasion',    "Shrine of Ru'Avitau",   178,  901.36,  99.50,  695.60 },
    { 'Byakko',           'Haste',      "Shrine of Ru'Avitau",   178,  901.26,  99.50,  666.78 },
    { 'Aspidochelone',    'INT',        'Cape Teriggan',         113, -175.33,   7.68, -247.30 },
    { 'Ouryu',            'Magic Atk',  'Riverne-Site B01',       29,  618.78,   0.56, -552.23 },
    { 'Bune',             'MND',        'The Boyahda Tree',      153,  405.43,  11.40,  -98.61 },
    { 'Phoenix',          'Healing',    'Riverne-Site A01',       30,  682.74, -31.76, -500.81 },
    { 'Suzaku',           'CHR',        "Shrine of Ru'Avitau",   178,  882.13,  99.79,  648.93 },
    { 'Kirin',            'Enmity',     "Shrine of Ru'Avitau",   178,  866.85,  99.50,  622.56 },
    { 'Fafnir',           'HP',         "Dragon's Aery",         154,  -63.39,  -1.56,   16.26 },
    { 'Nidhogg',          'Regen',      "Dragon's Aery",         154,  -60.87,  -1.55,  -11.13 },
    { 'Vrtra',            'MP',         "Ifrit's Cauldron",      205,  168.79,   0.90,  -19.83 },
    { 'Tiamat',           'Refresh',    'Uleguerand Range',        5, -242.35, -39.88, -415.62 },
    { 'King Vinegarroon', 'Pet',        'Western Altepa Desert', 125,  683.42,  -0.78,  -41.82 },
    { 'Khimaira',         'Ele Resist', "King Ranperre's Tomb",  190, -124.00,  -0.50,  249.52 },
    { 'Cerberus',         'Status',     "King Ranperre's Tomb",  190, -147.00,  -0.50,  250.00 },
    { 'Absolute Virtue',  'Skills',     "Ru'Aun Gardens",        130,   -6.03, -40.52, -417.21 },
    { 'Proto-Omega',      'WSD+',       "Ru'Aun Gardens",        130,    6.84, -38.60, -444.97 },
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
