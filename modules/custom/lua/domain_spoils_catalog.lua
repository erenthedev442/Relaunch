-----------------------------------
-- domain_spoils_catalog.lua
-- Config for the Domain Quartermaster NPC (DomainSpoils_NPC.lua reads it).
--
-- Owner request 2026-07-10: the 86 Zurim (Domain Points) items that upstream
-- shipped statless are now implemented (sql/zz_zurim_gear_mods.sql) and should
-- ALSO be purchasable with HUNT MARKS so they're farmable outside the
-- Domain Invasion daily-cap loop. This vendor charges the HL_Points CharVar
-- via the native shop window (same engine as the Infamy Vendor).
--
-- Pricing (owner rebalance 2026-07-12): 5,000-mark floor across the board.
-- Every previous tier (40/80/100/200/600/800/1000 DP) now sells for 5,000 Hunt
-- Marks flat. Rationale: match the Infamy Vendor's 3,000-mark floor pattern
-- but at a higher endgame gate for Domain items. DP daily cap (80) is
-- unchanged; marks flow freely from waves/dailies + gil exchange 400k gil/mark.
--
-- Each row: { id, cat, sub, name, cost }. cat/sub drive the browse menus.
-- Weapons sub = WEAPON TYPE (per item_weapon.skill; owner request 2026-07-11),
-- with Grip-Shield and Ammo kept as slot buckets; the content source
-- (Fete T2/Reisenjima/Voluspa) still shows in section comments + price tiers.
-- NOTE: these items stay OFF the medal (bronze/silver/gold) vendors -- they are
-- obtainable from Zurim + here, so medal-vendor exclusivity would be violated
-- (tools/validate_vendor_exclusivity.py enforces).
-----------------------------------
local catalog = {}

catalog.currencyCv = 'HL_Points'   -- Hunt Marks (matches HuntingLeague CV_POINTS)

-- Hub placement (Purgonorgo Isle, zone 44), on the vendor row near the Infamy
-- Vendor (554.971, 520.586). Nudge with !pos in-game if it clips a neighbor.
catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        =  551.000,
    y        =   -3.3322,
    z        =  475.600,
    rotation =   96,
}

