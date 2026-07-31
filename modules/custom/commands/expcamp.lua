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
-- Coords copied verbatim from the retired ExpCamp_Moogle.lua. One Aht Urhgan
-- camp (13 Bhaflau) still drops at the zone default (0,0,0); refine with !pos.
local camps =
{
    { '10-25 La Theine Plateau',     xi.zone.LA_THEINE_PLATEAU,      774.35,  29.00,  -18.57, 224 },
    { '10-25 Konschtat Highlands',   xi.zone.KONSCHTAT_HIGHLANDS,   -223.00,  71.07,  828.00,  32 },
    { '10-25 Tahrongi Canyon',       xi.zone.TAHRONGI_CANYON,       -160.00,  47.25,  647.11, 192 },
    { '15-30 Valkurm Dunes',         xi.zone.VALKURM_DUNES,          137.90,  -7.50,   97.00, 162 },
    { '25-40 Qufim Island',          xi.zone.QUFIM_ISLAND,          -251.98, -19.96,  298.21,  64 },
    { '30-45 Yuhtunga Jungle',       xi.zone.YUHTUNGA_JUNGLE,       -239.51,   0.00, -402.77,  64 },
    { '35-50 Yhoator Jungle',        xi.zone.YHOATOR_JUNGLE,         197.82,   0.00,  -81.82, 160 },
    { "45-60 Crawler's Nest",        xi.zone.CRAWLERS_NEST,          364.00, -32.20,  -22.03,  64 },
    { '45-60 Gustav Tunnel',         xi.zone.GUSTAV_TUNNEL,          296.68, -40.42,   64.68,  96 },
    { '50-60 Kuftal Tunnel',         xi.zone.KUFTAL_TUNNEL,          -16.84, -20.47, -237.00,   0 },
    { '50-60 Western Altepa Desert', xi.zone.WESTERN_ALTEPA_DESERT,  419.33,  -3.12,   11.68,  32 },
    { '60-75 The Boyahda Tree',      xi.zone.THE_BOYAHDA_TREE,        88.00, -15.00, -217.00,   0 },
    { '75-85 Bhaflau Thickets',      xi.zone.BHAFLAU_THICKETS,         0.00,   0.00,    0.00, 128 },
    { '75-85 Mount Zhayolm',         xi.zone.MOUNT_ZHAYOLM,          658.48, -27.4748, 314.4547, 102 },
    { '80-85 Misareaux Coast',       xi.zone.MISAREAUX_COAST,        488.4478, -22.1281, 260.9005, 180 },
    { '80-90 Caedarva Mire',         xi.zone.CAEDARVA_MIRE,          282.7048, -4.1514, -703.4025, 153 },
    { '85-95 Ceizak Battlegrounds',  xi.zone.CEIZAK_BATTLEGROUNDS,  332.8839,   0.3897,  136.2704,  69 },
    { '90-99 Yorcia Weald',          xi.zone.YORCIA_WEALD,          -183.76,   1.54,   69.93,  29 },
    { '90-99 Marjami Ravine',        xi.zone.MARJAMI_RAVINE,          367.30, -59.27,  145.73,  36 },
    { '90-99 North Gustaberg [S]',   xi.zone.NORTH_GUSTABERG_S,     -547.5531, 39.7761, 434.5975, 117 },
    { '95-99 Foret de Hennetiel',    xi.zone.FORET_DE_HENNETIEL,    -420.14,  -6.17,  181.50, 249 },
    { '95-99 Kamihr Drifts',         xi.zone.KAMIHR_DRIFTS,          210.00,  20.30,  315.00, 192 },
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
