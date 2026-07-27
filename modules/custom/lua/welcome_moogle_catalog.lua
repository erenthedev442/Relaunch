-----------------------------------
-- welcome_moogle_catalog.lua
-- Curated level-50 starter wares for the Welcome Moogle in GM Home.
--
-- Every item costs 1,000 gil and is granted with exactly two fixed, low-power
-- standard augments. Values are exdata boost values, not display values:
-- the live augment table applies each augment's base and multiplier.
-----------------------------------
local A =
{
    str     = function() return { id = 512, value = 4,  label = 'STR +5' } end,
    dex     = function() return { id = 513, value = 4,  label = 'DEX +5' } end,
    vit     = function() return { id = 514, value = 4,  label = 'VIT +5' } end,
    agi     = function() return { id = 515, value = 4,  label = 'AGI +5' } end,
    int     = function() return { id = 516, value = 4,  label = 'INT +5' } end,
    mnd     = function() return { id = 517, value = 4,  label = 'MND +5' } end,
    chr     = function() return { id = 518, value = 4,  label = 'CHR +5' } end,
    -- Use each stat's +1 augment tier. The old HP/MP +97 and combat-stat +33
    -- tiers made the tooltip labels understate the live modifiers by 29-81
    -- points once the augments were applied.
    hp      = function() return { id = 1,   value = 19, label = 'HP +20' } end,
    mp      = function() return { id = 9,   value = 19, label = 'MP +20' } end,
    attack  = function() return { id = 25,  value = 5,  label = 'Attack +6' } end,
    ratt    = function() return { id = 29,  value = 5,  label = 'Rng. Atk. +6' } end,
    acc     = function() return { id = 23,  value = 5,  label = 'Accuracy +6' } end,
    racc    = function() return { id = 27,  value = 5,  label = 'Rng. Acc. +6' } end,
    macc    = function() return { id = 35,  value = 5,  label = 'Mag. Acc. +6' } end,
    da      = function() return { id = 143, value = 2,  label = 'Double Attack +3' } end,
    stp     = function() return { id = 142, value = 3,  label = 'Store TP +4' } end,
    subtle  = function() return { id = 195, value = 3,  label = 'Subtle Blow +4' } end,
    mab     = function() return { id = 133, value = 3,  label = 'Mag. Atk. Bns. +4' } end,
    fc      = function() return { id = 140, value = 1,  label = 'Fast Cast +2' } end,
    haste   = function() return { id = 49,  value = 1,  label = 'Haste +2%' } end,
    refresh = function() return { id = 138, value = 0,  label = 'Refresh (T1)' } end,
    cure    = function() return { id = 329, value = 3,  label = 'Cure potency +4' } end,
    snapshot= function() return { id = 211, value = 2,  label = 'Snapshot +3' } end,
    zanshin = function() return { id = 198, value = 2,  label = 'Zanshin +3' } end,
    exp15   = function() return { id = 72,  value = 14, label = 'EXP +15%' } end,
}

local function item(id, name, left, right, jobs)
    return
    {
        id       = id,
        name     = name,
        price    = 1000,
        jobs     = jobs,
        augments = { A[left](), A[right]() },
    }
end

