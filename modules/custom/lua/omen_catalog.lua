-----------------------------------
-- Omen catalogue (data only)
--
-- Retail reference: https://www.bg-wiki.com/ffxi/Category:Omen
-- Runtime:          modules/custom/lua/omen_instance.lua
-- Entry NPCs:       modules/custom/lua/OmenNPCs.lua (Incantrix + Coelestrox,
--                   Reisenjima @ Ethereal Ingress #10)
-- SQL layer:        modules/custom/sql/omen.sql (pools/groups/instance row)
--
-- All tuning knobs live HERE. The runtime reads this file on every
-- hot-reload, so numbers can be adjusted without a map restart (new
-- instances pick up the change; live runs keep the values they started
-- with only where the runtime copied them into localvars).
--
-- Deviations from retail (documented on docs/endgame/omen.md too):
--   * All five floors play out on the RETAIL FLOOR-1 platform (the only
--     zone-292 geometry with captured spawn data -- see the 17 real rows
--     at sql/mob_spawn_points.sql:85258, x -743..-719 / y -440 / z -790..-767).
--     Ethereal ingresses advance the run in place instead of teleporting
--     between rooms; floors 2-5 spawn on rings inside the same platform.
--   * The Caturae's true model IDs were never publicly captured (no server
--     anywhere has them). The bosses wear stand-in era arcana models until
--     someone captures the real looks -- see modules/custom/sql/omen.sql.
--   * The untrackable "restore 500 HP ten times" bonus objective is not
--     offered; the other retail objective types are all implemented.
--   * Reforge fees are charged in Escha Beads at the retail "cheap" tier
--     but complete instantly (no game-day wait).
-----------------------------------
local catalog = {}

