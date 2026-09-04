-----------------------------------
-- !expcamp [N]
-- Warps to a popular EXP camp. Replaces the old ExpCamp Moogle NPC in GM Home.
--   !expcamp        -- lists every camp with its number
--   !expcamp 4      -- warps to camp #4 (Valkurm Dunes)
-- Camps are ordered low -> high level; the leading "10-25" etc. is the band.
-- Available to all players (permission 0), like !maat / !henge.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

-- { label, zone, x, y, z, rot } -- index = the !expcamp number.
-- Camp packs (relocated in-zone IDs, band levels, HP, half-respawn) live in
-- modules/custom/sql/expcamp_camps.sql. New high-targid inserts are not used
-- -- those slots show as NPC / Moogle on stock clients.
local camps =
{
    { '10-25 La Theine Plateau',     xi.zone.LA_THEINE_PLATEAU,      656.9457,  31.6260,  108.5068,  47 },
    { '10-25 Konschtat Highlands',   xi.zone.KONSCHTAT_HIGHLANDS,   -260.5458,  67.3785,  797.6899,  69 },
    { '10-25 Tahrongi Canyon',       xi.zone.TAHRONGI_CANYON,       -158.2538,  32.0502,  444.5488, 165 },
    { '15-30 Valkurm Dunes',         xi.zone.VALKURM_DUNES,         -738.0605,  -6.1496,  153.7633, 189 },
    { '25-40 Qufim Island',          xi.zone.QUFIM_ISLAND,           230.1152, -19.5029,  382.9870, 254 },
    { '30-45 Yuhtunga Jungle',       xi.zone.YUHTUNGA_JUNGLE,       -239.5560,   0.3452, -368.9259,  67 },
    { '35-50 Yhoator Jungle',        xi.zone.YHOATOR_JUNGLE,         221.8787,   0.4050, -131.5556, 157 },
    { "45-60 Crawler's Nest",        xi.zone.CRAWLERS_NEST,         -197.5995,  -0.2526,  203.6516, 163 },
    { '45-60 Gustav Tunnel',         xi.zone.GUSTAV_TUNNEL,          -71.8600, -10.4545, -164.8775,  63 },
    { '50-60 Kuftal Tunnel',         xi.zone.KUFTAL_TUNNEL,          -16.84,   -20.47,   -237.00,     0 },
    { '50-60 Western Altepa Desert', xi.zone.WESTERN_ALTEPA_DESERT,  406.0418,   0.0847,   70.1115, 191 },
    { '60-75 The Boyahda Tree',      xi.zone.THE_BOYAHDA_TREE,        40.4716, -18.2355, -159.3638, 154 },
    { '75-85 Bhaflau Thickets',      xi.zone.BHAFLAU_THICKETS,         8.00,   -24.00,    140.00,   128 },
    { '75-85 Mount Zhayolm',         xi.zone.MOUNT_ZHAYOLM,          595.1096, -23.5038,  226.0535,  72 },
    { '80-85 Misareaux Coast',       xi.zone.MISAREAUX_COAST,        488.4478, -22.1281,  260.9005, 180 },
    { '80-90 Caedarva Mire',         xi.zone.CAEDARVA_MIRE,          231.1413,   0.5000, -548.0793, 128 },
    { '85-95 Ceizak Battlegrounds',  xi.zone.CEIZAK_BATTLEGROUNDS,   328.3083,   0.5443,   72.6138,  67 },
    { '90-99 Yorcia Weald',          xi.zone.YORCIA_WEALD,           398.3880,   0.0000,  446.1991, 224 },
    { '90-99 Marjami Ravine',        xi.zone.MARJAMI_RAVINE,         368.9198, -59.0928,  141.0159,   5 },
    { '90-99 North Gustaberg [S]',   xi.zone.NORTH_GUSTABERG_S,     -547.5531,  39.7761,  434.5975, 117 },
    { '95-99 Foret de Hennetiel',    xi.zone.FORET_DE_HENNETIEL,    -185.5345,  -2.1250,  548.4019,  47 },
    { '95-99 Kamihr Drifts',         xi.zone.KAMIHR_DRIFTS,          210.00,    20.30,    315.00,   192 },
}

commandObj.onTrigger = function(player, arg)
    local n    = tonumber(arg)
    local camp = n and camps[n] or nil
    if not camp then
        player:printToPlayer('Exp Camps -- warp with  !expcamp <number>:', xi.msg.channel.SYSTEM_3)
        for i, c in ipairs(camps) do
            player:printToPlayer(string.format('  %2d. %s', i, c[1]), xi.msg.channel.SYSTEM_3)
        end
        return
    end
    player:printToPlayer(string.format('Warping to %s, kupo!', camp[1]), xi.msg.channel.SYSTEM_3)
    player:setPos(camp[3], camp[4], camp[5], camp[6], camp[2])
end

return commandObj
