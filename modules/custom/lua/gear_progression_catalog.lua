-----------------------------------
-- gear_progression_catalog.lua
-- Weapons-only progression catalog for the Gear Progression NPC.
--
-- HOW TO ADD A WEAPON:
--   Pick a tier (bronze / silver / gold), then add a line to its `weapons` list:
--     { id = xi.item.ITEM_CONSTANT, name = 'Display Name', cost = N, jobs = 'JOB/JOB' }
--   If the item has no xi.item constant, use the raw numeric ID instead.
--   Find item IDs in: scripts/enum/item.lua
--
-- MEDAL COSTS (suggested baseline - adjust freely):
--   Bronze : 10-30  Beastmens Medals
--   Silver : 10-30  Kindreds Medals
--   Gold   : 10-30  Demons Medals
--
-- Each rarity must contain no more than 16 items (the native shop limit).
-----------------------------------
local catalog = {}

-----------------------------------
-- ZONE / NPC PLACEMENT
--   Single source of truth for:
--     - GearProgression_NPC.lua : override registration + NPC position
--     - docgen                  : gear-vendors.md location table + zone name
-----------------------------------
catalog.zoneId    = xi.zone.ESCHA_ZITAH
catalog.zonePath  = 'xi.zones.Escha_ZiTah'
catalog.vendorPos = { x =  -6.0000, y = -0.5000, z = -30.0000, rot = 128 }

-----------------------------------
-- SEAL CURRENCY DEFINITIONS
-----------------------------------
-- All three are orphan currency items in item_basic.sql (no current drop
-- source) - exclusive Hunting League currency loop. Raw IDs because
-- xi.item.* enum entries don't exist for these medals.
catalog.seals =
{
    bronze = { id = 9539, name = "Beastmens Medal" },
    silver = { id = 9541, name = "Kindreds Medal"  },
    gold   = { id = 9543, name = "Demons Medal"    },
}

-----------------------------------
-- Legacy weapon-category helpers used only by the inert Infamy export below.
-----------------------------------
local function emptyCategories()
    return
    {
        { label = 'Swords',         items = {} },
        { label = 'Daggers',        items = {} },
        { label = 'Clubs',          items = {} },
        { label = 'Staves',         items = {} },
        { label = 'Great Swords',   items = {} },
        { label = 'Axes',           items = {} },
        { label = 'Great Axes',     items = {} },
        { label = 'Scythes',        items = {} },
        { label = 'Polearms',       items = {} },
        { label = 'Katana',         items = {} },
        { label = 'Great Katana',   items = {} },
        { label = 'Archery',        items = {} },
        { label = 'Marksmanship',   items = {} },
        { label = 'Hand-to-Hand',   items = {} },
        { label = 'Instruments',    items = {} },
    }
end

-- Convenience: index by category label so we can append without remembering
-- the slot index (Swords = [1], etc.).
local function cat(weaponsList, label)
    for _, g in ipairs(weaponsList) do
        if g.label == label then return g.items end
    end
    error('unknown weapon category: ' .. label)
end

-----------------------------------
-- BRONZE TIER
-----------------------------------
catalog.bronze =
{
    weapons =
    {
        -- 2026-07: removed Tokko Knuckles (21515) -- it is the Hand-to-Hand Stage-2 (119II)
        -- forge output in weapon_forge_catalog.lua, so selling it here violates the
        -- medal-vendor exclusivity rule (validate_vendor_exclusivity.py). MNK/PUP keep
        -- silver Premium Heart, the Infamy H2H picks, and the forge path itself.
        { id = 21274, name = "Donar Gun", cost = 12, jobs = 'THF/RNG/NIN/COR' },
    },
}

-----------------------------------
-- SILVER TIER
-----------------------------------
catalog.silver =
{
    weapons =
    {
        { id = 20615, name = "Levante Dagger", cost = 25, jobs = 'WAR/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/SCH/GEO' },
        { id = 20808, name = "Tramontane Axe", cost = 25, jobs = 'WAR/DRK/BST/RUN' },
        { id = 20827, name = "Kerehcatl", cost = 25, jobs = 'WAR/BST' },
        { id = 20893, name = "Shukuyus Scythe", cost = 25, jobs = 'WAR/DRK/BST' },
        { id = 20945, name = "Nativus Halberd", cost = 25, jobs = 'WAR/PLD/SAM/DRG' },
        { id = 21104, name = "Eosuchus Club", cost = 25, jobs = 'All' },
        { id = 21228, name = "Falubeza", cost = 25, jobs = 'RNG' },
        { id = 21256, name = "Illapa", cost = 25, jobs = 'RNG' },
        { id = 21529, name = "Premium Heart", cost = 25, jobs = 'MNK/PUP' },
        -- 7 Voluspa weapons removed 2026-07-11: sold by Zurim (Domain Points)
        -- and the Domain Quartermaster (Hunt Marks), so keeping them here broke
        -- medal-vendor exclusivity (validate_vendor_exclusivity.py).
        { id = 21568, name = "Acrontica", cost = 25, jobs = 'THF/DNC' },
        { id = 21569, name = "Chocobo Knife", cost = 25, jobs = 'RDM/THF/BRD/RNG/DNC' },
        { id = 21570, name = "Air Knife", cost = 25, jobs = 'THF/DNC' },
        { id = 22118, name = "Venery Bow", cost = 25, jobs = 'RNG' },
        { id = 22119, name = "Wochowsen", cost = 25, jobs = 'RNG' },
    },
}

