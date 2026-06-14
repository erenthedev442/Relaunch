-----------------------------------
-- func: aura
-- desc: Preview independentAnimation effects on yourself -- a tuning aid for the
--       Ascension aura (modules/custom/lua/Ascension_Aura.lua). Audition effects
--       in-game, then drop the winners into that module's TIERS table.
--
-- Usage:
--   !aura <animId> [mode]                       -- play one effect on yourself
--   !aura sweep <mode> <startId> <endId> [secs] -- auto-cycle a range, ~secs each
--
-- Examples:
--   !aura 251 4                 -- the "hearts" emote (sanity check that it works)
--   !aura 122 0                 -- a magic-y glow (used on Archaic Gear / Peddlestox)
--   !aura sweep 2 1 60          -- walk job-ability auras 1..60 (the bloody ones!)
--   !aura sweep 0 1 60 2        -- walk spell-cast effects, 2s each
--
-- mode = the animation TYPE (which table animId indexes into):
--   0 CastSpell   2 Ability   4 Event2(emotes)   6 WeaponSkill   9 MonsterSkill
-- Dark / bloody / flashing looks tend to live in:
--   mode 2 -> job-ability self-auras (Berserk red glow, Blood Weapon, Last Resort...)
--   mode 0 -> dark-element casting swirls (purple/black)
--   mode 6 -> weaponskill bursts (some very bloody)
--   mode 9 -> monster TP-move effects (lots of menacing ones)
-- Sweep those modes, jot the ids you like, tell Claude, and we lock them into TIERS.
--
-- A sweep prints "id=N mode=M" as each plays so you can record the keepers. Running
-- ANY new !aura command stops a sweep in progress. Ranges are capped at 60 ids.
--
-- GM-only (permission 1). Lives in modules/custom/commands/ (ours, merge-safe).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'sssss',
}

-- Per-character sweep generation. Any new !aura bumps it; an in-flight sweep loop
-- stops the instant it sees a newer generation -- so sweeps never stack and a plain
-- "!aura <id>" doubles as a stop button.
local sweepGen = {}

local function sweepStep(player, name, gen, id, endId, mode, stepMs)
    if not player or sweepGen[name] ~= gen then
        return  -- entity gone, or superseded by a newer !aura command -- stop.
    end
    if id > endId then
        player:printToPlayer('[aura] sweep complete.')
        return
    end

    player:independentAnimation(player, id, mode)
    player:printToPlayer(string.format('[aura] id=%d  mode=%d', id, mode))
    player:timer(stepMs, function(p) sweepStep(p, name, gen, id + 1, endId, mode, stepMs) end)
end

commandObj.onTrigger = function(player, a1, a2, a3, a4, a5)
    local name = player:getName()
    sweepGen[name] = (sweepGen[name] or 0) + 1  -- any new command supersedes a running sweep
    local gen = sweepGen[name]

    if a1 == 'sweep' then
        local mode    = tonumber(a2)
        local startId = tonumber(a3)
        local endId   = tonumber(a4)
        local stepSec = tonumber(a5) or 2.5
        if not (mode and startId and endId) then
            player:printToPlayer('Usage: !aura sweep <mode> <startId> <endId> [secs]   (e.g. !aura sweep 2 1 60)')
            return
        end

        if endId < startId then endId = startId end
        if endId - startId > 60 then
            endId = startId + 60
            player:printToPlayer('[aura] range capped to 60 ids.')
        end
        local stepMs = math.max(800, math.floor(stepSec * 1000))

        player:printToPlayer(string.format('[aura] sweeping mode=%d ids %d..%d, %.1fs each. Run any !aura to stop.',
            mode, startId, endId, stepMs / 1000))
        sweepStep(player, name, gen, startId, endId, mode, stepMs)
        return
    end

    -- single-shot: !aura <animId> [mode]
    local animId = tonumber(a1)
    if not animId then
        player:printToPlayer('Usage: !aura <animId> [mode]   |   !aura sweep <mode> <startId> <endId> [secs]')
        return
    end
    local mode = tonumber(a2) or 0

    player:independentAnimation(player, animId, mode)
    player:printToPlayer(string.format('[aura] played animId=%d mode=%d on yourself.', animId, mode))
end

return commandObj
