-----------------------------------
-- func: phantomcheck [player]
-- desc: GM diagnostic -- reports the Phantom Roll+ (Mod::PHANTOM_ROLL) value the
--       ENGINE sees on a character's EQUIPPED gear, including the custom
--       "Phantom Roll effect" augment (augId 2046). Confirms whether the augment
--       is actually applying at runtime, independent of the (always-blank)
--       client augment label.
--
-- USAGE
--   !phantomcheck            -- check yourself
--   !phantomcheck Ceebee     -- check a named (online) player
--
-- It reads getMaxGearMod(PHANTOM_ROLL): the highest single-piece total (a piece's
-- 5 augment slots SUM). corsair.lua caps the roll bonus at min(this, 3) and adds
-- (the roll's phantomBase x cap) to every Phantom Roll's EFFECT POWER (not the d6
-- roll number).
--   0  -> NOT applying  (augment not equipped, not on this char, on a cape on an
--                        un-patched build, or the augment cache is stale)
--   3+ -> applying at the +3 cap (working as intended)
--
-- Auto-loads from custom/commands/ (init.txt) and hot-reloads with no restart.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM diagnostic. Set to 0 if you want players to self-check.
    parameters = 's', -- optional player name
}

local S = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, name)
    local targ = player
    if name and name ~= '' then
        targ = GetPlayerByName(name)
        if not targ then
            player:printToPlayer(string.format('[PhantomCheck] No player named "%s" is online.', name), S)
            return
        end
    end

    local total   = targ:getMod(xi.mod.PHANTOM_ROLL)   -- sum across all equipped pieces
    local perPiece = targ:getMaxGearMod(xi.mod.PHANTOM_ROLL) -- best single piece (diagnostic)

    player:printToPlayer(string.format('[PhantomCheck] %s: Phantom Roll+ total = %d (best single piece = %d).',
        targ:getName(), total, perPiece), S)

    if total <= 0 then
        player:printToPlayer('  => NOT applying: augment not equipped or augment cache is stale (needs a map restart).', S)
    else
        player:printToPlayer(string.format('  => Applying. Each Phantom Roll gains +%d x its base increment (e.g. Chaos Roll +%d%%ATT, Hunters Roll +%d ACC).',
            total, 3 * total, 5 * total), S)
        player:printToPlayer('  Note: the client augment label is always blank -- judge by the effect, not the tooltip.', S)
    end
end

return commandObj
