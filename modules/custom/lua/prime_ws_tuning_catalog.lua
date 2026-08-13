-----------------------------------
-- Relaunch Prime weaponskill pinnacle tuning
--
-- Only approved final Prime weapon stages are listed. Prime-native WSs receive
-- their private fTP scale, TP-scaled defense bypass, and a WS-damage layer,
-- then use a job-tier cap above the universal 999,999 ceiling. The tuning goal
-- is for a final Prime weapon's native WS to remain the strongest damage option
-- available to its jobs. Ordinary uses of shared WSs remain unchanged.
-----------------------------------

local catalog = {}

catalog.DAMAGE_CAP_LOCAL_VAR = 'PrimeWsDamageCap'
catalog.WS_DAMAGE_BONUS      = 300
catalog.AOE_DAMAGE_CAP       = 199999

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
        name = 'Maru Kala', itemId = 21535, slot = xi.slot.MAIN,
        ftpScale = 7.50, wsDamageBonus = 425, ignoredDefense = { 0.55, 0.80, 0.95 },
    },
    [xi.weaponskill.RUTHLESS_STROKE] =
    {
        name = 'Merciless Strike', itemId = 21590, slot = xi.slot.MAIN,
        ftpScale = 5.25, wsDamageBonus = 425, ignoredDefense = { 0.55, 0.80, 0.95 },
    },
    [xi.weaponskill.IMPERATOR] =
    {
        name = 'Imperator', itemId = 21646, slot = xi.slot.MAIN,
        ftpScale = 6.75, wsDamageBonus = 425, ignoredDefense = { 0.60, 0.85, 1.00 },
    },
    [xi.weaponskill.FIMBULVETR] =
    {
        name = 'Fimbulvetr', itemId = 21653, slot = xi.slot.MAIN,
        ftpScale = 7.50, wsDamageBonus = 425, ignoredDefense = { 0.45, 0.70, 0.90 },
    },
    [xi.weaponskill.BLITZ] =
    {
        name = 'Blitz', itemId = 21730, slot = xi.slot.MAIN,
        ftpScale = 1.85, wsDamageBonus = 425, ignoredDefense = { 0.45, 0.70, 0.90 },
    },
    [xi.weaponskill.DISASTER] =
    {
        name = 'Disaster', itemId = 21785, slot = xi.slot.MAIN,
        ftpScale = 7.25, wsDamageBonus = 450, ignoredDefense = { 0.60, 0.85, 1.00 },
    },
    [xi.weaponskill.ORIGIN] =
    {
        name = 'Origin', itemId = 21837, slot = xi.slot.MAIN,
        ftpScale = 7.15, wsDamageBonus = 450, ignoredDefense = { 0.60, 0.85, 1.00 },
    },
    [xi.weaponskill.DIARMUID] =
    {
        name = 'Diarmuid', itemId = 21891, slot = xi.slot.MAIN,
        ftpScale = 3.75, wsDamageBonus = 425, ignoredDefense = { 0.45, 0.70, 0.90 },
    },
    [xi.weaponskill.ZESHO_MEPPO] =
    {
        name = 'Zesho Meppo', itemId = 21932, slot = xi.slot.MAIN,
        ftpScale = 2.85, wsDamageBonus = 425, ignoredDefense = { 0.45, 0.70, 0.90 },
    },
    [xi.weaponskill.TACHI_MUMEI] =
    {
        name = 'Tachi: Mumei', itemId = 21986, slot = xi.slot.MAIN,
        ftpScale = 5.50, wsDamageBonus = 450, ignoredDefense = { 0.60, 0.85, 1.00 },
    },
    [xi.weaponskill.DAGDA] =
    {
        name = 'Dagda', itemId = 22002, slot = xi.slot.MAIN,
        ftpScale = 3.50, wsDamageBonus = 400, ignoredDefense = { 0.45, 0.70, 0.90 },
    },
    [xi.weaponskill.OSHALA] =
    {
        name = 'Oshala', itemId = 22106, slot = xi.slot.MAIN,
        ftpScale = 12.00, wsDamageBonus = 450, ignoredDefense = { 0.60, 0.85, 1.00 },
    },
    [xi.weaponskill.SARV] =
    {
        name = 'Sarv', itemId = 22163, slot = xi.slot.RANGED,
        ftpScale = 8.50, wsDamageBonus = 475, ignoredDefense = { 0.55, 0.80, 0.95 },
    },
    [xi.weaponskill.TERMINUS] =
    {
        name = 'Terminus', itemId = 22164, slot = xi.slot.RANGED,
        ftpScale = 15.50, wsDamageBonus = 450, ignoredDefense = { 0.55, 0.80, 0.95 },
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
