-----------------------------------
-- fellow_companion.lua  --  "Adventuring Fellow", reimagined as an RPG companion
--
-- A personal, persistent companion ANY job can summon, that the player BUILDS:
-- it levels from your kills, and you spend the points it earns on the stats and
-- (later) abilities you choose. Inspired by retail's Adventuring Fellow, but the
-- progression is fully player-driven.
--
-- WHY A PET (not the retail fellow entity): the engine's CFellowEntity is an
-- empty // TODO stub on this fork (no stats, no spawn, no Lua hook), so there is
-- nothing to drive. Pets, by contrast, are a proven, Lua-drivable companion:
-- Ascension_Companion already spawns one for any job via RAW player:spawnPet().
-- Crucially, raw spawnPet does NOT route through xi.pet.spawnPet, so the BST /
-- SMN / WSTracker spawn-overrides never touch the Fellow -- we apply its stats
-- directly after spawn, mirroring BstJugPetOverhaul's addMod-after-calc pattern.
--
-- PHASE 1 (MVP) -- this file:
--   * !fellow menu: summon/dismiss, allocate stat points, pick role, status.
--   * Kill-XP -> levels -> stat points (xi.mob.onMobDeathEx faucet).
--   * Stat allocation layers real mods onto the live pet (instant + on re-summon).
--   * Keeper + onGameIn persistence (survives zoning; yields to real job pets).
--   * Roles: Vanguard (melee DD) + Bulwark (tank), both fully functional.
-- PHASE 2+ (later): ability/trait tree, Oracle/Magus/Hunter behaviours, respec,
--   custom name + humanoid appearance (dedicated entity), a physical Hall NPC.
--
-- ALL balance lives in CONFIG below -> tuning is a hot-reload, not a rebuild.
-- Override module (onGameIn / onMobDeathEx) -> needs ONE map restart to load;
-- after that, CONFIG edits and menu tweaks hot-reload.
-----------------------------------
require('modules/module_utils')

local m   = Module:new('fellow_companion')
local SYS = xi.msg.channel.SYSTEM_3

