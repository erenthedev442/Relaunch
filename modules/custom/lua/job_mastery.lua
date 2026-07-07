-----------------------------------
-- job_mastery.lua
--
-- JOB MASTERY CHALLENGES: each of the 12 weapon types has a powerful Guardian
-- boss that spawns in Walk of Echoes. Defeating your chosen Guardian earns
-- Prime Weapon Trial 4 credit (charVar PW_Trial4_Done = 1).
--
-- The fight is solo (honor system - trusts are disabled zone-wide (Walk of Echoes MISC_TRUST off)).
-- Death ends the challenge with no reward and no save.
--
-- CharVars:
--   PW_T4_<weapon>_Done   1 when that weapon's Guardian has been killed
--   PW_Trial4_Done        1 when ANY guardian has been killed (gates Prime Armory)
--
-- Globals exposed for the !mastery command:
--   xi._jm_sessions       live session table
--   xi._jm_endChallenge   endChallenge(player, reason) function
--   xi._jm_guardians      GUARDIANS catalog (read-only)
--
-- NPC: Weapon Mastery Sage in GM Home, z = -35.
-- Needs map restart (addOverride hooks for GM_Home + WalkOfEchoes + onPlayerDeath).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Walk_of_Echoes/Zone')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m         = Module:new('job_mastery')
local mechanics = require('modules/custom/lua/mob_mechanics_library')

-----------------------------------
-- Weapon Guardian hardcore-mechanics config.
-- Applied ONCE after spawn + stat setup via mechanics.attach().
-- addGroupId 11363 / addZoneId 210: Simurgh (Walk of Echoes mob_groups, zone 210),
-- matching GROUP_ZONE_ID used by every Guardian spawn in this file.
-- DMGPHYS/DMGMAGIC clamped at -5000 (library rule: -50% resistance cap).
-- No mob:addMod(ATT) calls -- enrage/fury `att` handled internally by safeAddMod.
-----------------------------------
local GUARDIAN_MECH_CFG = {
    name   = 'Weapon Guardian',
    enrage = {
        sec    = 150,
        att    = 5000,
        haste  = 200,
        msg    = 'The Guardian grows impatient. Time is your enemy!',
    },
    stance = {
        startHpp  = 90,
        periodSec = 16,
        stances   = {
            {
                mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0 },
                msg  = 'The Guardian hardens its body -- steel cannot bite!',
            },
            {
                mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -5000 },
                msg  = 'The Guardian tears a rift in aether -- spells shatter!',
            },
        },
    },
    aoe = {
        periodSec = 12,
        dmgPct    = 22,
        msg       = 'The Guardian releases a crushing shockwave!',
    },
    cc = {
        periodSec = 22,
        effect    = xi.effect.TERROR,
        power     = 1,
        dur       = 5,
        msg       = 'The Guardian roars -- you cannot move!',
    },
    drain = {
        periodSec = 8,
        healPct   = 2,
    },
    phases = {
        {
            hp  = 50,
            action  = 'nuke',
            dmgPct  = 40,
            msg     = 'The Guardian erupts in a pillar of annihilation!',
        },
        {
            hp     = 40,
            action = 'dispel',
            count  = 4,
            msg    = 'The Guardian unravels your enhancements!',
        },
        {
            hp     = 25,
            action = 'fury',
            att    = 4000,
            haste  = 120,
            msg    = 'The Guardian enters a killing frenzy!',
        },
        {
            hp  = 10,
            action  = 'doom',
            dur     = 25,
            msg     = 'The Guardian marks you for death -- finish it NOW!',
        },
        {
            hp     = 10,
            action = 'enrage',
            att    = 8000,
            haste  = 250,
            msg    = 'The Guardian has no mercy left!',
        },
    },
    doom = {
        startHpp = 12,
        dur      = 30,
        msg      = 'Doom descends -- the Guardian will not let you leave alive!',
    },
}

-----------------------------------
-- Constants
-----------------------------------
local CHALLENGE_ZONE_ID = xi.zone.WALK_OF_ECHOES
local GROUP_ZONE_ID     = 210
-- Owner-verified landing spot in Walk of Echoes (zone 182): a stone platform
-- at (-519, 36, 236), separate from the Endless Tower's spot so the two trials
-- never overlap. The original (-380,14,10) was off the map. The boss spawns at
-- player+12 (x), so it lands just east on the same platform.
local WARP_IN  = { x = -519.013, y = 36.000, z = 235.893, rot = 226 }
local EXIT_WARP = { zoneId = 44, x = 571.471, y = -3.360, z = 512.586, rot = 65 }

