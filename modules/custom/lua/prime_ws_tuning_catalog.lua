-----------------------------------
-- Relaunch Prime weaponskill beta tuning
--
-- Only approved final Prime weapon stages are listed.  The fTP scale is
-- applied to a private copy of the WS parameter table at execution time, so
-- ordinary uses of shared WSs (for example Resolution) remain unchanged.
-----------------------------------

local catalog = {}

catalog.PRIME_WS_TUNING =
{
    [xi.weaponskill.MARU_KALA] =
    {
        name = 'Maru Kala', itemId = 21535, slot = xi.slot.MAIN, ftpScale = 5.54,
    },
    [xi.weaponskill.RUTHLESS_STROKE] =
    {
        name = 'Merciless Strike', itemId = 21590, slot = xi.slot.MAIN, ftpScale = 3.56,
    },
    [xi.weaponskill.IMPERATOR] =
    {
        name = 'Imperator', itemId = 21646, slot = xi.slot.MAIN, ftpScale = 4.50,
    },
    [xi.weaponskill.RESOLUTION] =
    {
        name = 'Resolution', itemId = 21653, slot = xi.slot.MAIN, ftpScale = 5.70,
    },
    [xi.weaponskill.BLITZ] =
    {
        name = 'Blitz', itemId = 21730, slot = xi.slot.MAIN, ftpScale = 1.33,
    },
    [xi.weaponskill.DISASTER] =
    {
        name = 'Disaster', itemId = 21785, slot = xi.slot.MAIN, ftpScale = 4.99,
    },
    [xi.weaponskill.ORIGIN] =
    {
        name = 'Origin', itemId = 21837, slot = xi.slot.MAIN, ftpScale = 4.93,
    },
    [xi.weaponskill.DIARMUID] =
    {
        name = 'Diarmuid', itemId = 21891, slot = xi.slot.MAIN, ftpScale = 2.80,
    },
    [xi.weaponskill.TACHI_MUMEI] =
    {
        name = 'Tachi: Mumei', itemId = 21986, slot = xi.slot.MAIN, ftpScale = 3.51,
    },
    [xi.weaponskill.DAGDA] =
    {
        name = 'Dagda', itemId = 22002, slot = xi.slot.MAIN, ftpScale = 2.55,
    },
    [xi.weaponskill.OSHALA] =
    {
        name = 'Oshala', itemId = 22106, slot = xi.slot.MAIN, ftpScale = 5.15,
    },
    [xi.weaponskill.SARV] =
    {
        name = 'Sarv', itemId = 22163, slot = xi.slot.RANGED, ftpScale = 6.20,
    },
    [xi.weaponskill.TERMINUS] =
    {
        name = 'Terminus', itemId = 22164, slot = xi.slot.RANGED, ftpScale = 11.85,
    },
}

catalog.getEntry = function(itemId, wsId, slot)
    local tuning = catalog.PRIME_WS_TUNING[wsId]
    if
        not tuning or
        tuning.itemId ~= itemId or
        tuning.slot ~= slot
    then
        return nil
    end

    return tuning
end

return catalog
