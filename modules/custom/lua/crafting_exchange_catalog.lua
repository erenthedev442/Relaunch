-----------------------------------
-- crafting_exchange_catalog.lua
-- Maps high-quality crafted items to exchange rewards at the Crafting Exchange NPC.
-- Purpose: gives crafters a valued progression outlet. HQ synthesis products
-- that players actually make during leveling are accepted here for Hunt Marks
-- or special augment catalysts not available from mob drops.
--
-- Exchange rate logic:
--   craftReward   - Hunt Marks (HL_Points) paid per trade.
--   specialCat    - optional: item given as special augment catalyst. nil = marks only.
--
-- Adding new items: find the itemId via !additem or the item database,
-- verify it is actually craftable (NQ+HQ exist), add an entry.
-----------------------------------
local catalog = {}

catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =  1.500,
    y        =  0.000,
    z        = -30.000,
    rotation =  128,
}

catalog.npcLook = 2430    -- Elvaan merchant look (same as Armor/Accessory vendors)
catalog.npcName = 'Crafting Exchange'

-- Minimum crafting skill (shown to players, informational only).
catalog.skillNote = 'Trade any 1 HQ synthesis result for Hunt Marks or a special catalyst.'

-- Exchange entries. Each entry:
--   itemId      : FFXI item ID of the HQ crafted result
--   name        : display label
--   skill       : craft that makes it (informational)
--   reward      : { marks = N } or { marks = N, catalyst = itemId }
--   maxPerDay   : cap on trades of this item per player per calendar day (nil = uncapped)

catalog.exchanges =
{
    -- ── SMITHING ─────────────────────────────────────────────────────────────
    { itemId = 1784, name = 'Darksteel Ingot +1',     skill = 'Smithing',    reward = { marks = 150 },          maxPerDay = 5  },
    { itemId = 1780, name = 'Iron Ingot +1',           skill = 'Smithing',    reward = { marks =  75 },          maxPerDay = 10 },
    { itemId = 1787, name = 'Orichalcum Ingot +1',     skill = 'Smithing',    reward = { marks = 400 },          maxPerDay = 3  },

    -- ── CLOTHCRAFT ───────────────────────────────────────────────────────────
    { itemId = 1538, name = 'Linen Cloth +1',          skill = 'Clothcraft',  reward = { marks =  80 },          maxPerDay = 10 },
    { itemId = 1530, name = 'Silk Thread +1',          skill = 'Clothcraft',  reward = { marks = 120 },          maxPerDay = 5  },
    { itemId = 1541, name = 'Errant Chain +1',         skill = 'Clothcraft',  reward = { marks = 350 },          maxPerDay = 3  },

    -- ── WOODWORKING ──────────────────────────────────────────────────────────
    { itemId = 1610, name = 'Elm Lumber +1',           skill = 'Woodworking', reward = { marks =  60 },          maxPerDay = 10 },
    { itemId = 1619, name = 'Ebony Lumber +1',         skill = 'Woodworking', reward = { marks = 200 },          maxPerDay = 5  },
    { itemId = 1621, name = 'Phrygian Lumber +1',      skill = 'Woodworking', reward = { marks = 450 },          maxPerDay = 3  },

    -- ── ALCHEMY ──────────────────────────────────────────────────────────────
    { itemId =  763, name = 'Hi-Potion +1',            skill = 'Alchemy',     reward = { marks =  50 },          maxPerDay = 10 },
    { itemId =  768, name = 'Vile Elixir +1',          skill = 'Alchemy',     reward = { marks = 200 },          maxPerDay = 5  },
    { itemId = 4400, name = 'Firesand +1',             skill = 'Alchemy',     reward = { marks = 180 },          maxPerDay = 5  },

    -- ── COOKING ──────────────────────────────────────────────────────────────
    { itemId = 4518, name = 'Tavnazian Salad +1',      skill = 'Cooking',     reward = { marks = 100 },          maxPerDay = 5  },
    { itemId = 4527, name = 'Marinara Pizza +1',       skill = 'Cooking',     reward = { marks = 150 },          maxPerDay = 5  },
    { itemId = 4509, name = 'Emperor Eel +1',          skill = 'Cooking',     reward = { marks = 300 },          maxPerDay = 3  },

    -- ── GOLDSMITHING ─────────────────────────────────────────────────────────
    { itemId = 1727, name = 'Gold Ingot +1',           skill = 'Goldsmithing',reward = { marks = 300 },          maxPerDay = 3  },
    { itemId = 1732, name = 'Mythril Ingot +1',        skill = 'Goldsmithing',reward = { marks = 200 },          maxPerDay = 5  },
    { itemId = 1730, name = 'Platinum Ingot +1',       skill = 'Goldsmithing',reward = { marks = 500 },          maxPerDay = 2  },

    -- ── LEATHERCRAFT ─────────────────────────────────────────────────────────
    { itemId = 1557, name = 'Dhalmel Hide +1',         skill = 'Leathercraft',reward = { marks =  90 },          maxPerDay = 10 },
    { itemId = 1562, name = 'Peiste Skin +1',          skill = 'Leathercraft',reward = { marks = 280 },          maxPerDay = 3  },

    -- ── BONECRAFT ────────────────────────────────────────────────────────────
    { itemId = 1687, name = 'Dragon Bone +1',          skill = 'Bonecraft',   reward = { marks = 250 },          maxPerDay = 3  },
    { itemId = 1683, name = 'Bone Chip +1',            skill = 'Bonecraft',   reward = { marks =  60 },          maxPerDay = 10 },
}

-- Daily cap CV prefix.  DB_Craft_<itemId>_Day = YYYYDDD of last trade day.
catalog.cvDayPrefix   = 'DB_Craft_'
catalog.cvDaySuffix   = '_Day'
-- DB_Craft_<itemId>_Count = trades today (reset at new day).
catalog.cvCountSuffix = '_Count'

return catalog
