-----------------------------------
-- hades_leveling_catalog.lua
--
-- Weekend Leveling stall. Standing list (not a weekly one-piece roll)
-- of the lv.1 all-jobs EXP / Capacity augment-set pieces. Event-only
-- names that have no other Legendary source live here so they are
-- obtainable. 199 Soul Shards each. Already-owned pieces stay closed.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/hades_leveling_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.PRICE = 199
C.PAGE  = 4

local PRICE = C.PRICE

C.items =
{
    -- EXP set (wardrobe 3)
    { id = 11812, name = 'Charity Cap' },
    { id = 14430, name = 'Federation Aketon' },
    { id = 14072, name = 'Chocobo Gloves' },
    { id = 11966, name = 'Dream Trousers +1' },
    { id = 14173, name = 'Chocobo Boots' },
    { id = 13121, name = 'Beast Collar' },
    { id = 15455, name = 'Red Sash' },
    { id = 28511, name = 'Slime Earring' },
    { id = 28509, name = 'She-Slime Earring' },
    { id = 13492, name = "Copper Ring +1" },
    { id = 13454, name = 'Copper Ring' },
    { id = 11009, name = "Shaper's Shawl" },
    -- Capacity set (wardrobe 2)
    { id = 10430, name = 'Decennial Crown' },
    { id = 10251, name = 'Decennial Coat' },
    { id = 14832, name = "Tanner's Gloves" },
    { id = 14290, name = "Vagabond's Hose" },
    { id = 11400, name = 'Noble Poulaines' },
    { id = 13122, name = "Miner's Pendant" },
    { id = 15456, name = 'Dash Sash' },
    { id = 28510, name = 'Metal Slime Earring' },
    { id = 13402, name = 'Cassie Earring' },
    { id = 15823, name = "Tanner's Ring" },
    { id = 15819, name = "Carpenter's Ring" },
    { id = 16257, name = 'Ghost Cape' },
}

for _, row in ipairs(C.items) do
    row.price = PRICE
end

C.byId = {}
for _, row in ipairs(C.items) do
    C.byId[row.id] = row
end

return C
