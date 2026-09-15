local crate     = require('modules/custom/lua/hades_crate_catalog')
local trusts    = require('modules/custom/lua/hades_trust_catalog')
local cosmetics = require('modules/custom/lua/hades_cosmetic_catalog')
local leveling  = require('modules/custom/lua/hades_leveling_catalog')
local hold      = require('modules/custom/lua/hades_hold_currency')
local shop      = require('modules/custom/lua/hades_shop_catalog')

local function mockPlayer(vars, items, spells, opts)
    vars   = vars or {}
    items  = items or {}
    spells = spells or {}
    opts   = opts or {}
    local freeSlots = opts.freeSlots
    if freeSlots == nil then
        freeSlots = 2
    end
    local addOk = opts.addItem
    if addOk == nil then
        addOk = true
    end
    return {
        getCharVar = function(_, key) return vars[key] or 0 end,
        setCharVar = function(_, key, value) vars[key] = value end,
        getItemCount = function(_, id) return items[id] or 0 end,
        getFreeSlotsCount = function() return freeSlots end,
        hasSpell = function(_, id) return spells[id] == true end,
        printToPlayer = function() end,
        addItem = function(_, spec)
            if not addOk then
                return false
            end
            local id  = spec.id
            local qty = spec.quantity or 1
            items[id] = (items[id] or 0) + qty
            return true
        end,
    }
end

