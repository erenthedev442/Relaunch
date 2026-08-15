-----------------------------------
-- !forgegates
--
-- Prints every Weapon Forge stage gate + this player's met / not-met status.
-- Same labels + check functions the Weapon Forge NPC uses (both read
-- modules/custom/lua/weapon_forge_gates.lua) so what the command says can
-- never drift from what the forge enforces.
--
-- Usage: !forgegates [category]
--   No arg    -> every category with new gates (relic, empyrean, mythic,
--                aeonic, prime) in widget order.
--   Category  -> just that category. Case-insensitive; unknown names fall
--                back to the full list.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local function label(cat)
    local GATES = require('modules/custom/lua/weapon_forge_gates')
    return GATES.CATEGORY_LABELS[cat] or cat
end

commandObj.onTrigger = function(player, catArg)
    local SYS   = xi.msg.channel.SYSTEM_3
    local GATES = require('modules/custom/lua/weapon_forge_gates')
    local forgeCatalog = require('modules/custom/lua/weapon_forge_catalog')
local pilgrimageCatalog = require('modules/custom/lua/legendary_pilgrimage_catalog')

    -- Filter to a single category if the player passed one.
    local cats
    if catArg and catArg ~= '' then
        local wanted = catArg:lower()
        if GATES.STAGE_GATES[wanted] then
            cats = { wanted }
        else
            player:printToPlayer(
                string.format('[Forge Gates] Unknown category "%s". Showing everything.', catArg),
                SYS)
            cats = GATES.DISPLAY_ORDER
        end
    else
        cats = GATES.DISPLAY_ORDER
    end

    local met, total = 0, 0
    player:printToPlayer('[Forge Gates] Progression toward every Weapon Forge stage gate:', SYS)
    for _, cat in ipairs(cats) do
        local rows = GATES.STAGE_GATES[cat]
        if not rows or (rows[0] == nil and rows[1] == nil and rows[2] == nil) then
            player:printToPlayer(string.format('  %s: no new gates (existing checks only).', label(cat)), SYS)
        else
            player:printToPlayer(string.format('  %s', label(cat)), SYS)
            for i = 0, 2 do
                local gate = rows[i]
                if gate then
                    if cat == 'aeonic' and i == 2 then
                        local found = false
                        for _, chain in ipairs(forgeCatalog.chains) do
                            local entry = pilgrimageCatalog.byFinalId[chain.aeonic.s3.id]
                            if
                                player:getCharVar('LWP_AeonicActive') == entry.index and
                                (player:getCharVar(string.format('LWP_AeonicStage_%d', chain.aeonic.s3.id)) or 0) >= 2
                            then
                                found = true
                                total = total + 1
                                local ok = gate.check(player, chain)
                                if ok then met = met + 1 end
                                player:printToPlayer(
                                    string.format('    Stage III [%s] %s: %s',
                                        ok and '✓' or '✗', chain.aeonic.s3.name, gate.label),
                                    SYS)
                            end
                        end
                        if not found then
                            total = total + 1
                            player:printToPlayer(
                                string.format('    Stage III [✗] %s (complete Chapters I and II of an Aeonic pilgrimage)',
                                    gate.label),
                                SYS)
                        end
                    else
                        total = total + 1
                        local ok = gate.check(player)
                        if ok then met = met + 1 end
                        player:printToPlayer(
                            string.format('    Stage %s [%s] %s',
                                ({[0]='I',[1]='II',[2]='III'})[i], ok and '✓' or '✗', gate.label),
                            SYS)
                    end
                end
            end
        end
    end
    if total > 0 then
        player:printToPlayer(
            string.format('[Forge Gates] Met %d of %d gate(s).', met, total),
            SYS)
    end
end

return commandObj
