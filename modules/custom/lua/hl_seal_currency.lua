-----------------------------------
-- hl_seal_currency.lua
--
-- Shared seal/medal currency consumption for the Hunting League vendors
-- (Armor / Weapons / Accessory NPCs at Escha - Zi'Tah).
--
-- THE BUG THIS FIXES: those NPCs checked affordability with
-- player:getItemCount(sealId) -- which counts the medal across EVERY
-- container (inventory, satchel, sack, case, mog safe, ...) and across
-- EVERY stack -- but then spent it with player:delItem(sealId, cost),
-- which only touches the FIRST matching stack of MAIN INVENTORY. Worse,
-- charutils::UpdateItem refuses (removes nothing, charutils.cpp:1919) when
-- the cost exceeds that one stack's quantity, and delItem's return value
-- was ignored. Net result: a player whose medals were in the mog safe, or
-- split across stacks (they cap at 99), got the gear for free.
--
-- take() removes the full amount across every stack and container that
-- getItemCount counts, and returns whether it actually succeeded. Callers
-- MUST treat a false return as "do not hand over the reward."
-----------------------------------
local M = {}

-- Remove exactly `amount` of `itemId` from the player, spanning all stacks
-- and all containers (0 .. MAX_CONTAINER_ID-1 == the same sweep
-- charutils::getItemCount uses). Returns true only if the full `amount` was
-- removed; on any shortfall it stops and returns false. Idempotent-safe: it
-- pre-checks the total so it never partially charges when you can't afford.
function M.take(player, itemId, amount)
    if not itemId or itemId == 0 or amount == nil or amount <= 0 then
        return true
    end

    -- Affordability gate (counts every container + stack).
    if player:getItemCount(itemId) < amount then
        return false
    end

    local remaining = amount

    -- MAX_CONTAINER_ID == 18, so valid container ids are 0..17.
    for container = 0, 17 do
        if remaining <= 0 then
            break
        end

        local stacks = player:findItems(itemId, container)
        if stacks and #stacks > 0 then
            -- Snapshot (slot, qty) before mutating: delItemAt can empty a slot,
            -- and we never want to read a stale item object mid-loop.
            local plan = {}
            for _, it in ipairs(stacks) do
                plan[#plan + 1] = { slot = it:getSlotID(), qty = it:getQuantity() }
            end

            for _, s in ipairs(plan) do
                if remaining <= 0 then
                    break
                end
                local take = math.min(s.qty, remaining)
                if take > 0 and player:delItemAt(itemId, take, container, s.slot) then
                    remaining = remaining - take
                end
            end
        end
    end

    return remaining <= 0
end

return M
