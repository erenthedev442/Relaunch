-----------------------------------
-- func: unstick
-- desc: Self-rescue from stuck event/sequence state.
--
--       Two-phase strategy with an 8-second grace window:
--
--         t=0s   release() + MH unlock flag set + status message.
--                This is the gentle path — most stuck states clear
--                from release() alone, and you get to stay where you
--                are if it worked.
--
--         t=8s   IF still in event state, warp to homepoint as a
--                fallback. The grace period gives client + server
--                time to process the release packets and lets you
--                cancel a misfire (the warp only fires if the gentle
--                release didn't take).
--
--       Macro-friendly. Set up a chat macro:
--
--           /system "!unstick"
--
--       ...and bind to a hotkey. Trigger anytime you feel wedged.
--       Works even if the chat window appears blocked by a cutscene
--       UI, because the macro sends the chat packet directly.
--
--       Self-only — no target arg, no permission gate.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local WARP_DELAY_MS = 8000
local MH_UNLOCKED_2F = 0x0020

commandObj.onTrigger = function(player)
    -- 1. Standard event release. If the player isn't actually stuck,
    --    this is harmless (release() is a no-op when no event is
    --    active).
    player:release()

    -- 2. Pre-set the moghouse 2F unlock flag so the auto-CS won't
    --    re-fire next zone-in. The vanilla code does this AFTER the
    --    cutscene triggers; we do it now to break the loop where a
    --    stuck player relogs straight back into the same CS.
    local mhFlag = player:getMoghouseFlag()
    if bit.band(mhFlag, MH_UNLOCKED_2F) == 0 then
        player:setMoghouseFlag(bit.bor(mhFlag, MH_UNLOCKED_2F))
    end

    player:printToPlayer(string.format(
        '[unstick] Released. Warping home in %d seconds if still stuck.',
        WARP_DELAY_MS / 1000 
    ))

    -- 3. Deferred warp. Only fires if the player is STILL in event
    --    state after the grace window. If the gentle release worked,
    --    we leave them in place — no surprise zone change. If they
    --    are still stuck, the warp is the bulletproof fallback that
    --    tears down all per-zone state via a zone change.
    player:timer(WARP_DELAY_MS, function(playerArg)
        if playerArg:isInEvent() then
            playerArg:printToPlayer('[unstick] Still stuck — warping home now.')
            playerArg:warp()
        else
            playerArg:printToPlayer('[unstick] Release worked, no warp needed.')
        end
    end)
end

return commandObj
