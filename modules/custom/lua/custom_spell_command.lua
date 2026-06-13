-----------------------------------
-- custom_spell_command.lua
--
-- Shared gate/charge logic for the custom-spell chat commands
-- (!aegis, !convergence). Custom spells (IDs >= 1020) have no entry in
-- the stock client's spell database, so the client refuses to hard-cast
-- them ("a command error occurred"). These commands run the real
-- server-side spell effect instead, gated to mirror each spell's own
-- learn requirement, job/level, MP cost and recast timer.
--
-- This is a plain require()-library (returns a table), NOT a Module. It
-- lives in custom/lua/ alongside the other shared libs (hl_seal_currency,
-- the catalogs). Because everything under custom/lua/ is auto-loaded at
-- startup, NOTHING here may touch xi.* at file scope -- all xi.* lookups
-- happen inside the functions, which only run at command time.
--
-- cfg shape (built by the command file, where xi.* is available):
--   {
--     name    = 'Divine Aegis',         -- display name
--     spellId = 1020,                   -- must be learned (hasSpell) to use
--     jobs    = { [xi.job.PLD] = 50 },  -- mainJobId -> min main-job level
--     reqText = 'PLD 50',               -- human-readable requirement string
--     mp      = 80,                     -- MP cost
--     recast  = 120,                    -- recast in SECONDS
--     cdVar   = 'cmdspell_aegis_cd',    -- per-player localVar for the cooldown
--   }
-----------------------------------
local M = {}

-----------------------------------
-- Returns true if the player may cast now. On false it prints the reason
-- and the caller should bail. Charges nothing -- call M.commit() only after
-- the effect actually fires.
-----------------------------------
function M.check(player, cfg)
    local CH = xi.msg.channel.SYSTEM_3

    -- Must have learned the spell (i.e. bought + used the scroll).
    if not player:hasSpell(cfg.spellId) then
        player:printToPlayer(
            string.format('%s: you have not learned this spell. Buy its scroll from the Accessories NPC in Reisenjima Henge.', cfg.name),
            CH)
        return false
    end

    -- Main job + level gate (mirrors the spell's jobs/level requirement).
    local need = cfg.jobs[player:getMainJob()]
    if not need or player:getMainLvl() < need then
        player:printToPlayer(string.format('%s requires %s as your main job.', cfg.name, cfg.reqText), CH)
        return false
    end

    -- Recast cooldown (server time, in seconds). Unset localVar reads as 0.
    local remain = player:getLocalVar(cfg.cdVar) - os.time()
    if remain > 0 then
        player:printToPlayer(string.format('%s is recharging (%ds left).', cfg.name, remain), CH)
        return false
    end

    -- MP cost.
    if player:getMP() < cfg.mp then
        player:printToPlayer(string.format('%s needs %d MP (you have %d).', cfg.name, cfg.mp, player:getMP()), CH)
        return false
    end

    return true
end

-----------------------------------
-- Charge MP + start the recast. Call once, only after the effect fired.
-----------------------------------
function M.commit(player, cfg)
    player:delMP(cfg.mp)
    player:setLocalVar(cfg.cdVar, os.time() + cfg.recast)
end

return M
