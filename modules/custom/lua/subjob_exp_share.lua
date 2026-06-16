-----------------------------------
-- subjob_exp_share.lua
-- Awards the subjob a share of every EXP gain and levels it up in
-- the background, capped at the main job's current level.
--
-- Pure Lua - hooks the existing EXPERIENCE_POINTS event the C++
-- AddExperiencePoints() fires. No source edits, survives upstream
-- LSB updates.
--
-- HOW "50% of main" WORKS:
--   The sub banks SHARE_RATE (0.5) of every exp gain. To level a sub
--   at exactly half the main's pace, each sub-level must cost the SAME
--   exp the MAIN needs for that level (so half the inflow => half the
--   speed). EXP_TO_NEXT below therefore mirrors the server's real
--   `exp_base` table (what GetExpNEXTLevel reads), NOT an approximation.
--   The old stepped formula (level*N) ran 2-4x HIGHER than the real
--   curve above level ~15, so subs stalled at ~13-25% of main instead
--   of 50% - that was the "subjobs stopped leveling" bug.
--
-- CATCH-UP: a single exp gain drains the bank across as MANY levels as
--   it can afford (loop), so a big book/chain gain - or a backlog from
--   the old broken curve - resolves in one shot instead of 1 level per
--   kill.
--
-- BANK SCOPING: the bank is tied to the active sub job (SubExpBankJob).
--   Switching sub jobs starts the new sub's bank fresh, so you can't
--   bank exp on one sub and dump it into another.
--
-- Tuning:
--   SHARE_RATE - fraction of main EXP that banks toward sub (0.5 = half)
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('subjob_exp_share')

-----------------------------------
-- Config
-----------------------------------
local SHARE_RATE   = 0.5
local BANK_VAR     = 'SubExpBank'
local BANK_JOB_VAR = 'SubExpBankJob'

-- Exp to advance the sub from level L to L+1. Mirrors the live `exp_base`
-- table exactly (EXP_TO_NEXT[L] = exp_base[L+1] = what the MAIN job needs
-- for that level), so the sub tracks 50% of the main's true pace at every
-- level. Update this if exp_base is ever retuned. No level-99 entry: the
-- sub is hard-capped at the main's level (<= 99) before it could be used.
local EXP_TO_NEXT = {
    [1]=500,    [2]=750,    [3]=1000,   [4]=1250,   [5]=1500,
    [6]=1750,   [7]=2000,   [8]=2200,   [9]=2400,   [10]=2600,
    [11]=2800,  [12]=3000,  [13]=3200,  [14]=3400,  [15]=3600,
    [16]=3800,  [17]=4000,  [18]=4200,  [19]=4400,  [20]=4600,
    [21]=4800,  [22]=5000,  [23]=5100,  [24]=5200,  [25]=5300,
    [26]=5400,  [27]=5500,  [28]=5600,  [29]=5700,  [30]=5800,
    [31]=5900,  [32]=6000,  [33]=6100,  [34]=6200,  [35]=6300,
    [36]=6400,  [37]=6500,  [38]=6600,  [39]=6700,  [40]=6800,
    [41]=6900,  [42]=7000,  [43]=7100,  [44]=7200,  [45]=7300,
    [46]=7400,  [47]=7500,  [48]=7600,  [49]=7700,  [50]=7800,
    [51]=8000,  [52]=9200,  [53]=10400, [54]=11600, [55]=12800,
    [56]=14000, [57]=15200, [58]=16400, [59]=17600, [60]=18800,
    [61]=20000, [62]=21500, [63]=23000, [64]=24500, [65]=26000,
    [66]=27500, [67]=29000, [68]=30500, [69]=32000, [70]=34000,
    [71]=36000, [72]=38000, [73]=40000, [74]=42000, [75]=44000,
    [76]=44500, [77]=45000, [78]=45500, [79]=46000, [80]=46500,
    [81]=47000, [82]=47500, [83]=48000, [84]=48500, [85]=49000,
    [86]=49500, [87]=50000, [88]=50500, [89]=51000, [90]=51500,
    [91]=52000, [92]=52500, [93]=53000, [94]=53500, [95]=54000,
    [96]=54500, [97]=55000, [98]=55500,
}

-----------------------------------
-- Job name lookup for chat message
-----------------------------------
local _jobAbbr = {
    [xi.job.WAR] = 'WAR', [xi.job.MNK] = 'MNK', [xi.job.WHM] = 'WHM',
    [xi.job.BLM] = 'BLM', [xi.job.RDM] = 'RDM', [xi.job.THF] = 'THF',
    [xi.job.PLD] = 'PLD', [xi.job.DRK] = 'DRK', [xi.job.BST] = 'BST',
    [xi.job.BRD] = 'BRD', [xi.job.RNG] = 'RNG', [xi.job.SAM] = 'SAM',
    [xi.job.NIN] = 'NIN', [xi.job.DRG] = 'DRG', [xi.job.SMN] = 'SMN',
    [xi.job.BLU] = 'BLU', [xi.job.COR] = 'COR', [xi.job.PUP] = 'PUP',
    [xi.job.DNC] = 'DNC', [xi.job.SCH] = 'SCH', [xi.job.GEO] = 'GEO',
    [xi.job.RUN] = 'RUN',
}

-----------------------------------
-- Listener: fires on every EXP gain from any source
-- (mob kills, FoV/GoV books, ROE - anything that routes through
-- charutils::AddExperiencePoints, including merit/limit-mode exp at 99).
-----------------------------------
local function _awardSubExp(player, mob, exp)
    if not exp or exp <= 0 then return end

    local sjob = player:getSubJob()
    if sjob == nil or sjob == xi.job.NONE then return end

    local mainLvl = player:getMainLvl()
    local subLvl  = player:getJobLevel(sjob)
    if subLvl >= mainLvl then return end -- sub already at the main-level cap

    -- Scope the bank to the active sub job. Switching subs starts the new
    -- sub's bank fresh (no carrying banked exp between jobs). First run under
    -- this system (var unset, == 0) adopts the current sub WITHOUT wiping any
    -- bank already accumulated for it.
    local bankJob = player:getCharVar(BANK_JOB_VAR)
    if bankJob == 0 then
        player:setCharVar(BANK_JOB_VAR, sjob)
    elseif bankJob ~= sjob then
        player:setCharVar(BANK_VAR, 0)
        player:setCharVar(BANK_JOB_VAR, sjob)
    end

    local bank = player:getCharVar(BANK_VAR) + math.floor(exp * SHARE_RATE)

    -- Drain the bank across as many levels as it can afford, capped at the
    -- main job's level. Compute the final level first, then apply it with a
    -- single setsLevel() (each call rebuilds stats/skills, so we avoid N of
    -- them on a multi-level catch-up).
    local startLvl = subLvl
    while subLvl < mainLvl do
        local threshold = EXP_TO_NEXT[subLvl]
        if not threshold or bank < threshold then break end
        bank   = bank - threshold
        subLvl = subLvl + 1
    end

    if subLvl > startLvl then
        player:setsLevel(subLvl)
        player:printToPlayer(
            string.format('Your %s subjob is now level %d, kupo!',
                _jobAbbr[sjob] or tostring(sjob), subLvl),
            xi.msg.channel.SYSTEM_3
        )
    end

    player:setCharVar(BANK_VAR, bank)
end

-----------------------------------
-- Wire up the listener every time a player loads / zones.
-- A unique name per player isn't needed - same name re-registers
-- cleanly (LSB's addListener replaces a same-name binding).
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    player:addListener('EXPERIENCE_POINTS', 'SUBJOB_EXP_SHARE', _awardSubExp)
end)

return m
