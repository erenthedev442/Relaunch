-----------------------------------
-- fellow_companion.lua  --  "Adventuring Fellow", reimagined as an RPG companion
--
-- A personal, persistent companion ANY job can summon, that the player BUILDS:
-- it levels from your kills, and you spend the points it earns on the stats you
-- choose, plus pick its NAME and APPEARANCE. Inspired by retail's Adventuring
-- Fellow, but the progression is fully player-driven.
--
-- WHY A PET (not the retail fellow entity): the engine's CFellowEntity is an
-- empty // TODO stub on this fork (no stats, no spawn, no Lua hook), so there is
-- nothing to drive. Pets are a proven, Lua-drivable companion: Ascension_Companion
-- already spawns one for any job via RAW player:spawnPet(). Crucially, raw spawnPet
-- does NOT route through xi.pet.spawnPet, so the BST / SMN / WSTracker spawn-
-- overrides never touch the Fellow -- we apply its stats directly after spawn,
-- mirroring BstJugPetOverhaul's addMod-after-calc pattern.
--
-- NAME + APPEARANCE:
--   * NAME  -> pet:renameEntity(str, true). setPetName is a no-op for jug pets
--     (it only writes char_pet wyvern/chocobo rows); renameEntity sets the LIVE
--     displayed name to an arbitrary string on any pet. Re-applied each spawn.
--   * MODEL -> we spawn a single combat chassis (LYNX_FAMILIAR) then immediately
--     call pet:setModelId(id) to overlay an NPC/avatar model. This gives authentic
--     NPC visuals while keeping jug-pet combat AI (auto-engages; SMN avatar AI
--     only follows). Avatar model IDs 791-798 confirmed in Fantoccini_Avatar.lua.
--     Note: player-character looks (race/face/equipment slots) are NOT supported
--     via setModelId on CPetEntity -- NPC/mob model IDs work fine.
--
-- PHASE 1 (MVP): summon/dismiss, allocate stat points, pick role, name + model,
--   kill-XP -> levels, keeper + onGameIn persistence. Roles: Vanguard / Bulwark.
-- PHASE 2+: ability/trait tree, Oracle/Magus/Hunter behaviours, respec, humanoid
--   appearance, a physical Hall NPC.
--
-- ALL balance + name/model lists live in CONFIG -> tuning is a hot-reload.
-- Override module (onGameIn / onMobDeathEx) -> needs ONE map restart to load.
-----------------------------------
require('modules/module_utils')

local m   = Module:new('fellow_companion')
local SYS = xi.msg.channel.SYSTEM_3