-----------------------------------
-- Entry / exit (Reisenjima, zone 291 -- Ethereal Ingress #10)
-----------------------------------
catalog.entry =
{
    zoneName  = 'Reisenjima',
    zonePath  = 'xi.zones.Reisenjima',
    zoneId    = 291,

    -- Retail ingress #10 sits at (-389.220, -439.710, -835.130).
    incantrix  = { x = -387.50, y = -439.71, z = -833.00, rotation = 130 },
    coelestrox = { x = -391.00, y = -439.71, z = -833.00, rotation = 126 },

    -- Where players land when an Omen run ends (beside the ingress).
    exit       = { x = -389.22, y = -439.71, z = -838.50, rotation = 0 },
}

catalog.instanceId  = 29200
catalog.scriptName  = 'omen'
catalog.zoneId      = 292          -- Reisenjima Henge (instanced copy)
catalog.partyRange  = 50
catalog.maxMembers  = 18           -- retail: raised to 18 in March 2017

-----------------------------------
-- Time system (all values seconds)
-----------------------------------
catalog.time =
{
    start        = 10 * 60,  -- on entry
    perFloor     = 10 * 60,  -- each ethereal ingress used
    smallerLight = 30 * 60,  -- the floor-2 "smaller light" bonus route
    cap          = 50 * 60,  -- absolute maximum (retail: 50 minutes)
}

-----------------------------------
-- Mystical canteen economy
-----------------------------------
catalog.canteen =
{
    cooldown   = 20 * 60 * 60, -- one accrues every 20 Earth hours
    maxBanked  = 3,            -- Incantrix banks up to 3 (Oct 2017 update)
    currency   = 'mystical_canteen',
}

-----------------------------------
-- Key items
-----------------------------------
catalog.ki =
{
    blessing = xi.ki.PHOENIXS_BLESSING,
    canteen  = xi.ki.MYSTICAL_CANTEEN,
    beads =
    {
        kin  = xi.ki.KINS_BEAD,
        gin  = xi.ki.GINS_BEAD,
        kei  = xi.ki.KEIS_BEAD,
        kyou = xi.ki.KYOUS_BEAD,
        fu   = xi.ki.FUS_BEAD,
    },
}

-----------------------------------
-- Items
-----------------------------------
catalog.items =
{
    -- Paragon job cards: item id = cardBase + xi.job.* (WAR=1 .. RUN=22).
    cardBase = 9280,

    scales =
    {
        kin  = 9303,
        gin  = 9304,
        kei  = 9305,
        kyou = 9306,
        fu   = 9307,
    },

    moonbow =
    {
        steel   = 4077,
        cloth   = 4078,
        leather = 4079,
        urushi  = 4080,
        stone   = 4081,
        coral   = 4082, -- moonlight coral (Ou)
    },

    crystals =
    {
        thought     = 4074,
        hope        = 4075,
        fulfillment = 4076,
    },
}

-- One card per this many completed objectives (main objectives, bonus
-- objectives and boss kills all count; progress persists between runs).
catalog.objectivesPerCard = 5

-----------------------------------
-- Drop rates (fractions). Retail rates by default; single knob to tune.
-----------------------------------
catalog.dropRateMultiplier = 1.0

catalog.rates =
{
    bossAccessory  = 0.10, -- each of the two boss accessories
    bossBody       = 0.01, -- the very-rare body piece
    bossExtraScale = 0.15, -- chance of a second scale
    ouAccessory    = 0.15, -- each of the five Regal accessories
    ouHands        = 0.05, -- one roll over the four Regal hand pieces
    ouScale        = 0.15, -- each of the five boss scales
    bonusFloor     = 0.10, -- chance the floor 3 / floor 5 exit offers the
                           -- bonus treasure floor
}

-----------------------------------
-- Mob group ids (zone 292; see sql/mob_groups.sql + modules/custom/sql/omen.sql)
-----------------------------------
-- Each family entry: { sweetwater group, transcended group }
local FAMILIES =
{
    tiger      = {  1,  3 },
    fly        = {  2,  4 },
    leech      = {  5,  8 },
    beetle     = {  6,  7 },
    hippogryph = { 12, 16 },
    goobbue    = { 13, 17 },
    faaz       = { 14, 18 },
    pugil      = { 15, 19 },
    toad       = { 20, 24 },
    raptor     = { 21, 25 },
    mosquito   = { 22, 26 },
    bats       = { 23, 27 },
    elemental  = { 28, 32 },
    slime      = { 29, 33 },
    lucani     = { 30, 34 },
    worm       = { 31, 35 },
    chapuli    = { 36, 40 },
    treant     = { 37, 41 },
    mantis     = { 38, 42 },
    doomed     = { 39, 43 },
    skeleton   = { 44, 48 },
    cyhiraeth  = { 45, 49 },
    ghost      = { 46, 50 },
    doll       = { 47, 51 },
    rabbit     = { 57, 65 },
    mandragora = { 58, 66 },
    lizard     = { 59, 67 },
    vulture    = { 60, 68 },
    ladybug    = { 61, 69 },
    porxie     = { 62, 70 },
    panopt     = { 63, 71 },
    unseelie   = { 64, 72 },
}

catalog.families = FAMILIES

catalog.groups =
{
    glassyThinker = 9,
    glassyCraver  = 10,
    glassyGorger  = 11,
    kin           = 52,
    gin           = 53,
    kei           = 54,
    kyou          = 55,
    fu            = 56,
    ou            = 73,
}

-----------------------------------
-- Combat tuning (relaunch curve; retail publishes no numbers here)
-----------------------------------
-- Sweetwater/Transcended levels follow the retail spawn captures
-- (mob_spawn_points rows carry 127/129).
catalog.levels =
{
    sweetwater  = 127,
    transcended = 129,
    bonusFloor  = 125,
    midboss     = 132,
    caturae     = 137,
    ou          = 139,
}

catalog.hp =
{
    sweetwater  = 30000,
    transcended = 60000,
    bonusFloor  = 15000,
    midboss     = 250000,
    caturae     = 500000,
    ou          = 1200000,
}

-----------------------------------
-- Arena geometry
--
-- Verified-walkable Henge geometry on this server is the central platform
-- around (0, 5.5, 0) (the pre-migration Hunting League hub / !henge landing
-- spot). Every floor stages there: mobs fan out on a ring, the ethereal
-- ingress materialises at the centre once the floor objective is done.
-----------------------------------
catalog.arena =
{
    center     = { x = -731.0, y = -440.0, z = -778.5 },
    entryPos   = { x = -737.0, y = -439.9, z = -769.5, rotation = 100 },
    ingressPos = { x = -731.0, y = -440.0, z = -778.5, rotation = 192 },
    bossPos    = { x = -727.5, y = -440.0, z = -783.0, rotation = 192 },
    mobRadius  = 10.0,  -- trash ring radius (platform half-extent ~11)
    leash      = 35.0,  -- pull players back within this range of centre
}

-- Retail floor-1 spawn positions (verbatim from the capture rows).
-- 7 + 7 Sweetwater then 1 + 1 Transcended, matching the retail
-- 7-per-family + 1-Transcended-per-family floor composition.
catalog.floorOneSpawns =
{
    sweetwater =
    {
        { -740.595, -439.953, -777.042, 156 }, -- Tigers
        { -732.382, -439.874, -782.994, 100 },
        { -733.981, -439.982, -772.595,  74 },
        { -719.102, -439.845, -783.255, 219 },
        { -721.258, -439.625, -774.018,   4 },
        { -725.743, -440.013, -783.544, 156 },
        { -734.084, -440.092, -789.825, 127 },
        { -743.282, -439.971, -786.593, 183 }, -- Flies
        { -734.492, -439.819, -767.588, 152 },
        { -734.926, -440.057, -772.865, 103 },
        { -721.508, -440.162, -788.026,  56 },
        { -731.735, -440.031, -767.102, 248 },
        { -732.028, -439.987, -774.952, 254 },
        { -721.961, -439.777, -772.835,  58 },
    },
    transcended =
    {
        { -729.074, -440.030, -788.077, 184 }, -- Tiger
        { -727.724, -439.923, -783.467, 127 }, -- Fly
    },
}

-----------------------------------
-- Floors
-----------------------------------
-- Trash floor composition: `sweetwater` + `transcended` counts are split
-- evenly across the floor's families.
catalog.floors =
{
    -- Retail composition: 7 Sweetwater + 1 Transcended per family.
    [1] =
    {
        label       = 'First Gate',
        families    = { 'tiger', 'fly' },
        sweetwater  = 14,
        transcended = 2,
        bonusCount  = 3,
        bonusWindow = 180,
        exactSpawns = true, -- use catalog.floorOneSpawns (retail capture)
    },

    [2] =
    {
        label       = 'Second Gate',
        families    = { 'beetle', 'leech' },
        sweetwater  = 14,
        transcended = 2,
        bonusCount  = 3,
        bonusWindow = 180,
        lightChoice = true, -- larger / smaller light at the exit ingress
    },

    [3] =
    {
        label   = 'Third Gate',
        midboss = true, -- one of the three Glassy NMs, at random
    },

    [4] =
    {
        label       = 'Fourth Gate',
        sweetwater  = 28, -- 7 per family
        transcended = 4,  -- 1 per family
        bonusCount  = 5,
        bonusWindow = 300,
        -- Families depend on the floor 3 mid-boss (retail behaviour).
        -- The two spare retail family sets rotate in as random alternates
        -- so the whole Henge bestiary sees play (wiki leaves their exact
        -- mapping ambiguous).
        familiesByRoute =
        {
            craver  = { 'skeleton', 'cyhiraeth', 'ghost', 'doll' },
            gorger  = { 'chapuli', 'treant', 'mantis', 'doomed' },
            thinker = { 'elemental', 'slime', 'lucani', 'worm' },
        },
        familiesAlternate =
        {
            { 'toad', 'raptor', 'mosquito', 'bats' },
            { 'hippogryph', 'goobbue', 'faaz', 'pugil' },
        },
        alternateChance = 0.35, -- chance an alternate set replaces the route set
    },

    [5] =
    {
        label = 'Final Gate',
        boss  = true, -- Caturae picked at the floor 4 exit ingress
    },
}

-- The "smaller light" bonus route floor (replaces floors 3-5; exit offers Ou).
catalog.bonusRoute =
{
    label       = 'Luminous Rampart',
    families    = { 'rabbit', 'mandragora', 'lizard', 'vulture', 'ladybug', 'porxie', 'panopt', 'unseelie' },
    total       = 56,      -- all must fall for Ou eligibility
    waveSize    = 14,      -- spawned in waves to keep the platform sane
    bonusCount  = 10,
    bonusWindow = 600,
}

-----------------------------------
-- Main floor objectives (floors 1, 2, 4) -- one picked at random
-----------------------------------
catalog.mainObjectives =
{
    { id = 'specificKill',   weight = 20, text = 'Vanquish one specific monster.' },
    { id = 'sweetwaterKill', weight = 20, count = 6, text = 'Vanquish %d Sweetwater monsters.' },
    { id = 'transcendedAll', weight = 20, text = 'Vanquish all Transcended monsters.' },
    { id = 'killAll',        weight = 20, text = 'Vanquish all monsters.' },
    { id = 'free',           weight = 20, text = 'No trial this time. The ingress stands open.' },
}

-----------------------------------
-- Additional (bonus) objectives
--
-- N = min(#players, 6). `mult` scales N into the target count.
-- Implemented trackers (runtime): kill / ja / spell / ws / physWs / elemWs /
-- skillchain / magicBurst / crit / bigHit / bigWs / bigBurst / bigNuke.
-----------------------------------
catalog.bonusObjectives =
{
    { id = 'kill',       mult = 1, text = 'Vanquish %d foes' },
    { id = 'ja',         mult = 2, text = 'Use %d job abilities on your foes' },
    { id = 'spell',      mult = 3, text = 'Cast %d spells on your foes' },
    { id = 'skillchain', mult = 1, text = 'Execute %d skillchains' },
    { id = 'magicBurst', mult = 3, text = 'Perform %d magic bursts' },
    { id = 'crit',       mult = 3, text = 'Deal %d critical hits' },
    { id = 'elemWs',     mult = 3, text = 'Use %d elemental weapon skills' },
    { id = 'physWs',     mult = 3, text = 'Use %d physical weapon skills' },
    { id = 'ws',         mult = 5, text = 'Use %d weapon skills' },
    { id = 'bigHit',     mult = 0, target = 1, threshold = 2000,  text = 'Deal 2,000+ damage in a single attack' },
    { id = 'bigWs',      mult = 0, target = 1, threshold = 30000, text = 'Deal 30,000+ damage with a single weapon skill' },
    { id = 'bigBurst',   mult = 0, target = 1, threshold = 30000, text = 'Deal 30,000+ damage with a single magic burst' },
    { id = 'bigNuke',    mult = 0, target = 1, threshold = 15000, text = 'Deal 15,000+ damage with a single (non-burst) magic attack' },
}

-- Elemental weapon skills (per the classification used by Abyssea lights).
catalog.magicalWsIds =
{
    19, 20, 30, 33, 34, 36, 37, 47, 50, 51, 58, 74, 76, 97, 98, 107, 113, 114, 130,
    131, 132, 133, 139, 146, 147, 148, 149, 160, 161, 172, 177, 178, 179, 180,
    186, 187, 188, 189, 192, 208, 217, 218, 220,
}

-----------------------------------
-- Mid-bosses (floor 3)
-----------------------------------
catalog.midbosses =
{
    {
        key     = 'craver',
        group   = catalog.groups.glassyCraver,
        name    = 'Glassy Craver',
        crystal = { id = 4075, name = 'Hope Crystal' },
        gear    =
        {
            { id = 26421, name = 'Nusku Shield' },
            { id = 26084, name = 'Sherida Earring' },
            { id = 26029, name = 'Anu Torque' },
        },
    },
    {
        key     = 'gorger',
        group   = catalog.groups.glassyGorger,
        name    = 'Glassy Gorger',
        crystal = { id = 4076, name = 'Fulfillment Crystal' },
        gear    =
        {
            { id = 26188, name = 'Kishar Ring' },
            { id = 22213, name = 'Enki Strap' },
            { id = 26030, name = 'Erra Pendant' },
        },
    },
    {
        key     = 'thinker',
        group   = catalog.groups.glassyThinker,
        name    = 'Glassy Thinker',
        crystal = { id = 4074, name = 'Thought Crystal' },
        gear    =
        {
            { id = 26028, name = 'Adad Amulet' },
            { id = 22281, name = 'Knobkierrie' },
            { id = 26420, name = 'Adapa Shield' },
        },
    },
}

-----------------------------------
-- The Caturae (floor 5)
-----------------------------------
catalog.bosses =
{
    {
        key         = 'kin',
        group       = catalog.groups.kin,
        name        = 'Kin',
        job         = 'BLM/WAR',
        signature   = 'Target -> Eleventh Dimension (marked player is terrorized unless they break away)',
        scale       = { id = 9303, name = 'Kin\'s Scale' },
        moonbow     = { id = 4077, name = 'Moonbow Steel' },
        bead        = catalog.ki.beads.kin,
        accessories =
        {
            { id = 22212, name = 'Utu Grip' },
            { id = 26186, name = 'Ilabrat Ring' },
        },
        body        = { id = 25785, name = 'Dagon Breastplate' },
    },
    {
        key         = 'gin',
        group       = catalog.groups.gin,
        name        = 'Gin',
        job         = 'THF/BLM',
        signature   = 'Zero Hour (hate reset + Perfect Dodge); Suppressive Sphere after skillchains (break it with physical blows)',
        scale       = { id = 9304, name = 'Gin\'s Scale' },
        moonbow     = { id = 4079, name = 'Moonbow Leather' },
        bead        = catalog.ki.beads.gin,
        accessories =
        {
            { id = 22280, name = 'Yamarang' },
            { id = 26187, name = 'Dingir Ring' },
        },
        body        = { id = 25786, name = 'Ashera Harness' },
    },
    {
        key         = 'fu',
        group       = catalog.groups.fu,
        name        = 'Fu',
        job         = 'WAR/BLM',
        signature   = 'Ebullient Nullification (strips nearby buffs and grows stronger per effect absorbed)',
        scale       = { id = 9307, name = 'Fu\'s Scale' },
        moonbow     = { id = 4081, name = 'Moonbow Stone' },
        bead        = catalog.ki.beads.fu,
        accessories =
        {
            { id = 26185, name = 'Niqmaddu Ring' },
            { id = 26026, name = 'Shulmanu Collar' },
        },
        body        = { id = 25789, name = 'Nisroch Jerkin' },
    },
    {
        key         = 'kyou',
        group       = catalog.groups.kyou,
        name        = 'Kyou',
        job         = 'MNK/WHM',
        signature   = 'Extreme evasion; Unfaltering Bravado (10,000 damage split among those in front); Hundred Fists when low',
        scale       = { id = 9306, name = 'Kyou\'s Scale' },
        moonbow     = { id = 4078, name = 'Moonbow Cloth' },
        bead        = catalog.ki.beads.kyou,
        accessories =
        {
            { id = 26083, name = 'Enmerkar Earring' },
            { id = 26027, name = 'Iskur Gorget' },
        },
        body        = { id = 25788, name = 'Udug Jacket' },
    },
    {
        key         = 'kei',
        group       = catalog.groups.kei,
        name        = 'Kei',
        job         = 'WHM/BLM',
        signature   = 'Magic ward broken briefly by skillchains; rotating elemental spikes; one Benediction; Dancing Fullers',
        scale       = { id = 9305, name = 'Kei\'s Scale' },
        moonbow     = { id = 4080, name = 'Moonbow Urushi' },
        bead        = catalog.ki.beads.kei,
        accessories =
        {
            { id = 26419, name = 'Ammurapi Shield' },
            { id = 26082, name = 'Lugalbanda Earring' },
        },
        body        = { id = 25787, name = 'Shamash Robe' },
    },
}

catalog.ou =
{
    key       = 'ou',
    group     = catalog.groups.ou,
    name      = 'Ou',
    job       = 'RDM/WAR',
    signature = 'Every Caturae signature move on a scripted ladder, Chainspell at 65%, and Prophylaxis at 10% (rapid self-restoration -- burn it down)',
    -- Guaranteed: one of each moonbow material + moonlight coral.
    moonbow =
    {
        { id = 4077, name = 'Moonbow Steel' },
        { id = 4078, name = 'Moonbow Cloth' },
        { id = 4079, name = 'Moonbow Leather' },
        { id = 4080, name = 'Moonbow Urushi' },
        { id = 4081, name = 'Moonbow Stone' },
        { id = 4082, name = 'Moonlight Coral' },
    },
    accessories =
    {
        { id = 26342, name = 'Regal Belt' },
        { id = 26085, name = 'Regal Earring' },
        { id = 21396, name = 'Regal Gem' },
        { id = 26038, name = 'Regal Necklace' },
        { id = 26191, name = 'Regal Ring' },
    },
    hands =
    {
        { id = 25825, name = 'Regal Captain\'s Gloves' },
        { id = 25827, name = 'Regal Cuffs' },
        { id = 25824, name = 'Regal Gauntlets' },
        { id = 25826, name = 'Regal Gloves' },
    },
    scales = { 9303, 9304, 9305, 9306, 9307 },
}

-----------------------------------
-- Bonus treasure floor caskets
-----------------------------------
catalog.caskets =
{
    count = 6,
    -- Each casket rolls one line: { weight, itemId (nil = gil), qty/gil }
    loot =
    {
        { weight = 30, gil = 20000 },
        { weight = 20, item = 'card' },      -- a paragon card for the opener's job
        { weight = 15, item = 4077 },        -- random moonbow material (runtime rerolls 4077-4081)
        { weight = 15, item = 'scale' },     -- random boss scale
        { weight = 10, item = 28273 },       -- Regal Pumps
        { weight = 10, item = 'canteen' },   -- Mystical Canteen key item
    },
}

-----------------------------------
-- Coelestrox: 5:1 card conversion + Reforged AF +2/+3
-- (reforge recipes live in omen_reforge_catalog.lua)
-----------------------------------
catalog.cardConversionRate = 5

-- Scale required per job for AF+3 steps (retail mapping).
catalog.scaleForJob =
{
    [xi.job.WAR] = 'kin',  [xi.job.MNK] = 'kin',  [xi.job.PLD] = 'kin',
    [xi.job.DRK] = 'kin',  [xi.job.SAM] = 'kin',
    [xi.job.WHM] = 'kei',  [xi.job.BLM] = 'kei',  [xi.job.RDM] = 'kei',
    [xi.job.BLU] = 'kei',  [xi.job.SCH] = 'kei',
    [xi.job.THF] = 'gin',  [xi.job.NIN] = 'gin',  [xi.job.DNC] = 'gin',
    [xi.job.RUN] = 'gin',
    [xi.job.BST] = 'fu',   [xi.job.DRG] = 'fu',   [xi.job.SMN] = 'fu',
    [xi.job.PUP] = 'fu',
    [xi.job.BRD] = 'kyou', [xi.job.RNG] = 'kyou', [xi.job.COR] = 'kyou',
    [xi.job.GEO] = 'kyou',
}

-- Paragon cards required per slot for the +1 -> +2 step (retail).
catalog.cardsForSlot =
{
    head  = 4,
    body  = 5,
    hands = 3,
    legs  = 4,
    feet  = 3,
}

-- Reforge fees (Escha Beads; retail "cheap" tier, completed instantly).
catalog.reforgeFees =
{
    plusTwo   = 10,
    plusThree = 500, -- retail: 200 (day 1) + 300 (day 2)
}

-----------------------------------
-- Helpers
-----------------------------------
catalog.getBossByKey = function(key)
    if key == 'ou' then
        return catalog.ou
    end

    for _, boss in ipairs(catalog.bosses) do
        if boss.key == key then
            return boss
        end
    end

    return nil
end

catalog.cardForJob = function(jobId)
    if jobId >= xi.job.WAR and jobId <= xi.job.RUN then
        return catalog.items.cardBase + jobId
    end

    return nil
end

return catalog