local M =
{
    npc =
    {
        name = 'Welcome Moogle',
        x = 518.8482,
        y = -3.0378,
        z = 545.4992,
        rot = 67,
    },

    starterGifts =
    {
        { id = 10293, name = 'Chocobo Shirt' },
        { id = 11811, name = 'Destrier Beret' },
        { id = 27556, name = 'Echad Ring' },
    },

    categoryOrder = { 'Weapons', 'Armor', 'Accessories' },
    subcategoryOrder =
    {
        Weapons     = { 'Melee', 'Ranged', 'Magic' },
        Armor       = { 'Job Bodies', 'Other Pieces' },
        Accessories = { 'Rings', 'Earrings', 'Other' },
    },

    wares =
    {
        Weapons =
        {
            Melee =
            {
                item(17472, 'Cross-Counters',               'acc',    'da'),
                item(18752, 'Retaliators',                  'da',     'subtle'),
                item(18020, 'Mercurial Kris',               'dex',    'da'),
                item(18411, 'Buboso',                       'stp',    'da'),
                item(17813, 'Soboro Sukehiro',              'stp',    'str'),
                item(16965, 'Koryukagemitsu',               'zanshin','acc'),
                item(16940, "Gerwitz's Sword",              'str',    'acc'),
                item(16571, 'Temple Knight Army Sword',     'vit',    'acc'),
                item(18219, 'Leucous Voulge +1',            'str',    'attack'),
                item(16681, "Gerwitz's Axe",                'attack', 'stp'),
                item(16851, 'Royal Knight Army Lance',      'str',    'stp'),
                item(19150, 'Cobra Unit Claymore',          'str',    'attack'),
                item(19277, 'Tsugumi',                      'dex',    'acc'),
                item(17082, "Tactician Magician's Wand",    'acc',    'attack', 'WHM'),
            },
            Ranged =
            {
                item(17173, 'War Bow +1',                   'racc',   'snapshot'),
                item(17226, 'Arbalest +1',                  'racc',   'ratt'),
                item(17182, 'Kaman +1',                     'agi',    'racc'),
                item(17253, 'Musketeer Gun',                'racc',   'stp'),
                item(16757, "Corsair's Knife",              'dex',    'racc'),
                item(18711, 'Seadog Gun +1',                'racc',   'stp', 'THF/RNG/NIN/COR'),
            },
            Magic =
            {
                item(17072, "Lilith's Rod",                 'mab',    'int'),
                item(16694, "Tactician Magician's Hooks",  'fc',     'macc'),
                item(17851, 'Storm Fife',                   'chr',    'fc'),
                item(16810, "Tactician Magician's Espadon",'vit',    'macc'),
            },
        },

        Armor =
        {
            ['Job Bodies'] =
            {
                item(14412, 'Parade Cuirass',               'vit',    'hp',     'WAR/PLD'),
                item(14409, 'Gloom Breastplate',            'str',    'attack', 'DRK'),
                item(14411, 'Aikido Gi',                    'vit',    'haste',  'MNK'),
                item(14403, 'Rapparee Harness',             'dex',    'da',     'THF/DNC'),
                item(14405, 'Wyvern Mail',                  'str',    'hp',     'DRG'),
                item(14407, 'Cerise Doublet',               'int',    'fc',     'RDM/BRD/BLU/PUP/RUN'),
                item(14410, 'Nimbus Doublet',               'chr',    'mp',     'WHM/SMN'),
                item(14408, 'Glamor Jupon',                 'mnd',    'cure',   'RDM/SCH'),
                item(14406, 'Shikaree Aketon',              'agi',    'racc',   'RNG/COR'),
                item(14401, 'Duende Cotehardie',            'int',    'mab',    'BLM/SMN/GEO'),
                item(14402, 'Nokizaru Gi',                  'dex',    'subtle', 'NIN'),
                item(14404, 'Shinimusha Hara-ate',          'str',    'stp',    'SAM'),
                item(14413, 'Gaudy Harness',                'chr',    'hp',     'BST/BRD'),
            },
            ['Other Pieces'] =
            {
                item(12550, "Iron Musketeer's Cuirass",    'vit',    'hp'),
                item(12686, "Royal Knight's Mufflers",     'acc',    'attack'),
                item(12806, "Iron Musketeer's Cuisses",    'vit',    'hp'),
                item(12942, "Royal Knight's Sollerets",    'haste',  'hp'),
                item(13939, 'Austere Hat',                  'mnd',    'mp'),
                item(13940, 'Penance Hat',                  'int',    'macc'),
                item(14020, "Enkelados's Bracelets",       'dex',    'acc'),
                item(12312, 'Royal Knight Army Shield',     'vit',    'hp'),
                item(12379, 'Holy Shield',                  'mnd',    'vit'),
                item(14936, 'Storm Manopolas',              'acc',    'attack', 'All Jobs'),
                item(14937, 'Storm Gages',                  'macc',   'fc',     'All Jobs'),
                item(15691, 'Storm Gambieras',              'haste',  'hp',     'All Jobs'),
                item(15692, 'Storm Crackows',               'fc',     'mp',     'All Jobs'),
            },
        },

        Accessories =
        {
            Rings =
            {
                item(13286, "Soldier's Ring",               'str',    'attack',  'WAR'),
                item(13287, 'Kampfer Ring',                  'vit',    'haste',   'MNK'),
                item(13288, 'Medicine Ring',                 'mnd',    'cure',    'WHM'),
                item(13289, "Sorcerer's Ring",              'int',    'mab',     'BLM'),
                item(13290, "Fencer's Ring",                'int',    'fc',      'RDM'),
                item(13291, "Rogue's Ring",                 'dex',    'da',      'THF'),
                item(13292, "Guardian's Ring",              'vit',    'hp',      'PLD'),
                item(13293, "Slayer's Ring",                'str',    'attack',  'DRK'),
                item(13294, "Tamer's Ring",                 'chr',    'hp',      'BST'),
                item(13295, "Minstrel's Ring",              'chr',    'refresh', 'BRD'),
                item(13296, "Tracker's Ring",               'agi',    'racc',    'RNG'),
                item(13297, 'Ronin Ring',                    'str',    'stp',     'SAM'),
                item(13298, 'Shinobi Ring',                  'dex',    'subtle',  'NIN'),
                item(13299, 'Drake Ring',                    'str',    'hp',      'DRG'),
                item(13300, "Conjurer's Ring",              'int',    'mp',      'SMN'),
                item(15773, 'Imperial Ring',                 'str',    'stp',     'All Jobs'),
                item(15777, 'Hale Ring',                     'mnd',    'macc',    'All Jobs'),
                item(14649, 'Telluric Ring',                 'exp15',  'refresh', 'All Jobs'),
            },
            Earrings =
            {
                item(15974, 'Velocity Earring',              'haste',  'dex'),
                item(15970, 'Stoic Earring',                 'mnd',    'refresh'),
                item(11042, 'Rebel Earring',                 'stp',    'acc'),
                item(15969, 'Storm Earring',                 'int',    'mab'),
                item(14744, 'Undead Earring',                'attack', 'hp'),
                item(14745, 'Arcana Earring',                'macc',   'int'),
            },
            Other =
            {
                item(13107, 'Royal Knight Army Collar',      'acc',    'hp'),
                item(13105, 'Temple Knight Army Collar',     'mnd',    'cure'),
                item(13167, 'Storm Gorget',                  'stp',    'subtle'),
                item(13168, 'Intellect Torque',              'int',    'macc'),
                item(13220, "Royal Knight's Belt",          'str',    'hp'),
                item(13676, 'Heavy Mantle',                  'vit',    'hp'),
                item(13678, "Sniper's Mantle",              'ratt',   'racc'),
                item(13677, 'Esoteric Mantle',               'mab',    'int'),
                item(11531, 'Fidelity Mantle',               'exp15',  'haste', 'All Jobs'),
            },
        },
    },
}

-- Fail at module load if a future edit accidentally violates the two-slot
-- starter design or introduces duplicate stock.
do
    local seen = {}
    for _, categoryName in ipairs(M.categoryOrder) do
        for _, subcategoryName in ipairs(M.subcategoryOrder[categoryName]) do
            for _, entry in ipairs(M.wares[categoryName][subcategoryName]) do
                assert(not seen[entry.id], string.format('duplicate Welcome Moogle item %d', entry.id))
                assert(#entry.augments == 2, string.format('Welcome Moogle item %d must have two augments', entry.id))
                seen[entry.id] = true
            end
        end
    end
end

return M
