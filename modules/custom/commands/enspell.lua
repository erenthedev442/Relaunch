-----------------------------------
-- func: enspell
-- desc: GM diagnostic -- dump a player's live enspell mods and compare the
--       ENSPELL_DMG_BONUS the engine actually sees against what Ascension +
--       Rebirth SHOULD be granting (from their CharVars). If "live" is far
--       below "expected", the boost isn't being applied (a real bug); if it
--       matches/exceeds, the enspell math is fine and the weakness is elsewhere
--       (proc chance, resists, Composure, comparison, ...).
--
-- Usage:
--   !enspell            -- yourself
--   !enspell Jbae       -- a named online player
--
-- Read-only. Hot-reloads (command file) -- no restart.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM
    parameters = 's',
}

local SYS = xi.msg.channel.SYSTEM_3

-- Safe getMod: tolerate a missing xi.mod field (returns 0 rather than erroring).
local function modOf(t, name)
    local id = xi.mod[name]
    if id == nil then return 0 end
    return t:getMod(id)
end

commandObj.onTrigger = function(player, targetName)
    local t = player
    if targetName and targetName ~= '' then
        t = GetPlayerByName(targetName)
        if not t then
            player:printToPlayer(string.format('[Enspell] "%s" not found / not online.', targetName), SYS)
            return
        end
    end

    local job = t:getMainJob()

    -- Live engine values.
    local liveBonus = modOf(t, 'ENSPELL_DMG_BONUS')   -- 432, flat +dmg (your rebirth/ascension points)
    local accum     = modOf(t, 'ENSPELL_DMG')         -- 343, Tier-2 potency accumulator
    local pct       = modOf(t, 'ENSPELL_DMG_PCT')     -- 1195, % multiplier
    local etype     = modOf(t, 'ENSPELL')             -- 341, active enspell type (0 = none)
    local chance    = modOf(t, 'ENSPELL_CHANCE')      -- 856, 0 = 100% proc

    -- What Ascension + Rebirth SHOULD be granting (10 ENSPELL_DMG_BONUS / level).
    local ascLv = t:getCharVar('Prestige_Cat_' .. job .. '_ENSP') or 0
    local rebLv = t:getCharVar('Rebirth_Cat_' .. job .. '_ENSP') or 0
    local expected = (ascLv + rebLv) * 10
    local other    = liveBonus - expected   -- gear / augments / merits (should be >= 0)

    -- Effective Enhancing Magic skill + the Tier-2 potency cap the engine uses.
    local skill = t:getSkillLevel(xi.skill.ENHANCING_MAGIC)
    local cap
    if skill > 200 then
        cap = 5 + math.floor(5 * skill / 100)
    else
        cap = 3 + math.floor(6 * skill / 100)
    end
    cap = cap * 2

    player:printToPlayer(string.format('=== Enspell diagnostic: %s (job %d) ===', t:getName(), job), SYS)
    player:printToPlayer(string.format('  ENSPELL_DMG_BONUS (live) = %d   |   expected from points = %d', liveBonus, expected), SYS)
    player:printToPlayer(string.format('    Ascension ENSP lv %d (+%d)  +  Rebirth ENSP lv %d (+%d)', ascLv, ascLv * 10, rebLv, rebLv * 10), SYS)
    player:printToPlayer(string.format('    gear/augments/other = %d  %s', other,
        other < 0 and '<<< NEGATIVE: points are NOT fully applied (BUG)' or 'ok'), SYS)
    player:printToPlayer(string.format('  Enhancing skill = %d  ->  Tier-2 potency cap = %d', skill, cap), SYS)
    player:printToPlayer(string.format('  ENSPELL_DMG (accum)=%d  ENSPELL_DMG_PCT=%d  ENSPELL(type)=%d  ENSPELL_CHANCE=%d', accum, pct, etype, chance), SYS)
    player:printToPlayer(string.format('  Approx Tier-2 base/hit = min(accum,%d) + %d bonus = ~%d, then x(1 + pct%% + Composure).',
        cap, liveBonus, math.min(accum, cap) + liveBonus), SYS)
end

return commandObj
