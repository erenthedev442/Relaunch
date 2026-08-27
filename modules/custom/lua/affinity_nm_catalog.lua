-----------------------------------
-- Canonical roster, difficulty, travel, and collection rewards for all
-- 24 Affinity NMs. Sage registration remains owned by
-- augment_affinity_catalog.lua; registerCat is only a cross-reference.
-----------------------------------
local catalog = {}

catalog.clearVar       = 'Affinity_NM_Clears'
catalog.migrationVar   = 'Affinity_NM_Clears_Mig1'
catalog.repeatDayVar   = 'Affinity_NM_RepeatDay'
catalog.repeatMarksVar = 'Affinity_NM_RepeatMarks'
catalog.repeatDailyCap = 120

-- All 24 copies are forced to 99. HP is an absolute pool, not a retail
-- multiplier: i119 weaponskills cap at 79,999, so the old 60-80k bodies
-- died in one hit. These values are a real solo-with-trusts fight.
catalog.level = 99

catalog.profiles =
{
    intro =
    {
        label = 'Intro', hp = 800000, firstMarks = 90, repeatMarks = 5,
        mods =
        {
            [xi.mod.ATT] = 3000, [xi.mod.ACC] = 1200, [xi.mod.DEF] = 900,
            [xi.mod.EVA] = 500, [xi.mod.MATT] = 250, [xi.mod.MDEF] = 30,
            [xi.mod.STR] = 200, [xi.mod.DEX] = 200, [xi.mod.HASTE_GEAR] = 100,
            [xi.mod.DOUBLE_ATTACK] = 12, [xi.mod.CRITHITRATE] = 6, [xi.mod.STORETP] = 20,
        },
    },
    standard =
    {
        label = 'Standard', hp = 1200000, firstMarks = 150, repeatMarks = 8,
        mods =
        {
            [xi.mod.ATT] = 3600, [xi.mod.ACC] = 1500, [xi.mod.DEF] = 1100,
            [xi.mod.EVA] = 650, [xi.mod.MATT] = 320, [xi.mod.MDEF] = 40,
            [xi.mod.STR] = 250, [xi.mod.DEX] = 250, [xi.mod.HASTE_GEAR] = 140,
            [xi.mod.DOUBLE_ATTACK] = 16, [xi.mod.CRITHITRATE] = 8, [xi.mod.STORETP] = 28,
        },
    },
    veteran =
    {
        label = 'Veteran', hp = 1800000, firstMarks = 225, repeatMarks = 10,
        mods =
        {
            [xi.mod.ATT] = 4200, [xi.mod.ACC] = 1800, [xi.mod.DEF] = 1350,
            [xi.mod.EVA] = 800, [xi.mod.MATT] = 380, [xi.mod.MDEF] = 45,
            [xi.mod.STR] = 300, [xi.mod.DEX] = 300, [xi.mod.HASTE_GEAR] = 170,
            [xi.mod.DOUBLE_ATTACK] = 19, [xi.mod.CRITHITRATE] = 10, [xi.mod.STORETP] = 36,
        },
    },
    apex =
    {
        label = 'Apex', hp = 2500000, firstMarks = 300, repeatMarks = 12,
        mods =
        {
            [xi.mod.ATT] = 4800, [xi.mod.ACC] = 2000, [xi.mod.DEF] = 1500,
            [xi.mod.EVA] = 900, [xi.mod.MATT] = 440, [xi.mod.MDEF] = 50,
            [xi.mod.STR] = 350, [xi.mod.DEX] = 350, [xi.mod.HASTE_GEAR] = 190,
            [xi.mod.DOUBLE_ATTACK] = 22, [xi.mod.CRITHITRATE] = 11, [xi.mod.STORETP] = 42,
        },
    },
}

-- Retail skill lists stay on the pools. These only cap the lockout durations
-- so Absolute Terror / petrify / Doom cannot freeze a solo player for 30-60s.
catalog.ccCaps =
{
    [xi.effect.PETRIFICATION]         = 8,
    [xi.effect.GRADUAL_PETRIFICATION] = 8,
    [xi.effect.TERROR]                = 6,
    [xi.effect.DOOM]                  = 15,
    [xi.effect.CHARM_I]               = 8,
    [xi.effect.CHARM_II]              = 8,
}

