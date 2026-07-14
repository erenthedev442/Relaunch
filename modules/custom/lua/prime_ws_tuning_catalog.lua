-----------------------------------
-- Relaunch Prime weaponskill pinnacle tuning
--
-- Only approved final Prime weapon stages are listed. Prime-native WSs receive
-- both their private fTP scale and a +300% WS-damage layer, then use a job-tier
-- cap above the universal 999,999 ceiling. Ordinary uses of shared WSs (for
-- example Resolution) remain unchanged.
-----------------------------------

local catalog = {}

catalog.DAMAGE_CAP_LOCAL_VAR = 'PrimeWsDamageCap'
catalog.WS_DAMAGE_BONUS      = 300

catalog.DAMAGE_CAPS =
{
    SUPPORT = 1499999,
    HYBRID  = 1749999,
    DAMAGE  = 1999999,
}

catalog.JOB_DAMAGE_CAP =
{
    [xi.job.WHM] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.BLM] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.PLD] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.SMN] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.PUP] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.SCH] = catalog.DAMAGE_CAPS.SUPPORT,
    [xi.job.GEO] = catalog.DAMAGE_CAPS.SUPPORT,

    [xi.job.RDM] = catalog.DAMAGE_CAPS.HYBRID,
    [xi.job.BRD] = catalog.DAMAGE_CAPS.HYBRID,
    [xi.job.BLU] = catalog.DAMAGE_CAPS.HYBRID,
    [xi.job.COR] = catalog.DAMAGE_CAPS.HYBRID,
    [xi.job.DNC] = catalog.DAMAGE_CAPS.HYBRID,
    [xi.job.RUN] = catalog.DAMAGE_CAPS.HYBRID,

    [xi.job.WAR] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.MNK] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.THF] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.DRK] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.BST] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.RNG] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.SAM] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.NIN] = catalog.DAMAGE_CAPS.DAMAGE,
    [xi.job.DRG] = catalog.DAMAGE_CAPS.DAMAGE,
}

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
    [xi.weaponskill.ZESHO_MEPPO] =
    {
        name = 'Zesho Meppo', itemId = 21932, slot = xi.slot.MAIN, ftpScale = 2.00,
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

catalog.getDamageCap = function(jobId)
    return catalog.JOB_DAMAGE_CAP[jobId] or catalog.DAMAGE_CAPS.SUPPORT
end

return catalog
