-----------------------------------
-- func: aura
-- desc: Preview an independentAnimation effect on yourself -- a tuning aid for
--       the Ascension aura (modules/custom/lua/Ascension_Aura.lua). Flip through
--       animation IDs / modes in-game to find ones that look good, then drop the
--       winners into that module's TIERS table.
--
-- Usage:
--   !aura <animId> [mode]   -- play effect <animId> with <mode> (default 0) on you
--   !aura 251 4             -- the "hearts" emote, for reference
--
-- Known starting points (walk the IDs up/down from here):
--   122 mode 0  -- a magic-y sparkle (used on Archaic Gear / Peddlestox)
--   250 mode 4  -- lightbulb      251 mode 4 -- hearts      252 mode 4 -- music notes
--
-- GM-only (permission 1). Lives in modules/custom/commands/ (ours, merge-safe).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ii',
}

commandObj.onTrigger = function(player, animId, mode)
    if not animId then
        player:printToPlayer('Usage: !aura <animId> [mode]   (e.g. !aura 122 0)')
        return
    end
    mode = mode or 0

    player:independentAnimation(player, animId, mode)
    player:printToPlayer(string.format('[aura] played animId=%d mode=%d on yourself.', animId, mode))
end

return commandObj
