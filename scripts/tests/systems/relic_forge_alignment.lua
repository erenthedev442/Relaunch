local forge = require('modules/custom/lua/relic_forge_catalog')
local rema  = require('modules/custom/lua/rema_ws_tier_catalog')
local prime = require('modules/custom/lua/prime_ws_tuning_catalog')
local weaponForge = require('modules/custom/lua/weapon_forge_catalog')

describe('Relic Forge identifier alignment', function()
    it('forges the fourteen exact Relic 119 III damage items', function()
        assert(#forge.weapons == 16)

        for index = 1, 14 do
            local forged = forge.weapons[index]
            local entry = rema.BY_ITEM_ID[forged.id]
            assert(entry ~= nil, string.format('Missing REMA entry for %s', forged.name))
            assert(entry.family == 'RELIC')
            assert(entry.name == forged.name)
            assert(entry.enabled)
        end
    end)

    it('never reuses a Stage-5 Prime identifier', function()
        local primeIds = {}
        for _, entry in pairs(prime.PRIME_WS_TUNING) do
            primeIds[entry.itemId] = true
        end

        for _, forged in ipairs(forge.weapons) do
            assert(not primeIds[forged.id], string.format(
                '%s still collides with a Prime item ID %d', forged.name, forged.id))
            assert(forged.currency ~= 1449, string.format(
                '%s still uses Tukuku Whiteshell', forged.name))
        end
    end)

    it('keeps support Relics outside damage-WS tuning', function()
        assert(forge.weapons[15].name == 'Aegis')
        assert(forge.weapons[16].name == 'Gjallarhorn')
        assert(rema.BY_ITEM_ID[forge.weapons[15].id] == nil)
        assert(rema.BY_ITEM_ID[forge.weapons[16].id] == nil)
    end)

    it('shares currency families with the main Weapon Forge', function()
        local byId = {}
        for _, relic in ipairs(forge.weapons) do
            byId[relic.id] = relic
        end

        for _, chain in ipairs(weaponForge.relicChains) do
            local relic = byId[chain.s3]
            assert(relic ~= nil)
            assert(chain.currency == relic.currency)
            assert(chain.highCurrency == relic.highCurrency)
        end

        assert(forge.repeatCurrencyCost == 750)
        assert(forge.repeatPlutonCost == 500)
        assert(forge.plutonId == 4059)
    end)

    it('grants Yoichi\'s Quiver with final Yoichinoyumi and no other relic companions', function()
        assert.same({ 26343 }, forge.companionsFor(22129))

        for _, relic in ipairs(forge.weapons) do
            if relic.id ~= 22129 then
                assert.same({}, forge.companionsFor(relic.id), relic.name)
            end
        end

        local player =
        {
            quiver = 0,
            getItemCount = function(self, itemId)
                return itemId == 26343 and self.quiver or 0
            end,
        }

        assert(forge.companionSlotNeed(player, 22129) == 1)
        assert(forge.grantSlotNeed(player, 22129, false) == 2)
        assert(forge.grantSlotNeed(player, 22129, true) == 1)

        player.quiver = 1
        assert(forge.companionSlotNeed(player, 22129) == 0)
        assert(forge.grantSlotNeed(player, 22129, false) == 1)
        assert(forge.grantSlotNeed(player, 22129, true) == 1)
    end)

    it('refuses Yoichi Arrows from the bow script', function()
        local bow = require('scripts/items/yoichinoyumi')
        assert(bow.onItemCheck() == xi.msg.basic.ITEM_UNABLE_TO_USE)
    end)
end)
