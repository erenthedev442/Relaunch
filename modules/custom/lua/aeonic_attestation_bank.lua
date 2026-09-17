-----------------------------------
-- Aeonic attestation bank
--
-- Attestations are retail Rare/Ex (one in inventory). A full Aeonic needs
-- 1 + 2 + 3 = 6 of the matching type, so bag-held drops made the weapon
-- impossible. While an Aeonic pilgrimage is active, matching attestations
-- are credited to the Weapon Forge instead of the bag, with chapter
-- progress printed to chat (e.g. 1/2 for Chapter II).
--
-- FileWatcher dofile discards return; mutate the cached table.
-----------------------------------
local KEY = 'modules/custom/lua/aeonic_attestation_bank'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

local forge = require('modules/custom/lua/weapon_forge_catalog')
local pilgrimage = require('modules/custom/lua/legendary_pilgrimage_catalog')

local SYS = xi.msg.channel.SYSTEM_3
local CHAPTER = { [0] = 'I', [1] = 'II', [2] = 'III' }

M.IDS = {
    1556, 1557, 1558, 1559, 1560, 1561, 1562,
    1563, 1564, 1565, 1566, 1567, 1568, 1569,
}

local ID_SET = {}
for _, id in ipairs(M.IDS) do
    ID_SET[id] = true
end
M.ID_SET = ID_SET

local function costs()
    return forge.aeonicCosts
end

function M.var(attestationId)
    return string.format('WF_AttestBank_%d', attestationId)
end

function M.isAttestation(itemId)
    return ID_SET[itemId] == true
end

function M.chainByAttestation(attestationId)
    for _, chain in ipairs(forge.chains) do
        if chain.aeonic.attestationId == attestationId then
            return chain
        end
    end
    return nil
end

function M.activeChain(player)
    if not player or not player.getCharVar then
        return nil
    end

    local idx = player:getCharVar('LWP_AeonicActive') or 0
    if idx <= 0 then
        return nil
    end

    local entry = pilgrimage.byIndex[idx]
    if not entry or entry.family ~= 'aeonic' then
        return nil
    end

    local chain = forge.chains[entry.familyIndex]
    if not chain or chain.aeonic.s3.id ~= entry.finalId then
        return nil
    end

    return chain, entry
end

function M.fromStage(player, chain)
    if not player or not chain then
        return 0
    end

    local finalId = chain.aeonic.s3.id
    return player:getCharVar(string.format('LWP_AeonicStage_%d', finalId)) or 0
end

function M.stepNeed(fromStage)
    local ac = costs()
    if fromStage == 0 then
        return ac.toStage1.attestations
    elseif fromStage == 1 then
        return ac.toStage2.attestations
    end

    return ac.toStage3.attestations
end

function M.get(player, attestationId)
    if not player or not attestationId then
        return 0
    end

    return player:getCharVar(M.var(attestationId)) or 0
end

function M.add(player, attestationId, qty)
    qty = qty or 1
    if not player or not attestationId or qty <= 0 then
        return M.get(player, attestationId)
    end

    local held = M.get(player, attestationId) + qty
    player:setCharVar(M.var(attestationId), held)
    return held
end

function M.invCount(player, attestationId)
    if not player or not player.getItemCount then
        return 0
    end

    return player:getItemCount(attestationId) or 0
end

function M.totalHave(player, attestationId)
    return M.get(player, attestationId) + M.invCount(player, attestationId)
end

function M.progressText(held, need, chapterName)
    if held >= need then
        local extra = held - need
        if extra > 0 then
            return string.format('%d/%d for Chapter %s. Extra %d held for later chapters.',
                need, need, chapterName, extra)
        end

        return string.format('%d/%d for Chapter %s.', need, need, chapterName)
    end

    return string.format('%d/%d for Chapter %s.', held, need, chapterName)
end