describe('Hades Crate stall', function()
    it('covers REMA steps, Dynamis mid/high, and Paragon amounts', function()
        assert(#crate.items == 34)
        assert(crate.byKey.beitetsu_10000.amount == 10000)
        assert(crate.byKey.beitetsu_10000.price == 2499)
        assert(crate.byKey.boulder_3000.amount == 3000)
        assert(crate.byKey.boulder_3000.price == 1899)
        assert(crate.byKey.pluton_500.amount == 500)
        assert(crate.byKey.pluton_500.price == 899)
        assert(crate.byKey.byne_750.amount == 750)
        assert(crate.byKey.silver_750.price == 999)
        assert(crate.byKey.gold_50.amount == 50)
        assert(crate.byKey['10kbyne_50'].itemId == 1457)
        assert(crate.byKey.pp_250.kind == 'paragon')
        assert(crate.byKey.pp_250.price == 999)

        local seen = {}
        for _, row in ipairs(crate.items) do
            assert(row.key ~= '')
            assert(row.name ~= '')
            assert(row.amount > 0)
            assert(row.price > 0)
            assert(not seen[row.key])
            seen[row.key] = true
            if row.kind == 'paragon' then
                assert(row.itemId == nil)
            else
                assert(hold.TRACKED[row.itemId] == true)
            end
        end
    end)

    it('picks one crate for the whole UTC week and honors a pin', function()
        local a = crate.weeklyCrate(202636)
        local b = crate.weeklyCrate(202636)
        assert(a.key == b.key)
        local pinned = crate.weeklyCrate(202636, 'beitetsu_300')
        assert(pinned.key == 'beitetsu_300')
        assert(pinned.amount == 300)
    end)

    it('lets a player miss Crate only after they already bought that week', function()
        local vars = {}
        local player = mockPlayer(vars)
        local week = 202636
        local offer = shop.weekOffers(week)[6]
        assert(shop.owns(player, offer) == false)
        assert(crate.award(player, offer.row, week) == true)
        assert(vars.HD_CrateWeek == week)
        assert(shop.owns(player, offer) == true)
        assert(crate.award(player, offer.row, week) == false)
    end)

    it('banks item crates on Hold and Paragon on the existing charvar', function()
        local vars = {}
        local player = mockPlayer(vars)
        assert(crate.award(player, crate.byKey.beitetsu_10000, 1) == true)
        assert(vars[hold.cv(4060)] == 10000)
        assert(crate.award(player, crate.byKey.pp_100, 2) == true)
        assert(vars.Paragon_Points == 100)
    end)
end)

describe('Hades Hold currency', function()
    it('counts Hold plus bags and spends Hold first', function()
        local vars = {}
        local items = { [4060] = 20 }
        local player = mockPlayer(vars, items)
        hold.add(player, 4060, 80)
        assert(hold.held(player, 4060) == 80)
        assert(hold.count(player, 4060) == 100)
        assert(hold.take(player, 4060, 80) == true)
        assert(hold.held(player, 4060) == 0)
        assert(items[4060] == 20)
    end)

    it('withdraws one stack from Hold without touching bags', function()
        local vars = {}
        local items = { [4060] = 20 }
        local player = mockPlayer(vars, items)
        hold.add(player, 4060, 300)
        local ok, qty = hold.withdraw(player, 4060, 99)
        assert(ok == true)
        assert(qty == 99)
        assert(hold.held(player, 4060) == 201)
        assert(items[4060] == 119)
        assert(hold.count(player, 4060) == 320)
    end)

    it('caps a withdraw at the remaining Hold and at 99', function()
        local vars = {}
        local items = {}
        local player = mockPlayer(vars, items)
        hold.add(player, 1457, 50)
        local ok, qty = hold.withdraw(player, 1457, 99)
        assert(ok == true)
        assert(qty == 50)
        assert(hold.held(player, 1457) == 0)
        assert(items[1457] == 50)
    end)

    it('refuses a withdraw when Hold is empty or inventory is full', function()
        local vars = {}
        local items = { [4060] = 100 }
        local empty = mockPlayer(vars, items)
        local ok = hold.withdraw(empty, 4060, 99)
        assert(ok == false)
        assert(items[4060] == 100)

        local fullVars = {}
        local fullItems = {}
        local full = mockPlayer(fullVars, fullItems, {}, { freeSlots = 0 })
        hold.add(full, 4060, 80)
        assert(hold.withdraw(full, 4060, 99) == false)
        assert(hold.held(full, 4060) == 80)
        assert(fullItems[4060] == nil)
    end)

    it('refunds Hold when addItem fails and leaves forges able to take the rest', function()
        local vars = {}
        local items = {}
        local player = mockPlayer(vars, items, {}, { addItem = false })
        hold.add(player, 4060, 300)
        assert(hold.withdraw(player, 4060, 99) == false)
        assert(hold.held(player, 4060) == 300)

        local okPlayer = mockPlayer(vars, items)
        assert(hold.withdraw(okPlayer, 4060, 99) == true)
        assert(hold.held(okPlayer, 4060) == 201)
        assert(hold.take(okPlayer, 4060, 200) == true)
        assert(hold.held(okPlayer, 4060) == 1)
        assert(items[4060] == 99)
    end)

    it('lists only currencies that are actually banked', function()
        local player = mockPlayer({}, { [4060] = 20 })
        hold.add(player, 1457, 50)
        local rows = hold.heldRows(player)
        assert(#rows == 1)
        assert(rows[1].itemId == 1457)
        assert(rows[1].held == 50)
        assert(rows[1].label == '10k Byne')
    end)
end)

describe('Hades Trusts stall', function()
    it('sells the farmable roster minus starters, gil buys, completion, and dead slots', function()
        assert(#trusts.items == 110)
        local seen = {}
        for _, row in ipairs(trusts.items) do
            assert(row.spellId > 0)
            assert(row.name ~= '')
            assert(not seen[row.spellId])
            seen[row.spellId] = true
            assert(trusts.EXCLUDED[row.spellId] ~= true)
            if trusts.RARE[row.spellId] then
                assert(row.price == trusts.PRICE_RARE)
            else
                assert(row.price == trusts.PRICE_NORMAL)
            end
        end
        assert(trusts.bySpellId[896] == nil) -- Shantotto starter
        assert(trusts.bySpellId[898] == nil) -- Kupipi starter
        assert(trusts.bySpellId[905] == nil) -- Trion starter
        assert(trusts.bySpellId[908] == nil) -- Tenzen starter
        assert(trusts.bySpellId[899] == nil) -- Meat
        assert(trusts.bySpellId[901] == nil) -- Gemma
        assert(trusts.bySpellId[902] == nil) -- Corvus
        assert(trusts.bySpellId[930] == nil) -- Aldo
        assert(trusts.bySpellId[1002] == nil) -- Cornelia
        assert(trusts.bySpellId[1004] == nil) -- Matsui-P
        assert(trusts.bySpellId[1007] == nil) -- Aldo UC
        assert(trusts.bySpellId[1020] == nil) -- Fujito-P
        assert(trusts.bySpellId[897] ~= nil) -- Naji stays
        assert(trusts.bySpellId[1019].price == 699)
    end)

    it('picks one trust for the whole UTC week and honors a pin', function()
        local a = trusts.weeklyTrust(202636)
        local b = trusts.weeklyTrust(202636)
        assert(a.spellId == b.spellId)
        local pinned = trusts.weeklyTrust(202636, 897)
        assert(pinned.spellId == 897)
        assert(pinned.name == 'Naji')
    end)

    it('lets a player miss Trusts if they already know that spell', function()
        local offer = shop.weekOffers(202636)[7]
        local owner = mockPlayer({}, {}, { [offer.row.spellId] = true })
        assert(shop.owns(owner, offer) == true)
        assert(shop.owns(mockPlayer({}, {}, {}), offer) == false)
    end)
end)

describe('Hades Cosmetics stall', function()
    it('holds a unique cosmetic pool with rarity prices', function()
        assert(#cosmetics.items >= 100)
        local seen = {}
        for _, row in ipairs(cosmetics.items) do
            assert(row.id > 0)
            assert(row.name ~= '')
            assert(not seen[row.id])
            seen[row.id] = true
            assert(
                row.price == cosmetics.PRICE_COMMON
                or row.price == cosmetics.PRICE_SET
                or row.price == cosmetics.PRICE_PLUS
            )
        end
        assert(cosmetics.byId[26955].name == 'Behemoth Suit +1')
        assert(cosmetics.byId[26955].price == 399)
        assert(cosmetics.byId[10250].name == 'Moogle Suit')
    end)
end)

describe('Hades Leveling stall', function()
    it('puts every lv.1 EXP / Capacity look in the weekend Cosmetics pool', function()
        assert(#leveling.items == 24)
        for _, row in ipairs(leveling.items) do
            local look = cosmetics.byId[row.id]
            assert(look, string.format('missing Cosmetics entry for %s (%d)', row.name, row.id))
            assert(look.name == row.name or look.id == row.id)
        end
        assert(cosmetics.byId[11812].name == 'Charity Cap')
        assert(cosmetics.byId[13121].name == 'Beast Collar')
        assert(cosmetics.byId[15455].name == 'Red Sash')
        assert(cosmetics.byId[15456].name == 'Dash Sash')
        assert(cosmetics.byId[11400].name == 'Noble Poulaines')
        assert(cosmetics.byId[28510].name == 'Metal Slime Earring')
    end)
end)

describe('Hades Cosmetics stall (week roll)', function()
    it('picks one look for the whole UTC week and honors a pin', function()
        local a = cosmetics.weeklyPiece(202636)
        local b = cosmetics.weeklyPiece(202636)
        assert(a.id == b.id)
        local pinned = cosmetics.weeklyPiece(202636, 26955)
        assert(pinned.id == 26955)
    end)

    it('lets a player miss Cosmetics if they already hold that piece', function()
        local offer = shop.weekOffers(202636)[8]
        local owner = mockPlayer({}, { [offer.row.id] = 1 })
        assert(shop.owns(owner, offer) == true)
        assert(shop.owns(mockPlayer({}, {}), offer) == false)
    end)
end)

describe('Hades shop pins', function()
    it('overrides only the pinned stalls for that week', function()
        local previous = shop.PINNED[202636]
        shop.PINNED[202636] =
        {
            crate    = 'pluton_200',
            trust    = 1019,
            cosmetic = 10250,
        }
        local offers = shop.weekOffers(202636)
        assert(offers[6].row.key == 'pluton_200')
        assert(offers[7].row.spellId == 1019)
        assert(offers[8].row.id == 10250)
        shop.PINNED[202636] = previous
        local restored = shop.weekOffers(202636)
        assert(restored[6].row.key ~= nil)
    end)
end)
