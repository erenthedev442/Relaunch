-----------------------------------
-- Endgame identity catalog for HQ Beastmaster jug pets (pet IDs 77-127).
-- Shared progression lives in BstJugPetOverhaul; this file only describes
-- retail-facing roles and bounded stat weights.
-----------------------------------
local catalog = {}

catalog.STYLE =
{
    tank =
    {
        att = 0.70, acc = 1.00, str = 0.85, hp = 1.70, weapon = 0.80,
        matt = 0.75, macc = 1.00, magic = 0.75, multi = 0.70, dt = 2.00,
    },
    physical =
    {
        att = 1.25, acc = 1.10, str = 1.20, hp = 0.95, weapon = 1.25,
        matt = 0.65, macc = 0.80, magic = 0.60, multi = 1.15, dt = 0.90,
    },
    magical =
    {
        att = 0.75, acc = 0.95, str = 0.80, hp = 0.90, weapon = 0.80,
        matt = 1.35, macc = 1.25, magic = 1.40, multi = 0.80, dt = 0.90,
    },
    fast =
    {
        att = 1.05, acc = 1.20, str = 0.95, hp = 0.75, weapon = 0.95,
        matt = 0.85, macc = 1.00, magic = 0.85, multi = 1.55, dt = 0.75,
    },
    support =
    {
        att = 0.70, acc = 1.05, str = 0.75, hp = 1.10, weapon = 0.75,
        matt = 0.85, macc = 1.30, magic = 0.80, multi = 0.75, dt = 1.10,
    },
    control =
    {
        att = 0.85, acc = 1.10, str = 0.85, hp = 1.00, weapon = 0.90,
        matt = 1.00, macc = 1.40, magic = 0.95, multi = 0.85, dt = 1.00,
    },
    hybrid =
    {
        att = 1.00, acc = 1.00, str = 1.00, hp = 1.00, weapon = 1.00,
        matt = 1.00, macc = 1.00, magic = 1.00, multi = 1.00, dt = 1.00,
    },
}

local function pet(style, niche, power)
    return { style = style, niche = niche, power = power or 1.00 }
end

-- Every HQ/high-level jug has an explicit selection reason at level 99.
catalog.PETS =
{
    [77]  = pet('magical', 'AoE magical damage'),
    [78]  = pet('physical', 'Balanced bird physical damage', 0.94),
    [79]  = pet('physical', 'High physical burst', 1.02),
    [80]  = pet('physical', 'Fast single-target pressure', 1.03),
    [81]  = pet('control', 'Antlion debuffs and physical burst'),
    [82]  = pet('control', 'Flytrap control and drains', 0.96),
    [83]  = pet('tank', 'Maximum physical durability'),
    [84]  = pet('tank', 'Durable drain tank', 1.02),
    [85]  = pet('tank', 'Durable AoE/debuff tank', 1.05),
    [86]  = pet('magical', 'Dark magical damage and poison'),
    [87]  = pet('control', 'Funguar enfeebling specialist'),
    [88]  = pet('magical', 'Thunder AoE damage'),
    [89]  = pet('magical', 'Thunder damage and control', 1.04),
    [90]  = pet('support', 'Raaz party support and disruption'),
    [91]  = pet('support', 'Premium Raaz support', 1.05),
    [92]  = pet('physical', 'Eft physical pressure', 0.96),
    [93]  = pet('physical', 'Apkallu bruiser'),
    [94]  = pet('tank', 'Apkallu defensive bruiser'),
    [95]  = pet('magical', 'Fire AoE specialist', 0.96),
    [96]  = pet('physical', 'Sheep physical burst', 0.94),
    [97]  = pet('physical', 'Tiger single-target DPS', 1.05),
    [98]  = pet('fast', 'Ladybug rapid attacks and evasion'),
    [99]  = pet('tank', 'Beetle physical tank'),
    [100] = pet('control', 'Acuex drains and enfeebles'),
    [101] = pet('magical', 'Acuex magical/debuff damage', 1.04),
    [102] = pet('tank', 'Lucani defensive damage'),
    [103] = pet('physical', 'Lucani physical DPS', 1.04),
    [104] = pet('fast', 'Raptor rapid physical DPS', 1.04),
    [105] = pet('support', 'Mandragora sleep and party control'),
    [106] = pet('tank', 'Porter crab physical tank'),
    [107] = pet('tank', 'Crab tank with venom control', 1.05),
    [108] = pet('support', 'Tulfaire blind and utility'),
    [109] = pet('fast', 'Tulfaire mobile physical DPS', 1.04),
    [110] = pet('tank', 'Crab defensive specialist', 0.96),
    [111] = pet('tank', 'Crab endurance specialist'),
    [112] = pet('fast', 'Chapuli rapid AoE pressure', 0.98),
    [113] = pet('hybrid', 'Chapuli physical/magical AoE', 1.05),
    [114] = pet('control', 'Spider slow and defense down'),
    [115] = pet('control', 'Premium spider control', 1.04),
    [116] = pet('support', 'Colibri utility and fast attacks'),
    [117] = pet('fast', 'Colibri rapid physical DPS', 1.04),
    [118] = pet('physical', 'Rabbit single-target burst', 0.95),
    [119] = pet('physical', 'Premium rabbit physical DPS', 1.02),
    [120] = pet('tank', 'Armored crab tank', 1.02),
    [121] = pet('fast', 'Hippogryph rapid physical damage'),
    [122] = pet('physical', 'Hippogryph burst damage', 1.06),
    [123] = pet('support', 'Mosquito drain sustain'),
    [124] = pet('control', 'Mosquito drain and debuff specialist', 1.04),
    [125] = pet('physical', 'Leech single-target sustain', 1.04),
    [126] = pet('tank', 'Beetle defensive bruiser'),
    [127] = pet('physical', 'Beetle AoE physical damage', 1.05),
}

function catalog.get(petId)
    local entry = catalog.PETS[petId] or pet('hybrid', 'General-purpose jug', 0.90)
    entry.weights = catalog.STYLE[entry.style] or catalog.STYLE.hybrid
    return entry
end

return catalog