function M.statusText(player, chain)
    chain = chain or select(1, M.activeChain(player))
    if not chain then
        return nil
    end

    local attId = chain.aeonic.attestationId
    local held = M.totalHave(player, attId)
    local fromStage = M.fromStage(player, chain)
    local need = M.stepNeed(fromStage)
    local chapter = CHAPTER[fromStage] or '?'
    return string.format('[Weapon Forge] Holding %dx %s for %s (%s)',
        held, chain.aeonic.attestationName, chain.aeonic.s3.name,
        M.progressText(held, need, chapter))
end

function M.consume(player, attestationId, qty)
    qty = qty or 0
    if not player or not attestationId or qty <= 0 then
        return false
    end

    local bank = M.get(player, attestationId)
    local inv = M.invCount(player, attestationId)
    if bank + inv < qty then
        return false
    end

    local fromBank = math.min(bank, qty)
    local fromInv = qty - fromBank
    if fromBank > 0 then
        player:setCharVar(M.var(attestationId), bank - fromBank)
    end

    if fromInv > 0 then
        if not player:delItem(attestationId, fromInv) then
            player:setCharVar(M.var(attestationId), bank)
            return false
        end
    end

    return true
end

function M.depositInventory(player, attestationId)
    if not player or not attestationId then
        return 0
    end

    local moved = 0
    while M.invCount(player, attestationId) > 0 do
        if not player:delItem(attestationId, 1) then
            break
        end

        M.add(player, attestationId, 1)
        moved = moved + 1
    end

    return moved
end

function M.depositActive(player)
    local chain = select(1, M.activeChain(player))
    if not chain then
        return 0, chain
    end

    local moved = M.depositInventory(player, chain.aeonic.attestationId)
    return moved, chain
end

function M.grantDrop(player, attestationId)
    if not player or not M.isAttestation(attestationId) then
        return false
    end

    local chain = select(1, M.activeChain(player))
    if chain and chain.aeonic.attestationId == attestationId then
        local held = M.add(player, attestationId, 1)
        local fromStage = M.fromStage(player, chain)
        local need = M.stepNeed(fromStage)
        local chapter = CHAPTER[fromStage] or '?'
        player:printToPlayer(string.format(
            '[Geas Fete] %s sent to the Weapon Forge (%s)',
            chain.aeonic.attestationName, M.progressText(held, need, chapter)), SYS)
        return true
    end

    local name = (M.chainByAttestation(attestationId) or { aeonic = { attestationName = 'Attestation' } }).aeonic.attestationName
    if player.addItem and player:addItem({ id = attestationId, quantity = 1 }) then
        player:printToPlayer(string.format('[Geas Fete] Obtained: %s.', name), SYS)
        if chain then
            player:printToPlayer(string.format(
                '[Geas Fete] That attestation is not for %s -- the Weapon Forge only banks the matching type.',
                chain.aeonic.s3.name), SYS)
        end
        return true
    end

    player:printToPlayer(
        '[Geas Fete] An Attestation was lost -- you can only carry one of each. Begin the matching Aeonic pilgrimage so the Weapon Forge can hold them.',
        SYS)
    return false
end

function M.tryTradeDeposit(player, trade)
    local chain = select(1, M.activeChain(player))
    if not chain or not trade then
        return false
    end

    local attId = chain.aeonic.attestationId
    local qty = 0
    pcall(function()
        qty = trade:getItemQty(attId) or 0
    end)
    if qty < 1 then
        return false
    end

    local count = qty
    pcall(function()
        count = trade:getItemCount() or qty
    end)
    if count ~= qty then
        player:printToPlayer('[Weapon Forge] Trade only the matching attestation.', SYS)
        return true
    end

    player:tradeComplete()
    local held = M.add(player, attId, qty)
    local fromStage = M.fromStage(player, chain)
    local need = M.stepNeed(fromStage)
    local chapter = CHAPTER[fromStage] or '?'
    player:printToPlayer(string.format(
        '[Weapon Forge] Received %dx %s (%s)',
        qty, chain.aeonic.attestationName, M.progressText(held, need, chapter)), SYS)
    return true
end

return M
