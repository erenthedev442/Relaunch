-----------------------------------
-- Area: Maquette_Abdhaljs-Legion_B (287)
-----------------------------------
zones = zones or {}

zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B] =
{
    text =
    {
        CARRIED_OVER_POINTS           = 7002, -- You have carried over <number> login point[/s].
        LOGIN_CAMPAIGN_UNDERWAY       = 7003, -- The [/January/February/March/April/May/June/July/August/September/October/November/December] <number> Login Campaign is currently underway!
        LOGIN_NUMBER                  = 7004, -- In celebration of your most recent login (login no. <number>), we have provided you with <number> points! You currently have a total of <number> points.
        MEMBERS_LEVELS_ARE_RESTRICTED = 7024, -- Your party is unable to participate because certain members' levels are restricted.
    },
    mob =
    {
        -- Ambuscade fight mobs (instance 30000 / zone 287)
        -- DB entries: ambuscade_adds.sql
        BOZZETTO_BREADWINNER  = 17952867,   -- pool 30000, group 38
        BOZZETTO_URCHIN_1     = 17952868,   -- pool 30003, group 20024
        BOZZETTO_URCHIN_2     = 17952869,
        BOZZETTO_URCHIN_3     = 17952870,
        BOZZETTO_URCHIN_4     = 17952871,
        AMBUSCADE_HOUSEMAKER  = 17952872,   -- pool 30004, group 20025
    },
    npc =
    {
    },
}

return zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]
