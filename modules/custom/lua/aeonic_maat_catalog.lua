-----------------------------------
-- Weapon-specific Aeonic Maat trials.
--
-- The challenger must reach the matching Empowered pilgrimage milestone and
-- enter on one of the jobs listed for that Aeonic. Maat mirrors that exact current job while
-- the weapon profile supplies the encounter's unique mechanic.
-----------------------------------
local M = {}

M.trials =
{
    {
        finalId = 20515, name = 'Godhands',
        jobs = { xi.job.MNK, xi.job.PUP },
        mechanic = 'momentum',
        mechanicLabel = 'Relentless Momentum',
    },
    {
        finalId = 20594, name = 'Aeneas',
        jobs = { xi.job.THF, xi.job.BRD, xi.job.DNC },
        mechanic = 'performance',
        mechanicLabel = 'Deadly Performance',
    },
    {
        finalId = 20695, name = 'Sequence',
        jobs = { xi.job.RDM, xi.job.PLD, xi.job.BLU, xi.job.RUN },
        mechanic = 'rune_cycle',
        mechanicLabel = 'Runic Reversal',
    },
    {
        finalId = 21694, name = 'Lionheart',
        jobs = { xi.job.WAR, xi.job.DRK },
        mechanic = 'doom_brand',
        mechanicLabel = 'Lionheart Brand',
    },
    {
        finalId = 21753, name = 'Tri-edge',
        jobs = { xi.job.WAR, xi.job.BST },
        mechanic = 'beast_rage',
        mechanicLabel = 'Primal Dominion',
    },
    {
        finalId = 20843, name = 'Chango',
        jobs = { xi.job.WAR },
        mechanic = 'war_cry',
        mechanicLabel = 'Unbroken Warcry',
    },
    {
        finalId = 20890, name = 'Anguta',
        jobs = { xi.job.DRK },
        mechanic = 'dread_cycle',
        mechanicLabel = 'Dread Covenant',
    },
    {
        finalId = 20935, name = 'Trishula',
        jobs = { xi.job.DRG },
        mechanic = 'sky_assault',
        mechanicLabel = 'Skybreaker',
    },
    {
        finalId = 20977, name = 'Heishi Shorinken',
        jobs = { xi.job.NIN },
        mechanic = 'shadow_wheel',
        mechanicLabel = 'Wheel of Shadows',
    },
    {
        finalId = 21025, name = 'Dojikiri Yasutsuna',
        jobs = { xi.job.SAM },
        mechanic = 'skillchain',
        mechanicLabel = 'Perfect Skillchain',
    },
    {
        finalId = 21082, name = 'Tishtrya',
        jobs = { xi.job.WHM, xi.job.GEO },
        mechanic = 'sanctuary',
        mechanicLabel = 'Shifting Sanctuary',
    },
    {
        finalId = 21147, name = 'Khatvanga',
        jobs = { xi.job.BLM, xi.job.SMN, xi.job.SCH },
        mechanic = 'grimoire',
        mechanicLabel = 'Forbidden Grimoire',
    },
    {
        finalId = 22117, name = 'Fail-not',
        jobs = { xi.job.RNG },
        mechanic = 'deadzone',
        mechanicLabel = "Archer's Deadzone",
    },
    {
        finalId = 21485, name = 'Fomalhaut',
        jobs = { xi.job.COR, xi.job.RNG },
        mechanic = 'crooked_roll',
        mechanicLabel = 'Crooked Fortune',
    },
}

M.byFinalId = {}
for _, trial in ipairs(M.trials) do
    M.byFinalId[trial.finalId] = trial
end

M.jobNames =
{
    [xi.job.WAR] = 'WAR', [xi.job.MNK] = 'MNK', [xi.job.WHM] = 'WHM',
    [xi.job.BLM] = 'BLM', [xi.job.RDM] = 'RDM', [xi.job.THF] = 'THF',
    [xi.job.PLD] = 'PLD', [xi.job.DRK] = 'DRK', [xi.job.BST] = 'BST',
    [xi.job.BRD] = 'BRD', [xi.job.RNG] = 'RNG', [xi.job.SAM] = 'SAM',
    [xi.job.NIN] = 'NIN', [xi.job.DRG] = 'DRG', [xi.job.SMN] = 'SMN',
    [xi.job.BLU] = 'BLU', [xi.job.COR] = 'COR', [xi.job.PUP] = 'PUP',
    [xi.job.DNC] = 'DNC', [xi.job.SCH] = 'SCH', [xi.job.GEO] = 'GEO',
    [xi.job.RUN] = 'RUN',
}

function M.allowsJob(trial, jobId)
    if not trial then return false end
    for _, allowedJob in ipairs(trial.jobs or {}) do
        if allowedJob == jobId then
            return true
        end
    end
    return false
end

function M.jobList(trial)
    local names = {}
    for _, jobId in ipairs((trial and trial.jobs) or {}) do
        names[#names + 1] = M.jobNames[jobId] or tostring(jobId)
    end
    return table.concat(names, '/')
end

function M.completionVar(finalId)
    return string.format('AeonicMaat_%d', finalId or 0)
end

function M.bestTimeVar(finalId)
    return string.format('AeonicMaatBest_%d', finalId or 0)
end

function M.isComplete(player, finalId)
    return (player:getCharVar(M.completionVar(finalId)) or 0) > 0
end

function M.isReady(player, trial)
    return trial and (player:getCharVar(string.format('LWP_AeonicStage_%d', trial.finalId)) or 0) >= 2
end

function M.isGrouped(player)
    local grouped = false
    pcall(function()
        for _, member in ipairs(player:getParty() or {}) do
            if member:isPC() and member:getID() ~= player:getID() then
                grouped = true
            end
        end
    end)
    pcall(function()
        for _, member in ipairs(player:getAlliance() or {}) do
            if member:isPC() and member:getID() ~= player:getID() then
                grouped = true
            end
        end
    end)
    return grouped
end

function M.canEnter(player, trial)
    if not trial then return false, 'invalid_trial' end
    if M.isGrouped(player) then return false, 'grouped' end
    if not M.allowsJob(trial, player:getMainJob()) then return false, 'wrong_job' end
    if not M.isReady(player, trial) then return false, 'not_empowered' end
    return true, nil
end

return M
