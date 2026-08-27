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

catalog.profiles =
{
    intro =
    {
        label = 'Intro', hpMult = 8.0, firstMarks = 90, repeatMarks = 5,
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
        label = 'Standard', hpMult = 9.0, firstMarks = 150, repeatMarks = 8,
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
        label = 'Veteran', hpMult = 10.0, firstMarks = 225, repeatMarks = 10,
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
        label = 'Apex', hpMult = 11.0, firstMarks = 300, repeatMarks = 12,
        mods =
        {
            [xi.mod.ATT] = 4800, [xi.mod.ACC] = 2000, [xi.mod.DEF] = 1500,
            [xi.mod.EVA] = 900, [xi.mod.MATT] = 440, [xi.mod.MDEF] = 50,
            [xi.mod.STR] = 350, [xi.mod.DEX] = 350, [xi.mod.HASTE_GEAR] = 190,
            [xi.mod.DOUBLE_ATTACK] = 22, [xi.mod.CRITHITRATE] = 11, [xi.mod.STORETP] = 42,
        },
    },
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
    { index=1,  mobId=17208197, name='Behemoth',         display='Behemoth',         zoneId=105, zone='Batallia Downs',          zoneOverride='xi.zones.Batallia_Downs.Zone.onInitialize',         x=-670.00, y=-23.00, z=352.00,  band='intro',    registerCat=1  },
    { index=2,  mobId=17298310, name='King_Behemoth',    display='King Behemoth',    zoneId=127, zone="Behemoth's Dominion",    zoneOverride='xi.zones.Behemoths_Dominion.Zone.onInitialize',     x=-267.50, y=-19.80, z=73.70,   band='standard', registerCat=2  },
    { index=3,  mobId=17490823, name='King_Arthro',      display='King Arthro',      zoneId=174, zone='Kuftal Tunnel',           zoneOverride='xi.zones.Kuftal_Tunnel.Zone.onInitialize',          x=-27.91,  y=-10.69, z=-185.26, band='intro'                    },
    { index=4,  mobId=17228680, name='Simurgh',          display='Simurgh',          zoneId=110, zone='Rolanberry Fields',       zoneOverride='xi.zones.Rolanberry_Fields.Zone.onInitialize',      x=-681.00, y=-31.00, z=-447.00, band='intro'                    },
    { index=5,  mobId=17302409, name='Adamantoise',      display='Adamantoise',      zoneId=128, zone='Valley of Sorrows',       zoneOverride='xi.zones.Valley_of_Sorrows.Zone.onInitialize',      x=3.00,    y=-0.42,  z=8.00,    band='standard'                 },
    { index=6,  mobId=17310621, name='Genbu',            display='Genbu',            zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=261.87,  y=-70.22, z=526.41,  band='veteran',  registerCat=4  },
    { index=7,  mobId=17269643, name='Roc',              display='Roc',              zoneId=120, zone='Sauromugue Champaign',    zoneOverride='xi.zones.Sauromugue_Champaign.Zone.onInitialize',   x=232.00,  y=-0.01,  z=-327.00, band='intro'                    },
    { index=8,  mobId=17310622, name='Seiryu',           display='Seiryu',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=580.84,  y=-70.22, z=-84.53,  band='veteran'                  },
    { index=9,  mobId=17310623, name='Byakko',           display='Byakko',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=-419.40, y=-70.20, z=410.96,  band='veteran',  registerCat=5  },
    { index=10, mobId=17240974, name='Aspidochelone',    display='Aspidochelone',    zoneId=113, zone='Cape Teriggan',           zoneOverride='xi.zones.Cape_Teriggan.Zone.onInitialize',          x=-175.33, y=7.68,   z=-247.30, band='standard', registerCat=6  },
    { index=11, mobId=16896911, name='Ouryu',            display='Ouryu',            zoneId=29,  zone='Riverne Site B01',        zoneOverride='xi.zones.Riverne-Site_B01.Zone.onInitialize',       x=618.78,  y=0.56,   z=-552.23, band='standard', registerCat=3  },
    { index=12, mobId=17404816, name='Bune',             display='Bune',             zoneId=153, zone='The Boyahda Tree',        zoneOverride='xi.zones.The_Boyahda_Tree.Zone.onInitialize',       x=405.43,  y=11.40,  z=-98.61,  band='intro'                    },
    { index=13, mobId=16901009, name='Phoenix',          display='Phoenix',          zoneId=30,  zone='Riverne Site A01',        zoneOverride='xi.zones.Riverne-Site_A01.Zone.onInitialize',       x=685.00,  y=-31.76, z=-481.00, band='intro',    registerCat=8  },
    { index=14, mobId=17310624, name='Suzaku',           display='Suzaku',           zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=-520.84, y=-70.22, z=-271.52, band='veteran'                  },
    { index=15, mobId=17507219, name='Kirin',            display='Kirin',            zoneId=178, zone="Shrine of Ru'Avitau",     zoneOverride='xi.zones.The_Shrine_of_RuAvitau.Zone.onInitialize', x=-68.00,  y=32.58,  z=3.50,    band='apex',     registerCat=11 },
    { index=16, mobId=17408916, name='Fafnir',           display='Fafnir',           zoneId=154, zone="Dragon's Aery",           zoneOverride='xi.zones.Dragons_Aery.Zone.onInitialize',           x=46.00,   y=6.00,   z=18.00,   band='veteran'                  },
    { index=17, mobId=17408917, name='Nidhogg',          display='Nidhogg',          zoneId=154, zone="Dragon's Aery",           zoneOverride='xi.zones.Dragons_Aery.Zone.onInitialize',           x=46.00,   y=6.00,   z=24.00,   band='veteran'                  },
    { index=18, mobId=17617814, name='Vrtra',            display='Vrtra',            zoneId=205, zone="Ifrit's Cauldron",        zoneOverride='xi.zones.Ifrits_Cauldron.Zone.onInitialize',        x=168.79,  y=0.90,   z=-19.83,  band='veteran'                  },
    { index=19, mobId=16798615, name='Tiamat',           display='Tiamat',           zoneId=5,   zone='Uleguerand Range',        zoneOverride='xi.zones.Uleguerand_Range.Zone.onInitialize',       x=-242.35, y=-39.88, z=-415.62, band='veteran'                  },
    { index=20, mobId=17290136, name='King_Vinegarroon', display='King Vinegarroon', zoneId=125, zone='Western Altepa Desert',  zoneOverride='xi.zones.Western_Altepa_Desert.Zone.onInitialize',  x=-239.00, y=-0.23,  z=-650.00, band='standard', registerCat=7  },
    { index=21, mobId=17556377, name='Khimaira',         display='Khimaira',         zoneId=190, zone="King Ranperre's Tomb",    zoneOverride='xi.zones.King_Ranperres_Tomb.Zone.onInitialize',    x=-124.00, y=-0.50,  z=249.52,  band='standard'                 },
    { index=22, mobId=17556378, name='Cerberus',         display='Cerberus',         zoneId=190, zone="King Ranperre's Tomb",    zoneOverride='xi.zones.King_Ranperres_Tomb.Zone.onInitialize',    x=-147.00, y=-0.50,  z=250.00,  band='standard'                 },
    { index=23, mobId=17310619, name='Absolute_Virtue',  display='Absolute Virtue',  zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=-6.03,   y=-40.52, z=-417.21, band='apex',     registerCat=9  },
    { index=24, mobId=17310620, name='Proto-Omega',      display='Proto-Omega',      zoneId=130, zone="Ru'Aun Gardens",          zoneOverride='xi.zones.RuAun_Gardens.Zone.onInitialize',          x=1.00,    y=-38.60, z=-485.00, band='apex',     registerCat=10 },
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
