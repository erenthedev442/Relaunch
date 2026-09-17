local bank = require('modules/custom/lua/aeonic_attestation_bank')
local forge = require('modules/custom/lua/weapon_forge_catalog')
local pilgrimage = require('modules/custom/lua/legendary_pilgrimage_catalog')

local function makePlayer(opts)
    opts = opts or {}
    local vars = opts.vars or {}
    local items = opts.items or {}
    local chat = {}
    local player = {}

    function player:getCharVar(name)
        return vars[name] or 0
    end

    function player:setCharVar(name, value)
        vars[name] = value
    end

    function player:getItemCount(itemId)
        return items[itemId] or 0
    end

    function player:delItem(itemId, qty)
        local have = items[itemId] or 0
        if have < qty then
            return false
        end
        items[itemId] = have - qty
        return true
    end

    function player:addItem(payload)
        local itemId = payload.id
        if (items[itemId] or 0) > 0 then
            return false
        end
        items[itemId] = (items[itemId] or 0) + (payload.quantity or 1)
        return true
    end

    function player:printToPlayer(text)
        chat[#chat + 1] = text
    end

    function player:tradeComplete()
        player.traded = true
    end

    player.vars = vars
    player.items = items
    player.chat = chat
    return player
end

describe('Aeonic attestation bank', function()
    it('maps every forge attestation id and needs six matching pieces', function()
        assert(#bank.IDS == 14)
        assert(forge.aeonicCosts.toStage1.attestations
            + forge.aeonicCosts.toStage2.attestations
            + forge.aeonicCosts.toStage3.attestations == 6)

        for _, chain in ipairs(forge.chains) do
            assert(bank.isAttestation(chain.aeonic.attestationId))
            assert(bank.chainByAttestation(chain.aeonic.attestationId) == chain)
        end
    end)

    it('banks matching drops while an Aeonic pilgrimage is active', function()
        local chain = forge.chains[1]
        local entry = pilgrimage.byFinalId[chain.aeonic.s3.id]
        local player = makePlayer({
            vars = { LWP_AeonicActive = entry.index },
        })

        assert(bank.grantDrop(player, chain.aeonic.attestationId))
        assert(bank.get(player, chain.aeonic.attestationId) == 1)
        assert((player.items[chain.aeonic.attestationId] or 0) == 0)
        assert(player.chat[1]:find('1/1 for Chapter I', 1, true))
        assert(player.chat[1]:find('sent to the Weapon Forge', 1, true))
    end)

    it('prints 1/2 then 2/2 for Chapter II', function()
        local chain = forge.chains[2]
        local entry = pilgrimage.byFinalId[chain.aeonic.s3.id]
        local player = makePlayer({
            vars = {
                LWP_AeonicActive = entry.index,
                [string.format('LWP_AeonicStage_%d', chain.aeonic.s3.id)] = 1,
            },
        })

        bank.grantDrop(player, chain.aeonic.attestationId)
        assert(player.chat[#player.chat]:find('1/2 for Chapter II', 1, true))
        bank.grantDrop(player, chain.aeonic.attestationId)
        assert(player.chat[#player.chat]:find('2/2 for Chapter II', 1, true))
        assert(bank.get(player, chain.aeonic.attestationId) == 2)
    end)

    it('keeps surplus for later chapters instead of overflowing the bag', function()
        local chain = forge.chains[3]
        local entry = pilgrimage.byFinalId[chain.aeonic.s3.id]
        local player = makePlayer({
            vars = { LWP_AeonicActive = entry.index },
        })

        for _ = 1, 4 do
            bank.grantDrop(player, chain.aeonic.attestationId)
        end

        assert(bank.get(player, chain.aeonic.attestationId) == 4)
        assert(player.chat[#player.chat]:find('Extra 3 held for later chapters', 1, true))
    end)

    it('does not bank a mismatched attestation type', function()
        local chain = forge.chains[1]
        local other = forge.chains[2]
        local entry = pilgrimage.byFinalId[chain.aeonic.s3.id]
        local player = makePlayer({
            vars = { LWP_AeonicActive = entry.index },
        })

        assert(bank.grantDrop(player, other.aeonic.attestationId))
        assert(bank.get(player, other.aeonic.attestationId) == 0)
        assert(player.items[other.aeonic.attestationId] == 1)
        assert(player.chat[2]:find('not for Godhands', 1, true))
    end)

    it('consumes the forge bank before leftover inventory', function()
        local attId = forge.chains[1].aeonic.attestationId
        local player = makePlayer({
            vars = { [bank.var(attId)] = 2 },
            items = { [attId] = 1 },
        })

        assert(bank.totalHave(player, attId) == 3)
        assert(bank.consume(player, attId, 2))
        assert(bank.get(player, attId) == 0)
        assert(player.items[attId] == 1)
        assert(bank.consume(player, attId, 1))
        assert(player.items[attId] == 0)
        assert(not bank.consume(player, attId, 1))
    end)

    it('scoops a bag-held matching attestation into the forge bank', function()
        local chain = forge.chains[4]
        local entry = pilgrimage.byFinalId[chain.aeonic.s3.id]
        local attId = chain.aeonic.attestationId
        local player = makePlayer({
            vars = { LWP_AeonicActive = entry.index },
            items = { [attId] = 1 },
        })

        local moved = bank.depositActive(player)
        assert(moved == 1)
        assert(bank.get(player, attId) == 1)
        assert(player.items[attId] == 0)
    end)
end)