-----------------------------------
-- GOLD TIER
-----------------------------------
catalog.gold =
{
    weapons =
    {
        { id = 21273, name = "Nibiru Gun", cost = 50, jobs = 'RNG/COR' },
    },
}
-----------------------------------
-- INFAMY TIER  (top-5-per-category; promoted to the Dungeon Infamy
--   Vendor by tools/build_infamy_top_picks.py. Inert here: the
--   Weapons NPC only sells bronze/silver/gold.)
-----------------------------------
catalog.infamy = { weapons = emptyCategories() }
do
    -- Hand-to-Hand: 5 pick(s) -> Infamy Vendor
    local inf_h2h = cat(catalog.infamy.weapons, 'Hand-to-Hand')
    table.insert(inf_h2h, { id = 21535, name = "Varga Purnikawa", cost = 500, jobs = 'MNK/PUP' })  -- WS score 329, DMG 213/Dly 596
    table.insert(inf_h2h, { id = 21527, name = "Sakpatas Fists", cost = 500, jobs = 'MNK/PUP' })  -- DPS score 275, DMG 165/Dly 576
    table.insert(inf_h2h, { id = 21528, name = "Dragon Fangs", cost = 500, jobs = 'MNK/PUP' })  -- WS score 214, DMG 188/Dly 606

    -- Daggers: 5 pick(s) -> Infamy Vendor
    local inf_daggers = cat(catalog.infamy.weapons, 'Daggers')
    table.insert(inf_daggers, { id = 21567, name = "Gletis Knife", cost = 500, jobs = 'RDM/THF/BRD/RNG/NIN/COR/DNC' })  -- DPS score 326, DMG 133/Dly 200
    table.insert(inf_daggers, { id = 21590, name = "Mpu Gandring", cost = 500, jobs = 'RDM/THF/BRD/DNC' })  -- DPS score 322, DMG 137/Dly 176

    -- Swords: 5 pick(s) -> Infamy Vendor
    local inf_swords = cat(catalog.infamy.weapons, 'Swords')
    table.insert(inf_swords, { id = 20672, name = "Ice Brand", cost = 500, jobs = 'RDM/PLD/BLU' })  -- CASTER score 1060, DMG 187/Dly 264
    table.insert(inf_swords, { id = 21637, name = "Sakpatas Sword", cost = 500, jobs = 'RDM/PLD/BLU' })  -- CASTER score 977, DMG 160/Dly 240
    table.insert(inf_swords, { id = 21646, name = "Caliburnus", cost = 500, jobs = 'RDM/PLD/BLU' })  -- CASTER score 935, DMG 181/Dly 233

    -- Great Swords: 5 pick(s) -> Infamy Vendor
    local inf_greatswords = cat(catalog.infamy.weapons, 'Great Swords')
    table.insert(inf_greatswords, { id = 21683, name = "Ragnarok 119 Iii", cost = 500, jobs = 'WAR/PLD/DRK' })  -- WS score 296, DMG 304/Dly 431
    table.insert(inf_greatswords, { id = 21653, name = "Helheim", cost = 500, jobs = 'WAR/PLD/DRK/RUN' })  -- WS score 264, DMG 318/Dly 431
    table.insert(inf_greatswords, { id = 21663, name = "Raetic Algol +1", cost = 500, jobs = 'WAR/PLD/DRK/RUN' })  -- WS score 256, DMG 327/Dly 474

    -- Axes: 5 pick(s) -> Infamy Vendor
    local inf_axes = cat(catalog.infamy.weapons, 'Axes')
    table.insert(inf_axes, { id = 21707, name = "Barbarity +1", cost = 500, jobs = 'WAR/BST' })  -- WS score 250, DMG 189/Dly 280
    table.insert(inf_axes, { id = 21712, name = "Voluspa Axe", cost = 500, jobs = 'WAR/DRK/BST/RUN' })  -- WS score 185, DMG 169/Dly 312

    -- Great Axes: 5 pick(s) -> Infamy Vendor
    local inf_greataxes = cat(catalog.infamy.weapons, 'Great Axes')
    table.insert(inf_greataxes, { id = 21766, name = "Hepatizon Axe +1", cost = 500, jobs = 'WAR/DRK/RUN' })  -- WS score 273, DMG 330/Dly 489
    table.insert(inf_greataxes, { id = 21768, name = "Raetic Chopper +1", cost = 500, jobs = 'WAR/BLM/DRK/BRD/SMN/SCH/RUN' })  -- WS score 262, DMG 337/Dly 489

    -- Scythes: 5 pick(s) -> Infamy Vendor
    local inf_scythes = cat(catalog.infamy.weapons, 'Scythes')
    table.insert(inf_scythes, { id = 21816, name = "Maliya Sickle +1", cost = 500, jobs = 'WAR/BLM/DRK/BST' })  -- WS score 272, DMG 328/Dly 490
    table.insert(inf_scythes, { id = 21819, name = "Raetic Scythe +1", cost = 500, jobs = 'WAR/BLM/DRK/BST' })  -- WS score 270, DMG 353/Dly 513

    -- Polearms: 5 pick(s) -> Infamy Vendor
    local inf_polearms = cat(catalog.infamy.weapons, 'Polearms')
    table.insert(inf_polearms, { id = 21870, name = "Exalted Spear +1", cost = 500, jobs = 'WAR/PLD/SAM/DRG' })  -- WS score 278, DMG 259/Dly 385
    table.insert(inf_polearms, { id = 21872, name = "Raetic Halberd +1", cost = 500, jobs = 'WAR/BLM/PLD/BRD/SAM/DRG/SMN/SCH' })  -- WS score 226, DMG 265/Dly 385

    -- Great Katana: 5 pick(s) -> Infamy Vendor
    local inf_gkatana = cat(catalog.infamy.weapons, 'Great Katana')
    table.insert(inf_gkatana, { id = 21964, name = "Beryllium Tachi +1", cost = 500, jobs = 'SAM/NIN' })  -- WS score 286, DMG 275/Dly 407

    -- Clubs: 5 pick(s) -> Infamy Vendor
    local inf_clubs = cat(catalog.infamy.weapons, 'Clubs')
    table.insert(inf_clubs, { id = 22002, name = "Lorg Mor", cost = 500, jobs = 'WHM/GEO' })  -- CASTER score 1061, DMG 227/Dly 308
    table.insert(inf_clubs, { id = 22042, name = "Wizards Rod", cost = 500, jobs = 'BLM/RDM/SCH/GEO' })  -- CASTER score 1060, DMG 149/Dly 216
    table.insert(inf_clubs, { id = 22040, name = "Daybreak", cost = 500, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 1033, DMG 150/Dly 216
    table.insert(inf_clubs, { id = 21071, name = "Cath Palug Hammer", cost = 500, jobs = 'WHM/GEO' })  -- CASTER score 1013, DMG 212/Dly 300

    -- Staves: 5 pick(s) -> Infamy Vendor
    local inf_staves = cat(catalog.infamy.weapons, 'Staves')
    table.insert(inf_staves, { id = 22106, name = "Opashoro", cost = 500, jobs = 'BLM/SMN/SCH' })  -- CASTER score 1215, DMG 304/Dly 390
    table.insert(inf_staves, { id = 22055, name = "Oranyan", cost = 500, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 1054, DMG 230/Dly 366
    table.insert(inf_staves, { id = 22081, name = "Raetic Staff +1", cost = 500, jobs = 'WAR/MNK/WHM/BLM/RDM/BST/BRD/SMN/SCH/GEO' })  -- CASTER score 1019, DMG 245/Dly 356
    table.insert(inf_staves, { id = 22058, name = "Contemplator +1", cost = 500, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 1004, DMG 232/Dly 390

    -- Archery: 5 pick(s) -> Infamy Vendor
    local inf_archery = cat(catalog.infamy.weapons, 'Archery')
    table.insert(inf_archery, { id = 22114, name = "Steinthor", cost = 500, jobs = 'RNG' })  -- WS score 346, DMG 290/Dly 600
    table.insert(inf_archery, { id = 21221, name = "Brahmastra", cost = 500, jobs = 'RNG' })  -- WS score 326, DMG 261/Dly 600
    table.insert(inf_archery, { id = 22113, name = "Teller", cost = 500, jobs = 'RNG' })  -- WS score 322, DMG 270/Dly 600
    table.insert(inf_archery, { id = 22123, name = "Arasy Bow +1", cost = 500, jobs = 'RNG' })  -- WS score 295, DMG 227/Dly 524
    table.insert(inf_archery, { id = 21220, name = "Paloma Bow +1", cost = 500, jobs = 'RNG' })  -- WS score 272, DMG 220/Dly 480

    -- Marksmanship: 5 pick(s) -> Infamy Vendor
    local inf_marksmanship = cat(catalog.infamy.weapons, 'Marksmanship')
    table.insert(inf_marksmanship, { id = 22164, name = "Earp", cost = 500, jobs = 'RNG/COR' })  -- WS score 448, DMG 162/Dly 582
    table.insert(inf_marksmanship, { id = 22121, name = "Imati +1", cost = 500, jobs = 'RNG' })  -- WS score 307, DMG 146/Dly 424
    table.insert(inf_marksmanship, { id = 21485, name = "Fomalhaut", cost = 500, jobs = 'RNG/COR' })  -- WS score 270, DMG 167/Dly 600
    table.insert(inf_marksmanship, { id = 22136, name = "Arasy Gun +1", cost = 500, jobs = 'RNG/COR' })  -- WS score 252, DMG 108/Dly 582
    table.insert(inf_marksmanship, { id = 19209, name = "Molybdosis", cost = 500, jobs = 'COR' })  -- WS score 222, DMG 103/Dly 480

end
return catalog