-- ════════════════════════════════ CONFIG ════════════════════════════════════
local CONFIG =
{
    -- Underlying pet chassis. Any jug familiar id (scripts/enum/pet_id.lua,
    -- 21..127) works; jug pets auto-engage in melee. Re-skinned via setModelId.
    -- LYNX_FAMILIAR is proven (Ascension_Companion uses it).
    petId = xi.petId.LYNX_FAMILIAR,
    model = 0,                 -- 0 = keep the chassis model; set an id to re-skin (P3 work)

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
    -- (STR/DEX/... also raise the attribute itself so it reads correctly in-game.)
    statMods =
    {
        STR = { { xi.mod.STR, 6 }, { xi.mod.ATT, 12 } },
        DEX = { { xi.mod.DEX, 6 }, { xi.mod.ACC, 10 } },
        VIT = { { xi.mod.VIT, 6 }, { xi.mod.DEF, 10 } },
        AGI = { { xi.mod.AGI, 6 }, { xi.mod.EVA, 10 } },
        INT = { { xi.mod.INT, 6 }, { xi.mod.MATT, 10 } },
        MND = { { xi.mod.MND, 6 }, { xi.mod.MDEF, 10 } },
    },
    -- Order shown in the Allocate menu.
    statOrder = { 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND' },

    -- Flat base that scales with Fellow level (×level), so it stays relevant even
    -- before you allocate. Survivability floors keep it alive at endgame.
    perLevel = { { xi.mod.ATT, 80 }, { xi.mod.ACC, 40 }, { xi.mod.DEF, 15 } },
    hpBase       = 5000,
    hpPerLevel   = 1500,
    hpPerVitPt   = 120,        -- bonus HP per allocated VIT point
    pdt          = -1500,      -- DMGPHYS (/100, engine caps each at -5000)
    mdt          = -1500,      -- DMGMAGIC

    -- Roles. mods apply on summon; autoReady = fires its TP move on its own.
    roles =
    {
        vanguard = { name = 'Vanguard', blurb = 'Melee damage dealer.',
                     mods = { { xi.mod.ATTP, 30 }, { xi.mod.DOUBLE_ATTACK, 10 } }, autoReady = true },
        bulwark  = { name = 'Bulwark',  blurb = 'Tank: more DEF, less damage taken.',
                     mods = { { xi.mod.DEF, 300 }, { xi.mod.DMGPHYS, -1000 }, { xi.mod.ENMITY, 50 } }, autoReady = true },
    },
    roleOrder   = { 'vanguard', 'bulwark' },
    defaultRole = 'vanguard',

    autoReadyTP         = 1000,
    autoReadyIntervalMs = 3000,
    keeperMs            = 10000,  -- re-check / re-spawn cadence
    firstMs             = 4000,   -- delay before first spawn after a zone-in settles
}

-- charVar keys (per-character).
local V =
{
    active = 'Fellow_Active',   -- 1 = the player wants their Fellow out
    born   = 'Fellow_Born',     -- 1 = created (starting points granted once)
    level  = 'Fellow_Level',
    xp     = 'Fellow_XP',
    points = 'Fellow_Points',   -- unspent stat points
    role   = 'Fellow_Role',
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

local function xpToNext(level) return CONFIG.xpBase * level end

-- Create-on-first-use: grant starting points exactly once.
local function ensureBorn(p)
    if getN(p, V.born) == 1 then return end
    p:setCharVar(V.born, 1)
    setN(p, V.level, 1)
    setN(p, V.points, CONFIG.startingPoints)
    setN(p, V.role, 1)  -- index into CONFIG.roleOrder (1 = defaultRole)
end

-- ════════════════════════════ Stat application ══════════════════════════════
local scheduleAutoReady -- fwd

-- Layer the Fellow's full stat block onto a freshly-spawned pet. Guarded so it
-- runs once per spawned entity (the keeper may re-check it repeatedly).
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

    if CONFIG.model and CONFIG.model > 0 then
        pcall(function() pet:setModelId(CONFIG.model) end)
    end

    if role.autoReady then scheduleAutoReady(pet) end
end

-- Self-rescheduling TP-move loop; bails when the pet dies/despawns.
scheduleAutoReady = function(pet)
    pet:timer(CONFIG.autoReadyIntervalMs, function(pp)
        if not pp or not pp:isAlive() then return end
        if pp:isEngaged() and pp:getTP() >= CONFIG.autoReadyTP then
            pp:useMobAbility()
        end
        scheduleAutoReady(pp)
    end)
end

-- Live-add a single allocated point's worth of mods to an out Fellow, so the
-- menu gives instant feedback without a re-summon.
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

-- Is THIS pet our Fellow? (vs a real job pet the player summoned.)
local function petIsFellow(pet)
    return pet ~= nil and pet:getLocalVar('fellowApplied') == 1
end

-- Keeper: while active, (re)spawn the Fellow whenever the player has NO pet and
-- pets are allowed here -- so it survives zoning/death and YIELDS to real job
-- pets (a SMN/BST/etc. who calls their own pet simply replaces it; on dismiss,
-- the Fellow returns within keeperMs).
local function keeper(p, name, gen)
    if not p or genByName[name] ~= gen then return end
    if getN(p, V.active) ~= 1 then return end          -- dismissed -> stop

    if not p:hasPet() and p:canUseMisc(xi.zoneMisc.PET) then
        pcall(function()
            p:spawnPet(CONFIG.petId)
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
    armKeeper(p, 30)  -- near-immediate first spawn
    p:printToPlayer('[Fellow] Your Adventuring Fellow heeds the call.', SYS)
end

local function dismiss(p)
    setN(p, V.active, 0)
    genByName[p:getName()] = (genByName[p:getName()] or 0) + 1  -- invalidate keeper
    if p:hasPet() and petIsFellow(p:getPet()) then
        local pet = p:getPet()
        pcall(function() DespawnMob(pet:getID(), 0) end)
    end
    p:printToPlayer('[Fellow] Your Adventuring Fellow returns to rest.', SYS)
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
    p:printToPlayer(string.format('=== Adventuring Fellow ===  Lv.%d %s', lvl, role.name), SYS)
    if lvl < CONFIG.maxLevel then
        p:printToPlayer(string.format('  XP: %d / %d to next level   |   Unspent points: %d',
            getN(p, V.xp), xpToNext(lvl), getPoints(p)), SYS)
    else
        p:printToPlayer(string.format('  Level MAX   |   Unspent points: %d', getPoints(p)), SYS)
    end
    local parts = {}
    for _, stat in ipairs(CONFIG.statOrder) do
        parts[#parts + 1] = string.format('%s %d', stat, getStatPts(p, stat))
    end
    p:printToPlayer('  Allocation: ' .. table.concat(parts, '  '), SYS)
end

-- ════════════════════════════════ Menus ═════════════════════════════════════
local openMain, openAllocate, openRole

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
        { 'View Status',  function(pp) statusReport(pp); openMain(pp) end },
        { 'Close',        function(pp) end },
    }
    show(p, string.format('Fellow  Lv.%d', lvl), options)
end

openAllocate = function(p)
    local pts = getPoints(p)
    if pts <= 0 then
        p:printToPlayer('[Fellow] No unspent points. Defeat foes with your Fellow out to earn more.', SYS)
        openMain(p)
        return
    end
    local options = {}
    for _, stat in ipairs(CONFIG.statOrder) do
        local s = stat
        options[#options + 1] =
        {
            string.format('%s  (now %d)', s, getStatPts(p, s)),
            function(pp)
                if getPoints(pp) <= 0 then openMain(pp); return end
                setN(pp, V.points, getPoints(pp) - 1)
                setN(pp, statVar(s), getStatPts(pp, s) + 1)
                liveAddStat(pp, s)
                pp:printToPlayer(string.format('[Fellow] %s raised to %d. (%d points left)',
                    s, getStatPts(pp, s), getPoints(pp)), SYS)
                openAllocate(pp)
            end,
        }
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

-- ════════════════════════════════ Faucet ════════════════════════════════════
-- Kills grant Fellow XP, but only while the player's Fellow is actually summoned
-- (rewards using it). Party-wide if enabled: same-zone members with a Fellow out
-- each earn from the kill.
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
-- Used by the !fellow command (commands/fellow.lua) and open to other systems.
xi.fellow = xi.fellow or {}
xi.fellow.openMenu = function(p) openMain(p) end
xi.fellow.summon   = function(p) summon(p) end
xi.fellow.dismiss  = function(p) dismiss(p) end
xi.fellow.status   = function(p) statusReport(p) end
xi.fellow.addXp    = function(p, n) addXp(p, n) end
xi.fellow.grantPoints = function(p, n) ensureBorn(p); setN(p, V.points, getPoints(p) + math.max(0, n)) end

return m
