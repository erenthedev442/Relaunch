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
    hp      = function() return { id = 4,   value = 4,  label = 'HP +20' } end,
    mp      = function() return { id = 12,  value = 4,  label = 'MP +20' } end,
    attack  = function() return { id = 65,  value = 2,  label = 'Attack +6' } end,
    ratt    = function() return { id = 66,  value = 2,  label = 'Rng. Atk. +6' } end,
    acc     = function() return { id = 62,  value = 2,  label = 'Accuracy +6' } end,
    racc    = function() return { id = 63,  value = 2,  label = 'Rng. Acc. +6' } end,
    macc    = function() return { id = 64,  value = 2,  label = 'Mag. Acc. +6' } end,
    da      = function() return { id = 143, value = 2,  label = 'Double Attack +3' } end,
    stp     = function() return { id = 142, value = 3,  label = 'Store TP +4' } end,
    subtle  = function() return { id = 195, value = 3,  label = 'Subtle Blow +4' } end,
    mab     = function() return { id = 133, value = 3,  label = 'Mag. Atk. Bns. +4' } end,
    fc      = function() return { id = 140, value = 1,  label = 'Fast Cast +2' } end,
    haste   = function() return { id = 49,  value = 1,  label = 'Haste (T1)' } end,
    refresh = function() return { id = 138, value = 0,  label = 'Refresh (T1)' } end,
    cure    = function() return { id = 329, value = 3,  label = 'Cure potency +4' } end,
    snapshot= function() return { id = 211, value = 2,  label = 'Snapshot +3' } end,
    zanshin = function() return { id = 198, value = 2,  label = 'Zanshin +3' } end,
    exp15   = function() return { id = 72,  value = 14, label = 'EXP +15%' } end,
}

local function item(id, name, left, right)
    return { id = id, name = name, price = 1000, augments = { A[left](), A[right]() } }
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
            },
            Ranged =
            {
                item(17173, 'War Bow +1',                   'racc',   'snapshot'),
                item(17226, 'Arbalest +1',                  'racc',   'ratt'),
                item(17182, 'Kaman +1',                     'agi',    'racc'),
                item(17253, 'Musketeer Gun',                'racc',   'stp'),
                item(16757, "Corsair's Knife",              'dex',    'racc'),
            },
            Magic =
            {
                item(17072, "Lilith's Rod",                 'mab',    'int'),
                item(17082, "Tactician Magician's Wand",   'mnd',    'cure'),
                item(16694, "Tactician Magician's Hooks",  'fc',     'macc'),
                item(17851, 'Storm Fife',                   'chr',    'fc'),
                item(16810, "Tactician Magician's Espadon",'vit',    'macc'),
            },
        },

        Armor =
        {
            ['Job Bodies'] =
            {
                item(14412, 'Parade Cuirass',               'vit',    'hp'),
                item(14409, 'Gloom Breastplate',            'str',    'attack'),
                item(14411, 'Aikido Gi',                    'vit',    'haste'),
                item(14403, 'Rapparee Harness',             'dex',    'da'),
                item(14405, 'Wyvern Mail',                  'str',    'hp'),
                item(14407, 'Cerise Doublet',               'int',    'fc'),
                item(14410, 'Nimbus Doublet',               'chr',    'mp'),
                item(14408, 'Glamor Jupon',                 'mnd',    'cure'),
                item(14406, 'Shikaree Aketon',              'agi',    'racc'),
                item(14401, 'Duende Cotehardie',            'int',    'mab'),
                item(14402, 'Nokizaru Gi',                  'dex',    'subtle'),
                item(14404, 'Shinimusha Hara-ate',          'str',    'stp'),
                item(14413, 'Gaudy Harness',                'chr',    'hp'),
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
            },
        },

        Accessories =
        {
            Rings =
            {
                item(13286, "Soldier's Ring",               'str',    'attack'),
                item(13287, 'Kampfer Ring',                  'vit',    'haste'),
                item(13288, 'Medicine Ring',                 'mnd',    'cure'),
                item(13289, "Sorcerer's Ring",              'int',    'mab'),
                item(13290, "Fencer's Ring",                'int',    'fc'),
                item(13291, "Rogue's Ring",                 'dex',    'da'),
                item(13292, "Guardian's Ring",              'vit',    'hp'),
                item(13293, "Slayer's Ring",                'str',    'attack'),
                item(13294, "Tamer's Ring",                 'chr',    'hp'),
                item(13295, "Minstrel's Ring",              'chr',    'refresh'),
                item(13296, "Tracker's Ring",               'agi',    'racc'),
                item(13297, 'Ronin Ring',                    'str',    'stp'),
                item(13298, 'Shinobi Ring',                  'dex',    'subtle'),
                item(13299, 'Drake Ring',                    'str',    'hp'),
                item(13300, "Conjurer's Ring",              'int',    'mp'),
                item(14649, 'Telluric Ring',                 'exp15',  'refresh'),
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
                item(13692, "Skulker's Cape",               'exp15',  'haste'),
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
