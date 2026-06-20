-----------------------------------
-- cosmetic_shop_catalog.lua
--
-- Config for the daily-rotating Seasonal Boutique NPC in GM Home.
-- One item is available per server day (UTC); the rotation advances
-- automatically. No player can buy the same day's item twice unless
-- they want a duplicate. Pure appearance items: no combat stats.
--
-- Price tiers (all in gil):
--   100,000  -- simple seasonal headgear, themed shirts
--   150,000  -- yukatas, formal coats, full event outfits
--   200,000  -- monster costume suits, rare event pieces
--
-- To add items: append to catalog.items. No restart needed once hot-reloaded.
-----------------------------------
local catalog = {}

catalog.npcName = 'Boutique Moogle'
catalog.npcLook = 2419  -- Moogle
catalog.npcPos  = { x = 7.500, y = 0.000, z = -25.000, rot = 128 }

-- Daily rotation table. One item per entry.
-- Fields: id (item_basic itemId), name (display string ≤20 chars), price (gil)
catalog.items = {
    -- === YUKATA (Summer Festival) ===
    { id = 11316, name = 'Otokogusa Yukata',  price = 150000 },
    { id = 11317, name = 'Onnagusa Yukata',   price = 150000 },
    { id = 11318, name = 'Otokoeshi Yukata',  price = 150000 },
    { id = 11319, name = 'Ominaeshi Yukata',  price = 150000 },
    { id = 11861, name = 'Hikogami Yukata',   price = 150000 },
    { id = 11862, name = 'Himegami Yukata',   price = 150000 },
    { id = 13819, name = 'Onoko Yukata',      price = 150000 },
    { id = 13820, name = 'Omina Yukata',      price = 150000 },
    { id = 13821, name = "Lord's Yukata",     price = 150000 },
    { id = 13822, name = "Lady's Yukata",     price = 150000 },
    { id = 14532, name = 'Otoko Yukata',      price = 150000 },
    { id = 14533, name = 'Onago Yukata',      price = 150000 },
    { id = 14534, name = 'Otokogimi Yukata',  price = 150000 },
    { id = 14535, name = 'Onnagimi Yukata',   price = 150000 },

    -- === HALLOWEEN ===
    { id = 13916, name = 'Pumpkin Head',      price = 200000 },
    { id = 15176, name = 'Pumpkin Head II',   price = 200000 },
    { id = 16075, name = 'Witch Hat',         price = 150000 },

    -- === WINTER ===
    { id = 11490, name = 'Snow Bunny Hat',    price = 150000 },
    { id = 11491, name = 'Snow Bunny Hat +1', price = 200000 },

    -- === FORMAL / DECENNIAL ===
    { id = 10251, name = 'Decennial Coat',    price = 150000 },
    { id = 10252, name = 'Decennial Dress',   price = 150000 },
    { id = 10430, name = 'Decennial Crown',   price = 100000 },
    { id = 10431, name = 'Decennial Tiara',   price = 100000 },
    { id = 10593, name = 'Decennial Tights',  price = 100000 },
    { id = 10594, name = 'Decennial Hose',    price = 100000 },
    { id = 10796, name = 'Decennial Ring',    price = 100000 },
    { id = 11355, name = 'Dinner Jacket',     price = 150000 },
    { id = 16378, name = 'Dinner Hose',       price = 100000 },

    -- === WEDDING / BRIDAL ===
    { id = 14386, name = 'Wedding Dress',     price = 200000 },
    { id = 14251, name = 'Wedding Hose',      price = 100000 },
    { id = 14126, name = 'Wedding Boots',     price = 100000 },
    { id = 13933, name = 'Bridal Corsage',    price = 100000 },

    -- === MOOGLE-THEMED ===
    { id = 10250, name = 'Moogle Suit',       price = 200000 },
    { id = 10429, name = 'Moogle Masque',     price = 150000 },
    { id = 10809, name = 'Moogle Guard',      price = 100000 },
    { id = 16118, name = 'Moogle Cap',        price = 100000 },
    { id = 26546, name = 'Moogle Shirt',      price = 100000 },

    -- === MONSTER / EVENT SUITS ===
    { id = 23791, name = 'Adenium Suit',      price = 200000 },
    { id = 25711, name = 'Botulus Suit',      price = 200000 },
    { id = 25715, name = 'Korrigan Suit',     price = 200000 },
    { id = 25726, name = 'Kupo Suit',         price = 200000 },
    { id = 25756, name = 'Wyrmking Suit',     price = 200000 },
    { id = 26954, name = 'Behemoth Suit',     price = 200000 },
    { id = 27854, name = 'Mandragora Suit',   price = 200000 },
    { id = 27866, name = 'Goblin Suit',       price = 200000 },
    { id = 27911, name = 'Chocobo Suit',      price = 150000 },

    -- === MASKS / MASQUES ===
    { id = 10384, name = 'Cumulus Masque',    price = 150000 },
    { id = 23790, name = 'Adenium Masque',    price = 150000 },
    { id = 25639, name = 'Korrigan Masque',   price = 150000 },
    { id = 26703, name = 'Lycopodium Masque', price = 150000 },

    -- === CHOCOBO-THEMED ===
    { id = 11500, name = 'Chocobo Beret',     price = 100000 },
    { id = 10293, name = 'Chocobo Shirt',     price = 100000 },
    { id = 25585, name = 'Black Chocobo Cap', price = 150000 },
    { id = 23731, name = 'Ryl. Chocobo Beret',price = 150000 },

    -- === DREAM / SEASONAL HATS ===
    { id = 15178, name = 'Dream Hat',         price = 100000 },
    { id = 26719, name = 'Sheep Cap',         price = 100000 },

    -- === THEMED SHIRTS ===
    { id = 25722, name = 'Jubilee Shirt',     price = 100000 },
    { id = 25758, name = 'Rhapsody Shirt',    price = 100000 },
    { id = 26517, name = 'Shadow Lord Shirt', price = 100000 },
}

return catalog
