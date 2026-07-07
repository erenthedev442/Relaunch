-----------------------------------
-- leaf_ambience.lua
-- Ambient decoration for the Leafallia hub -- a few no-aggro animals so the
-- hub feels alive instead of an NPC parking lot. Adapted from the Mog Garden
-- "decor" pattern (Shroud.lua). Purely cosmetic:
--   * NPC-type entities (no mob template / mob_groups needed in a hub zone)
--   * untargetable, hidden name, no loot, no aggro
--   * models idle-animate on their own, so they read as live critters
-- Coords sit near the vendor/homepoint strip; run !pos on each after a restart
-- and nudge if any clips a wall (Leafallia geometry isn't visible from here).
-----------------------------------
require('modules/module_utils')

local m = Module:new('leaf_ambience')

-- { name, look, x, y, z, rot }   look 1997 = chocobo, 2948 = sheep
local CRITTERS =
{
    { 'Chocobo',  1997,  -8.0, -0.434, 11.0,  96 },
    { 'Chocobo',  1997,   3.0, -0.434, 12.0, 200 },
    { 'Sheep',    2948, -12.0, -0.434,  6.0,  45 },
    { 'Sheep',    2948,   6.0, -0.434,  5.0, 260 },
}

m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)
    for _, c in ipairs(CRITTERS) do
        local critter = zone:insertDynamicEntity({
            objtype   = xi.objType.NPC,
            name      = c[1],
            look      = c[2],
            x         = c[3],
            y         = c[4],
            z         = c[5],
            rotation  = c[6],
            widescan  = 0,
            onTrade   = function(player, npc, trade) end,
            onTrigger = function(player, npc) end,
        })
        critter:hideName(true)
        critter:setUntargetable(true)
        utils.unused(critter)
    end
end)

return m
