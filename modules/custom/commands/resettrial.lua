-----------------------------------
-- func: resettrial [player]
-- desc: [GM] Clear a STUCK Ascension Trial spawn flag so the Provenance Altar
--       stops insisting the trial boss is "already spawned" when it isn't.
--
--       Background: the Altar's "Face the Trial" option is gated on an in-memory
--       flag, xi._prestige_summonedTrial[charID] (set in Prestige_System.lua), so
--       a player can't stack two trial bosses at once. It's normally cleared when
--       the boss dies, the player leaves Provenance, falls, or idles out. But if
--       the boss despawns abnormally (zone reset / server hiccup) the flag can
--       stick with NO live mob -- and !killtrial can't help then, because it needs
--       a live mob to kill. The flag is keyed by the STABLE char id, so relogging
--       does NOT clear it. This clears it directly.
--
--       Usage:  !resettrial              -- clear your own stuck flag
--               !resettrial PlayerName    -- clear a named online player's flag
--       After clearing, commune with the Altar to summon the Trial boss again.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 's',
}

commandObj.onTrigger = function(player, targetName)
    local targ = player
    if targetName then
        targ = GetPlayerByName(targetName)
        if not targ then
            player:printToPlayer(string.format('[ResetTrial] Player "%s" not found (must be online).', targetName))
            return
        end
    end

    local tbl = xi._prestige_summonedTrial
    if not tbl then
        player:printToPlayer('[ResetTrial] The Ascension system has not initialised yet (no flag table) -- nothing to clear.')
        return
    end

    local pid = targ:getID()
    if tbl[pid] then
        tbl[pid] = nil
        player:printToPlayer(string.format(
            '[ResetTrial] Cleared the stuck Ascension Trial flag for %s. The Altar will let them face the Trial again.', targ:getName()))
        if targ:getID() ~= player:getID() then
            targ:printToPlayer('[Ascension] A GM reset your Trial spawn flag. Commune with the Altar to face the Trial again.', xi.msg.channel.SYSTEM_3)
        end
    else
        player:printToPlayer(string.format(
            '[ResetTrial] %s has no active Trial flag -- nothing to clear (you should already be able to summon).', targ:getName()))
    end
end

return commandObj
