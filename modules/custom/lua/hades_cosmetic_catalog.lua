-----------------------------------
-- hades_cosmetic_catalog.lua
--
-- Weekend Cosmetics stall. One piece per UTC week, same name for
-- every player. Event / lockstyle gear -- suits, masques, yukatas,
-- seasonal hats, formal sets -- including +1 versions the Boutique
-- does not sell.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/hades_cosmetic_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.WEEK_SALT     = 47
C.PRICE_COMMON  = 199
C.PRICE_SET     = 299
C.PRICE_PLUS    = 399

local COMMON = 199
local SET    = 299
local PLUS   = 399

C.items =
{
    -- Yukata
    { id = 11316, name = 'Otokogusa Yukata',     price = SET },
    { id = 11317, name = 'Onnagusa Yukata',      price = SET },
    { id = 11318, name = 'Otokoeshi Yukata',     price = SET },
    { id = 11319, name = 'Ominaeshi Yukata',     price = SET },
    { id = 11861, name = 'Hikogami Yukata',      price = SET },
    { id = 11862, name = 'Himegami Yukata',      price = SET },
    { id = 13819, name = 'Onoko Yukata',         price = SET },
    { id = 13820, name = 'Omina Yukata',         price = SET },
    { id = 13821, name = "Lord's Yukata",        price = SET },
    { id = 13822, name = "Lady's Yukata",        price = SET },
    { id = 14532, name = 'Otoko Yukata',         price = SET },
    { id = 14533, name = 'Onago Yukata',         price = SET },
    { id = 14534, name = 'Otokogimi Yukata',     price = SET },
    { id = 14535, name = 'Onnagimi Yukata',      price = SET },

    -- Halloween / winter hats
    { id = 13916, name = 'Pumpkin Head',         price = COMMON },
    { id = 15176, name = 'Pumpkin Head II',      price = COMMON },
    { id = 13917, name = 'Horror Head',          price = COMMON },
    { id = 15177, name = 'Horror Head II',       price = COMMON },
    { id = 16075, name = 'Witch Hat',            price = COMMON },
    { id = 11490, name = 'Snow Bunny Hat',       price = COMMON },
    { id = 11491, name = 'Snow Bunny Hat +1',    price = PLUS },
    { id = 10875, name = 'Snowman Cap',          price = COMMON },

    -- Formal / anniversary
    { id = 10251, name = 'Decennial Coat',       price = SET },
    { id = 10252, name = 'Decennial Dress',      price = SET },
    { id = 10253, name = 'Decennial Coat +1',    price = PLUS },
    { id = 10254, name = 'Decennial Dress +1',   price = PLUS },
    { id = 10430, name = 'Decennial Crown',      price = COMMON },
    { id = 10431, name = 'Decennial Tiara',      price = COMMON },
    { id = 10432, name = 'Decennial Crown +1',   price = PLUS },
    { id = 10433, name = 'Decennial Tiara +1',   price = PLUS },
    { id = 10593, name = 'Decennial Tights',     price = COMMON },
    { id = 10594, name = 'Decennial Hose',       price = COMMON },
    { id = 10595, name = 'Decennial Tights +1',  price = PLUS },
    { id = 10596, name = 'Decennial Hose +1',    price = PLUS },
    { id = 10796, name = 'Decennial Ring',       price = COMMON },
    { id = 28528, name = 'Undecennial Ring',     price = COMMON },
    { id = 28562, name = 'Duodecennial Ring',    price = COMMON },
    { id = 11355, name = 'Dinner Jacket',        price = SET },
    { id = 16378, name = 'Dinner Hose',          price = COMMON },

    -- Wedding
    { id = 14386, name = 'Wedding Dress',        price = SET },
    { id = 14251, name = 'Wedding Hose',         price = COMMON },
    { id = 14126, name = 'Wedding Boots',        price = COMMON },
    { id = 13933, name = 'Bridal Corsage',       price = COMMON },

    -- Moogle
    { id = 10250, name = 'Moogle Suit',          price = SET },
    { id = 10429, name = 'Moogle Masque',        price = COMMON },
    { id = 10809, name = 'Moogle Guard',         price = COMMON },
    { id = 10810, name = 'Moogle Guard +1',      price = PLUS },
    { id = 16118, name = 'Moogle Cap',           price = COMMON },
    { id = 26546, name = 'Moogle Shirt',         price = COMMON },
    { id = 27716, name = 'Green Moogle Masque',  price = COMMON },
    { id = 27867, name = 'Green Moogle Suit',    price = SET },

    -- Monster / event suits and masques
    { id = 23790, name = 'Adenium Masque',       price = COMMON },
    { id = 23791, name = 'Adenium Suit',         price = SET },
    { id = 25711, name = 'Botulus Suit',         price = SET },
    { id = 25712, name = 'Botulus Suit +1',      price = PLUS },
    { id = 25639, name = 'Korrigan Masque',      price = COMMON },
    { id = 25715, name = 'Korrigan Suit',        price = SET },
    { id = 25638, name = 'Pachypodium Masque',   price = COMMON },
    { id = 25645, name = 'Kupo Masque',          price = COMMON },
    { id = 25726, name = 'Kupo Suit',            price = SET },
    { id = 25657, name = 'Wyrmking Masque',      price = COMMON },
    { id = 25658, name = 'Wyrmking Masque +1',   price = PLUS },
    { id = 25756, name = 'Wyrmking Suit',        price = SET },
    { id = 25757, name = 'Wyrmking Suit +1',     price = PLUS },
    { id = 26798, name = 'Behemoth Masque',      price = COMMON },
    { id = 26799, name = 'Behemoth Masque +1',   price = PLUS },
    { id = 26954, name = 'Behemoth Suit',        price = SET },
    { id = 26955, name = 'Behemoth Suit +1',     price = PLUS },
    { id = 26705, name = 'Mandragora Masque',    price = COMMON },
    { id = 26706, name = 'Mandragora Masque +1', price = PLUS },
    { id = 27854, name = 'Mandragora Suit',      price = SET },
    { id = 27855, name = 'Mandragora Suit +1',   price = PLUS },
    { id = 27715, name = 'Goblin Masque',        price = COMMON },
    { id = 27866, name = 'Goblin Suit',          price = SET },
    { id = 27765, name = 'Chocobo Masque',       price = COMMON },
    { id = 27760, name = 'Chocobo Masque +1',    price = PLUS },
    { id = 27911, name = 'Chocobo Suit',         price = SET },
    { id = 27906, name = 'Chocobo Suit +1',      price = PLUS },
    { id = 25776, name = 'Black Chocobo Suit',   price = SET },
    { id = 25585, name = 'Black Chocobo Cap',    price = COMMON },
    { id = 10384, name = 'Cumulus Masque',       price = COMMON },
    { id = 10385, name = 'Cumulus Masque +1',    price = PLUS },
    { id = 26703, name = 'Lycopodium Masque',    price = COMMON },
    { id = 26704, name = 'Lycopodium Masque +1', price = PLUS },
    { id = 26707, name = 'Flan Masque',          price = COMMON },
    { id = 26708, name = 'Flan Masque +1',       price = PLUS },
    { id = 25672, name = 'Snoll Masque',         price = COMMON },
    { id = 25673, name = 'Snoll Masque +1',      price = PLUS },
    { id = 27717, name = 'Worm Masque',          price = COMMON },
    { id = 27718, name = 'Worm Masque +1',       price = PLUS },
    { id = 27757, name = 'Bomb Masque',          price = COMMON },
    { id = 27758, name = 'Bomb Masque +1',       price = PLUS },
    { id = 26963, name = 'Onca Suit',            price = SET },
    { id = 23737, name = 'Byakko Masque',        price = COMMON },

    -- Chocobo / themed extras
    { id = 11500, name = 'Chocobo Beret',        price = COMMON },
    { id = 23731, name = 'Ryl. Chocobo Beret',   price = COMMON },
    { id = 10293, name = 'Chocobo Shirt',        price = COMMON },
    { id = 10811, name = 'Chocobo Shield',       price = COMMON },
    { id = 10812, name = 'Chocobo Shield +1',    price = PLUS },

    -- Dream set
    { id = 15178, name = 'Dream Hat',            price = COMMON },
    { id = 15179, name = 'Dream Hat +1',         price = PLUS },
    { id = 14519, name = 'Dream Robe',           price = SET },
    { id = 14520, name = 'Dream Robe +1',        price = PLUS },
    { id = 10382, name = 'Dream Mittens',        price = COMMON },
    { id = 10383, name = 'Dream Mittens +1',     price = PLUS },
    { id = 11965, name = 'Dream Trousers',       price = COMMON },
    { id = 11966, name = 'Dream Trousers +1',    price = PLUS },
    { id = 11967, name = 'Dream Pants',          price = COMMON },
    { id = 11968, name = 'Dream Pants +1',       price = PLUS },

    -- Caps / coats / shirts
    { id = 10446, name = 'Ahriman Cap',          price = COMMON },
    { id = 10447, name = 'Pyracmon Cap',         price = COMMON },
    { id =  2334, name = 'Poroggo Hat',          price = COMMON },
    { id = 26514, name = 'Poroggo Fleece',       price = SET },
    { id = 26515, name = 'Poroggo Fleece +1',    price = PLUS },
    { id = 26956, name = 'Poroggo Coat',         price = SET },
    { id = 26957, name = 'Poroggo Coat +1',      price = PLUS },
    { id = 26719, name = 'Sheep Cap',            price = COMMON },
    { id = 26720, name = 'Sheep Cap +1',         price = PLUS },
    { id = 25722, name = 'Jubilee Shirt',        price = COMMON },
    { id = 25758, name = 'Rhapsody Shirt',       price = COMMON },
    { id = 25759, name = 'Rhapsody Shirt +1',    price = PLUS },
    { id = 26517, name = 'Shadow Lord Shirt',    price = COMMON },
    { id = 27759, name = 'Korrigan Beret',       price = COMMON },
}

C.byId = {}
for _, row in ipairs(C.items) do
    C.byId[row.id] = row
end

function C.weeklyPiece(weekId, pinId)
    if pinId and C.byId[pinId] then
        return C.byId[pinId]
    end
    local n = #C.items
    if n == 0 then
        return nil
    end
    weekId = weekId or tonumber(os.date('!%Y%W'))
    return C.items[(((weekId or 0) * C.WEEK_SALT) % n) + 1]
end

return C