-- ════════════════════════════════ CONFIG ════════════════════════════════════
local CONFIG =
{
    -- DEFAULT chassis (a jug familiar; auto-engages in melee). The Appearance
    -- picker swaps this petId to another familiar. Spawned via RAW player:spawnPet,
    -- so it bypasses the xi.pet.spawnPet overrides (no BST/SMN collision).
    petId = xi.petId.LYNX_FAMILIAR,

    maxLevel       = 50,
    startingPoints = 6,        -- granted once, when the Fellow is first created
    pointsPerLevel = 3,        -- stat points granted per level-up

    -- XP: each kill grants clamp(mobLevel * xpPerMobLevel, xpMin, xpMax), but only
    -- while your Fellow is summoned. xpToNext(L) = xpBase * L (linear ramp).
    xpPerMobLevel = 3,
    xpMin         = 5,
    xpMax         = 200,
    xpBase        = 80,
    partyWideXp   = true,      -- party members with a Fellow out also earn from the kill

    -- Per-allocated-point -> mods. One point in a stat adds ALL of its mods.
    statMods =
    {
        -- Attributes: each point adds the attribute + a derived combat stat.
        STR = { { xi.mod.STR, 6 }, { xi.mod.ATT, 12 } },
        DEX = { { xi.mod.DEX, 6 }, { xi.mod.ACC, 10 } },
        VIT = { { xi.mod.VIT, 6 }, { xi.mod.DEF, 10 } },
        AGI = { { xi.mod.AGI, 6 }, { xi.mod.EVA, 10 } },
        INT = { { xi.mod.INT, 6 }, { xi.mod.MATT, 10 } },
        MND = { { xi.mod.MND, 6 }, { xi.mod.MDEF, 10 } },
        -- Advanced categories: focused combat mods that STACK on top of the attributes.
        Ferocity  = { { xi.mod.ATTP, 1 } },                                -- +1% attack
        Critical  = { { xi.mod.CRITHITRATE, 1 } },                         -- +1% critical hit rate
        Frenzy    = { { xi.mod.DOUBLE_ATTACK, 1 } },                       -- +1% Double Attack
        Onslaught = { { xi.mod.TRIPLE_ATTACK, 1 }, { xi.mod.STORETP, 3 } },-- +1% Triple Attack, +3 Store TP
        Sorcery   = { { xi.mod.MATT, 12 }, { xi.mod.MACC, 6 } },           -- magic atk + acc (boosts Magus)
        Celerity  = { { xi.mod.HASTE_GEAR, 8 } },                          -- attack speed (engine-capped ~25%)
        Warding   = { { xi.mod.DMGPHYS, -20 }, { xi.mod.DMGMAGIC, -20 } }, -- damage taken - (engine-capped -50%)
        Vigor     = { { xi.mod.REGEN, 3 }, { xi.mod.REFRESH, 1 } },        -- HP + MP regen per tick
    },
    statOrder = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND',
                  'Ferocity', 'Critical', 'Frenzy', 'Onslaught', 'Sorcery', 'Celerity', 'Warding', 'Vigor' },

    -- Flat base that scales with Fellow level (×level), plus survivability floors.
    perLevel = { { xi.mod.ATT, 80 }, { xi.mod.ACC, 40 }, { xi.mod.DEF, 15 } },
    hpBase       = 5000,
    hpPerLevel   = 1500,
    hpPerVitPt   = 120,
    pdt          = -1500,
    mdt          = -1500,

    -- A role applies its `mods` on spawn; an optional `behavior` ('heal'/'nuke'/
    -- 'ranged') runs each combat-loop tick (see scheduleCombatLoop). Every role
    -- still melee-assists + uses TP moves; behaviors are additive on top.
    roles =
    {
        vanguard  = { name = 'Vanguard',  blurb = 'Balanced melee damage dealer.',
                      mods = { { xi.mod.ATTP, 30 }, { xi.mod.DOUBLE_ATTACK, 10 } } },
        berserker = { name = 'Berserker', blurb = 'All-out melee offense; takes a bit more damage.',
                      mods = { { xi.mod.ATTP, 60 }, { xi.mod.DOUBLE_ATTACK, 20 }, { xi.mod.TRIPLE_ATTACK, 10 }, { xi.mod.DMGPHYS, 1000 } } },
        bulwark   = { name = 'Bulwark',   blurb = 'Tank: more DEF, less damage taken, holds hate.',
                      mods = { { xi.mod.DEF, 300 }, { xi.mod.DMGPHYS, -1000 }, { xi.mod.ENMITY, 50 } } },
        oracle    = { name = 'Oracle',    blurb = 'Battle-healer: fights and mends your wounds when hurt.',
                      mods = { { xi.mod.MND, 150 }, { xi.mod.DEF, 150 }, { xi.mod.MDEF, 150 } }, behavior = 'heal' },
        magus     = { name = 'Magus',     blurb = 'Battle-mage: fights and hurls elemental magic at your foe.',
                      mods = { { xi.mod.INT, 150 }, { xi.mod.MATT, 400 }, { xi.mod.MACC, 200 } }, behavior = 'nuke' },
        hunter    = { name = 'Hunter',    blurb = 'Ranger: fights and adds ranged strikes to your target.',
                      mods = { { xi.mod.AGI, 150 }, { xi.mod.ACC, 200 }, { xi.mod.EVA, 100 } }, behavior = 'ranged' },
    },
    roleOrder   = { 'vanguard', 'berserker', 'bulwark', 'oracle', 'magus', 'hunter' },
    defaultRole = 'vanguard',

    -- NAME picker: curated person-names (lifted from the engine's dead fellowNames
    -- table in fellowentity.cpp). renameEntity wire limit ~15 chars -> keep short.
    names =
    {
        'Siegward', 'Theobald', 'Gunnar', 'Ferdinand', 'Beatrice', 'Henrietta',
        'Karyn', 'Nanako', 'Gauldeval', 'Romidiant', 'Liabelle', 'Radille',
        'Nokum-Akkum', 'Yawawa', 'Cupapa', 'Raka Maimhov', 'Voldai', 'Zoldof',
    },

    -- APPEARANCE picker: each entry has a modelId applied via setModelId() right after
    -- spawn. The spawn chassis is always LYNX_FAMILIAR (combat AI); only the visual
    -- is swapped. Model IDs derived from mob_pools.modelid bytes [2-3] little-endian.
    models =
    {
        { name = 'Moogle',     modelId = 3035 },  -- mob_pools: moogle
        { name = 'Mandragora', modelId = 300  },  -- mob_pools: Mandragora
        { name = 'Coeurl',     modelId = 367  },  -- mob_pools: Coeurl
        { name = 'Sabotender', modelId = 372  },  -- mob_pools: Sabotender (Cactuar)
        { name = 'Cardian',    modelId = 431  },  -- mob_pools: Cardian_Prototype
        { name = 'Goblin',     modelId = 292  },  -- mob_pools: Goblin_Gruel
        { name = 'Yagudo',     modelId = 580  },  -- mob_pools: Yagudo_Initiate
        { name = 'Tonberry',   modelId = 1177 },  -- mob_pools: Tonberry_Bedeviler
        { name = 'Antican',    modelId = 1280 },  -- mob_pools: Antican_Quaestor
        { name = 'Boggart',    modelId = 451  },  -- mob_pools: Boggart
        { name = 'Goobbue',    modelId = 296  },  -- mob_pools: Goobbue
        { name = 'Adventurer', modelId = 3119 },  -- trust: Cornelia humanoid NPC
    },

    autoReadyTP         = 1000,
    combatLoopMs        = 2000,   -- auto-assist + auto-Ready + role-behaviour tick cadence

    -- Role behaviours, applied per combat-loop tick (placeholders -- tune in playtest):
    healHpp        = 70,    -- Oracle heals the master while their HP% is at/below this
    healBase       = 300,   -- Oracle: + healPerLevel*FellowLevel HP restored per tick while hurt
    healPerLevel   = 60,
    nukeBase       = 1500,  -- Magus: magic damage to the target per tick while engaged
    nukePerLevel   = 300,
    rangedBase     = 1500,  -- Hunter: ranged damage to the target per tick while engaged
    rangedPerLevel = 300,

    keeperMs            = 10000,
    firstMs             = 4000,
    namesPerPage        = 6,   -- customMenu caps: keep page + nav <= 8 options / 150 bytes
}

