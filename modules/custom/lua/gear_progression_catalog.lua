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
        -- HUNT-VENDOR BATCH (owner 2026-07-13): exclusive Escha/Delve weapons (flat ilvl band)
        { id = 20955, name = "Agilis Lance", cost = 12, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 109
        { id = 20910, name = "Anaimatos Scythe", cost = 12, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 109
        { id = 20819, name = "Antican Axe", cost = 12, jobs = 'WAR/DRK/BST/RNG/RUN', cat = 'Axes' },  -- ilvl 109
        { id = 20776, name = "Beorc Sword", cost = 12, jobs = 'RUN', cat = 'Great Swords' },  -- ilvl 109
        { id = 20626, name = "Blitto Needle", cost = 12, jobs = 'RDM/THF/BRD/RNG/NIN', cat = 'Daggers' },  -- ilvl 109
        { id = 21185, name = "Boonwell Staff", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO', cat = 'Staves' },  -- ilvl 109
        { id = 21045, name = "Bukyoku", cost = 12, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 109
        { id = 20823, name = "Camaraderie Axe", cost = 12, jobs = 'WAR/BST', cat = 'Axes' },  -- ilvl 109
        { id = 20735, name = "Camaraderie Blade", cost = 12, jobs = 'RDM/PLD/BLU', cat = 'Swords' },  -- ilvl 109
        { id = 21235, name = "Camaraderie Bow", cost = 12, jobs = 'RNG', cat = 'Archery' },  -- ilvl 109
        { id = 21254, name = "Camaraderie Bowgun", cost = 12, jobs = 'RNG', cat = 'Marksmanship' },  -- ilvl 109
        { id = 20771, name = "Camaraderie Claymore", cost = 12, jobs = 'PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 109
        { id = 20633, name = "Camaraderie Dagger", cost = 12, jobs = 'THF/BRD/DNC', cat = 'Daggers' },  -- ilvl 109
        { id = 21285, name = "Camaraderie Gun", cost = 12, jobs = 'RNG/COR', cat = 'Marksmanship' },  -- ilvl 109
        { id = 21003, name = "Camaraderie Katana", cost = 12, jobs = 'NIN', cat = 'Katana' },  -- ilvl 109
        { id = 20545, name = "Camaraderie Knuckles", cost = 12, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 109
        { id = 20960, name = "Camaraderie Lance", cost = 12, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 109
        { id = 21189, name = "Camaraderie Pole", cost = 12, jobs = 'SMN', cat = 'Staves' },  -- ilvl 109
        { id = 20869, name = "Camaraderie Reaver", cost = 12, jobs = 'WAR/DRK/RUN', cat = 'Great Axes' },  -- ilvl 109
        { id = 20914, name = "Camaraderie Scythe", cost = 12, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 109
        { id = 21188, name = "Camaraderie Staff", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO', cat = 'Staves' },  -- ilvl 109
        { id = 21050, name = "Camaraderie Tachi", cost = 12, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 109
        { id = 21123, name = "Camaraderie Wand", cost = 12, jobs = 'WHM/BLM/RDM/SMN/BLU/SCH/GEO', cat = 'Clubs' },  -- ilvl 109
        { id = 20957, name = "Concido Course", cost = 12, jobs = 'WAR/SAM/DRG', cat = 'Polearms' },  -- ilvl 109
        { id = 21124, name = "Dowsers Wand", cost = 12, jobs = 'GEO', cat = 'Clubs' },  -- ilvl 109
        { id = 20542, name = "Gnafrons Adargas", cost = 12, jobs = 'PUP', cat = 'Hand-to-Hand' },  -- ilvl 109
        { id = 20999, name = "Habukatana", cost = 12, jobs = 'NIN', cat = 'Katana' },  -- ilvl 109
        { id = 20818, name = "Hurlbat", cost = 12, jobs = 'RNG', cat = 'Axes' },  -- ilvl 109
        { id = 20728, name = "Kheshig Blade", cost = 12, jobs = 'PLD', cat = 'Swords' },  -- ilvl 109
        { id = 21046, name = "Kiikanemitsu", cost = 12, jobs = 'SAM/NIN', cat = 'Great Katana' },  -- ilvl 109
        { id = 20911, name = "Last Rest", cost = 12, jobs = 'WAR/BLM/DRK/BST', cat = 'Scythes' },  -- ilvl 109
        { id = 20629, name = "Legato Dagger", cost = 12, jobs = 'BRD', cat = 'Daggers' },  -- ilvl 109
        { id = 21000, name = "Magorokuhocho", cost = 12, jobs = 'NIN', cat = 'Katana' },  -- ilvl 109
        { id = 20767, name = "Medicor Sword", cost = 12, jobs = 'WAR/PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 109
        { id = 20628, name = "Mindmeld Kris", cost = 12, jobs = 'BLM/SMN/SCH/GEO', cat = 'Daggers' },  -- ilvl 109
        { id = 21252, name = "One-Eyed", cost = 12, jobs = 'THF/RNG', cat = 'Marksmanship' },  -- ilvl 109
        { id = 20866, name = "Parashu", cost = 12, jobs = 'WAR/DRK/RUN', cat = 'Great Axes' },  -- ilvl 109
        { id = 21120, name = "Patriarch Cane", cost = 12, jobs = 'WHM/BLM/SMN/SCH/GEO', cat = 'Clubs' },  -- ilvl 109
        { id = 21232, name = "Phulax Bow", cost = 12, jobs = 'WAR/RDM/THF/PLD/DRK/BST/RNG/SAM/NIN', cat = 'Archery' },  -- ilvl 109
        { id = 20541, name = "Pinion Cesti", cost = 12, jobs = 'MNK', cat = 'Hand-to-Hand' },  -- ilvl 109
        { id = 20730, name = "Predatrice", cost = 12, jobs = 'BLU', cat = 'Swords' },  -- ilvl 109
        { id = 21282, name = "Qasama Hexagun", cost = 12, jobs = 'COR', cat = 'Marksmanship' },  -- ilvl 109
        { id = 20625, name = "Secespita", cost = 12, jobs = 'RDM', cat = 'Daggers' },  -- ilvl 109
        { id = 20956, name = "Sibat", cost = 12, jobs = 'WAR/PLD/SAM/DRG', cat = 'Polearms' },  -- ilvl 109
        { id = 20627, name = "Surcoufs Jambiya", cost = 12, jobs = 'COR', cat = 'Daggers' },  -- ilvl 109
        { id = 21184, name = "Surma Staff", cost = 12, jobs = 'MNK/WHM/PLD/DRG', cat = 'Staves' },  -- ilvl 109
        { id = 20727, name = "Tabahi Fleuret", cost = 12, jobs = 'RDM/DRG', cat = 'Swords' },  -- ilvl 109
        { id = 20749, name = "Trial Blade", cost = 12, jobs = 'RUN', cat = 'Great Swords' },  -- ilvl 109
        { id = 21066, name = "Trial Wand", cost = 12, jobs = 'GEO', cat = 'Clubs' },  -- ilvl 109
        { id = 20729, name = "Vivifiante", cost = 12, jobs = 'WAR/RDM/THF/PLD/DRK/BRD/RNG/NIN/DRG/BLU/RUN', cat = 'Swords' },  -- ilvl 109
        { id = 20740, name = "Camatlatia", cost = 12, jobs = 'RDM/PLD/BLU', cat = 'Swords' },  -- ilvl 106
        { id = 21454, name = "Forefront Animator", cost = 12, jobs = 'PUP', cat = 'Grips' },  -- ilvl 106
        { id = 20825, name = "Forefront Axe", cost = 12, jobs = 'WAR/BST', cat = 'Axes' },  -- ilvl 106
        { id = 20737, name = "Forefront Blade", cost = 12, jobs = 'WAR/THF/DRK/BST/RNG/SAM/BLU', cat = 'Swords' },  -- ilvl 106
        { id = 21237, name = "Forefront Bow", cost = 12, jobs = 'RNG', cat = 'Archery' },  -- ilvl 106
        { id = 21255, name = "Forefront Bowgun", cost = 12, jobs = 'RNG', cat = 'Marksmanship' },  -- ilvl 106
        { id = 20547, name = "Forefront Cesti", cost = 12, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 106
        { id = 20777, name = "Forefront Claymore", cost = 12, jobs = 'PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 106
        { id = 20635, name = "Forefront Dagger", cost = 12, jobs = 'THF/BRD/DNC', cat = 'Daggers' },  -- ilvl 106
        { id = 21287, name = "Forefront Gun", cost = 12, jobs = 'RNG/COR', cat = 'Marksmanship' },  -- ilvl 106
        { id = 20871, name = "Forefront Labrys", cost = 12, jobs = 'WAR', cat = 'Great Axes' },  -- ilvl 106
        { id = 20962, name = "Forefront Lance", cost = 12, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 106
        { id = 21197, name = "Forefront Scepter", cost = 12, jobs = 'SMN', cat = 'Staves' },  -- ilvl 106
        { id = 20916, name = "Forefront Scythe", cost = 12, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 106
        { id = 21196, name = "Forefront Staff", cost = 12, jobs = 'BLM/SCH/GEO', cat = 'Staves' },  -- ilvl 106
        { id = 21127, name = "Forefront Wand", cost = 12, jobs = 'WHM/BLM/RDM/SMN/BLU/SCH/GEO', cat = 'Clubs' },  -- ilvl 106
        { id = 21014, name = "Ichijintanto", cost = 12, jobs = 'NIN', cat = 'Katana' },  -- ilvl 106
        { id = 21059, name = "Ichijinto", cost = 12, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 106
        { id = 20829, name = "Icoyoca", cost = 12, jobs = 'WAR/BST', cat = 'Axes' },  -- ilvl 106
        { id = 20643, name = "Macoquetza", cost = 12, jobs = 'RDM/THF/BRD/RNG/NIN/COR/DNC', cat = 'Daggers' },  -- ilvl 106
        { id = 21054, name = "Suijingiri Kanemitsu", cost = 12, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 106
        { id = 20554, name = "Tlalpoloani", cost = 12, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 106
        { id = 20965, name = "Tlamini", cost = 12, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 106
        { id = 21257, name = "Zoquittihuitz", cost = 12, jobs = 'RNG', cat = 'Marksmanship' },  -- ilvl 106
        { id = 21191, name = "Voay Staff -1", cost = 12, jobs = 'WAR/MNK/WHM/BLM/PLD/BRD/DRG/SMN/SCH/GEO', cat = 'Staves' },  -- ilvl 105
        { id = 20772, name = "Voay Sword -1", cost = 12, jobs = 'PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 105
        { id = 21205, name = "Avitap Pole", cost = 12, jobs = 'SMN', cat = 'Staves' },  -- ilvl 100
        { id = 20830, name = "Coalition Axe", cost = 12, jobs = 'WAR/BST', cat = 'Axes' },  -- ilvl 100
        { id = 20741, name = "Coalition Blade", cost = 12, jobs = 'RDM/PLD/BLU', cat = 'Swords' },  -- ilvl 100
        { id = 21241, name = "Coalition Bow", cost = 12, jobs = 'RNG', cat = 'Archery' },  -- ilvl 100
        { id = 20638, name = "Coalition Dirk", cost = 12, jobs = 'THF/BRD/DNC', cat = 'Daggers' },  -- ilvl 100
        { id = 20966, name = "Coalition Lance", cost = 12, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 100
        { id = 21131, name = "Coalition Rod", cost = 12, jobs = 'WHM/GEO', cat = 'Clubs' },  -- ilvl 100
        { id = 20782, name = "Coalition Sword", cost = 12, jobs = 'PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 100
        { id = 20921, name = "Fieldrazer Scythe", cost = 12, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 100
        { id = 21055, name = "Kashiwadachi", cost = 12, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 100
        { id = 21008, name = "Kotekirigo", cost = 12, jobs = 'NIN', cat = 'Katana' },  -- ilvl 100
        { id = 21291, name = "Shadeshot Gun", cost = 12, jobs = 'RNG/COR', cat = 'Marksmanship' },  -- ilvl 100
        { id = 21204, name = "Sortilevel Staff", cost = 12, jobs = 'BLM/SCH/GEO', cat = 'Staves' },  -- ilvl 100
        { id = 20876, name = "Trunkcleaver", cost = 12, jobs = 'WAR', cat = 'Great Axes' },  -- ilvl 100
        { id = 20550, name = "Vineslash Cesti", cost = 12, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 100
        -- 2026-07: removed Tokko Knuckles (21515) -- it is the Hand-to-Hand Stage-2 (119II)
        -- forge output in weapon_forge_catalog.lua, so selling it here violates the
        -- medal-vendor exclusivity rule (validate_vendor_exclusivity.py). MNK/PUP keep
        -- silver Premium Heart, the Infamy H2H picks, and the forge path itself.
        -- Donar Gun (21274) REMOVED 2026-07-13 (single-source: added to
        -- Trial by Lightning HTBF pool in commit f753d47641, vendor row is the duplicate).
    },
}

-----------------------------------
-- SILVER TIER
-----------------------------------
catalog.silver =
{
    weapons =
    {
        -- HUNT-VENDOR BATCH (owner 2026-07-13): exclusive Escha/Delve weapons (flat ilvl band)
        { id = 21233, name = "Ajjub Bow", cost = 25, jobs = 'RNG', cat = 'Archery' },  -- ilvl 115
        { id = 21253, name = "Atetepeyorg", cost = 25, jobs = 'RNG', cat = 'Marksmanship' },  -- ilvl 115
        { id = 20630, name = "Atoyac", cost = 25, jobs = 'RDM/THF/BRD/RNG/NIN/COR/DNC', cat = 'Daggers' },  -- ilvl 115
        { id = 21047, name = "Azukinagamitsu", cost = 25, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 115
        { id = 21186, name = "Baqil Staff", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO', cat = 'Staves' },  -- ilvl 115
        { id = 20820, name = "Hatxiik", cost = 25, jobs = 'WAR/BST', cat = 'Axes' },  -- ilvl 115
        { id = 20826, name = "Hunahpu", cost = 25, jobs = 'BST', cat = 'Axes' },  -- ilvl 115
        { id = 20872, name = "Ixtab", cost = 25, jobs = 'WAR', cat = 'Great Axes' },  -- ilvl 115
        { id = 20768, name = "Kaquljaan", cost = 25, jobs = 'WAR/PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 115
        { id = 20958, name = "Kuakuakait", cost = 25, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 115
        { id = 20543, name = "Maochinoli", cost = 25, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 115
        { id = 20992, name = "Taikogane", cost = 25, jobs = 'NIN', cat = 'Katana' },  -- ilvl 115
        { id = 21125, name = "Tamaxchi", cost = 25, jobs = 'WHM/BLM/RDM/SMN/BLU/SCH/GEO', cat = 'Clubs' },  -- ilvl 115
        { id = 20917, name = "Xbalanque", cost = 25, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 115
        { id = 20731, name = "Xiutleato", cost = 25, jobs = 'RDM/PLD/BLU', cat = 'Swords' },  -- ilvl 115
        { id = 21455, name = "Alternator", cost = 25, jobs = 'PUP', cat = 'Grips' },  -- ilvl 113
        { id = 20637, name = "Aphotic Kukri", cost = 25, jobs = 'WAR/THF/DRK/RNG/NIN/COR/PUP/DNC', cat = 'Daggers' },  -- ilvl 113
        { id = 20778, name = "Bereaver", cost = 25, jobs = 'PLD/DRK/RUN', cat = 'Great Swords' },  -- ilvl 113
        { id = 20873, name = "Bloodbath Axe", cost = 25, jobs = 'WAR', cat = 'Great Axes' },  -- ilvl 113
        { id = 20828, name = "Brethren Axe", cost = 25, jobs = 'BST', cat = 'Axes' },  -- ilvl 113
        { id = 20918, name = "Dimmet Scythe", cost = 25, jobs = 'DRK', cat = 'Scythes' },  -- ilvl 113
        { id = 20739, name = "Halachuinic Sword", cost = 25, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/NIN/DRG/BLU/COR/RUN', cat = 'Swords' },  -- ilvl 113
        { id = 21005, name = "Kiji", cost = 25, jobs = 'NIN', cat = 'Katana' },  -- ilvl 113
        { id = 21128, name = "Mondaha Cudgel", cost = 25, jobs = 'WAR/MNK/WHM/BLM/PLD/SMN/BLU/SCH/GEO', cat = 'Clubs' },  -- ilvl 113
        { id = 20964, name = "Ophidian Trident", cost = 25, jobs = 'DRG', cat = 'Polearms' },  -- ilvl 113
        { id = 20549, name = "Rigor Baghnakhs", cost = 25, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },  -- ilvl 113
        { id = 21198, name = "Soothsayer Staff", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO', cat = 'Staves' },  -- ilvl 113
        { id = 21238, name = "Speleogen Bow", cost = 25, jobs = 'RNG/SAM', cat = 'Archery' },  -- ilvl 113
        { id = 21288, name = "Surefire Arquebus", cost = 25, jobs = 'RNG/COR', cat = 'Marksmanship' },  -- ilvl 113
        { id = 21053, name = "Uguisumaru", cost = 25, jobs = 'SAM', cat = 'Great Katana' },  -- ilvl 113
        { id = 21199, name = "Yaskomos Pole", cost = 25, jobs = 'SMN', cat = 'Staves' },  -- ilvl 113
        -- Levante Dagger (20615) REMOVED 2026-07-13 (single-source: added to
        -- Trial by Wind HTBF pool in commit f753d47641, vendor row is the duplicate).
        -- Tramontane Axe (20808) REMOVED 2026-07-13 (single-source: added to
        -- Trial by Wind HTBF pool in commit f753d47641, vendor row is the duplicate).
        { id = 20827, name = "Kerehcatl", cost = 25, jobs = 'WAR/BST', cat = 'Axes' },
        { id = 20945, name = "Nativus Halberd", cost = 25, jobs = 'WAR/PLD/SAM/DRG', cat = 'Polearms' },
        { id = 21104, name = "Eosuchus Club", cost = 25, jobs = 'All', cat = 'Clubs' },
        { id = 21228, name = "Falubeza", cost = 25, jobs = 'RNG', cat = 'Archery' },
        { id = 21256, name = "Illapa", cost = 25, jobs = 'RNG', cat = 'Marksmanship' },
        { id = 21529, name = "Premium Heart", cost = 25, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' },
        -- 7 Voluspa weapons removed 2026-07-11: sold by Zurim (Domain Points)
        -- and the Domain Quartermaster (Hunt Marks), so keeping them here broke
        -- medal-vendor exclusivity (validate_vendor_exclusivity.py).
        { id = 21568, name = "Acrontica", cost = 25, jobs = 'THF/DNC', cat = 'Daggers' },
        { id = 21569, name = "Chocobo Knife", cost = 25, jobs = 'RDM/THF/BRD/RNG/DNC', cat = 'Daggers' },
        { id = 21570, name = "Air Knife", cost = 25, jobs = 'THF/DNC', cat = 'Daggers' },
    },
}

-----------------------------------
-- GOLD TIER
-----------------------------------
catalog.gold =
{
    weapons =
    {
        -- HUNT-VENDOR BATCH (owner 2026-07-13): exclusive Escha/Delve weapons (flat ilvl band)
        { id = 21478, name = "Moros Crossbow +1", cost = 50, jobs = 'RNG', cat = 'Marksmanship' },  -- ilvl 118
        { id = 21375, name = "Magneto", cost = 50, jobs = 'PUP', cat = 'Grips' },  -- ilvl 117
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
    table.insert(inf_h2h, { id = 21528, name = "Dragon Fangs", cost = 500, jobs = 'MNK/PUP', cat = 'Hand-to-Hand' })  -- WS score 214, DMG 188/Dly 606

    -- Daggers: 5 pick(s) -> Infamy Vendor
    local inf_daggers = cat(catalog.infamy.weapons, 'Daggers')

    -- Swords: 5 pick(s) -> Infamy Vendor
    local inf_swords = cat(catalog.infamy.weapons, 'Swords')
    table.insert(inf_swords, { id = 20672, name = "Ice Brand", cost = 500, jobs = 'RDM/PLD/BLU', cat = 'Swords' })  -- CASTER score 1060, DMG 187/Dly 264

    -- Great Swords: 5 pick(s) -> Infamy Vendor
    local inf_greatswords = cat(catalog.infamy.weapons, 'Great Swords')
    table.insert(inf_greatswords, { id = 21683, name = "Ragnarok 119 Iii", cost = 500, jobs = 'WAR/PLD/DRK', cat = 'Great Swords' })  -- WS score 296, DMG 304/Dly 431
    -- Do NOT add 21663 Raetic Algol +1 here: HQ1 craft (Alchemy 119).

    -- Axes: 5 pick(s) -> Infamy Vendor
    local inf_axes = cat(catalog.infamy.weapons, 'Axes')
    table.insert(inf_axes, { id = 21707, name = "Barbarity +1", cost = 500, jobs = 'WAR/BST', cat = 'Axes' })  -- WS score 250, DMG 189/Dly 280
    table.insert(inf_axes, { id = 21712, name = "Voluspa Axe", cost = 500, jobs = 'WAR/DRK/BST/RUN', cat = 'Axes' })  -- WS score 185, DMG 169/Dly 312

    -- Great Axes: 5 pick(s) -> Infamy Vendor
    local inf_greataxes = cat(catalog.infamy.weapons, 'Great Axes')
    -- Do NOT add 21766 Hepatizon Axe +1 here: HQ1 craft (Gold 106).
    -- Do NOT add 21768 Raetic Chopper +1 here: HQ1 craft (Smith 110).

    -- Scythes: 5 pick(s) -> Infamy Vendor
    local inf_scythes = cat(catalog.infamy.weapons, 'Scythes')
    -- Do NOT add 21816 Maliya Sickle +1 here: HQ1 craft (Bone 106).
    -- Do NOT add 21819 Raetic Scythe +1 here: HQ1 craft (Bone 110).

    -- Polearms: 5 pick(s) -> Infamy Vendor
    local inf_polearms = cat(catalog.infamy.weapons, 'Polearms')
    -- Do NOT add 21870 Exalted Spear +1 here: HQ1 craft (Wood 106).
    -- Do NOT add 21872 Raetic Halberd +1 here: HQ1 craft (Wood 110).

    -- Great Katana: 5 pick(s) -> Infamy Vendor
    local inf_gkatana = cat(catalog.infamy.weapons, 'Great Katana')
    -- Do NOT add 21964 Beryllium Tachi +1 here: HQ1 craft (Smith 106).

    -- Clubs: 5 pick(s) -> Infamy Vendor
    local inf_clubs = cat(catalog.infamy.weapons, 'Clubs')
    table.insert(inf_clubs, { id = 22042, name = "Wizards Rod", cost = 500, jobs = 'BLM/RDM/SCH/GEO', cat = 'Clubs' })  -- CASTER score 1060, DMG 149/Dly 216
    table.insert(inf_clubs, { id = 21071, name = "Cath Palug Hammer", cost = 500, jobs = 'WHM/GEO', cat = 'Clubs' })  -- CASTER score 1013, DMG 212/Dly 300

    -- Staves: 5 pick(s) -> Infamy Vendor
    local inf_staves = cat(catalog.infamy.weapons, 'Staves')
    -- Do NOT add 22081 Raetic Staff +1 here: HQ1 craft (Wood 110).
    table.insert(inf_staves, { id = 22058, name = "Contemplator +1", cost = 500, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO', cat = 'Staves' })  -- CASTER score 1004, DMG 232/Dly 390

    -- Archery: 5 pick(s) -> Infamy Vendor
    local inf_archery = cat(catalog.infamy.weapons, 'Archery')
    table.insert(inf_archery, { id = 21221, name = "Brahmastra", cost = 500, jobs = 'RNG', cat = 'Archery' })  -- WS score 326, DMG 261/Dly 600
    -- Do NOT add 22123 Arasy Bow +1 here: HQ1 craft (Wood 102 + Alchemy 110).
    table.insert(inf_archery, { id = 21220, name = "Paloma Bow +1", cost = 500, jobs = 'RNG', cat = 'Archery' })  -- WS score 272, DMG 220/Dly 480

    -- Marksmanship: 5 pick(s) -> Infamy Vendor
    local inf_marksmanship = cat(catalog.infamy.weapons, 'Marksmanship')
    table.insert(inf_marksmanship, { id = 22121, name = "Imati +1", cost = 500, jobs = 'RNG', cat = 'Marksmanship' })  -- WS score 307, DMG 146/Dly 424
    -- Do NOT add 22136 Arasy Gun +1 here: HQ1 craft (Wood 110 + Smith 102).

end
return catalog
