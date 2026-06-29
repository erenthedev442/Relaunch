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

    maxLevel       = 120,
    startingPoints = 6,        -- granted once, when the Fellow is first created
    pointsPerLevel = 3,        -- stat points granted per level-up
    -- Post-cap progression: once the Fellow hits maxLevel you can BUY stat points
    -- with gil (!fellow -> Allocate Points -> Buy Points) and keep dumping them.
    buyPointsCost  = 50000,    -- gil per purchased point (tunable)
    -- Overflow guard: a pet's mods are int16 and WRAP NEGATIVE past ~32k. STR adds
    -- the biggest per-point mod (+12 ATT), so cap points-per-category to stay safe
    -- (1500 STR = +18000 ATT; + ~9600 from levels = ~27.6k, under the wrap).
    statCap        = 1500,

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
        -- `defaultWs` = fired at TP cap when the player picks "(Default)" in the Role menu.
        -- `moves`     = curated per-role list shown in the TP Move picker (replaces the old
        --               shared global tpMoves pool). Index stored in Fellow_TP_<role> charVar.
        vanguard  =
        {
            name = 'Vanguard', blurb = 'Balanced melee damage dealer.', defaultWs = xi.mobSkill.DANCING_EDGE,
            mods  = { { xi.mod.ATTP, 30 }, { xi.mod.DOUBLE_ATTACK, 10 } },
            moves =
            {
                { name = 'Penta Thrust',     ws = xi.mobSkill.PENTA_THRUST       },  -- 5-hit barrage
                { name = 'Vorpal Blade',     ws = xi.mobSkill.VORPAL_BLADE_1     },  -- fast slash
                { name = 'Brain Crush',      ws = xi.mobSkill.BRAIN_CRUSH_1      },  -- heavy crush (Antican)
                { name = 'Spinning Attack',  ws = xi.mobSkill.SPINNING_ATTACK_1  },  -- spinning multi-hit
                { name = 'Sonic Blade',      ws = xi.mobSkill.SONIC_BLADE        },  -- sonic cutting wave
            },
        },
        berserker =
        {
            name = 'Berserker', blurb = 'All-out melee offense; takes a bit more damage.', defaultWs = xi.mobSkill.HEAVY_BLOW,
            mods  = { { xi.mod.ATTP, 60 }, { xi.mod.DOUBLE_ATTACK, 20 }, { xi.mod.TRIPLE_ATTACK, 10 }, { xi.mod.DMGPHYS, 1000 } },
            moves =
            {
                { name = 'Auroral Uppercut', ws = xi.mobSkill.AURORAL_UPPERCUT_1 },  -- massive single hit
                { name = 'Amorphic Scythe',  ws = xi.mobSkill.AMORPHIC_SCYTHE   },  -- heavy scythe
                { name = 'Nightmare Scythe', ws = xi.mobSkill.NIGHTMARE_SCYTHE   },  -- dark scythe
                { name = 'Sickle Moon',      ws = xi.mobSkill.SICKLE_MOON_1      },  -- crescent slash
                { name = 'Backhand Blow',    ws = xi.mobSkill.BACKHAND_BLOW_1    },  -- brutal backhand
            },
        },
        bulwark   =
        {
            name = 'Bulwark', blurb = 'Tank: more DEF, less damage taken, holds hate.', defaultWs = xi.mobSkill.EARTH_CRUSHER,
            mods  = { { xi.mod.DEF, 300 }, { xi.mod.DMGPHYS, -1000 }, { xi.mod.ENMITY, 50 } }, behavior = 'tank',
            moves =
            {
                { name = 'Earth Pounder',    ws = xi.mobSkill.EARTH_POUNDER      },  -- ground slam
                { name = 'Earthbreaker',     ws = xi.mobSkill.EARTHBREAKER_1     },  -- shockwave
                { name = 'Maelstrom',        ws = xi.mobSkill.MAELSTROM_1        },  -- AoE hate pull
                { name = 'Earth Shock',      ws = xi.mobSkill.EARTH_SHOCK        },  -- tremor
            },
        },
        oracle    =
        {
            name = 'Oracle', blurb = 'Battle-healer: fights and mends your wounds when hurt.', defaultWs = xi.mobSkill.DIVINE_JUDGMENT,
            mods  = { { xi.mod.MND, 150 }, { xi.mod.DEF, 150 }, { xi.mod.MDEF, 150 } }, behavior = 'heal',
            moves =
            {
                { name = 'Benediction',      ws = xi.mobSkill.BENEDICTION_1      },  -- major heal burst
                { name = 'Divine Spear',     ws = xi.mobSkill.DIVINE_SPEAR       },  -- holy lance
                { name = 'Empty Salvation',  ws = xi.mobSkill.EMPTY_SALVATION_1  },  -- light nova
                { name = 'Cursed Sphere',    ws = xi.mobSkill.CURSED_SPHERE_1    },  -- dark burst
            },
        },
        magus     =
        {
            name = 'Magus', blurb = 'Battle-mage: fights and hurls elemental magic at your foe.', defaultWs = xi.mobSkill.FIRE_IV,
            mods  = { { xi.mod.INT, 150 }, { xi.mod.MATT, 400 }, { xi.mod.MACC, 200 } }, behavior = 'nuke',
            moves =
            {
                { name = 'Blizzard IV',      ws = xi.mobSkill.BLIZZARD_IV        },
                { name = 'Thunderstrike',    ws = xi.mobSkill.THUNDERSTRIKE      },  -- fTP 9, AoE stun
                { name = 'Aero IV',          ws = xi.mobSkill.AERO_IV            },
                { name = 'Stone IV',         ws = xi.mobSkill.STONE_IV           },
                { name = 'Water IV',         ws = xi.mobSkill.WATER_IV           },
            },
        },
        hunter    =
        {
            name = 'Hunter', blurb = 'Ranger: fights and adds ranged strikes to your target.', defaultWs = xi.mobSkill.EAGLE_EYE_SHOT_HUMANOID,
            mods  = { { xi.mod.AGI, 150 }, { xi.mod.ACC, 200 }, { xi.mod.EVA, 100 } }, behavior = 'ranged',
            moves =
            {
                { name = 'Barbed Crescent',  ws = xi.mobSkill.BARBED_CRESCENT_1   },  -- crescent projectile
                { name = 'Barrage',          ws = xi.mobSkill.BARRAGE             },  -- rapid volley
                { name = 'Bomb Toss',        ws = xi.mobSkill.BOMB_TOSS_1         },  -- explosive throw
                { name = 'Broadside Barrage',ws = xi.mobSkill.BROADSIDE_BARRAGE_1 },  -- wide volley
                { name = 'Dark Shot',        ws = xi.mobSkill.DARK_SHOT           },  -- dark ranged
            },
        },
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
        -- `ws` = this form's SIGNATURE TP move, forced at TP cap (useMobAbility).
        { name = 'Moogle',     modelId = 3035, ws = xi.mobSkill.METEORITE          },  -- light burst
        { name = 'Mandragora', modelId = 300,  ws = xi.mobSkill.AERO_IV            },  -- wind nuke
        { name = 'Coeurl',     modelId = 367,  ws = xi.mobSkill.CHARGED_WHISKER    },  -- thunder (coeurl signature)
        { name = 'Sabotender', modelId = 372,  ws = xi.mobSkill.THOUSAND_NEEDLES_1 },  -- 1000 Needles (cactuar)
        { name = 'Cardian',    modelId = 431,  ws = xi.mobSkill.FIRE_IV            },  -- fire nuke
        { name = 'Goblin',     modelId = 292,  ws = xi.mobSkill.BOMB_TOSS_1        },  -- Bomb Toss (goblin)
        { name = 'Yagudo',     modelId = 580,  ws = xi.mobSkill.DANCING_EDGE       },  -- multi-hit physical (yagudo)
        { name = 'Tonberry',   modelId = 1177, ws = xi.mobSkill.CURSED_SPHERE_1    },  -- dark burst
        { name = 'Antican',    modelId = 1280, ws = xi.mobSkill.ROCK_BUSTER        },  -- earth physical
        { name = 'Boggart',    modelId = 451,  ws = xi.mobSkill.BLIZZARD_IV        },  -- ice nuke
        { name = 'Goobbue',    modelId = 296,  ws = xi.mobSkill.AURORAL_UPPERCUT_1 },  -- heavy uppercut
        { name = 'Adventurer', modelId = 3119, ws = xi.mobSkill.CRESCENT_FANG      },  -- strong physical
    },

    -- OUTFIT picker: humanoid job-class themes applied on top of Appearance.
    -- When an outfit is set it overrides the Appearance model entirely.
    -- Model IDs are the trust-era (0C-range) npc_list look values for iconic FFXI
    -- characters: bytes[2]|(bytes[3]<<8) from HEX(SUBSTR(look,1,4)) -- same LE formula
    -- as mob_pools.modelid. Select "(None)" to revert to the Appearance model.
    outfits =
    {
        { name = 'Thief',       modelId = 3128 },  -- Lion (trust era)
        { name = 'Monk',        modelId = 3129 },  -- Prishe (trust era)
        { name = 'Red Mage',    modelId = 3131 },  -- Lilisette (trust era)
        { name = 'Ranger',      modelId = 3133 },  -- Aldo (trust era)
        { name = 'Dark Knight', modelId = 3135 },  -- Zeid (trust era)
        { name = 'Warrior',     modelId = 3136 },  -- Volker (trust era)
        { name = 'Paladin',     modelId = 3137 },  -- Trion (trust era)
        { name = 'Black Mage',  modelId = 3139 },  -- Shantotto (trust era)
        { name = 'Scholar',     modelId = 3140 },  -- Ajido-Marujido (trust era)
        { name = 'Bard',        modelId = 3147 },  -- Ulmia (trust era)
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
    tauntCE        = 4000,  -- Bulwark: cumulative enmity spiked onto the mob per tick (toward the Fellow)
    tauntVE        = 8000,  -- Bulwark: volatile enmity spiked onto the mob per tick (toward the Fellow)
    tauntDrain     = 20,    -- Bulwark: % of player's enmity bled off the mob per tick (keeps WS spikes in check)

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
    outfit   = 'Fellow_Outfit',  -- 0 = none (use Appearance); N = CONFIG.outfits[N]
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
-- Outfit overrides Appearance when set (0 = no outfit).
local function getOutfitModelId(p)
    local entry = CONFIG.outfits[getN(p, V.outfit)]
    return entry and entry.modelId
end
-- Per-role TP-move override charVar (0/unset = use the role's defaultWs).
local function tpVar(roleKey) return 'Fellow_TP_' .. roleKey end
-- The signature TP move fired at TP cap, resolved PER ROLE (not by appearance):
--   per-role override (Fellow_TP_<role>) -> the role's defaultWs -> appearance ws.
-- nil -> the combat loop falls back to a chassis-picked Ready move.
local function chosenWs(p)
    local roleKey = getRole(p)
    local choice  = getN(p, tpVar(roleKey))
    if choice > 0 then
        local rd    = CONFIG.roles[roleKey]
        local entry = rd and rd.moves and rd.moves[choice]
        if entry and entry.ws then return entry.ws end
    end
    local rd = CONFIG.roles[roleKey]
    if rd and rd.defaultWs then return rd.defaultWs end
    local mdl = CONFIG.models[getN(p, V.modelPet)]
    return mdl and mdl.ws
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

    -- Visual NPC model overlay. Outfit overrides Appearance when set.
    local mdlId = getOutfitModelId(p) or chosenModelId(p)
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

            -- Bulwark: spike hate toward the Fellow + bleed the player's enmity every tick.
            -- addEnmity(pet, CE, VE) raises the mob's hate toward the Fellow.
            -- lowerEnmity(master, %) drains the player's enmity so WS spikes don't pull hate permanently.
            if beh == 'tank' and master:isEngaged() then
                local tgt = master:getTarget()
                if tgt and not tgt:isDead() and p:isEngaged() then
                    pcall(function()
                        tgt:addEnmity(p, CONFIG.tauntCE, CONFIG.tauntVE)
                        tgt:lowerEnmity(master, CONFIG.tauntDrain)
                    end)
                end
            end

            -- Combat: every role fights (assist when idle, Ready at TP cap).
            if master:isEngaged() then
                local tgt = master:getTarget()
                if not p:isEngaged() then
                    if tgt and not tgt:isDead() then master:petAttack(tgt) end
                elseif p:getTP() >= CONFIG.autoReadyTP then
                    local ws = chosenWs(master)
                    if ws and ws > 0 and tgt and not tgt:isDead() then
                        p:useMobAbility(ws, tgt)  -- the chosen FORM's signature TP move (forced)
                        p:setTP(0)                -- forced skills don't consume TP; reset for a cap-and-build cadence
                    else
                        p:useMobAbility()         -- fallback: chassis picks a Ready move (consumes TP itself)
                    end
                end
                -- NOTE (fix): Magus/Hunter formerly added silent per-tick damage via
                -- bare tgt:takeDamage(). That bypasses the action system entirely, so
                -- it produced NO "hits for X" message, AND at 1500+/tick of flat,
                -- defense-ignoring damage it one-shot weak mobs the instant the master
                -- engaged -- before the player (or the Fellow's own melee) could land a
                -- blow, leaving only the "defeats" line and a "cannot attack" error.
                -- Removed: every role now fights VISIBLY through melee (petAttack) + its
                -- signature TP move (useMobAbility, above). Magus/Hunter stay distinct
                -- via their stat block + elemental/physical signature move. Real per-tick
                -- magic/ranged is a Phase-2 job, done through proper VISIBLE casts
                -- (pet:castSpell / a ranged mob skill), not bare takeDamage.
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
    local outfitEntry = CONFIG.outfits[getN(p, V.outfit)]
    local mdl         = CONFIG.models[getN(p, V.modelPet)]
    local lookName    = (outfitEntry and outfitEntry.name) or (mdl and mdl.name) or 'Moogle'
    p:printToPlayer(string.format('=== %s ===  Lv.%d %s  (%s)',
        nm, lvl, role.name, lookName), SYS)
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
    -- TP move in effect for the current role (per-role override, else role default).
    local roleKey  = getRole(p)
    local tpChoice  = getN(p, tpVar(roleKey))
    local roleMoves = (CONFIG.roles[roleKey] or {}).moves or {}
    local tpName    = (tpChoice > 0 and roleMoves[tpChoice] and roleMoves[tpChoice].name)
        or '(role default)'
    p:printToPlayer(string.format('  TP move (%s): %s', role.name, tpName), SYS)
end

-- ════════════════════════════════ Menus ═════════════════════════════════════
local openMain, openAllocate, openRole, openName, openModel, openOutfit, openTpMove, openBuyPoints

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
        { 'Outfit',       function(pp) openOutfit(pp, 0) end },
        { 'View Status',  function(pp) statusReport(pp); openMain(pp) end },
        { 'Close',        function(pp) end },
    }
    show(p, string.format('Fellow  Lv.%d', lvl), options)
end

openAllocate = function(p, page)
    local pts   = getPoints(p)
    local atMax = getLevel(p) >= CONFIG.maxLevel
    -- At max level you can buy points, so let players in even with 0 unspent.
    if pts <= 0 and not atMax then
        p:printToPlayer('[Fellow] No unspent points. Defeat foes with your Fellow out to earn more.', SYS)
        openMain(p)
        return
    end
    page = page or 0
    local order = CONFIG.statOrder
    -- Reserve a slot for "Buy Points" at max level; keep each page within the 8-option cap.
    local per   = atMax and 5 or CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#order / per))
    page = page % pages
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #order) do
        local s = order[i]
        options[#options + 1] =
        {
            string.format('%s (%d)', s, getStatPts(p, s)),
            function(pp)
                if getPoints(pp) <= 0 then
                    pp:printToPlayer('[Fellow] No unspent points.' .. (atMax and ' Use Buy Points.' or ''), SYS)
                    openAllocate(pp, page); return
                end
                if getStatPts(pp, s) >= CONFIG.statCap then
                    pp:printToPlayer(string.format('[Fellow] %s is at the cap (%d).', s, CONFIG.statCap), SYS)
                    openAllocate(pp, page); return
                end
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
    if atMax then
        options[#options + 1] = { 'Buy Points', function(pp) openBuyPoints(pp) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, string.format('Allocate (%d left)', pts), options)
end

-- Post-cap gil -> points exchange. Only reachable from openAllocate at max level.
openBuyPoints = function(p)
    local cost    = CONFIG.buyPointsCost
    local bundles = { 1, 10, 50 }
    local options = {}
    for _, n in ipairs(bundles) do
        local qty   = n
        local price = cost * qty
        options[#options + 1] =
        {
            string.format('Buy %d (%dg)', qty, price),
            function(pp)
                if pp:getGil() < price then
                    pp:printToPlayer(string.format('[Fellow] Need %d gil (have %d).', price, pp:getGil()), SYS)
                    openBuyPoints(pp); return
                end
                pp:delGil(price)
                setN(pp, V.points, getPoints(pp) + qty)
                pp:printToPlayer(string.format('[Fellow] Bought %d point(s) for %d gil. Unspent: %d.',
                    qty, price, getPoints(pp)), SYS)
                openBuyPoints(pp)
            end,
        }
    end
    options[#options + 1] = { 'Spend Points', function(pp) openAllocate(pp, 0) end }
    options[#options + 1] = { 'Back',         function(pp) openMain(pp) end }
    show(p, string.format('Buy Points (have %dg)', p:getGil()), options)
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
    -- TP move is configured PER ROLE; edit the current role's move here.
    options[#options + 1] = { 'Set TP Move', function(pp) openTpMove(pp, 0) end }
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

-- Paginated outfit picker: humanoid job-class themes that override Appearance.
-- "(None)" at index 0 reverts to the Appearance model; each numbered entry maps
-- to CONFIG.outfits[N]. Re-spawns the Fellow live if it is currently out.
openOutfit = function(p, page)
    page = page or 0
    -- Prepend "(None)" so realIdx 0 = clear outfit; realIdx N = CONFIG.outfits[N].
    local all = { { name = '(None)' } }
    for _, o in ipairs(CONFIG.outfits) do all[#all + 1] = o end
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#all / per))
    page = page % pages
    local cur   = getN(p, V.outfit)
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #all) do
        local idx      = i
        local entry    = all[idx]
        local realIdx  = idx - 1
        local label    = (cur == realIdx) and (entry.name .. ' *') or entry.name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, V.outfit, realIdx)
                respawnIfOut(pp)
                if realIdx == 0 then
                    pp:printToPlayer('[Fellow] Outfit cleared; using Appearance model.', SYS)
                else
                    pp:printToPlayer(string.format('[Fellow] Outfit: %s.', entry.name), SYS)
                end
                openOutfit(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openOutfit(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, 'Choose Outfit', options)
end

-- Paginated TP-move picker for the CURRENT role. "(Default)" at realIdx 0 uses the
-- role's defaultWs; each numbered entry maps to that role's moves[N]. Applies live --
-- the combat loop reads chosenWs() each tick, so no re-summon is needed.
openTpMove = function(p, page)
    page = page or 0
    local roleKey  = getRole(p)
    local roleName = (CONFIG.roles[roleKey] or {}).name or roleKey
    local roleMoves = (CONFIG.roles[roleKey] or {}).moves or {}
    -- Prepend "(Default)" so realIdx 0 = role default; realIdx N = role's moves[N].
    local all = { { name = '(Default)' } }
    for _, t in ipairs(roleMoves) do all[#all + 1] = t end
    local per   = CONFIG.namesPerPage
    local pages = math.max(1, math.ceil(#all / per))
    page = page % pages
    local cur   = getN(p, tpVar(roleKey))
    local options = {}
    for i = page * per + 1, math.min((page + 1) * per, #all) do
        local idx     = i
        local entry   = all[idx]
        local realIdx = idx - 1
        local label   = (cur == realIdx) and (entry.name .. ' *') or entry.name
        options[#options + 1] =
        {
            label,
            function(pp)
                setN(pp, tpVar(roleKey), realIdx)
                if realIdx == 0 then
                    pp:printToPlayer(string.format('[Fellow] %s TP move: Default.', roleName), SYS)
                else
                    pp:printToPlayer(string.format('[Fellow] %s TP move: %s.', roleName, entry.name), SYS)
                end
                openTpMove(pp, page)
            end,
        }
    end
    if pages > 1 then
        options[#options + 1] = { 'More >>', function(pp) openTpMove(pp, page + 1) end }
    end
    options[#options + 1] = { 'Back', function(pp) openRole(pp) end }
    show(p, string.format('TP Move: %s', roleName), options)
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

-- Diagnostic (!fellow debug): dump the LIVE Fellow's ACTUAL mods, read straight off
-- the spawned pet. Spend a point (it applies instantly while the Fellow is out) and
-- re-run to watch the matching number move -- verifiable proof the allocation lands.
xi.fellow.debug = function(p)
    if not (p:hasPet() and petIsFellow(p:getPet())) then
        p:printToPlayer('[Fellow] Summon your Fellow first -- this reads mods off the live pet.', SYS)
        return
    end
    local pet = p:getPet()
    local function m(mod) return pet:getMod(mod) end
    p:printToPlayer('=== Fellow live mods (straight off the spawned pet) ===', SYS)
    p:printToPlayer(string.format('  ATT %d  ACC %d  DEF %d  EVA %d', m(xi.mod.ATT), m(xi.mod.ACC), m(xi.mod.DEF), m(xi.mod.EVA)), SYS)
    p:printToPlayer(string.format('  MATT %d  MACC %d  MDEF %d', m(xi.mod.MATT), m(xi.mod.MACC), m(xi.mod.MDEF)), SYS)
    p:printToPlayer(string.format('  ATK%% %d  Crit %d  DA %d  TA %d  StoreTP %d  HasteGear %d',
        m(xi.mod.ATTP), m(xi.mod.CRITHITRATE), m(xi.mod.DOUBLE_ATTACK), m(xi.mod.TRIPLE_ATTACK), m(xi.mod.STORETP), m(xi.mod.HASTE_GEAR)), SYS)
    p:printToPlayer(string.format('  PDT %d  MDT %d  Regen %d  Refresh %d', m(xi.mod.DMGPHYS), m(xi.mod.DMGMAGIC), m(xi.mod.REGEN), m(xi.mod.REFRESH)), SYS)
    p:printToPlayer(string.format('  STR %d  DEX %d  VIT %d  AGI %d  INT %d  MND %d',
        m(xi.mod.STR), m(xi.mod.DEX), m(xi.mod.VIT), m(xi.mod.AGI), m(xi.mod.INT), m(xi.mod.MND)), SYS)
    p:printToPlayer(string.format('  MaxHP %d   TP %d/3000   Engaged %s   (fires a Ready move at TP>=%d)',
        pet:getMaxHP(), pet:getTP(), tostring(pet:isEngaged()), CONFIG.autoReadyTP), SYS)
end

return m