catalog.milestones =
{
    [6]  = { marks = 75,  label = 'Affinity Scout' },
    [12] = { marks = 150, label = 'Affinity Stalker' },
    [18] = { marks = 250, label = 'Affinity Veteran' },
    [24] = { marks = 500, label = 'Master Hunter', title = xi.title.MASTER_HUNTER },
}

-- index is the persistent clear bit (index - 1). Keep order stable.
catalog.entries =
{
    { index=1,  mobId=17298309, name='Behemoth',         display='Behemoth',         zoneId=127, zone="Behemoth's Dominion",    zoneOverride='xi.zones.Behemoths_Dominion.Zone.onInitialize',     x=-277.763, y=-20.309, z=72.189, band='intro',    registerCat=1  },
    { index=2,  mobId=17298310, name='King_Behemoth',    display='King Behemoth',    zoneId=127, zone="Behemoth's Dominion",    zoneOverride='xi.zones.Behemoths_Dominion.Zone.onInitialize',     x=-267.50, y=-19.80, z=73.70,   band='standard', registerCat=2  },
    { index=3,  mobId=17204087, name='King_Arthro',      display='King Arthro',      zoneId=104, zone='Jugner Forest',           zoneOverride='xi.zones.Jugner_Forest.Zone.onInitialize',           x=-177.8894, y=0.2285, z=434.2736, band='intro'                    },
    { index=4,  mobId=17228680, name='Simurgh',          display='Simurgh',          zoneId=110, zone='Rolanberry Fields',       zoneOverride='xi.zones.Rolanberry_Fields.Zone.onInitialize',      x=-681.00, y=-31.00, z=-447.00, band='intro'                    },
    { index=5,  mobId=17302409, name='Adamantoise',      display='Adamantoise',      zoneId=128, zone='Valley of Sorrows',       zoneOverride='xi.zones.Valley_of_Sorrows.Zone.onInitialize',      x=3.00,    y=-0.42,  z=8.00,    band='standard'                 },
    { index=6,  mobId=17310621, name='Genbu',            display='Genbu',            zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=261.87,  y=-70.22, z=526.41,  band='veteran',  registerCat=4  },
    { index=7,  mobId=17269643, name='Roc',              display='Roc',              zoneId=120, zone='Sauromugue Champaign',    zoneOverride='xi.zones.Sauromugue_Champaign.Zone.onInitialize',   x=232.00,  y=-0.01,  z=-327.00, band='intro'                    },
    { index=8,  mobId=17310622, name='Seiryu',           display='Seiryu',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=580.84,  y=-70.22, z=-84.53,  band='veteran'                  },
    { index=9,  mobId=17310623, name='Byakko',           display='Byakko',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=-419.40, y=-70.20, z=410.96,  band='veteran',  registerCat=5  },
    { index=10, mobId=17302414, name='Aspidochelone',    display='Aspidochelone',    zoneId=128, zone='Valley of Sorrows',       zoneOverride='xi.zones.Valley_of_Sorrows.Zone.onInitialize',      x=19.00,   y=0.089,  z=14.00,   band='standard', registerCat=6  },
    { index=11, mobId=16896911, name='Ouryu',            display='Ouryu',            zoneId=29,  zone='Riverne Site B01',        zoneOverride='xi.zones.Riverne-Site_B01.Zone.onInitialize',       x=618.78,  y=0.56,   z=-552.23, band='standard', registerCat=3  },
    { index=12, mobId=17404816, name='Bune',             display='Bune',             zoneId=153, zone='The Boyahda Tree',        zoneOverride='xi.zones.The_Boyahda_Tree.Zone.onInitialize',       x=405.43,  y=11.40,  z=-98.61,  band='intro'                    },
    { index=13, mobId=16901009, name='Phoenix',          display='Phoenix',          zoneId=30,  zone='Riverne Site A01',        zoneOverride='xi.zones.Riverne-Site_A01.Zone.onInitialize',       x=685.00,  y=-31.76, z=-481.00, band='intro',    registerCat=8  },
    { index=14, mobId=17310624, name='Suzaku',           display='Suzaku',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=-520.84, y=-70.22, z=-271.52, band='veteran'                  },
    { index=15, mobId=17507219, name='Kirin',            display='Kirin',            zoneId=178, zone="Shrine of Ru'Avitau",     zoneOverride='xi.zones.The_Shrine_of_RuAvitau.Zone.onInitialize', x=-68.00,  y=32.58,  z=3.50,    band='apex',     registerCat=11 },
    { index=16, mobId=17408916, name='Fafnir',           display='Fafnir',           zoneId=154, zone="Dragon's Aery",           zoneOverride='xi.zones.Dragons_Aery.Zone.onInitialize',           x=46.00,   y=6.00,   z=18.00,   band='veteran'                  },
    { index=17, mobId=17408917, name='Nidhogg',          display='Nidhogg',          zoneId=154, zone="Dragon's Aery",           zoneOverride='xi.zones.Dragons_Aery.Zone.onInitialize',           x=46.00,   y=6.00,   z=24.00,   band='veteran'                  },
    { index=18, mobId=17556374, name='Vrtra',            display='Vrtra',            zoneId=190, zone="King Ranperre's Tomb",    zoneOverride='xi.zones.King_Ranperres_Tomb.Zone.onInitialize',    x=228.00,  y=7.134,  z=-311.00, band='veteran'                  },
    { index=19, mobId=16806807, name='Tiamat',           display='Tiamat',           zoneId=7,   zone='Attohwa Chasm',           zoneOverride='xi.zones.Attohwa_Chasm.Zone.onInitialize',          x=-529.519, y=-5.811, z=-43.413, band='veteran'                  },
    { index=20, mobId=17290136, name='King_Vinegarroon', display='King Vinegarroon', zoneId=125, zone='Western Altepa Desert',  zoneOverride='xi.zones.Western_Altepa_Desert.Zone.onInitialize',  x=-239.00, y=-0.23,  z=-650.00, band='standard', registerCat=7  },
    { index=21, mobId=17101721, name='Khimaira',         display='Khimaira',         zoneId=79,  zone='Caedarva Mire',           zoneOverride='xi.zones.Caedarva_Mire.Zone.onInitialize',          x=603.887, y=-16.140, z=414.765, band='standard'                 },
    { index=22, mobId=17027994, name='Cerberus',         display='Cerberus',         zoneId=61,  zone='Mount Zhayolm',           zoneOverride='xi.zones.Mount_Zhayolm.Zone.onInitialize',          x=316.00,  y=-23.00, z=-84.00,  band='standard'                 },
    { index=23, mobId=16913307, name='Absolute_Virtue',  display='Absolute Virtue',  zoneId=33,  zone="Al'Taieu",                zoneOverride='xi.zones.AlTaieu.Zone.onInitialize',                x=461.266, y=-1.643, z=-580.192, band='apex',     registerCat=9  },
    { index=24, mobId=16909196, name='Proto-Omega',      display='Proto-Omega',      zoneId=32,  zone="Sealion's Den",           zoneOverride='xi.zones.Sealions_Den.Zone.onInitialize',           x=-640.00, y=-231.00, z=516.00,  band='apex',     registerCat=10 },
}