-- charVar keys (per-character; ALL INTEGER).
local V =
{
    active   = 'Fellow_Active',
    born     = 'Fellow_Born',
    level    = 'Fellow_Level',
    xp       = 'Fellow_XP',
    points   = 'Fellow_Points',
    role     = 'Fellow_Role',     -- index into CONFIG.roleOrder
    nameIdx  = 'Fellow_NameIdx',  -- index into CONFIG.names
    modelPet = 'Fellow_ModelPet', -- index into CONFIG.models (each carries a petId)
}
local function statVar(stat) return 'Fellow_' .. stat end

-- ════════════════════════════ Data-model helpers ════════════════════════════
local function getN(p, k)     return p:getCharVar(k) or 0 end
local function setN(p, k, n)  p:setCharVar(k, math.max(0, math.floor(n))) end

local function getLevel(p)  return math.max(1, getN(p, V.level)) end
local function getPoints(p) return getN(p, V.points) end
local function getStatPts(p, stat) return getN(p, statVar(stat)) end

-- Role is stored as an INTEGER index into CONFIG.roleOrder (charVars are ints,
-- not strings). 0/unset -> default.
local function getRole(p)
    local key = CONFIG.roleOrder[getN(p, V.role)]
    if key and CONFIG.roles[key] then return key end
    return CONFIG.defaultRole
