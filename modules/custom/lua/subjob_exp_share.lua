-----------------------------------
-- subjob_exp_share.lua
-- Awards the subjob a share of every EXP gain and levels it up in
-- the background, capped at the main job's current level.
--
-- Pure Lua - hooks the existing EXPERIENCE_POINTS event the C++
-- AddExperiencePoints() fires. No source edits, survives upstream
-- LSB updates.
--
-- Tuning:
--   SHARE_RATE  - fraction of main EXP that banks toward sub
--                  (0.5 = half rate)
--   _expToNext  - simple per-level threshold table. Values mirror
--                  the shape of the C++ exp_table; precision matters
--                  less for sub-job catch-up than pacing.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('subjob_exp_share')

-----------------------------------
-- Config
-----------------------------------
local SHARE_RATE = 0.5
local BANK_VAR   = 'SubExpBank'

-- Approximated exp-to-next-level. The real C++ table (sql/exp_table.sql)
-- has dozens of per-level values; this stepped formula tracks the same
-- shape closely enough that sub levels at ~half the main rate without
-- having to mirror the SQL table by hand. If you ever want exact parity,
-- replace this with a literal table of values.
local function _expToNext(level)
    if level <  20 then return level * 200
    elseif level < 40 then return level * 400
    elseif level < 60 then return level * 600
    elseif level < 75 then return level * 900
    else                  return level * 1100
    end
end

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
-- charutils::AddExperiencePoints).
-----------------------------------
local function _awardSubExp(player, mob, exp)
    if not exp or exp <= 0 then return end

    local sjob = player:getSubJob()
    if sjob == nil or sjob == xi.job.NONE then return end

    local mainLvl = player:getMainLvl()
    local subLvl  = player:getJobLevel(sjob)
    if subLvl >= mainLvl then return end -- already at cap

    local bank      = player:getCharVar(BANK_VAR) + math.floor(exp * SHARE_RATE)
    local threshold = _expToNext(subLvl)

    if bank >= threshold then
        local newLvl = subLvl + 1
        player:setsLevel(newLvl)
        bank = bank - threshold
        player:printToPlayer(
            string.format('Subjob %s reached level %d, kupo!',
                _jobAbbr[sjob] or tostring(sjob), newLvl),
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
