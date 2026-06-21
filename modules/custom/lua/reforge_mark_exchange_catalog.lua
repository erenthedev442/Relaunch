-----------------------------------
-- reforge_mark_exchange_catalog.lua
-- Config for the Reforge Mark Exchange vendor at Gwora-Corridor.
-- Lets players convert between Reforge mark types at a 2:1 rate,
-- removing the "dead inventory" feel when you have excess marks in
-- one track. Does not trivialize any track - the exchange tax is
-- intentional friction.
--
-- Rates: 2 AF = 1 Relic, 2 Relic = 1 Empy, 3 AF = 1 Empy (direct).
-----------------------------------
local catalog = {}

catalog.npcPos =
{
    zone     = 'Gwora-Corridor',
    zoneId   = xi.zone.GWORA_CORRIDOR,
    x        = 20.0,
    y        =  0.0,
    z        =  0.0,
    rotation =  128,
}

catalog.npcLook = 2430
catalog.npcName = 'Reforge Exchange'

-- Each exchange: spend 'cost' of 'from' currency, receive 1 of 'to'.
-- Players can enter how many batches they want (1–10 per menu visit).
catalog.exchanges =
{
    {
        id       = 'af_to_relic',
        label    = '2 AF->1 Relic',
        fromCv   = 'RF_AF_Marks',
        fromName = 'AF Marks',
        fromShort = 'AF',
        toCv     = 'RF_Relic_Marks',
        toName   = 'Relic Marks',
        toShort  = 'Relic',
        rate     = 2,  -- 2 from = 1 to
    },
    {
        id       = 'relic_to_empy',
        label    = '2 Relic->1 Empy',
        fromCv   = 'RF_Relic_Marks',
        fromName = 'Relic Marks',
        fromShort = 'Relic',
        toCv     = 'RF_Empy_Marks',
        toName   = 'Empy Marks',
        toShort  = 'Empy',
        rate     = 2,
    },
    {
        id       = 'af_to_empy',
        label    = '3 AF->1 Empy',
        fromCv   = 'RF_AF_Marks',
        fromName = 'AF Marks',
        fromShort = 'AF',
        toCv     = 'RF_Empy_Marks',
        toName   = 'Empy Marks',
        toShort  = 'Empy',
        rate     = 3,
    },
}

-- Batch sizes offered in the menu (how many 'to' units to receive per trade).
catalog.batchSizes = { 1, 5, 10, 25, 50 }

return catalog