end
local function roleDef(p) return CONFIG.roles[getRole(p)] or CONFIG.roles[CONFIG.defaultRole] end

-- Appearance = NPC model ID applied via setModelId after spawn; Name = live display name.
local function chosenModelId(p)
    local mdl = CONFIG.models[getN(p, V.modelPet)]
    return mdl and mdl.modelId
end
local function chosenName(p)
    return CONFIG.names[getN(p, V.nameIdx)]  -- nil if unset -> no rename
end

local function xpToNext(level) return CONFIG.xpBase * level end

-- Create-on-first-use: grant starting points + sensible defaults exactly once.
local function ensureBorn(p)
    if getN(p, V.born) == 1 then return end
    p:setCharVar(V.born, 1)
    setN(p, V.level, 1)
    setN(p, V.points, CONFIG.startingPoints)
    setN(p, V.role, 1)      -- defaultRole
    setN(p, V.nameIdx, 1)   -- a proper name by default; player can re-pick
    setN(p, V.modelPet, 1)  -- default chassis (Lynx)
end

-- ════════════════════════════ Stat application ══════════════════════════════
local scheduleCombatLoop -- fwd

-- Layer the Fellow's full stat block + chosen name onto a freshly-spawned pet.
-- Guarded so it runs once per spawned entity.
local function applyFellow(p, pet)
    if not pet or pet:getLocalVar('fellowApplied') ~= 0 then return end
    pet:setLocalVar('fellowApplied', 1)

    local lvl  = getLevel(p)
    local role = roleDef(p)

    for _, mv in ipairs(CONFIG.perLevel) do pet:addMod(mv[1], mv[2] * lvl) end
    for _, mv in ipairs(role.mods or {})  do pet:addMod(mv[1], mv[2]) end

    for stat, mods in pairs(CONFIG.statMods) do
        local pts = getStatPts(p, stat)
        if pts > 0 then
            for _, mv in ipairs(mods) do pet:addMod(mv[1], mv[2] * pts) end
        end
    end

    pet:addMod(xi.mod.DMGPHYS,  CONFIG.pdt)
    pet:addMod(xi.mod.DMGMAGIC, CONFIG.mdt)

    local bonusHP = CONFIG.hpBase + CONFIG.hpPerLevel * lvl + getStatPts(p, 'VIT') * CONFIG.hpPerVitPt
    pet:setMaxHP(pet:getMaxHP() + bonusHP)
    pet:addHP(bonusHP)

    -- Live display name (arbitrary string; silent=true to avoid console spam).
    local nm = chosenName(p)
    if nm then pcall(function() pet:renameEntity(nm, true) end) end

    -- Visual NPC model overlay (combat chassis remains LYNX_FAMILIAR).
    local mdlId = chosenModelId(p)
    if mdlId then pcall(function() pet:setModelId(mdlId) end) end

    scheduleCombatLoop(p, pet)
end

