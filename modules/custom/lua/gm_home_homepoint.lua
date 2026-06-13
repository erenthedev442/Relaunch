-----------------------------------
-- gm_home_homepoint.lua
-- Adds a Home Point crystal to GM Home (zone 210) that behaves like a full
-- homepoint network terminal: set your home point here AND warp to ANY
-- homepoint in the game, for FREE, with no attunement requirement.
--
-- On trigger the crystal opens a menu:
--   1. Set home point here   -> player:setHomePoint() + unlocks GM Home (index
--                               122) in the homepoint network so other
--                               crystals can teleport back here.
--   2. Warp to a home point  -> region list -> destination -> player:setPos().
--                               No gil cost, no hasTeleport() gate.
--   3. Close.
--
-- WHY A CUSTOM MENU INSTEAD OF THE NATIVE HOMEPOINT UI:
--   The retail homepoint cutscene/menu is event 8700, which every normal
--   zone's .dat ships -- but GM Home's .dat does NOT contain event 8700, so
--   player:startEvent(8700, ...) would render nothing here. We therefore drive
--   everything from a server-side customMenu (the same GM-prompt mechanism the
--   other GM Home NPCs use) and move the player with setPos directly.
--
-- The ~120 destinations live in gm_home_homepoint_catalog.lua. customMenu
-- packs the escaped title + every option label into one GM-prompt packet with
-- a ~150-byte client cap, so showPaged() below auto-paginates every screen by
-- a byte budget -- the catalog never has to worry about menu sizes.
--
-- Homepoint network integration (for "Set home point here"):
--   Index 122 is registered in scripts/globals/homepoint.lua.
--   hpBit = 122 % 32 = 26, hpSet = floor(122/32) = 3.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog = require('modules/custom/lua/gm_home_homepoint_catalog')

local m = Module:new('gm_home_homepoint')

-- Index in scripts/globals/homepoint.lua for the GM Home destination.
local HP_INDEX = 122
local HP_BIT   = HP_INDEX % 32              -- 26
local HP_SET   = math.floor(HP_INDEX / 32)  -- 3

-----------------------------------
-- Menu sizing.
--
-- The GM-prompt packet that backs customMenu fits the escaped title plus every
-- escaped option label (each string costs its length + 2 surrounding quotes)
-- in roughly 150 bytes; overflow truncates rows client-side. Stay well under
-- it and also cap raw row count.
-----------------------------------
local BYTE_BUDGET = 144
local ROW_CAP     = 11

-- Split `entries` (array of { label = str, action = fn }) into pages that each
-- fit the packet budget after reserving the page title and the worst-case
-- control rows (Prev / Next / Back). Pure function of its inputs.
local function paginate(title, entries, backLabel)
    local titleCost = #title + 8 + 2 -- + room for a " (n/m)" suffix + quotes
    local ctrlCost  = (#'<< Prev' + 2) + (#'Next >>' + 2) + (#backLabel + 2)
    local baseUsed  = titleCost + ctrlCost

    local pages = {}
    local cur   = {}
    local used  = baseUsed

    for _, e in ipairs(entries) do
        local cost = #e.label + 2
        if #cur > 0 and (#cur >= ROW_CAP or used + cost > BYTE_BUDGET) then
            pages[#pages + 1] = cur
            cur  = {}
            used = baseUsed
        end
        cur[#cur + 1] = e
        used = used + cost
    end

    if #cur > 0 then
        pages[#pages + 1] = cur
    end

    return pages
end

-- Render a paginated menu. `backLabel`/`backFn` is the control shown on every
-- page that returns to the previous screen.
local function showPaged(player, title, entries, backLabel, backFn)
    local pages  = paginate(title, entries, backLabel)
    local nPages = #pages

    local function showPage(p, idx)
        local options = {}

        for _, e in ipairs(pages[idx]) do
            local action = e.action
            options[#options + 1] = { e.label, function(pa) action(pa) end }
        end

        if idx > 1 then
            options[#options + 1] = { '<< Prev', function(pa) showPage(pa, idx - 1) end }
        end
        if idx < nPages then
            options[#options + 1] = { 'Next >>', function(pa) showPage(pa, idx + 1) end }
        end
        options[#options + 1] = { backLabel, function(pa) backFn(pa) end }

        local pageTitle = (nPages > 1) and string.format('%s (%d/%d)', title, idx, nPages) or title
        local menu      = { title = pageTitle, options = options }
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        p:timer(30, function(pp) pp:customMenu(snapshot) end)
    end

    showPage(player, 1)
end

-----------------------------------
-- Menu screens (mutually recursive).
-----------------------------------
local showRoot, showRegionList, showRegion

local function setHomeHere(player)
    player:setHomePoint()

    -- Unlock GM Home in the homepoint network so it appears as a teleport
    -- destination at other homepoint crystals.
    if not player:hasTeleport(xi.teleport.type.HOMEPOINT, HP_BIT, HP_SET) then
        player:addTeleport(xi.teleport.type.HOMEPOINT, HP_BIT, HP_SET)
    end

    player:printToPlayer(
        '[GM Home] Home point set! You will return here upon raising or using !homepoint.',
        xi.msg.channel.SYSTEM_3)
end

showRoot = function(player)
    local menu =
    {
        title   = 'Home Point',
        options =
        {
            { 'Set home point here',  function(p) setHomeHere(p) end },
            { 'Warp to a home point', function(p) showRegionList(p) end },
            { 'Close',                function(_) end },
        },
    }
    local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

showRegionList = function(player)
    local entries = {}
    for _, region in ipairs(catalog.regions) do
        local r = region
        entries[#entries + 1] =
        {
            label  = r.name,
            action = function(p) showRegion(p, r) end,
        }
    end
    showPaged(player, 'Warp: choose a region', entries, '<< Back', showRoot)
end

showRegion = function(player, region)
    local entries = {}
    for _, dest in ipairs(region.dests) do
        local d = dest
        entries[#entries + 1] =
        {
            label  = d.label,
            action = function(p)
                p:printToPlayer(
                    string.format('Warping to %s - %s. Safe travels!', region.name, d.label),
                    xi.msg.channel.SYSTEM_3)
                p:setPos(d.x, d.y, d.z, d.r, d.zone)
            end,
        }
    end
    showPaged(player, region.name, entries, '<< Regions', showRegionList)
end

-----------------------------------
-- Place the crystal in GM Home.
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    -- Teleport-services cluster on the east side of GM Home: the three travel
    -- NPCs (Home Point / Warpman / ExpCamp Moogle) sit together here so players
    -- find every warp option in one spot. IMPORTANT: keep this position in sync
    -- with the homepoint-return coord for index 122 in scripts/globals/homepoint.lua,
    -- or raising / warping back will land players away from the crystal.
    local HomeCrystal = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Home_Point',
        packetName = 'Home Point',
        look       = 51,        -- homepoint crystal model (modelid 0x0033)
        x          =  4.000,
        y          =  0.000,
        z          = -12.000,
        rotation   =  128,
        widescan   = 1,

        onTrigger = function(player, npc)
            showRoot(player)
        end,
    })

    utils.unused(HomeCrystal)
end)

return m