-----------------------------------
-- Boss affix pool (same as Endless Tower)
-----------------------------------
-- Trial 4 is meant to be BRUTAL (owner: "go even further"). Every affix now
-- carries real offense on top of the flat floor applied in spawnGuardian, so
-- there is no "safe" roll -- even the tank/regen affixes hit hard.
local AFFIXES = {
    { label = 'Fortified',    mods = { [xi.mod.DEF] = 2000, [xi.mod.ATT] = 4000 },                                    hpMult = 1.4  },
    { label = 'Frenzied',     mods = { [xi.mod.HASTE_GEAR] = 300, [xi.mod.DOUBLE_ATTACK] = 35, [xi.mod.ATT] = 5000 }, hpMult = 1.1  },
    { label = 'Regenerating', mods = { [xi.mod.REGEN] = 1500, [xi.mod.ATT] = 4000 },                                  hpMult = 1.1  },
    { label = 'Empowered',    mods = { [xi.mod.ATT] = 9000, [xi.mod.STR] = 300 },                                     hpMult = 1.1  },
    { label = 'Colossal',     mods = { [xi.mod.ATT] = 5000, [xi.mod.DOUBLE_ATTACK] = 15 },                            hpMult = 2.2  },
    { label = 'Furious',      mods = { [xi.mod.ATT] = 10000, [xi.mod.HASTE_GEAR] = 200, [xi.mod.TRIPLE_ATTACK] = 20 }, hpMult = 1.3  },
}

-----------------------------------
-- Guardian catalog (12 weapon types)
-- groupId picks from existing HL mob_groups (registered in zone 210 / GM_Home).
-----------------------------------
-- "10x harder" baked straight into the stat block (owner: silent difficulty --
-- no visible multiplier). Two real levers:
--   * HP x10  (5M -> 50M, 5.5M -> 55M)
--   * LEVEL the engine actually honors. mob level is uint8, so the old 260/265
--     WRAPPED to level 4/9 -- the bosses were accidentally near-trivial in base
--     stats (weak hits, weak TP). Set to a genuine 160/170 (above the 135-145
--     Abyssea NMs): real accuracy to land on a 99, real auto/TP-move damage.
--     This level fix is the main reason they go from "HP sponge" to "brutal".
-- Tuning dials if it's too much/little: the level (130 easier .. 200 harder) and
-- the HP. Higher level lowers the player's hit rate, so HP and level compound.
local GUARDIANS =
{
    sword      = { label = 'Sword',      bossName = 'Guardian of the Blade',    level = 160, hp = 50000000, groupId = 11365 },
    dagger     = { label = 'Dagger',     bossName = 'Guardian of the Shadow',   level = 160, hp = 50000000, groupId = 11362 },
    greatsword = { label = 'Grt.Sword',  bossName = 'Guardian of Ruin',         level = 170, hp = 55000000, groupId = 11367 },
    axe        = { label = 'Axe',        bossName = 'Guardian of the Axe',      level = 160, hp = 50000000, groupId = 11363 },
    greataxe   = { label = 'Grt.Axe',   bossName = 'Guardian of the Vanguard', level = 170, hp = 55000000, groupId = 11368 },
    scythe     = { label = 'Scythe',     bossName = 'Guardian of Catastrophe',  level = 170, hp = 55000000, groupId = 11366 },
    polearm    = { label = 'Polearm',    bossName = 'Guardian of the Dragon',   level = 170, hp = 55000000, groupId = 11369 },
    katana     = { label = 'Katana',     bossName = 'Void Blade Guardian',      level = 160, hp = 50000000, groupId = 11362 },
    greatkatana = { label = 'Grt.Katana', bossName = 'Guardian of the Kensei', level = 170, hp = 55000000, groupId = 11367 },
    club       = { label = 'Club',       bossName = 'Guardian of the Mace',     level = 160, hp = 50000000, groupId = 11364 },
    staff      = { label = 'Staff',      bossName = 'Guardian of Elements',     level = 170, hp = 55000000, groupId = 11366 },
    archery    = { label = 'Archery',    bossName = 'Guardian of the Hunt',     level = 160, hp = 50000000, groupId = 11363 },
}

-- Page-ordered key list for the 2-page menu (6 per page).
local GUARDIAN_ORDER = {
    'sword', 'dagger', 'greatsword', 'axe', 'greataxe', 'scythe',
    'polearm', 'katana', 'greatkatana', 'club', 'staff', 'archery',
}

-----------------------------------
-- Sessions
-----------------------------------
local sessions = {}
xi._jm_sessions  = sessions
xi._jm_guardians = GUARDIANS

local function getSession(p)   return sessions[p:getName()] end
local function clearSession(p) sessions[p:getName()] = nil  end

-----------------------------------
-- Forward declarations
-----------------------------------
local endChallenge