-- Self-rescheduling COMBAT loop. Jug pets DON'T assist a non-BST master on their
-- own, and a non-pet job has no Fight/Sic command -- so each tick we:
--   * AUTO-ASSIST: if the master is engaged and the Fellow is idle, order it onto
--     the master's battle target (master:petAttack = the BST Fight order, not
--     job-gated; master:getTarget() = the battle target, same as allyassist).
--   * AUTO-READY: if engaged with capped TP, fire its TP move.
-- Bails when the pet dies/despawns. The master ref is captured in the closure; by
-- the time it could go invalid the pet has already despawned (pets die with their
-- master) so the loop has stopped -- and all master access is pcall-guarded.
scheduleCombatLoop = function(master, pet)
    pet:timer(CONFIG.combatLoopMs, function(p)
        if not p or not p:isAlive() then return end
        pcall(function()
            if not (master and master:isAlive()) then return end
            local beh = roleDef(master).behavior
            local lvl = getLevel(master)

            -- Oracle: mend the master whenever their HP is low (works in or out of combat).
            if beh == 'heal' then
                local maxhp = math.max(1, master:getMaxHP())
                if (master:getHP() * 100 / maxhp) <= CONFIG.healHpp then
                    master:addHP(CONFIG.healBase + CONFIG.healPerLevel * lvl)
                end
            end

            -- Combat: every role fights (assist when idle, Ready at TP cap).
            if master:isEngaged() then
                local tgt = master:getTarget()
                if not p:isEngaged() then
                    if tgt and not tgt:isDead() then master:petAttack(tgt) end
                elseif p:getTP() >= CONFIG.autoReadyTP then
                    p:useMobAbility()  -- no arg = pet picks from its Ready-move list
                end
                -- Magus / Hunter: bonus magic / ranged damage on the master's target.
                if tgt and not tgt:isDead() then
                    if beh == 'nuke' then
                        tgt:takeDamage(CONFIG.nukeBase + CONFIG.nukePerLevel * lvl, p, xi.attackType.MAGICAL, xi.damageType.FIRE)
                    elseif beh == 'ranged' then
                        tgt:takeDamage(CONFIG.rangedBase + CONFIG.rangedPerLevel * lvl, p, xi.attackType.RANGED, xi.damageType.PIERCING)
                    end
                end
            end
        end)
        scheduleCombatLoop(master, p)
    end)
end

-- Live-add a single allocated point's worth of mods to an out Fellow.
local function liveAddStat(p, stat)
    if not p:hasPet() then return end
    local pet = p:getPet()
    if pet and pet:getLocalVar('fellowApplied') == 1 then
        for _, mv in ipairs(CONFIG.statMods[stat]) do pet:addMod(mv[1], mv[2]) end
        if stat == 'VIT' then
            pet:setMaxHP(pet:getMaxHP() + CONFIG.hpPerVitPt)
            pet:addHP(CONFIG.hpPerVitPt)
        end
    end
end

-- ════════════════════════════ Summon / keeper ═══════════════════════════════
local genByName = {}

local function petIsFellow(pet)
    return pet ~= nil and pet:getLocalVar('fellowApplied') == 1
end

-- Keeper: while active, (re)spawn the chosen chassis whenever the player has NO
-- pet and pets are allowed here -- survives zoning/death, yields to real job pets.
local function keeper(p, name, gen)
    if not p or genByName[name] ~= gen then return end
    if getN(p, V.active) ~= 1 then return end

    if not p:hasPet() and p:canUseMisc(xi.zoneMisc.PET) then
        pcall(function()
            p:spawnPet(CONFIG.petId)  -- always Lynx (combat AI); setModelId applied in applyFellow
            local pet = p:getPet()
            if pet then applyFellow(p, pet) end
        end)
    end

    p:timer(CONFIG.keeperMs, function(pp) keeper(pp, name, gen) end)
end

local function armKeeper(p, delayMs)
    local name = p:getName()
    local gen  = (genByName[name] or 0) + 1
    genByName[name] = gen
    p:timer(delayMs or CONFIG.firstMs, function(pp) keeper(pp, name, gen) end)
end

local function summon(p)
    ensureBorn(p)
    setN(p, V.active, 1)
    if p:hasPet() and not petIsFellow(p:getPet()) then
        p:printToPlayer('[Fellow] Dismiss your current pet first; your Fellow will appear.', SYS)
    end
    armKeeper(p, 30)
    p:printToPlayer('[Fellow] Your Adventuring Fellow heeds the call.', SYS)
end

local function dismiss(p)
    setN(p, V.active, 0)
    genByName[p:getName()] = (genByName[p:getName()] or 0) + 1
    if p:hasPet() and petIsFellow(p:getPet()) then
        pcall(function() p:despawnPet() end)  -- the proper pet-release call (BST Leave / SMN Release)
    end
    p:printToPlayer('[Fellow] Your Adventuring Fellow returns to rest.', SYS)
end

