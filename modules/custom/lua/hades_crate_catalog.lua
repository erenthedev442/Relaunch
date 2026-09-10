-----------------------------------
-- hades_crate_catalog.lua
--
-- Weekend Crate stall. One currency SKU per UTC week, same roll for
-- every player. Amounts sit on real REMA / Relic steps. Bought once
-- that week (currency is not unique). Paid into HD_Hold_* so a 10k
-- crate does not flood the bag. Forges spend Hold first.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/hades_crate_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.WEEK_SALT = 53
C.CV_WEEK   = 'HD_CrateWeek'

C.items =
{
    { key = 'beitetsu_99',     name = 'Beitetsu x99',            itemId = 4060, amount =    99, price =  199 },
    { key = 'beitetsu_300',    name = 'Beitetsu x300',           itemId = 4060, amount =   300, price =  449 },
    { key = 'beitetsu_10000',  name = 'Beitetsu x10000',         itemId = 4060, amount = 10000, price = 2499 },

    { key = 'boulder_99',      name = 'Riftborn x99',            itemId = 4061, amount =    99, price =  199 },
    { key = 'boulder_300',     name = 'Riftborn x300',           itemId = 4061, amount =   300, price =  449 },
    { key = 'boulder_3000',    name = 'Riftborn x3000',          itemId = 4061, amount =  3000, price = 1899 },

    { key = 'pluton_99',       name = 'Pluton x99',              itemId = 4059, amount =    99, price =  249 },
    { key = 'pluton_200',      name = 'Pluton x200',             itemId = 4059, amount =   200, price =  499 },
    { key = 'pluton_500',      name = 'Pluton x500',             itemId = 4059, amount =   500, price =  899 },

    { key = 'byne_50',         name = '100 Byne x50',            itemId = 1456, amount =    50, price =  199 },
    { key = 'byne_100',        name = '100 Byne x100',           itemId = 1456, amount =   100, price =  349 },
    { key = 'byne_500',        name = '100 Byne x500',           itemId = 1456, amount =   500, price =  799 },
    { key = 'byne_750',        name = '100 Byne x750',           itemId = 1456, amount =   750, price =  999 },

    { key = 'silver_50',       name = 'M. Silver x50',           itemId = 1453, amount =    50, price =  199 },
    { key = 'silver_100',      name = 'M. Silver x100',          itemId = 1453, amount =   100, price =  349 },
    { key = 'silver_500',      name = 'M. Silver x500',          itemId = 1453, amount =   500, price =  799 },
    { key = 'silver_750',      name = 'M. Silver x750',          itemId = 1453, amount =   750, price =  999 },

    { key = 'jade_50',         name = 'L. Jadeshell x50',        itemId = 1450, amount =    50, price =  199 },
    { key = 'jade_100',        name = 'L. Jadeshell x100',       itemId = 1450, amount =   100, price =  349 },
    { key = 'jade_500',        name = 'L. Jadeshell x500',       itemId = 1450, amount =   500, price =  799 },
    { key = 'jade_750',        name = 'L. Jadeshell x750',       itemId = 1450, amount =   750, price =  999 },

    { key = 'gold_10',         name = 'R. Goldpiece x10',        itemId = 1454, amount =    10, price =  299 },
    { key = 'gold_25',         name = 'R. Goldpiece x25',        itemId = 1454, amount =    25, price =  599 },
    { key = 'gold_50',         name = 'R. Goldpiece x50',        itemId = 1454, amount =    50, price =  999 },

    { key = '10kbyne_10',      name = '10k Byne x10',            itemId = 1457, amount =    10, price =  299 },
    { key = '10kbyne_25',      name = '10k Byne x25',            itemId = 1457, amount =    25, price =  599 },
    { key = '10kbyne_50',      name = '10k Byne x50',            itemId = 1457, amount =    50, price =  999 },

    { key = 'stripe_10',       name = 'R. Stripeshell x10',      itemId = 1451, amount =    10, price =  299 },
    { key = 'stripe_25',       name = 'R. Stripeshell x25',      itemId = 1451, amount =    25, price =  599 },
    { key = 'stripe_50',       name = 'R. Stripeshell x50',      itemId = 1451, amount =    50, price =  999 },

    { key = 'pp_25',           name = 'Paragon Pts x25',  kind = 'paragon', amount =  25, price =  199 },
    { key = 'pp_50',           name = 'Paragon Pts x50',  kind = 'paragon', amount =  50, price =  349 },
    { key = 'pp_100',          name = 'Paragon Pts x100', kind = 'paragon', amount = 100, price =  599 },
    { key = 'pp_250',          name = 'Paragon Pts x250', kind = 'paragon', amount = 250, price =  999 },
}

C.byKey = {}
for _, row in ipairs(C.items) do
    C.byKey[row.key] = row
end

function C.weeklyCrate(weekId, pinKey)
    if pinKey and C.byKey[pinKey] then
        return C.byKey[pinKey]
    end
    local n = #C.items
    if n == 0 then
        return nil
    end
    weekId = weekId or tonumber(os.date('!%Y%W'))
    return C.items[(((weekId or 0) * C.WEEK_SALT) % n) + 1]
end

function C.owns(player, weekId)
    if not player or not weekId then
        return false
    end
    return (player:getCharVar(C.CV_WEEK) or 0) == weekId
end

function C.award(player, row, weekId)
    if not player or not row or not weekId then
        return false
    end
    if C.owns(player, weekId) then
        return false
    end

    if row.kind == 'paragon' then
        local pp = player:getCharVar('Paragon_Points') or 0
        player:setCharVar('Paragon_Points', pp + row.amount)
    else
        local hold = require('modules/custom/lua/hades_hold_currency')
        if not hold.add(player, row.itemId, row.amount) then
            return false
        end
    end

    player:setCharVar(C.CV_WEEK, weekId)
    return true
end

return C