-----------------------------------
-- Complete a guardian challenge
-----------------------------------
local function completeChallenge(player, weaponKey)
    clearSession(player)

    local g = GUARDIANS[weaponKey]
    player:setCharVar('PW_T4_' .. weaponKey .. '_Done', 1)

    player:printToPlayer(string.format(
        '[Mastery] The %s has been defeated! %s Challenge complete!',
        g.bossName, g.label), xi.msg.channel.SYSTEM_3)

    if (player:getCharVar('PW_Trial4_Done') or 0) == 0 then
        player:setCharVar('PW_Trial4_Done', 1)
        player:printToPlayer(
            '[Mastery] Trial 4 complete! Visit the Prime Armory to forge your Prime Weapon.',
            xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer(
            '[Mastery] Additional guardian defeated! All weapon challenges accumulate.',
            xi.msg.channel.SYSTEM_3)
    end

    player:timer(3000, function(p)
        p:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
    end)
end

-----------------------------------
-- End the challenge early (death / abort / zone-leave)
-----------------------------------
endChallenge = function(player, reason)
    local sess = getSession(player)
    clearSession(player)

    if sess and sess.boss then
        pcall(function() sess.boss:setHP(0) end)
    end

    if reason == 'death' then
        player:printToPlayer('[Mastery] You were defeated. The Guardian endures.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'abort' then
        player:printToPlayer('[Mastery] Challenge aborted.', xi.msg.channel.SYSTEM_3)
    elseif reason == 'left' then
        player:printToPlayer('[Mastery] You left the arena. Challenge forfeited.', xi.msg.channel.SYSTEM_3)
    end

    player:timer(2000, function(p)
        p:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
    end)
end

xi._jm_endChallenge = endChallenge

-----------------------------------
-- Spawn the Guardian
-----------------------------------
local function spawnGuardian(player, weaponKey)
    local g         = GUARDIANS[weaponKey]
    local affix     = AFFIXES[math.random(#AFFIXES)]
    local ownerName = player:getName()

    local px, py, pz = player:getXPos(), player:getYPos(), player:getZPos()
    local mx = px + 12
    local mz = pz

    local mob = player:getZone():insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = g.groupId,
        groupZoneId          = GROUP_ZONE_ID,
        name                 = g.bossName,
        x = mx, y = py, z = mz,
        rotation             = 128,
        minLevel             = g.level,
        maxLevel             = g.level,
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            mechanics.cleanup(deadMob)
            if not sessions[ownerName] then return end
            sessions[ownerName] = nil
            local resolved = GetPlayerByName(ownerName)
            if resolved then completeChallenge(resolved, weaponKey) end
        end,

        onMobFight = function(mfMob, mfTarget)
            mechanics.tick(mfMob, mfTarget)
        end,
    })

    if not mob then
        player:printToPlayer('[Mastery] ERROR: Guardian failed to spawn. Aborting.', xi.msg.channel.SYSTEM_3)
        endChallenge(player, 'abort')
        return
    end

    mob:setSpawn(mx, py, mz, 128)
    mob:spawn()
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setModelSize(3)

    for modId, val in pairs(affix.mods) do mob:setMod(modId, val) end

    -- Light flat floor on TOP of the affix. The real level (160/170) already
    -- supplies high accuracy + attack + TP-move damage, so we DON'T pile on a big
    -- ACC/ATT floor (that would push it into one-shot territory) -- just make its
    -- TP moves come faster and add a couple of extra swings.
    mob:addMod(xi.mod.STORETP, 200)
    mob:addMod(xi.mod.DOUBLE_ATTACK, 10)

    local finalHp = math.floor(g.hp * affix.hpMult)
    mob:setMaxHP(finalHp)
    mob:setHP(finalHp)
    mob:addEnmity(player, 30000, 30000)

    -- Attach hardcore fight mechanics (stance dance / AoE / CC / drain /
    -- phases / doom / enrage). Must come AFTER all stat + HP setup.
    mechanics.attach(mob, GUARDIAN_MECH_CFG)

    -- Store ref for abort/death cleanup.
    local sess = sessions[ownerName]
    if sess then sess.boss = mob end

    -- Idle despawn: if the mob hasn't taken any damage after 45s, remove it.
    -- Clear the session first so onMobDeath's completion guard fires and exits.
    local spawnHp = finalHp
    player:timer(45000, function(p)
        local s = sessions[ownerName]
        if not s or s.boss ~= mob then return end   -- session gone or boss replaced
        local hp = 0
        local ok = pcall(function() hp = mob:getHP() end)
        if not ok then return end                    -- mob already gone
        if hp < spawnHp then return end              -- player is fighting; leave it alone
        sessions[ownerName] = nil
        pcall(function() mob:setHP(0) end)
        p:printToPlayer('[Mastery] The Guardian vanished — engage within 45 seconds next time.', xi.msg.channel.SYSTEM_3)
        p:timer(2000, function(pp)
            pp:setPos(EXIT_WARP.x, EXIT_WARP.y, EXIT_WARP.z, EXIT_WARP.rot, EXIT_WARP.zoneId)
        end)
    end)

    player:printToPlayer(string.format(
        '[Mastery] The %s appears! [%s - %d HP] Solo fight: defeat it to earn Trial 4.',
        g.bossName, affix.label, finalHp), xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- Zone-in trigger (called after the warp lands)
-----------------------------------
local function startChallenge(player, weaponKey)
    local g = GUARDIANS[weaponKey]
    player:printToPlayer(string.format(
        '[Mastery] %s Mastery Challenge! Defeat the %s. Good luck.',
        g.label, g.bossName), xi.msg.channel.SYSTEM_3)
    player:timer(2000, function(p)
        if sessions[p:getName()] then spawnGuardian(p, weaponKey) end
    end)
end

-----------------------------------
-- NPC menu (2 pages; each page ≤150 bytes including title + all labels)
-----------------------------------
local function showMasteryMenu(player, page)
    -- Print completion status above the menu.
    local doneList = {}
    for _, key in ipairs(GUARDIAN_ORDER) do
        if (player:getCharVar('PW_T4_' .. key .. '_Done') or 0) == 1 then
            doneList[#doneList + 1] = GUARDIANS[key].label
        end
    end
    if #doneList > 0 then
        player:printToPlayer('[Mastery] Guardians defeated: ' .. table.concat(doneList, ', '), xi.msg.channel.SYSTEM_3)
    else
        player:printToPlayer('[Mastery] No Weapon Guardians defeated yet. Trial 4 incomplete.', xi.msg.channel.SYSTEM_3)
    end

    local title    = 'Mastery ' .. page .. '/2'
    local opts     = {}
    local idxStart = (page == 1) and 1 or 7
    local idxEnd   = (page == 1) and 6 or 12

    for i = idxStart, idxEnd do
        local key    = GUARDIAN_ORDER[i]
        local g      = GUARDIANS[key]
        local isDone = (player:getCharVar('PW_T4_' .. key .. '_Done') or 0) == 1
        local lbl    = isDone and (g.label .. ' [Done]') or g.label

        local capturedKey = key
        table.insert(opts, {
            lbl,
            function(p)
                if getSession(p) then
                    p:printToPlayer('[Mastery] Active challenge. !mastery abort to reset.', xi.msg.channel.SYSTEM_3)
                    return
                end
                sessions[p:getName()] = { weapon = capturedKey, boss = nil }
                p:setPos(WARP_IN.x, WARP_IN.y, WARP_IN.z, WARP_IN.rot, CHALLENGE_ZONE_ID)
            end,
        })
    end

    if page == 1 then
        table.insert(opts, { 'Next ->', function(p) showMasteryMenu(p, 2) end })
    else
        table.insert(opts, { '<- Back', function(p) showMasteryMenu(p, 1) end })
    end
    table.insert(opts, { 'Leave', function(p) end })

    local snap = { title = title, options = opts }
    player:timer(30, function(p) p:customMenu(snap) end)
end

-----------------------------------
-- Module overrides
-----------------------------------

-- GM Home: place the Mastery Sage NPC at z = -35.
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local npc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapon_Mastery_Sage',
        packetName = 'Weapon Mastery Sage',
        look       = 212,
        x          =  572.971,
        y          =   -3.360,
        z          =  532.586,
        rotation   =  192,
        widescan   =  1,

        onTrigger = function(player, npc)
            if getSession(player) then
                player:printToPlayer('[Mastery] You have an active challenge. Use !mastery abort to reset.', xi.msg.channel.SYSTEM_3)
                return
            end
            player:printToPlayer(
                '[Mastery] Choose a weapon type. Its Guardian waits in Walk of Echoes. Defeat it to earn Trial 4 of the Prime Weapon path.',
                xi.msg.channel.SYSTEM_3)
            showMasteryMenu(player, 1)
        end,
    })
    utils.unused(npc)
end)

-- Walk of Echoes: start the challenge after zone-in.
m:addOverride('xi.zones.Walk_of_Echoes.Zone.onZoneIn', function(player, prevZone)
    local cs   = super(player, prevZone)
    local sess = getSession(player)
    -- Only fire if we have a session and the boss hasn't spawned yet.
    if sess and sess.boss == nil and sess.weapon then
        startChallenge(player, sess.weapon)
    end
    return cs
end)

-- Death ends the challenge.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    local cs = super(player, ...)
    if getSession(player) then
        player:timer(2000, function(p) endChallenge(p, 'death') end)
    end
    return cs
end)

return m