function catalog.byId(mobId)
    for _, entry in ipairs(catalog.entries) do
        if entry.mobId == mobId then
            return entry
        end
    end
end

function catalog.byName(name)
    for _, entry in ipairs(catalog.entries) do
        if entry.name == name then
            return entry
        end
    end
end

function catalog.hasClear(player, index)
    local mask = player:getCharVar(catalog.clearVar) or 0
    return bit.band(mask, bit.lshift(1, index - 1)) ~= 0
end

function catalog.grantClear(player, index)
    local mask = player:getCharVar(catalog.clearVar) or 0
    player:setCharVar(catalog.clearVar, bit.bor(mask, bit.lshift(1, index - 1)))
end

function catalog.clearCount(player)
    local count = 0
    for index = 1, #catalog.entries do
        if catalog.hasClear(player, index) then
            count = count + 1
        end
    end
    return count
end

function catalog.migrateRegisteredClears(player)
    if (player:getCharVar(catalog.migrationVar) or 0) ~= 0 then
        return
    end

    local affinities = player:getCharVar('Augment_Affinities') or 0
    local clears     = player:getCharVar(catalog.clearVar) or 0
    for _, entry in ipairs(catalog.entries) do
        if
            entry.registerCat and
            bit.band(affinities, bit.lshift(1, entry.registerCat - 1)) ~= 0
        then
            clears = bit.bor(clears, bit.lshift(1, entry.index - 1))
        end
    end

    player:setCharVar(catalog.clearVar, clears)
    player:setCharVar(catalog.migrationVar, 1)
end

return catalog