-- Re-spawn the live Fellow now (used after an appearance change). No-op if not out.
local function respawnIfOut(p)
    if getN(p, V.active) ~= 1 then return end
    if p:hasPet() and petIsFellow(p:getPet()) then
        pcall(function() p:despawnPet() end)
    end
    armKeeper(p, 700)  -- keeper re-spawns the new chassis shortly
end

-- ════════════════════════════════ XP / levels ═══════════════════════════════
local function addXp(p, amount)
    if amount <= 0 then return end
    local lvl     = getLevel(p)
    local xp      = getN(p, V.xp) + amount
    local gained  = 0
    while lvl < CONFIG.maxLevel and xp >= xpToNext(lvl) do
        xp  = xp - xpToNext(lvl)
        lvl = lvl + 1
        gained = gained + CONFIG.pointsPerLevel
    end
    setN(p, V.level, lvl)
    setN(p, V.xp, (lvl >= CONFIG.maxLevel) and 0 or xp)
    if gained > 0 then
        setN(p, V.points, getPoints(p) + gained)
        p:printToPlayer(string.format(
            '[Fellow] Your Fellow reached level %d! +%d points to spend (%d unspent).',
            lvl, gained, getPoints(p)), SYS)
    end
end

-- ════════════════════════════════ Status ════════════════════════════════════
local function statusReport(p)
    ensureBorn(p)
    local lvl  = getLevel(p)
    local role = roleDef(p)
    local nm   = chosenName(p) or '(unnamed)'
    local mdl  = CONFIG.models[getN(p, V.modelPet)]
    p:printToPlayer(string.format('=== %s ===  Lv.%d %s  (%s)',
        nm, lvl, role.name, (mdl and mdl.name) or 'Moogle'), SYS)
    if lvl < CONFIG.maxLevel then
        p:printToPlayer(string.format('  XP: %d / %d to next level   |   Unspent points: %d',
            getN(p, V.xp), xpToNext(lvl), getPoints(p)), SYS)
    else
        p:printToPlayer(string.format('  Level MAX   |   Unspent points: %d', getPoints(p)), SYS)
    end
    local parts = {}
    for _, stat in ipairs(CONFIG.statOrder) do
        local v = getStatPts(p, stat)
        if v > 0 then parts[#parts + 1] = string.format('%s %d', stat, v) end
    end
    p:printToPlayer('  Allocation: ' .. (#parts > 0 and table.concat(parts, '  ') or 'none yet'), SYS)
end

-- ════════════════════════════════ Menus ═════════════════════════════════════
local openMain, openAllocate, openRole, openName, openModel

local function show(p, title, options)
    local snapshot = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snapshot) end)
end

openMain = function(p)
    ensureBorn(p)
    local lvl = getLevel(p)
    local out = (getN(p, V.active) == 1)
    local options =
    {
        { out and 'Dismiss Fellow' or 'Summon Fellow',
          function(pp) if getN(pp, V.active) == 1 then dismiss(pp) else summon(pp) end end },
        { string.format('Allocate Points (%d)', getPoints(p)), function(pp) openAllocate(pp) end },
        { 'Choose Role',  function(pp) openRole(pp) end },
        { 'Choose Name',  function(pp) openName(pp, 0) end },
        { 'Appearance',   function(pp) openModel(pp, 0) end },
        { 'View Status',  function(pp) statusReport(pp); openMain(pp) end },
        { 'Close',        function(pp) end },
    }
    show(p, string.format('Fellow  Lv.%d', lvl), options)
end

openAllocate = function(p, page)
    local pts = getPoints(p)
    if pts <= 0 then
        p:printToPlayer('[Fellow] No unspent points. Defeat foes with your Fellow out to earn more.', SYS)
        openMain(p)
        return
    end
    page = page or 0
    local order = CONFIG.statOrder
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#order / per))
    page = page % pages
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #order) do
        local s = order[i]
        options[#options + 1] =
        {
            string.format('%s (%d)', s, getStatPts(p, s)),
            function(pp)
                if getPoints(pp) <= 0 then openMain(pp); return end
                setN(pp, V.points, getPoints(pp) - 1)
                setN(pp, statVar(s), getStatPts(pp, s) + 1)
                liveAddStat(pp, s)
                pp:printToPlayer(string.format('[Fellow] %s raised to %d. (%d points left)',
                    s, getStatPts(pp, s), getPoints(pp)), SYS)
                openAllocate(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openAllocate(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, string.format('Allocate (%d left)', pts), options)
end

openRole = function(p)
    local cur = getRole(p)
    local options = {}
    for i, key in ipairs(CONFIG.roleOrder) do
        local idx = i
        local r   = CONFIG.roles[key]
        local label = (key == cur) and (r.name .. ' *') or r.name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.role, idx)
                pp:printToPlayer(string.format('[Fellow] Role set: %s -- %s Re-summon to apply.',
                    r.name, r.blurb), SYS)
                openRole(pp)
            end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Choose Role', options)
end

-- Paginated name picker -> renames the live Fellow instantly (and on next spawn).
openName = function(p, page)
    page = page or 0
    local names = CONFIG.names
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#names / per))
    page = page % pages
    local cur   = getN(p, V.nameIdx)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #names) do
        local idx = i
        local label = (idx == cur) and (names[idx] .. ' *') or names[idx]
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.nameIdx, idx)
                if pp:hasPet() and petIsFellow(pp:getPet()) then
                    pcall(function() pp:getPet():renameEntity(names[idx], true) end)
                end
                pp:printToPlayer(string.format('[Fellow] Name set: %s', names[idx]), SYS)
                openName(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openName(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Choose Name', options)
end

-- Paginated appearance picker -> swaps the spawn chassis (petId); re-summon to apply.
openModel = function(p, page)
    page = page or 0
    local models = CONFIG.models
    local per    = CONFIG.namesPerPage
    local pages  = math.max(1, math.ceil(#models / per))
    page = page % pages
    local cur    = getN(p, V.modelPet)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #models) do
        local idx = i
        local label = (idx == cur) and (models[idx].name .. ' *') or models[idx].name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.modelPet, idx)
                respawnIfOut(pp)  -- live-swap the chassis if the Fellow is out
                pp:printToPlayer(string.format('[Fellow] Appearance set: %s.', models[idx].name), SYS)
                openModel(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openModel(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Appearance', options)
end

-- ════════════════════════════════ Faucet ════════════════════════════════════
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if player == nil or player:getObjType() ~= xi.objType.PC then return end

        local mobLvl = mob:getMainLvl() or 1
        local xp     = math.max(CONFIG.xpMin, math.min(CONFIG.xpMax, mobLvl * CONFIG.xpPerMobLevel))

        local function credit(pc)
            if pc and pc:getObjType() == xi.objType.PC
               and getN(pc, V.active) == 1 and pc:hasPet() and petIsFellow(pc:getPet()) then
                addXp(pc, xp)
            end
        end

        if isKiller and CONFIG.partyWideXp then
            local zoneId = mob:getZoneID()
            local ok, party = pcall(function() return player:getParty() end)
            if ok and party and #party > 0 then
                for _, mem in ipairs(party) do
                    if mem and mem:getZoneID() == zoneId then credit(mem) end
                end
                return
            end
        end
        if isKiller then credit(player) end
    end)
end)

-- ════════════════════════════════ Login re-arm ══════════════════════════════
m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)
    pcall(function()
        if getN(player, V.active) == 1 then
            armKeeper(player, CONFIG.firstMs)
        end
    end)
end)

-- ════════════════════════════════ Public API ════════════════════════════════
xi.fellow = xi.fellow or {}
xi.fellow.openMenu    = function(p) openMain(p) end
xi.fellow.summon      = function(p) summon(p) end
xi.fellow.dismiss     = function(p) dismiss(p) end
xi.fellow.status      = function(p) statusReport(p) end
xi.fellow.addXp       = function(p, n) addXp(p, n) end
xi.fellow.grantPoints = function(p, n) ensureBorn(p); setN(p, V.points, getPoints(p) + math.max(0, n)) end

return m
