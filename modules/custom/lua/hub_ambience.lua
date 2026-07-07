-----------------------------------
-- hub_ambience.lua
-- Ambient decoration for the consolidated hub on Purgonorgo Isle (zone 44).
-- A menagerie of no-aggro critters so the plaza feels alive instead of an NPC
-- parking lot. Adapted from the Mog Garden "decor" pattern. Purely cosmetic:
--   * NPC-type entities (no mob template / mob_groups needed in a hub zone)
--   * untargetable, hidden name, no loot, no aggro -- models idle-animate on
--     their own, so they read as live critters
--   * scattered around the PERIMETER of the vendor grid (grid sits x505-535,
--     z550-580) so they never block a vendor's click target.
--
-- LOOK IDS: only globally-valid NPC models render in an arbitrary zone (a
-- zone-local mob model would show invisible here). The four below are PROVEN
-- valid on this client (already in use by working custom NPCs):
--     1997 = Chocobo        2948 = Sheep
--     1834 = Alexander (giant iron colossus -- the exotic centerpiece)
--     2883 = (proven wildcard look, in use elsewhere)
-- After a restart, !pos-check the plaza and nudge any that clip terrain; if any
-- render invisible, its look id isn't valid here -- swap it. See EXOTIC_EXTRAS
-- at the bottom for more species to promote once verified in-game.
-----------------------------------
require('modules/module_utils')

local m = Module:new('hub_ambience')

-- { name, look, x, y, z, rot }
local CRITTERS =
{
    -- Two Alexander colossi flank the arrival walkway as exotic "guardians"
    { 'Sentinel',  1834, 501.0, -3.0, 546.0,  64 },
    { 'Sentinel',  1834, 539.0, -3.0, 546.0, 192 },
    -- Chocobo flock roaming the edges
    { 'Chocobo',   1997, 508.0, -3.0, 546.0,  64 },
    { 'Chocobo',   1997, 524.0, -3.0, 546.0, 192 },
    { 'Chocobo',   1997, 499.0, -3.0, 560.0,  64 },
    { 'Chocobo',   1997, 541.0, -3.0, 560.0, 192 },
    { 'Chocobo',   1997, 508.0, -3.0, 586.0,  64 },
    { 'Chocobo',   1997, 532.0, -3.0, 586.0, 192 },
    -- Sheep grazing the perimeter
    { 'Sheep',     2948, 516.0, -3.0, 546.0, 128 },
    { 'Sheep',     2948, 532.0, -3.0, 546.0, 192 },
    { 'Sheep',     2948, 499.0, -3.0, 572.0,  64 },
    { 'Sheep',     2948, 541.0, -3.0, 572.0, 192 },
    { 'Sheep',     2948, 516.0, -3.0, 586.0, 128 },
    { 'Sheep',     2948, 524.0, -3.0, 586.0, 192 },
    -- Exotic wildcards in the back corners
    { 'Wanderer',  2883, 499.0, -3.0, 568.0,  64 },
    { 'Wanderer',  2883, 541.0, -3.0, 580.0, 192 },
    { 'Wanderer',  2883, 520.0, -3.0, 588.0, 128 },
}

-- EXOTIC_EXTRAS: more species to sprinkle in once their look id is confirmed to
-- render on this client (invalid look = invisible NPC). To promote one: copy a
-- row into CRITTERS above with a plaza-perimeter x/z, restart, and !pos-verify.
-- Candidate global NPC/avatar look ids to try (per request for "exotic" fauna):
--   1789 Behemoth-ish   1790 Wyvern      1791 Dragon      2415 Cait Sith
--   2416 Fenrir         2417 Carbuncle   2884 Moogle-lord  2950 Buffalo
-- (These are UNVERIFIED on this client -- try a couple, keep the ones that show.)

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
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