catalog.vendorItems =
{
    -- ============ Domain Invasion armor (Zurim 40 DP -> 100 marks) ============
    { id = 23738, cat = 'Armor', sub = 'Head',  name = 'Hervor Galea',        cost = 5000 },
    { id = 23739, cat = 'Armor', sub = 'Head',  name = 'Heidrek Mask',        cost = 5000 },
    { id = 23741, cat = 'Armor', sub = 'Body',  name = 'Hervor Haubert',      cost = 5000 },
    { id = 23743, cat = 'Armor', sub = 'Body',  name = 'Angantyr Robe',       cost = 5000 },
    { id = 23744, cat = 'Armor', sub = 'Hands', name = 'Hervor Mouffles',     cost = 5000 },
    { id = 23745, cat = 'Armor', sub = 'Hands', name = 'Heidrek Gloves',      cost = 5000 },
    { id = 23746, cat = 'Armor', sub = 'Hands', name = 'Angantyr Mittens',    cost = 5000 },
    { id = 23747, cat = 'Armor', sub = 'Legs',  name = 'Hervor Brayettes',    cost = 5000 },
    { id = 23748, cat = 'Armor', sub = 'Legs',  name = 'Heidrek Brais',       cost = 5000 },
    { id = 23749, cat = 'Armor', sub = 'Legs',  name = 'Angantyr Tights',     cost = 5000 },
    { id = 23750, cat = 'Armor', sub = 'Feet',  name = 'Hervor Sollerets',    cost = 5000 },
    { id = 23751, cat = 'Armor', sub = 'Feet',  name = 'Heidrek Boots',       cost = 5000 },
    { id = 23752, cat = 'Armor', sub = 'Feet',  name = 'Angantyr Boots',      cost = 5000 },

    -- ============ Voluspa grip / shield (Zurim 80 DP -> 200 marks) ============
    { id = 22219, cat = 'Weapons', sub = 'Grip-Shield', name = 'Voluspa Grip',   cost = 5000 },
    { id = 26413, cat = 'Weapons', sub = 'Grip-Shield', name = 'Voluspa Shield', cost = 5000 },

    -- ============ Dragon accessories (Zurim 100 DP -> 250 marks) ==============
    { id = 26163, cat = 'Accessories', sub = 'Ring',  name = 'Etana Ring',      cost = 5000 },
    { id = 27616, cat = 'Accessories', sub = 'Back',  name = 'Izdubar Mantle',  cost = 5000 },
    { id = 26245, cat = 'Accessories', sub = 'Back',  name = 'Solemnity Cape',  cost = 5000 },

    -- ============ T2 Geas Fete weapons (Zurim 200 DP -> 500 marks) ============

    -- ============ Skill earrings (Zurim 600 DP -> 1500 marks) =================
    { id = 26092, cat = 'Accessories', sub = 'Ear', name = 'Hretha Earring',   cost = 5000 },
    { id = 26089, cat = 'Accessories', sub = 'Ear', name = 'Ran Earring',      cost = 5000 },
    { id = 26091, cat = 'Accessories', sub = 'Ear', name = 'Foresti Earring',  cost = 5000 },
    { id = 26090, cat = 'Accessories', sub = 'Ear', name = 'Hermodr Earring',  cost = 5000 },
    { id = 26093, cat = 'Accessories', sub = 'Ear', name = 'Saxnot Earring',   cost = 5000 },
    { id = 26098, cat = 'Accessories', sub = 'Ear', name = 'Meili Earring',    cost = 5000 },
    { id = 26095, cat = 'Accessories', sub = 'Ear', name = 'Mimir Earring',    cost = 5000 },
    { id = 26096, cat = 'Accessories', sub = 'Ear', name = 'Vor Earring',      cost = 5000 },
    { id = 26097, cat = 'Accessories', sub = 'Ear', name = 'Ilmr Earring',     cost = 5000 },
    { id = 26094, cat = 'Accessories', sub = 'Ear', name = 'Mani Earring',     cost = 5000 },
    { id = 26099, cat = 'Accessories', sub = 'Ear', name = 'Lodurr Earring',   cost = 5000 },
    { id = 26104, cat = 'Accessories', sub = 'Ear', name = 'Njordr Earring',   cost = 5000 },
    { id = 26101, cat = 'Accessories', sub = 'Ear', name = 'Bragi Earring',    cost = 5000 },
    { id = 26103, cat = 'Accessories', sub = 'Ear', name = 'Dellingr Earring', cost = 5000 },
    { id = 26102, cat = 'Accessories', sub = 'Ear', name = 'Gersemi Earring',  cost = 5000 },
    { id = 26100, cat = 'Accessories', sub = 'Ear', name = 'Hnoss Earring',    cost = 5000 },
    { id = 26105, cat = 'Accessories', sub = 'Ear', name = 'Gna Earring',      cost = 5000 },
    { id = 26106, cat = 'Accessories', sub = 'Ear', name = 'Fulla Earring',    cost = 5000 },

    -- ============ Reisenjima Fete weapons (Zurim 800 DP -> 2000 marks) ========

    -- ============ Reisenjima Fete armor (Zurim 800 DP -> 2000 marks) ==========

    -- ============ Endgame accessories / ammo (Zurim 1000 DP -> 2500 marks) ====
    { id = 22294, cat = 'Weapons', sub = 'Ammo', name = 'Hauksbok Bolt',     cost = 5000 },
    { id = 22295, cat = 'Weapons', sub = 'Ammo', name = 'Hauksbok Bullet',   cost = 5000 },
    { id = 22296, cat = 'Weapons', sub = 'Ammo', name = 'Voluspa Tathlum',   cost = 5000 },
    { id = 26353, cat = 'Accessories', sub = 'Waist', name = 'Ask Sash',          cost = 5000 },
    { id = 26354, cat = 'Accessories', sub = 'Waist', name = 'Embla Sash',        cost = 5000 },
    { id = 26355, cat = 'Accessories', sub = 'Waist', name = 'Audumbla Sash',     cost = 5000 },
    { id = 26111, cat = 'Accessories', sub = 'Ear',   name = 'Beyla Earring',     cost = 5000 },
    { id = 26112, cat = 'Accessories', sub = 'Ear',   name = 'Tuisto Earring',    cost = 5000 },
    { id = 26113, cat = 'Accessories', sub = 'Ear',   name = 'Nehalennia Earring', cost = 5000 },
    { id = 26110, cat = 'Accessories', sub = 'Ear',   name = 'Sjofn Earring',     cost = 5000 },

    -- ================================================================
    -- Zurim gap fill 2026-07-10: Domain/Geas items sold ONLY by Zurim
    -- (daily-capped) + obtainable nowhere else -> now marks-farmable here.
    -- Priced Domain-Points x 2.5 like the rest. (Statless Voluspa set pending.)
    -- ================================================================
    { id = 23742, cat = 'Armor', sub = 'Body', name = 'Heidrek Harness', cost = 5000 },
    { id = 26109, cat = 'Accessories', sub = 'Ear', name = 'Snotra Earring', cost = 5000 },
    { id = 26040, cat = 'Accessories', sub = 'Neck', name = 'Yngvi Choker', cost = 5000 },
    { id = 26216, cat = 'Accessories', sub = 'Ring', name = 'Dreki Ring', cost = 5000 },
    { id = 26323, cat = 'Accessories', sub = 'Waist', name = 'Gishdubar Sash', cost = 5000 },

    -- Voluspa weapon set + 2 armor bases (statted 2026-07-10 via zz_zurim_gear_mods.sql)
    { id = 21510, cat = 'Weapons', sub = 'Hand-to-Hand', name = 'Voluspa Knuckles', cost = 5000 },
    { id = 21566, cat = 'Weapons', sub = 'Dagger', name = 'Voluspa Knife', cost = 5000 },
    { id = 21622, cat = 'Weapons', sub = 'Sword', name = 'Voluspa Sword', cost = 5000 },
    { id = 21665, cat = 'Weapons', sub = 'Gt. Sword', name = 'Voluspa Blade', cost = 5000 },
    { id = 21769, cat = 'Weapons', sub = 'Gt. Axe', name = 'Voluspa Chopper', cost = 5000 },
    { id = 21822, cat = 'Weapons', sub = 'Scythe', name = 'Voluspa Scythe', cost = 5000 },
    { id = 21864, cat = 'Weapons', sub = 'Polearm', name = 'Voluspa Lance', cost = 5000 },
    { id = 21912, cat = 'Weapons', sub = 'Katana', name = 'Voluspa Katana', cost = 5000 },
    { id = 21976, cat = 'Weapons', sub = 'Gt. Katana', name = 'Voluspa Tachi', cost = 5000 },
    { id = 22006, cat = 'Weapons', sub = 'Club', name = 'Voluspa Hammer', cost = 5000 },
    { id = 22088, cat = 'Weapons', sub = 'Staff', name = 'Voluspa Pole', cost = 5000 },
    { id = 22133, cat = 'Weapons', sub = 'Archery', name = 'Voluspa Bow', cost = 5000 },
    { id = 22144, cat = 'Weapons', sub = 'Marksmanship', name = 'Voluspa Gun', cost = 5000 },
    { id = 23740, cat = 'Armor', sub = 'Head', name = 'Angantyr Beret', cost = 5000 },

    -- Ammo pouches (Zurim 80 DP -> 200 marks). Player request 2026-07-10:
    -- Date Shuriken shares Zurim's 80 DP pool with the Voluspa pouches, so all
    -- four dispensers belong here too. Usable items (99x ammo per use), sold
    -- through the same native shop window as everything else.
    { id = 6420, cat = 'Weapons', sub = 'Ammo', name = 'Voluspa Quiver',      cost = 5000 },
    { id = 6429, cat = 'Weapons', sub = 'Ammo', name = 'Voluspa Bolt Quiver', cost = 5000 },
    { id = 6438, cat = 'Weapons', sub = 'Ammo', name = 'Voluspa Bullet Pouch', cost = 5000 },
    { id = 6449, cat = 'Weapons', sub = 'Ammo', name = 'Date Shuriken Pouch', cost = 5000 },
}

return catalog
