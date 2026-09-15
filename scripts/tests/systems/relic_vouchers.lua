local vouchers   = require('modules/custom/lua/relic_voucher_catalog')
local forge      = require('modules/custom/lua/weapon_forge_catalog')
local ambuscade  = require('modules/custom/lua/ambuscade_weapons_catalog')
local armor      = require('modules/custom/lua/hades_armor_catalog')
local accessory  = require('modules/custom/lua/hades_accessory_catalog')
local shop       = require('modules/custom/lua/hades_shop_catalog')
local hades      = require('modules/custom/lua/hades_catalog')

local function mockPlayer(vars, items)
    vars  = vars or {}
    items = items or {}
    return {
        getCharVar = function(_, key) return vars[key] or 0 end,
        getItemCount = function(_, id) return items[id] or 0 end,
        getFreeSlotsCount = function() return 2 end,
    }
end

describe('Hades Relic 119 III vouchers', function()
    it('covers Relic + Odyssey vouchers and Ambuscade + Geas named in two Steel bands', function()
        assert(#forge.relicChains == 14)
        assert(#ambuscade.CHAINS == 14)
        local counts = { relic = 0, odyssey = 0, ambuscade = 0, geas = 0 }
        for _, row in ipairs(vouchers.weapons) do
            counts[row.kind] = (counts[row.kind] or 0) + 1
        end
        assert(counts.relic == 16)
        assert(counts.odyssey == 13)
        assert(counts.ambuscade == 14)
        assert(counts.geas == 67)
        assert(#vouchers.weapons == 110)
        assert(#vouchers.rareItems == 29)
        assert(#vouchers.commonItems == 81)
        assert(vouchers.POOL_WEIGHT.rare == 16)
        assert(vouchers.POOL_WEIGHT.common == 14)
        assert(vouchers.byWeaponId[11927].name == 'Aegis')
        assert(vouchers.byWeaponId[18840].name == 'Gjallarhorn')
        assert(vouchers.byVoucherId[23867].weaponId == 11927)
        assert(vouchers.byVoucherId[23868].weaponId == 18840)
        assert(vouchers.byVoucherId[24276].weaponId == 21527)
        assert(vouchers.byVoucherId[24276].kind == 'odyssey')
        assert(vouchers.isOdysseyWeapon(21527) == true)
        assert(vouchers.isOdysseyWeapon(21621) == false)
        assert(vouchers.byWeaponId[27645] == nil) -- Genmei Shield stays out

        local seenVoucher = {}
        local seenWeapon  = {}
        for _, row in ipairs(vouchers.weapons) do
            assert(row.weaponId > 0)
            assert(row.name ~= '')
            assert(not seenWeapon[row.weaponId])
            seenWeapon[row.weaponId] = true
            if vouchers.isVoucherKind(row.kind) then
                assert(row.voucherId ~= nil)
                assert(vouchers.voucherName(row) == row.name .. ' Voucher')
                assert(vouchers.shopName(row) == row.name .. ' Voucher')
                assert(not seenVoucher[row.voucherId])
                seenVoucher[row.voucherId] = true
            else
                assert(row.voucherId == nil)
                assert(vouchers.shopName(row) == row.name)
            end
        end

        for _, chain in ipairs(forge.relicChains) do
            local row = vouchers.byWeaponId[chain.s3]
            assert(row ~= nil, string.format('missing voucher for %s (%s)', chain.name, tostring(chain.s3)))
            assert(row.name == chain.name)
            assert(row.kind == 'relic')
        end

        for _, chain in ipairs(ambuscade.CHAINS) do
            local finalId = chain.stages[5]
            local row = vouchers.byWeaponId[finalId]
            assert(row ~= nil, string.format('missing Ambuscade offer for %s', chain.label))
            assert(row.kind == 'ambuscade')
            assert(row.weaponId == finalId)
        end
    end)

    it('only redeems after a from-scratch Relic finish', function()
        assert(vouchers.hasForgedRelic(mockPlayer({ WF_Relic_Final = 1 })) == true)
        assert(vouchers.hasForgedRelic(mockPlayer({})) == false)
    end)

    it('picks one Steel ware for the whole UTC week', function()
        local a = vouchers.weeklyRelic(202636)
        local b = vouchers.weeklyRelic(202636)
        assert(a.weaponId == b.weaponId)
        assert(vouchers.weeklyPrice(202636, a) == vouchers.weeklyPrice(202636, b))
    end)

    it('lets a player miss the Steel stall if they already hold that weapon', function()
        local week = vouchers.weeklyRelic(202636)
        assert(vouchers.ownsRelic(mockPlayer({}, { [week.weaponId] = 1 }), week) == true)
        assert(vouchers.ownsRelic(mockPlayer({}, {}), week) == false)
    end)

    it('lets Hades set a weekly Relic or Ambuscade price inside the band', function()
        assert(vouchers.PRICE.relic.lo == 1901)
        assert(vouchers.PRICE.relic.hi == 2099)
        assert(vouchers.PRICE.odyssey.lo == 1400)
        assert(vouchers.PRICE.odyssey.hi == 1500)
        assert(vouchers.PRICE.ambuscade.lo == 901)
        assert(vouchers.PRICE.ambuscade.hi == 1099)
        assert(vouchers.PRICE.geas.lo == 499)
        assert(vouchers.PRICE.geas.hi == 599)
        local row = vouchers.weeklyRelic(202636)
        local price = vouchers.weeklyPrice(202636, row)
        if row.kind == 'relic' then
            assert(price >= 1901 and price <= 2099)
        elseif row.kind == 'odyssey' then
            assert(price >= 1400 and price <= 1500)
        elseif row.kind == 'geas' then
            assert(price >= 499 and price <= 599)
        else
            assert(price >= 901 and price <= 1099)
        end
    end)

    it('keeps Relic-tier and Ambuscade-tier week weights, then rolls uniformly inside each band', function()
        local seen = { relic = 0, odyssey = 0, ambuscade = 0, geas = 0 }
        for week = 0, 179 do
            local row = vouchers.weeklyRelic(week)
            seen[row.kind] = seen[row.kind] + 1
            assert(row == vouchers.weeklyRelic(week))
        end
        assert(seen.relic > 0)
        assert(seen.odyssey > 0)
        assert(seen.ambuscade > 0)
        assert(seen.geas > 0)
        assert((seen.relic + seen.odyssey) > (seen.ambuscade + seen.geas) * 0.7)
        assert((seen.relic + seen.odyssey) < (seen.ambuscade + seen.geas) * 1.6)
    end)

    it('keeps Odyssey WS ids aligned with the voucher list and out of Invasion', function()
        local ws = require('modules/custom/lua/standard_ws_tuning_catalog')
        local odysseyIds = {}
        for _, row in ipairs(vouchers.weapons) do
            if row.kind == 'odyssey' then
                odysseyIds[row.weaponId] = true
                assert(ws.isOdysseyWeapon(row.weaponId) == true)
            end
        end
        local listed = 0
        for itemId in pairs(ws.ODYSSEY_WEAPON_IDS) do
            listed = listed + 1
            assert(odysseyIds[itemId] == true)
        end
        assert(listed == 13)

        local invasion = require('modules/custom/lua/invasion_loot_pool')
        local raw = {}
        for _, itemId in ipairs(invasion) do
            raw[itemId] = true
        end
        for itemId in pairs(odysseyIds) do
            assert(raw[itemId] == true) -- still in the generated dump
        end

        local invFile = assert(io.open('modules/custom/lua/Invasion.lua', 'r'))
        local invText = invFile:read('*a')
        invFile:close()
        assert(invText:find("row.kind == 'odyssey'", 1, true))
    end)
end)

describe('Hades Mail stall', function()
    it('holds at least 200 119 armor pieces with rarity prices', function()
        assert(#armor.items >= 200)
        assert(#shop.POOLS == 8)
        assert(shop.POOLS[1].key == 'weapon')
        assert(shop.POOLS[2].key == 'weapon')
        assert(shop.POOLS[3].key == 'armor')
        assert(shop.POOLS[4].key == 'armor')
        assert(shop.POOLS[5].key == 'accessory')
        assert(shop.POOLS[6].key == 'crate')
        assert(shop.POOLS[7].key == 'trust')
        assert(shop.POOLS[8].key == 'cosmetic')

        local unsourced, sourced = 0, 0
        local seen = {}
        for _, row in ipairs(armor.items) do
            assert(row.id > 0)
            assert(row.name ~= '')
            assert(not seen[row.id])
            seen[row.id] = true
            if row.sourced then
                sourced = sourced + 1
                assert(row.price >= armor.SOURCED_LO and row.price <= armor.SOURCED_HI)
            else
                unsourced = unsourced + 1
                assert(row.price == armor.UNSOURCED_PRICE)
            end
        end
        assert(unsourced >= 80)
        assert(sourced >= 80)
        assert(armor.byId[23768].name == 'Nyame Mail')
        assert(armor.byId[23768].sourced == false)
        assert(armor.byId[23768].price == 1499)
    end)

    it('picks one Mail piece for the whole UTC week', function()
        local a = armor.weeklyPiece(202636)
        local b = armor.weeklyPiece(202636)
        assert(a.id == b.id)
        assert(a.price == b.price)
    end)

    it('sells two Steel, two Mail, Gild, Crate, Trusts, and Cosmetics as the weekend board', function()
        local offers = hades.weekOffers(202636)
        assert(#offers == 8)
        assert(offers[1].key == 'weapon')
        assert(offers[2].key == 'weapon')
        assert(offers[3].key == 'armor')
        assert(offers[4].key == 'armor')
        assert(offers[5].key == 'accessory')
        assert(offers[6].key == 'crate')
        assert(offers[7].key == 'trust')
        assert(offers[8].key == 'cosmetic')
        -- 202636 is fully pinned so the first ferry cannot drift.
        assert(offers[1].row.weaponId == 21722)
        assert(offers[1].row.name == 'Dolichenus')
        assert(offers[1].price == 926)
        assert(offers[2].row.weaponId == 21621)
        assert(offers[2].row.name == 'Naegling')
        assert(offers[2].price == 899)
        assert(offers[3].row.id == 23798)
        assert(offers[3].row.name == 'Crepuscular Mail')
        assert(offers[3].price == 557)
        assert(offers[4].row.id == 27496)
        assert(offers[4].row.name == 'Herculean Boots')
        assert(offers[5].row.id == 27555)
        assert(offers[5].price == 503)
        assert(offers[6].row.key == '10kbyne_50')
        assert(offers[6].price == 999)
        assert(offers[7].row.spellId == 932)
        assert(offers[7].row.name == 'Fablinix')
        assert(offers[7].price == 399)
        assert(offers[8].row.id == 11318)
        assert(offers[8].row.name == 'Otokoeshi Yukata')
        assert(offers[8].price == 299)
        for _, offer in ipairs(offers) do
            assert(offer.price <= 1050)
        end
        assert(offers[3].row.id == armor.weeklyPiece(202636).id)
        assert(offers[3].price == offers[3].row.price)
        assert(offers[5].row.id == accessory.weeklyPiece(202636).id)
        assert(offers[5].price == offers[5].row.price)
        assert(offers[1].row.weaponId ~= offers[2].row.weaponId)
        assert(offers[3].row.id ~= offers[4].row.id)

        local mail = offers[3]
        local owner = mockPlayer({}, { [mail.row.id] = 1 })
        assert(shop.owns(owner, mail) == true)
        assert(shop.owns(mockPlayer({}, {}), mail) == false)

        local gild = offers[5]
        local gildOwner = mockPlayer({}, { [gild.row.id] = 1 })
        assert(shop.owns(gildOwner, gild) == true)
        assert(shop.owns(mockPlayer({}, {}), gild) == false)

        assert(offers[6].row.key ~= nil)
        assert(offers[6].price == offers[6].row.price)
        assert(offers[7].row.spellId ~= nil)
        assert(offers[7].price == offers[7].row.price)
        assert(offers[8].row.id ~= nil)
        assert(offers[8].price == offers[8].row.price)
    end)
end)

describe('Hades Gild stall', function()
    it('holds at least 200 accessories with rarity prices', function()
        assert(#accessory.items >= 200)

        local unsourced, sourced = 0, 0
        local seen = {}
        for _, row in ipairs(accessory.items) do
            assert(row.id > 0)
            assert(row.name ~= '')
            assert(not seen[row.id])
            seen[row.id] = true
            if row.sourced then
                sourced = sourced + 1
                assert(row.price >= accessory.SOURCED_LO and row.price <= accessory.SOURCED_HI)
            else
                unsourced = unsourced + 1
                assert(row.price == accessory.UNSOURCED_PRICE)
            end
        end
        assert(unsourced >= 80)
        assert(sourced >= 80)
        assert(accessory.byId[27541].name == 'Cessance Earring')
        assert(accessory.byId[27541].sourced == false)
        assert(accessory.byId[27541].price == 1499)
        assert(accessory.byId[26088].name == 'Malignance Earring')
        assert(accessory.byId[26088].sourced == true)
        assert(accessory.byId[26088].price >= 499 and accessory.byId[26088].price <= 999)
        assert(accessory.byId[26189] == nil) -- Moonbeam Ring stays on the medal vendor
        assert(accessory.byId[26269] == nil) -- Moonlight Cape stays on Infamy
    end)

    it('picks one Gild piece for the whole UTC week', function()
        local a = accessory.weeklyPiece(202636)
        local b = accessory.weeklyPiece(202636)
        assert(a.id == b.id)
        assert(a.price == b.price)
    end)
end)
